"use strict";
const Router = require("koa-router");
const router = new Router();
const api = require("./api");

router.post("/auth", api.auth);
router.get("/post", api.post);
router.get("/", api.index);

module.exports = router;