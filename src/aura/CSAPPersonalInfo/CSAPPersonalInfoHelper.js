({
    processLead : function(component, event, helper) {
        var lead = component.get("v.lead");
        var sendBillToHome = component.get("v.sendBillToHome");
        if(sendBillToHome === "Yes"){
            lead.Street = lead.LASERCA__Home_Address__c;
            lead.City = lead.LASERCA__Home_City__c
            lead.State = lead.LASERCA__Home_State__c
            lead.PostalCode = lead.LASERCA__Home_Zip__c
        }
        if(lead.Application_Type__c === "Residential" && lead.Company == null){
            lead.Company = lead.FirstName + " " + lead.LastName;
        }
        if (component.get('v.partnerId') != null) {
            lead.Application_Source_Phase_1__c = 'CSAP with Partner';
        } else {
            lead.Application_Source_Phase_1__c = 'CSAP without Partner';
        }
        lead.Product_line__c = "Community Solar";
        component.set("v.lead", lead);
    },

    upsertRecords : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (!lead.Application_Source_Phase_2__c || lead.Application_Source_Phase_2__c === 'CSAP Duplicate Attempt'){
            var upsertCSAPRecordsAction = component.get("c.upsertCSAPRecords");
            upsertCSAPRecordsAction.setParams({
                "lead": lead,
                "partnerId" : component.get("v.partnerId"),
                "salesRepId" : component.get("v.salesRepId"),
                "referralCode" : component.get("v.referralCode")
            });
            upsertCSAPRecordsAction.setCallback(this, function(actionResult) {
                if (actionResult.getState() === 'SUCCESS') {
                    var lead = actionResult.getReturnValue();
                    component.set("v.lead", lead);
                    if (lead.Utility_1__c.includes('/') || lead.Load_Zone__c.includes('/')) {
                        component.set('v.loading', false);
                        component.set('v.splitZones', lead.Load_Zone__c.split('/'));
                        component.set('v.splitUtilities', lead.Utility_1__c.split('/'));
                        component.set('v.page', 'SplitLoadZone');
                    } else {
                        helper.finishStage(component, event, helper);
                    }
                } else {
                    helper.raiseError('CSAPPersonalInfoHelper', 'upsertRecords',
                        'There was an issue saving your information. It is possible that the information you provided may contain a typo. Please review',
                        JSON.stringify(actionResult.getError()));
                    component.set("v.loading", false);
                    component.set("v.page", "AboutYourself");
                }
            });
            $A.enqueueAction(upsertCSAPRecordsAction);
        } else {
            var addAdditionalLeadAction = component.get("c.addAdditionalLead");
            addAdditionalLeadAction.setParams({
                "lead": lead
            });
            addAdditionalLeadAction.setCallback(this, function(actionResult) {
                if (actionResult.getState() === 'SUCCESS') {
                    var lead = actionResult.getReturnValue();
                    component.set("v.lead", lead);
                    if (lead.Utility_1__c.includes('/') || lead.Load_Zone__c.includes('/')) {
                        component.set('v.loading', false);
                        component.set('v.splitZones', lead.Load_Zone__c.split('/'));
                        component.set('v.splitUtilities', lead.Utility_1__c.split('/'));
                        component.set('v.page', 'SplitLoadZone');
                    } else {
                        helper.finishStage(component, event, helper);
                    }
                } else {
                    helper.raiseError('CSAPPersonalInfoHelper', 'upsertRecords',
                        'There was an issue saving your information. It is possible that the information you provided may contain a typo. Please review',
                        JSON.stringify(actionResult.getError()));
                    component.set("v.loading", false);
                    component.set("v.page", "AboutYourself");
                }
            });
            $A.enqueueAction(addAdditionalLeadAction);
        }
    },
})
