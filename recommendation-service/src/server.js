const express=require("express"); const axios=require("axios"); const app=express(); const PORT=process.env.PORT||3012; const PRODUCT_URL=process.env.PRODUCT_SERVICE_URL||"http://product-service:3003";
app.get("/health",(_,res)=>res.json({service:"recommendation-service",status:"ok"}));
app.get("/recommendations/:userId",async(req,res)=>{try{const {data}=await axios.get(`${PRODUCT_URL}/products`);const items=[...data].sort((a,b)=>b.rating-a.rating).slice(0,3);res.json({userId:req.params.userId,strategy:"top-rated-demo",items});}catch{res.status(502).json({message:"Product service unavailable"});}});
app.listen(PORT,()=>console.log(`recommendation-service listening on ${PORT}`));
