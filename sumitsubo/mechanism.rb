require "sumitsubo/mechanism/seed"
require "sumitsubo/mechanism/glossary"
require "sumitsubo/mechanism/contract"
require "sumitsubo/mechanism/behavior"

module Sumitsubo
  # A mechanism is one kind of specification and the checks it is verified by.
  # It names the word .sumi.json switches it by, lays down a seed to start a
  # reference line from, says how a file of its own is read, and runs its
  # checks over what the two repositories hand back. A check is named for what
  # it finds, so the mechanism is what puts its own word in front of one.
  #
  # A mechanism registers by being in the list: Spinel decides what an
  # executable carries when it is built, so there is no hook to register
  # through.
  #
  # What a build carries arrives as those two repositories rather than being
  # named here, the way the revision does. Nothing in this graph reaches a
  # grammar or names a format, which is what leaves a snapshot of it one
  # `--regen` can write.
  module Mechanism
    # The order a run reaches them in, which is the order init lays them down,
    # and the order the README sets them out in.
    ALL = [Glossary.new, Contract.new, Behavior.new]
  end
end
