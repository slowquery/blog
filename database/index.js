"use strict";
const mongoose = require("mongoose");
const config = require("../config");

mongoose.Promise = global.Promise;

// mongo 연결시 autoindex: false 로 해줘야함 production일 때
module.exports = {
	connect: () => {
		//return mongoose.connect(config.mongoURI, {uri_decode_auth: true, useMongoClient: true})
		return mongoose.connect(config.mongoURI)
			.then(() => console.log("MongoDB Connection Success!"))
			.catch((err) => console.error(`Log: ${err}`));
	},
	disconnect: () => {
		mongoose.connection.close();
	}
}
