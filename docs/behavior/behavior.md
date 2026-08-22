# Behavior

The scenarios a project declares, and where each one sits.

What this establishes is that a behavior was read and implemented, never that the implementation is right. Nothing mechanical can judge whether the code under a claim does what the claim says, so that one sentence licenses everything the mechanism cannot check.

The model is Gherkin's, not its file format: these scenarios are read rather than executed, so `.feature` would buy nothing the other mechanisms could share.

## One sentence each

`when` and `then` are one sentence each, which three disciplines make reachable rather than a cap that turns work away: the operation under test is the last one and everything before it is `given`; an outcome is what one observation settles, so two observations are two scenarios; and `then` names the observable difference and stops.

Not the exit code, which follows from which of the three a `then` names, and not the reason, which belongs to the title. The reason is the one that creeps back in.

## Verification runs one way

A scenario nothing claims is a difference, answered at the line of the specification declaring it, because that is where a reader chooses between writing the test and dropping the scenario. A claim resolving to no scenario is not one: there is nothing on the specification side to compare it against.

Both collect before reporting, the way a linter does, so a renamed id is fixed in one pass.

## B-001 — What the directory declares, and where

| Step | Statement |
| --- | --- |
| Given | a behavior directory holding more than one specification |
| When | the directory is loaded |
| Then | every scenario answers with the line of the file that declares it |

## B-002 — A directory nobody wrote

| Step | Statement |
| --- | --- |
| Given | a behavior directory that is not there |
| When | the directory is loaded |
| Then | no scenario is declared |

## B-003 — The root arrives absolute

| Step | Statement |
| --- | --- |
| Given | a behavior directory named by an absolute path |
| When | a message about one of its scenarios is composed |
| Then | the path answers relative to where the run started |

## B-004 — One id under two scenarios

| Step | Statement |
| --- | --- |
| Given | two specifications declaring the same id |
| When | the directory is loaded |
| Then | both places the id was declared are named |

## B-005 — A scenario with no id

| Step | Statement |
| --- | --- |
| Given | a specification declaring a scenario without an id |
| When | the directory is loaded |
| Then | the file is named as declaring a scenario nothing can reference |

## B-006 — A specification that will not parse

| Step | Statement |
| --- | --- |
| Given | a behavior specification that is not readable JSON |
| When | the directory is loaded |
| Then | the file is named as unreadable |

## B-007 — Several ids on one marker line

| Step | Statement |
| --- | --- |
| Given | the text a marker line carries after its keyword, naming more than one id |
| When | the mechanism reads it |
| Then | each id is answered on its own |

## B-008 — Two scenarios on one line

| Step | Statement |
| --- | --- |
| Given | a specification declaring two scenarios on the same line |
| When | the directory is loaded |
| Then | both answer at that line rather than the second answering at none |

## B-009 — The prose a feature carries for its document

| Step | Statement |
| --- | --- |
| Given | a feature file writing notes of its own |
| When | the feature is rendered |
| Then | the notes answer between the description and the first scenario |

## B-010 — A note of a kind this document has no words for

| Step | Statement |
| --- | --- |
| Given | a feature file writing a note whose type is none the form has |
| When | the directory is read |
| Then | the file is named as one that cannot be read, and the help that has the form |
