"use strict";
const mongoose = require("mongoose");
const config = require("../config");

mongoose.Promise = global.Promise;

// mongo 연결시 autoindex: false 로 해줘야함 production일 때
module.exports = {
	connect: () => {
		return mongoose.connect(config.mongoURI, {useMongoClient: true})
			.then(() => console.log("MongoDB Connection Success!"))
			.catch((err) => console.error(err));
	},
	disconnect: () => {
		mongoose.connection.close();
	}
}