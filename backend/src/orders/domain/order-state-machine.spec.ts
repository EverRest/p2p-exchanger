import {
  assertTransition,
  canTransition,
  OrderStatus,
} from './order-state-machine';

describe('Assisted order state machine', () => {
  const happyPath: OrderStatus[] = [
    OrderStatus.CREATED,
    OrderStatus.AWAITING_PAYMENT,
    OrderStatus.PAYMENT_DETECTED,
    OrderStatus.PAYMENT_CONFIRMED,
    OrderStatus.PROCESSING,
    OrderStatus.PAYOUT_PENDING,
    OrderStatus.PAYOUT_APPROVED,
    OrderStatus.COMPLETED,
  ];

  it('allows the Assisted happy-path transitions including PAYOUT_APPROVED', () => {
    for (let i = 0; i < happyPath.length - 1; i += 1) {
      const from = happyPath[i];
      const to = happyPath[i + 1];
      expect(canTransition(from, to)).toBe(true);
      expect(() => assertTransition(from, to)).not.toThrow();
    }
  });

  it('exposes PAYOUT_APPROVED as an order-visible status', () => {
    expect(OrderStatus.PAYOUT_APPROVED).toBe('PAYOUT_APPROVED');
    expect(Object.values(OrderStatus)).toContain('PAYOUT_APPROVED');
  });

  it('allows transition to EXPIRED from AWAITING_PAYMENT', () => {
    expect(
      canTransition(OrderStatus.AWAITING_PAYMENT, OrderStatus.EXPIRED),
    ).toBe(true);
  });

  it('allows CANCELLED from early non-terminal states', () => {
    expect(canTransition(OrderStatus.CREATED, OrderStatus.CANCELLED)).toBe(
      true,
    );
    expect(
      canTransition(OrderStatus.AWAITING_PAYMENT, OrderStatus.CANCELLED),
    ).toBe(true);
  });

  it('forbids reopening COMPLETED', () => {
    expect(
      canTransition(OrderStatus.COMPLETED, OrderStatus.AWAITING_PAYMENT),
    ).toBe(false);
    expect(
      canTransition(OrderStatus.COMPLETED, OrderStatus.PAYOUT_PENDING),
    ).toBe(false);
    expect(() =>
      assertTransition(OrderStatus.COMPLETED, OrderStatus.AWAITING_PAYMENT),
    ).toThrow(/illegal transition/i);
  });

  it('forbids rolling back PAYMENT_CONFIRMED to AWAITING_PAYMENT', () => {
    expect(
      canTransition(
        OrderStatus.PAYMENT_CONFIRMED,
        OrderStatus.AWAITING_PAYMENT,
      ),
    ).toBe(false);
  });

  it('forbids rolling back PAYOUT_APPROVED to PAYMENT_DETECTED', () => {
    expect(
      canTransition(OrderStatus.PAYOUT_APPROVED, OrderStatus.PAYMENT_DETECTED),
    ).toBe(false);
  });

  it('forbids leaving EXPIRED terminal state', () => {
    expect(canTransition(OrderStatus.EXPIRED, OrderStatus.PROCESSING)).toBe(
      false,
    );
  });

  it('forbids skipping operator confirm (PAYMENT_DETECTED → PROCESSING)', () => {
    expect(
      canTransition(OrderStatus.PAYMENT_DETECTED, OrderStatus.PROCESSING),
    ).toBe(false);
  });

  it('forbids payout execute path without PAYOUT_APPROVED (PAYOUT_PENDING → COMPLETED)', () => {
    expect(
      canTransition(OrderStatus.PAYOUT_PENDING, OrderStatus.COMPLETED),
    ).toBe(false);
  });
});
