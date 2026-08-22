module Sumitsubo
  module Command
    # How to write a specification, carried by the executable rather than by a
    # document beside it: a project using sumi has the command and nothing else
    # of this repository, and a form it cannot look up is one it guesses at.
    #
    # Every text below is a literal for the reason the usage always was — it has
    # to read the same under Spinel and under the CRuby run that takes the
    # snapshot.
    # @command help
    class Help
      USAGE = <<~TEXT
        Usage: sumi <command> [options]

        Commands:
            init             Lay down an empty specification to start from
            render           Render the specification to markdown
            verify           Check the source against the specification
            help <topic>     Explain how to write a specification

        Topics:
            glossary         The vocabulary, and the words it rejects
            contract         The interfaces the project means to keep
            behavior         The scenarios its tests implement
            config           .sumi.json - where things live, and what a run touches

        Options:
            -v, --version    Show version
            -h, --help       Show this help
      TEXT

      # @command help glossary
      GLOSSARY = <<~TEXT
        The vocabulary a project means to use, and the words it rejects in its
        place. Only the rejected words are checked: a term declaring none is
        vocabulary the tool carries but cannot verify.

        File
            .spec/glossary.json - one file, laid down by `sumi init`.

        Form
            {
              "glossary": [
                {
                  "include": ["app/**/*.rb", "docs/*.md"],
                  "terms": [
                    {
                      "term": "Order",
                      "definition": "What a customer asks us to fulfil.",
                      "not": [
                        {
                          "term": "Purchase",
                          "reason": "Order is what the domain calls it."
                        }
                      ]
                    }
                  ]
                }
              ]
            }

            A section is scoped by its `include` globs. A file takes every
            section covering it, in the order the file lists them; a later term
            replaces an earlier one of the same name outright, its rejected
            words included, because a term meaning something else there rejects
            different words.

            A `reason` says why that word is wrong, not why the term is right -
            what the term means is what `definition` carries. The reason is
            what a reader is handed at the line they tripped on.

        What is read
            A Ruby file: its comments, found through the syntax tree. An
            identifier is a spelling of a concept rather than the concept's
            name, so counting one would flag every legitimate class in the tree.
            Any other file: entire - prose is a comment for its whole length.
            Matching is whole-word and case sensitive.

        Findings
            app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
                The line uses a word the vocabulary rejects, one finding per
                line however often the word appears on it. Fix the wording, or
                drop the rejected word from the specification - which side is
                wrong is not the tool's to decide.

            no glossary at .spec/glossary.json; sumi init lays one down (exit 2)
                `sumi init` lays this file down, so a root without one is a root
                something removed. Nothing was compared.
      TEXT

      # @command help contract
      CONTRACT = <<~TEXT
        The interfaces a project means to keep. What this establishes is that a
        registered interface is implemented somewhere in scope and reached the
        way the specification says - never that what it does behind that is
        right.

        Files
            .spec/contract/*.json - one file per kind of interface: the commands
            an executable answers, the routes an application serves, the methods
            a package exposes.

        Two readings
            A file says which by naming a `marker` or not.

            WITH A MARKER, source claims each interface in the comment in front
            of the code implementing it. That is what an interface needs when no
            construct of the language points at one - nothing in a file *is* a
            route.

            {
              "name": "Routes",
              "description": "The routes this application serves.",
              "marker": "@route",
              "include": ["app/**/*.rb"],
              "contracts": [
                { "name": "GET /users/:id", "description": "One user." }
              ]
            }

                # @route GET /users/:id
                def show

            Everything after the marker to the end of the line is the name, so
            a name need not be a name in any language at all.

            WITHOUT ONE, the interfaces are read from the syntax tree and
            nothing is written in front of the code. The name is how that
            language spells it - in Ruby, `.` for a singleton method, `#` for an
            instance one, a bare path for a class or module; in Rust, the path
            the file itself carries, `Charge::settle` for a method in an `impl`
            and `audit::Entry` for a struct in a `mod`. A crate name and the
            module a file becomes live outside the file, so a name stops where
            the file does.

            Such a file names its `language`. `include` says which files a
            reading reaches and never what they are written in, and a name is
            spelled the way one language spells it, so the file says which
            rather than leaving the filename to imply it. A marker needs none:
            a claim is a claim in whatever the file is written in.

            {
              "name": "Internal seams",
              "description": "The places this project keeps to one shape.",
              "language": "ruby",
              "include": ["lib/**/*.rb"],
              "contracts": [
                {
                  "name": "Store.open",
                  "description": "Open the store.",
                  "params": [
                    { "name": "path" },
                    { "name": "mode", "optional": true },
                    { "kind": "block", "optional": true }
                  ]
                },
                { "name": "Store#read", "description": "Read one.", "internal": true }
              ]
            }

        Parameters
            Only the syntax tree reading carries them: a name registered under a
            marker with parameters is refused, since only the tree says what a
            definition takes.

            A parameter is what it is called, its `kind`, and whether a caller
            may leave it out. `kind` defaults to `positional`, and a parameter
            the language lets go unnamed registers a kind alone. The kind words
            are each language's own, compared as text:

                ruby  positional  keyword  splat  hash_splat  block
                      destructured  forward
                rust  positional  self

            A contract registering parameters is compared against them entire;
            one registering none asks for none to be compared. In a finding the
            shape is spelled as a call - the name, then `:kind` unless it is
            positional, then `?` where the caller may leave it out, and `-`
            where the language gave the parameter no name:

                (path, mode?, encoding:keyword, rest:splat?, block:block?)

            Types are not compared. A specification says the shape a caller
            writes, and no further.

        internal
            `"internal": true` says the project means to keep the interface but
            not to publish it. It is verified like any other; what it stays out
            of is the document. A kind whose every interface is internal renders
            no page.

        Notes
            `"notes"` is the prose a specification carries for its document
            alone. A structured field says what a project declares; nothing in
            one says why the declaration is right, and that is the half this
            holds. Nothing compares it against source.

            Notes sit under the kind and under each contract:

              "notes": [
                { "type": "paragraph",
                  "text": ["The store keeps one entry per key.",
                           "Nothing here says how it is stored."] },
                { "type": "heading", "level": 1, "text": ["Example"] },
                { "type": "code", "language": "ruby",
                  "text": ["store = Store.open(path)"] }
              ]

            A block is a `heading`, a `paragraph`, or a `code` fence, and its
            text is written as lines. They close up by kind - prose with
            spaces, code with newlines - so a paragraph reworded a word at a
            time shows which sentence moved.

            A heading's `level` counts from what its notes hang under rather
            than from the top of the page: 1 is one level in. It defaults to 1
            and goes no deeper than 4.

            An internal interface takes its notes out of the document with it.

        include
            With a marker it narrows the search: the union of every file covered
            is scanned, so a claim written somewhere unexpected is still found -
            and still counted when two places claim one contract. Without one it
            is simply where a definition has to be for the interface to count as
            implemented.

            Two files may share a marker: a project whose routes outgrow one
            file is registering more of one kind, not a second kind. What cannot
            happen is one name twice under one word.

        Findings
            .spec/contract/routes.json:6 @route GET /users/:id is claimed nowhere in app/**/*.rb
                Registered, and no source in scope claims it. Write the claim
                the finding leads with, or drop the contract.

            .spec/contract/api.json:5 Store.open is defined nowhere in lib/**/*.rb, and a method made by a call or mixed in never is
                Registered, and the syntax tree finds no such definition. Read
                "What the reading cannot see" before changing the code.

            .spec/contract/api.json:5 Store#read takes (id) where the specification registers (key)
                The shape differs from the one registered, answered at the line
                registering it.

            lib/store.rb:4 Store#read takes (id) here and (key) at lib/other.rb:9
                One name defined with two shapes is a second way in. Both places
                answer, each naming the other, because deciding which to keep
                means comparing them. Definitions agreeing on their shape are
                one way in still, so ordinary reopening says nothing.

            app/show.rb:1 @route GET /users/:id is claimed at app/other.rb:7 as well
                A contract is the way in, so a second claim is an entrance the
                specification does not describe.

            app/show.rb:1 @route GET /users/:id resolves to no contract      (exit 2)
                A claim nothing registers is a comparison that could not be made
                rather than a difference. Usually a renamed name.

            .spec/contract/routes.json names GET /users/:id, which no ruby definition can be spelled; sumi help contract has the two readings   (exit 2)
                The file registers a name the language it named cannot spell.
                Usually a marker that went missing.

            .spec/contract/seams.json names no marker and no language, so nothing says how to spell what it registers; sumi help contract has the two readings   (exit 2)
                One of the two has to be there: the marker says a claim carries
                the name, and the language says how a definition spells it.

            .spec/contract/api.json writes a note of type quote, which is none this document has   (exit 2)
                A note whose type is not one of the three, whose text is not
                lines, or whose heading sits deeper than 4, is a specification
                that could not be read.

        What the reading cannot see
            The syntax tree reading finds a definition by its name in the tree.
            A contract naming one of these is answered as undefined however
            plainly the code works. In Ruby:

                attr_reader :size              a call, not a definition - the
                                               method exists only once it runs
                define_method(:computed)       the same, and the name need not
                                               be a literal at all
                def_delegator :@parts, :count  the same, through Forwardable
                include Helper                 Helper#helped is declared;
                                               Widget#helped never is
                def Other.oddball              only a receiver of `self` is read

            And in Rust:

                #[derive(Clone)]               the impl exists only after the
                                               macro has run
                impl<T: Read> Parse for T      a blanket impl declares nothing
                                               under any one type's name
                pub use inner::Store           a re-export names it here and
                                               defines it elsewhere

            A project leaning on these registers the contracts it can check and
            leaves the rest unregistered: an interface nobody registered is not
            a difference.
      TEXT

      # @command help behavior
      BEHAVIOR = <<~TEXT
        The behaviors a project means its tests to implement. What this
        establishes is that a behavior was read and implemented - never that the
        implementation is right.

        Files
            .spec/behavior/*.json - one file per feature, each carrying its own
            include. Declaring no scenarios is what a fresh clone answers, since
            git carries no empty directory.

        Form
            {
              "name": "Verify",
              "description": "How a run answers what it was asked.",
              "include": ["test/verify_test.rb"],
              "scenarios": [
                {
                  "id": "V-001",
                  "title": "Code that drifted from its glossary",
                  "given": ["a glossary declaring a word one of its terms rejects"],
                  "when": "`sumi verify` runs",
                  "then": "one finding is reported for the line the word appears on"
                }
              ]
            }

            The model is Gherkin's, not its file format: these scenarios are
            read rather than executed.

            `given` is a list with no limit. `when` and `then` are one sentence
            each, which three disciplines make reachable rather than a cap that
            turns work away:

                The operation under test is the last one; everything before it
                is `given`.

                An outcome is what one observation settles. Two observations are
                two scenarios, repeating their `given` and `when`.

                `then` names the observable difference and stops - not the exit
                code, and not the reason, which belongs to the title.

            An id is unique across the whole directory: a claim carries only the
            id, and a referent that is not unique resolves to nothing.

        Notes
            `"notes"` is the prose a feature carries for its document alone -
            why these scenarios are the right ones, which no mechanism can
            check. It hangs from the feature and not from a scenario, whose
            reason belongs to its title.

              "notes": [
                { "type": "heading", "level": 1, "text": ["Why these are read"] },
                { "type": "paragraph",
                  "text": ["A scenario asserts a behavior was implemented.",
                           "Whether the code under it is right is not read."] }
              ]

            A block is a `heading`, a `paragraph`, or a `code` fence, and its
            text is written as lines. They close up by kind - prose with
            spaces, code with newlines. A heading's `level` counts from what
            its notes hang under: 1 is one level in, and 4 is as deep as it
            goes. `sumi help contract` has the same form.

        Claiming
            Source claims a scenario in the comment in front of the code
            implementing it. A claim is read as a list, so one may carry
            several:

                # @behavior V-008 V-009

            A behavior may be claimed by as many tests as exercise it.

        Findings
            .spec/behavior/verify.json:6 @behavior V-002 is claimed nowhere in test/*_test.rb
                Declared, and no test in scope claims it. Write the claim the
                finding leads with, or drop the scenario.

            test/verify_test.rb:13 V-404 resolves to no scenario             (exit 2)
                A claim naming no scenario is a comparison that could not be
                made rather than a difference. Usually a renamed id.
      TEXT

      # @command help config
      CONFIG = <<~TEXT
        .sumi.json says where. A run takes the nearest one at or above where it
        started; failing that the repository it sits in; failing that - with
        neither to go on - where it started. A project that has said nothing is
        not misconfigured, so an absent .sumi.json answers the defaults; only an
        unreadable one stops the run.

        Form
            {
              "root": ".spec",
              "docs": "docs",
              "specifications": { "glossary": { "verify": false } }
            }

            root    where the specifications live, `.spec` by default
            docs    where `sumi render` writes, `docs` by default

            Both are read against the directory holding the .sumi.json, so
            wherever under it a run starts it reaches the same files. Findings
            answer relative to where the run started, so a reader can go
            straight to one.

            `specifications` lists only the exceptions: one nobody mentions is
            both verified and rendered. The names are `glossary`, `contract`,
            and `behavior`. The two switches are independent - `verify: false`
            keeps a specification without checking it, and `render: false` keeps
            one out of the documents without stopping the check.

        Answers
            0   the two sides agree
            1   they differ
            2   the comparison could not be made - whatever had to be read first
                was absent, unreadable, or ambiguous

            A difference is a finding about the code; being unable to compare is
            not, and a run with both answers 2: it says everything it found
            either way, and the answer is what refuses to certify it. A
            mechanism that could not be read stops that mechanism and no other.

            `sumi render` compares nothing, so it never answers 1: its 0 says
            every document it had to write is written.
      TEXT

      def run(name)
        return usage if name.nil?

        text = topic(name)
        return no_topic(name) if text.nil?

        puts text
        0
      end

      # Spinel decides what an executable carries when it is built, so a topic
      # is reached by being named here rather than through a table a name is
      # looked up in.
      def topic(name)
        case name
        when "glossary" then GLOSSARY
        when "contract" then CONTRACT
        when "behavior" then BEHAVIOR
        when "config" then CONFIG
        end
      end

      private

      def usage
        puts USAGE
        0
      end

      def no_topic(name)
        puts "#{name} is no topic sumi explains"
        puts USAGE
        2
      end
    end
  end
end
