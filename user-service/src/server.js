const express = require("express");
const app = express(); app.use(express.json());
const PORT = process.env.PORT || 3002;
const users = new Map([
  ["1", { id:"1", name:"Demo Customer", email:"demo@example.com", addresses:[{ id:"a1", line1:"King Fahd Road", city:"Riyadh", country:"Saudi Arabia" }] }]
]);
app.get("/health", (_,res)=>res.json({service:"user-service",status:"ok"}));
app.get("/users/:id", (req,res)=> { const u=users.get(req.params.id); return u?res.json(u):res.status(404).json({message:"User not found"}); });
app.put("/users/:id", (req,res)=> { const existing=users.get(req.params.id)||{id:req.params.id}; const updated={...existing,...req.body,id:req.params.id}; users.set(req.params.id,updated); res.json(updated); });
app.listen(PORT,()=>console.log(`user-service listening on ${PORT}`));
