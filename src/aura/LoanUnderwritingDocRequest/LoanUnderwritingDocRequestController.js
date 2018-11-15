/**
 * Created by abarnes on 10/25/2018.
 */
({
    addDocumentToRequestList : function(component, event, helper) {
        var document;
        var docList = component.get("v.docsToRequest");
        if (!docList) {
            docList = [];
        }
        if (component.get("v.informationType") === "Select File Type") {
            alert('Please select a file type');
        } else {
            if (component.get("v.informationType") === "Other") {
                document = component.get("v.informationTypeOther");
            } else {
                document = component.get("v.informationType")
            }
            docList.push(document);
            component.set("v.docsToRequest", docList);
        }
    },

    clearDocRequestList : function(component) {
        component.set("v.docsToRequest", null);
    },

    closeInfoRequestModal : function(component, event, helper) {
        component.set("v.showInfoRequestModal", false);
    },

    sendInfoRequestEmail : function(component, event, helper) {
        var documentList = component.get("v.docsToRequest");
        var capStage = component.get("v.lead.CAP_Stage__c")
        if (documentList.length === 0 &&
            (capStage === 'NAV_Income_Doc' ||
             capStage === 'NAV_Complete')) {
            alert('Please add files to complete the request to the customer');
        } else {
            var action = component.get("c.handleDocRequest");
            action.setParams({
                "lead": component.get("v.lead"),
                "documentType": documentList,
                "capStage": capStage
            });
            action.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    alert('The customer has been notified');
                    component.set("v.showInfoRequestModal", false);
                } else {
                    alert('Failed to send Email! Please notify your Administrator.');
                }
            });
            $A.enqueueAction(action);
        }
    }
})