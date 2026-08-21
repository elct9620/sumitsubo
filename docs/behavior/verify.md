# Verify

Checking the source against the verifiable part of the specification, and answering what was found.

## V-001 — Code that drifted from its glossary

| Step | Statement |
| --- | --- |
| Given | a glossary declaring a word one of its terms rejects |
| Given | a comment in scope using that word |
| When | `sumi verify` runs |
| Then | one finding is reported for the line the word appears on |

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

## V-016 — A contract naming no marker and nothing Ruby can define

| Step | Statement |
| --- | --- |
| Given | a contract naming no marker |
| Given | an interface named the way a route is named |
| When | the two sides are compared |
| Then | the file is named as registering something no Ruby definition can be |
