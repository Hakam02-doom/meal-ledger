-- Run in the dedicated project's SQL Editor after applying the migration.
-- All data and test identities are rolled back.
begin;
insert into auth.users(id,email) values
 ('11111111-1111-4111-8111-111111111111','meal-ledger-test-one@example.test'),
 ('22222222-2222-4222-8222-222222222222','meal-ledger-test-two@example.test');
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
set local role authenticated;
do $$
declare result jsonb; payload jsonb; token text;
begin
 result:=public.meal_ledger_workspace('{"action":"get"}');
 assert result->>'revision'='0','Workspace was not initialized';
 payload:=result->'data';
 result:=public.meal_ledger_workspace(jsonb_build_object('action','save','data',payload,'revision',0));
 assert result->>'revision'='1','Save failed';
 result:=public.meal_ledger_workspace(jsonb_build_object('action','save','data',payload,'revision',0));
 assert result->>'status'='409','Stale revision accepted';
 result:=public.meal_ledger_workspace('{"action":"save","data":{},"revision":1}');
 assert result->>'status'='400','Invalid data accepted';
 result:=public.meal_ledger_workspace('{"action":"pin","pin":"986543"}');
 assert result->>'locked'='true','PIN setup failed';
 result:=public.meal_ledger_workspace('{"action":"get"}');
 assert result->>'locked'='true' and not (result ? 'data'),'Locked data leaked';
 result:=public.meal_ledger_workspace(jsonb_build_object('action','save','data',payload,'revision',1));
 assert result->>'status'='423','Locked write accepted';
 result:=public.meal_ledger_workspace('{"action":"unlock","pin":"000000"}');
 assert result->>'status'='403','Wrong PIN accepted';
 result:=public.meal_ledger_workspace('{"action":"unlock","pin":"986543"}');
 token:=result->>'unlockToken';
 assert length(token)=64,'Unlock token missing';
 result:=public.meal_ledger_workspace(jsonb_build_object('action','get','unlockToken',token));
 assert result->>'locked'='false' and (result ? 'data'),'Unlock failed';
 perform set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
 result:=public.meal_ledger_workspace(jsonb_build_object('action','get','unlockToken',token));
 assert result->>'revision'='0' and result->>'hasPin'='false','Second account saw first account data';
 perform set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
 result:=public.meal_ledger_workspace(jsonb_build_object('action','lock','unlockToken',token));
 result:=public.meal_ledger_workspace(jsonb_build_object('action','get','unlockToken',token));
 assert result->>'locked'='true','Revoked token still works';
 result:=public.meal_ledger_workspace('{"action":"unlock","pin":"986543"}');
 token:=result->>'unlockToken';
 result:=public.meal_ledger_workspace(jsonb_build_object('action','removePin','unlockToken',token));
 result:=public.meal_ledger_workspace('{"action":"get"}');
 assert result->>'hasPin'='false','PIN removal failed';
 assert not has_table_privilege('authenticated','meal_ledger_private.workspaces','SELECT'),'Direct table access granted';
 assert not has_function_privilege('anon','public.meal_ledger_workspace(jsonb)','EXECUTE'),'Anonymous RPC access granted';
 raise notice 'PASS: database CRUD, conflict protection, schema validation, PIN locking and account isolation.';
end $$;
rollback;
