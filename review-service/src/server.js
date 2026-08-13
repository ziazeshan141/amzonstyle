const express=require("express"); const app=express(); app.use(express.json()); const PORT=process.env.PORT||3011; const reviews=[];
app.get("/health",(_,res)=>res.json({service:"review-service",status:"ok"}));
app.get("/reviews/product/:productId",(req,res)=>res.json(reviews.filter(r=>r.productId===req.params.productId)));
app.post("/reviews",(req,res)=>{const {productId,userId,rating,comment}=req.body;if(!productId||!userId||rating<1||rating>5)return res.status(400).json({message:"productId, userId and rating 1-5 required"});const r={id:`r_${Date.now()}`,productId,userId,rating,comment:comment||"",createdAt:new Date().toISOString()};reviews.push(r);res.status(201).json(r);});
app.listen(PORT,()=>console.log(`review-service listening on ${PORT}`));
