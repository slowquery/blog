const Koa = require("koa");
const Router = require("koa-router");
const Pug = require("koa-pug");
const bodyParser = require("koa-bodyparser");
const json = require("koa-json");
const serve = require("koa-static");
const mount = require("koa-mount");
const config = require("./config");
const db = require("./database");

const app = new Koa();

// pug viewer setting
new Pug({
	viewPath: "./views",
	pretty: true,
	app: app
});

// session redis setting
app.keys = ["secret", config.secret_key];
app.use(config.redis_session);

db.connect();

app.use(bodyParser());
app.use(json());
// response header timer setting
app.use(async(ctx, next) => {
	const start = Date.now();
	await next();
	const ms = Date.now() - start;
	ctx.set("X-Response-Time", `${ms}ms`);
});

// public directory setting
app.use(serve(`${__dirname}/public`));
app.use(mount("/image", serve(`${__dirname}/upload`)));

// debugger setting
app.use(async(ctx, next) => {
	const start = Date.now();
	await next();
	const ms = Date.now() - start;
	console.log(`${ctx.method} ${ctx.url} - ${ms}`);
});

// router setting
app.use(require("./routes").routes());

// server open
app.listen(config.port, () => {
	console.log(`SERVER ${config.port} LISTEN!`);
});