# Glossary

| Term | Definition |
| --- | --- |
| Specification | What a project declares its source should stay aligned with. It is the structured files; what Render writes from them is a Document. |
| Structured Specification | The machine-readable file a mechanism reads: .spec/glossary.json, one file per kind of contract under .spec/contract/, and one file per feature under .spec/behavior/. |
| Document | What Render writes for a person to read: the half of the specification that says what it means, without what the tool needs in order to find things. |
| Verifiable Specification | The part of the structured specification a mechanism can check against source code. |
| Source Code | The code verified against the specification. Glossary and Contract verify the implementation, Behavior the tests. |
| Syntax Tree | What tree-sitter answers for a source file: every token kept, comments included. |
| Contract | An interface a project registers as one it means to keep, found in the source that implements it. Source claims one in a comment where no construct of the language points at it, and declares it outright where one does. |
| Behavior | A scenario the specification declares in a BDD style, claimed by the test that implements it. |
| Declare | To say something exists. A specification declares the contracts and behaviors it registers; source declares the classes, modules and methods it defines. One relation, and the subject is what changes — which is why both sides use the word. |
| Marker | The word source claims a contract or behavior with, written in the comment in front of the code. It is what an interface needs when no construct of the language points at it. |
| Internal | An interface the project means to keep but not to publish. It is verified like any other, and what it stays out of is the Document. |
| Note | A block of prose a specification carries for its document alone: a heading, a paragraph, or a fenced example. It says why a declaration is right, which no mechanism can check, so it is compared against nothing. |
