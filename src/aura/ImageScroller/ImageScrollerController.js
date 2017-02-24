({
	
    afterScriptsLoaded : function(cmp, event, helper) {
        helper.getImages(cmp, event, helper);
    },
    
    afterRendering : function(cmp, event, helper) {
      		cmp.set("v.sliderLoaded", true);
            $(".flexslider").flexslider({animation:"slide"});
        	$(".inlineSlider").colorbox({inline:true, width:"90%"});
    }
})