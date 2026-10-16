# Vercel migration status

The migration uses standard Next.js 16.4.2 and Supabase Postgres/Auth. The original runtime is preserved under legacy/sites and remains deployed separately.

## Completed locally
- Next.js production build passed.
- TypeScript check passed.
- Browser smoke check passed for all 11 report tabs in sample mode.
- Sign-in screen correctly reports missing configuration until provisioning.
- Accounting, validation, Excel import/duplicate and backup tests passed.
- Vercel configuration and environment template included.
- Database migration and transactional security regression checks prepared.
- ChatGPT identity headers replaced with verified Supabase authentication.

## Pending external setup
- Confirm the organization/project for the dedicated Supabase database.
- Apply and test the SQL migration, then run database advisors.
- Configure Supabase email templates/redirect URLs and test real sign-in.
- Grant the connected Vercel integration access to the intended team; its current account connection cannot access the default team.
- Set environment variables, deploy and test the hosted app before production cutover.

No Vercel deployment or Supabase provisioning is claimed by these local checks. Existing saved records have not been moved or altered.
