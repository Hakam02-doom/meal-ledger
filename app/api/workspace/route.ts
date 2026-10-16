import {NextResponse} from 'next/server';
import {cookies} from 'next/headers';
import {createClient,authConfigured} from '../../../lib/supabase/server';
import {DataSchema} from '../../model';
export const dynamic='force-dynamic';
export const runtime='nodejs';
const json=(body:unknown,status=200)=>NextResponse.json(body,{status,headers:{'Cache-Control':'private, no-store'}});
async function execute(request:Request,body:Record<string,unknown>) {
  if(!authConfigured())return json({error:'Database connection is not configured.'},503);
  const client=await createClient();
  const {data:{user},error:authError}=await client.auth.getUser();
  if(authError||!user)return json({error:'Sign in to access your register.'},401);
  const jar=await cookies();
  const {data,error}=await client.rpc('meal_ledger_workspace',{request:{...body,unlockToken:jar.get('meal_unlock')?.value||''}});
  if(error){console.error('Workspace database request failed:',error.code);return json({error:'Could not access your register. Please try again.'},503);}
  const {status=200,unlockToken,...result}=data as Record<string,any>;
  const response=json(result,status);
  if(unlockToken)response.cookies.set('meal_unlock',unlockToken,{httpOnly:true,sameSite:'strict',secure:new URL(request.url).protocol==='https:',path:'/',maxAge:28800});
  if(status===200&&['pin','lock','removePin'].includes(String(body.action)))response.cookies.set('meal_unlock','',{httpOnly:true,sameSite:'strict',secure:new URL(request.url).protocol==='https:',path:'/',maxAge:0});
  return response;
}
export async function GET(request:Request) {
  try{return await execute(request,{action:'get'});}catch{return json({error:'Could not load your register.'},503);}
}
export async function POST(request:Request) {
  if(request.headers.get('origin')!==new URL(request.url).origin)return json({error:'Invalid request origin.'},403);
  try {
    const raw=await request.text();
    if(new TextEncoder().encode(raw).length>1600000)return json({error:'Register is too large. Export and archive older records.'},413);
    const b=JSON.parse(raw);
    if(!b||typeof b!=='object'||!['save','pin','unlock','lock','removePin'].includes(b.action))return json({error:'Unknown action.'},400);
    if(b.action==='save') {
      const parsed=DataSchema.safeParse(b.data);
      if(!parsed.success)return json({error:parsed.error.issues.slice(0,3).map(i=>`${i.path.join('.')}: ${i.message}`).join('; ')},400);
      if(!Number.isInteger(b.revision)||b.revision<0)return json({error:'Missing revision.'},400);
      return await execute(request,{action:'save',data:parsed.data,revision:b.revision});
    }
    if(['pin','unlock'].includes(b.action)&&(typeof b.pin!=='string'||!/^\d{4,12}$/.test(b.pin)))return json({error:'Use a PIN of 4–12 digits.'},400);
    return await execute(request,{action:b.action,...(b.pin?{pin:b.pin}:{})});
  }catch{return json({error:'Unable to process this request. Your saved data is unchanged.'},400);}
}
