export enum OrderStatus {
  CREATED = 'CREATED',
  AWAITING_PAYMENT = 'AWAITING_PAYMENT',
  PAYMENT_DETECTED = 'PAYMENT_DETECTED',
  PAYMENT_CONFIRMED = 'PAYMENT_CONFIRMED',
  PROCESSING = 'PROCESSING',
  PAYOUT_PENDING = 'PAYOUT_PENDING',
  PAYOUT_APPROVED = 'PAYOUT_APPROVED',
  COMPLETED = 'COMPLETED',
  EXPIRED = 'EXPIRED',
  CANCELLED = 'CANCELLED',
  REFUNDED = 'REFUNDED',
  FAILED = 'FAILED',
}

export class IllegalOrderTransitionError extends Error {
  constructor(from: OrderStatus, to: OrderStatus) {
    super(`Illegal transition: ${from} → ${to}`);
    this.name = 'IllegalOrderTransitionError';
  }
}

const ALLOWED: ReadonlyMap<OrderStatus, ReadonlySet<OrderStatus>> = new Map([
  [
    OrderStatus.CREATED,
    new Set([OrderStatus.AWAITING_PAYMENT, OrderStatus.CANCELLED]),
  ],
  [
    OrderStatus.AWAITING_PAYMENT,
    new Set([
      OrderStatus.PAYMENT_DETECTED,
      OrderStatus.EXPIRED,
      OrderStatus.CANCELLED,
    ]),
  ],
  [
    OrderStatus.PAYMENT_DETECTED,
    new Set([
      OrderStatus.PAYMENT_CONFIRMED,
      OrderStatus.CANCELLED,
      OrderStatus.FAILED,
    ]),
  ],
  [
    OrderStatus.PAYMENT_CONFIRMED,
    new Set([OrderStatus.PROCESSING, OrderStatus.FAILED]),
  ],
  [
    OrderStatus.PROCESSING,
    new Set([
      OrderStatus.PAYOUT_PENDING,
      OrderStatus.FAILED,
      OrderStatus.REFUNDED,
    ]),
  ],
  [
    OrderStatus.PAYOUT_PENDING,
    new Set([
      OrderStatus.PAYOUT_APPROVED,
      OrderStatus.FAILED,
      OrderStatus.REFUNDED,
    ]),
  ],
  [
    OrderStatus.PAYOUT_APPROVED,
    new Set([OrderStatus.COMPLETED, OrderStatus.FAILED, OrderStatus.REFUNDED]),
  ],
  // Terminals: no outbound transitions
  [OrderStatus.COMPLETED, new Set()],
  [OrderStatus.EXPIRED, new Set()],
  [OrderStatus.CANCELLED, new Set()],
  [OrderStatus.REFUNDED, new Set()],
  [OrderStatus.FAILED, new Set()],
]);

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  const next = ALLOWED.get(from);
  if (!next) {
    return false;
  }
  return next.has(to);
}

export function assertTransition(from: OrderStatus, to: OrderStatus): void {
  if (!canTransition(from, to)) {
    throw new IllegalOrderTransitionError(from, to);
  }
}
