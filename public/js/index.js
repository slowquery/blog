$(document).ready(function(){
	var controller = new ScrollMagic.Controller();
	var scene = new ScrollMagic.Scene({triggerElement: ".loading", triggerHook: "onEnter"})
		.addTo(controller)
		.on("enter", function (e) {
			setTimeout(Scroll, 0);
		});
	function Scroll() {
		$(".loading").show();
		$.ajax({
			url: "/api/post" + "?token=" + $(".post-cardlist.col-md-4").last().attr("data-id"),
			type: "GET"
		})
		.done(function(data) {
			if(data["code"] === 200 && data["posts"] === null) {
				$(".loading").hide();
			}
			else if(data["code"] === 200) {
				var post = "";
				for(var i = 0; i < data["posts"].length; i++) {
					var style = data["posts"][i]["type"] === "bgcolor" ? "background-color: " + data["posts"][i]["bgcolor"] : "background-image: url(/image/" + data["posts"][i]["thumbnail"] + ")";
					post += "<div class='post-cardlist col-md-4' data-id='" + data["posts"][i]["_id"] + "'><div class='card'><div class='card card-inverse'><a href='/view/" + data["posts"][i]["_id"] + "/'><div class='post-card' style='" + style + "'></div><div class='card-img-overlay'><span>" + data["posts"][i]["time"] + "</span><div class='post-content'><div class='post-title'>" + data["posts"][i]["title"] + "</div><div class='post-description'>" + data["posts"][i]["description"] + "</div></div></div></a></div></div></div>";
				}

				$(".post.mt-4.mb-4 .row").append(post);
				$(".loading").hide();
				$(".loading").appendTo(".post.mt-4.mb-4 .row");
				if(data["posts"].length === 6)
					$(".loading").show();
				scene.update();
			}
			else {
				alert(data["code"]);
			}
		});
	}
});