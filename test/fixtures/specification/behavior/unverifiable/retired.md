# Retired

What a feature cannot be held to yet, and what it is retiring.

## Includes

- `test/*_test.rb`

## `R-001` A behavior no test can reach yet

| Step | Statement |
| --- | --- |
| Given | a run that writes outside the directory |
| When | `sumi verify` runs |
| Then | the file outside is written |
| unverifiable | a test reads nothing outside the directory |

## `R-002` A behavior a test has come to witness

| Step | Statement |
| --- | --- |
| Given | a run that writes into the directory |
| When | `sumi verify` runs |
| Then | the file inside is written |
| unverifiable | no test could read the directory |

## `R-003` A behavior on its way out

| Step | Statement |
| --- | --- |
| Given | a run with no configuration |
| When | `sumi verify` runs |
| Then | the defaults are written out |
| deprecated | R-002 replaces it |
