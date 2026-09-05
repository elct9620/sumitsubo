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
  class Finding < Data.define(:rule, :difference, :place, :message)
    # A document its own form refused, worded the way every other finding is
    # worded so a reader meets it in the order they walk the file. The rule is
    # the mechanism's, and where and what are the refusal's own.
    def self.refused(rule, refusal)
      # The message is written out rather than passed on: a refusal arrives out
      # of the several a document was refused for, which Spinel holds untyped,
      # and what a member answers there is boxed. Passing it on stops the build.
      #
      # Nobody has reduced this to a file of its own, so there is no ticket to
      # follow: six standalone shapes carrying what looked like the cause all
      # compiled. Take the interpolation out to see it again.
      new(rule: rule, difference: false, place: refusal.place, message: "#{refusal.message}")
    end

    # The comparison was made and the two sides disagree. False says it could
    # not be made at all, which is not a difference about the code.
    def difference?
      difference
    end
  end
end
