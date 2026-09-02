pub struct Order;

// An identifier spells a concept rather than naming it, so the type below is
// walked past. A reading that answered for every line would not walk past it.
pub struct Purchase;

impl Order {
    // The upstream feed calls this a Purchase.
    pub fn settle(&self, at: u32) -> bool {
        at > 0
    }
}
