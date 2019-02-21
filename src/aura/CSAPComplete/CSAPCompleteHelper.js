/**
 * Created by mstackhouse on 10/26/2018.
 */
({
    addNewLead : function(component, event, helper, applicationType) {
        var action = component.get("c.getLead");
        action.setParams({
            "leadId": component.get("v.lead.Id"),
            "email" : component.get("v.lead.Email")
        });
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                //Clone the fields from the old lead
                var oldLead = resp.getReturnValue();

                /*
                   If they have already run credit on a previous property, set CSAP Additional Property
                   and do not run credit again. If they have not run credit (ie they are waitlisted)
                   set CSAP Duplicate Attempt and run credit.
                */

                var runCredit = 'CSAP Additional Property';
                if (oldLead.Credit_Check_Acknowledged__c === false){
                    runCredit = 'CSAP Duplicate Attempt';
                }
                var newLead = {
                    sobjectType: "Lead",
                    Id : oldLead.Id,
                    Personal_Credit_Report__c: oldLead.Personal_Credit_Report__c,
                    Parent_Account__c: oldLead.Parent_Account__c,
                    Partner_Lookup__c : oldLead.Partner_Lookup__c,
                    bs_Sales_ID__c : oldLead.bs_Sales_ID__c,
                    Email : oldLead.Email,
                    FirstName: oldLead.FirstName,
                    LastName: oldLead.LastName,
                    MobilePhone: oldLead.MobilePhone,
                    Phone: oldLead.Phone,
                    LASERCA__Birthdate__c: oldLead.LASERCA__Birthdate__c,
                    LASERCA__SSN__c : oldLead.LASERCA__SSN__c,
                    Application_Type__c : applicationType,
                    Application_Source_Phase_2__c : runCredit,
                    Credit_Check_Acknowledged__c : oldLead.Credit_Check_Acknowledged__c,
                    Product_line__c : 'Community Solar',
                    OwnerId : oldLead.OwnerId
                };
                component.set("v.lead", newLead);

                //Redirect to the Personal Information
                var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
                stageChangeEvent.setParams({"stageName": "NAV_Personal_Information"});
                stageChangeEvent.setParams({"options": {"pageName": "AddressForm"}});
                stageChangeEvent.setParams({"eventType": "INITIATED"});
                stageChangeEvent.setParams({"lead": newLead});
                stageChangeEvent.fire();
                component.set("v.page", 'AddressForm');
            } else if (resp.getState() === "ERROR") {
                helper.logError("CSAPCompleteHelper", "getLeadRecord", resp.getError(), component.get("v.leadId"));
                reject(resp.getError());
            } else {
                reject(Error("Unknown error"));
            }
        });
        $A.enqueueAction(action);

    },

    convertLeadFunction : function(component, event, helper) {
        let action = component.get('c.convertCSLead');
        action.setParams({
            "leadId": component.get('v.lead.Id'),
            "email": component.get('v.lead.Email')
        });
        action.setCallback(this, function(resp) {
            if (resp.getState() !== "SUCCESS") {
                this.logError("CSAPCompleteHelper", "convertLeadFunction", resp.getError(), component.get("v.lead"));
            }
            component.set('v.loading', false);
            component.set('v.page', 'Complete');
        });
        $A.enqueueAction(action);
    }
})