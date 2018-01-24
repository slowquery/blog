"use strict";
const session = require("koa-generic-session");
const redisStore = require("koa-redis");

module.exports = {
	port: 80,
	secret_key: "SeCreTKeY!@",
	redis_session: session({
		store: redisStore({
			host: "127.0.0.1",
			port: 6379
		}),
		cookie: {
			path: "/",
			httpOnly: true,
			maxAge: 1000 * 3600 * 24,
			overwrite: true,
			signed: false
		},
		key: "PHPSESSID",
		prefix: "blog:sess:"
	}),
	mongoURI: "mongodb://127.0.0.1/blog",
	path: __dirname
}