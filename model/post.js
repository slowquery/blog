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
	},
	comment: [
		{
			type: mongoose.Schema.Types.ObjectId, 
			ref: "comment"
		}
	]
});

post.statics = {
	getPost(seq) {
		return new Promise((resolve, reject) => {
			seq ?
				this.find({_id: {$lt: seq}, type: {$ne: "save"}}, {type: 0, tag: 0, __v: 0, content: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post)) :
				this.find({type: {$ne: "save"}}, {type: 0, tag: 0, __v: 0, content: 0, comment: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post));
		});
	},
	getPostSearch(search, seq) {
		return new Promise((resolve, reject) => {
			seq ?
				this.find({type: {$ne: "save"}, _id: {$ne:seq}, $or:[{title:{$regex: search}},{tag:{$regex: search}}]}, {type: 0, tag: 0, __v: 0, content: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post)) :
				this.find({type:{$ne: "save"}, $or:[{title:{$regex: search}},{tag:{$regex: search}}]},{type: 0, tag: 0, __v: 0, content: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post));
		});
	},
	pushComment(obj) {
		return new Promise((resolve, reject) => {
			this.update({_id: obj.post}, {$push: {comment: obj.comment}}, (err, data) => err ? reject(err) : resolve(data));
		});
	},
	pullComment(obj) {
		return new Promise((resolve, reject) => {
			this.update({_id: obj.post}, {$pull: {comment: obj.comment}}, (err, data) => err ? reject(err) : resolve(data));
		});
	},
	addView(id) {
		return new Promise((resolve, reject) => {
			this.update({_id: id}, {$inc: {view: 1}}, (err, data) => err ? reject(err) : resolve(data));
		});
	}
}

module.exports = mongoose.model("post", post);
