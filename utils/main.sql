create table public.team (
    id uuid primary key,

    constraint fk_team_user foreign key (id) references auth.users(id)
);

create table public.systems (
    id serial primary key,
    name text not null unique,
    description text,

    -- What URL to hit to?
    sys_url text,

    -- What is an acceptable number for the latency
    acc_num integer,
    created_at timestamp default now()
);

create table public.latencies (
    id serial primary key,
    sys_id integer,
    latency integer not null,
    created_at timestamp default now(),

    constraint fk_latencies_system foreign key (sys_id) references public.systems(id)
);

create table public.incidents (
    id serial primary key,
    sys_id integer,
    title text not null,
    description text not null,
    
    -- References to images stored in Supabase bucket of the incident if any
    ref_images text[],

    -- Incident checked by the team
    is_legit boolean default false,
    
    what text,
    why text,
    how text,

    is_resolved boolean default false,

    created_at timestamp default now(),

    constraint fk_incidents_system foreign key (sys_id) references public.systems(id)
);

create table public.messages (
    id serial primary key,
    incident_id integer,
    message text not null,
    user_id uuid not null,
    created_at timestamp default now(),

    constraint fk_messages_incident foreign key (incident_id) references public.incidents(id),
    constraint fk_messages_user foreign key (user_id) references auth.users(id)
);

create table public.checks (
    id serial primary key,
    name text not null,
    slug text not null unique,
    description text,
    sys_id integer,
    cron_expr text not null,
    
    constraint fk_checks_system foreign key (sys_id) references public.systems(id)
);

create table public.checks_history (
    id serial primary key,
    check_id integer,
    sys_id integer,
    created_at timestamp default now(),
    status boolean default true,
    error_message text,

    constraint fk_check_history_check foreign key (check_id) references public.checks(id),
    constraint fk_check_history_system foreign key (sys_id) references public.systems(id)
);

-- A function that runs on trigger to hit the latency function
create function ping_latency_function()
returns trigger
language plpgsql
as $func$
begin
    if(old.sys_url is not null) then
        perform cron.schedule(
                '* * * * *',
                $cron$
                    select *
                    from http((
                        'GET',
                        'http://localhost:3000/api/latency?sys_url=' || old.sys_url,
                        ARRAY[http_header('Bearer', 'from-cron-for-latency')]
                    )::http_request);
                $cron$
            );
    end if;

    return new;
end
$func$;

-- A trigger that runs the ping_latency_function every minute
create trigger ping_latency_trigger
after insert
on public.systems
for each row
execute procedure ping_latency_function();

create function ping_checks_function()
returns trigger
language plpgsql
as $func$
begin
    perform cron.schedule(
        old.cron_expr,
        $cron$
            select *
            from http((
                'GET',
                'http://localhost:3000/api/check/' || old.slug,
                ARRAY[http_header('Bearer', 'from-cron-for-check')]
            )::http_request);
        $cron$
    );
end
$func$;

create trigger ping_checks_trigger
after insert
on public.checks
for each row
execute procedure ping_checks_function();
