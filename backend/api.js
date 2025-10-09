// Import required libaries
const express = require('express');
const mysql = require('mysql');

const app = express(); // defines the express application
const port = 3000; // sets the port where the server will listen
const cors = require("cors"); // imports cors to allow for frontend to comms with backend

app.use(cors()); // use cors to allow the frontend to comms with backend
app.use(express.json()); // set up module to parse json automatically


// Connect to database
let con = mysql.createConnection({
  host: "localhost",
  user: "API",
  password: "Wycombe153*",
  database: "Agriculture"
});

con.connect(function(err) {
  if (err) throw err; // if the connectoin fails throw an error
  console.log("Connected!");  // if not say connected
});

// Root endpoint
app.get("/", (req, res) => {
  res.send("Agricultural DB API is working!! Use /farm to interact.");
});

// creating the full query request
app.post("/query", (req, res) => {
  const sql = req.body && req.body.sql;
  if (!sql) return res.status(400).json({ error: "Missing 'sql' in body" });

  console.log("Running SQL:", sql);
  con.query(sql, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});

// using the user input to create the sql query sent to the DB
app.get("/:table/:id?", (req, res) => {
  const table = req.params.table;   
  const id = req.params.id;         

  let sql = `SELECT * FROM ??`;
  let params = [table];

  if (id) {
    const pk = table.toLowerCase() + "ID";   // "Farm" -> "farmID", "Crop" -> "cropID"
    sql += ` WHERE ?? = ?`;                  // <-- add space + column placeholder
    params.push(pk, id);                     // <-- push COLUMN and VALUE (2 items)
  }

  // see exactly what MySQL will execute (leave this on while testing)
  console.log(require('mysql').format(sql, params));

  con.query(sql, params, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});

// creating the post request
app.post("/:table", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body; // e.g. { farmID:1, farm_Location:"Kent" }

  let sql = `INSERT INTO ?? SET ?`;
  let params = [table, data];

  con.query(sql, params, (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    console.log('Data Inserted');
    // send a response so the frontend can finish
    return res.status(201).json({ ok: true, insertedId: result.insertId || null });
  });
});

// creating the PUT request
app.put("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  let sql = `UPDATE ?? SET ?`;
  let params = [table, data]

  if (id) {
    const pk = table.toLowerCase() + "ID";   
    sql += ` WHERE ?? = ?`;                  
    params.push(pk, id);                     
  }

  console.log(require('mysql').format(sql, params));

  con.query(sql, params, (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    console.log('Data Updated');
    return res.status(201).json({ ok: true, insertedId: result.insertId || null });
    });
});
 
// creating the patch request
app.patch("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;
  const data = req.body;

  let sql = `UPDATE ?? SET ?`;
  let params = [table, data]

  if (id) {
    const pk = table.toLowerCase() + "ID";   
    sql += ` WHERE ?? = ?`;                  
    params.push(pk, id);                     
  }

  console.log(require('mysql').format(sql, params));

  con.query(sql, params, (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    console.log('Data Updated');
    return res.status(201).json({ ok: true, insertedId: result.insertId || null });
    });
});

// creating the delete request
app.delete("/:table/:id", async (req, res) => {
  const table = req.params.table;
  const id = req.params.id;

  const pk = table.toLowerCase() + "ID";
  const sql = `DELETE FROM ?? WHERE ?? = ?`;
  const params = [table, pk, id];

  console.log(require("mysql").format(sql, params));

  con.query(sql, params, (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    console.log("Data Deleted");

    if (result.affectedRows === 0) {
      return res.status(404).json({ ok: false, message: "No matching record found" });
    }

    return res.status(200).json({
      ok: true,
      message: "Record deleted successfully",
      affectedRows: result.affectedRows
    });
  });
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
