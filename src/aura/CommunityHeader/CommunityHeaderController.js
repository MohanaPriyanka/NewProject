({
	doneRendering : function(component, event, helper) {
        //alert('done');
		//componentHandler.upgradeAllRegistered();
		
        //alert('done2');
        if($('.mdl-layout__header').length !== 0 && !component.get("v.mdlLoaded"))  {
            //alert($('.mdl-layout__header').length );
        	//$.getScript("//storage.googleapis.com/code.getmdl.io/1.0.4/material.min.js");
            component.set("v.mdlLoaded", true);
        }
	}
    
})