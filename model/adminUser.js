"use strict";
const mongoose = require("mongoose");
const {Schema} = require("mongoose");
const config = require("../config");

const adminUser = new Schema({
	user_id: {
		type: String,
		required: true
	},
	user_pass: {
		type: String,
		required: true	
	}
});

adminUser.statics = {
	login(obj) {
		return new Promise((resolve, reject) => {
			this.count(obj, (err, count) => err ? reject(err) : resolve(count));
		});
	}
}

module.exports = mongoose.model("adminUser", adminUser);