require "pathname"
require "sumitsubo/contract"

# The loader answers where an interface sits as well as what it says. An
# interface nothing claims is a finding about the specification, so the reader
# has to be able to go to the line that registers it.
#
# Nothing here reaches the grammar, so this snapshot can be regenerated. See
# the Build section of CLAUDE.md for what that buys.

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

# @behavior T-007
puts "--- a definition with no marker says nothing to look for ---"
fails { Sumitsubo::Contract.load("#{FIXTURE}/nomarker") }

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
