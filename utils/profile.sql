create table public.profiles (
    id uuid primary key,
    is_admin boolean default false,
    constraint fk_users_profiles foreign key(id) references auth.users(id)
);

create function create_profile()
returns trigger
language plpgsql
security definer
as $$
begin
    insert into public.profiles(id) values (new.id);
    return new;
end;
$$;

create trigger create_profile_on_insert
after insert on auth.users
for each statement
execute procedure create_profile();