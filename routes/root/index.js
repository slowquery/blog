"use strict";
const Router = require("koa-router");
const router = new Router();
const root_router = require("./root_router");

router.get("/view/:view_id/", root_router.view);
router.get("/", root_router.index);

module.exports = router;