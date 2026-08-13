const express=require("express"); const app=express(); app.use(express.json()); const PORT=process.env.PORT||3010; const shipments=[];
app.get("/health",(_,res)=>res.json({service:"shipping-service",status:"ok"}));
app.post("/shipments",(req,res)=>{const s={id:`ship_${Date.now()}`,orderId:req.body.orderId,address:req.body.address,status:"CREATED",trackingNumber:`AMZ${Date.now()}`,etaDays:3,createdAt:new Date().toISOString()};shipments.push(s);res.status(201).json(s);});
app.get("/shipments/:id",(req,res)=>{const s=shipments.find(x=>x.id===req.params.id);return s?res.json(s):res.status(404).json({message:"Shipment not found"});});
app.listen(PORT,()=>console.log(`shipping-service listening on ${PORT}`));
