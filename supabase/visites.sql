-- Journal des visites de la fiche fleuriste & décoratrice.
-- À exécuter une seule fois dans le projet Supabase de la fiche :
-- SQL Editor → New query → coller → Run.
--
-- Chaque passage enregistre : date, adresse IP, navigateur, page d'origine, langue,
-- taille d'écran et le nom de fleur du visiteur (le même que dans les cercles de présence).
-- L'adresse IP est relevée par Supabase à partir de la requête : la page ne peut pas la falsifier.
-- Un même visiteur qui recharge la page dans les 30 minutes ne crée pas de nouvelle ligne.
--
-- Les visiteurs peuvent seulement ajouter leur passage (via log_fiche_visit), jamais lire
-- le journal. Il se consulte depuis le tableau de bord Supabase (Table Editor → fiche_visites).

create table if not exists public.fiche_visites (
  id          bigint generated always as identity primary key,
  visited_at  timestamptz not null default now(),
  visitor_id  text not null,
  flower_name text,
  ip          text,
  user_agent  text,
  referrer    text,
  language    text,
  screen      text
);

create index if not exists fiche_visites_visitor_idx on public.fiche_visites (visitor_id, visited_at desc);

alter table public.fiche_visites enable row level security;
revoke all on public.fiche_visites from anon, authenticated;

create or replace function public.log_fiche_visit(
  p_visitor_id text,
  p_flower_name text default null,
  p_referrer text default null,
  p_language text default null,
  p_screen text default null
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  headers json := coalesce(nullif(current_setting('request.headers', true), ''), '{}')::json;
  client_ip text;
begin
  if p_visitor_id is null or length(p_visitor_id) not between 4 and 64 then
    return;
  end if;

  -- Rechargement par le même visiteur dans les 30 minutes : même passage.
  if exists (select 1 from public.fiche_visites
             where visitor_id = p_visitor_id and visited_at > now() - interval '30 minutes') then
    return;
  end if;

  client_ip := btrim(split_part(coalesce(headers ->> 'x-forwarded-for', headers ->> 'x-real-ip', ''), ',', 1));

  insert into public.fiche_visites (visitor_id, flower_name, ip, user_agent, referrer, language, screen)
  values (p_visitor_id,
          left(p_flower_name, 40),
          nullif(client_ip, ''),
          left(headers ->> 'user-agent', 400),
          left(p_referrer, 400),
          left(p_language, 40),
          left(p_screen, 20));
end;
$$;

revoke all on function public.log_fiche_visit(text, text, text, text, text) from public;
-- Seule la page (clé publique, rôle anon) enregistre des visites : un compte connecté n'en a pas besoin.
grant execute on function public.log_fiche_visit(text, text, text, text, text) to anon;
revoke execute on function public.log_fiche_visit(text, text, text, text, text) from authenticated;

-- Les dates sont stockées en heure universelle (UTC), comme partout dans Supabase.
-- Cette vue les affiche à l'heure de Paris (heure d'été / d'hiver gérée automatiquement) :
-- Table Editor → fiche_visites_paris.
create or replace view public.fiche_visites_paris
with (security_invoker = true) as
  select id,
         (visited_at at time zone 'Europe/Paris')::timestamp(0) as heure_paris,
         flower_name, ip, referrer, language, screen, user_agent, visitor_id
  from public.fiche_visites
  order by visited_at desc;

revoke all on public.fiche_visites_paris from anon, authenticated;

-- Consulter les visites (les plus récentes d'abord) :
--   select visited_at at time zone 'Europe/Paris' as quand, flower_name, ip, referrer, user_agent
--   from public.fiche_visites order by visited_at desc;
--
-- Nombre de visiteurs différents et de passages :
--   select count(distinct visitor_id) as visiteurs, count(*) as passages from public.fiche_visites;
--
-- Tout effacer (par exemple après le mariage) :
--   delete from public.fiche_visites;
