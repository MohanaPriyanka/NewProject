({    
    doInit : function(component, event, helper) {
        var actionGetDocsAvailable = component.get("c.getSLPortalCustomSetting");
        actionGetDocsAvailable.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                var slpSettings = resp.getReturnValue();
                var customSetting = slpSettings[0].Types_of_Documents_Available_for_Upload__c; 
                var docList = customSetting.split(',');
                var previousTaxYear = helper.getPreviousTaxYear();
                var previousYearTaxReturn = previousTaxYear.toString() + ' Tax Return (Previous Year)';
                var previous2YearTaxReturn = (previousTaxYear - 1).toString() + ' Tax Return (Two Years Previous)';
                docList.unshift(previous2YearTaxReturn);
                docList.unshift(previousYearTaxReturn);
                component.set("v.fileTypes", docList);
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionGetDocsAvailable);
    },

    filePreview : function(component, event, helper) {
       	helper.saveFileToList(component);
   	},
    
    removeFile : function(component, event, helper) {
		var fileToRemove = event.getSource().get("v.name");
        helper.removeFileFromList(component, fileToRemove);
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
        var parentId = component.get("v.fileParentId");  
        var fileInput = component.get("v.fileList"); 
        var newFileName = component.get("v.fileName"); 
        var fr = component.get("v.fileReader");
        var numberOfFiles = fr.length; 
        helper.saveFilesToServer(component, event, parentId, 0, fileInput, newFileName, fr, numberOfFiles, helper);
    },
    
    closeWindow : function(component, event, helper) {
        helper.closeWindow(component); 
    },
    
    doneButton : function(component, event, helper) {
        helper.firePartnerTaskRefresh(component, helper);
        helper.closeWindow(component);
    },
    
})