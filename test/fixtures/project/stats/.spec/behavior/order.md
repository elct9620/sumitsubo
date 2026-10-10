# Order

What placing an order does.

## Includes

- `test/*_test.rb`

## `O-001` An order is placed

| Step | Statement |
| --- | --- |
| Given | a cart with an item |
| When | the order is placed |
| Then | the cart is empty |

## `O-002` An order is numbered

| Step | Statement |
| --- | --- |
| Given | a cart with an item |
| When | the order is placed |
| Then | it carries a number |

## `O-003` An order is cancelled

| Step | Statement |
| --- | --- |
| Given | a placed order |
| When | it is cancelled |
| Then | nothing is charged |

## `O-004` An order is shipped

| Attribute | Value |
| --- | --- |
| unverifiable | no test reaches the courier |

| Step | Statement |
| --- | --- |
| Given | a placed order |
| When | a courier collects it |
| Then | it leaves the warehouse |

## `O-005` An order is printed

| Attribute | Value |
| --- | --- |
| deprecated | O-002 replaces it |

| Step | Statement |
| --- | --- |
| Given | a placed order |
| When | it is printed |
| Then | the slip lists the item |
