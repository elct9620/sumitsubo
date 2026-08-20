# Glossary

| Term | Definition |
| --- | --- |
| Specification | What a project declares its source should stay aligned with. It is the structured files; what Render writes from them is a Document. |
| Structured Specification | The machine-readable file a mechanism reads: .spec/glossary.json, one file per kind of contract under .spec/contract/, and one file per feature under .spec/behavior/. |
| Document | What Render writes for a person to read: the half of the specification that says what it means, without what the tool needs in order to find things. |
| Verifiable Specification | The part of the structured specification a mechanism can check against source code. |
| Source Code | The code verified against the specification. Glossary and Contract verify the implementation, Behavior the tests. |
| Syntax Tree | What tree-sitter answers for a source file: every token kept, comments included. |
| Contract | An interface a project registers as one it means to keep, claimed by the source that implements it. The marker it is claimed with is its namespace. |
| Behavior | A scenario the specification declares in a BDD style, claimed by the test that implements it. |
