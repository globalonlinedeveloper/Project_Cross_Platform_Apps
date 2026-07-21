import { describe, it, expect } from 'vitest';
import { advance, rollForward } from '../src/renewals';

describe('renewals date math (pure core)', () => {
  it('advances one month in UTC', () => {
    expect(advance('2026-01-15', 'monthly')).toBe('2026-02-15');
    expect(advance('2026-12-15', 'monthly')).toBe('2027-01-15');
  });

  it('advances one year in UTC', () => {
    expect(advance('2026-03-10', 'yearly')).toBe('2027-03-10');
  });

  it('month-end overflow follows JS Date semantics deterministically', () => {
    // Jan 31 + 1 month → Mar 3 (2026 is not a leap year): stable + documented.
    expect(advance('2026-01-31', 'monthly')).toBe('2026-03-03');
  });

  it('rollForward: nothing crossed when already today-or-future', () => {
    const r = rollForward('2026-07-25', 'monthly', '2026-07-21');
    expect(r.next).toBe('2026-07-25');
    expect(r.crossings).toEqual([]);
  });

  it('rollForward: rolls a past-due date to today-or-future, recording each crossing', () => {
    const r = rollForward('2026-05-10', 'monthly', '2026-07-21');
    // 2026-05-10 → 06-10 → 07-10 → 08-10 (first >= today)
    expect(r.next).toBe('2026-08-10');
    expect(r.crossings).toEqual(['2026-05-10', '2026-06-10', '2026-07-10']);
  });

  it('rollForward: yearly cadence', () => {
    const r = rollForward('2024-02-01', 'yearly', '2026-07-21');
    expect(r.crossings).toEqual(['2024-02-01', '2025-02-01', '2026-02-01']);
    expect(r.next).toBe('2027-02-01');
  });

  it('rollForward: the final next is always >= today', () => {
    const r = rollForward('2020-01-01', 'monthly', '2026-07-21');
    expect(r.next >= '2026-07-21').toBe(true);
  });
});
