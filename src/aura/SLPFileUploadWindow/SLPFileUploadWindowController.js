({    
    filePreview : function(component, event, helper) {
    	var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        var fr = new FileReader();
        fr.readAsDataURL(file);
        component.set("v.buttonText", file.name);
        component.set("v.fileReader", fr);
		helper.greyOutUpload(component);
    },
   
    fileUpload : function(component, event, helper) {
        var errors = "";
        if (component.get("v.dateLabel") != 'hide') {
            var dateValue =  component.get("v.dateValue");
            errors = helper.checkDateField(component, helper, dateValue);   
        	if (errors != "") {
                component.set("v.errorText" , errors);
                $A.util.removeClass(component.find("errorTextLine"), 'noDisplay'); 
                return;
        	}
        }
        helper.removeErrorMessaging(component);
        var fileType = component.get("v.fileName");
        var parentId = component.get("v.fileParentId"); 
        helper.saveFile(component, event, fileType, parentId);
    },
    
    closeWindow : function(component, event, helper) {
        helper.closeWindow(component); 
    },
    
    doneButton : function(component, event, helper) {
        helper.firePartnerTaskRefresh(component, helper);
        helper.closeWindow(component);
    },
    
})