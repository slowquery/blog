"use strict";
const path = require("path");
const mv = require("mv");
const joi = require("joi");
const moment = require("moment");
const util = require("../../lib/util");
const config = require("../../config");

const index = async(ctx) => {
	let {admin} = ctx.session;

	if(!admin) {
		ctx.render("admin/login");
		return;
	}

	ctx.redirect("/admin/main");
	return;
}

const main_view = async(ctx) => {
	const model = require("../../model/post");

	try {
		let posts = await new Promise((resolve, reject) => {
			model.find({}).sort({_id: -1}).exec((err, data) => err ? reject(err) : resolve(data));
		});

		ctx.render("admin/main", {admin: true, post: posts});
		return;
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

const write = async(ctx) => {
	const model = require("../../model/post");
	const {id, mode} = ctx.query;

	try {
		if(id && mode) {
			let post_data = await new Promise((resolve, reject) => {
				model.findOne({_id: id}, (err, data) => err ? reject(err) : resolve(data));
			});

			if(!post_data) {
				ctx.status = 400;
				ctx.body = {
					code: 401
				};
				return;
			}
			post_data["content"] = new Buffer(post_data["content"]).toString("base64");
			ctx.render("admin/write", {admin: true, mode: "edit", post: post_data, id: id});
			return;
		}
		else {
			ctx.render("admin/write", {admin: true, mode: "write"});
			return;	
		}
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

const admin_auth = async(ctx, next) => {
	let {admin} = ctx.session;
	
	if(!admin) {
		ctx.redirect("/");
		return;
	}

	await next();
}

const login = async(ctx) => {
	const {user_id, user_pass} = ctx.request.body;
	const model = require("../../model/adminUser");

	const joi_schema = joi.object({
		user_id: joi.string().required(),
		user_pass: joi.string().required()
	});
	
	if(joi.validate(ctx.request.body, joi_schema).error) {
		ctx.status = 400;
		ctx.body = {
			code: 401
		}
		return;
	}

	try {
		let admin = new model({
			user_id: user_id,
			user_pass: util.sha512Hash(user_pass)
		});

		let count = await model.count();

		if(count === 1) {
			let login = await model.login({
				user_id: user_id,
				user_pass: util.sha512Hash(user_pass)
			});

			if(login === 1) {
				ctx.session = {
					admin: true
				};
				ctx.redirect("/admin");
				return;
			}
			else {
				ctx.redirect("/");
				return;
			}

		}
		else if(count > 1){
			ctx.status = 400;
			ctx.body = {
				code: 400
			}

			return;
		}
		else {
			let admin_create = await new Promise((resolve, reject) => {
				admin.save((err, data) => err ? reject(err) : resolve(data));
			});

			if(!admin_create) {
				ctx.status = 400;
				ctx.body = {
					code: 602
				}
				return;
			}

			ctx.session = {
				admin: true
			};

			ctx.redirect("/admin");
			return;
		}
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const upload = async(ctx) => {
	try {
		const filename = `${moment(new Date()).format("YYYY-MM-DD_HH-mm-ss_SSS")}${path.extname(ctx.request.body.files.file.name)}`;
		let filemove = await new Promise((resolve, reject) => {
			mv(`${ctx.request.body.files.file.path}`, `${config.path}/public/image/${filename}`, err => !err ? resolve(true) : reject(err));
		});

		if(!filemove) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		ctx.status = 200;
		ctx.body = {
			code: 200,
			filename: filename
		};
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const post = async(ctx, next) => {
	let {title, description, password, tag, bgcolor, thumbnail, content, type, id} = ctx.request.body;
	const model = require("../../model/post");

	tag = tag.toString().split(",").map(data => data.trim());
	ctx.request.body.tag = tag;

	const joi_schema = joi.object({
		title: joi.string().required(),
		description: joi.string().required(),
		password: joi.string().empty(""),
		tag: joi.array().items(joi.string()),
		bgcolor: joi.string().empty(""),
		thumbnail: joi.string().empty(""),
		content: joi.string().required(),
		type: joi.string().required(),
		id: joi.string()
	}).without("bgcolor", "thumbnail");

	if(joi.validate(ctx.request.body, joi_schema).error) {
		ctx.status = 400;
		ctx.body = {
			code: 401
		}
		return;
	}

	try {
		switch(password.length) {
			case 0:
				password = null;
				break; 
			case 128:
				password = password;
				break;
			default:
				password = util.sha512Hash(password);
				break;
		}

		let post = new model({
			title: title,
			description: description,
			password: password,
			tag: tag,
			bgcolor: bgcolor ? bgcolor : null,
			thumbnail: thumbnail ? thumbnail : null,
			content: content,
			type: type
		});

		switch(type) {
			case "write":
				const write_mode = async() => {
					let posting = await new Promise((resolve, reject) => {
						post.save((err, data) => err ? reject(err) : resolve(data));
					});

					if(!posting) {
						ctx.status = 400;
						ctx.body = {
							code: 602
						}
						return;
					}
				}
				write_mode();
				break;
			case "save":
				const save_mode = async() => {
					let issave = await model.count();
					
					if(issave) {
						let save_data = post.toObject();
						delete save_data["_id"];

						let post_update = await new Promise((resolve, reject) => {
							model.update({type: type}, save_data, (err, data) => err ? reject(err) : resolve(data));
						});

						if(!post_update) {
							ctx.status = 400;
							ctx.body = {
								code: 602
							}
							return;
						}
					}
					else {
						let posting = await new Promise((resolve, reject) => {
							post.save((err, data) => err ? reject(err) : resolve(data));
						});

						if(!posting) {
							ctx.status = 400;
							ctx.body = {
								code: 602
							}
							return;
						}
					}
				}
				save_mode();
				break;
			case "edit":
				const edit_mode = async() => {
					if(!id) {
						ctx.status = 400;
						ctx.body = {
							code: 600
						}
						return;
					}
					let save_data = post.toObject();
					delete save_data["_id"];

					let post_update = await new Promise((resolve, reject) => {
						model.update({_id: id}, save_data, (err, data) => err ? reject(err) : resolve(data));
					});

					if(!post_update) {
						ctx.status = 400;
						ctx.body = {
							code: 602
						}
						return;
					}
				}
				edit_mode();
				break;
		}

		ctx.status = 200;
		ctx.body = {
			code: 200
		};
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const save_load = async(ctx) => {
	const model = require("../../model/post");

	try {
		let post_obj = await new Promise((resolve, reject) => {
			model.findOne({type: "save"}, (err, data) => err ? reject(err) : resolve(data));
		});

		if(!post_obj) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		ctx.status = 200;
		ctx.body = {
			code: 200,
			data: post_obj
		};
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const post_delete = async(ctx) => {
	const model = require("../../model/post");
	let {id} = ctx.query;

	if(!id) {
		ctx.status = 400;
		ctx.body = {
			code: 600
		}
		return;
	}

	try {
		let post_del = await new Promise((resolve, reject) => {
			model.remove({_id: id}, (err, data) => err ? reject(err) : resolve(data));
		});

		if(!post_del) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		ctx.redirect("/admin/main");
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const comment = async(ctx) => {
	const model = require("../../model/comment");

	try {
		let comments = await new Promise((resolve, reject) => {
			model.find({}).sort({_id: -1}).exec((err, data) => err ? reject(err) : resolve(data));
		});

		ctx.render("admin/comment", {admin: true, comment: comments});
		return;
	} catch(err) {
		console.error(err);
		ctx.redirect("/");
		return;
	}
}

const comment_delete = async(ctx) => {
	const model = require("../../model/comment");
	const postModel = require("../../model/post");
	let {id} = ctx.query;

	if(!id) {
		ctx.status = 400;
		ctx.body = {
			code: 600
		}
		return;
	}

	try {
		let comment_info = await new Promise((resolve, reject) => {
			model.findOne({_id: id}, (err, data) => err ? reject(err) : resolve(data));
		});

		if(!comment_info) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		let post_comment_del = await postModel.pullComment({comment: id, post: comment_info.post});

		if(!post_comment_del) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		let comment_del = await new Promise((resolve, reject) => {
			model.remove({_id: id}, (err, data) => err ? reject(err) : resolve(data));
		});

		if(!comment_del) {
			ctx.status = 400;
			ctx.body = {
				code: 401
			}
			return;
		}

		ctx.redirect("/admin/commgt");
		return;
	} catch(err) {
		console.error(err);
		ctx.status = 400;
		ctx.body = {
			code: 601
		}
		return;
	}
}

const logout = async(ctx) => {
	let {admin} = ctx.session;
	
	if(!admin) {
		ctx.redirect("/");
		return;
	}

	ctx.session = null;
	ctx.redirect("/");
	return;
}

module.exports.index = index;
module.exports.main_view = main_view;
module.exports.write = write;
module.exports.admin_auth = admin_auth;
module.exports.login = login;
module.exports.upload = upload;
module.exports.post = post;
module.exports.save_load = save_load;
module.exports.post_delete = post_delete;
module.exports.comment = comment;
module.exports.comment_delete = comment_delete;
module.exports.logout = logout;