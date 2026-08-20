# Behavior

The scenarios a project declares, and where each one sits.

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
