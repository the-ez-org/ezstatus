const postgres = require("postgres");
require("dotenv").config({ path: ".env.local" });

const sql = postgres(process.env.DATABASE_URL);

sql`
    create table public.profiles (
        id uuid primary key,
        is_admin boolean default false,
        constraint fk_users_profiles foreign key(id) references auth.users(id)
    );
`
    .then(() => console.log("Profiles table created"))
    .catch((err) => console.error(err));
