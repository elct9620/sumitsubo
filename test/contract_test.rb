require "pathname"
require "sumitsubo/contract"
require "sumitsubo/grammar"
require "sumitsubo/language"
require "sumitsubo/source"
require "sumitsubo/parser/markdown"
require "sumitsubo/specification"

# Nothing under sumitsubo/ names a format, so a test says which it reads. This
# one reads the format definitions are really written in, which is why its
# snapshot is written by hand: the mechanism is checked against the shape a
# person actually wrote rather than one assembled here.
PARSERS = [Sumitsubo::Parser::Markdown.new(Sumitsubo::Grammar)]

# The loader answers where an interface sits as well as what it says. An
# interface nothing claims is a finding about the specification, so the reader
# has to be able to go to the line that registers it.

FIXTURE = "test/fixtures/contract"

# A format this build does not really carry, so that what decides which files
# are specifications is visibly the parsers rather than an extension written
# into the mechanism.
class Other
  SUFFIX = ".spec"

  def reads?(path) = "#{path}".end_with?(SUFFIX)

  def contract(path, languages)
    where = "#{path}"
    Sumitsubo::Specification.new("Other", nil, [], where, { "marker" => ["@other"] }, [
      Sumitsubo::Statement.new("what another format registers", nil, where, 1, {}, [])
    ])
  end
end

def loaded(directory, parsers = PARSERS)
  # A signature is read by the reading that reads the source, so what a
  # definition is checked against is the languages this build carries.
  Sumitsubo::Contract.load(directory, Sumitsubo::Language, parsers)
end

def claim(path, line, keyword, name)
  Sumitsubo::Contract::Claim.new(
    path, line, Sumitsubo::Contract::Name.new(keyword, name)
  )
end

def fails
  yield
rescue Sumitsubo::Error => e
  puts e.message
end

# @behavior T-001
puts "--- what the directory registers, and where ---"
definitions = loaded("#{FIXTURE}/.spec/contract")
definitions.each do |definition|
  puts "#{definition.key} #{Sumitsubo::Contract.marker_of(definition)} #{definition.includes.inspect}"
  definition.statements.each do |interface|
    puts "  #{interface.path}:#{interface.line} #{interface.key} — #{interface.text}"
  end
end
# Two definitions share `@route`, and the word answers once.
# @behavior T-003
puts "--- the words to look for ---"
puts Sumitsubo::Contract.keywords(definitions).inspect

# An `include` is the boundary of what a definition answers for rather than a
# list of files to read: two definitions over one tree reach different files,
# and the union of them is only what gets read once.
# @behavior T-035
puts "--- what each definition's include reaches ---"
reach = Sumitsubo::Contract.reach(definitions, Pathname.new(FIXTURE), [])
definitions.each { |definition| puts "  #{definition.key} #{reach[definition.path].keys.sort.inspect}" }

# @behavior T-014
puts "--- the files to look in ---"
puts Sumitsubo::Contract.scope(reach).inspect

# `init` is registered by the CLI definition, whose include reaches only src.
# A claim of it from the controller names the contract without being able to
# implement it, so the contract stands unclaimed.
astray = [claim("test/fixtures/contract/app/controller.rb", 4, "@command", "init")]

# @behavior T-036
puts "--- a contract claimed only from outside its own definition ---"
witnessing = Sumitsubo::Contract.witnessing(definitions, astray, reach)
Sumitsubo::Contract.unclaimed(definitions, witnessing).each do |finding|
  puts "  #{finding.path}:#{finding.line} #{finding.message}"
end

# @behavior T-037
puts "--- and the claim that could not implement it ---"
Sumitsubo::Contract.misplaced(definitions, astray, reach).each do |finding|
  puts "  #{finding.path}:#{finding.line} #{finding.message}"
end

# @behavior T-002
puts "--- a directory nobody wrote registers no contracts ---"
p loaded("#{FIXTURE}/.spec/absent")

# The marker is the namespace, so one name may sit under two of them.
# @behavior T-004
puts "--- the same name under two markers is two contracts ---"
p loaded("#{FIXTURE}/shared").length

# @behavior T-005
puts "--- one name twice under one marker leaves a claim nothing to resolve to ---"
fails { loaded("#{FIXTURE}/duplicate") }

# @behavior T-006
puts "--- a contract with no name cannot be claimed at all ---"
fails { loaded("#{FIXTURE}/nameless") }

# A marker is what a route needs because nothing in Ruby points at one. A
# definition naming none is read from the syntax tree instead.
# @behavior T-007
puts "--- a definition with no marker is read from the syntax tree ---"
p Sumitsubo::Contract.defined(loaded("#{FIXTURE}/nomarker")).length

# The syntax tree reading shares one namespace, so a name twice in it is the
# same ambiguity — said without a marker in front of it.
# @behavior T-017
puts "--- one name twice with no marker ---"
fails { loaded("#{FIXTURE}/twice") }


# `Store.open` is registered as internal and answers here all the same: what
# internal keeps it out of is the document, not the comparison.
# @behavior T-016 T-018
puts "--- an interface the syntax tree does not define ---"
Sumitsubo::Contract.undefined(
  loaded("#{FIXTURE}/nomarker"), { "ruby" => [Sumitsubo::Source::Declaration.new("src/commands.rb", 3, "init", [])] }
).each do |finding|
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end

