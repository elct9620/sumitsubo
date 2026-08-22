# Contract

The interfaces a project registers, and what source claims to implement them.

What this establishes is that a registered interface is implemented somewhere in scope, and reached the way the specification says — never that what it does behind that is right. It is the same sentence Behavior turns on, and it licenses everything the mechanism cannot check.

## Verification runs one way

An interface nothing claims is a difference, answered at the line registering it, because that is where a reader chooses between writing the code and dropping the contract. An interface nobody registered is not one: only the contracts that matter are written down, so an absent registration says nothing about the code.

A claim resolving to no contract belongs to the marker reading alone, since it is about a claim and the syntax tree makes none. It is a comparison that could not be made rather than a difference.

A name the other reading could resolve to no construct stops the mechanism rather than answering. Read as Ruby, a route-shaped name is undefined everywhere, and reporting that would blame the code for a specification that lost its marker.

## A second way in

A behavior may be claimed by as many tests as exercise it, but a contract is the way in, so a second one is an entrance the specification does not describe. Under the marker reading that is one interface claimed in two places; under the other it is one name defined with two shapes.

Which is why a method defined twice said nothing while only names were compared: the name is the way in, and there was one of them. Definitions agreeing on their shape are one way in still, so ordinary reopening goes on saying nothing. Both places are answered, each naming the other, since deciding which to keep means comparing them.

## What is compared, and what stays out

A contract registering parameters is compared against them entire, since a shape half-registered would let the rest drift; one registering none asks for none to be compared, which is the same one-way rule. Where the definitions disagree among themselves the contract is not also compared against one of them: two entrances are already the answer.

The kind words a parameter carries are the language's own, and they live in the reading that answers them. Contract compares them as text without learning what any of them means, which is what lets a specification stay silent about the language it is about — `include` already says which files, and those files are read by whatever answers for them.

`internal` is a fact about the interface rather than a preference about pages, which is what separates it from a configuration switching a whole specification off. A kind whose every interface is internal has nothing to render at all.

## T-001 — What the directory registers, and where

| Step | Statement |
| --- | --- |
| Given | a contract directory holding several definitions |
| When | the directory is loaded |
| Then | each interface answers with its name, what it is for, and the line registering it |

## T-002 — A directory nobody wrote

| Step | Statement |
| --- | --- |
| Given | a root with no contract directory |
| When | the directory is loaded |
| Then | no contracts are registered |

## T-003 — The words to look for

| Step | Statement |
| --- | --- |
| Given | definitions naming their markers, two of them sharing one |
| When | the words are asked for |
| Then | each word answers once, however many definitions claim it |

## T-004 — The same name under two markers

| Step | Statement |
| --- | --- |
| Given | two definitions registering one name under different markers |
| When | the directory is loaded |
| Then | both are registered, because the marker is the namespace |

## T-005 — One name twice under one marker

| Step | Statement |
| --- | --- |
| Given | two definitions registering the same name under the same marker |
| When | the directory is loaded |
| Then | the message names both places, relative to where the run started |

## T-006 — A contract with no name

| Step | Statement |
| --- | --- |
| Given | a definition registering a contract that names nothing |
| When | the directory is loaded |
| Then | the file is named as registering a contract nothing can claim |

## T-007 — A definition with no marker

| Step | Statement |
| --- | --- |
| Given | a definition that does not say what word claims it |
| When | the directory is loaded |
| Then | it is registered as one the syntax tree answers rather than refused |

## T-008 — A specification that will not parse

| Step | Statement |
| --- | --- |
| Given | a contract definition that is not readable JSON |
| When | the directory is loaded |
| Then | the file is named as unreadable |

## T-009 — An interface nothing claims

| Step | Statement |
| --- | --- |
| Given | a registered interface no claim in scope names |
| When | the two sides are compared |
| Then | it is answered at the line registering it, naming the scope that was searched |

## T-010 — A claim resolving to no contract

| Step | Statement |
| --- | --- |
| Given | a claim naming something no definition registers under that marker |
| When | the two sides are compared |
| Then | the claim is answered at the line it sits on as resolving to no contract |

## T-011 — A claim naming no contract at all

| Step | Statement |
| --- | --- |
| Given | a claim carrying its marker and nothing after it |
| When | the two sides are compared |
| Then | the claim is answered as naming no contract rather than being passed over |

## T-012 — One contract claimed in two places

