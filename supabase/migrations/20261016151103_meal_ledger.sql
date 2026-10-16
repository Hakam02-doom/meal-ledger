-- Meal Ledger database. No table in this schema is exposed through the Data API.
create schema if not exists meal_ledger_private;
revoke all on schema meal_ledger_private from public,anon;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_jsonschema with schema extensions;
create table meal_ledger_private.workspaces (
 owner uuid primary key references auth.users(id) on delete cascade,
 payload jsonb not null default '{"schools":[],"vendors":[],"entries":[],"trash":[],"audit":[]}'::jsonb,
 revision bigint not null default 0,
 pin_hash text,
 failures integer not null default 0,
 locked_until timestamptz
);
create table meal_ledger_private.unlock_sessions (
 token_hash text primary key,
 owner uuid not null references meal_ledger_private.workspaces(owner) on delete cascade,
 expires timestamptz not null
);
create index meal_ledger_sessions_owner_expires on meal_ledger_private.unlock_sessions(owner,expires);
alter table meal_ledger_private.workspaces enable row level security;
alter table meal_ledger_private.unlock_sessions enable row level security;
create or replace function meal_ledger_private.valid_payload(data jsonb)
returns boolean language plpgsql immutable set search_path='' as $$
declare e jsonb; dt text;
begin
 if not extensions.jsonb_matches_schema($schema${"type": "object", "properties": {"schools": {"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "minLength": 1, "maxLength": 100}, "name": {"type": "string", "maxLength": 250, "minLength": 1}, "udise": {"type": "string", "maxLength": 250}, "type": {"enum": ["UKG", "PRIMARY", "UPPER PRIMARY"]}, "cookingOpening": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}, "fruitOpening": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}}, "required": ["id", "name", "udise", "type", "cookingOpening", "fruitOpening"], "additionalProperties": false}, "maxItems": 3000}, "vendors": {"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "minLength": 1, "maxLength": 100}, "name": {"type": "string", "maxLength": 250, "minLength": 1}, "account": {"type": "string", "maxLength": 250}, "ifsc": {"type": "string", "maxLength": 250}, "branch": {"type": "string", "maxLength": 250}}, "required": ["id", "name", "account", "ifsc", "branch"], "additionalProperties": false}, "maxItems": 3000}, "entries": {"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "minLength": 1, "maxLength": 100}, "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, "documentType": {"enum": ["Bill", "Payment Invoice"]}, "tokenNo": {"type": "string", "maxLength": 250}, "tokenDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "voucherNo": {"type": "string", "maxLength": 250}, "voucherDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "referenceNo": {"type": "string", "maxLength": 250}, "billNo": {"type": "string", "maxLength": 250, "minLength": 1}, "billDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "schoolId": {"type": "string", "minLength": 1, "maxLength": 100}, "schoolType": {"enum": ["UKG", "PRIMARY", "UPPER PRIMARY"]}, "fund": {"enum": ["Cooking", "Fruit"]}, "sanctionNo": {"type": "string", "maxLength": 250}, "sanctionDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "received": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}, "consumed": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}, "status": {"enum": ["Passed", "Pending", "Failed", "Cancelled"]}, "vendorName": {"type": "string", "maxLength": 250}, "account": {"type": "string", "maxLength": 250}, "ifsc": {"type": "string", "maxLength": 250}, "branch": {"type": "string", "maxLength": 250}, "remarks": {"type": "string", "maxLength": 2000}}, "required": ["id", "date", "documentType", "tokenNo", "tokenDate", "voucherNo", "voucherDate", "referenceNo", "billNo", "billDate", "schoolId", "schoolType", "fund", "sanctionNo", "sanctionDate", "received", "consumed", "status", "vendorName", "account", "ifsc", "branch", "remarks"], "additionalProperties": false, "anyOf": [{"properties": {"received": {"exclusiveMinimum": 0}}}, {"properties": {"consumed": {"exclusiveMinimum": 0}}}]}, "maxItems": 15000}, "trash": {"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "minLength": 1, "maxLength": 100}, "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, "documentType": {"enum": ["Bill", "Payment Invoice"]}, "tokenNo": {"type": "string", "maxLength": 250}, "tokenDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "voucherNo": {"type": "string", "maxLength": 250}, "voucherDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "referenceNo": {"type": "string", "maxLength": 250}, "billNo": {"type": "string", "maxLength": 250, "minLength": 1}, "billDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "schoolId": {"type": "string", "minLength": 1, "maxLength": 100}, "schoolType": {"enum": ["UKG", "PRIMARY", "UPPER PRIMARY"]}, "fund": {"enum": ["Cooking", "Fruit"]}, "sanctionNo": {"type": "string", "maxLength": 250}, "sanctionDate": {"anyOf": [{"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$", "format": "date"}, {"const": ""}]}, "received": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}, "consumed": {"type": "number", "minimum": 0, "maximum": 999999999, "multipleOf": 0.01}, "status": {"enum": ["Passed", "Pending", "Failed", "Cancelled"]}, "vendorName": {"type": "string", "maxLength": 250}, "account": {"type": "string", "maxLength": 250}, "ifsc": {"type": "string", "maxLength": 250}, "branch": {"type": "string", "maxLength": 250}, "remarks": {"type": "string", "maxLength": 2000}}, "required": ["id", "date", "documentType", "tokenNo", "tokenDate", "voucherNo", "voucherDate", "referenceNo", "billNo", "billDate", "schoolId", "schoolType", "fund", "sanctionNo", "sanctionDate", "received", "consumed", "status", "vendorName", "account", "ifsc", "branch", "remarks"], "additionalProperties": false, "anyOf": [{"properties": {"received": {"exclusiveMinimum": 0}}}, {"properties": {"consumed": {"exclusiveMinimum": 0}}}]}, "maxItems": 15000}, "audit": {"type": "array", "items": {"type": "object", "properties": {"id": {"type": "string", "minLength": 1, "maxLength": 100}, "at": {"type": "string"}, "message": {"type": "string", "maxLength": 250}}, "required": ["id", "at", "message"], "additionalProperties": false}, "maxItems": 300}}, "required": ["schools", "vendors", "entries", "trash", "audit"], "additionalProperties": false}$schema$::json,data) then return false; end if;
 if exists(select 1 from jsonb_array_elements(data->'schools') s group by s->>'id' having count(*)>1)
 or exists(select 1 from jsonb_array_elements(data->'vendors') s group by s->>'id' having count(*)>1)
 or exists(select 1 from jsonb_array_elements((data->'entries')||(data->'trash')) e group by e->>'id' having count(*)>1)
 or exists(select 1 from jsonb_array_elements(data->'schools') s where s->>'udise'<>'' group by s->>'udise' having count(*)>1)
 or exists(select 1 from jsonb_array_elements((data->'entries')||(data->'trash')) e where not exists(select 1 from jsonb_array_elements(data->'schools') s where s->>'id'=e->>'schoolId'))
 then return false; end if;
 for e in select value from jsonb_array_elements((data->'entries')||(data->'trash')) loop
  foreach dt in array array[e->>'date',e->>'tokenDate',e->>'voucherDate',e->>'billDate',e->>'sanctionDate'] loop
   if dt<>'' and to_char(dt::date,'YYYY-MM-DD')<>dt then return false; end if;
  end loop;
 end loop;
 return true;
exception when others then return false;
end;
$$;
create or replace function meal_ledger_private.workspace(request jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
 uid uuid := auth.uid();
 action text := request->>'action';
 w meal_ledger_private.workspaces%rowtype;
 unlocked boolean;
 token text;
 next_payload jsonb;
 rev bigint;
begin
 if uid is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  return jsonb_build_object('status',401,'error','Sign in to access your register.');
 end if;
 if action is null or action not in ('get','save','pin','unlock','lock','removePin') then
  return jsonb_build_object('status',400,'error','Unknown action.');
 end if;
 insert into meal_ledger_private.workspaces(owner) values(uid) on conflict do nothing;
 select * into w from meal_ledger_private.workspaces where owner=uid for update;
 select exists(select 1 from meal_ledger_private.unlock_sessions where owner=uid
  and token_hash=encode(extensions.digest(coalesce(request->>'unlockToken',''),'sha256'),'hex')
  and expires>now()) into unlocked;
 if action='unlock' then
  if w.pin_hash is null then return jsonb_build_object('ok',true); end if;
  if w.locked_until>now() then return jsonb_build_object('status',429,'error','Too many attempts. Please try again in 5 minutes.'); end if;
  if coalesce(request->>'pin','') !~ '^[0-9]{4,12}$' then return jsonb_build_object('status',400,'error','Use a PIN of 4–12 digits.'); end if;
  if extensions.crypt(request->>'pin',w.pin_hash)<>w.pin_hash then
   update meal_ledger_private.workspaces set failures=failures+1,
    locked_until=case when failures+1>=5 then now()+interval '5 minutes' else null end where owner=uid;
   return jsonb_build_object('status',403,'error','That PIN is incorrect.');
  end if;
  token:=encode(extensions.gen_random_bytes(32),'hex');
  update meal_ledger_private.workspaces set failures=0,locked_until=null where owner=uid;
  delete from meal_ledger_private.unlock_sessions where owner=uid and expires<=now();
  insert into meal_ledger_private.unlock_sessions(token_hash,owner,expires)
   values(encode(extensions.digest(token,'sha256'),'hex'),uid,now()+interval '8 hours');
  return jsonb_build_object('ok',true,'unlockToken',token);
 end if;
 if action='lock' then
  delete from meal_ledger_private.unlock_sessions where owner=uid
   and token_hash=encode(extensions.digest(coalesce(request->>'unlockToken',''),'sha256'),'hex');
  return jsonb_build_object('ok',true);
 end if;
 if w.pin_hash is not null and not unlocked then
  if action='get' then return jsonb_build_object('locked',true,'hasPin',true); end if;
  return jsonb_build_object('status',423,'locked',true,'error','Unlock your register first.');
 end if;
 if action='get' then return jsonb_build_object('data',w.payload,'revision',w.revision,'hasPin',w.pin_hash is not null,'locked',false); end if;
 if action='pin' then
  if coalesce(request->>'pin','') !~ '^[0-9]{4,12}$' then return jsonb_build_object('status',400,'error','Use a PIN of 4–12 digits.'); end if;
  update meal_ledger_private.workspaces set pin_hash=extensions.crypt(request->>'pin',extensions.gen_salt('bf',10)),failures=0,locked_until=null where owner=uid;
  delete from meal_ledger_private.unlock_sessions where owner=uid;
  return jsonb_build_object('ok',true,'locked',true);
 end if;
 if action='removePin' then
  update meal_ledger_private.workspaces set pin_hash=null,failures=0,locked_until=null where owner=uid;
  delete from meal_ledger_private.unlock_sessions where owner=uid;
  return jsonb_build_object('ok',true);
 end if;
 next_payload:=request->'data';
 if next_payload is null or not meal_ledger_private.valid_payload(next_payload) then return jsonb_build_object('status',400,'error','Invalid register data.'); end if;
 if octet_length(next_payload::text)>1500000 then return jsonb_build_object('status',413,'error','Register is too large. Export and archive older records.'); end if;
 if coalesce(request->>'revision','') !~ '^[0-9]{1,15}$' then return jsonb_build_object('status',400,'error','Missing revision.'); end if;
 rev:=(request->>'revision')::bigint;
 if rev<>w.revision then return jsonb_build_object('status',409,'error','This register changed in another tab. Reload before saving to avoid overwriting newer records.'); end if;
 update meal_ledger_private.workspaces set payload=next_payload,revision=revision+1 where owner=uid;
 return jsonb_build_object('ok',true,'revision',rev+1);
end;
$$;
-- The exposed wrapper is an invoker; the privileged function is in a non-exposed schema.
create or replace function public.meal_ledger_workspace(request jsonb)
returns jsonb language sql security invoker set search_path='' as $$
 select meal_ledger_private.workspace(request);
$$;
revoke all on all tables in schema meal_ledger_private from public,anon,authenticated;
revoke all on all functions in schema meal_ledger_private from public,anon,authenticated;
revoke all on function public.meal_ledger_workspace(jsonb) from public,anon;
grant usage on schema meal_ledger_private to authenticated;
grant execute on function meal_ledger_private.workspace(jsonb) to authenticated;
grant execute on function public.meal_ledger_workspace(jsonb) to authenticated;
