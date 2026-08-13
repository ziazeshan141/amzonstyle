const express=require("express"); const axios=require("axios");
const app=express(); app.use(express.json()); const PORT=process.env.PORT||3006; const PRODUCT_URL=process.env.PRODUCT_SERVICE_URL||"http://product-service:3003"; const carts=new Map();
app.get("/health",(_,res)=>res.json({service:"cart-service",status:"ok"}));
app.get("/carts/:userId",(req,res)=>res.json({userId:req.params.userId,items:carts.get(req.params.userId)||[]}));
app.post("/carts/:userId/items",async(req,res)=>{try{const {productId,quantity=1}=req.body;const {data:p}=await axios.get(`${PRODUCT_URL}/products/${productId}`);const cart=carts.get(req.params.userId)||[];const found=cart.find(x=>x.productId===productId);if(found)found.quantity+=Number(quantity);else cart.push({productId,title:p.title,price:p.price,quantity:Number(quantity)});carts.set(req.params.userId,cart);res.status(201).json({userId:req.params.userId,items:cart});}catch{res.status(404).json({message:"Product not found"});}});
app.delete("/carts/:userId/items/:productId",(req,res)=>{const cart=(carts.get(req.params.userId)||[]).filter(x=>x.productId!==req.params.productId);carts.set(req.params.userId,cart);res.json({items:cart});});
app.delete("/carts/:userId",(req,res)=>{carts.delete(req.params.userId);res.status(204).end();});
app.listen(PORT,()=>console.log(`cart-service listening on ${PORT}`));
