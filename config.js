"use strict";

const path = require("path");
const session = require("koa-generic-session");
const redisStore = require("koa-redis");

const envInt = (key, fallback) => {
  const raw = process.env[key];
  if (raw === undefined || raw === "") {
    return fallback;
  }
  return parseInt(raw, 10);
};

const buildMongoUri = () => {
  if (process.env.MONGO_URI) {
    return process.env.MONGO_URI;
  }
  const user = process.env.MONGODB_USER;
  const password = process.env.MONGODB_PASSWORD;
  if (user && password) {
    const host = process.env.MONGODB_HOST || "localhost";
    const port = process.env.MONGODB_PORT || "27017";
    const db = process.env.MONGODB_DB || "blog";
    return `mongodb://${user}:${encodeURIComponent(password)}@${host}:${port}/${db}`;
  }
  return "mongodb://antiweb:pingumaster@localhost:27017/blog";
};

const port = envInt("PORT", 9000);
const secretKey = process.env.SECRET_KEY || "bL0GSeCreTKeY@#$";
const redisHost = process.env.REDIS_HOST || "localhost";
const redisPort = envInt("REDIS_PORT", 6379);
const redisPassword = process.env.REDIS_PASSWORD || "pingumaster";
const appPath = process.env.APP_PATH || __dirname;
const uploadPath = process.env.UPLOAD_PATH || path.join(appPath, "upload");

module.exports = {
  port,
  secret_key: secretKey,
  path: appPath,
  uploadPath,
  mongoURI: buildMongoUri(),
  redis_session: session({
    store: redisStore({
      host: redisHost,
      port: redisPort,
      pass: redisPassword,
    }),
    cookie: {
      path: "/",
      httpOnly: true,
      maxAge: 1000 * 3600 * 24,
      overwrite: true,
      signed: false,
    },
    key: "PHPSESSID",
    prefix: "blog:",
  }),
};
