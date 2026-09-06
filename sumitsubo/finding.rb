module Sumitsubo
  # One thing a comparison has to say about one place. The check words it while
  # every part is still in hand, so a finding carries the sentence rather than
  # the pieces to build one from, and every check answers with this one shape.
  #
  # A check answers under `<mechanism>/<check>`, the first half being the word
  # .sumi.json already switches that mechanism by.
  #
  # Nothing is required here. A reading that reached a grammar would cost every
  # check's test its snapshot.
  class Finding < Data.define(:check, :difference, :place, :message)
    # A document its own form refused, worded the way every other finding is
    # worded so a reader meets it in the order they walk the file. The check is
    # the mechanism's, and where and what are the refusal's own.
    def self.refused(check, refusal)
      # The message is interpolated rather than passed on: the send answers
      # boxed, and the constructor a Data synthesizes takes that uncoerced where
      # a user method's parameter of the same type does not. matz/spinel#4348.
      new(check: check, difference: false, place: refusal.place, message: "#{refusal.message}")
    end

    # The comparison was made and the two sides disagree. False says it could
    # not be made at all, which is not a difference about the code.
    def difference?
      difference
    end
  end
end
