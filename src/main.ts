import express from "express";
import { createProxyMiddleware, Options as ProxyOptions } from "http-proxy-middleware";

var app = express();
app.get("/api/hey", (_, res) => {
   res.send("Hey");
});

registerFrontendProxy(app); // NOTE: Order matters, keep it last just before `listen`
app.listen(3001);

function registerFrontendProxy(_app: express.Express) {
  const frontendProxyOptions: ProxyOptions = {
    target: process.env.FRONTEND_PROXY_TARGET, // target host
    changeOrigin: true, // needed for virtual hosted sites
    pathRewrite: {
      [process.env.FRONTEND_PROXY_REWRITE as string]: "/"
    }
  };
  const frontendProxy = createProxyMiddleware(frontendProxyOptions);
  _app.use("*", frontendProxy);
}

