const express=require("express"); const axios=require("axios");
const app=express(); const PORT=process.env.PORT||3005; const PRODUCT_URL=process.env.PRODUCT_SERVICE_URL||"http://product-service:3003";
app.get("/health",(_,res)=>res.json({service:"search-service",status:"ok"}));
app.get("/search",async(req,res)=>{try{const q=String(req.query.q||"").toLowerCase();const {data}=await axios.get(`${PRODUCT_URL}/products`);const hits=!q?data:data.filter(p=>`${p.title} ${p.category} ${p.description}`.toLowerCase().includes(q));res.json({query:q,count:hits.length,items:hits});}catch{res.status(502).json({message:"Product service unavailable"});}});
app.listen(PORT,()=>console.log(`search-service listening on ${PORT}`));
