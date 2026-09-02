# Nodes

The part of reading a syntax tree that no language owns.

Captures arrive from the binding in node position rather than in pattern order,
so they are grouped by the match they came from, made into nodes, and nested by
where those nodes sit. Every language puts its own query through this and each
one spells its nodes differently, which is why nothing here names a construct.

Nesting is recovered from where the nodes sit rather than from the query: a
pattern reaches only its direct children, and tree-sitter has no operator for
a deeper one. Two constructs spanning the same lines therefore answer with no
scope, which loses a prefix rather than inventing one.

## Includes

- `test/nodes_test.rb`

## `D-016` Captures grouped by the match they came from

| Step | Statement |
| --- | --- |
| Given | captures from two matches, arriving interleaved |
| When | they are grouped |
| Then | each match answers whole, in the order the parser met them |

## `D-017` A match that declares nothing

| Step | Statement |
| --- | --- |
| Given | a match carrying no capture that names it |
| When | the matches are read for what they declare |
| Then | it answers nothing, and the node beside it carries the lines its text spans |

## `D-018` The nodes holding one, outermost first

| Step | Statement |
| --- | --- |
| Given | a node inside two others, and a third spanning exactly its lines |
| When | what holds it is worked out |
| Then | the two answer outermost first and the third does not, since neither can be told from it |

## `D-021` What each comment stands next to

| Step | Statement |
| --- | --- |
| Given | captures naming every comment, and pairs naming what stands beside two of them |
| When | the captures are read for what each comment stands next to |
| Then | the one beside a comment answers a comment, the one beside a definition answers code, and the one with no pair answers nothing |
