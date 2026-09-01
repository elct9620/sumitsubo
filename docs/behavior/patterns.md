# Patterns

Which paths a run reads and which it leaves alone, matched against rules
written the way a `.gitignore` line is written.

The same text is read differently on the two sides: an exclusion turns a path
down wherever it sits, and an include is anchored to the base and names the
files a specification answers for.

## Includes

- `test/patterns_test.rb`

## `P-001` A directory named at any depth

| Step | Statement |
| --- | --- |
| Given | an exclusion naming a directory with no separator in it |
| When | a path is asked whether it is left out |
| Then | it reaches that directory wherever it sits and everything under it, and leaves alone the file named after it |

## `P-002` Anchored by a separator

| Step | Statement |
| --- | --- |
| Given | an exclusion carrying a separator at its start or in its middle |
| When | a path is asked whether it is left out |
| Then | it is read from the base rather than at any depth |

## `P-003` However many directories

| Step | Statement |
| --- | --- |
| Given | an exclusion carrying `**` |
| When | a path is asked whether it is left out |
| Then | it stands for however many directories, none included |

## `P-004` A name at any depth

| Step | Statement |
| --- | --- |
| Given | an exclusion naming files by a wildcard rather than a directory |
| When | a path is asked whether it is left out |
| Then | it reaches the name at any depth, the way one naming a directory does |

## `P-005` The last rule to match decides

| Step | Statement |
| --- | --- |
| Given | a rule turning a path down and a later one putting it back |
| When | the path is asked whether it is left out |
| Then | the later rule answers, so the order the project wrote them in is what a reader follows |

## `P-006` A rule matching nothing takes nothing out

| Step | Statement |
| --- | --- |
| Given | an exclusion no path matches |
| When | the paths are asked whether they are left out |
| Then | every one of them stands |

## `P-007` What an include reaches

| Step | Statement |
| --- | --- |
| Given | an include naming files under a wildcard directory |
| When | a path is asked whether the include covers it |
| Then | the whole path has to match, because an include is anchored to the base and names files |

## `P-008` One rule read as both

| Step | Statement |
| --- | --- |
| Given | one pattern with no separator |
| When | it is read as an exclusion and as an include |
| Then | the exclusion reaches the name at any depth and the include reaches the base and no deeper |

## `P-009` What a `.gitignore` holds

| Step | Statement |
| --- | --- |
| Given | a `.gitignore` written with remarks and blank lines between its sections |
| When | it is read for the rules it holds |
| Then | neither the remark nor the blank line is one |

## `P-010` What each shape an include is written in reaches

| Step | Statement |
| --- | --- |
| Given | every shape the includes of two real projects take, and three nobody has written yet |
| When | each is matched against a tree written out here |
| Then | each reaches the files it names, a trailing `**` reaching every depth the way a `.gitignore` reads one |

## `P-012` A hidden directory is the walk's to rule on

| Step | Statement |
| --- | --- |
| Given | a path inside a directory whose name begins with a dot |
| When | it is matched |
| Then | the matcher answers inside it, because skipping one is the walk's decision and not the matcher's |

## `P-013` A pattern written outside ASCII

| Step | Statement |
| --- | --- |
| Given | an include naming files in characters a byte count and a character index disagree about |
| When | a path is asked whether that include reaches it |
| Then | each pattern reaches the files it names, wherever its star or placeholder sits |
