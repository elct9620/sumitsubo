require "sumitsubo/finding"
require "sumitsubo/place"
require "sumitsubo/specification/block"

module Sumitsubo
  # How long a specification's prose may run, measured over the blocks any form
  # is written in. It asks nothing of what a document means, which is why it
  # belongs to no mechanism and answers under a word of its own.
  #
  # A limit nobody wrote is nil and is not measured, so a project writing no
  # budget is held to nothing.
  class Budget
    SENTENCE = "budget/sentence"
    PARAGRAPH = "budget/paragraph"

    # How many words of a sentence a finding quotes, enough to find it by in a
    # paragraph the parser has folded onto one line.
    OPENING = 4

    def initialize(sentence, paragraph)
      @sentence = sentence
      @paragraph = paragraph
    end

    def measures?
      !@sentence.nil? || !@paragraph.nil?
    end

    # The blocks prose is written in. A cell arrives under its row.
    def kinds
      [Specification::Block::PARAGRAPH, Specification::Block::ITEM, Specification::Block::ROW]
    end

    # Every place one document's prose runs over a limit.
    def over(path, blocks)
      found = []
      blocks.each do |block|
        if block.kind == Specification::Block::ROW
          block.cells.each { |cell| sentences_over(found, path, cell) }
        else
          sentences_over(found, path, block)
          paragraph_over(found, path, block)
        end
      end
      found
    end

    # The text as its words, each sentence apart. A sentence ends at a word
    # closing on a stop, so the dot inside a path or a version ends nothing; a
    # span of code is one word, whatever spaces or stops it holds.
    def self.sentences(text)
      found = []
      words = []
      open = false
      text.split(" ").each do |piece|
        if open
          words[-1] = "#{words[-1]} #{piece}"
        else
          words.push(piece)
        end
        open = !open if piece.count("`").odd?
        next if open || !piece.match?(/[.!?]["')\]]*\z/)

        found.push(words)
        words = []
      end
      found.push(words) unless words.empty?
      found
    end

    # The words a sentence counts: a dash or a lone mark is not one.
    def self.counted(words)
      words.count { |word| word.match?(/[A-Za-z0-9]/) }
    end

    private

    def sentences_over(found, path, block)
      return if @sentence.nil?

      Budget.sentences(block.text).each do |words|
        counted = Budget.counted(words)
        next if counted <= @sentence

        found.push(Finding.new(
          check: SENTENCE, difference: true, place: Place.new(path: path, line: block.line),
          message: "\"#{words.take(OPENING).join(" ")}…\" runs #{counted} words, over #{@sentence}"
        ))
      end
    end

    def paragraph_over(found, path, block)
      return if @paragraph.nil?

      many = Budget.sentences(block.text).length
      return if many <= @paragraph

      found.push(Finding.new(
        check: PARAGRAPH, difference: true, place: Place.new(path: path, line: block.line),
        message: "the #{block.kind} runs #{many} sentences, over #{@paragraph}"
      ))
    end
  end
end
