-- Preparación del panel de administración
alter table public.reservations
  add column if not exists payment_method text not null default 'pending',
  add column if not exists notes text,
  add column if not exists total numeric not null default 0;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.admin_users enable row level security;

-- Un administrador solo puede verse a sí mismo en esta tabla.
drop policy if exists "Admins can view own admin record" on public.admin_users;
create policy "Admins can view own admin record"
on public.admin_users for select
to authenticated
using (user_id = auth.uid());

-- Los administradores pueden gestionar reservas.
drop policy if exists "Admins can manage reservations" on public.reservations;
create policy "Admins can manage reservations"
on public.reservations for all
to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Después de crear tu usuario en Authentication, ejecuta:
-- insert into public.admin_users(user_id) values ('PEGA-AQUI-EL-UUID-DE-TU-USUARIO');
