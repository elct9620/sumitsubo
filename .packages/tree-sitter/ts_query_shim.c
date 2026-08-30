// Parse one source with a grammar linked into this binary, run one query over
// it, and hand the captures back as one string.
//
// One call does everything because the boundary is where the cost is: every
// crossing has to marshal, so parse-query-collect stays on this side.
//
// A capture comes back as `match\tname\tline\tlast\tstart\tfinish\ttext\n` with
// the text escaped — a
// comment is the thing being collected, and one routinely contains the newline
// that would otherwise end the record. Captures arrive in node position rather
// than pattern order, so the name is what tells them apart and the match number
// is what groups the ones describing the same thing. Predicates (`#eq?` and
// friends) are not evaluated: the queries are the tool's own, and none carries
// one.
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include "spinel/runtime.h"
// The header the declarations are written against travels with them: spin puts
// only the package root on the include path, so a carried .c cannot reach one
// anywhere else.
#include "tree_sitter/api.h"

static char *tsq_out = NULL;
static size_t tsq_out_len = 0;
static size_t tsq_out_cap = 0;
static char tsq_err[512] = {0};
// Failure needs its own channel: the result arrives as bytes and an empty
// result is a legitimate answer, so it cannot double as an error signal.
static int tsq_ok = 1;
static int tsq_parsed_clean = 1;

static void tsq_reset(void) {
  tsq_out_len = 0;
  tsq_ok = 1;
  if (tsq_out) tsq_out[0] = '\0';
  tsq_err[0] = '\0';
}

static int tsq_reserve(size_t extra) {
  if (tsq_out_len + extra + 1 <= tsq_out_cap) return 1;
  size_t cap = tsq_out_cap ? tsq_out_cap : 4096;
  while (cap < tsq_out_len + extra + 1) cap *= 2;
  char *grown = (char *)realloc(tsq_out, cap);
  if (!grown) return 0;
  tsq_out = grown;
  tsq_out_cap = cap;
  return 1;
}

static int tsq_put(const char *bytes, size_t len) {
  if (!tsq_reserve(len)) return 0;
  memcpy(tsq_out + tsq_out_len, bytes, len);
  tsq_out_len += len;
  tsq_out[tsq_out_len] = '\0';
  return 1;
}

// Escapes so one capture stays one line: backslash, newline, carriage return
// and tab are the only bytes that could break the record apart.
static int tsq_put_escaped(const char *bytes, size_t len) {
  for (size_t i = 0; i < len; i++) {
    char c = bytes[i];
    const char *rep = NULL;
    switch (c) {
      case '\\': rep = "\\\\"; break;
      case '\n': rep = "\\n"; break;
      case '\r': rep = "\\r"; break;
      case '\t': rep = "\\t"; break;
      default: break;
    }
    if (rep) {
      if (!tsq_put(rep, 2)) return 0;
    } else if (!tsq_put(&c, 1)) {
      return 0;
    }
  }
  return 1;
}

// Grammars linked into the binary announce themselves rather than being listed
// here. Which languages a build carries is the application's decision, and a
// binding naming them would make every one of those symbols a requirement.
#define TSQ_MAX_GRAMMARS 8

static struct {
  char *name;
  const TSLanguage *language;
} tsq_grammars[TSQ_MAX_GRAMMARS];
static int tsq_grammar_count = 0;

void tsq_register(const char *name, const TSLanguage *language) {
  if (tsq_grammar_count >= TSQ_MAX_GRAMMARS) return;
  tsq_grammars[tsq_grammar_count].name = strdup(name);
  tsq_grammars[tsq_grammar_count].language = language;
  tsq_grammar_count++;
}

static const TSLanguage *tsq_language(const char *name) {
  for (int i = 0; i < tsq_grammar_count; i++) {
    if (strcmp(tsq_grammars[i].name, name) == 0) return tsq_grammars[i].language;
  }
  snprintf(tsq_err, sizeof(tsq_err), "no grammar registered for %s", name);
  return NULL;
}

// A run scans hundreds of files, and compiling a query per call would be the
// whole cost. It does not scan them with one query: a caller reads a file
// through one grammar and then reads inside what came back through another, and
// turns between several of its own, so a single slot is thrown away on every
// turn and rebuilt on the next. Every query a program writes is held instead —
// there are a handful, they live as long as the run, and holding them is what
// makes the order a caller reads in cost nothing.
//
// Beyond what fits, a query is compiled every time rather than evicting one: a
// program with more queries than this has a shape nobody here has met, and
// answering slowly is better than answering wrongly about which one to drop.
// The one it was handed last is kept only to be freed on the next, so a run
// long enough to reach here does not grow without end.
#define TSQ_QUERIES 32
static const TSLanguage *tsq_query_lang[TSQ_QUERIES];
static char *tsq_query_src[TSQ_QUERIES];
static TSQuery *tsq_query_held[TSQ_QUERIES];
static int tsq_query_count = 0;
static TSQuery *tsq_query_spare = NULL;

