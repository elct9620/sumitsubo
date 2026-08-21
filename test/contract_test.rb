require "pathname"
require "sumitsubo/contract"

# The loader answers where an interface sits as well as what it says. An
# interface nothing claims is a finding about the specification, so the reader
# has to be able to go to the line that registers it.
#
# Nothing here reaches the grammar, so --regen can still write this snapshot.

FIXTURE = "test/fixtures/contract"

def claim(path, line, keyword, name)
  Sumitsubo::Contract::Claim.new(path, line, keyword, name)
end

def fails
  yield
rescue Sumitsubo::Contract::Error => e
  puts e.message
end

# @behavior T-001
puts "--- what the directory registers, and where ---"
definitions = Sumitsubo::Contract.load("#{FIXTURE}/.spec/contract")
definitions.each do |definition|
  puts "#{definition.name} #{definition.marker} #{definition.includes.inspect}"
  definition.interfaces.each do |interface|
    puts "  #{interface.path}:#{interface.line} #{interface.name} — #{interface.description}"
  end
end
# Two definitions share `@route`, and the word answers once.
# @behavior T-003
puts "--- the words to look for ---"
puts Sumitsubo::Contract.keywords(definitions).inspect

# @behavior T-014
puts "--- the files to look in ---"
puts Sumitsubo::Contract.scope(definitions, Pathname.new(FIXTURE)).inspect

# @behavior T-002
puts "--- a directory nobody wrote registers no contracts ---"
p Sumitsubo::Contract.load("#{FIXTURE}/.spec/absent")

# The marker is the namespace, so one name may sit under two of them.
# @behavior T-004
puts "--- the same name under two markers is two contracts ---"
p Sumitsubo::Contract.load("#{FIXTURE}/shared").length

# @behavior T-005
puts "--- one name twice under one marker leaves a claim nothing to resolve to ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/duplicate") }

# @behavior T-006
puts "--- a contract with no name cannot be claimed at all ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/nameless") }

# A marker is what a route needs because nothing in Ruby points at one. A
# definition naming none is read from the syntax tree instead.
# @behavior T-007
puts "--- a definition with no marker is read from the syntax tree ---"
p Sumitsubo::Contract.defined(Sumitsubo::Contract.load("#{FIXTURE}/nomarker")).length

# The syntax tree reading shares one namespace, so a name twice in it is the
# same ambiguity — said without a marker in front of it.
# @behavior T-017
puts "--- one name twice with no marker ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/twice") }

# @behavior T-015
puts "--- a contract no Ruby definition can be ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/unresolvable") }

# `Store.open` is registered as internal and answers here all the same: what
# internal keeps it out of is the document, not the comparison.
# @behavior T-016 T-018
puts "--- an interface the syntax tree does not define ---"
Declared = Struct.new(:path, :line, :name, :params)
Sumitsubo::Contract.undefined(
  Sumitsubo::Contract.load("#{FIXTURE}/nomarker"), [Declared.new("src/commands.rb", 3, "init", [])]
).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Contract.describe_undefined(finding)}"
end

# @behavior T-008
puts "--- and neither is a specification that will not parse ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/broken") }

claims = [
  claim("src/commands.rb", 3, "@command", "verify"),
  claim("app/controller.rb", 5, "@route", "GET /users/:id"),
  claim("app/legacy.rb", 9, "@route", "GET /users/:id"),
  claim("src/commands.rb", 20, "@command", "render"),
  claim("src/commands.rb", 24, "@command", "")
]

# @behavior T-009
puts "--- an interface nothing claims ---"
Sumitsubo::Contract.unclaimed(definitions, claims).each do |finding|
  puts "#{finding.path}:#{finding.line} #{Sumitsubo::Contract.describe_unclaimed(finding)}"
end

# @behavior T-010 T-011
puts "--- a claim resolving to no contract, and one naming none at all ---"
Sumitsubo::Contract.unresolved(definitions, claims).each do |unresolved|
  puts "#{unresolved.path}:#{unresolved.line} #{Sumitsubo::Contract.describe_unresolved(unresolved)}"
end

# @behavior T-012
puts "--- one contract claimed in two places ---"
Sumitsubo::Contract.duplicated(definitions, claims).each do |pair|
  puts "#{pair[0].path}:#{pair[0].line} #{Sumitsubo::Contract.describe_duplicated(pair)}"
end

# @behavior T-013
puts "--- the document a definition becomes ---"
puts Sumitsubo::Contract.render(definitions[1])

Takes = Struct.new(:name, :kind, :optional)

def takes(name, kind = "positional", optional = false)
  Takes.new(name, kind, optional)
end

def declares(line, name, params)
  Declared.new("src/store.rb", line, name, params)
end

registered = Sumitsubo::Contract.load("#{FIXTURE}/params")

# A kind nobody named is the one a bare name says, and `Store#touch` registers
# no shape at all — which is not the same as `Store#write` registering that it
# takes none.
# @behavior T-019
puts "--- the shape a contract registers ---"
registered[0].interfaces.each do |interface|
  shape = interface.params.nil? ? "registers no shape" : Sumitsubo::Contract.spell(interface.params)
  puts "  #{interface.name} #{shape}"
end

# `Store#read` and `Store#write` are defined as registered, and `Store#touch`
# registers no shape, so only `Store.open` answers.
# @behavior T-020 T-021
puts "--- an interface defined with another shape ---"
Sumitsubo::Contract.mismatched(registered, [
  declares(2, "Store.open", [takes("path")]),
  declares(6, "Store#read", [takes("key", "keyword"), takes(nil, "block", true)]),
  declares(9, "Store#write", []),
  declares(12, "Store#touch", [takes("at")])
]).each do |mismatch|
  puts "#{mismatch.path}:#{mismatch.line} #{Sumitsubo::Contract.describe_mismatched(mismatch)}"
end

# `Store.open` is defined twice with one shape, which is one way in; `Store#read`
# is defined with two, which is an entrance the specification does not describe.
# @behavior T-022 T-023
puts "--- one name defined with two shapes ---"
twice = [
  declares(2, "Store.open", [takes("path")]),
  declares(20, "Store.open", [takes("path")]),
  declares(6, "Store#read", [takes("key", "keyword"), takes(nil, "block", true)]),
  declares(24, "Store#read", [takes("key", "keyword")])
]
Sumitsubo::Contract.conflicting(registered, twice).each do |pair|
  puts "#{pair[0].path}:#{pair[0].line} #{Sumitsubo::Contract.describe_conflicting(pair)}"
end

# Nothing but the syntax tree answers what a definition takes, so parameters
# under a marker would be a promise nobody holds.
# @behavior T-024
puts "--- parameters registered under a marker ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/marked") }

# `"name"` names three things here: the kind, each contract, and each
# parameter. `loose` is spelled the same as a parameter of the contract before
# it, and `Store` the same as the kind — both answer at their own line rather
# than at the first one carrying the word.
# @behavior T-025
puts "--- a name the specification uses at more than one depth ---"
Sumitsubo::Contract.load("#{FIXTURE}/collide")[0].interfaces.each do |interface|
  puts "  #{interface.path}:#{interface.line} #{interface.name}"
end
