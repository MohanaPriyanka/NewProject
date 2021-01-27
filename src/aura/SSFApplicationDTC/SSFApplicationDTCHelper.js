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

    checkCreditReportStatus : function(component) {
        // Check if application requires FICO guarantor
        if (component.get('v.lead.underwritingCriteria') !== 'FICO') {
            return;
        }

        // Send callout to server to process credit report analysis
        var action = component.get('c.getLatestCreditReport');
        action.setParams({
            leadId : component.get('v.lead.id'),
            queryAllHistoric : true
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                this.assessCreditReport(component, response);
            }
            if (state === 'INCOMPLETE') {
                this.logError(
                    component,
                    'SSFApplicationController',
                    'helper.checkCreditPullStatus',
                    'Server returned no response. Possible network error incurred');
                this.showFinalPage(component);
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                this.logError(
                    component,
                    'SSFApplicationController',
                    'helper.checkCreditPullStatus',
                    errors[0].message);
                this.showFinalPage(component);
            }
        });
        $A.enqueueAction(action);
    },

    assessCreditReport : function(component, response) {
        const creditReportDetail = response.getReturnValue();
        if (creditReportDetail.noMatch === true) {
            // PCR has been generated, but no match credit score ("9999") indicated
            component.set('v.latestCreditReport', creditReportDetail);
            component.set('v.showCreditCheckInfoPage', true);
        }
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
                // Prior to bringing user to Complete screen, check status of credit report if relevant
                let showCreditCheckForm = component.get('v.showCreditCheckInfoPage');
                if (showCreditCheckForm === true) {
                    this.showCreditCheckInfoPage(component);
                } else {
                    this.showFinalPage(component);
                }
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

    showCreditCheckInfoPage : function(component) {
        component.set('v.showSpinner', false);
        component.set('v.getInfo', false);
        component.set('v.getPayment', false);
        component.set('v.showCreditCheckInfoPage', true);
        component.set('v.showComplete', false);
    },

    showFinalPage : function(component) {
        component.set('v.showSpinner', false);
        component.set('v.getInfo', false);
        component.set('v.getPayment', false);
        component.set('v.showCreditCheckInfoPage', false);
        component.set('v.showComplete', true);
        this.scrollToTop();
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

    scrollToTop : function() {
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'auto'
        }
        window.scrollTo(scrollOptions);
    },
});