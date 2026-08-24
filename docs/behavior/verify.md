# Verify

Checking the source against the verifiable part of the specification, and answering what was found.

The reader is an agent working in the codebase, with a person reading over its shoulder. Findings answer as `path:line` relative to where the run started, one per line, sorted on a key that leaves no ties.

One finding per line however often the word appears on it: the line is what a reader goes to, and what an exclusion would one day be written against.

The three words a 2 stands for — absent, unreadable, ambiguous — are a list that grows with every mechanism. A mechanism that could not be read stops that mechanism and no other, the way a linter reports every file it managed to parse, and arguments the run cannot act on answer the same 2: a run that compared nothing has nothing to certify.

Findings and failures share one stream, so whoever reads them reads them in the order they happened.

## V-001 — Code that drifted from its glossary

| Step | Statement |
| --- | --- |
| Given | a glossary declaring a word one of its terms rejects |
| Given | a comment in scope using that word |
| When | `sumi verify` runs |
| Then | one finding is reported for the line the word appears on |

## V-019 — A finding set aside by hand, and an ignore that no longer names one

| Step | Statement |
| --- | --- |
| Given | a rejection carrying an ignore for the line a comment trips on |
| Given | and a second ignore naming a line nothing trips on |
| When | `sumi verify` runs |
| Then | the first line is not reported, and the second ignore answers at the specification as a comparison that could not be made |

## V-020 — A build directory the project excludes

| Step | Statement |
| --- | --- |
| Given | a project whose configuration excludes a directory |
| Given | source under it drifted from the glossary the same way source outside it did |
| When | the run verifies |
| Then | only the line outside the excluded directory answers |

## V-021 — A build directory the .gitignore already leaves out

| Step | Statement |
| --- | --- |
| Given | a project keeping a .gitignore that names a build directory |
| Given | source under it drifted from the glossary the same way source outside it did |
| When | the run verifies |
| Then | only the line outside that directory answers, without the configuration saying so again |

## V-022 — An include covering no file

| Step | Statement |
| --- | --- |
| Given | a vocabulary whose include matches nothing |
| Given | a second vocabulary whose only file the project excludes |
| When | the run verifies |
| Then | the first refuses to certify at the line that wrote it, and the second says nothing |

## V-023 — A claim the feature declaring it does not reach

| Step | Statement |
| --- | --- |
| Given | a scenario declared by a feature that includes one test file |
| Given | a claim of that scenario sitting in another test file the run reads |
| When | `sumi verify` runs |
| Then | the claim is reported at the line it sits on as sitting outside what that specification includes |

## V-002 — The same run from a subdirectory

| Step | Statement |
| --- | --- |
| Given | a project whose source has drifted from its glossary |
| When | `sumi verify` runs from a subdirectory of that project |
| Then | the same findings answer with paths relative to where the run started |

## V-003 — A specification the configuration switched off

| Step | Statement |
| --- | --- |
| Given | a .sumi.json declaring the glossary is not to be verified |
| Given | source that has drifted from that glossary |
| When | `sumi verify` runs |
| Then | the switched-off specification contributes no findings |

## V-004 — Every declared behavior is claimed

| Step | Statement |
| --- | --- |
| Given | a behavior specification whose every scenario is claimed by source in scope |
| When | `sumi verify` runs |
| Then | no difference is reported between the two sides |

## V-005 — A scenario nothing claims

| Step | Statement |
| --- | --- |
| Given | a behavior specification with a scenario no source in scope claims |
| When | `sumi verify` runs |
| Then | the scenario is reported at the line of the specification that declares it, naming the scope that was searched |

## V-006 — A claim resolving to no scenario

| Step | Statement |
| --- | --- |
| Given | source claiming an id no behavior specification declares |
| When | `sumi verify` runs |
| Then | the claim is reported at the line it sits on as resolving to no scenario |

## V-007 — Source the grammar cannot read

| Step | Statement |
| --- | --- |
| Given | a Ruby file in scope the grammar cannot parse |
| When | `sumi verify` runs |
| Then | the file is named as one the grammar could not read rather than reported as agreeing |

## V-008 — No specification to verify from

| Step | Statement |
| --- | --- |
| Given | a directory with no specification root |
| When | `sumi verify` runs |
| Then | the missing root is named |

## V-009 — A root the configuration points at but nothing wrote

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming a root no one created |
| When | `sumi verify` runs |
| Then | that root is named as the specification that is not there |

## V-010 — A clone that arrived without the empty behavior directory

| Step | Statement |
| --- | --- |
| Given | a project whose behavior directory git did not carry |
| When | `sumi verify` runs |
| Then | no difference is reported |

## V-011 — A mechanism that could not be read does not silence the others

| Step | Statement |
| --- | --- |
| Given | a project whose glossary names a file the grammar cannot parse |
| Given | a scenario in the same project that no source in scope claims |
| When | `sumi verify` runs |
| Then | the unclaimed scenario is reported alongside the file that could not be read |

## V-012 — An interface nothing claims

| Step | Statement |
| --- | --- |
| Given | a contract specification registering an interface no source in scope claims |
| When | `sumi verify` runs |
| Then | the interface is reported at the line registering it, naming the scope that was searched |

## V-013 — One interface claimed in two places

| Step | Statement |
| --- | --- |
| Given | two places in scope claiming one registered interface |
| When | `sumi verify` runs |
| Then | each place is reported naming the other |

## V-014 — A claim resolving to no contract

| Step | Statement |
| --- | --- |
| Given | source claiming a name no contract specification registers under that marker |
| When | `sumi verify` runs |
| Then | the claim is reported at the line it sits on as resolving to no contract |

## V-015 — An interface the syntax tree does not declare

| Step | Statement |
| --- | --- |
| Given | a contract naming no marker |
| Given | a registered method no source in scope defines |
| When | the two sides are compared |
| Then | it is answered at the line registering it, naming the scope that was searched |

## V-016 — A contract the language it named cannot spell

| Step | Statement |
| --- | --- |
| Given | a contract naming a language rather than a marker |
| Given | an interface named the way a route is named |
| When | the two sides are compared |
| Then | the file is named as registering a name that language cannot spell |

## V-017 — Source whose shape drifted from the contract

| Step | Statement |
| --- | --- |
| Given | a project registering the shape of two interfaces |
| Given | one defined with another shape and one defined twice with two |
| When | the run verifies |
| Then | both answer as differences and the run answers 1 |

## V-018 — A registered class reopened without changing it

| Step | Statement |
| --- | --- |
| Given | a project registering a class |
| Given | source reopening that class |
| When | the run verifies |
| Then | nothing answers for it |
