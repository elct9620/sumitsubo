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
            .spec/glossary.md - one file, laid down by `sumi init`.

        Form
            # Glossary

            The words this project keeps, and the ones it turns down in
            their place.

            ## Everywhere

            ### Includes

            - `app/**/*.rb`
            - `docs/*.md`

            ### Order

            What a customer asks us to fulfil.

            #### Rejected

            - `Purchase` — Order is what the domain calls it.
              - `app/legacy_import.rb:88` — Quotes the upstream column name.

            ## Billing

            ### Includes

            - `app/billing/**/*.rb`

            ### Order

            The billable set of lines.

            The title says the document is a vocabulary, and one declaring
            no section is a vocabulary that checks nothing - which is what
            `sumi init` lays down. Every `##` opens a section, named by the
            project: what it covers is its `Includes`, what it means is the
            terms under it.

            A file takes every section covering it, in the order the file
            lists them; a later term replaces an earlier one of the same
            name outright, its rejected words included, because a term
            meaning something else there rejects different words. Order is
            all that decides which way that goes, so the section a file falls
            back to is written first.

            A term is a `###` heading and the paragraph under it is the
            definition. `Includes` is the one `###` heading that is reserved
            rather than a term, which is why a heading of a term's own
            starts at `####` - and `Rejected` is the one word read there.

            A rejected word is a list item opening with that word in
            backticks. What follows the dash says why the word is wrong, not
            why the term is right - what the term means is what its
            definition carries. The reason is what a reader is handed at the
            line they tripped on.

            An ignore is a list item under the word it sets aside, naming
            `path:line` in backticks with its own reason after the dash.
            Which term is rejecting and which word it rejects come from where
            it sits, so the line is the whole of what it names - against the
            same place the `Includes` globs are, which is what a finding
            prints when the run starts there. Both halves are required.

            Fix the line and it names nothing, so the run stops until the
            exception is looked at again. That is the opposite of what a
            fingerprint would do, and deliberate: an exception nobody is made
            to revisit outlives what it was written for.

        What is read
            A source file: its comments, found through the syntax tree. An
            identifier is a spelling of a concept rather than the concept's
            name, so counting one would flag every legitimate class in the tree.
            Any other file: entire - prose is a comment for its whole length.
            Matching is whole-word and case sensitive.

            The glossary itself, where its own includes cover it: a word has
            to be spelled to be declared rejected, so the line a term or one
            of its rejections is written on declares that word rather than
            uses it, and nothing is reported there.

        Findings
            app/order.rb:2 Order rejects Purchase: Order is what the domain calls it.
                The line uses a word the vocabulary rejects, one finding per
                line however often the word appears on it. Fix the wording, or
                drop the rejected word from the specification - which side is
                wrong is not the tool's to decide.

            .spec/glossary.md:19 nothing at app/legacy_import.rb:88 has Order
            rejecting Purchase; the line moved or the wording was fixed (exit 2)
                An ignore names a finding that is no longer there. Point it at
                where the line went, or drop it - nothing was set aside, so
                nothing was compared either.

            no glossary at .spec/glossary.md; sumi init lays one down (exit 2)
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
            .spec/contract/*.md - one file per kind of interface: the commands
            an executable answers, the routes an application serves, the methods
            a package exposes.

        Two readings
            A definition says which by writing a `## Marker` section or not.

            WITH ONE, source claims each interface in the comment in front of
            the code implementing it. That is what an interface needs when no
            construct of the language points at one - nothing in a file *is* a
            route. Every fence in such a document is prose.

            # Routes

            The routes this application serves.

            ## Includes

            - `app/**/*.rb`

            ## Marker

            `@route`

            ## `GET /users/:id`

            One user.

                # @route GET /users/:id
                def show

            Everything after the marker to the end of the line is the name, so
            a name need not be a name in any language at all.

            WITHOUT ONE, the interfaces are read from the syntax tree and
            nothing is written in front of the code. Each contract carries a
            fenced signature, and the fence's language is what says how its
            name is spelled - so one definition may register contracts in two
            languages.

            # Internal seams

            The places this project keeps to one implementation.

            ## Includes

            - `lib/**/*.rb`

            ## `Store.open`

            Open the store.

            ```ruby
            class Store
              def self.open(path, mode = "r")
              end
            end
            ```

            ## `Store#read` `internal`

            Read one.

            ```ruby
            class Store
              def read(key)
              end
            end
            ```

        Signatures
            The signature is the code the contract means, written out. It is
            read by the very reading that reads the source, so what a
            specification can register is what that reading can find - a shape
            no definition could have is a shape nobody can write down here.

            It carries its nesting, because that is what makes the name what
            it is: `def self.of(path)` on its own declares `of`, where
            `module Sumitsubo::Where` around it declares `Sumitsubo::Where.of`.
            The name it declares has to be the name in the heading, and the
            only other things it may declare are the scopes holding that name.

            Registering a scope is written as the scope: `class Store` with
            nothing in it. A scope describes no call, so nothing is compared
            about the shape - which is not the same as a call taking nothing.

            Types are not compared. A specification says the shape a caller
            writes, and no further.

            In a finding the shape is spelled as a call - the name, then
            `:kind` unless it is the plain one, then `?` where the caller may
            leave it out, and `-` where the language gave the parameter no
            name:

                (path, mode?, encoding:keyword, rest:splat?, block:block?)

            `positional` is the one kind word sumi owns: it names the parameter
            a caller writes with no marking of any sort, which every language
            has, and a finding leaves it out because a bare name already says
            it. Every other kind word belongs to the language and is compared
            as text, sumi knowing nothing of what it means:

                ruby  keyword  splat  hash_splat  block  destructured  forward
                rust  self

        Names
            A name is how the language spells it - in Ruby, `.` for a singleton
            method, `#` for an instance one, a bare path for a class or module;
            in Rust, the path the file itself carries, `Charge::settle` for a
            method in an `impl` and `audit::Entry` for a struct in a `mod`. A
            crate name and the module a file becomes live outside the file, so
            a name stops where the file does.

            The language is the namespace, the way the marker is for the other
            reading. Two languages may spell one name and mean nothing alike,
            so a Rust declaration does not define a Ruby contract, and one name
            registered under each is not ambiguous.

        internal
            A contract heading may carry `internal` after its name, in
            backticks of its own. It says the project means to keep the
            interface but not to publish it. It is verified like any other;
            what it says is that a reader outside the project is not the one it
            is kept for.

        Includes
            The boundary of what a definition answers for, and not merely a
            list of files to read. With a marker, a contract is implemented by
            the files its own definition covers, and a claim from anywhere else
            names it without being able to implement it. Without one, a
            definition has to sit among those files to count, so a type of the
            same name in another component is a type of the same name in
            another component.

            One file may sit under two definitions, which is how a module
            answering for both is written. `sumi help glossary` has the same
            boundary under another word: a subdomain.

            Two files may share a marker: a project whose routes outgrow one
            file is registering more of one kind, not a second kind. What cannot
            happen is one name twice under one word.

        Findings
            .spec/contract/routes.md:11 @route GET /users/:id is claimed nowhere this specification includes
                Registered, and no source this definition reaches claims it.
                Write the claim the finding leads with, or drop the contract.

            .spec/contract/api.md:9 Store.open is defined nowhere this specification includes, and one the reading cannot see never is
                Registered, and the syntax tree finds no such definition among
                the files this definition reaches. Read "What the reading
                cannot see" before changing the code.

            .spec/contract/api.md:9 Store#read takes (id) where the specification registers (key)
                The signature and the code describe different calls, answered
                at the line registering it.

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

            app/show.rb:1 @route GET /users/:id is claimed outside what .spec/contract/routes.md includes   (exit 2)
                The name resolves and the definition registering it does not
                reach this file, so nothing here can implement it. Widen that
                include, or move the claim. A definition merely spelling a
                registered name says nothing this way: a claim asserts that a
                contract was implemented, where a class of that name asserts
                nothing at all.

            .spec/contract/api.md:9 writes a signature declaring open, and not Store.open   (exit 2)
                The heading and the signature name one thing written twice.
                Usually a signature written without the scopes around it.

            .spec/contract/api.md:9 registers Store.open with no signature, so nothing says how its name is spelled   (exit 2)
                Every contract read from the syntax tree carries one. Usually a
                `## Marker` section that went missing.

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
                MAX = 100                      a constant is not read at all,
                                               so a signature declaring one is
                                               refused rather than registered

            And in Rust:

                #[derive(Clone)]               the impl exists only after the
                                               macro has run
                impl<T: Read> Parse for T      a blanket impl declares nothing
                                               under any one type's name
                pub use inner::Store           a re-export names it here and
                                               defines it elsewhere

            Two things it sees without telling them apart: `module` and `class`
            spell one name, and a signature may say either. Visibility is read
            only where it is written on the definition itself, so a bare
            `private` above a method says nothing about it.

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
            .spec/behavior/*.md - one file per feature, each carrying its own
            includes. Declaring no scenarios is what a fresh clone answers,
            since git carries no empty directory.

            An id is what a claim in the source names, so one declared twice
            is refused rather than resolved to either.

        Form
            # Verify

            How a run answers what it was asked.

            ## Includes

            - `test/verify_test.rb`

            ## `V-001` Code that drifted from its glossary

            | Step | Statement |
            | --- | --- |
            | Given | a glossary declaring a word one of its terms rejects |
            | When | `sumi verify` runs |
            | Then | one finding is answered for the line the word appears on |

            The title names the feature and the paragraph under it says what
            the feature is for. Every other block of prose is the feature's
            own, carried for whoever reads it and read by nothing.

            A scenario is an `##` heading opening with its id in backticks;
            the rest of that line is the title. `Includes` is the one `##`
            heading that is prose rather than a scenario, which is why a
            heading of the feature's own starts at `###`.

            The model is Gherkin's, not its file format: these scenarios are
            read rather than executed.

            The steps are a two-column table. `Given` may be written as many
            times as the scenario stands on states; `When` and `Then` are one
            row each, which three disciplines make reachable rather than a cap
            that turns work away:

                The operation under test is the last one; everything before it
                is `Given`.

                An outcome is what one observation settles. Two observations are
                two scenarios, repeating their `Given` and `When`.

                `Then` names the observable difference and stops - not the exit
                code, and not the reason, which belongs to the title.

            A cell cannot wrap, which is where those three get their pressure.
            A `|` inside one is written `\\|`.

            An id is unique across the whole directory: a claim carries only the
            id, and a referent that is not unique resolves to nothing.

        Includes
            The boundary of what a feature answers for, and not merely a list
            of files to read: a scenario is witnessed by the files its own
            feature covers, and a claim from anywhere else names it without
            being able to witness it. One file may sit under two features,
            which is how a test answering for both is written.
            `sumi help glossary` has the same boundary under another word: a
            subdomain.

        Claiming
            Source claims a scenario in the comment in front of the code
            implementing it. A claim is read as a list, so one may carry
            several:

                # @behavior V-008 V-009

            A behavior may be claimed by as many tests as exercise it.

        Findings
            .spec/behavior/verify.md:9 @behavior V-002 is claimed nowhere this specification includes
                Declared, and no test this feature reaches claims it. Write the
                claim the finding leads with, or drop the scenario.

            test/verify_test.rb:13 V-404 resolves to no scenario             (exit 2)
                A claim naming no scenario is a comparison that could not be
                made rather than a difference. Usually a renamed id.

            test/other_test.rb:13 V-002 is claimed outside what .spec/behavior/verify.md includes   (exit 2)
                The id resolves and the feature declaring it does not reach
                this file, so nothing here can witness it. Widen that include,
                or move the claim.
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
              "exclude": ["vendor/"],
              "gitignore": true,
              "specifications": { "glossary": { "verify": false } }
            }

            root        where the specifications live, `.spec` by default
            exclude     paths no mechanism reads, whatever an include covers
            gitignore   whether the .gitignore beside this file is read too,
                        which it is unless this says false

            All are read against the directory holding the .sumi.json, so
            wherever under it a run starts it reaches the same files. Findings
            answer relative to where the run started, so a reader can go
            straight to one.

            `specifications` lists only the exceptions: one nobody mentions is
            verified. The names are `glossary`, `contract`, and `behavior`.
            `verify: false` keeps a specification the project means to hold
            without a run being checked against it yet.

        What a run reads
            `include` and `exclude` are globs read against the directory
            holding the .sumi.json: `*` and `?` within a name, `**` for
            however many directories, one in the middle included - so
            `crates/*/src/**/*.rs` is each crate's own source. Character
            classes and escapes are read by neither, a wildcard never reaches
            a hidden file, and a directory linking back up the tree is not
            followed.

            An include is where it says: `README.md` is the one at the top,
            `**/README.md` is every one. An exclusion with no separator
            reaches a name at any depth, which is what makes `target/` every
            build directory; `!` and a trailing separator are its alone.

            The .gitignore beside this file is read as well, and only that one
            - not the ones deeper in the tree, not the user's own, and not
            git's rule that a tracked file is never left out. This file is
            read after it, so `!` here puts a path back and
            `"gitignore": false` takes the .gitignore out entirely.

            An excluded directory is never looked inside, so `target/` is
            worth more than anything written about what is under it.

            An include covering no file at all is a pattern nobody can have
            meant, and the run refuses to certify. One whose files `exclude`
            takes away says nothing.

            `exclude` says what no mechanism reads. An `include` says more
            than which files are read: it is the boundary of what one
            specification answers for, so the same file under two of them
            answers for both, and under neither answers for nothing. Each
            mechanism's help has what that means for it.

        Answers
            0   the two sides agree
            1   they differ
            2   the comparison could not be made - whatever had to be read first
                was absent, unreadable, or ambiguous

            A difference is a finding about the code; being unable to compare is
            not, and a run with both answers 2: it says everything it found
            either way, and the answer is what refuses to certify it. A
            mechanism that could not be read stops that mechanism and no other.
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