// The language is half the key. A query is compiled against one grammar's node
// ids, so the same text compiled for another answers nonsense rather than
// failing. No two grammars here write a query alike today, which is why nothing
// goes red when this half is dropped — the pair is what makes it safe for the
// day one of them does.
static TSQuery *tsq_query_for(const TSLanguage *language, const char *src) {
  for (int i = 0; i < tsq_query_count; i++) {
    if (tsq_query_lang[i] == language && strcmp(tsq_query_src[i], src) == 0) {
      return tsq_query_held[i];
    }
  }

  uint32_t error_offset = 0;
  TSQueryError error_type = TSQueryErrorNone;
  TSQuery *query = ts_query_new(language, src, (uint32_t)strlen(src), &error_offset, &error_type);
  if (!query) {
    snprintf(tsq_err, sizeof(tsq_err), "query error type %d at byte %u", (int)error_type, error_offset);
    return NULL;
  }

  char *held = tsq_query_count < TSQ_QUERIES ? strdup(src) : NULL;
  if (held) {
    tsq_query_lang[tsq_query_count] = language;
    tsq_query_src[tsq_query_count] = held;
    tsq_query_held[tsq_query_count] = query;
    tsq_query_count++;
    return query;
  }

  if (tsq_query_spare) ts_query_delete(tsq_query_spare);
  tsq_query_spare = query;
  return query;
}

static TSParser *tsq_parser = NULL;

const char *tsq_error(void) { return tsq_err; }

// Whether the last query failed. Kept apart from the result because the result
// cannot carry the distinction: no captures and no answer look the same once
// the bytes arrive.
int tsq_failed(void) { return !tsq_ok; }

// Whether the last parse produced a clean tree. A file the grammar could not
// read yields few or no captures, which is indistinguishable from a file that
// genuinely says nothing — and the caller has to tell those apart or it will
// report the specification as wrong when the source is what broke.
int tsq_parse_ok(void) { return tsq_parsed_clean; }

const char *tsq_query(const char *grammar, const char *source, const char *query_src) {
  tsq_reset();

  const TSLanguage *language = tsq_language(grammar);
  if (!language) { tsq_ok = 0; return NULL; }

  if (!tsq_parser) tsq_parser = ts_parser_new();
  if (!ts_parser_set_language(tsq_parser, language)) {
    snprintf(tsq_err, sizeof(tsq_err), "grammar %s is not ABI-compatible with this tree-sitter", grammar);
    tsq_ok = 0;
    return NULL;
  }

  TSQuery *query = tsq_query_for(language, query_src);
  if (!query) { tsq_ok = 0; return NULL; }

  uint32_t source_len = (uint32_t)strlen(source);
  TSTree *tree = ts_parser_parse_string(tsq_parser, NULL, source, source_len);
  tsq_parsed_clean = !ts_node_has_error(ts_tree_root_node(tree));

  TSQueryCursor *cursor = ts_query_cursor_new();
  ts_query_cursor_exec(cursor, query, ts_tree_root_node(tree));

  TSQueryMatch match;
  int ok = 1;
  // Numbered here rather than taken from the match: tree-sitter recycles its
  // own ids, and what a caller needs is only that two records made by one
  // match carry the same number.
  uint32_t matched = 0;
  while (ok && ts_query_cursor_next_match(cursor, &match)) {
    for (uint16_t i = 0; i < match.capture_count; i++) {
      TSNode node = match.captures[i].node;
      uint32_t start = ts_node_start_byte(node);
      uint32_t end = ts_node_end_byte(node);
      if (end > source_len) end = source_len;

      uint32_t name_len = 0;
      const char *name = ts_query_capture_name_for_id(query, match.captures[i].index, &name_len);

      char head[32];
      int head_len = snprintf(head, sizeof(head), "%u\t", matched);

      // Rows count from zero inside tree-sitter and from one for anyone
      // reading a file, so the conversion happens here rather than in every
      // caller that wants to print a location. The bytes are carried as they
      // are: they say where the node sits in what was parsed, which is what a
      // caller reading inside one capture has to know.
      char extent[80];
      int extent_len = snprintf(extent, sizeof(extent), "\t%u\t%u\t%u\t%u\t",
                                ts_node_start_point(node).row + 1,
                                ts_node_end_point(node).row + 1, start, end);

      if (!tsq_put(head, (size_t)head_len) || !tsq_put(name, (size_t)name_len) ||
          !tsq_put(extent, (size_t)extent_len) ||
          !tsq_put_escaped(source + start, end - start) || !tsq_put("\n", 1)) {
        snprintf(tsq_err, sizeof(tsq_err), "out of memory collecting captures");
        ok = 0;
        break;
      }
    }
    matched++;
  }

  ts_query_cursor_delete(cursor);
  ts_tree_delete(tree);

  if (!ok) { tsq_ok = 0; return NULL; }

  // Handed back as bytes with the length alongside: a capture's text carries
  // newlines and the caller reads records by count rather than by terminator.
  // Spinel copies out of this buffer before returning, so the scratch space
  // stays ours.
  sp_ffi_bin_len = (int)tsq_out_len;
  return tsq_out ? tsq_out : "";
}
