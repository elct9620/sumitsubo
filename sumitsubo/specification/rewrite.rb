# `Specification` is assigned rather than declared, so a file reopening it
# before that assignment runs loses what it added. Nothing here calls into it —
# the require is the order.
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    # One line a document writes otherwise than a reference line is written,
    # and what it would be written as.
    #
    # The finding is what a run only reporting answers with, and the text is
    # what a run rewriting puts in the line's stead. They are one thing said
    # twice, held together so that what `fmt` reports and what it would do
    # cannot drift apart.
    Rewrite = Struct.new(:finding, :line, :text)
  end
end
