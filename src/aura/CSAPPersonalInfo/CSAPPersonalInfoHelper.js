({

    processLead : function(component, event, helper) {
        var lead = component.get("v.lead");

        lead.Application_Type__c = component.get("v.applicationType");

        //Both Billing Address and address for Credit Check are populated
        lead.Street = lead.LASERCA__Home_Address__c;
        lead.City = lead.LASERCA__Home_City__c;
        lead.State = lead.LASERCA__Home_State__c;
        lead.PostalCode = lead.LASERCA__Home_Zip__c;

        if (lead.Application_Type__c === "Residential" && lead.Company == null){
            lead.Company = lead.FirstName + " " + lead.LastName;
        }

        if(component.get("v.partnerApp")){
            lead.Application_Source_Phase_1__c = 'CSAP 2.1 with Partner';
        } else {
            lead.Application_Source_Phase_1__c = 'CSAP 2.1 with Inside Sales';
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

                    if (!component.get("v.hasProject")){
                        helper.saveSObject(component, lead.Id, "Lead", "Status", "Unqualified");
                        helper.saveSObject(component, lead.Id, "Lead", "CSAP_Stage__c", "NAV_Personal_Information");
                        component.set("v.loading", false);
                        component.set("v.page", "NoProjects");
                    } else {
                        this.populateUtilityPicklist(component,event,helper,lead);
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

            if (lead.LoadZone__c.includes('/')){
                var allZones = lead.LoadZone__c.split('/');
                if (lead.LASERCA__Home_State__c == 'NY'){
                    lead.LoadZone__c = allZones[0];
                    component.set('v.lead', lead);
                    component.set('v.splitZones', null);

                } else {
                    component.set('v.splitZones', allZones);
                }
            }


            if (utilityList.length == 1 && lead.LASERCA__Home_State__c =='NY') {
                var saveSplitZip = component.get('c.saveUnsplitZone');
                $A.enqueueAction(saveSplitZip);
            } else {
                component.set('v.loading', false);
                component.set('v.page', 'SplitLoadZone');
                component.set('v.splitUtilities', utilityList);
            }
        } else {
            helper.finishStage(component, event, helper);
        }
    },

    login : function(component, event, helper) {
        var promise = helper.getLeadRecord(component, event, helper);
        promise.then($A.getCallback(function resolve(retVal) {
            var lead = retVal;
            if(lead){
                if(lead.Application_Source_Phase_1__c == 'CSAP 2.1 with Partner'){
                    component.set("v.partnerApp", true);
                } else {
                    component.set("v.partnerApp", false);
                }

                if (lead.CSAP_Stage__c) {
                    helper.raiseNavEvent("COMPLETED", {"stageName": lead.CSAP_Stage__c, "lead": lead});
                }else{
                    component.set("v.lead", lead);
                    helper.finishStage(component, event, helper);
                }
            }else{
                alert("Incorrect email address. Please verify your email address.");
            }
        }));
    },
    getLeadRecord : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getLead");
            action.setParams({
                "leadId": component.get("v.leadId"),
                "email" : component.get("v.leadEmail")
            });
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "CSAPStartHelper",
                        "methodName" : "getLeadRecord",
                        "errors" : resp.getError(),
                        "developerInfo" : component.get("v.leadId")});
                    appEvent.fire();
                    reject(resp.getError());
                } else {
                    reject(Error("Unknown error"));
                }
            });
            $A.enqueueAction(action);
        });
    },

})