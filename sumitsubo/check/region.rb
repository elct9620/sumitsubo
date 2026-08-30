require "sumitsubo/check"
require "sumitsubo/finding"
require "sumitsubo/place"

module Sumitsubo
  module Check
    # What the words a person wrote are compared against. A mention is one use
    # of a word standing on a line; an ignore is the exemption a specification
    # wrote for one. Both arrive from the mechanism that read them, and both
    # answer `key` — what an ignore names a mention by.
    module Region
      # A word the vocabulary turns down, standing where it was turned down.
      # A mention the specification set aside is not reported: which side is
      # wrong is not the tool's to decide, and there the project has decided.
      class Rejected
        def initialize(rule)
          @rule = rule
        end

        # An ignore names a mention by its path under the base, and a finding
        # answers at the path a reader started the run from. This is where a
        # mention stops being a candidate, so this is where the two are told
        # apart.
        def run(mentions, aside, base)
          found = []
          mentions.each do |mention|
            next unless aside[mention.key].nil?

            found.push(Finding.new(
              rule: @rule, difference: true,
              place: Place.of(base / mention.path, mention.line),
              message: "#{mention.term} rejects #{mention.used}: #{mention.reason}"
            ))
          end
          found
        end
      end

      # An exemption that no longer names anything — the line moved, or the
      # wording was fixed. Nothing else notices, so one left behind outlives
      # what it was for; the run refuses to certify rather than pass.
      class Stale
        def initialize(rule)
          @rule = rule
        end

        def run(mentions, aside, path)
          met = {}
          mentions.each { |mention| met[mention.key] = true }
          found = []
          aside.keys.sort.each do |key|
            next unless met[key].nil?

            ignore = aside[key]
            found.push(Finding.new(
              rule: @rule, difference: false,
              place: Place.of(path, ignore.line),
              message: "nothing at #{ignore.at} has #{ignore.term} rejecting " \
                       "#{ignore.used}; the line moved or the wording was fixed"
            ))
          end
          found
        end
      end
    end
  end
end
