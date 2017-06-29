({
    getPicklistOptions : function(component, objectName, fieldName, inputSelect) {
        var action = component.get("c.getPicklistFields");
        action.setParams({"objectName": objectName,
                          "fieldName": fieldName});
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputSelect.set("v.options", opts);
            console.log(opts);
        });
        $A.enqueueAction(action); 
    },

    saveSObject : function(component, id, objectName, field, value) {
        var lead = component.get("v.lead");
        var sobj = new Object();
        sobj = {'sobjectType': objectName,
               'Id': id};
        sobj[field] = value;
        var action = component.get("c.updateSObject");
        action.setParams({"sobj": sobj});
        action.setCallback(this, function(resp) {
            if (resp.getState() != "SUCCESS") {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingController",
                                    "methodName" : "updateReviewStatus",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    },

})