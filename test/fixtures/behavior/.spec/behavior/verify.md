# Glossary Verification

How a run answers when the source and the glossary disagree.

## Includes

- `test/*_test.rb`

## `G-001` Code that drifted from its glossary

| Step | Statement |
| --- | --- |
| Given | a glossary declaring a word its term rejects |
| Given | a comment using that word |
| When | `sumi verify` runs |
| Then | one finding is reported for the line the word appears on |

## `G-002` A specification the configuration switched off

| Step | Statement |
| --- | --- |
| Given | a .sumi.json declaring glossary verify false |
| When | `sumi verify` runs |
| Then | the glossary contributes no findings |
