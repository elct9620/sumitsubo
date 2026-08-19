# The tree-sitter binding: parse a source through a grammar and read back what
# one query captured.
#
# The binding carries the declarations, the shim and the header; the runtime and
# the grammars are the application's to link in, and a grammar announces itself
# through +register+. That is why a build carrying no grammar fails at link time
# rather than at run time: what the executable can parse is decided when it is
# built.
#
# A capture arrives as an escaped `line\ttext` record. The escaping is because a
# comment routinely contains the newline that would otherwise end the record;
# the line is what lets a finding be reported somewhere a reader can go and look.

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
  Capture = Struct.new(:line, :text)

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
      at = record.index("\t")
      # A record without its separator is skipped rather than half-read: half a
      # capture reads like something the source never said.
      next if at.nil?

      # Interpolated to settle the element type: an array built by a loop keeps
      # its members open, and unescape needs a string.
      found << Capture.new(record[0, at].to_i, unescape("#{record[(at + 1)..-1]}"))
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
