import {NextResponse} from 'next/server';
import {createClient} from '../../../lib/supabase/server';
export async function GET(request:Request) {
  const url=new URL(request.url),code=url.searchParams.get('code');
  if(code) {
    const client=await createClient();
    const {error}=await client.auth.exchangeCodeForSession(code);
    if(!error)return NextResponse.redirect(new URL('/',url),{headers:{'Cache-Control':'no-store'}});
  }
  return NextResponse.redirect(new URL('/login?error=expired',url),{headers:{'Cache-Control':'no-store'}});
}
