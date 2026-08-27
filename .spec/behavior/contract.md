# Contract

The interfaces a project registers, and what source claims to implement them.

What this establishes is that a registered interface is implemented somewhere
in scope, and reached the way the specification says — never that what it does
behind that is right. It is the same sentence Behavior turns on, and it
licenses everything the mechanism cannot check.

### Verification runs one way

An interface nothing claims is a difference, answered at the line registering
it, because that is where a reader chooses between writing the code and
dropping the contract. An interface nobody registered is not one: only the
contracts that matter are written down, so an absent registration says nothing
about the code.

A claim resolving to no contract belongs to the marker reading alone, since it
is about a claim and the syntax tree makes none. It is a comparison that could
not be made rather than a difference.

A name the language it named could spell no definition of stops the mechanism
rather than answering. Reporting it would blame the code for a specification
that says how its names are spelled and then writes one that language cannot
spell.

### A second way in

A behavior may be claimed by as many tests as exercise it, but a contract is
the way in, so a second one is an entrance the specification does not
describe. Under the marker reading that is one interface claimed in two
places; under the other it is one name defined with two shapes.

Which is why a method defined twice said nothing while only names were
compared: the name is the way in, and there was one of them. Definitions
agreeing on their shape are one way in still, so ordinary reopening goes on
saying nothing. Both places are answered, each naming the other, since
deciding which to keep means comparing them.

### What is compared, and what stays out

A shape half-registered would let the rest drift, which is why a registered
shape is compared entire and an unregistered one asks for nothing. Where the
definitions disagree among themselves the contract is not also compared
against one of them: two entrances are already the answer.

`positional` is the one kind word this tool owns. It names the parameter a
caller writes with no marking of any sort, which every language has one of,
and it is what a contract leaving `kind` out is compared as — so a reading
answers it for that parameter and names the rest itself. Every other kind word
belongs to the language and lives in the reading that answers it. Contract
compares them as text without learning what any of them means, so a
specification writes the words its own language uses.

`internal` is a fact about the interface rather than a preference about pages,
which is what separates it from a configuration switching a whole
specification off.

### Which language spells a name

`include` says which files a reading reaches and never what they are written
in: a generated file may carry one language under an extension nobody knows. A
name, though, is spelled the way one language spells it and two of them can
spell one name differently, so the reading that compares names says which
language it means.

A marker needs none, because a claim is a claim in whatever the file is
written in. Naming both says one thing twice, and naming neither leaves
nothing to say how a name is spelled — each is a specification that cannot be
read rather than a difference to report. So is a language this build was not
given: what an executable can read is decided when it is built, and a run that
guessed would compare against the wrong spelling.

## Includes

- `test/contract_test.rb`

## `T-001` What the directory registers, and where

| Step | Statement |
| --- | --- |
| Given | a contract directory holding several definitions |
| When | the directory is loaded |
| Then | each interface answers with its name, what it is for, and the line registering it |

## `T-002` A directory nobody wrote

| Step | Statement |
| --- | --- |
| Given | a root with no contract directory |
| When | the directory is loaded |
| Then | no contracts are registered |

## `T-003` The words to look for

| Step | Statement |
| --- | --- |
| Given | definitions naming their markers, two of them sharing one |
| When | the words are asked for |
| Then | each word answers once, however many definitions claim it |

## `T-004` The same name under two markers

| Step | Statement |
| --- | --- |
| Given | two definitions registering one name under different markers |
| When | the directory is loaded |
| Then | both are registered, because the marker is the namespace |

## `T-005` One name twice under one marker

| Step | Statement |
| --- | --- |
| Given | two definitions registering the same name under the same marker |
| When | the directory is loaded |
| Then | the message names both places, relative to where the run started |

## `T-006` A contract with no name

| Step | Statement |
| --- | --- |
| Given | a definition registering a contract that names nothing |
| When | the directory is loaded |
| Then | the file is named as registering a contract nothing can claim |

## `T-007` A definition with no marker

| Step | Statement |
| --- | --- |
| Given | a definition that does not say what word claims it |
| When | the directory is loaded |
| Then | it is registered as one the syntax tree answers rather than refused |

## `T-008` A specification that will not parse

| Step | Statement |
| --- | --- |
| Given | a contract definition that is not readable JSON |
| When | the directory is loaded |
| Then | the file is named as unreadable |

## `T-009` An interface nothing claims

| Step | Statement |
| --- | --- |
| Given | a registered interface no claim in scope names |
| When | the two sides are compared |
| Then | it is answered at the line registering it, as claimed nowhere it includes |

## `T-010` A claim resolving to no contract

| Step | Statement |
| --- | --- |
| Given | a claim naming something no definition registers under that marker |
| When | the two sides are compared |
| Then | the claim is answered at the line it sits on as resolving to no contract |

## `T-011` A claim naming no contract at all

