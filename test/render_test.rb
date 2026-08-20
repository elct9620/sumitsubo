require "pathname"
require "sumitsubo"

# render writes into the working directory, so the run has to happen somewhere
# other than the repository it is testing.
root = Pathname.new("/tmp/sumi_render_test_#{Process.pid}")
root.rmtree if root.exist?
root.mkpath

back = Dir.pwd
Dir.chdir(root.to_s)

cli = Sumitsubo::CLI.new

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

# @behavior R-001 R-002
puts "--- the structured specification becomes documents ---"
puts "exit=#{cli.run(["render"])}"
puts "--- docs/glossary.md ---"
print File.read("docs/glossary.md")
puts "--- docs/behavior/checkout.md ---"
print File.read("docs/behavior/checkout.md")

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
