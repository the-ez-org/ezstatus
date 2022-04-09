const postgres = require("postgres");
require("dotenv").config({ path: ".env.local" });

const sql = postgres(process.env.DATABASE_URL);

sql.file("utils/main.sql").then(() => console.log("Tables and Functions created")).catch(console.error);
