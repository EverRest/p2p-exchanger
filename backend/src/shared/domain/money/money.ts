import Decimal from 'decimal.js';

export class MoneyInvalidAmountError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MoneyInvalidAmountError';
  }
}

export class MoneyCurrencyMismatchError extends Error {
  constructor(left: string, right: string) {
    super(`Currency mismatch: ${left} vs ${right}`);
    this.name = 'MoneyCurrencyMismatchError';
  }
}

/** Default decimal places per currency (domain display/storage scale). */
const DEFAULT_SCALE: Record<string, number> = {
  UAH: 2,
  BTC: 8,
  USDT: 6,
};

const AMOUNT_PATTERN = /^-?\d+(\.\d+)?$/;

export class Money {
  private constructor(
    private readonly value: Decimal,
    readonly currency: string,
    private readonly scale: number,
  ) {}

  static fromDecimalString(amount: string, currency: string): Money {
    const trimmedCurrency = currency.trim().toUpperCase();
    if (!trimmedCurrency) {
      throw new MoneyInvalidAmountError('Currency must be non-empty');
    }
    if (typeof amount !== 'string' || !amount.trim()) {
      throw new MoneyInvalidAmountError(
        'Amount must be a non-empty decimal string',
      );
    }
    const trimmed = amount.trim();
    if (!AMOUNT_PATTERN.test(trimmed)) {
      throw new MoneyInvalidAmountError(`Invalid decimal amount: ${amount}`);
    }

    let decimal: Decimal;
    try {
      decimal = new Decimal(trimmed);
    } catch {
      throw new MoneyInvalidAmountError(`Invalid decimal amount: ${amount}`);
    }
    if (!decimal.isFinite()) {
      throw new MoneyInvalidAmountError(`Invalid decimal amount: ${amount}`);
    }

    const scale = DEFAULT_SCALE[trimmedCurrency] ?? 8;
    const normalized = decimal.toFixed(scale);
    return new Money(new Decimal(normalized), trimmedCurrency, scale);
  }

  get amount(): string {
    return this.value.toFixed(this.scale);
  }

  add(other: Money): Money {
    this.assertSameCurrency(other);
    return Money.fromDecimalString(
      this.value.plus(other.value).toFixed(this.scale),
      this.currency,
    );
  }

  sub(other: Money): Money {
    this.assertSameCurrency(other);
    return Money.fromDecimalString(
      this.value.minus(other.value).toFixed(this.scale),
      this.currency,
    );
  }

  equals(other: Money): boolean {
    this.assertSameCurrency(other);
    return this.value.equals(other.value);
  }

  gt(other: Money): boolean {
    this.assertSameCurrency(other);
    return this.value.greaterThan(other.value);
  }

  lt(other: Money): boolean {
    this.assertSameCurrency(other);
    return this.value.lessThan(other.value);
  }

  toJSON(): { amount: string; currency: string } {
    return { amount: this.amount, currency: this.currency };
  }

  private assertSameCurrency(other: Money): void {
    if (this.currency !== other.currency) {
      throw new MoneyCurrencyMismatchError(this.currency, other.currency);
    }
  }
}
