({
    showHelp: function(component, event, helper) {
        $A.util.removeClass(component.find('helpTextBubble'), 'noDisplay'); 
    },                    

    hideHelp: function(component, event, helper) {
        $A.util.addClass(component.find('helpTextBubble'), 'noDisplay'); 
    },                    

})