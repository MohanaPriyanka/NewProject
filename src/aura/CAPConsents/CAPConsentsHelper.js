({
    getLead : function(component, helper) {
        var action = component.get('c.getLead');
        action.setParams({'leadId' : component.get('v.lead.Id'),
            'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() !== 'SUCCESS') {
                this.logError('CAPConsentsHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

	getSRECProducts : function(component, event, helper, lead) {
		var i;
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.lead.LASERCA__Home_State__c"),
                          productType: 'SREC'});
        action.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                var srecOptions = resp.getReturnValue();
                var i = 0;
                for (; i < srecOptions.length; i++) {
                    if (srecOptions[i] && lead.SREC_Product__r) {
                        if (srecOptions[i]["Name"] === lead.SREC_Product__r.Name) {
                            var selectedIndex = i; 
                            var selectedSrec = srecOptions[i];
                        }
                    }
                }
                if (i > 0) {
                    resp.getReturnValue().unshift(selectedSrec);
                    resp.getReturnValue().splice(selectedIndex + 1, 1);
                }
                component.set("v.availableSRECProducts", resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailController", "availableSRECProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
	},

    sendLoanDocs : function(component, event, helper) {
        return new Promise(function(resolve) {
            let action = component.get('c.sendLoanDocs');
            action.setParams({
                'leadId': component.get('v.lead.Id'),
                'email': component.get('v.lead.Email')
            });
            action.setCallback(this, function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    helper.raiseNavEvent("CONTRACTSENT", {"lead": component.get('v.lead'), "contractSent": true});
                    resolve();
                } else {
                    helper.logError('CAPConsentsHelper', 'sendLoanDocs', 'DocuSign could not be sent', resp);
                }
            });
            $A.enqueueAction(action);
        });
    },
})