"use strict";
const joi = require("joi");
const marked = require("marked");

const index = async(ctx, next) => {
	const model = require("../../model/post");
	const {search} = ctx.query;

	const joi_schema = joi.object({
		search: joi.string()
	});

	if(joi.validate(ctx.query, joi_schema).error) {
		/*
		ctx.status = 401;
		ctx.body = {
			code: 401,
			body: "invalid parameter"
		};
		*/
		ctx.redirect("/");
		return;
	}

	try {
		if(ctx.path !== "/") {
			ctx.redirect("/");
		}

		let posts = search ? await model.getPostSearch(search) : await model.getPost();

		ctx.render("index", {post: posts, moment: require("moment")});
		return;
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

const view = async(ctx) => {
	const model = require("../../model/post");
	const commentModel = require("../../model/comment");
	const html = require("htmldom");

	let {view_id} = ctx.params;

	const joi_schema = joi.object({
		view_id: joi.string().alphanum().min(24).max(24).required()
	});

	delete ctx.params["0"];
	
	if(joi.validate(ctx.params, joi_schema).error) {
		ctx.status = 401;
		ctx.body = {
			code: 401,
			body: "invalid parameter"
		};
		return;
	}

	try {
		let post = await new Promise((resolve, reject) => {
			model.findOne({_id: view_id}).populate("comment").exec((err, data) => err ? reject(err) : resolve(data));
		});

		if(!post) {
			ctx.redirect("/");
			return;
		}

		if(post["password"] === null || ctx.session.auth === view_id) {
			let dom = new html(marked(post["content"]));
			let $ = dom.$;

			$("img").addClass("magniflier");
			$("a").attr("target", "_blank");

			post["content"] = dom.html();

			//ctx.session.auth ?
			//	ctx.session = null : null;

			!ctx.session.view ? ctx.session.view = [] : null;

			if(ctx.session.view.indexOf(view_id) === -1) {
				let view_update = await model.addView(view_id);
				ctx.session.view.push(view_id);
			}

			ctx.render("view", {post: post, moment: require("moment")});
			return;
		}
		else {
			ctx.render("view", {id: view_id, title: post["title"]});
			return;
		}
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

module.exports.index = index;
module.exports.view = view;
