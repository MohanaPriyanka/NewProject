({
    doInit : function(component, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        var outputText = component.find("outputTextId");
        if(record[fieldName] != null) {
        	outputText.set("v.value", record["Product__r"["Name"]]);
        }
    }
})