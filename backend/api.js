// Import required libaries
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

const express = require('express');
const sql = require('mssql'); 
const app = express();
const port = process.env.PORT || 3000;
const cors = require("cors");

app.use(cors());
app.use(express.json());

// Database config

// Configuration - set up the database access
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

let pool; 

// Function to create and maintain the connection pool
async function connectToDb() {
  try {
    pool = await sql.connect(dbConfig);
    console.log("Connected to Azure SQL Database!");
  } catch (err) {
    console.error("Database connection failed:", err.message);
    // Exit if the database connection fails on startup
    process.exit(1); 
  }
}

// Endpoints

// Root endpoint
app.get("/", (req, res) => {
  res.send("Agricultural DB API is working!! Use /farm to interact.");
});

// Full query request - only allows SELECT statements
app.post("/query", async (req, res) => {
  const sqlQuery = req.body && req.body.sql;
  if (!sqlQuery) return res.status(400).json({ error: "Missing 'sql' in body" });

  const upperSql = sqlQuery.trim().toUpperCase();

  if (!upperSql.startsWith("SELECT")) {
    return res.status(403).json({  
      error: "Forbidden: Only SELECT queries are allowed via this endpoint." 
    });
  }

  console.log("Running SQL:", sqlQuery);

  try {
    const result = await pool.request().query(sqlQuery);

    res.json(result.recordset); 
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// GET request: Retrieve data by table and optional ID
app.get("/:table/:id?", async (req, res) => {
  const table = req.params.table;   
  const id = req.params.id;         

  let sqlQuery = `SELECT * FROM ${table}`; 

  try {
    const request = pool.request();
    
    if (id) {
        const pk = table.toLowerCase() + "ID";   
        sqlQuery += ` WHERE ${pk} = @idParam`; 
        request.input('idParam', sql.Int, id);
    }

    const result = await request.query(sqlQuery);
    res.json(result.recordset);

  } catch (err) {
    // Log the full error to the console
    console.error(`Error in GET /${table}/${id}:`, err); 
    return res.status(500).json({ error: err.message });
  }
});

// POST request: Insert new record
app.post("/:table", async (req, res) => {
  const table = req.params.table;
  const data = req.body; 

  // Safely construct INSERT query using mssql inputs
  try {
    const request = pool.request();
    const columns = Object.keys(data);
    const values = columns.map(col => `@${col}`);

    // Map all properties from the request body to mssql input parameters
    columns.forEach(col => {
        // Use VARCHAR as a generic type, or specify actual SQL type if known
        request.input(col, sql.VarChar, data[col]); 
    });

    const sqlQuery = `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${values.join(', ')})`;

    const result = await request.query(sqlQuery);
    console.log('Data Inserted');


    return res.status(201).json({ ok: true, rowsAffected: result.rowsAffected[0] });

  } catch (err) {
    console.error(`Error in POST /${table}:`, err);
    return res.status(500).json({ error: err.message });
  }
});

// PUT request: Full update of record
app.put("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  try {
    const request = pool.request();
    const setClauses = Object.keys(data).map(col => `${col} = @${col}`);
    const pk = table.toLowerCase() + "ID";   

    // Define all parameters
    Object.keys(data).forEach(col => {
        request.input(col, sql.VarChar, data[col]);
    });
    request.input('idParam', sql.Int, id);

    let sqlQuery = `UPDATE ${table} SET ${setClauses.join(', ')} WHERE ${pk} = @idParam`;

    const result = await request.query(sqlQuery);
    console.log('Data Updated');

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ ok: false, message: "No matching record found to update" });
    }
    
    return res.status(200).json({ ok: true, rowsAffected: result.rowsAffected[0] });

  } catch (err) {
    console.error(`Error in PUT /${table}/${id}:`, err);
    return res.status(500).json({ error: err.message });
  }
});
 
// PATCH request: Partial update of record (Uses the same logic as PUT for simplicity)
app.patch("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  try {
    const request = pool.request();
    const setClauses = Object.keys(data).map(col => `${col} = @${col}`);
    const pk = table.toLowerCase() + "ID";   

    // Define all parameters
    Object.keys(data).forEach(col => {
        request.input(col, sql.VarChar, data[col]);
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

// DELETE request: Delete a record
app.delete("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;

  try {
    const pk = table.toLowerCase() + "ID";
    const sqlQuery = `DELETE FROM ${table} WHERE ${pk} = @idParam`;
    
    const result = await pool.request()
        .input('idParam', sql.Int, id)
        .query(sqlQuery);

    console.log("Data Deleted");

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ ok: false, message: "No matching record found" });
    }

    return res.status(200).json({
      ok: true,
      message: "Record deleted successfully",
      affectedRows: result.rowsAffected[0]
    });
  } catch (err) {
    console.error(`Error in DELETE /${table}/${id}:`, err);
    return res.status(500).json({ error: err.message });
  }
});

// Start server
connectToDb().then(() => {
    app.listen(port, () => {
      console.log(`Server running at http://localhost:${port}`);
    });
});