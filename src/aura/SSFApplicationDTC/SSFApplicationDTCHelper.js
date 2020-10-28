({
    paymentInfoCollected : function(restLead) {
        return !!restLead.propertyAccounts[0].zuoraPaymentRefId;
    },

    savePaymentMethodToAccount : function(propertyAccount) {
        return this.genericCallout(
            '/apply/services/apexrest/v3/property-accounts',
            'PATCH',
            JSON.stringify(propertyAccount)
        );
    },

    finishApplication : function(component) {
        let restLead = JSON.stringify({
            id: component.get('v.lead.id'),
            email: component.get('v.lead.email'),
            applicationCompleteDate: new Date(),
            underwritingCriteria: component.get('v.lead.underwritingCriteria')
        });
        let callout = this.genericCallout(
            '/apply/services/apexrest/v3/leads',
            'PATCH',
            restLead
        ).then(
            (resolveResult) => {
                this.showFinalPage(component);
            },
            (rejectResult) => {
                let message = 'Lead sent by PATCH to server: ' + restLead
                              + '\n\n' + 'Callback received from server: ' + JSON.stringify(rejectResult);
                this.logError(
                    component,
                    'SSFApplicationController',
                    'helper.finishApplication',
                    message
                );
                this.showFinalPage(component);
            }
        );
    },

    genericCallout : function(calloutURI, apiMethod, bodyAsString) {
        return new Promise($A.getCallback(function(resolve, reject) {
            const xmlHttpRequest = new XMLHttpRequest();
            xmlHttpRequest.onreadystatechange = function() {
                if (this.readyState === 4) {
                    const response = JSON.parse(this.responseText);
                    if (this.status === 200 || this.status === 201) {
                        if (response.data) {
                            resolve(response.data);
                        } else {
                            reject(this.responseText);
                        }
                    } else {
                        reject(this.responseText);
                    }
                }
            };
            xmlHttpRequest.open(apiMethod, calloutURI, true);
            xmlHttpRequest.setRequestHeader('Content-Type', 'application/json');
            xmlHttpRequest.send(bodyAsString);
        }));
    },

    showFinalPage : function(component) {
        component.set('v.showSpinner', false);
        component.set('v.getInfo', false);
        component.set('v.getPayment', false);
        component.set('v.showComplete', true);
    },

    logError : function(component, cmpName, methodName, message) {
        var action = component.get("c.log");
        action.setParams({
            "className": cmpName,
            "methodName": methodName,
            "message": message,
            "severity": "Error"
        });
        $A.enqueueAction(action);
    },
});