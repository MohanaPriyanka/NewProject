({    
    doInit : function(component, event, helper) {
        var actionGetDocsAvailable = component.get("c.possibleFileTypes");
        actionGetDocsAvailable.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.fileTypes", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionGetDocsAvailable);
    },
        
    filePreview : function(component, event, helper) {
        var fileInput = component.find("file").getElement();
        var numberOfFiles = fileInput.files.length; 
        var MAXFILE_SIZE = 4500000;
        var fileStep;
        helper.removeErrorMessaging(component);
        helper.greyOutSelection(component);
        console.log(fileInput);
		for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
            var file = fileInput.files[fileStep];
        	var fr = new FileReader();
        	fr.readAsDataURL(file);
            if (file === undefined) {
                component.set("v.errorText", 'Please Select a File');
                helper.addErrorMessaging(component);
                return;
            }
            else if (file.size > MAXFILE_SIZE) {
                component.set("v.errorText", 'File size cannot exceed ' + MAXFILE_SIZE + ' bytes.\n' +
                  'Selected file size: ' + file.size);
                helper.addErrorMessaging(component);
                return;
            }           
        	component.get("v.fileReader").push(fr);
            component.get("v.fileList").push(file);
            if(component.get("v.fileList").length == 4){
               $A.util.addClass(component.find("addButton"), 'noDisplay'); 
            }
            var newFileList = component.get("v.fileList");
        	component.set("v.fileList", newFileList);
        	var numberOpen = component.get("v.fileList").length;
        	if (numberOpen === 4) {
            	$A.util.addClass(component.find("fileUploadBox"), 'noDisplay'); 
                return;
        	} 
        } 
    },
    
    removeFile : function(component, event, helper) {
       	var buttonClicked = event.getSource().get("v.name");
        var newList= component.get("v.fileList");
        var newListReader = component.get("v.fileReader");
        var numberOfFiles = newList.length; 
        var fileStep;
        for (fileStep = 0; fileStep < numberOfFiles; fileStep++) {
            var file = newList[fileStep];
            if (file.name === buttonClicked) {
                var toDeleteLocation = fileStep;
                $A.util.removeClass(component.find("fileUploadBox"), 'noDisplay'); 
            } 
        }
        newList.splice(toDeleteLocation, 1);
        newListReader.splice(toDeleteLocation, 1);
        component.set("v.fileList", newList);
        component.set("v.fileReader", newListReader);
    },

    fileUpload : function(component, event, helper) {
        var errors = "";
        if (component.get("v.dateLabel") != 'hide' && component.get("v.dateLabel") != 'hideAndFileOption') {
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
    
    addFileUpload : function(component, event, helper) {
        var NewButton = component.get("v.buttonText");
        component.set("v.buttonText", NewButton);
        component.set("v.mostRecent", "Select File(s)");
        helper.unGreyOutUpload(component);
        var numberOpen = component.get("v.fileList").length;
        if (numberOpen === 4) {
            $A.util.addClass(component.find("fileUploadBox"), 'noDisplay'); 
        }  
    },
    
})