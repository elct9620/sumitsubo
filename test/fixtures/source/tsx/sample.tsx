// A Charge is rendered here.

/** A JSDoc comment carries a marker here too. */
export interface Props {
  amount: number;
}

export abstract class Charge {
  // @contract Charge#settle
  settle(at: number, note?: string): boolean {
    return at > 0;
  }

  static open(amount: number): Charge {
    return null!;
  }
}

/* @contract Charge.open — a claim in a block comment. */
export const Panel = (props: Props) => <div className="panel">{props.amount}</div>;

export function Badge({ amount }: Props) {
  return <span>{amount}</span>;
}

const LIMIT = 10;

/* A block comment has nothing after it in this file. */
