// A Charge is settled here.
// Each of these lines is a comment of its own.
use std::fmt;

/// A doc comment is a line comment with a marker on it.
pub struct Charge {
    amount: u32,
}

impl Charge {
    // @contract Charge::settle
    pub fn settle(&self, at: u32) -> bool {
        at > 0
    }

    pub fn open(amount: u32) -> Charge {
        Charge { amount }
    }
}

pub enum Outcome {
    Settled,
    Declined,
}

pub trait Ledger {
    fn record(&mut self, charge: &Charge);
}

impl Ledger for Charge {
    fn record(&mut self, charge: &Charge) {}
}

pub mod audit {
    pub const LIMIT: u32 = 10;

    pub fn trail() {}

    pub struct Entry;

    impl Entry {
        pub fn at(&self) -> u32 {
            0
        }
    }
}

/* A block comment has nothing after it in this file. */
