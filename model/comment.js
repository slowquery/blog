"use strict";
const mongoose = require("mongoose");
const {Schema} = require("mongoose");
const config = require("../config");

const comment = new Schema({
	post: {
		type: Schema.Types.ObjectId,
		ref: "post",
		required: true
	},
	user_name: {
		type: String,
		required: true
	},
	content: {
		type: String,
		required: true	
	}
});

comment.statics = {
	getPost(seq) {
		return new Promise((resolve, reject) => {
			seq ?
				this.find({_id: {$lt: seq}, type: {$ne: "save"}}, {type: 0, tag: 0, __v: 0, content: 0}).sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post)) :
				this.find().sort({_id: -1}).limit(6).exec((err, post) => err ? reject(err) : resolve(post));
		});
	},
}

module.exports = mongoose.model("comment", comment);