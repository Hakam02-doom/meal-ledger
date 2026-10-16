import {NextResponse} from 'next/server';
import {createClient} from '../../../lib/supabase/server';
export async function GET(request:Request) {
  const url=new URL(request.url),hash=url.searchParams.get('token_hash');
  if(hash&&url.searchParams.get('type')==='email') {
    const client=await createClient();
    const {error}=await client.auth.verifyOtp({token_hash:hash,type:'email'});
    if(!error)return NextResponse.redirect(new URL('/',url),{headers:{'Cache-Control':'no-store','Referrer-Policy':'no-referrer'}});
  }
  return NextResponse.redirect(new URL('/login?error=expired',url),{headers:{'Cache-Control':'no-store'}});
}
