# The record format this binding owns, read back without a parser.
#
# The native side is free to change how it collects captures, but the shape it
# hands over — `match\tname\tline\ttext`, one record per line, text escaped — is
# what every caller reads. Holding it here means a change to it fails on its own
# terms, rather than downstream where the cause looks like a grammar or a query.
#
# Nothing here calls the shim, so this test needs neither the runtime nor a
# grammar: its object never reaches the link.
require "treesitter"

def show(captures)
  captures.map { |capture| "#{capture.match}:#{capture.name}/#{capture.line}/#{capture.text}" }
end

p show(TreeSitter.decode("0\ttext\t31\t# A Customer is billed here.\n1\ttext\t43\t# Not an Invoice.\n"))

# Two captures of one match carry the same number, and are told apart by name.
# The scope arrives before the name it holds, which is position order rather
# than the order the query names them in.
p show(TreeSitter.decode("4\tscope\t2\tmodule Inner\n4\tname\t2\tInner\n"))

# A newline inside a comment is exactly the case the escaping exists for.
p show(TreeSitter.decode("0\ttext\t9\t=begin\\nline two\\n=end\n"))

# The other pairs the escaper writes, including a literal backslash.
p show(TreeSitter.decode("0\ttext\t7\ta\\tb\\rc\\\\d\n"))

# A capture of nothing keeps its record: the split drops the empty tail, so the
# separators alone have to be enough to read it.
p show(TreeSitter.decode("0\tname\t5\t\n"))

# A record short of its separators is skipped rather than half-read.
p show(TreeSitter.decode("5\n"))

# Nothing captured is a legitimate answer, not a failure.
p show(TreeSitter.decode(""))
