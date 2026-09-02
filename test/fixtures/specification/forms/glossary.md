# Glossary

The words this fixture keeps, and the ones it turns down. This paragraph is
prose: nothing above a section declares anything.

## Everywhere

### Includes

- `app/**/*.rb`
- `docs/*.md`

### Order

What a customer asks us to fulfil.

#### Rejected

- `Purchase` — Order is what the domain calls it.
  - `app/legacy_import.rb:88` — Quotes the upstream column name.

### Customer

Whoever the order is fulfilled for.

#### Rejected

- `User` — Nobody logs in to place an order.

## Billing

### Includes

- `app/billing/*.rb`

### Order

The billable set of lines.

#### Rejected

- `Invoice` — An invoice is issued later, from an order.
