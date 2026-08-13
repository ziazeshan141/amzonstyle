const express = require("express");
const app = express(); app.use(express.json());
const PORT = process.env.PORT || 3003;
let products = [
 {id:"p1",title:"Wireless Headphones",category:"Electronics",price:149.99,rating:4.5,image:"https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80",description:"Noise-cancelling over-ear wireless headphones."},
 {id:"p2",title:"Smart Watch",category:"Electronics",price:199.99,rating:4.3,image:"https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80",description:"Fitness and notification smartwatch."},
 {id:"p3",title:"Coffee Maker",category:"Home",price:79.99,rating:4.2,image:"https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?auto=format&fit=crop&w=600&q=80",description:"Programmable coffee maker for home use."},
 {id:"p4",title:"Travel Backpack",category:"Fashion",price:59.99,rating:4.6,image:"https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=600&q=80",description:"Durable travel backpack with laptop compartment."}
];
app.get("/health",(_,res)=>res.json({service:"product-service",status:"ok"}));
app.get("/products",(req,res)=>res.json(products));
app.get("/products/:id",(req,res)=>{const p=products.find(x=>x.id===req.params.id); return p?res.json(p):res.status(404).json({message:"Product not found"});});
app.post("/products",(req,res)=>{const p={id:req.body.id||`p${Date.now()}`,...req.body};products.push(p);res.status(201).json(p);});
app.put("/products/:id",(req,res)=>{const i=products.findIndex(x=>x.id===req.params.id);if(i<0)return res.status(404).json({message:"Product not found"});products[i]={...products[i],...req.body,id:req.params.id};res.json(products[i]);});
app.delete("/products/:id",(req,res)=>{products=products.filter(x=>x.id!==req.params.id);res.status(204).end();});
app.listen(PORT,()=>console.log(`product-service listening on ${PORT}`));
