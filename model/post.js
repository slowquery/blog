"use strict";
const mongoose = require("mongoose");
const {Schema} = require("mongoose");
const config = require("../config");

const post = new Schema({
	title: {
		type: String,
		required: true
	},
	description: {
		type: String,
		required: true	
	},
	password: {
		type: String,
		required: false
	},
	tag: {
		type: Array,
		required: true
	},
	bgcolor: {
		type: String,
		required: false
	},
	thumbnail: {
		type: String,
		required: false
	},
	content: {
		type: String,
		required: true
	},
	type: {
		type: String,
		required: true
	},
	time: {
		type: Date,
		default: Date.now,
		required: true
	},
	view: {
		type: Number,
		default: 0,
		required: true
	}
});

post.statics = {
	getPost(seq) {
		return new Promise((resolve, reject) => {
			seq ?
				this.find({_id: {$lt: seq}, type: {$ne: "save"}}, {type: 0, tag: 0, __v: 0, content: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post)) :
				this.find().sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post));
		});
	}
}

module.exports = mongoose.model("post", post);