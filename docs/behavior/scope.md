# Scope

Which files a specification's include covers, and the walk that finds them.

## Includes

- `test/scope_test.rb`

## `W-001` Where a walk starts

| Step | Statement |
| --- | --- |
| Given | an include carrying a wildcard |
| When | the scope is asked which directories to walk |
| Then | it names everything before the first wildcard, and a pattern carrying none names no walk at all |

## `W-002` A root under another root

| Step | Statement |
| --- | --- |
| Given | two includes whose directories nest |
| When | the scope is asked which directories to walk |
| Then | only the outermost is walked, so a file is met once however many includes reach it |

## `W-003` What a walk passes over

| Step | Statement |
| --- | --- |
| Given | a tree holding a hidden entry, a hidden directory, and a directory linked back up the tree |
| When | the walk runs |
| Then | the hidden entries are passed over and the link is not followed |

## `W-004` A root nothing wrote

| Step | Statement |
| --- | --- |
| Given | an include naming a directory that is not there |
| When | the walk runs |
| Then | it answers nothing rather than refusing to run |

## `W-005` What an include covers

| Step | Statement |
| --- | --- |
| Given | an include, and what the project excludes |
| When | the scope is asked what it covers |
| Then | it answers the files the include reaches, less what the project excludes |

## `W-007` A wildcard standing between two names

| Step | Statement |
| --- | --- |
| Given | an include whose wildcard names a directory in the middle of a path |
| When | the scope is asked what it covers |
| Then | the files under every directory it matches are answered |

## `W-006` A directory the walk refuses, so an emptied include is told from a wrong one

| Step | Statement |
| --- | --- |
| Given | an excluded directory holding files an include would otherwise reach |
| When | the walk runs |
| Then | it is not walked into at all, and what was refused is carried forward |
