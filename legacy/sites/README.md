# Meal Ledger

Live website: [Meal Ledger](https://meal-ledger-hakam.developervsandhu.chatgpt.site/)

This repository contains the application source and database migrations. The live site continues to be deployed through Sites; GitHub pushes do not automatically deploy it.

A private, database-backed Mid Day Meal cash book and fund register. The interface follows the compact single-page form and report tabs of https://school-fund-whisperer.lovable.app/.

## Start using it

Open the deployed site and sign in with ChatGPT. Add schools with opening cooking and fruit balances, then use the always-visible **Entry Form** to record receipts, bills, and payment invoices. **Sample data ਵੇਖੋ** uses temporary demo records; demo changes never enter the saved register.

## Interface

The entry form stays at the top of the page. Eleven report tabs switch the report below it without discarding an unfinished entry. School and vendor forms are inline. There is no sidebar, dashboard chart, marketing header, or entry popup.

## Included

- Schools: create/edit/remove unlinked schools; UDISE stored as text; UKG, PRIMARY, UPPER PRIMARY; separate opening balances.
- Entries: all reference fields, token/voucher/bill dates, sanction letters, document type, school type, fund, received/consumed amounts, status, vendor bank details, remarks.
- Vendors: directory, autofill, editing, payment totals and payment report export.
- Summary: compact all-time totals and separate Cooking/Fruit fund balances.
- Cash book: passed entries only; date/fund/financial-year filters; running balance with prior transactions and opening balances.
- Reports: school-wise, consolidated, school type, searchable/sortable ledger; Excel and browser Print / Save as PDF.
- Excel: actual .xlsx import/export, templates, preview, strict validation, duplicate skipping and automatic school creation.
- Backups: versioned JSON download/restore with preview; full Excel backup.
- Security: owner-private hosting, ChatGPT sign-in, server-authorized user-owned data, optional server-verified PIN, limited failed PIN attempts.
- Data management: edit entries, reversible deletion/recycle bin, bulk clear, saved-action history.

## Accounting rules

Only Passed entries count in balances. Closing balance = opening + received − consumed. Calculations sum integer paise before converting back to rupees. All statuses remain in the ledger. Cash book start balances include passed transactions before the selected date. School-wise summaries show all-time balances and all entries for the selected school. School type reports group by the school setup classification. Bank details are recorded for bookkeeping; the application does not send money.

## Architecture

React 19 + TypeScript on the Sites Vinext starter, deployed to Cloudflare Workers. Cloudflare D1 stores validated workspace snapshots with optimistic revision checks, preventing silent overwrites from two tabs. Each signed-in user has an isolated workspace. PINs use salted PBKDF2 hashes; unlock tokens are HTTP-only cookies backed by expiring server sessions. There are no database credentials in browser code.

Local and hosted databases are separate. `.openai/hosting.json` retains the registered project ID and `DB` binding. Migration `drizzle/0000_nasty_adam_destine.sql` initializes the schema. Use the Sites skill workflow for deployment.

## Development and validation

- `npm run dev` serves the local preview (loopback; default port 5173).
- `npx tsc --noEmit` checks TypeScript.
- `node_modules/.bin/esbuild tests/model.test.ts --bundle --platform=node --format=esm --packages=external --outfile=.sites-runtime/model.test.mjs && node .sites-runtime/model.test.mjs` tests accounting, validation, spreadsheet imports and backups.
- `node tests/api.test.mjs` tests the running LOCAL server at port 5173. It temporarily adds synthetic data, verifies database persistence, conflicts and PIN protection, then restores the original local dataset. Do not point this test at production.
- Build through the Sites plugin `scripts/build-site.mjs`.

## Draft scope and limits

The reference was inspected through its visible empty-state interface; no real records were changed on it. Hidden behavior requiring pre-existing records or the original PIN was not accessible. Excel column names are preserved for migration. JSON restore accepts Meal Ledger backups; migrate the old app using Excel. Imports accept modern `.xlsx` files, not legacy `.xls`, and reject formula cells. The UI preserves the original English/Punjabi labels and guidance. Text fields support Punjabi/Unicode. Print/PDF uses the browser print dialog; a physical printer was not tested.

This draft is owner-private and intended for a single administrator. It does not include team roles, password recovery, scheduled backups, or an immutable regulatory audit trail. Keep your optional PIN safe; this draft has no PIN recovery. Workbook uploads are limited to 5 MB, and each saved register to 1.5 MB of UTF-8 data. For larger school networks, split records into normalized tables and add paginated server-side reports.
