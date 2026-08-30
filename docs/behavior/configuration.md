# Configuration

Where a run is configured from, and what the configuration decides.

Walking up for the nearest configuration is what tsc and RuboCop both do: each
searches the ancestor directories until one answers.

The base a configuration is read against and the one findings answer from are
deliberately different. The first is what lets a run started anywhere under it
reach the same files; the second is what lets a reader go straight to a
finding.

`verify: false` keeps a specification the project means to hold without a run
being checked against it yet.

`.spec` is the default because `spec/` is already RSpec's, and because a
directory that does not start with a dot is one a build is liable to sweep in
as source.

## Includes

- `test/config_test.rb`

## `C-001` The nearest .sumi.json decides the base

| Step | Statement |
| --- | --- |
| Given | a .sumi.json at the top of a project |
| Given | a run starting several directories below it |
| When | the configuration is loaded |
| Then | the base is the directory holding that .sumi.json, however deep the run started |

## `C-002` With no .sumi.json, the repository it sits in

| Step | Statement |
| --- | --- |
| Given | a project with a .git but no .sumi.json |
| When | the configuration is loaded |
| Then | the base is the repository root, whether .git is a directory or a gitfile |

## `C-003` With neither, where the run started

| Step | Statement |
| --- | --- |
| Given | a directory with no .sumi.json and no .git above it |
| When | the configuration is loaded |
| Then | the base is where the run started |

## `C-004` A .sumi.json that will not parse

| Step | Statement |
| --- | --- |
| Given | a .sumi.json that is not readable JSON |
| When | the configuration is loaded |
| Then | the file is named as unreadable |

## `C-005` Only the exceptions are listed

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be verified |
| When | the configuration is asked about each specification |
| Then | the specification it named is not verified |

## `C-006` A specification nobody mentioned is verified

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be verified |
| When | the configuration is asked about each specification |
| Then | a specification the file does not mention is verified |

## `C-011` What the project leaves alone

| Step | Statement |
| --- | --- |
| Given | a configuration naming what to exclude |
| When | the configuration is loaded |
| Then | it answers the rules once for the project, and a configuration naming none answers none |

## `C-012` What the .gitignore beside it already said

| Step | Statement |
| --- | --- |
| Given | a project keeping a .gitignore |
| When | the configuration is loaded |
| Then | what git leaves out is excluded too |

## `C-013` A path put back, the configuration being read after the .gitignore

| Step | Statement |
| --- | --- |
| Given | a project keeping a .gitignore that leaves a path out |
| Given | a .sumi.json whose exclude names that path with a `!` |
| When | the configuration is loaded |
| Then | the path is left in |

## `C-014` The .gitignore switched off

| Step | Statement |
| --- | --- |
| Given | a project keeping a .gitignore |
| Given | a .sumi.json switching the .gitignore off |
| When | the configuration is loaded |
| Then | what git leaves out is not excluded |
