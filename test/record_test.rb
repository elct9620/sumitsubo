require "pathname"
require "sumitsubo/reach"
require "sumitsubo/relation"
require "sumitsubo/relation/repository"
require "sumitsubo/source"
require "sumitsubo/specification"
require "sumitsubo/check/reference"
require "sumitsubo/mechanism/behavior/record"
require "sumitsubo/mechanism/contract/record"
require "sumitsubo/mechanism/glossary/record"

# What each stage keeps, handed in as data and read back the way the next one
# asks. Nothing reaches the grammar, so `--regen` can write the snapshot.

root = Pathname.new("/tmp/sumi_record_test_#{Process.pid}")
root.rmtree if root.exist?
back = Dir.pwd
root.mkpath
Dir.chdir(root)
base = Pathname.pwd
["app/order.rb", "app/billing/charge.rb", "test/order_test.rb"].each do |path|
  (base / path).dirname.mkpath
  (base / path).write("# a file\n")
end

def statement(key, text, path, line, children = [], attributes = {})
  Sumitsubo::Statement.new(key, text, [], path, line, attributes, children)
end

def spec(path, globs)
  includes = globs.map { |one| statement(one, nil, path, 5) }
  Sumitsubo::Specification.new("Spec", nil, includes, path, {}, [])
end

def reference(mechanism, key)
  Sumitsubo::Relation::Reference.new(mechanism: mechanism, key: key)
end

# @behavior K-001
puts "--- what each specification reaches ---"
orders = spec(".spec/behavior/orders.md", ["app/*.rb", "test/*.rb"])
billing = spec(".spec/behavior/billing.md", ["app/billing/*.rb"])
relations = Sumitsubo::Relation::Repository.new
Sumitsubo::Reach.keep([orders, billing], base, [], relations, Pathname.pwd)
reach = Sumitsubo::Reach.of([orders, billing], relations)
[orders, billing].each { |one| puts "  #{one.path} #{reach[one.path].keys.sort.inspect}" }
puts "  read once: #{Sumitsubo::Reach.files(reach).inspect}"

# @behavior K-002
puts "--- the keys one comment names ---"
marks = Sumitsubo::Relation::Repository.new
[["O-001", 1, 1], ["O-002", 2, 1], ["O-001", 3, 1], ["O-003", 7, 7]].each do |mark|
  claim = Sumitsubo::Source::Claim.new("test/order_test.rb", mark[1], mark[2], "@behavior", mark[0])
  marks.add(Sumitsubo::Relation.claim(claim, reference("behavior", mark[0])))
end
p marks.keys_in([Sumitsubo::Relation::CLAIM], "behavior", "test/order_test.rb", 1)
p marks.keys_in([Sumitsubo::Relation::CLAIM], "behavior", "test/order_test.rb", 7)

# @behavior K-003
puts "--- a claim read back for a check ---"
claims = Sumitsubo::Relation::Repository.new
command = Sumitsubo::Source::Claim.new("app/order.rb", 9, 9, "@command", "verify")
claims.add(Sumitsubo::Relation.claim(command, reference("contract", "verify")))
Sumitsubo::Mechanism::Contract.read(claims.of_mechanism(Sumitsubo::Relation::CLAIM, "contract")).each do |one|
  puts "  contract #{one.key.spoken} at #{one.place.spoken} said #{one.said}"
end
scenario = Sumitsubo::Source::Claim.new("test/order_test.rb", 3, 3, "@behavior", "O-001")
claims.add(Sumitsubo::Relation.claim(scenario, reference("behavior", "O-001")))
Sumitsubo::Mechanism::Behavior.claims_in(claims, "behavior").each do |one|
  puts "  scenario #{one.id} at #{one.path}:#{one.line}"
end

# @behavior K-004
puts "--- a declaration read back under its language ---"
declared = Sumitsubo::Relation::Repository.new
[["typescript", "Order", 1], ["tsx", "Order", 1], ["typescript", "Charge", 3]].each do |read|
  language = read[0]
  name = read[1]
  found = Sumitsubo::Source::Declaration.new(path: "app/order.ts", line: read[2], name: name, shape: nil)
  spelled = Sumitsubo::Source::Spelling.new(declaration: found, language: language)
  declared.add(Sumitsubo::Relation.declares(spelled, reference("contract", name)))
end
held = Sumitsubo::Mechanism::Contract.declarations_from(declared.of_mechanism(Sumitsubo::Relation::DECLARES, "contract"))
held.keys.each { |language| puts "  #{language} #{held[language].map { |one| "#{one.name}:#{one.line}" }.inspect}" }

# @behavior K-005
puts "--- a mention read back with its reason ---"
mentioned = Sumitsubo::Relation::Repository.new
word = Sumitsubo::Source::Mention.new(path: "app/order.rb", line: 2, used: "Purchase")
mentioned.add(Sumitsubo::Relation.mentions(word, reference("glossary", "Order")))
rejected = statement("Purchase", "Order is what the domain calls it.", ".spec/glossary.md", 12)
scope = { "app/order.rb" => { "Order" => statement("Order", "What a customer asks for.", ".spec/glossary.md", 9, [rejected]) } }
Sumitsubo::Mechanism::Glossary.mentions_from(mentioned.of_mechanism(Sumitsubo::Relation::MENTIONS, "glossary"), scope, base, Pathname.pwd).each do |one|
  puts "  #{one.path}:#{one.line} #{one.term} rejects #{one.used}: #{one.reason}"
end

# @behavior K-006
puts "--- a written key naming none, or more than one ---"
writer = statement("O-001", "An order is placed", ".spec/behavior/orders.md", 9)
nothing = Sumitsubo::Relation.relates(reference("behavior", "O-001"), reference("contract", "absent"))
def said(finding)
  puts "  #{finding.place.spoken}: #{finding.check}: #{finding.message}"
end
said(Sumitsubo::Check::Reference.unresolved(nothing, writer))
twice = Sumitsubo::Relation.relates(reference("behavior", "O-001"), reference("contract", "inspect"))
found = [statement("inspect", nil, ".spec/contract/cli.md", 11), statement("inspect", nil, ".spec/contract/routes.md", 11)]
said(Sumitsubo::Check::Reference.ambiguous(twice, writer, found))

Dir.chdir(back)
root.rmtree
