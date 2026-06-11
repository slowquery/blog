"use strict";
const session = require("koa-generic-session");
const redisStore = require("koa-redis");

module.exports = {
	port: 9000,
	secret_key: "bL0GSeCreTKeY@#$",
	redis_session: session({
		store: redisStore({
			host: "localhost",
			port: 6379,
			pass: "pingumaster"
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
	mongoURI: "mongodb://antiweb:pingumaster@localhost:27017/blog",
	path: __dirname
}
	//mongoURI: "mongodb://antiweb:pingumaster!%23@mongo-master:27017/blog",
