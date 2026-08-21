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
p Sumitsubo::Contract.declared(Sumitsubo::Contract.load("#{FIXTURE}/nomarker")).length

# The syntax tree reading shares one namespace, so a name twice in it is the
# same ambiguity — said without a marker in front of it.
# @behavior T-017
puts "--- one name twice with no marker ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/twice") }

# @behavior T-015
puts "--- a contract no Ruby declaration can be ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/unresolvable") }

# `Store.open` is registered as internal and answers here all the same: what
# internal keeps it out of is the document, not the comparison.
# @behavior T-016 T-018
puts "--- an interface the syntax tree does not declare ---"
Declared = Struct.new(:name)
Sumitsubo::Contract.undefined(
  Sumitsubo::Contract.load("#{FIXTURE}/nomarker"), [Declared.new("init")]
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
