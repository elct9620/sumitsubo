# Glossary

The domain vocabulary a project declares, and the words it rejects in their place.

## G-001 — A section reaches the files its includes cover

| Step | Statement |
| --- | --- |
| Given | a glossary whose sections carry include globs |
| When | the sections are resolved against the base |
| Then | each section answers the files its globs cover |

## G-002 — A later term replaces an earlier one of the same name

| Step | Statement |
| --- | --- |
| Given | two sections covering one file and declaring the same term |
| When | the effective vocabulary for that file is worked out |
| Then | the later term replaces the earlier one outright, its rejected words included |

## G-003 — A missing glossary is a broken reference line

| Step | Statement |
| --- | --- |
| Given | a path where no glossary was written |
| When | the glossary is loaded |
| Then | the path is named as one holding no glossary |

## G-004 — A glossary that will not parse

| Step | Statement |
| --- | --- |
| Given | a glossary file that is not readable JSON |
| When | the glossary is loaded |
| Then | the file is named as unreadable |

## G-005 — A file declaring no glossary at all

| Step | Statement |
| --- | --- |
| Given | readable JSON with no glossary in it |
| When | the glossary is loaded |
| Then | the file is named as declaring no glossary |

## G-006 — The root arrives absolute

| Step | Statement |
| --- | --- |
| Given | a glossary named by an absolute path that is not there |
| When | the glossary is loaded |
| Then | the path answers relative to where the run started |
