require "sumitsubo/error"
require "sumitsubo/where"

module Sumitsubo
  # The prose a specification carries so a reader learns what it meant. A
  # structured field says what a project declares; nothing in one says why the
  # declaration is right, and that is the half this holds.
  #
  # Nothing here is compared against source. It is licensed under the rule
  # that an unverifiable specification is a document rather than a reference
  # line, by saying it is one.
  #
  # Shared because every mechanism writing a document needs it and none of
  # them needs it differently, the way Locations is. Nothing here reaches the
  # grammar, so a mechanism using it keeps a snapshot that can be regenerated.
  module Note
    # The kinds of block a note carries. A closed set, because each is a shape
    # this has to word, and a word it does not know is a specification it
    # cannot read rather than a block to pass through unrendered.
    HEADING = "heading"
    PARAGRAPH = "paragraph"
    CODE = "code"

    # How deep a heading may sit under its anchor. Four reaches `######` from
    # a section, which is as far as the page goes.
    DEEPEST = 4

    # One block. A block names none of its parts, which is what keeps it out
    # of the walk over `"name"` and `"id"` that gives a specification's own
    # declarations their lines.
    Block = Struct.new(:type, :level, :language, :text)

    # The blocks a specification wrote, in the order it wrote them. Text
    # arrives as lines and is joined here, because how they close up is what
    # tells the kinds apart: prose reflows and code does not.
    #
    # The topic is the help a reader is sent to, which is the mechanism's to
    # name: this knows the form and not who is asking about it.
    def self.all_in(path, raw, topic)
      return [] if raw.nil?

      found = []
      raw.each do |note|
        type = note["type"]
        text = note["text"]
        # Lines rather than one string, so a paragraph reworded a word at a
        # time shows which sentence moved.
        unless text.is_a?(Array)
          raise Error, "#{Where.of(path)} writes a note whose \"text\" is not lines; " \
                       "sumi help #{topic} has the form"
        end

        case type
        when HEADING
          found.push(Block.new(type, depth_in(path, note["level"], topic), nil, text.join(" ")))
        when PARAGRAPH
          found.push(Block.new(type, nil, nil, text.join(" ")))
        when CODE
          found.push(Block.new(type, nil, note["language"], text.join("\n")))
        else
          raise Error, "#{Where.of(path)} writes a note of type #{type}, " \
                       "which is none this document has; " \
                       "sumi help #{topic} has the form"
        end
      end
      found
    end

    # The lines these blocks become. A heading answers relative to where its
    # notes hang, so a specification says how deep a block sits and the
    # mechanism says under what: absolute levels would have every author work
    # out the anchor themselves, and get it wrong wherever the page moved.
    def self.spell(blocks, anchor)
      lines = []
      (blocks || []).each do |block|
        case block.type
        when HEADING
          lines.push("#{"#" * (anchor + block.level)} #{block.text}", "")
        when CODE
          lines.push("```#{block.language}", block.text, "```", "")
        else
          lines.push(block.text, "")
        end
      end
      lines
    end

    # A heading deeper than the page reaches would answer as text where it
    # stood, so the specification is refused rather than quietly flattened.
    def self.depth_in(path, level, topic)
      return 1 if level.nil?
      return level if level >= 1 && level <= DEEPEST

      raise Error, "#{Where.of(path)} writes a heading at level #{level}, " \
                   "which is deeper than a page carries; " \
                   "sumi help #{topic} has the form"
    end
  end
end
