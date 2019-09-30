({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            component.set("v.page", 'CapacityCheck');
            component.set("v.supressWaiting", false);
            component.set("v.loading", true);
            component.set("v.loadingText", "Checking if there are Community Solar projects in your area...");
            component.set("v.hasCapacity", "");
            var lead = component.get("v.lead");
            if (lead && lead.Loan_System_Information__c === 'Yes' && lead.LASERCA__Home_State__c === 'NY') {
                component.set("v.loading", false);
                component.set("v.hasCapacity", "No");
                component.set("v.noCapacityReason", "NYHasSolar");
            } else if (lead && lead.Id) {
                component.set("v.loadingText", "Returning the results...");
                var hasAvailableCapacityAction = component.get("c.hasAvailableCapacity");
                hasAvailableCapacityAction.setParams({
                    "leadId": lead.Id
                });
                hasAvailableCapacityAction.setCallback(this, function(actionResult) {
                    if (actionResult.getReturnValue() !== null) {
                        var hasAvailableCapacity = actionResult.getReturnValue();
                        if (hasAvailableCapacity) {
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Qualified").then(
                                $A.getCallback(function resolve() {
                                    component.set("v.loading", false);
                                    component.set("v.hasCapacity", "Yes");
                                    $A.util.addClass(component.find("greatNews"), 'pulse');
                                }));
                        } else if (!hasAvailableCapacity && lead.Application_Source_Phase_2__c !== null) {
                            var delaySkipToEnd = component.get('c.delaySkipToEnd');
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Waitlist").then(
                                $A.getCallback(function resolve() {
                                    component.set("v.loading", false);
                                    component.set("v.hasCapacity", "No");
                                    component.set("v.page", "NoCapacity");
                                })).then(
                            $A.enqueueAction(delaySkipToEnd)
                            );
                        } else {
                            helper.saveSObject(component, lead.Id, "Lead", "Status", "Waitlist").then(
                                $A.getCallback(function resolve() {
                                    component.set("v.loading", false);
                                    component.set("v.hasCapacity", "No");
                                    component.set("v.page", "NoCapacity");
                                }));
                        }
                    } else {
                        alert("There was an issue. Please go back and verify the information provided is correct.");
                    }
                });
                $A.enqueueAction(hasAvailableCapacityAction);
            }
        }
    },

    checkCredit : function(component, event, helper) {

        var billNotUploaded = !component.get("v.electricBill1") && !component.get('v.isLargeFile') && !component.get("v.partnerApp");
        var initials = component.get("v.initials");
        if (billNotUploaded) {
            alert("Please upload your recent electric bill");
        }
        if (initials == null){
            alert("Please sign your initials for the Terms and Conditions");
        }
        if (helper.validatePageFields(component) && !billNotUploaded && initials != null ) {
            //Disable after the first click to prevent the user from clicking it again
            event.getSource().set("v.disabled", true);

            var lead = component.get("v.lead");
            helper.storeTermsConditions(component, event, helper);
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);

            if (component.get("v.partnerApp")){
                helper.finishStage(component, event, helper);
            } else{
                lead.CSAP_Stage__c = 'NAV_Capacity_Check';
                component.set('v.page', 'ApplicationComplete');

            }
        }
    },



    skipToEnd : function(component, event, helper) {
        var lead = component.get('v.lead');
        var stageName = lead.CSAP_Stage__c;
        component.set("v.page", "NoCapacity");
    },

    delaySkipToEnd : function(component, event, helper) {
        var skipToEnd = component.get('c.skipToEnd');
        window.setTimeout(
            $A.getCallback(function() {
                $A.enqueueAction(skipToEnd);
            }), 5000);
    },
    handleUploadFinished : function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        component.set("v.fileUploadedText", uploadedFiles.length + " file(s) uploaded.");
        component.set("v.electricBill1", true);
    }
})