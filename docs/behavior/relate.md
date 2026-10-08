# Relate

What specifications say of one another. A statement names, among its
attributes, the statements it relates to and the ones it refines, and the run
keeps each as a relation from the statement writing it.

A key is the statement's own key, kept by the mechanism writing it. One opening
with another mechanism's name and a space is that mechanism's.

## Includes

- `test/related_test.rb`

## `RL-001` A scenario relating to another of its own

| Step | Statement |
| --- | --- |
| Given | a scenario whose relates names another scenario by its id |
| When | the relations its specifications write are kept |
| Then | one relates relation runs from the first scenario to the second |

## `RL-002` A key naming another mechanism's statement

| Step | Statement |
| --- | --- |
| Given | a scenario whose relates names a contract with the mechanism's name first |
| When | the relations its specifications write are kept |
| Then | the relation runs to that contract, under the contract mechanism |

## `RL-003` A refinement runs from the narrower statement

| Step | Statement |
| --- | --- |
| Given | a scenario whose refines names another |
| When | the relations its specifications write are kept |
| Then | one refines relation runs from the scenario writing it to the one it names |
