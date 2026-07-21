import { describe, it, expect } from 'vitest';
import { baseConfig, mergeConfig, resolveConfig } from '../src/config';

describe('CFG-1 config resolution', () => {
  it('returns compiled defaults for a known app', () => {
    const cfg = baseConfig('subly');
    expect(cfg).not.toBeNull();
    expect(cfg!.app_id).toBe('subly');
    expect(cfg!.api_base_url).toBe('https://api.nikatru.com/v1');
    expect(cfg!.features.renewals).toBe(true);
    expect(cfg!.paywall.enabled).toBe(false);
    expect(cfg!.min_supported_version).toBe('1.0.0');
  });

  it('returns null for an unregistered app', () => {
    expect(baseConfig('nope')).toBeNull();
    expect(resolveConfig('nope', null)).toBeNull();
    expect(resolveConfig('nope', '{"paywall":{"enabled":true}}')).toBeNull();
  });

  it('resolves to defaults when there is no KV override', () => {
    expect(resolveConfig('subly', null)).toEqual(baseConfig('subly'));
  });

  it('deep-merges a KV override over defaults (override wins, siblings kept)', () => {
    const merged = resolveConfig(
      'subly',
      JSON.stringify({
        paywall: { enabled: true, plan: 'pro' },
        features: { exports: false },
        min_supported_version: '1.2.0',
      }),
    )!;
    // overridden
    expect(merged.paywall.enabled).toBe(true);
    expect(merged.paywall.plan).toBe('pro');
    expect(merged.features.exports).toBe(false);
    expect(merged.min_supported_version).toBe('1.2.0');
    // siblings preserved from defaults
    expect(merged.features.renewals).toBe(true);
    expect(merged.features.budgets).toBe(true);
    expect(merged.api_base_url).toBe('https://api.nikatru.com/v1');
  });

  it('ignores malformed KV JSON and falls back to defaults (never takes an app down)', () => {
    expect(resolveConfig('subly', '{not valid json')).toEqual(baseConfig('subly'));
  });

  it('does not mutate the shared defaults across calls', () => {
    const a = resolveConfig('subly', JSON.stringify({ paywall: { enabled: true } }))!;
    expect(a.paywall.enabled).toBe(true);
    // a second, override-free resolve must still see the pristine default
    expect(resolveConfig('subly', null)!.paywall.enabled).toBe(false);
  });

  it('mergeConfig with a nullish override returns the base unchanged', () => {
    const base = baseConfig('subly')!;
    expect(mergeConfig(base, null)).toEqual(base);
    expect(mergeConfig(base, undefined)).toEqual(base);
  });
});
