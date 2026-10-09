require "pathname"
require "sumitsubo/reach"
require "sumitsubo/relation"
require "sumitsubo/relation/repository"
require "sumitsubo/source"
require "sumitsubo/specification"
require "sumitsubo/check/related"
require "sumitsubo/definition/kept"
require "sumitsubo/vocabulary/kept"

# What each stage keeps, handed in as data and read back the way the next one
# asks. Nothing reaches the grammar, so `--regen` can write the snapshot.

root = Pathname.new("/tmp/sumi_kept_test_#{Process.pid}")
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
Sumitsubo::Reach.keep([orders, billing], base, [], relations)
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
p marks.named_in([Sumitsubo::Relation::CLAIM], "behavior", "test/order_test.rb", 1)
p marks.named_in([Sumitsubo::Relation::CLAIM], "behavior", "test/order_test.rb", 7)

# Spinel 2026.09.12, and master at 7232a802, cannot type a scenario's claims
# read back in a program this small, so only the contract's half is asked here;
# verify_test asks the scenario's through a whole run. Ask both once it can.
# @behavior K-003
puts "--- a claim read back for a check ---"
claims = Sumitsubo::Relation::Repository.new
command = Sumitsubo::Source::Claim.new("app/order.rb", 9, 9, "@command", "verify")
claims.add(Sumitsubo::Relation.claim(command, reference("contract", "verify")))
Sumitsubo::Definition.read(claims.naming(Sumitsubo::Relation::CLAIM, "contract")).each do |one|
  puts "  contract #{one.key.spoken} at #{one.place.spoken} said #{one.said}"
end

# @behavior K-004
puts "--- a declaration read back under its language ---"
declared = Sumitsubo::Relation::Repository.new
[["typescript", "Order", 1], ["tsx", "Order", 1], ["typescript", "Charge", 3]].each do |read|
  language = read[0]
  name = read[1]
  found = Sumitsubo::Source::Declaration.new(path: "app/order.ts", line: read[2], name: name, shape: nil)
  spelled = Sumitsubo::Source::Spelled.new(declaration: found, language: language)
  declared.add(Sumitsubo::Relation.declares(spelled, reference("contract", name)))
end
held = Sumitsubo::Definition.declared_from(declared.naming(Sumitsubo::Relation::DECLARES, "contract"))
held.keys.each { |language| puts "  #{language} #{held[language].map { |one| "#{one.name}:#{one.line}" }.inspect}" }

# @behavior K-005
puts "--- a mention read back with its reason ---"
mentioned = Sumitsubo::Relation::Repository.new
word = Sumitsubo::Source::Mention.new(path: "app/order.rb", line: 2, used: "Purchase")
mentioned.add(Sumitsubo::Relation.mentions(word, reference("glossary", "Order")))
rejected = statement("Purchase", "Order is what the domain calls it.", ".spec/glossary.md", 12)
scope = { "app/order.rb" => { "Order" => statement("Order", "What a customer asks for.", ".spec/glossary.md", 9, [rejected]) } }
Sumitsubo::Vocabulary.mentioned(mentioned.naming(Sumitsubo::Relation::MENTIONS, "glossary"), scope, base).each do |one|
  puts "  #{one.path}:#{one.line} #{one.term} rejects #{one.used}: #{one.reason}"
end

# @behavior K-006
puts "--- a written key naming none, or more than one ---"
writer = statement("O-001", "An order is placed", ".spec/behavior/orders.md", 9)
nothing = Sumitsubo::Relation.relates(reference("behavior", "O-001"), reference("contract", "absent"))
def said(finding)
  puts "  #{finding.place.spoken}: #{finding.check}: #{finding.message}"
end
said(Sumitsubo::Check::Related.unresolved(nothing, writer))
twice = Sumitsubo::Relation.relates(reference("behavior", "O-001"), reference("contract", "inspect"))
found = [statement("inspect", nil, ".spec/contract/cli.md", 11), statement("inspect", nil, ".spec/contract/routes.md", 11)]
said(Sumitsubo::Check::Related.ambiguous(twice, writer, found))

Dir.chdir(back)
root.rmtree
