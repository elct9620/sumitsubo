// A Charge is settled here.
// Each of these lines is a comment of its own.
package charge

// Charge carries what is owed.
type Charge struct {
	Amount uint32
}

// @contract Charge.Settle
func (c *Charge) Settle(at uint32) bool {
	return at > 0
}

func (c Charge) Audit() {}

func Open(amount uint32, notes ...string) *Charge {
	return nil
}

func Grouped(a, b uint32) {}

func Unnamed(uint32) {}

type Ledger interface {
	Record(charge *Charge)
}

const Limit = 10

var Started = false

/* @contract Charge.Audit — a claim in a block comment. */
func Recorded() {}

/* A block comment has nothing after it in this file. */
