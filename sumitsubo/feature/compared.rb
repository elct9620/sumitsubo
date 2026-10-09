require "pathname"
require "sumitsubo/error"
require "sumitsubo/place"
require "sumitsubo/finding"
require "sumitsubo/check"
require "sumitsubo/reach"
require "sumitsubo/source/repository"
require "sumitsubo/relation"

module Sumitsubo
  # What a feature hands the Behavior mechanism's checks.
  module Feature
    # A claim carrying nothing after the marker names no scenario at all, which
    # is a different thing to say than an id that resolves to none, so the two
    # are answered apart.
    def self.nameless(claims)
      found = []
      claims.each do |claim|
        next unless claim.id.empty?

        found.push(Check::Made.new(key: claim.key, place: claim.place, said: claim.said))
      end
      found
    end

    def self.named(claims)
      found = []
      claims.each { |claim| found.push(claim) unless claim.id.empty? }
      found
    end

    # Every scenario a claim could name, said the way a claim says it.
    def self.stated_in(features)
      found = []
      features.each do |feature|
        feature.statements.each do |scenario|
          found.push(Check::Stated.new(
            key: scenario.key,
            place: Place.of(scenario.path, scenario.line),
            said: "#{MARKER} #{scenario.key}",
            unverifiable: Check.unverifiable(scenario.attributes)
          ))
        end
      end
      found
    end

    # The claims that can witness: each sitting among the files the feature
    # declaring its scenario answers for. Filtering once is what leaves the
    # reading below unchanged — a scenario is claimed by the claims that count.
    # A claim naming a scenario the feature declaring it does not reach. The
    # id resolves, so neither side is wrong about the behavior; what could not
    # be made is the comparison, since nothing among the files that feature
    # answers for witnesses the scenario.
    #
    # Saying nothing about it would leave the scenario reported as claimed
    # nowhere with the claim in plain sight.
    # Which specification declares each scenario, so a claim can be asked
    # whether it sits where that specification can see it. One id belongs to
    # one feature, which is what refuse_ambiguity guarantees.
    def self.declaring_in(features)
      found = {}
      features.each do |feature|
        feature.statements.each { |scenario| found[scenario.key] = feature.path }
      end
      found
    end
  end
end
