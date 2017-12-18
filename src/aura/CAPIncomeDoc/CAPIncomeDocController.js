({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, 'EmployedQuestion');
        // helper.handleNavEvent(component, event, helper, 'GetTaxReturns');
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            helper.parseAttachments(component, helper);
        }
    },

    getPayStubs : function(component, event, helper) {
        if (component.get('v.employed')) {
            component.set('v.page', 'GetPayStubs');
        } else {
            component.set('v.page', 'SelfEmployedQuestion');
        }
    },

    saveAndAskSelfEmployed : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Year_Employment__c: lead.Year_Employment__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        if (lead.Application_Type__c === 'Joint') {
            if (lead.CoApplicant_Contact__c) {
                var contact = {
                    sobjectType: 'Contact',
                    Id: lead.CoApplicant_Contact__c,
                    Year_Employment__c: lead.CoApplicant_Contact__r.Year_Employment__c
                };
                leadPromise.then($A.getCallback(function resolve(retVal) {
                    return(helper.saveSObject(component, contact.Id, 'Contact', null, null, contact));
                })).then($A.getCallback(function resolve(retVal) {
                    component.set('v.page', 'SelfEmployedQuestion');
                }));
            } else {
                helper.logError('CAPIncomeDocController', 'saveAndAskSelfEmployed',
                    'This Joint Application has no Co-Signer or Co-Applicant', lead);
            }
        } else {
            leadPromise.then($A.getCallback(function resolve(retVal) {
                component.set('v.page', 'SelfEmployedQuestion');
            }));
        }
    },

    getTaxReturns : function(component, event, helper) {
        if (component.get('v.selfEmployed')) {
            component.set('v.page', 'GetTaxReturns');
        } else {
            component.set('v.page', 'RetirementQuestion');
        }
    },

    saveAndAskRetirement : function(component, event, helper) {
        component.set('v.page', 'RetirementQuestion');
    },

    getRetirementIncome : function(component, event, helper) {
        if (component.get('v.retired')) {
            component.set('v.page', 'GetRetirementIncome');
        } else {
            component.set('v.page', 'VeteranQuestion');
        }
    },

    saveAndAskVeteran : function(component, event, helper) {
        component.set('v.page', 'VeteranQuestion');
    },

    getVeteranIncome : function(component, event, helper) {
        if (component.get('v.veteran')) {
            component.set('v.page', 'GetVeteranIncome');
        } else {
            component.set('v.page', 'AlimonyQuestion');
        }
    },

    saveAndAskAlimony : function(component, event, helper) {
        component.set('v.page', 'AlimonyQuestion');
    },

    getAlimonyIncome : function(component, event, helper) {
        if (component.get('v.alimony')) {
            component.set('v.page', 'GetAlimonyIncome');
        } else {
            component.set('v.page', 'OtherIncome');
        }
    },

    saveAndAskOther : function(component, event, helper) {
        const lead = component.get('v.lead');
        var errorMessage = "";
        errorMessage += helper.getFieldError(component, {
            'fieldValue': lead.Monthly_Income_Details__c,
            'fieldId': 'alimonyDetails',
            'maxLength': 30,
            'optional': true,
            'allowSpecialChars': true,
            'allowSpaces': true,
            'errorMessage': 'Please enter a detail with fewer than 30 characters'
        });
        errorMessage += helper.getFieldError(component, {
            'fieldValue': lead.Monthly_Income_Details_2__c,
            'fieldId': 'alimonyDetails2',
            'maxLength': 30,
            'optional': true,
            'allowSpecialChars': true,
            'allowSpaces': true,
            'errorMessage': 'Please enter a detail with fewer than 30 characters'
        });
        if (errorMessage) {
            helper.logError("CAPIncomeDoc", "saveAndAskOther", errorMessage);
            return;
        }
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Monthly_Income__c: lead.Monthly_Income__c,
            Monthly_Income_Details__c: lead.Monthly_Income_Details__c,
            Monthly_Income_2__c: lead.Monthly_Income_2__c,
            Monthly_Income_Details_2__c: lead.Monthly_Income_Details_2__c,
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            component.set('v.page', 'OtherIncome');
        }));
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },

    handlePaystubFiles : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.PAYSTUB);
    },

    handleTaxOneYear : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.TAX_PREV_YEAR);
    },

    handleTaxTwoYear : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.TAX_TWO_YEARS_PRIOR);
    },

    handlePension : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.PENSION);
    },

    handleSSN : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.SSN);
    },

    handleBankStatement : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.BANK);
    },

    handleVeteran : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.VETERAN);
    },

    handleOtherIncome : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.OTHER_INCOME);
    },
})
