# Meal Ledger

A compact, bilingual Mid Day Meal cash book and fund register, built with Next.js, React and TypeScript. The GitHub repository is public; saved financial records require sign-in and are private to each account.

## Hosting

This branch targets **Vercel** for the website and **Supabase Postgres + Auth** for persistent data and email sign-in. GitHub stores the code; it is not the website host.

The original Sites version remains available separately. Its runtime and setup files are preserved under `legacy/sites/`, and its complete source is in Git history. These files are excluded from the Vercel build. The two databases do not automatically share records.

## Features

- Single-page entry form and eleven report/setup tabs, retaining English/Punjabi text.
- Schools and opening Cooking/Fruit balances; vendors and account autofill.
- Bills, Payment Invoices, token/voucher/sanction details, receipts, payments and status.
- Summary, Cash Book, School-wise, Consolidated, School Type, Ledger and Vendor reports.
- Passed-only balances calculated in integer paise, with prior transactions in date-filtered opening balances.
- Excel templates, exports, validated imports and duplicate-bill protection.
- JSON backup/restore, recycle bin, bulk deletion and action history.
- Email sign-in, per-account database ownership, revision conflicts and optional PIN locking.

## Local development

Use Node 22 and npm:

```sh
npm ci
cp .env.example .env.local
# Fill in the two Supabase values before testing saved data or sign-in.
npm run dev
```

Open http://127.0.0.1:3000. Without database configuration, the temporary sample register is available, while sign-in clearly reports that setup is incomplete. Sample changes are not persisted.

## Database setup

Create/select a dedicated Supabase project. Apply `supabase/migrations/20261016151103_meal_ledger.sql` through the Supabase CLI or SQL Editor. The migration enables pgcrypto and pg_jsonschema.

Set these server environment variables locally and in Vercel (Production and Preview):

| Variable | Value |
| --- | --- |
| `SUPABASE_URL` | Project URL from Supabase Connect |
| `SUPABASE_PUBLISHABLE_KEY` | Current publishable key from Supabase Connect |

No service-role key is needed. Never commit `.env.local`, session cookies, database backups or private API credentials.

Database tables live in the non-exposed `meal_ledger_private` schema with RLS enabled and no direct client table grants. The single public RPC delegates to a private function that verifies `auth.uid()`, validates payloads, handles PIN attempts and sessions, and serializes updates with a row lock. PIN hashes and unlock-session hashes never appear in a register response. The browser's PIN unlock cookie is HTTP-only, same-site and secure in production.

## Email sign-in setup

In Supabase Authentication → URL Configuration, set **Site URL** to the final Vercel production URL and allow the exact production `/auth/callback` URL. Add `http://127.0.0.1:3000/auth/callback` for local testing; add explicit preview callback URLs when needed.

Sign-in sends an email link. For a code-based flow, include `{{ .Token }}` in the Magic Link email template; the login screen also accepts that code. The app supports a custom confirmation link of `{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email`.

Configure SMTP before making sign-in available to users beyond the Supabase project's team: the default mail service restricts recipients and sending volume. Do not disable email confirmation to work around configuration issues.

## Deploy to Vercel

1. Import `Hakam02-doom/meal-ledger` into the intended Vercel team.
2. Select the Next.js framework; root directory is the repository root.
3. Add the two environment variables above.
4. Apply the database migration and configure the auth URLs.
5. Deploy the verified migration branch for a preview. Test sign-in and persistence before making it the production branch.

The repository contains `vercel.json`. No GitHub Pages workflow is needed. Once connected, Vercel handles deployment from GitHub.

## Move existing records

On the original register, download **Backup / Security → Backup Download (JSON)**. Sign in to the new Vercel register and restore that JSON using **Backup Restore**. This transfers schools, entries, vendors, trash and history. Sign-in sessions and PIN credentials are not part of the backup; set a new optional PIN after migration. Keep the original site until the new register and restored totals are verified.

## Checks

```sh
npm run typecheck
npm test
npm run build
```

`npm test` covers paise arithmetic, status accounting, filtering, validation, imports, duplicate handling and backup parsing. `tests/api.test.mjs` checks unauthenticated API access and origin protection against a running, configured local server. Database SQL regression checks are in `supabase/tests/workspace.sql` and roll back their temporary records.

The earlier Sites QA results are in `docs/verification-report.md`. They do not imply the new Supabase deployment has been provisioned or tested. `docs/vercel-migration-status.md` records this migration's checks and outstanding setup.
