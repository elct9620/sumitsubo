# Retired

What a feature cannot be held to yet, and what it is retiring.

## Includes

- `test/*_test.rb`

## `R-001` A behavior no test can reach yet

| Attribute | Value |
| --- | --- |
| unverifiable | a test reads nothing outside the directory |

| Step | Statement |
| --- | --- |
| Given | a run that writes outside the directory |
| When | `sumi verify` runs |
| Then | the file outside is written |

## `R-002` A behavior a test has come to witness

| Attribute | Value |
| --- | --- |
| unverifiable | no test could read the directory |

| Step | Statement |
| --- | --- |
| Given | a run that writes into the directory |
| When | `sumi verify` runs |
| Then | the file inside is written |

## `R-003` A behavior on its way out

| Attribute | Value |
| --- | --- |
| deprecated | R-002 replaces it |

| Step | Statement |
| --- | --- |
| Given | a run with no configuration |
| When | `sumi verify` runs |
| Then | the defaults are written out |
