const express=require("express"); const app=express(); app.use(express.json()); const PORT=process.env.PORT||3009;
const stock=new Map([["p1",25],["p2",18],["p3",30],["p4",40]]);
app.get("/health",(_,res)=>res.json({service:"inventory-service",status:"ok"}));
app.get("/inventory/:productId",(req,res)=>res.json({productId:req.params.productId,available:stock.get(req.params.productId)||0}));
app.post("/inventory/reserve",(req,res)=>{const items=req.body.items||[];for(const i of items){if((stock.get(i.productId)||0)<i.quantity)return res.status(409).json({message:`Insufficient stock for ${i.productId}`});}for(const i of items)stock.set(i.productId,(stock.get(i.productId)||0)-i.quantity);res.json({reserved:true,items});});
app.post("/inventory/release",(req,res)=>{for(const i of req.body.items||[])stock.set(i.productId,(stock.get(i.productId)||0)+i.quantity);res.json({released:true});});
app.listen(PORT,()=>console.log(`inventory-service listening on ${PORT}`));