# `verify` is registered by a definition reaching src alone. A class merely
# spelling that name asserts nothing, so the declaration from the controller
# is left out and no finding is written about it — where a claim from outside
# would have answered for itself.
# @behavior T-038
puts "--- a declaration outside the definition registering its name ---"
spelled = loaded("#{FIXTURE}/nomarker")
Sumitsubo::Contract.defining(
  spelled,
  { "ruby" => [Sumitsubo::Source::Declaration.new("#{FIXTURE}/src/commands.rb", 3, "verify", []),
               Sumitsubo::Source::Declaration.new("#{FIXTURE}/app/controller.rb", 9, "verify", [])] },
  Sumitsubo::Contract.reach(spelled, Pathname.new(FIXTURE), [])
).each do |language, names|
  names.each { |name| puts "  #{language} #{name.path}:#{name.line} #{name.name}" }
end


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
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end

# @behavior T-010 T-011
puts "--- a claim resolving to no contract, and one naming none at all ---"
Sumitsubo::Contract.unresolved(definitions, claims).each do |finding|
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end

# @behavior T-012
puts "--- one contract claimed in two places ---"
Sumitsubo::Contract.duplicated(definitions, claims).each do |finding|
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end

# What a reading answers, since that is what the mechanism is really handed.
def takes(name, kind = "positional", optional = false)
  Sumitsubo::Source::Param.new(name, kind, optional)
end

def declares(line, name, params)
  Sumitsubo::Source::Declaration.new("src/store.rb", line, name, params)
end

registered = loaded("#{FIXTURE}/params")

# The shape is whatever the signature declares, so a kind nobody wrote is the
# one that spelling gives it and `Store` registers no shape at all — which is
# not the same as `Store#write` registering that it takes none.
# @behavior T-019
puts "--- the shape a contract registers ---"
definition = registered[0]
definition.statements.each do |interface|
  params = Sumitsubo::Contract.shape_of(definition, interface, Sumitsubo::Language)
  shape = params.nil? ? "registers no shape" : Sumitsubo::Contract.spell(params)
  puts "  #{interface.key} #{shape}"
end

# `Store#read` and `Store#write` are defined as registered, and `Store` is a
# scope with no call to describe, so only `Store.open` answers.
# @behavior T-020 T-021
puts "--- an interface defined with another shape ---"
Sumitsubo::Contract.mismatched(registered, { "ruby" => [
  declares(2, "Store.open", [takes("path")]),
  declares(6, "Store#read", [takes("key", "keyword"), takes(nil, "block", true)]),
  declares(9, "Store#write", []),
  declares(12, "Store", nil)
] }, Sumitsubo::Language).each do |finding|
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end

# `Store.open` is defined twice with one shape, which is one way in; `Store#read`
# is defined with two, which is an entrance the specification does not describe.
# @behavior T-022 T-023
puts "--- one name defined with two shapes ---"
twice = { "ruby" => [
  declares(2, "Store.open", [takes("path")]),
  declares(20, "Store.open", [takes("path")]),
  declares(6, "Store#read", [takes("key", "keyword"), takes(nil, "block", true)]),
  declares(24, "Store#read", [takes("key", "keyword")])
] }
Sumitsubo::Contract.conflicting(registered, twice).each do |finding|
  puts "#{finding.path}:#{finding.line} #{finding.message}"
end


# Which files in the directory are specifications is the parsers' answer, so
# `notes.txt` and a definition left in a format this build no longer reads are
# both passed over rather than refused: the directory is the project's to keep
# other things in. There is one real format left, which is why the second has
# to be stood in for.
# @behavior T-039
puts "--- which files a directory holds that this build can read ---"
Pathname.new("#{FIXTURE}/formats").glob("*").map { |file| "#{file}" }.sort.each do |file|
  puts "  holding #{file}"
end
loaded("#{FIXTURE}/formats", PARSERS + [Other.new]).each do |definition|
  puts "  #{definition.path} #{definition.key} #{definition.statements.map { |one| one.key }.inspect}"
end

# A name is spelled the way one language spells it, so the language is the
# namespace the other reading registers under: two of them may spell one name
# and mean nothing alike, and neither definition is ambiguous.
# @behavior T-040
puts "--- the same name under two languages ---"
spelling = loaded("#{FIXTURE}/spelled")
spelling.each do |definition|
  definition.statements.each do |interface|
    puts "  #{definition.key} #{Sumitsubo::Contract.language_of(definition, interface)} #{interface.key}"
  end
end

# Each definition's files are read as the language its own contracts are
# spelled in, so a file under two of them is read once for each.
puts "--- and each definition's files are read as its own language ---"
Sumitsubo::Contract.readings_in(
  spelling, Sumitsubo::Contract.reach(spelling, Pathname.new(FIXTURE), [])
).each { |reading| puts "  #{reading.path} as #{reading.language}" }

# The Ruby contract is defined in Ruby and the Rust one is not: a declaration
# the other language answered does not define it, however alike they spell.
# @behavior T-041
puts "--- a declaration another language spells alike ---"
Sumitsubo::Contract.undefined(
  spelling, { "ruby" => [Sumitsubo::Source::Declaration.new("src/store.rb", 2, "Store::Handle", nil)] }
).each do |finding|
  puts "  #{finding.path}:#{finding.line} #{finding.message}"
end
