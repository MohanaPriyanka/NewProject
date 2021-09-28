({  
    getUALs : function(component, event, helper) {
        const actionGetUALs = component.get("c.getUALs"); 
        const accountIDVar = component.get("v.acctId");
        actionGetUALs.setParams({
          "propAccount": accountIDVar
        });
        actionGetUALs.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.ListofUALs", resp.getReturnValue());
                console.log(resp.getReturnValue());
            }
        });
        $A.enqueueAction(actionGetUALs);
    },
    
    createUALandUAS : function(component, event, helper){
        component.set("v.UAL.Account__c", component.get("v.acctId"));
        const UALtoInsert = component.get("v.UAL");
        const ualPromise = helper.insertSObject(component, UALtoInsert);
        ualPromise.then($A.getCallback(function resolve(retVal) { 
            component.set("v.UAS.Utility_Account_Log__c", retVal.Id);
            component.set("v.UAS.Name", retVal.Name);
            helper.createUAS(component, event, helper);
        }));
    },    

    createUAS : function(component, event, helper) {
        component.set("v.UAS.Opportunity__c", component.get("v.OppId"));
        const share = component.find("sharePercent").get("v.value");
        const sssSize = component.get("v.SSSsize");
        component.set("v.UAS.Customer_Subscription_KW_DC_STATIC__c", share/100*sssSize);
        const UAStoInsert = component.get("v.UAS");
        const uasPromise = helper.insertSObject(component, UAStoInsert);
        uasPromise.then($A.getCallback(function resolve(retVal) {
            component.set("v.showPage", false);
            component.set("v.successText", 'Record Saved Successfully: ' + retVal.Id);
        }));
    },
})