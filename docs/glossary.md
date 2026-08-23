# Glossary

| Term | Definition |
| --- | --- |
| Specification | What a project declares its source should stay aligned with. It is the structured files; what Render writes from them is a Document. |
| Structured Specification | The machine-readable file a mechanism reads: .spec/glossary.json, one file per kind of contract under .spec/contract/, and one file per feature under .spec/behavior/. |
| Document | What Render writes for a person to read: the half of the specification that says what it means, without what the tool needs in order to find things. |
| Verifiable Specification | The part of the structured specification a mechanism can check against source code. |
| Source Code | The code verified against the specification. Glossary and Contract verify the implementation, Behavior the tests. |
| Syntax Tree | What tree-sitter answers for a source file: every token kept, comments included. |
| Language | How a file is read for what a person put in it, and how the names it declares are spelled. A file is offered to each in turn and the first one claiming it answers, which is how comments are found without anyone saying what the file is written in; a name, though, is spelled the way one language spells it, so a specification registering names says which it means. What a build carries is decided when it is built. |
| Contract | An interface a project registers as one it means to keep, found in the source that implements it. Source claims one in a comment where no construct of the language points at it, and declares it outright where one does. |
| Behavior | A scenario the specification declares in a BDD style, claimed by the test that implements it. |
| Declare | To say something exists. A specification declares the contracts and behaviors it registers; source declares the classes, modules and methods it defines. One relation, and the subject is what changes — which is why both sides use the word. |
| Marker | The word source claims a contract or behavior with, written in the comment in front of the code. It is what an interface needs when no construct of the language points at it. |
| Internal | An interface the project means to keep but not to publish. It is verified like any other, and what it stays out of is the Document. |
| Note | A block of prose a specification carries for its document alone: a heading, a paragraph, or a fenced example. It says why a declaration is right, which no mechanism can check, so it is compared against nothing. |
| Ignore | One line a rejection does not answer for, and the reason that line is right to say what it says. It names a finding and nothing wider, so fixing the line leaves it naming nothing and the run says so. |
| Exclude | A path no mechanism reads, however wide an include reaches. It is written once for the project because a build directory is the project's rather than any one specification's, and it decides what is read where an Ignore decides what is answered for. |
| Subdomain | A part of the problem a project addresses, and the vocabulary that part keeps. A glossary entry declares one by naming it, and its terms hold in the files its includes cover, in place of Global's wherever both name the same term. |
| Global | The vocabulary a project keeps wherever no subdomain says otherwise. It is declared by the glossary entry that names no subdomain, and a subdomain covering a file stands in for it there. |
