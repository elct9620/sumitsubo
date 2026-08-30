# The record format this binding owns, read back without a parser.
#
# The native side is free to change how it collects captures, but the shape it
# hands over — `match\tname\tline\tlast\tstart\tfinish\ttext`, one record per
# line, text escaped — is what every caller reads. Holding it here means a
# change to it fails on its own terms, rather than downstream where the cause
# looks like a grammar or a query.
#
# Nothing here calls the shim, so this test needs neither the runtime nor a
# grammar: its object never reaches the link.
require "treesitter"

def show(captures)
  captures.map do |capture|
    "#{capture.match}:#{capture.name}/#{capture.line}-#{capture.last}" \
      "/#{capture.start}..#{capture.finish}/#{capture.text}"
  end
end

p show(TreeSitter.decode(
  "0\ttext\t31\t31\t612\t640\t# A Customer is billed here.\n" \
  "1\ttext\t43\t43\t871\t888\t# Not an Invoice.\n"
))

# Two captures of one match carry the same number, and are told apart by name.
# The scope arrives before the name it holds, which is position order rather
# than the order the query names them in.
p show(TreeSitter.decode("4\tscope\t2\t4\t18\t42\tmodule Inner\n4\tname\t2\t2\t25\t30\tInner\n"))

# A node spanning several lines says where it closes, so a caller wanting its
# extent is never made to count the newlines back out of the text.
p show(TreeSitter.decode("0\ttext\t9\t11\t120\t145\t=begin\\nline two\\n=end\n"))

# The other pairs the escaper writes, including a literal backslash.
p show(TreeSitter.decode("0\ttext\t7\t7\t3\t10\ta\\tb\\rc\\\\d\n"))

# A capture of nothing keeps its record: the split drops the empty tail, so the
# separators alone have to be enough to read it.
p show(TreeSitter.decode("0\tname\t5\t5\t44\t44\t\n"))

# A record short of its separators is skipped rather than half-read, whether it
# lost all of them or only the ones the extent added.
p show(TreeSitter.decode("5\n"))
p show(TreeSitter.decode("0\tname\t5\ttext without an extent\n"))

# Nothing captured is a legitimate answer, not a failure.
p show(TreeSitter.decode(""))
