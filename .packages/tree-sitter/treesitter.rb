# The tree-sitter binding: parse a source through a grammar and read back what
# one query captured.
#
# The binding carries the declarations, the shim and the header; the runtime and
# the grammars are the application's to link in, and a grammar announces itself
# through +register+. That is why a build carrying no grammar fails at link time
# rather than at run time: what the executable can parse is decided when it is
# built.
#
# A capture arrives as an escaped `match\tname\tline\ttext` record. The escaping
# is because a comment routinely contains the newline that would otherwise end
# the record; the line is what lets a finding be reported somewhere a reader can
# go and look.
#
# Captures arrive in node position order rather than pattern order, so a caller
# reading several of them tells them apart by name and groups them by match.

# The C side, reached through FFI: these declarations are the whole of what the
# compiler knows about it. A capture's text is binary-safe rather than
# NUL-terminated, so the result comes back by length, and whether the call
# failed is asked separately — an empty result is a legitimate answer.
module TreeSitterNative
  ffi_func :tsq_register, [:str, :ptr], :void
  ffi_func :tsq_query, [:str, :str, :str], :binstr
  ffi_func :tsq_error, [], :str
  ffi_func :tsq_failed, [], :bool
  ffi_func :tsq_parse_ok, [], :bool
end

module TreeSitter
  # +match+ groups the captures one match made; +name+ is the capture's name in
  # the query, without its `@`. A node's extent is not carried: the text is the
  # source slice, so a caller wanting the last line counts the newlines in it.
  Capture = Struct.new(:match, :name, :line, :text)

  # A source the grammar could not read, as opposed to one that says nothing.
  class ParseError < StandardError; end

  module_function

  # Announces a grammar linked into this binary under +name+. The application
  # decides which ones it carries, so the list lives there rather than here.
  def register(name, language)
    TreeSitterNative.tsq_register(name, language)
  end

  # What +query+ captured in +source+, in the order the parser met them.
  #
  # A source the grammar cannot read raises rather than returning what it
  # managed to recover. Partial recovery is the dangerous case: some captures
  # come back and others do not, so the missing ones read exactly like a promise
  # the source never made.
  def capture(grammar, source, query, where = "source")
    raw = TreeSitterNative.tsq_query(grammar, source, query)
    raise ParseError, "tree-sitter: #{TreeSitterNative.tsq_error}" if TreeSitterNative.tsq_failed
    raise ParseError, "#{where}: cannot be parsed by the #{grammar} grammar" unless TreeSitterNative.tsq_parse_ok

    decode(raw)
  end

  # The record format this binding owns, read back without a parser.
  def decode(raw)
    found = []

    raw.split("\n").each do |record|
      # The escaping is what makes this safe: a tab in the captured text is
      # written as a pair, so the only tabs left are the three separators.
      fields = record.split("\t")
      # A record short of its separators is skipped rather than half-read: half
      # a capture reads like something the source never said. A capture of
      # nothing loses its last field to the split, so three is enough.
      next if fields.length < 3

      # Interpolated to settle the element type: an array built by a loop keeps
      # its members open, and unescape needs a string.
      found << Capture.new(
        fields[0].to_i, "#{fields[1]}", fields[2].to_i, unescape("#{fields[3]}")
      )
    end

    found
  end

  # Reverses the native side's escaper.
  def unescape(text)
    text.gsub(/\\./) do |pair|
      case pair[1]
      when "n" then "\n"
      when "r" then "\r"
      when "t" then "\t"
      else pair[1]
      end
    end
  end
end
