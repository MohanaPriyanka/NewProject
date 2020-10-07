/**
 * Created by PeterYao on 3/9/2020.
 */

({
    savePaymentMethodToAccount : function(propertyAccount) {
        return new Promise($A.getCallback(function (resolve, reject) {
            let calloutURI = '/apply/services/apexrest/v3/property-accounts';
            const xmlHttpRequest = new XMLHttpRequest();
            xmlHttpRequest.onreadystatechange = function () {
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
            xmlHttpRequest.open('PATCH', calloutURI, true);
            xmlHttpRequest.setRequestHeader('Content-Type', 'application/json');
            xmlHttpRequest.send(JSON.stringify(propertyAccount));
        }));
    },

    finishApplication : function(restLead) {
        return new Promise($A.getCallback(function(resolve, reject) {
            let calloutURI = '/apply/services/apexrest/v3/leads';
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
            xmlHttpRequest.open('PATCH', calloutURI, true);
            xmlHttpRequest.setRequestHeader('Content-Type', 'application/json');
            xmlHttpRequest.send(JSON.stringify(restLead));
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
    }

});