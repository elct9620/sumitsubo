# Relate

What specifications say of one another. A statement's attributes name the
statements it relates to and the ones it refines. The run keeps each as a
relation from the statement writing it.

A key is the statement's own key, kept by the mechanism writing it. One opening
with another mechanism's name and a space is that mechanism's.

`sumi relate` answers one statement and what it is related to, two relations
out, whether or not each mechanism is switched on. Nothing is compared, so it
never answers `1`.

## Includes

- `test/related_test.rb`
- `test/relate_test.rb`

## `RL-001` A scenario relating to another of its own

| Step | Statement |
| --- | --- |
| Given | a scenario whose relates names another scenario by its id |
| When | the relations its specifications write are kept |
| Then | one relates relation runs from the first scenario to the second |

## `RL-002` A key naming another mechanism's statement

| Step | Statement |
| --- | --- |
| Given | a scenario whose relates names a contract with the mechanism's name first |
| When | the relations its specifications write are kept |
| Then | the relation runs to that contract, under the contract mechanism |

## `RL-003` A refinement runs from the narrower statement

| Step | Statement |
| --- | --- |
| Given | a scenario whose refines names another |
| When | the relations its specifications write are kept |
| Then | one refines relation runs from the scenario writing it to the one it names |

## `RL-004` A statement and what it is related to, two relations out

| Step | Statement |
| --- | --- |
| Given | a scenario related to a contract and refining a scenario, each related further out |
| When | `sumi relate` is given its id |
| Then | each relation answers two levels out, as a tree under the scenario |

## `RL-005` A statement met again is not opened a second time

| Step | Statement |
| --- | --- |
| Given | a scenario reached by two relations in one answer |
| When | `sumi relate` is given an id whose answer reaches it twice |
| Then | the second answers as seen above |

## `RL-006` A relation naming nothing

| Step | Statement |
| --- | --- |
| Given | a scenario relating to a key nobody declares |
| When | `sumi relate` is given its id |
| Then | that key answers as declared nowhere |

## `RL-007` Scenarios claimed in the same comment

| Step | Statement |
| --- | --- |
| Given | a scenario claimed in one comment with another |
| When | `sumi relate` is given its id |
| Then | the other answers as claimed beside it, marked as derived from the source |

## `RL-008` A statement another mechanism keeps

| Step | Statement |
| --- | --- |
| Given | a contract switched off, relating to scenarios |
| When | `sumi relate` is given its mechanism's name and key as one quoted word |
| Then | the contract answers with what it is related to, each scenario named with its mechanism |

## `RL-009` A refinement read from the statement it narrows

| Step | Statement |
| --- | --- |
| Given | a scenario refined by one scenario and refining another |
| When | `sumi relate` is given its id |
| Then | the one it narrows answers as refines, and the one narrowing it as refined by |

## `RL-010` A key nothing declares

| Step | Statement |
| --- | --- |
| Given | a key no specification declares |
| When | `sumi relate` is given it |
| Then | it says nothing declares it, and the run answers 0 |

## `RL-011` Nothing to relate

| Step | Statement |
| --- | --- |
| Given | no key |
| When | `sumi relate` runs |
| Then | it says what it takes, and the run answers 2 |

## `RL-012` A switched-off mechanism the answer names and cannot read

| Step | Statement |
| --- | --- |
| Given | contracts switched off and written out of shape, and a scenario relating to one |
| When | `sumi relate` is given the scenario's id |
| Then | the contract answers as unreadable, followed by the refusal, and the run answers 2 |
