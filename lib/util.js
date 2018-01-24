"use strict";
const config = require("../config");
const crypto = require("crypto");

const sha512Hash = (text) => {
	return crypto.createHmac("sha512", config.secret_key).update(text).digest("hex");
}

module.exports.sha512Hash = sha512Hash;