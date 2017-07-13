({
    doInit : function(component, event, helper) {
        var leadPromise = helper.getLead(component);
        leadPromise.then(
            $A.getCallback(function resolve(helper) {
                helper.calculateApplicationIncome(component);
                helper.calculateApplicationDTI(component);
            }));
        helper.getPicklistOptions(component,
                                  'LASERCA__Personal_Credit_Report__c', 
                                  'Avidia_Review_Status__c',
                                  component.find("AvidiaReviewStatus"));
    },

    updateReviewStatus : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component,
                           lead.Personal_Credit_Report__r.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Avidia_Review_Status__c',
                           event.getSource().get("v.value"));
    },
        
    handleEvent : function(component, event, helper) {
        var leadPromise = helper.getLead(component);
        leadPromise.then(
            $A.getCallback(function resolve(helper) {
                helper.calculateApplicationIncome(component);
                helper.calculateApplicationDTI(component);
            }));
    },

    updateAdjustedDTI : function(component, event, helper) {
        var lead = component.get("v.lead");
        var savePromise = helper.saveSObject(component,
                                             lead.Personal_Credit_Report__r.Id,
                                             'LASERCA__Personal_Credit_Report__c',
                                             'Adjusted_DTI__c',
                                             lead.Personal_Credit_Report__r.Adjusted_DTI__c);
        savePromise.then(
            $A.getCallback(function resolve(value) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                debtEvent.setParams({"pcrId":component.get("v.pcr.Id")});
                debtEvent.fire();
            })
        );
    },

    saveDTINotes : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component,
                           lead.Personal_Credit_Report__r.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Adjusted_DTI_Notes__c',
                           lead.Personal_Credit_Report__r.Adjusted_DTI_Notes__c);
    },

    // http://peterknolle.com/file-upload-lightning-component/
    handleFilesChange : function(component, event, helper) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.lead.Id");
        for (var i=0; i<files.length; i=i+1) {
            (function(file) {
                if (file.size > helper.MAX_FILE_SIZE) {
                    alert('File size cannot exceed ' + this.MAX_FILE_SIZE + ' bytes.\n' +
    	                  'Selected file size: ' + file.size);
                }
                console.log(file);
                var fr = new FileReader(); 

       	        fr.onload = function() {
                    var fileContents = fr.result;
                    var base64Mark = 'base64,';
                    var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;

                    fileContents = fileContents.substring(dataStart);
                    
                    helper.upload(component, file, fileContents, parentId).then(
                        $A.getCallback(function resolve(helper) {
                                helper.getLead(component);
                            }),
                        $A.getCallback(function resolve() {
                                var appEvent = $A.get("e.c:ApexCallbackError");
                                appEvent.setParams({"className" : "LoanUnderwritingController",
                                            "methodName" : "emailCreditDecline",
                                            "errors" : resp.getError()});
                                appEvent.fire();
                            }));
                };

                fr.readAsDataURL(file);
            })(files[i]);
        }
    },

})
