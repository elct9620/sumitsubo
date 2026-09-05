// A Charge is settled here.

/** A JSDoc comment carries a marker here too. */
export interface Ledger {
  record(charge: Charge): void;
  limit: number;
}

export type Outcome = "settled" | "declined";

export enum Status {
  Settled,
  Declined,
}

export abstract class Charge {
  // @contract Charge#settle
  settle(at: number, note?: string, mark: number = 1, ...rest: string[]): boolean {
    return at > 0;
  }

  static open(amount: number): Charge {
    return null!;
  }

  abstract audit(): void;
}

export namespace audit {
  export function trail(entry: string): void {}
}

const LIMIT = 10;

export const recorded = (entry: string) => entry;

/* @contract Charge.open — a claim in a block comment. */
declare function ambient(x: number): void;

/* A block comment has nothing after it in this file. */
