import {NextResponse} from 'next/server';
import {cookies} from 'next/headers';
import {createClient,authConfigured} from '../../../lib/supabase/server';
export const dynamic = 'force-dynamic';
export async function POST(request:Request) {
  const reply=(body:unknown,status=200)=>NextResponse.json(body,{status,headers:{'Cache-Control':'no-store'}});
  if(request.headers.get('origin')!==new URL(request.url).origin)return reply({error:'Invalid request origin.'},403);
  if(!authConfigured())return reply({error:'Sign-in is not configured yet. Please contact the administrator.'},503);
  try {
    const body=await request.json();
    const client=await createClient();
    if(body.action==='signout') {
      const jar=await cookies();
      await client.rpc('meal_ledger_workspace',{request:{action:'lock',unlockToken:jar.get('meal_unlock')?.value||''}});
      const {error}=await client.auth.signOut();
      if(error)return reply({error:'Could not sign out. Please try again.'},503);
      jar.delete('meal_unlock');
      return reply({ok:true});
    }
    const email=typeof body.email==='string'?body.email.trim():'';
    if(email.length>254||!/^\S+@\S+\.\S+$/.test(email))return reply({error:'Enter a valid email address.'},400);
    if(body.action==='sendLink') {
      const {error}=await client.auth.signInWithOtp({email,options:{emailRedirectTo:new URL('/auth/callback',request.url).href}});
      if(error)return reply({error:error.status===429?'Please wait before requesting another sign-in email.':'Could not send the sign-in email. Please try again or contact the administrator.'},error.status===429?429:400);
      return reply({ok:true});
    }
    if(body.action==='verify') {
      if(typeof body.code!=='string'||!/^\d{6,8}$/.test(body.code))return reply({error:'Enter the code from your email.'},400);
      const {error}=await client.auth.verifyOtp({email,token:body.code,type:'email'});
      return error?reply({error:'That code is invalid or expired. Request a new email.'},400):reply({ok:true});
    }
    return reply({error:'Unknown action.'},400);
  } catch {return reply({error:'Unable to complete sign-in. Please try again.'},400);}
}
