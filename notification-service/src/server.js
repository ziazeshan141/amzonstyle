const express=require("express"); const app=express(); app.use(express.json()); const PORT=process.env.PORT||3013; const notifications=[];
app.get("/health",(_,res)=>res.json({service:"notification-service",status:"ok"}));
app.post("/notifications",(req,res)=>{const n={id:`n_${Date.now()}`,channel:req.body.channel||"email",recipient:req.body.recipient,message:req.body.message,status:"SENT_DEMO",createdAt:new Date().toISOString()};notifications.push(n);console.log("notification",n);res.status(201).json(n);});
app.get("/notifications",(_,res)=>res.json(notifications));
app.listen(PORT,()=>console.log(`notification-service listening on ${PORT}`));
