({
    processLead : function(component, event, helper) {
        var lead = component.get("v.lead");

        lead.Application_Type__c = component.get("v.applicationType");
        //var sendBillToHome = component.get("v.sendBillToHome");
        //if(sendBillToHome === "Yes"){

        //Setting the Billing Address as well as the address for the credit check
            lead.Street = lead.LASERCA__Home_Address__c;
            lead.City = lead.LASERCA__Home_City__c;
            lead.State = lead.LASERCA__Home_State__c;
            lead.PostalCode = lead.LASERCA__Home_Zip__c;
        //}
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
                    this.populateUtilityPicklist(component,event,helper,lead);
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
                    this.populateUtilityPicklist(component,event,helper,lead);
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

    populateUtilityPicklist : function(component, event, helper, lead) {
        var utilityList = [];


        if ((lead.Confirm_Utility__c && lead.Confirm_Utility__c.includes('/'))
            || (lead.LoadZone__c && lead.LoadZone__c.includes('/'))){
            var splitNamesFromId = lead.Confirm_Utility__c.split('>');
            var namesList = splitNamesFromId[0].split('/');
            var idsList = splitNamesFromId[1].split('/');

            var i;
            for (i = 0; i < namesList.length; i++) {
                var newUtility = {
                    'Name': namesList[i],
                    'Id': idsList[i]
                };
                utilityList.push(newUtility);
            };
            component.set('v.loading', false);
            component.set('v.page', 'SplitLoadZone');
            component.set('v.splitUtilities', utilityList);
            if (lead.LoadZone__c.includes('/')){
                var allZones = lead.LoadZone__c.split('/');
                if (lead.LASERCA__Home_State__c == 'NY'){
                    component.set('v.splitZones', null);
                    lead.LoadZone__c = allZones[0];
                } else {
                    component.set('v.splitZones', lead.LoadZone__c.split('/'));
                }
            }
        } else {
            helper.finishStage(component, event, helper);
        }


    },

})