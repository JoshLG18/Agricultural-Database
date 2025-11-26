// import environment variables from azure or .env file
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

// load in all dependencies to variables
const express = require('express');
const sql = require('mssql'); 
const app = express();
const port = process.env.PORT || 3000;
const cors = require("cors");

app.use(cors());
app.use(express.json());

// Database config 
const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  options: { 
    encrypt: true,
    trustServerCertificate: false
  }
};

let pool; // variable to hold the connections

// Function to create and maintain the connection pool
async function connectToDb() {
  try {
    pool = await sql.connect(dbConfig); // wait for connection with the database
    console.log("Connected to Azure SQL Database!"); // if connected log success
  } catch (err) { // if there is an error
    console.error("Database connection failed:", err.message); // log the error message
    // exit the process if there is a failure
    process.exit(1); 
  }
}

// Function to allow for data insertion - creates type mapping
function TypeMapping(col_name) {
  const mappings = {
    "farmID": sql.Int,
    "cropID": sql.Int,
    "soilID": sql.Int,
    "resourceID": sql.Int,
    "initativeID": sql.Int,

    'ph_level': sql.Decimal(3, 1),
    'nitrogen_level': sql.Int,
    'phosphorus_level': sql.Int,
    'potassium_level': sql.Int,
    'resource_quantity': sql.Decimal(10, 2),
    'crop_yield': sql.Int,
    'ev_score': sql.Int,
    'labour_hours': sql.Int,

    'planting_date': sql.Date,
    'harvest_date': sql.Date,
    'date_of_application': sql.Date,
    'date_initiated': sql.Date,
  };
  return mappings[col_name] || sql.NVarChar;
}

// Endpoints

// Root endpoint
app.get("/", (req, res) => { // base endpoint at /
  // send a message to the user if it is working
  res.send("Agricultural DB API is working!! Use /farm to interact."); 
});

// Full query request - only allows SELECT statements
app.post("/query", async (req, res) => {
  const sqlQuery = req.body && req.body.sql; // get the SQL from the frontend body
  // return an error if there is no SQL provided
  if (!sqlQuery) return res.status(400).json({ error: "Missing 'sql' in body" });

  // turn the query to uppercase and trim whitespace for checking
  const upperSql = sqlQuery.trim().toUpperCase();

  // check if the sql starts with SELECT if not return an error
  if (!upperSql.startsWith("SELECT")) {
    return res.status(403).json({  // error 403 = forbidden
      error: "Forbidden: Only SELECT queries are allowed via this endpoint." 
    });
  }

  console.log("Running SQL:", sqlQuery); // log that the query is running

  try {
    // execute the query and wait for the result
    const result = await pool.request().query(sqlQuery);

    res.json(result.recordset); // send back the resulting data as JSON
  } catch (err) {
    return res.status(500).json({ error: err.message }); // return any SQL errors
  }
});

// GET request: Retrieve data by table and optional ID
app.get("/:table/:id?", async (req, res) => {
  // get the parameters from the request in the URL
  const table = req.params.table;   
  const id = req.params.id;         

  // set the base sql to be a select all from the table
  let sqlQuery = `SELECT * FROM ${table}`; 

  try {
    // create a new request object
    const request = pool.request();
    
    // if there is an ID provided, add a WHERE clause to the SQL
    if (id) {
        const pk = table.toLowerCase() + "ID";   
        sqlQuery += ` WHERE ${pk} = @idParam`; 
        request.input('idParam', sql.Int, id);
    }
    // execute the query and wait for the result
    const result = await request.query(sqlQuery);
    res.json(result.recordset);

  // catch any errors that occur during the process
  } catch (err) {
    // Log the full error to the console
    console.error(`Error in GET /${table}/${id}:`, err); 
    return res.status(500).json({ error: err.message });
  }
});

// POST request - insert a record
app.post("/:table", async (req, res) => {
  // get the parameters from the request in the URL
  const table = req.params.table;
  const data = req.body; 

  try {
    // create a new request object
    const request = pool.request();

    // builds the columns and values for the insert statement
    const columns = Object.keys(data);

    const values = columns.map(col => `@${col}`);

    // creates SQL parameters for each column
    columns.forEach(col => {
        const type = TypeMapping(col); 
        request.input(col, type, data[col]); 
    });

    // construct the full SQL insert statement
    const sqlQuery = `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${values.join(', ')})`;

    // wait for the query to run and get the result
    const result = await request.query(sqlQuery);
    console.log('Data Inserted'); // log success - data entered

    // return a response to the frontend
    return res.status(201).json({ ok: true, rowsAffected: result.rowsAffected[0] });

  } catch (err) {
    console.error(`Error in POST /${table}:`, err);
    return res.status(500).json({ error: err.message });
  }
});