| Step | Statement |
| --- | --- |
| Given | a claim carrying its marker and nothing after it |
| When | the two sides are compared |
| Then | the claim is answered as naming no contract rather than being passed over |

## `T-012` One contract claimed in two places

| Step | Statement |
| --- | --- |
| Given | two places claiming one registered interface |
| When | the two sides are compared |
| Then | each place is answered naming the other |

## `T-014` The files to look in

| Step | Statement |
| --- | --- |
| Given | definitions whose includes cover different directories |
| When | the scope is asked for |
| Then | the union of what every definition reaches answers, without repeats |

## `T-035` What each definition's include reaches

| Step | Statement |
| --- | --- |
| Given | two definitions writing different includes over the same tree |
| When | the files each one reaches are taken |
| Then | each answers the files its own include covers and no other definition's |

## `T-036` A contract claimed only from outside its own definition

| Step | Statement |
| --- | --- |
| Given | a contract whose definition includes one directory |
| Given | a claim of it sitting in a file that definition does not include |
| When | the two sides are compared |
| Then | the contract answers as one nothing claims |

## `T-037` The claim that could not implement it

| Step | Statement |
| --- | --- |
| Given | a contract whose definition includes one directory |
| Given | a claim of it sitting in a file that definition does not include |
| When | the two sides are compared |
| Then | the claim answers at the line it sits on, naming the specification that registers it |

## `T-038` A declaration outside the definition registering its name

| Step | Statement |
| --- | --- |
| Given | a name registered by a definition that includes one directory |
| Given | a declaration of that name from a file the definition does not include |
| When | the declarations that can define what they name are taken |
| Then | that declaration is left out, and nothing answers for it |

## `T-015` A contract the named language cannot spell

| Step | Statement |
| --- | --- |
| Given | a definition naming a language rather than a marker |
| Given | an interface named the way a route is named |
| When | the directory is loaded |
| Then | the file is named as registering a name that language cannot spell |

## `T-016` An interface the syntax tree does not define

| Step | Statement |
| --- | --- |
| Given | a definition naming no marker |
| Given | names the source in scope declares, one of them missing |
| When | the two sides are compared |
| Then | the missing one is answered at the line registering it, as defined nowhere it includes |

## `T-017` One name twice with no marker

| Step | Statement |
| --- | --- |
| Given | two definitions naming no marker and registering the same name |
| When | the directory is loaded |
| Then | the message names both places without a namespace in front of the name |

## `T-018` An internal interface is verified like any other

| Step | Statement |
| --- | --- |
| Given | a definition registering an internal interface nothing declares |
| When | the two sides are compared |
| Then | it is answered the way a published one would be |

## `T-019` The shape a contract registers

| Step | Statement |
| --- | --- |
| Given | a contract registering parameters, one of them naming no kind |
| When | the directory is read |
| Then | the parameter naming no kind answers the one a bare name says |

## `T-020` An interface defined with another shape

| Step | Statement |
| --- | --- |
| Given | a contract registering a shape |
| Given | source defining that interface with another |
| When | the two are compared |
| Then | the interface answers at the line registering it, naming both shapes |

## `T-021` A contract registering no shape

| Step | Statement |
| --- | --- |
| Given | a contract naming an interface and no parameters |
| Given | source defining it with parameters |
| When | the two are compared |
| Then | nothing answers |

## `T-022` One name defined with two shapes

| Step | Statement |
| --- | --- |
| Given | a registered interface defined twice, the two disagreeing on what a caller writes |
| When | the two are compared |
| Then | each definition answers, naming the other |

## `T-023` Definitions agreeing on their shape

| Step | Statement |
| --- | --- |
| Given | a registered interface defined twice with the same parameters |
| When | the two are compared |
| Then | nothing answers |

## `T-024` Parameters registered under a marker

| Step | Statement |
| --- | --- |
| Given | a contract file naming a marker and giving an interface parameters |
| When | the directory is read |
| Then | the file is named as one that cannot be read |

## `T-025` A name the specification uses at more than one depth

| Step | Statement |
| --- | --- |
| Given | a contract file whose kind, one contract and one parameter of another are spelled alike |
| When | the directory is read |
| Then | each contract answers at the line declaring it |

## `T-032` A definition that says neither how to claim nor how to spell

| Step | Statement |
| --- | --- |
| Given | a definition naming no marker and no language |
| When | the directory is loaded |
| Then | the file is named as leaving nothing to say how its names are spelled |

## `T-033` A language this build does not carry

| Step | Statement |
| --- | --- |
| Given | a definition naming a language the executable was not built with |
| When | the directory is loaded |
| Then | the file is named as asking for a language this sumi does not carry |

## `T-034` A definition naming both a marker and a language

| Step | Statement |
| --- | --- |
| Given | a definition naming a marker and a language |
| When | the directory is loaded |
| Then | the file is named as saying both, where a claim needs neither |
