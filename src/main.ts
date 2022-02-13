import express from "express";
var app = express();

app.get('*', (_, res) => {
   res.send("Hey");
});

app.listen(3001);

