# Glossary

One line set aside twice under one rejected word, where another word turns the
same line down for its own reason.

## Everywhere

### Includes

- `app/**/*.rb`

### Order

What a customer asks us to fulfil.

#### Rejected

- `Invoice` — An invoice is issued later, from an order.
  - `app/order.rb:2` — The line names the invoice this order became.
- `Purchase` — Order is what the domain calls it.
  - `app/order.rb:2` — The line quotes the upstream column name.
  - `app/order.rb:2` — Set aside again where this word already has it.
