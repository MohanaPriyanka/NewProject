({
    loadBlog: function(cmp, event, helper) {
        helper.getBgs(cmp, event, helper);
	},
    
    setLinks: function(cmp, event, helper) {
		$(".inlineBlog").colorbox({inline:true, width:"90%"});
    }
})