| Step | Statement |
| --- | --- |
| Given | two places claiming one registered interface |
| When | the two sides are compared |
| Then | each place is answered naming the other |

## T-013 — The document a definition becomes

| Step | Statement |
| --- | --- |
| Given | a definition registering interfaces with descriptions |
| When | it is rendered |
| Then | the page carries the names and what each is for, and neither the marker nor the globs |

## T-014 — The files to look in

| Step | Statement |
| --- | --- |
| Given | definitions whose includes cover different directories |
| When | the scope is asked for |
| Then | the union of every include answers, without repeats |

## T-015 — A contract no Ruby definition can be

| Step | Statement |
| --- | --- |
| Given | a definition naming no marker |
| Given | an interface named the way a route is named |
| When | the directory is loaded |
| Then | the file is named as registering something no Ruby definition can be |

## T-016 — An interface the syntax tree does not define

| Step | Statement |
| --- | --- |
| Given | a definition naming no marker |
| Given | names the source in scope declares, one of them missing |
| When | the two sides are compared |
| Then | the missing one is answered at the line registering it, naming the scope that was searched |

## T-017 — One name twice with no marker

| Step | Statement |
| --- | --- |
| Given | two definitions naming no marker and registering the same name |
| When | the directory is loaded |
| Then | the message names both places without a namespace in front of the name |

## T-018 — An internal interface is verified like any other

| Step | Statement |
| --- | --- |
| Given | a definition registering an internal interface nothing declares |
| When | the two sides are compared |
| Then | it is answered the way a published one would be |

## T-019 — The shape a contract registers

| Step | Statement |
| --- | --- |
| Given | a contract registering parameters, one of them naming no kind |
| When | the directory is read |
| Then | the parameter naming no kind answers the one a bare name says |

## T-020 — An interface defined with another shape

| Step | Statement |
| --- | --- |
| Given | a contract registering a shape |
| Given | source defining that interface with another |
| When | the two are compared |
| Then | the interface answers at the line registering it, naming both shapes |

## T-021 — A contract registering no shape

| Step | Statement |
| --- | --- |
| Given | a contract naming an interface and no parameters |
| Given | source defining it with parameters |
| When | the two are compared |
| Then | nothing answers |

## T-022 — One name defined with two shapes

| Step | Statement |
| --- | --- |
| Given | a registered interface defined twice, the two disagreeing on what a caller writes |
| When | the two are compared |
| Then | each definition answers, naming the other |

## T-023 — Definitions agreeing on their shape

| Step | Statement |
| --- | --- |
| Given | a registered interface defined twice with the same parameters |
| When | the two are compared |
| Then | nothing answers |

## T-024 — Parameters registered under a marker

| Step | Statement |
| --- | --- |
| Given | a contract file naming a marker and giving an interface parameters |
| When | the directory is read |
| Then | the file is named as one that cannot be read |

## T-025 — A name the specification uses at more than one depth

| Step | Statement |
| --- | --- |
| Given | a contract file whose kind, one contract and one parameter of another are spelled alike |
| When | the directory is read |
| Then | each contract answers at the line declaring it |

## T-026 — The prose a specification carries for its document

| Step | Statement |
| --- | --- |
| Given | a contract file writing notes under the kind and under one contract |
| When | the definition is rendered |
| Then | each note answers under the heading it hangs from |

## T-027 — A heading answers relative to where its notes hang

| Step | Statement |
| --- | --- |
| Given | a note under a contract writing a heading at level 1 |
| When | the definition is rendered |
| Then | the heading sits one level under the contract's own |

## T-028 — Notes under an interface the project does not publish

| Step | Statement |
| --- | --- |
| Given | a contract marked internal writing notes of its own |
| When | the definition is rendered |
| Then | the document carries neither the interface nor its notes |

## T-029 — A note of a kind this document has no words for

| Step | Statement |
| --- | --- |
| Given | a contract file writing a note whose type is none of the three |
| When | the directory is read |
| Then | the file is named as one that cannot be read |

## T-030 — A note whose text is not lines

| Step | Statement |
| --- | --- |
| Given | a contract file writing a note whose text is one string |
| When | the directory is read |
| Then | the file is named as one that cannot be read |

## T-031 — A heading deeper than a page carries

| Step | Statement |
| --- | --- |
| Given | a contract file writing a heading below the deepest level |
| When | the directory is read |
| Then | the file is named as one that cannot be read |
