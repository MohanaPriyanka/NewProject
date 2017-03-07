({
	saveInfo : function(component, event) {
        if(jQuery('#create').prop('checked')) {
            var action2 = component.get("c.setCreateAccount");
    		action2.setCallback(this,function(resp){
            	if(resp.getState() == 'SUCCESS') {
            	}
            	else {
                	$A.log("Errors", resp.getError());
            	}
    		});
            $A.run(function() {
    			$A.enqueueAction(action2);
            });
        }
        var action3 = component.get("c.setInfo"); 
 
        action3.setParams({
            username: jQuery('#username').val(),
            password: jQuery('#password').val()
        }); 
        action3.setCallback(this, function(resp) {
            if(resp.getState() == 'SUCCESS') {
                jQuery( "#utility-info-form" ).dialog( "close" );   
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.run(function() {
        	$A.enqueueAction(action3);
        });
	},
    bypassInfo : function(component, event) {
        var action4 = component.get("c.setNoAdjustment");
    	action4.setCallback(this,function(resp){
           	if(resp.getState() == 'SUCCESS') {
                jQuery( "#utility-info-cancel" ).dialog( "close" );   
                jQuery( "#utility-info-form" ).dialog( "close" );
           	}
           	else {
               	$A.log("Errors", resp.getError());
           	}
    	});
        $A.run(function() {
            $A.enqueueAction(action4);
        });
    }
})