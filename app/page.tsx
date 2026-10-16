import Ledger from './ledger';
import { getUser } from '../lib/supabase/server';
export const dynamic = 'force-dynamic';
export default async function Home() {
  const user = await getUser();
  return <Ledger signedIn={!!user} />;
}
