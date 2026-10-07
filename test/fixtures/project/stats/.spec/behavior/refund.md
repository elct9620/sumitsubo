# Refund

What refunding an order does.

## Includes

- `test/*_test.rb`

## `R-001` An order is refunded

| Step | Statement |
| --- | --- |
| Given | a paid order |
| When | it is refunded |
| Then | the charge is returned |

## `R-002` Part of an order is refunded

| Step | Statement |
| --- | --- |
| Given | a paid order of two items |
| When | one is refunded |
| Then | half the charge is returned |

## `R-003` A refund is refused

| Step | Statement |
| --- | --- |
| Given | an unpaid order |
| When | it is refunded |
| Then | nothing is returned |
