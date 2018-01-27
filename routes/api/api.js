"use strict";
const joi = require("joi");
const _ = require("lodash");
const moment = require("moment");
const util = require("../../lib/util");

const index = async(ctx) => {
	ctx.body = "API SERVER";
	return;
}

const post = async(ctx) => {
	const model = require("../../model/post");
	let {token, search} = ctx.query;

	const joi_schema = joi.object({
		token: joi.string().alphanum().min(24).max(24).required(),
		search: joi.string()
	});
	
	if(joi.validate(ctx.query, joi_schema).error) {
		ctx.status = 401;
		ctx.body = {
			code: 401,
			body: "invalid parameter"
		};
		return;
	}

	try {
		let post = search ? await model.getPostSearch(search, token) : await model.getPost(token);

		if(!post) {
			ctx.status = 404;
			ctx.body = {
				code: 404,
				body: "data not found"
			};
			return;
		}

		let ret_model = [];
		for(let data of post) {
			ret_model.push({
				type: data["bgcolor"] !== null ? "bgcolor" : "thumbnail",
				_id: data["_id"],
				title: data["title"],
				description: data["description"],
				password: data["password"] ?
					data["password"] = Boolean(true) :
					data["password"] = Boolean(false),
				bgcolor: data["bgcolor"],
				thumbnail: data["thumbnail"],
				time: moment(new Date(data["time"])).format("YYYY.MM.DD")
			});
		}

		ctx.body = {
			code: 200,
			posts: ret_model.length ? ret_model : null
		}
		return;
	} catch(err) {
		ctx.status = 500;
		ctx.body = {
			code: 400,
			body: "error"
		};
		return;
	}
}

const auth = async(ctx) => {
	const model = require("../../model/post");
	let {password, key} = ctx.request.body;

	const joi_schema = joi.object({
		password: joi.string().required(),
		key: joi.string().alphanum().min(24).max(24).required()
	});
	
	if(joi.validate(ctx.request.body, joi_schema).error) {
		ctx.status = 401;
		ctx.body = {
			code: 401,
			body: "invalid parameter"
		};
		return;
	}

	try {
		let post = await new Promise((resolve, reject) => {
			model.findOne({_id: key, password: util.sha512Hash(password)}, (err, data) => err ? reject(err) : resolve(data));
		});

		if(!post) {
			ctx.status = 404;
			ctx.body = {
				code: 404,
				body: "data not found"
			};
			return;
		}

		ctx.session.auth = key;
		ctx.body = {
			code: 200
		}
		return;
	} catch(err) {
		ctx.status = 500;
		ctx.body = {
			code: 400,
			body: "error"
		};
		return;
	}
}

const comment = async(ctx) => {
	const xss = require("xss");
	const model = require("../../model/comment");
	const postModel = require("../../model/post");
	let {post, user_name, content} = ctx.request.body;

	const joi_schema = joi.object({
		post: joi.string().alphanum().min(24).max(24).required(),
		user_name: joi.string().required(),
		content: joi.string().required()
	});
	
	if(joi.validate(ctx.request.body, joi_schema).error) {
		ctx.status = 401;
		ctx.body = {
			code: 401,
			body: "invalid parameter"
		};
		return;
	}

	try {
		let comment = new model({
			post: post,
			user_name: xss(user_name),
			content: xss(content)
		});

		let post_push = await postModel.pushComment({post: post, comment: comment._id});

		if(!post_push) {
			ctx.status = 400;
			ctx.body = {
				code: 602
			}
			return;
		}

		let comment_create = await new Promise((resolve, reject) => {
			comment.save((err, data) => err ? reject(err) : resolve(data));
		});

		if(!comment_create) {
			ctx.status = 400;
			ctx.body = {
				code: 602
			}
			return;
		}

		ctx.status = 200;
		ctx.body = {
			code: 200,
			data: {
				user_name: xss(user_name),
				content: xss(content)
			}
		};
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 500;
		ctx.body = {
			code: 400,
			body: "error"
		};
		return;
	}
}

module.exports.index = index;
module.exports.post = post;
module.exports.auth = auth;
module.exports.comment = comment;
