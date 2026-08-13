const express=require("express"); const app=express(); app.use(express.json()); const PORT=process.env.PORT||3008; const payments=[];
app.get("/health",(_,res)=>res.json({service:"payment-service",status:"ok"}));
app.post("/payments",(req,res)=>{const {orderId,amount,currency="USD",method="demo-card"}=req.body;if(!amount||amount<=0)return res.status(400).json({message:"Valid amount required"});const p={id:`pay_${Date.now()}`,orderId,amount,currency,method,status:"APPROVED",createdAt:new Date().toISOString()};payments.push(p);res.status(201).json(p);});
app.get("/payments/:id",(req,res)=>{const p=payments.find(x=>x.id===req.params.id);return p?res.json(p):res.status(404).json({message:"Payment not found"});});
app.listen(PORT,()=>console.log(`payment-service listening on ${PORT}`));
