require "pathname"
require "sumitsubo"
require "sumitsubo/language"

# render writes into the working directory, so the run has to happen somewhere
# other than the repository it is testing.
root = Pathname.new("/tmp/sumi_render_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath

back = Dir.pwd
Dir.chdir(root.to_s)

cli = Sumitsubo::CLI.new(Sumitsubo::BUILD_REV, Sumitsubo::Language)

# @behavior R-004
puts "--- a project with no specification renders nothing ---"
puts "exit=#{cli.run(["render"])}"

(Pathname.pwd / ".spec" / "behavior").mkpath
File.write(".spec/glossary.json", <<~JSON)
  {
    "glossary": [
      {
        "include": ["app/**/*.rb"],
        "terms": [
          {
            "term": "Order",
            "definition": "What a customer asks us to fulfil.",
            "not": [
              { "term": "Purchase", "reason": "Order is what the domain calls it." }
            ]
          },
          {
            "term": "Refund",
            "definition": "Money returned after an order is settled."
          }
        ]
      }
    ]
  }
JSON
File.write(".spec/behavior/checkout.json", <<~JSON)
  {
    "name": "Checkout",
    "description": "Taking payment for an order.",
    "include": ["test/*_test.rb"],
    "scenarios": [
      {
        "id": "K-001",
        "title": "A card the bank declines",
        "given": ["an order awaiting payment", "a card the bank will decline"],
        "when": "checkout runs",
        "then": "the order is left awaiting payment"
      }
    ]
  }
JSON

File.write(".spec/behavior/refund.json", <<~JSON)
  {
    "name": "Refund",
    "description": "Giving money back for a settled order.",
    "include": ["test/*_test.rb"],
    "scenarios": [
      {
        "id": "F-001",
        "title": "A refund larger than the order",
        "given": ["a settled order"],
        "when": "a refund larger than that order is asked for",
        "then": "the order is left settled"
      }
    ]
  }
JSON

(Pathname.pwd / ".spec" / "contract").mkpath
File.write(".spec/contract/cli.json", <<~JSON)
  {
    "name": "CLI",
    "description": "The commands the executable answers.",
    "marker": "@command",
    "include": ["src/*.rb"],
    "contracts": [
      { "name": "verify", "description": "Check the source against the specification." },
      { "name": "dump", "description": "Say what was read.", "internal": true }
    ]
  }
JSON

File.write(".spec/contract/api.json", <<~JSON)
  {
    "name": "API",
    "language": "ruby",
    "description": "The methods this package exposes.",
    "include": ["src/*.rb"],
    "contracts": [
      {
        "name": "Cache.open",
        "description": "Open the cache.",
        "params": [{ "name": "path" }, { "name": "mode", "optional": true }]
      },
      { "name": "Cache#close", "description": "Close it.", "params": [] },
      { "name": "Cache", "description": "The cache itself." }
    ]
  }
JSON

File.write(".spec/contract/hidden.json", <<~JSON)
  {
    "name": "Hidden",
    "language": "ruby",
    "description": "A kind this project keeps entirely to itself.",
    "include": ["src/*.rb"],
    "contracts": [
      { "name": "Store.open", "description": "Open the store.", "internal": true }
    ]
  }
JSON

# `dump` is registered as internal, so the page below carries `verify` alone,
# and `hidden.json` has nothing but internal interfaces, so it becomes no page.
# The API page shows the shape each interface is reached by, and `Cache`
# registers none, so it is named alone.
# @behavior R-001 R-002 R-007 R-008 R-009 R-010
puts "--- the structured specification becomes documents ---"
puts "exit=#{cli.run(["render"])}"
puts "--- docs/glossary.md ---"
print File.read("docs/glossary.md")
puts "--- docs/behavior/checkout.md ---"
print File.read("docs/behavior/checkout.md")
puts "--- docs/contract/cli.md ---"
print File.read("docs/contract/cli.md")
puts "--- docs/contract/api.md ---"
print File.read("docs/contract/api.md")
puts "--- what docs/contract holds ---"
p Pathname.glob("docs/contract/*").map { |page| "#{page}" }.sort

# @behavior R-005
puts "--- a second run brings the document up to date ---"
File.write("docs/glossary.md", "stale\n")
puts "exit=#{cli.run(["render"])}"
print File.read("docs/glossary.md")

# @behavior R-003
puts "--- a specification the configuration switched off is not rendered ---"
File.write(".sumi.json", "{ \"specifications\": { \"glossary\": { \"render\": false } } }\n")
File.write("docs/glossary.md", "stale\n")
puts "exit=#{cli.run(["render"])}"
print File.read("docs/glossary.md")

# @behavior R-006
puts "--- a specification that could not be read stops that mechanism and no other ---"
File.write(".sumi.json", "{}\n")
File.write(".spec/behavior/broken.json", "{ not json\n")
puts "exit=#{cli.run(["render"])}"

Dir.chdir(back)
root.rmtree
