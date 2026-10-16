import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export const authConfigured = () => Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_PUBLISHABLE_KEY);
export async function createClient() {
  if (!authConfigured()) throw new Error('Database connection is not configured.');
  const store = await cookies();
  return createServerClient(process.env.SUPABASE_URL!, process.env.SUPABASE_PUBLISHABLE_KEY!, {
    cookies: {
      getAll: () => store.getAll(),
      setAll(values) {
        try { values.forEach(({name,value,options}) => store.set(name,value,options)); }
        catch { /* Server Components are read-only; proxy.ts refreshes their cookies. */ }
      },
    },
  });
}
export async function getUser() {
  if (!authConfigured()) return null;
  const client = await createClient();
  const {data,error} = await client.auth.getUser();
  return error ? null : data.user;
}
