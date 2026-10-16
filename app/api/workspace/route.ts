import {env} from 'cloudflare:workers';
import {getChatGPTUser} from '../../chatgpt-auth';
import {DataSchema,emptyData} from '../../model';
const json=(v:unknown,status=200,headers:Record<string,string>={})=>Response.json(v,{status,headers:{'Cache-Control':'no-store',...headers}});
const cookie=(r:Request)=>r.headers.get('cookie')?.split(';').map(s=>s.trim()).find(s=>s.startsWith('meal_unlock='))?.slice(12)||'';
async function digest(pin:string,salt:string){const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(pin),'PBKDF2',false,['deriveBits']);const bits=await crypto.subtle.deriveBits({name:'PBKDF2',salt:new TextEncoder().encode(salt),iterations:100000,hash:'SHA-256'},key,256);return Array.from(new Uint8Array(bits),b=>b.toString(16).padStart(2,'0')).join('');}
async function context(r:Request){const user=await getChatGPTUser();if(!user)throw new Error('AUTH');const db=env.DB!;await db.prepare('INSERT OR IGNORE INTO workspaces (owner,payload,revision) VALUES (?,?,0)').bind(user.userId,JSON.stringify(emptyData())).run();const row=await db.prepare('SELECT * FROM workspaces WHERE owner=?').bind(user.userId).first<any>();const session=cookie(r)?await db.prepare('SELECT token FROM unlock_sessions WHERE token=? AND owner=? AND expires>?').bind(cookie(r),user.userId,Date.now()).first():null;return {db,user,row,locked:!!row.pin_hash&&!session};}
export async function GET(r:Request){try{const {row,locked}=await context(r);return json(locked?{locked:true,hasPin:true}:{data:JSON.parse(row.payload),revision:row.revision,hasPin:!!row.pin_hash,locked:false});}catch(e){return json({error:e instanceof Error&&e.message==='AUTH'?'Sign in to access your register.':'Could not load your register.'},e instanceof Error&&e.message==='AUTH'?401:500);}}
export async function POST(r:Request){try{
 if(r.headers.get('origin')&&r.headers.get('origin')!==new URL(r.url).origin)return json({error:'Invalid request origin'},403);
 if(Number(r.headers.get('content-length')||0)>12000000)return json({error:'File is too large'},413);
 const {db,user,row,locked}=await context(r);const b=await r.json() as any;
 const secure=new URL(r.url).protocol==='https:'?'; Secure':'';
 const clear={'Set-Cookie':`meal_unlock=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0${secure}`};
 if(b.action==='unlock'){
  if(!row.pin_hash)return json({ok:true});if(row.locked_until>Date.now())return json({error:'Too many attempts. Please try again in 5 minutes.'},429);
  if(typeof b.pin!=='string'||b.pin.length>12)return json({error:'Invalid PIN'},400);
  if(await digest(b.pin,row.pin_salt)!==row.pin_hash){const failures=row.failures+1;await db.prepare('UPDATE workspaces SET failures=?,locked_until=? WHERE owner=?').bind(failures,failures>=5?Date.now()+300000:0,user.userId).run();return json({error:'That PIN is incorrect.'},403);}
  const token=crypto.randomUUID()+crypto.randomUUID();await db.batch([db.prepare('UPDATE workspaces SET failures=0,locked_until=0 WHERE owner=?').bind(user.userId),db.prepare('DELETE FROM unlock_sessions WHERE owner=? AND expires<?').bind(user.userId,Date.now()),db.prepare('INSERT INTO unlock_sessions(token,owner,expires) VALUES(?,?,?)').bind(token,user.userId,Date.now()+28800000)]);return json({ok:true},200,{'Set-Cookie':`meal_unlock=${token}; Path=/; HttpOnly; SameSite=Strict; Max-Age=28800${secure}`});
 }
 if(b.action==='lock'){if(cookie(r))await db.prepare('DELETE FROM unlock_sessions WHERE token=? AND owner=?').bind(cookie(r),user.userId).run();return json({ok:true},200,clear);}
 if(locked)return json({error:'Unlock your register first.',locked:true},423);
 if(b.action==='pin'){
  if(typeof b.pin!=='string'||!/^\d{4,12}$/.test(b.pin))return json({error:'Use a PIN of 4–12 digits.'},400);
  const salt=crypto.randomUUID();await db.batch([db.prepare('UPDATE workspaces SET pin_hash=?,pin_salt=?,failures=0,locked_until=0 WHERE owner=?').bind(await digest(b.pin,salt),salt,user.userId),db.prepare('DELETE FROM unlock_sessions WHERE owner=?').bind(user.userId)]);return json({ok:true,locked:true},200,clear);
 }
 if(b.action==='removePin'){await db.batch([db.prepare('UPDATE workspaces SET pin_hash=NULL,pin_salt=NULL WHERE owner=?').bind(user.userId),db.prepare('DELETE FROM unlock_sessions WHERE owner=?').bind(user.userId)]);return json({ok:true},200,clear);}
 if(b.action!=='save')return json({error:'Unknown action'},400);
 const parsed=DataSchema.safeParse(b.data);if(!parsed.success)return json({error:parsed.error.issues.slice(0,3).map(i=>`${i.path.join('.')}: ${i.message}`).join('; ')},400);
 if(!Number.isInteger(b.revision))return json({error:'Missing revision'},400);
 const payload=JSON.stringify(parsed.data);if(new TextEncoder().encode(payload).length>1500000)return json({error:'Register is too large. Export and archive older records.'},413);
 const result=await db.prepare('UPDATE workspaces SET payload=?,revision=revision+1 WHERE owner=? AND revision=?').bind(payload,user.userId,b.revision).run();if(!result.meta.changes)return json({error:'This register changed in another tab. Reload before saving to avoid overwriting newer records.'},409);
 return json({ok:true,revision:b.revision+1});
 }catch(e){return json({error:e instanceof Error&&e.message==='AUTH'?'Sign in to access your register.':'Unable to save. Your previous data is unchanged.'},e instanceof Error&&e.message==='AUTH'?401:500);}}
