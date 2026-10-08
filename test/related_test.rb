require "sumitsubo/related"
require "sumitsubo/relation/repository"
require "sumitsubo/specification"

# What specifications say of one another, kept as relations. The statements
# are built here rather than read, since what is pinned is what a key written
# among the attributes becomes, not how a document is read.
NAMES = ["glossary", "contract", "behavior"]

def scenario(key, attributes)
  Sumitsubo::Statement.new(key, nil, [], "relate.md", 1, attributes, [])
end

def kept(statements)
  relations = Sumitsubo::Relation::Repository.new
  Sumitsubo::Related.relate("behavior", statements, NAMES, relations)
  [Sumitsubo::Relation::RELATES, Sumitsubo::Relation::REFINES].each do |kind|
    relations.of(kind).each do |one|
      puts "  #{one.kind} #{one.subject.mechanism} #{one.subject.key} -> #{one.object.mechanism} #{one.object.key}"
    end
  end
end

# @behavior RL-001
puts "--- a scenario relating to another of its own ---"
kept([scenario("IN-001", { "relates" => ["IN-002"] })])

# The name is taken only where it is one this build keeps, so a key that
# happens to hold a space is still kept by the mechanism writing it.
# @behavior RL-002
puts "--- a key naming another mechanism's statement ---"
kept([scenario("IN-001", { "relates" => ["contract inspect", "nobody inspect"] })])

# @behavior RL-003
puts "--- a refinement runs from the narrower statement ---"
kept([scenario("IN-002", { "refines" => ["IN-001"] })])
