({
    startSpinner : function(component, name) {
        var spinner = component.find(name);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },

    stopSpinner : function(component, spinnerName) {
        var spinner = component.find(spinnerName);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    },

    setWindowToBWSL : function(component) {
        component.set("v.productProgram","bwsl");           
        $A.util.removeClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
        $A.util.addClass(component.find('bwslEmailInput'), 'nimbusBackground');      
    },    

    setWindowToMSLP : function(component) {
        component.set("v.productProgram","mslp");                                        
        $A.util.removeClass(component.find('bwslEmailInput'), 'nimbusBackground');        
        $A.util.addClass(component.find('mslpEmailInput'), 'nimbusBackground');      
    },        
})