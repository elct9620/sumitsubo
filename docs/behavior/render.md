# Render

Rendering the structured specification into documents a person reads.

## R-001 — The vocabulary becomes a document

| Step | Statement |
| --- | --- |
| Given | a glossary declaring terms |
| When | `sumi render` runs |
| Then | a glossary document is written under the configured documents path |

## R-002 — One document per feature

| Step | Statement |
| --- | --- |
| Given | a behavior specification holding one file per feature |
| When | `sumi render` runs |
| Then | each feature is written to a document named after the file declaring it |

## R-003 — A specification the configuration switched off

| Step | Statement |
| --- | --- |
| Given | a .sumi.json declaring the glossary is not to be rendered |
| When | `sumi render` runs |
| Then | the switched-off specification leaves no document behind |

## R-004 — Nothing to render is not a failure

| Step | Statement |
| --- | --- |
| Given | a directory with no specification |
| When | `sumi render` runs |
| Then | nothing is written |

## R-005 — A second run brings the document up to date

| Step | Statement |
| --- | --- |
| Given | a project whose rendered document no longer matches the specification |
| When | `sumi render` runs again |
| Then | the document is replaced by what the specification now says |

## R-006 — A specification that could not be read

| Step | Statement |
| --- | --- |
| Given | a behavior specification that is not readable JSON |
| When | `sumi render` runs |
| Then | the file is named as one that could not be read |

## R-007 — One document per kind of contract

| Step | Statement |
| --- | --- |
| Given | a contract specification registering interfaces |
| When | `sumi render` runs |
| Then | each definition is written to a document named after the file registering it |

## R-008 — An interface the project keeps but does not publish

| Step | Statement |
| --- | --- |
| Given | a definition registering one internal interface and one that is not |
| When | it is rendered |
| Then | the page carries only the one that is not internal |
