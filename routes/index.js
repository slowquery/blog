"use strict";
const Router = require("koa-router");
const router = new Router();

router.use("/api", require("./api").routes());
router.use("/admin", require("./admin").routes());
router.use(require("./root").routes());

module.exports = router;