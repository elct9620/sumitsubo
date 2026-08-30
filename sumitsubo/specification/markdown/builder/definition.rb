require "sumitsubo/specification/markdown/format"
require "sumitsubo/specification"

module Sumitsubo
  class Specification
    class Markdown
      module Builder
        # The interfaces a definition registers, built out of the blocks a
        # document is made of.
        #
        # A definition is read one of two ways and they are exclusive: with the
        # reserved heading naming a marker, source claims its contracts in a
        # comment and every fence in the document is prose; without it, source
        # declares them outright and the fence under each contract is the
        # signature. That heading is the only thing telling the two apart, so it
        # is written before the first contract or refused — a walk reaching a
        # fence has to know already.
        #
        # A fence is asked for as well as its language and its content, and
        # arrives ahead of both, so a fence carrying neither is still a fence
        # rather than nothing. It is closed by the first capture that is not one
        # of its parts, the way a table row is.
        #
        # The language is the fence's own rather than the document's, which is
        # what lets one definition register contracts in two languages. What the
        # signature says is carried as it was written: how a shape is compared
        # against the source is the mechanism's, and this is where that text
        # comes from.
        class Definition
          QUERY = <<~QUERY
            (atx_heading (atx_h1_marker) (inline) @h1)
            (atx_heading (atx_h2_marker) (inline) @h2)
            (section (paragraph (inline) @paragraph))
            (section (list (list_item (paragraph (inline) @item))))
            (section (fenced_code_block) @fence)
            (section (fenced_code_block (info_string (language) @language)))
            (section (fenced_code_block (code_fence_content) @content))
          QUERY

          # The heading naming the word source claims these contracts with.
          MARKER = "Marker"

          # The flags a contract heading may carry after its name. A closed set:
          # a word this does not know is a form nobody reads rather than one
          # this build happens not to.
          FLAGS = ["internal"]

          # What the attributes a contract carries are held under, which are the
          # words the mechanism words its own help with.
          LANGUAGE = "language"
          SIGNATURE = "signature"

          # The topic a refusal from this builder sends a reader to.
          TOPIC = "contract"

          # What stands between a scope and what it holds. Every language
          # spelling a nested name uses one of them, and which means what is
          # that language's own — all this asks is whether a name ended where
          # another began, so that a scope sharing a prefix with the contract
          # is not read as holding it.
          SEPARATORS = [":", ".", "#"]

          # A fence being read: where it opened, and the two parts that may or
          # may not follow it.
          Fence = Struct.new(:line, :language, :content)

          def initialize(path, languages)
            @path = path
            @languages = languages
            @key = nil
            @text = nil
            @marker = nil
            @marker_at = nil
            @includes = []
            @contracts = []
            @contract = nil
            @holding = nil
            @fence = nil
          end

          def query
            QUERY
          end

          def build(captures)
            captures.each { |capture| arrived(capture) }
            signed

            refuse(1, "declares no name") if @key.nil?
            refuse(@marker_at, "names #{MARKER} and gives no word to claim with") if @marker.nil? && !@marker_at.nil?
            @contracts.each { |contract| declared(contract) }

            Specification.new(@key, @text, @includes, @path, attributes, @contracts)
          end

          private

          def arrived(capture)
            name = capture.name
            signed unless name == Format::LANGUAGE || name == Format::CONTENT

            case name
            when Format::H1 then named(capture)
            when Format::PARAGRAPH then described(capture)
            when Format::H2 then heading(capture)
            when Format::ITEM then item(capture) if @holding == Format::INCLUDES
            when Format::FENCE then @fence = Fence.new(capture.line, nil, nil)
            when Format::LANGUAGE then @fence.language = capture.text.strip unless @fence.nil?
            when Format::CONTENT then @fence.content = capture.text unless @fence.nil?
            end
          end

          # A definition is named once, and a file naming two says which of them
          # it is nowhere.
          def named(capture)
            refuse(capture.line, "declares a second name") unless @key.nil?

            @key = Format.folded(capture.text)
          end

          # The reserved headings, or a contract. Which arrived is what the
          # blocks after it are read as: a list under one spells includes, a
          # paragraph under another names the marker, and a paragraph under a
          # contract says what it is for.
          def heading(capture)
            said = Format.folded(capture.text)
            @contract = nil
            @holding = nil

            return @holding = Format::INCLUDES if said == Format::INCLUDES
            return marking(capture.line) if said == MARKER

            @contract = registered(said, capture.line)
            @contracts.push(@contract)
          end

          def marking(line)
            refuse(line, "names #{MARKER} twice") unless @marker_at.nil?
            refuse(line, "names #{MARKER} after a contract, which is read one way or the other") unless @contracts.empty?

            @marker_at = line
            @holding = MARKER
          end

          # A contract's name is what a claim in the source names, so it is
          # spelled in a code span and taken from it letter for letter. What
          # follows is a flag or nothing: a description is a paragraph, and a
          # heading is not the place a sentence goes.
          def registered(said, line)
            opened = Format.code_span(said)
            if opened.nil? || opened.taken.empty?
              refuse(line, "declares a contract whose heading does not open with a name in backticks")
            end

            Statement.new(opened.taken, nil, @path, line, flagged(opened.after, line), [])
          end

          # Every flag after the name, each a code span of its own. A closed
          # set, so an unknown word is a form nobody reads; prose there is the
          # same answer, since a heading carries a name and its flags and
          # nothing else.
          def flagged(said, line)
            attributes = {}
            rest = said
            until rest.empty?
              flag = Format.code_span(rest)
              refuse(line, "writes #{rest} after a name, where only a flag in backticks is read") if flag.nil?
              refuse(line, "writes #{flag.taken}, which is not a flag a contract carries") unless FLAGS.include?(flag.taken)

              attributes[flag.taken] = []
              rest = flag.after
            end
            attributes
          end

          # The marker, the definition's own description, or a contract's. Only
          # the first paragraph under each says what it declares; a second is
          # prose.
          def described(capture)
            said = Format.folded(capture.text)
            return marked(said, capture.line) if @holding == MARKER
            return unless @holding.nil?

            return @contract.text = said if !@contract.nil? && @contract.text.nil?
            return unless @contract.nil?

            @text = said if @text.nil? && @contracts.empty?
          end

          # The word source claims with is consumed letter for letter, so it is
          # spelled in a code span like every other such word.
          def marked(said, line)
            return unless @marker.nil?

            word = Format.code_span(said)
            refuse(line, "names a marker that is not a word in backticks") if word.nil?

            @marker = word.taken
          end

          def item(capture)
            @includes.push(Format.glob(@path, capture.line, Format.folded(capture.text), TOPIC))
          end

          # The fence held so far, taken as the signature of the contract it sat
          # under. A marker reading has no signature to take, so every fence in
          # such a document is prose; so is a second fence under one contract,
          # and so is one written before any contract.
          def signed
            fence = @fence
            @fence = nil
            return if fence.nil? || !@marker_at.nil?
            return if @contract.nil? || !@contract.attributes[SIGNATURE].nil?

            refuse(fence.line, "writes a signature with no language, which is what says how #{@contract.key} is spelled") if fence.language.nil?

            @contract.attributes[LANGUAGE] = [fence.language]
            @contract.attributes[SIGNATURE] = [fence.content.nil? ? "" : fence.content]
          end

          # What every contract has to answer once the document is read. The
          # marker reading asks nothing of a name — a claim is a claim in
          # whatever the file is written in — so this is the other one's alone.
          def declared(contract)
            return unless @marker.nil?

            named = contract.attributes[LANGUAGE]
            if named.nil?
              refuse(contract.line, "registers #{contract.key} with no signature, so nothing says how its name is spelled")
            end

            language = named[0]
            refuse(contract.line, "names #{language}, which this sumi does not carry") unless @languages.carries?(language)
            registering(contract, language)
          end

          # The signature read as the language it names. Asking the reading
          # rather than the spelling of the name is what makes the two sides
          # one: what a contract can register is what that reading finds.
          #
          # What comes back is thrown away. The shape is read again when the
          # two sides are compared, because a value derived here would be a
          # second place the specification says something.
          def registering(contract, language)
            found = declarations_of(contract, language)
            holding = found.reject { |name| name.name == contract.key }
            # Nothing was taken out, so nothing declared what the heading names.
            if holding.length == found.length
              refuse(contract.line, "writes a signature declaring #{spelled(found)}, and not #{contract.key}")
            end

            holding.each do |name|
              next if name.params.nil? && encloses?(name.name, contract.key)

              refuse(contract.line, "writes a signature declaring #{name.name} as well, " \
                                    "where a signature declares the one contract and what holds it")
            end
          end

          def declarations_of(contract, language)
            @languages.declarations_of(contract.attributes[SIGNATURE][0], @path, language)
          rescue Sumitsubo::Error
            # Named rather than passed on: the reading's message is about a
            # piece of source, and what a reader has is a specification. Caught
            # as the error every reading answers with, so nothing here reaches
            # for the one that names a grammar.
            refuse(contract.line, "writes a signature the #{language} reading cannot read")
          end

          # Whether a declaration is one of the scopes the contract's own name
          # is written inside. A signature carries the nesting because that is
          # what makes the name what it is, so the scopes are declarations too
          # and registering none of them.
          def encloses?(name, key)
            key.start_with?(name) && SEPARATORS.include?("#{key[name.length]}")
          end

          def spelled(found)
            return "nothing" if found.empty?

            found.map { |name| name.name }.join(", ")
          end

          def attributes
            found = {}
            found["marker"] = [@marker] unless @marker.nil?
            found
          end

          def refuse(line, said)
            Format.refuse(@path, line, said, TOPIC)
          end
        end
      end
    end
  end
end
