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

## Vercel hosting verified
- Project: `hakams-projects-a6d8ca99/meal-ledger` (`prj_ZMNMNUYM7YOWSAse61xfnwBbs6AK`).
- URL: https://meal-ledger-nu.vercel.app
- Deployment: `dpl_CoYyPPwkw5BVi9ZPsU2JJuRpBcY2`, READY, production target. Vercel assigned the first deployment to production even though the CLI request selected preview.
- Source: commit `535b4e6`, uploaded through Vercel CLI 64.3.1.
- Remote build and TypeScript checks passed. All 11 report tabs opened in hosted sample mode.
- Real sign-in and persistence remain unavailable until Supabase provisioning.
- CLI team access works. The connected MCP integration still returns 403 for this team.
- Automatic Git deployment has not been enabled while the migration is a draft.

## Pending external setup
- Confirm the organization/project for the dedicated Supabase database.
- Apply and test the SQL migration, then run database advisors.
- Configure Supabase email templates/redirect URLs and test real sign-in.
- Set Supabase environment variables, redeploy and verify authenticated persistence before the new host is ready for real records.

Supabase has not been provisioned for this migration. Existing saved records have not been moved or altered.