// PUT request - update a current record
app.put("/:table/:id", async (req, res) => {
  // get the parameters from the request in the URL
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  try {
    // create a new request object in the pool
    const request = pool.request();

    const columns = Object.keys(data); 

    // builds the SET clauses for the update statement
    const setClauses = columns.map(col => `${col} = @${col}`);

    // figure out the primary key name as the table name + "ID"
    const pk = table.toLowerCase() + "ID";   

    // Define all parameters
    columns.forEach(col => {
        const type = TypeMapping(col); 
        request.input(col, type, data[col]); 
    });

    // define the ID parameter
    request.input('idParam', sql.Int, id);

    // construct the full SQL update statement
    let sqlQuery = `UPDATE ${table} SET ${setClauses.join(', ')} WHERE ${pk} = @idParam`;

    // wait for the query to run and get the result
    const result = await request.query(sqlQuery);

    console.log('Data Updated'); // log success - data updated

    // check if any rows were affected
    if (result.rowsAffected[0] === 0) {
      // no rows updated - return 404 not found
      return res.status(404).json({ ok: false, message: "No matching record found to update" });
    }

    // return success response to frontend
    return res.status(200).json({ ok: true, rowsAffected: result.rowsAffected[0] });

  } catch (err) { // catch any errors and return to frontend
    console.error(`Error in PUT /${table}/${id}:`, err);
    return res.status(500).json({ error: err.message });
  }
});
 
// PATCH request - partially update a record - same logic as the PUT request
app.patch("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  try {
    const request = pool.request();
    const columns = Object.keys(data);

    // builds the SET clauses for the update statement
    const setClauses = columns.map(col => `${col} = @${col}`);
    const pk = table.toLowerCase() + "ID";   

    // Define all parameters
    columns.forEach(col => {
        const type = TypeMapping(col); 
        request.input(col, type, data[col]);
    });

    request.input('idParam', sql.Int, id);

    let sqlQuery = `UPDATE ${table} SET ${setClauses.join(', ')} WHERE ${pk} = @idParam`;
    
    const result = await request.query(sqlQuery);
    console.log('Data Updated');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ ok: false, message: "No matching record found to patch" });
    }
    
    return res.status(200).json({ ok: true, rowsAffected: result.rowsAffected[0] });

  } catch (err) {
    console.error(`Error in PATCH /${table}/${id}:`, err);
    return res.status(500).json({ error: err.message });
  }
});

// DELETE request - delete a record
app.delete("/:table/:id", async (req, res) => {
  // get the parameters from the request in the URL
  const table = req.params.table;
  const id = req.params.id;

  try {
    // construct the primary key name
    const pk = table.toLowerCase() + "ID";

    // construct the full SQL delete statement
    const sqlQuery = `DELETE FROM ${table} WHERE ${pk} = @idParam`;
    
    // execute the delete query
    const result = await pool.request()
        .input('idParam', sql.Int, id)
        .query(sqlQuery);

    // log success - data deleted
    console.log("Data Deleted");

    // check if any rows were affected
    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ ok: false, message: "No matching record found" });
    }
    // return success response to frontend
    return res.status(200).json({
      ok: true,
      message: "Record deleted successfully",
      affectedRows: result.rowsAffected[0]
    });
  } catch (err) {
    // log any errors that occur
    console.error(`Error in DELETE /${table}/${id}:`, err);
    return res.status(500).json({ error: err.message });
  }
});

// Start server
connectToDb().then(() => {
  const port = process.env.PORT || 8080;
  app.listen(port, "0.0.0.0", () => {
    console.log(`Server running on http://0.0.0.0:${port}`);
  });
});


// References Used:
// https://www.youtube.com/watch?v=Uvy_BlgwfLI
// https://www.youtube.com/watch?v=XJpYH7K7TGM
// https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-nodejs?view=azuresql&tabs=macos
// https://www.npmjs.com/package/mssql
// https://expressjs.com/en/4x/api.html#app
// https://www.w3schools.com/js/
