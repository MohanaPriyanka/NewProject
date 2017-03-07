({
	doInit : function(component, event, helper) {
        component.set("v.editmode", false);
		helper.initMore(component, event, helper);
	},
    edit : function(component, event, helper) {
        component.set("v.editmode", true);
    },
    saveedit : function(component, event, helper) {
        var action = component.get("c.setInfo"); 
 
        action.setParams({
            email: component.find("emailedit").get("v.value"),
            phone: component.find("phoneedit").get("v.value"),
            username: component.find("usernameedit").get("v.value"),
            password: component.find("passwordedit").get("v.value")
        });
 
        action.setCallback(this, function(a) {
            if(a.getReturnValue() != 'success') {
                alert(a.getReturnValue());
            }
            else {
                component.set("v.editmode", false);
                this.initMore(component, event, helper);
            }
        });
            
        $A.run(function() {
            $A.enqueueAction(action); 
        });
    },
    

    save : function(component, event, helper) {
        var fileInput = component.find("file").getElement();
    	var file = fileInput.files[0];
   
        if (file.size >  750000) {
            alert('File size cannot exceed ' + 750000 + ' bytes.\n' +
    	          'Selected file size: ' + file.size);
    	    return;
        }
    
        var fr = new FileReader();
        
        
       	fr.onload = function() {
            var fileContents = fr.result;
    	    var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
 
            fileContents = fileContents.substring(dataStart);
        
    	    helper.upload(component, file, fileContents);
        };
 
        fr.readAsDataURL(file);
    },
    loadChart : function(component, event, helper) {
        helper.loadChart(component, helper);
    }
})