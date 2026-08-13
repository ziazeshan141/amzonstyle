const express=require("express"); const {createProxyMiddleware}=require("http-proxy-middleware");
const app=express(); const PORT=process.env.PORT||8080;
const routes=[
 ["/api/auth",process.env.AUTH_SERVICE_URL||"http://auth-service:3001","/auth"],
 ["/api/users",process.env.USER_SERVICE_URL||"http://user-service:3002","/users"],
 ["/api/products",process.env.PRODUCT_SERVICE_URL||"http://product-service:3003","/products"],
 ["/api/catalog",process.env.CATALOG_SERVICE_URL||"http://catalog-service:3004","/catalog"],
 ["/api/search",process.env.SEARCH_SERVICE_URL||"http://search-service:3005","/search"],
 ["/api/carts",process.env.CART_SERVICE_URL||"http://cart-service:3006","/carts"],
 ["/api/orders",process.env.ORDER_SERVICE_URL||"http://order-service:3007","/orders"],
 ["/api/payments",process.env.PAYMENT_SERVICE_URL||"http://payment-service:3008","/payments"],
 ["/api/inventory",process.env.INVENTORY_SERVICE_URL||"http://inventory-service:3009","/inventory"],
 ["/api/shipments",process.env.SHIPPING_SERVICE_URL||"http://shipping-service:3010","/shipments"],
 ["/api/reviews",process.env.REVIEW_SERVICE_URL||"http://review-service:3011","/reviews"],
 ["/api/recommendations",process.env.RECOMMENDATION_SERVICE_URL||"http://recommendation-service:3012","/recommendations"],
 ["/api/notifications",process.env.NOTIFICATION_SERVICE_URL||"http://notification-service:3013","/notifications"]
];
app.get("/health",(_,res)=>res.json({service:"api-gateway",status:"ok",routes:routes.map(r=>r[0])}));
for(const [mount,target,upstream] of routes){app.use(mount,createProxyMiddleware({target,changeOrigin:true,pathRewrite:(path)=>upstream+path}));}
app.listen(PORT,()=>console.log(`api-gateway listening on ${PORT}`));
