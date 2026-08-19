# The record format this binding owns, read back without a parser.
#
# The native side is free to change how it collects captures, but the shape it
# hands over — `line\ttext`, one record per line, text escaped — is what every
# caller reads. Holding it here means a change to it fails on its own terms,
# rather than downstream where the cause looks like a grammar or a query.
#
# Nothing here calls the shim, so this test needs neither the runtime nor a
# grammar: its object never reaches the link.
require "treesitter"

def show(captures)
  captures.map { |capture| "#{capture.line}/#{capture.text}" }
end

p show(TreeSitter.decode("31\t# A Customer is billed here.\n43\t# Not an Invoice.\n"))

# A newline inside a comment is exactly the case the escaping exists for.
p show(TreeSitter.decode("9\t=begin\\nline two\\n=end\n"))

# The other pairs the escaper writes, including a literal backslash.
p show(TreeSitter.decode("7\ta\\tb\\rc\\\\d\n"))

# A record without its separator is skipped rather than half-read.
p show(TreeSitter.decode("5\n"))

# Nothing captured is a legitimate answer, not a failure.
p show(TreeSitter.decode(""))
