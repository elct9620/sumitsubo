# Stats

How each behavior specification is witnessed, counted for a person to read.
A place is a comment: claims written in one comment are one place, however
many scenarios it names.

Nothing is compared, so a count is never a difference. What cannot be read is
said, since a count missing a specification is not one.

## Includes

- `test/stats_test.rb`

## `SA-001` Each specification and how it is claimed

| Step | Statement |
| --- | --- |
| Given | features whose scenarios are claimed from several places, one comment naming three |
| When | `sumi stats` runs |
| Then | each answers with its scenarios, its places, and the most one place claims |

## `SA-002` The busiest place comes first

| Step | Statement |
| --- | --- |
| Given | two features, one with a place claiming more of its scenarios |
| When | `sumi stats` runs |
| Then | that feature is answered first, with where its busiest place begins |

## `SA-003` Scenarios set apart are counted

| Step | Statement |
| --- | --- |
| Given | a scenario nothing claims, one unverifiable, and one deprecated |
| When | `sumi stats` runs |
| Then | the closing line counts each, and the run answers 0 |

## `SA-004` Files reached that claim nothing

| Step | Statement |
| --- | --- |
| Given | a file the features reach with no claim in it |
| When | `sumi stats` runs |
| Then | the file is listed as reached with nothing claimed |

## `SA-005` A feature that cannot be read

| Step | Statement |
| --- | --- |
| Given | one id declared twice, or a scenario heading with no id |
| When | `sumi stats` runs |
| Then | that is said instead of a count, and the run answers 2 |

## `SA-006` No specification at all

| Step | Statement |
| --- | --- |
| Given | a directory with no specification root |
| When | `sumi stats` runs |
| Then | it says where it looked, and the run answers 2 |
