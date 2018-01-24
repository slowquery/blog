"use strict";
const joi = require("joi");
const marked = require("marked");

const index = async(ctx) => {
	const model = require("../../model/post");

	try {
		let posts = await model.getPost();

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
			model.findOne({_id: view_id}, (err, data) => err ? reject(err) : resolve(data));
		});

		post["content"] = marked(post["content"]);
		console.log(post);
		ctx.render("view", {post: post, moment: require("moment")});
		return;
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

module.exports.index = index;
module.exports.view = view;