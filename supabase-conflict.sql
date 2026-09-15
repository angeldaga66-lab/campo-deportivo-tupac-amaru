create or replace function public.prevent_field_overlap()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  conflict_found boolean;
begin
  if NEW.status = 'cancelled' then
    return NEW;
  end if;

  select exists (
    select 1
    from public.reservations r
    where r.id <> coalesce(NEW.id, -1)
      and r.reservation_date = NEW.reservation_date
      and r.status <> 'cancelled'
      and r.start_time < NEW.end_time
      and r.end_time > NEW.start_time
      and (
        -- Fútbol 11 ocupa todo el espacio físico.
        (NEW.field_type = 'Fútbol 11' and NEW.field_number = 7)
        or (r.field_type = 'Fútbol 11' and r.field_number = 7)

        -- El mismo campo físico no puede tener dos reservas.
        or (NEW.field_type = r.field_type and NEW.field_number = r.field_number)

        -- Fútbol 9 Campo 5 = Fútbol 7 Campos 1 + 2.
        or (
          NEW.field_type = 'Fútbol 9' and NEW.field_number = 5
          and r.field_type = 'Fútbol 7' and r.field_number in (1,2)
        )
        or (
          r.field_type = 'Fútbol 9' and r.field_number = 5
          and NEW.field_type = 'Fútbol 7' and NEW.field_number in (1,2)
        )

        -- Fútbol 9 Campo 6 = Fútbol 7 Campos 3 + 4.
        or (
          NEW.field_type = 'Fútbol 9' and NEW.field_number = 6
          and r.field_type = 'Fútbol 7' and r.field_number in (3,4)
        )
        or (
          r.field_type = 'Fútbol 9' and r.field_number = 6
          and NEW.field_type = 'Fútbol 7' and NEW.field_number in (3,4)
        )
      )
  ) into conflict_found;

  if conflict_found then
    raise exception 'El horario solicitado ya no esta disponible';
  end if;

  return NEW;
end;
$$;

drop trigger if exists reservations_no_overlap on public.reservations;

create trigger reservations_no_overlap
before insert or update on public.reservations
for each row execute function public.prevent_field_overlap();
