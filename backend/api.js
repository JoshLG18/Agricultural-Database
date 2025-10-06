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


// add the ability to select all from the database - selects all from the table
app.get("/Farms", async (req, res) => { // defines get endpoint at /farm | req is the request and res is the response
  try {
    con.query("SELECT * FROM Farm", (err, result) => { // runs sql query when the user goes to the endpoint
      if (err) {
        return res.status(500).json({ error: err.message }); 
      }
      res.json(result); // if no error return the json result
    });
  } catch (err) {
    res.status(500).json({ error: err.message }); // if there is an error return the error
  }
});

app.get("/Crops", async (req, res) => {
  try {
    con.query("SELECT * FROM Crops", (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/Soils", async (req, res) => {
  try {
    con.query("SELECT * FROM Soils", (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/Resources", async (req, res) => {
  try {
    con.query("SELECT * FROM Resources", (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get("/Initiatives", async (req, res) => {
  try {
    con.query("SELECT * FROM Initiatives", (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// using the user input to create the sql query sent to the DB - WORKS
app.get("/:table/:id?", async (req, res) => {
    const table = req.params.table;
    const id = req.params.id;
    let sql = `SELECT * FROM ??`; 
    let params = [table];

    if (id) {
      sql += `WHERE ` + table.toLowerCase() + `ID = ?`;
      params.push(id);
    }

    // run the query
    con.query(sql, params, (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
  })
});

// creating the post request
app.post("/:table", async (req, res) => {
  const table = req.params.table;
  const data = req.body;
  let sql = `INSERT INTO ?? SET ?`;
  let params = [table, data];
  con.query(sql, params, (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    console.log('Data Inserted')
    })
});


// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
