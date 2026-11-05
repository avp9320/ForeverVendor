# v1.0 acceptance checklist

This is a release gate, not a claim of implementation. README claims and static code inspection do not substitute for live-client evidence. Check a box only after its behavior is verified; record test date/client and evidence in this file.

- [ ] Auto-sell gray items with positive vendor value; re-check quality, lock and identity before each sale
- [ ] Confirm merchant lifecycle, bag API and secure action restrictions on live Forever client
- [ ] Verify sale totals against actual merchant proceeds; handle rejected/failed sales without reporting false success
- [ ] Exercise bag swaps, partial stacks, locked items, no-price items, rapid vendor close/reopen and manual /fv sell
- [ ] Verify WoWUp 1.0 release packaging and compatibility

## Evidence

- Code review: 2026-11-05 — confirmed prior implementation counted attempted sales as successful. Commit c0c8d17 now waits for observed merchant money gain before counting each stack; still needs live verification for delayed currency updates and edge cases.
- Automated/static tests: pending (no live WoW runtime available; change has not been executed in client)
- Live WoW: Forever client verification: pending
- Release ZIP and WoWUp installation: pending

## Status

Pre-1.0. Features described in README may be implemented but are not accepted as verified here until tested. Avoid declaring v1.0 solely on version metadata.
