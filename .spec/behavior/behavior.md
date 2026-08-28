# Behavior

The scenarios a project declares, and where each one sits.

What this establishes is that a behavior was read and implemented, never that
the implementation is right. Nothing mechanical can judge whether the code
under a claim does what the claim says, so that one sentence licenses
everything the mechanism cannot check.

The model is Gherkin's, not its file format: these scenarios are read rather
than executed, so `.feature` would buy nothing the other mechanisms could
share.

Of the three disciplines that make one sentence each reachable, the reason is
the one that creeps back into a `then`. It belongs to the title, and the exit
code follows from which of the three the `then` named.

A scenario nothing claims is answered at the line declaring it because that is
where a reader chooses between writing the test and dropping the scenario.
Both findings collect before reporting, the way a linter does, so a renamed id
is fixed in one pass.

## Includes

- `test/behavior_test.rb`

## `B-001` What the directory declares, and where

| Step | Statement |
| --- | --- |
| Given | a behavior directory holding more than one specification |
| When | the directory is loaded |
| Then | every scenario answers with the line of the file that declares it |

## `B-002` A directory nobody wrote

| Step | Statement |
| --- | --- |
| Given | a behavior directory that is not there |
| When | the directory is loaded |
| Then | no scenario is declared |

## `B-003` The root arrives absolute

| Step | Statement |
| --- | --- |
| Given | a behavior directory named by an absolute path |
| When | a message about one of its scenarios is composed |
| Then | the path answers relative to where the run started |

## `B-004` One id under two scenarios

| Step | Statement |
| --- | --- |
| Given | two specifications declaring the same id |
| When | the directory is loaded |
| Then | both places the id was declared are named |

## `B-005` A scenario with no id

| Step | Statement |
| --- | --- |
| Given | a specification declaring a scenario without an id |
| When | the directory is loaded |
| Then | the file is named as declaring a scenario nothing can reference |

## `B-007` Several ids on one marker line

| Step | Statement |
| --- | --- |
| Given | the text a marker line carries after its keyword, naming more than one id |
| When | the mechanism reads it |
| Then | each id is answered on its own |

## `B-011` What each feature's include reaches

| Step | Statement |
| --- | --- |
| Given | two features writing different includes over the same directory |
| When | the files each one reaches are taken |
| Then | each answers the files its own include covers and no other feature's |

## `B-012` A scenario claimed only from outside its own feature

| Step | Statement |
| --- | --- |
| Given | a scenario whose feature includes one file |
| Given | a claim of it sitting in a file that feature does not include |
| When | the two sides are compared |
| Then | the scenario answers as one nothing claims |

## `B-013` The claim that could not witness it

| Step | Statement |
| --- | --- |
| Given | a scenario whose feature includes one file |
| Given | a claim of it sitting in a file that feature does not include |
| When | the two sides are compared |
| Then | the claim answers at the line it sits on, naming the specification that declares it |

## `B-014` Which files a directory holds that this build can read

| Step | Statement |
| --- | --- |
| Given | a behavior directory holding a file in each format this build carries |
| Given | a file no parser answers for |
| When | the directory is loaded |
| Then | a feature is read from each file some parser answers for, and no other |

## `B-015` An include covering no file

| Step | Statement |
| --- | --- |
| Given | a feature whose include covers no file |
| When | the includes are asked what they cover |
| Then | the include answers at the line of the specification that wrote it |
