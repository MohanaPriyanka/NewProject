({
    doInit : function(component, event, helper) {
        var parsedUrl = new URL(window.location.href);
        let leadId = parsedUrl.searchParams.get("leadId");
        let leadEmail = parsedUrl.searchParams.get("leadEmail");
        let oppCounter = parseInt(parsedUrl.searchParams.get("oppCounter"));
        let oppTotal = parsedUrl.searchParams.get("oppTotal");
        component.set("v.loadingText", "Generating contract " + (oppCounter + 1) + " of " +  oppTotal);

        if (leadId && leadEmail && oppCounter) {
            var lead = {
                'sobjectType':'Lead',
                'Id': leadId,
                'Email': leadEmail
            };
            var sendDocuSignAction = component.get('c.sendEmbeddedContract');
            sendDocuSignAction.setParams({
                'lead': lead,
                'oppCounter': oppCounter
            });
            sendDocuSignAction.setCallback(this, function(docuSignResp) {
                if (docuSignResp.getState() !== "SUCCESS") {
                    helper.logError("CSAPShowContract", "doInit", docuSignResp.getError(), leadId);
                } else {
                    window.location.href = docuSignResp.getReturnValue();
                }
            });
            $A.enqueueAction(sendDocuSignAction);
        }
    },
})