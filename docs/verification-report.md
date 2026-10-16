# Meal Ledger verification — 16 October 2026

## Fixes
- Dropdown chevrons now have a consistent 10 px inset and reserved text space; native keyboard selection is retained.
- Excel import skips existing bills by school, bill number, date and fund, even if spreadsheet amounts have changed. Existing values are preserved. A regression test reproduced the double-counting bug before the fix and passed afterward.
- Clear filters also restores the default sort order.

## Database
The deployed application uses Cloudflare D1 through its `DB` binding. School, vendor, entry, recycle-bin and audit data are stored in a workspace scoped to the signed-in account. Updates use revision checks to prevent stale tabs overwriting newer changes. The live site successfully loaded its workspace. Write, reload and PIN tests used the separate local D1 database; production records were not changed by QA.

## Checks passed
| Area | Evidence |
| --- | --- |
| School setup | Added a school with two opening balances; edited its name; deletion of a school with linked bills was blocked. |
| Vendors | Created vendor; account/IFSC/branch autofilled; renamed vendor and verified linked report totals. |
| Entries | Saved, reloaded and edited a bill; imported a complete Payment Invoice including token, voucher, reference, sanction dates and Punjabi remarks. |
| Status accounting | Browser edit to Pending excluded values from totals; automated tests cover Passed, Pending, Failed and Cancelled. |
| Totals | Verified ₹1,200.30 opening + ₹550.75 receipts − ₹125.40 expenditure = ₹1,625.65 closing; fund totals and vendor payments agreed. |
| Reports | Summary, Cash Book, School-wise, Consolidated, School Type, Ledger and Vendor-wise views checked using known records. |
| Filters | Search, fund/school/date/status filters and ordering checked; native keyboard date change carried earlier transactions into the opening balance. Clear filters restored newest sort. |
| Recycle Bin | Single delete, bulk delete and restore worked. |
| Excel export | Downloaded and parsed actual XLSX output; Schools, Entries, Vendors and Consolidated sheets present; leading zeros preserved. |
| Excel import | New invoice added; import preview displayed counts; reimport skipped existing records; invalid imports and changed-amount duplicate regression tests passed. |
| Backup | Downloaded JSON; deleted test entries; restored through the UI and confirmed restored count. Invalid-format backup test passed. |
| Database API | Save/reload, stale revision conflict, invalid-data rejection and anonymous-access rejection passed. |
| PIN API | Set, wrong PIN rejection, unlock, lock, locked-write rejection and PIN removal passed. |
| UI | Desktop and 390 px mobile views checked; no page overflow; all dropdowns show the inset arrow. No browser console errors observed. |
| Type checking and build | TypeScript check and production build passed. Existing Excel library size warning remains non-blocking. |

## Verification limits
Print/PDF invokes a native browser dialog. Automated control timed out while it was open; final printed/PDF output was not inspected. Browser checks ran in the Codex in-app browser, not across every browser/device. These results establish the tested workflows, not a guarantee of zero future bugs.
