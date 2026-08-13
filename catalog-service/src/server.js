const express=require("express"); const axios=require("axios");
const app=express(); const PORT=process.env.PORT||3004; const PRODUCT_URL=process.env.PRODUCT_SERVICE_URL||"http://product-service:3003";
app.get("/health",(_,res)=>res.json({service:"catalog-service",status:"ok"}));
app.get("/catalog",async(req,res)=>{try{const {data}=await axios.get(`${PRODUCT_URL}/products`);const grouped=data.reduce((a,p)=>{(a[p.category]??=[]).push(p);return a;},{});res.json(grouped);}catch(e){res.status(502).json({message:"Product service unavailable"});}});
app.get("/catalog/:category",async(req,res)=>{try{const {data}=await axios.get(`${PRODUCT_URL}/products`);res.json(data.filter(p=>p.category.toLowerCase()===req.params.category.toLowerCase()));}catch{res.status(502).json({message:"Product service unavailable"});}});
app.listen(PORT,()=>console.log(`catalog-service listening on ${PORT}`));
