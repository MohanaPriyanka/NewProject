({
    doInit : function(component, event, helper) {
        helper.getUALs(component, event, helper);
    },
    
    selectUAL : function(component, event, helper) {
        const ualChoice = component.find("ualInput").get("v.value");
        if (ualChoice === 'createNewUAL'){
            component.set("v.createNew", true);
        } else {
            component.set("v.createNew", false);
            const ualInfo = component.find("ualInput").get("v.value");
            const infoArray = ualInfo.split('-');
            console.log(infoArray);
            component.set("v.UAS.Utility_Account_Log__c", infoArray[0]);
            component.set("v.UAS.Name", infoArray[1]);
        }
    },
    
    submitUAL : function(component, event, helper) {
        if(component.get("v.SSSname").length < 1){
            component.set("v.errorMessage", "Opportunity Must Be Linked to SSS");
        } else if (component.get("v.SSSsize") == 0 || component.get("v.SSSsize") == null) {
            component.set("v.errorMessage", "Project Size must be > 0");
        } else if(component.get("v.createNew")){
            helper.createUALandUAS(component, event, helper);
        } else {
            helper.createUAS(component, event, helper);
        }
    },
    
    goBack : function(component, event, helper) {
        component.set("v.showPage", true);
        helper.getUALs(component, event, helper);
    },
})