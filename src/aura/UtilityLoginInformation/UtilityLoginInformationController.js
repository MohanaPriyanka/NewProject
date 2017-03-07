({
	loadUtilityPopup : function(component, event, helper) {
        jQuery.noConflict();
        dialogCancel = jQuery( "#utility-info-cancel").dialog({
      	autoOpen: false,
        open: function(event, ui) {
        	jQuery(".ui-dialog-titlebar-close", ui.dialog | ui).hide();
            jQuery(".ui-dialog-title").css("color", "#000000");
    	},
      	height: 300,
      	width: 600,
      	modal: true,
      	buttons: {
        	"Procced Without Providing This Information": function() {
          		helper.bypassInfo(component, event);
        	},
            "Cancel": function() {
                jQuery( "#utility-info-cancel" ).dialog( "close" );
            }
      	},
      	close: function() {
        	
        	
      	}
      });
        dialog = jQuery( "#utility-info-form" ).dialog({
      	autoOpen: false,
        open: function(event, ui) {
        	jQuery(".ui-dialog-titlebar-close", ui.dialog | ui).hide();
            jQuery(".ui-dialog-titlebar").append('<img style="width:25px;" src="/resource/QuestionMark" title="By providing your login information you are enabling BlueWave to track your energy consumption monthly. With this we are able to adjust your community subscription every year to make sure you are getting savings that are right for your energy demand. It also unlocks unique features on your portal."/>');
            jQuery(".ui-dialog-titlebar").tooltip();
            jQuery(".ui-dialog-title").css("color", "#000000");
    	},
      	height: 300,
      	width: 600,
      	modal: true,
      	buttons: {
        	"Procced Without Providing This Information": function() {
          		jQuery( "#utility-info-cancel" ).dialog("open");
        	},
            "Submit": function() {
                helper.saveInfo(component, event);
            }
      	},
      	close: function() {
        	
        	
      	}
      });
		var action = component.get("c.needsUtility");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue() === true) {
                    jQuery( "#utility-info-form" ).dialog("open");
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
	}
})