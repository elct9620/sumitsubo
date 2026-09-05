# JavaScript

What JavaScript answers when it is the reading a file was handed to.

A name is the JSDoc namepath: `Charge#settle` for a method reached through a
value, `Charge.open` for one reached through the class, and the bare name for
whatever the module declares directly. Which of the two a method is comes from
the grammar — `static` is a node a query can ask for — and the mark that writes
it down comes from the convention. A private method carries a `#` of its own,
so the mark and the name meet and `Charge##secret` is what a reader has to
write.

`const f = () => {}` is how a module writes most of its functions, so the name
it is assigned to is the name it declares. That is also what keeps a callback
out: an arrow nobody assigned to a name declares nothing. What the name was
assigned decides it either way — `const LIMIT = 10` declares nothing, because
reading a name for whatever it holds would read every value in the module as a
declaration.

What the reading does not carry. A function written inside another answers by
its bare name — JSDoc marks an inner member with `~`, and nothing here spells
it, so two of one name in two functions cannot be told apart. What an object
literal holds is outside this as well: a module written as `const audit = {
entry() {} }` declares nothing, since reading it would mean reading every
object whose value happens to be a function.

## Includes

- `test/language_javascript_test.rb`

## `JS-001` A fifth language reads its own comments

| Step | Statement |
| --- | --- |
| Given | a file carrying line comments, a JSDoc comment and a block comment |
| Given | a block comment with nothing after it, and text in one that is not all ASCII |
| When | the file is read for what a person wrote and for what each comment stands next to |
| Then | every comment answers, the region ends where the closing delimiter begins, and the one nothing follows says so |

## `JS-002` A member is marked the way JSDoc marks it

| Step | Statement |
| --- | --- |
| Given | a class declaring an instance method, a static one, a getter and a private one |
| When | the file is read for what it declares |
| Then | the static one answers under a `.` and the rest under a `#`, the private one keeping the `#` it was written with |

## `JS-003` A function is named by what it was assigned to

| Step | Statement |
| --- | --- |
| Given | an arrow function and a function expression each assigned to a name |
| Given | an arrow function passed as an argument, and a name assigned a plain value |
| When | the file is read for what it declares |
| Then | the assigned functions answer under the names they were given, and neither the argument nor the plain value answers |

## `JS-004` Source the grammar cannot read for what a person wrote

| Step | Statement |
| --- | --- |
| Given | a JavaScript file the grammar cannot parse |
| When | the file is read for what a person wrote |
| Then | the file is named as unreadable rather than answering with what it recovered |

## `JS-005` Source the grammar cannot read for what it declares

| Step | Statement |
| --- | --- |
| Given | a JavaScript file the grammar cannot parse |
| When | the file is read for what it declares |
| Then | the file is named as unreadable rather than answering with the names it recovered |
