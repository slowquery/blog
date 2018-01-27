"use strict";
const Router = require("koa-router");
const router = new Router();
const path = require("path");
const koaBody = require("koa-body")({multipart: true});
const admin = require("./admin");

router.get("/comment", admin.admin_auth, admin.comment_delete); // delete...
router.get("/commgt", admin.admin_auth, admin.comment);
router.get("/logout", admin.admin_auth, admin.logout);
router.get("/post", admin.admin_auth, admin.post_delete); // delete...
router.get("/save", admin.admin_auth, admin.save_load);
router.post("/post", admin.admin_auth, admin.post);
router.post("/upload", admin.admin_auth, koaBody, admin.upload);
router.get("/write", admin.admin_auth, admin.write);
router.get("/main", admin.admin_auth, admin.main_view);
router.post("/login", admin.login);
router.get("/", admin.index);

module.exports = router;