# Configuration

Where a run is configured from, and what the configuration decides.

Walking up for the nearest configuration is what tsc and RuboCop both do: each searches the ancestor directories until one answers.

The base a configuration is read against and the one findings answer from are deliberately different. The first is what lets a run started anywhere under it reach the same files; the second is what lets a reader go straight to a finding.

`verify: false` and `render: false` are separate because a Render that only records a specification still needs one that is not checked.

`.spec` is the default because `spec/` is already RSpec's, and because a directory that does not start with a dot is one a build is liable to sweep in as source.

## C-001 — The nearest .sumi.json decides the base

| Step | Statement |
| --- | --- |
| Given | a .sumi.json at the top of a project |
| Given | a run starting several directories below it |
| When | the configuration is loaded |
| Then | the base is the directory holding that .sumi.json, however deep the run started |

## C-002 — With no .sumi.json, the repository it sits in

| Step | Statement |
| --- | --- |
| Given | a project with a .git but no .sumi.json |
| When | the configuration is loaded |
| Then | the base is the repository root, whether .git is a directory or a gitfile |

## C-003 — With neither, where the run started

| Step | Statement |
| --- | --- |
| Given | a directory with no .sumi.json and no .git above it |
| When | the configuration is loaded |
| Then | the base is where the run started |

## C-004 — A .sumi.json that will not parse

| Step | Statement |
| --- | --- |
| Given | a .sumi.json that is not readable JSON |
| When | the configuration is loaded |
| Then | the file is named as unreadable |

## C-005 — Only the exceptions are listed

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be verified |
| When | the configuration is asked about each specification |
| Then | the specification it named is not verified |

## C-006 — A specification nobody mentioned is verified

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be verified |
| When | the configuration is asked about each specification |
| Then | a specification the file does not mention is verified |

## C-007 — Where the rendered specification goes

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming a documents path |
| When | the configuration is loaded |
| Then | the documents base is that path, answered against the directory the file was found in |

## C-008 — A project that has said nothing writes to docs

| Step | Statement |
| --- | --- |
| Given | a project with no .sumi.json |
| When | the configuration is loaded |
| Then | the documents base is `docs` under the base |

## C-009 — A specification that is kept but not rendered

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be rendered |
| When | the configuration is asked about each specification |
| Then | the specification it named is not rendered |

## C-010 — A specification nobody mentioned is rendered

| Step | Statement |
| --- | --- |
| Given | a .sumi.json naming one specification as not to be rendered |
| When | the configuration is asked about each specification |
| Then | a specification the file does not mention is rendered |
