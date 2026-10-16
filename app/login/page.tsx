import {redirect} from 'next/navigation';
import {authConfigured,getUser} from '../../lib/supabase/server';
import LoginForm from './form';
export const dynamic='force-dynamic';
export default async function Login({searchParams}:{searchParams:Promise<{error?:string}>}) {
  if(await getUser())redirect('/');
  return <main className="login-page"><section className="panel"><h1>Sign in to Meal Ledger</h1><p className="helper" lang="pa">ਆਪਣਾ register ਖੋਲ੍ਹਣ ਲਈ email ਨਾਲ sign in ਕਰੋ।</p>{authConfigured()?<LoginForm expired={!!(await searchParams).error}/>:<p role="alert" className="form-error">Sign-in setup is not complete yet. Please contact the administrator.</p>}<a href="/" className="button">Back to register</a></section></main>;
}
