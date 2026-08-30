module Sumitsubo
  # One thing a comparison has to say about one place. The rule words it while
  # every part is still in hand, so a finding carries the sentence rather than
  # the pieces to build one from, and every rule answers with this one shape.
  #
  # A rule is named `<specification>/<check>`, the first half being the word
  # .sumi.json already switches that specification by.
  #
  # Nothing is required here. A reading that reached a grammar would cost every
  # rule's test its snapshot.
  Finding = Data.define(:rule, :difference, :place, :message) do
    # The comparison was made and the two sides disagree. False says it could
    # not be made at all, which is not a difference about the code.
    def difference?
      difference
    end
  end
end
