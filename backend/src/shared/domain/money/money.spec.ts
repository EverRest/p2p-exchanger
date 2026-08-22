import {
  Money,
  MoneyCurrencyMismatchError,
  MoneyInvalidAmountError,
} from './money';

describe('Money', () => {
  describe('fromDecimalString', () => {
    it('creates money from a decimal string and currency', () => {
      const m = Money.fromDecimalString('1234.56', 'UAH');
      expect(m.amount).toBe('1234.56');
      expect(m.currency).toBe('UAH');
    });

    it('rejects empty amount', () => {
      expect(() => Money.fromDecimalString('', 'UAH')).toThrow(
        MoneyInvalidAmountError,
      );
    });

    it('rejects non-decimal amount strings', () => {
      expect(() => Money.fromDecimalString('not-a-number', 'UAH')).toThrow(
        MoneyInvalidAmountError,
      );
      expect(() => Money.fromDecimalString('12.34.56', 'UAH')).toThrow(
        MoneyInvalidAmountError,
      );
    });

    it('rejects empty currency', () => {
      expect(() => Money.fromDecimalString('1.00', '')).toThrow(
        MoneyInvalidAmountError,
      );
    });

    it('normalizes scale for UAH to 2 decimal places', () => {
      const m = Money.fromDecimalString('10.1', 'UAH');
      expect(m.amount).toBe('10.10');
    });

    it('normalizes scale for BTC to 8 decimal places', () => {
      const m = Money.fromDecimalString('0.1', 'BTC');
      expect(m.amount).toBe('0.10000000');
    });

    it('normalizes scale for USDT to 6 decimal places by default', () => {
      const m = Money.fromDecimalString('1.5', 'USDT');
      expect(m.amount).toBe('1.500000');
    });
  });

  describe('arithmetic', () => {
    it('adds same currency', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('2.50', 'UAH');
      expect(a.add(b).amount).toBe('12.50');
      expect(a.add(b).currency).toBe('UAH');
    });

    it('subtracts same currency', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('2.50', 'UAH');
      expect(a.sub(b).amount).toBe('7.50');
    });

    it('forbids add across currencies', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('1.00', 'USDT');
      expect(() => a.add(b)).toThrow(MoneyCurrencyMismatchError);
    });

    it('forbids sub across currencies', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('1.00', 'USDT');
      expect(() => a.sub(b)).toThrow(MoneyCurrencyMismatchError);
    });
  });

  describe('comparison', () => {
    it('equals same amount and currency', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('10.00', 'UAH');
      expect(a.equals(b)).toBe(true);
    });

    it('gt / lt within same currency', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('2.00', 'UAH');
      expect(a.gt(b)).toBe(true);
      expect(b.lt(a)).toBe(true);
      expect(a.lt(b)).toBe(false);
    });

    it('forbids compare across currencies', () => {
      const a = Money.fromDecimalString('10.00', 'UAH');
      const b = Money.fromDecimalString('10.00', 'USDT');
      expect(() => a.equals(b)).toThrow(MoneyCurrencyMismatchError);
      expect(() => a.gt(b)).toThrow(MoneyCurrencyMismatchError);
    });
  });

  describe('serialization', () => {
    it('toJSON returns decimal string and currency', () => {
      const m = Money.fromDecimalString('99.99', 'UAH');
      expect(m.toJSON()).toEqual({ amount: '99.99', currency: 'UAH' });
    });
  });
});
