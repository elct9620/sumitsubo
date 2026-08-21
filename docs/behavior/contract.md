# Contract

The interfaces a project registers, and what source claims to implement them.

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

## T-015 — A contract no Ruby declaration can be

| Step | Statement |
| --- | --- |
| Given | a definition naming no marker |
| Given | an interface named the way a route is named |
| When | the directory is loaded |
| Then | the file is named as registering something no Ruby declaration can be |

## T-016 — An interface the syntax tree does not declare

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
