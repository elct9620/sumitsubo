// A Charge is settled here.
// Each of these lines is a comment of its own.

/** A JSDoc comment is a block comment carrying a marker. */
export class Charge {
  // @contract Charge#settle
  settle(at, note = "none", ...rest) {
    return at > 0;
  }

  static open(amount) {
    return new Charge();
  }

  get amount() {
    return 1;
  }

  #secret() {
    return 2;
  }
}

export function recorded({ entry }, [first]) {}

const LIMIT = 10;

export const trail = (entry) => entry;

const later = function (entry, mark = 1) {
  return entry;
};

const single = (entry) => entry;

const nested = () => {
  const inner = () => 1;
  return inner;
};

[1, 2].map((n) => n * 2);

/* @contract Charge.open — a claim in a block comment. */
export const audited = () => true;

/* A block comment has nothing after it in this file. */
