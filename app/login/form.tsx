'use client';
import {useState} from 'react';
export default function LoginForm({expired}:{expired:boolean}) {
 const [email,setEmail]=useState(''),[code,setCode]=useState(''),[sent,setSent]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState(expired?'This sign-in link expired. Request another email.':'');
 async function submit(action:'sendLink'|'verify') {
  setBusy(true);setError('');
  try {const r=await fetch('/api/auth',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,email,code})});const b=await r.json();if(!r.ok)throw Error(b.error);if(action==='verify')window.location.assign('/');else setSent(true);}
  catch(e){setError((e as Error).message)}finally{setBusy(false)}
 }
 return <form onSubmit={e=>{e.preventDefault();submit(sent?'verify':'sendLink')}} className="login-form">
 <label className="field"><span>Email address</span><input type="email" autoComplete="email" required value={email} readOnly={sent} onChange={e=>setEmail(e.target.value)}/></label>
 {sent&&<><p role="status" className="helper">Check your email for a sign-in link. Open it in this browser. If the email contains a code, enter it below.</p><label className="field"><span>Email code</span><input inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6,8}" required value={code} onChange={e=>setCode(e.target.value)}/></label></>}
 {error&&<p role="alert" className="form-error">{error}</p>}
 <div className="toolbar"><button className="button primary" disabled={busy}>{busy?'Please wait…':sent?'Verify code':'Email me a sign-in link'}</button>{sent&&<button className="button" type="button" disabled={busy} onClick={()=>{setSent(false);setCode('')}}>Use another email / resend</button>}</div>
 </form>
}
