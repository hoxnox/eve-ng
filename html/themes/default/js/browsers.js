// $(document).ready(function() {

	// Grayscale images on Safari and Opera browsers
	// if(getBrowser()=='opera' || getBrowser()=='safari'){
	// 	return;
	// 	var $images = $(".container img")
	// 	, imageCount = $images.length
	// 	, counter = 0;

	// 	// One instead of on, because it need only fire once per image
	// 	$images.one("load",function(){
	// 		// increment counter every time an image finishes loading
	// 		counter++;
	// 		if (counter == imageCount) {
	// 			// do stuff when all have loaded
	// 			grayscale($('.container img'));
	// 			$(".container img").hover(
	// 				function () {
	// 					grayscale.reset($(this));
	// 				}, 
	// 				function () {
	// 					grayscale($(this));
	// 				}
	// 			);
	// 		}
	// 	}).each(function () {
	// 	if (this.complete) {
	// 		// manually trigger load event in
	// 		// event of a cache pull
	// 			$(this).trigger("load");
	// 		}
	// 	});
	// };
	
	
	// Grayscale images only on browsers IE10+ since they removed support for CSS grayscale filter
	// if (getInternetExplorerVersion() >= 10){
	// 	return;
	// 	$('.container img').each(function(){
	// 		var el = $(this);
	// 		el.css({"position":"absolute"}).wrap("<div class='img_wrapper' style='display: inline-block'>").clone().addClass('img_grayscale').css({"position":"absolute","z-index":"5","opacity":"0"}).insertBefore(el).queue(function(){
	// 			var el = $(this);
	// 			el.parent().css({"width":this.width,"height":this.height});
	// 			el.dequeue();
	// 		});
	// 		this.src = grayscaleIE10(this.src);
	// 	});
		
	// 	// Quick animation on IE10+ 
	// 	$('.container img').hover(
	// 		function () {
	// 			$(this).parent().find('img:first').stop().animate({opacity:1}, 200);
	// 		}, 
	// 		function () {
	// 			$('.img_grayscale').stop().animate({opacity:0}, 200);
	// 		}
	// 	);	
		
	// };
	function grayscaleIE10(src){
		var canvas = document.createElement('canvas');
		var ctx = canvas.getContext('2d');
		var imgObj = new Image();
		imgObj.src = src;
		canvas.width = imgObj.width;
		canvas.height = imgObj.height; 
		ctx.drawImage(imgObj, 0, 0); 
		var imgPixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
		for(var y = 0; y < imgPixels.height; y++){
			for(var x = 0; x < imgPixels.width; x++){
				var i = (y * 4) * imgPixels.width + x * 4;
				var avg = (imgPixels.data[i] + imgPixels.data[i + 1] + imgPixels.data[i + 2]) / 3;
				imgPixels.data[i] = avg; 
				imgPixels.data[i + 1] = avg; 
				imgPixels.data[i + 2] = avg;
			}
		}
		ctx.putImageData(imgPixels, 0, 0, 0, 0, imgPixels.width, imgPixels.height);
		return canvas.toDataURL();
	};
	

	// Detection function to tell what kind of browser is used
	function getBrowser(){
		var userAgent = navigator.userAgent.toLowerCase();
		$.browser = {}
		$.browser.chrome = /chrome/.test(userAgent);
		$.browser.safari= /webkit/.test(userAgent);
		$.browser.opera=/opera/.test(userAgent);
		$.browser.msie=/msie/.test( userAgent ) && !/opera/.test( userAgent );
		$.browser.mozilla= /mozilla/.test( userAgent ) && !/(compatible|webkit)/.test( userAgent ) || /firefox/.test(userAgent);

		if($.browser.chrome) return "chrome";
		if($.browser.mozilla) return "mozilla";
		if($.browser.opera) return "opera";
		if($.browser.safari) return "safari";
		if($.browser.msie) return "ie";
	};
	
	// Since IE11 can not be detected like this because the new user agent on IE11 is trying to hide as Mozilla
	// we detect IE11 with this function
	function getInternetExplorerVersion(){
		var rv = -1;
		if (navigator.appName == 'Microsoft Internet Explorer'){
			var ua = navigator.userAgent;
			var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
			if (re.exec(ua) != null)
			rv = parseFloat( RegExp.$1 );
		}
		else if (navigator.appName == 'Netscape'){
			var ua = navigator.userAgent;
			var re  = new RegExp("Trident/.*rv:([0-9]{1,}[\.0-9]{0,})");
			if (re.exec(ua) != null)
			rv = parseFloat( RegExp.$1 );
		}
		return rv;
	};
// });