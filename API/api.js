// Set up 
const express = require('express');
const mysql = require('mysql');

const app = express();
const port = 3000;


// Connect to database
let con = mysql.createConnection({
  host: "localhost",
  user: "API",
  password: "Wycombe153*",
  database: "Agriculture"
});

con.connect(function(err) {
  if (err) throw err;
  console.log("Connected!");  
});


// add the ability to select all from the database - selects all from the farm table (any SQL can go in there - will add input option)
app.get("/farm", async (req, res) => {
  try {
    con.query("SELECT * FROM Farm", (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(result);
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
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






// Root endpoint
app.get("/", (req, res) => {
  res.send("Agricultural DB API is working!! Use /farm to interact.");
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
