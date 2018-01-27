"use strict";
const session = require("koa-generic-session");
const redisStore = require("koa-redis");

module.exports = {
	port: 40000,
	secret_key: "bL0GSeCreTKeY@#$",
	redis_session: session({
		store: redisStore({
			host: "127.0.0.1",
			port: 6379,
			password: "pingumaster@#"
		}),
		cookie: {
			path: "/",
			httpOnly: true,
			maxAge: 1000 * 3600 * 24,
			overwrite: true,
			signed: false
		},
		key: "PHPSESSID",
		prefix: "blog:"
	}),
	mongoURI: "mongodb://antiweb%3Apingumaster!%23@127.0.0.1:27017/blog",
	path: __dirname
}
