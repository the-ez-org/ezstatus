const postgres = require("postgres");
require("dotenv").config({ path: ".env.local" });

const sql = postgres(process.env.DATABASE_URL);

// Profiles table
sql.file("utils/profile.sql")
    .then(() => console.log("Profiles table created"))
    .catch((err) => console.error(`Error in creating profiles table: ${err}`));
