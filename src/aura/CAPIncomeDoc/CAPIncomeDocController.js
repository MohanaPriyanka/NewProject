({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, 'EmployedQuestion');
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            helper.parseAttachments(component, helper);
        }
    },

    getPayStubs : function(component, event, helper) {
        var employed = component.get('v.lead.Employed__c');
        var notEmployed = component.get('v.lead.Not_Employed__c');
        if (!employed && !notEmployed) {
            alert('Please choose an option.');
        } else {
            if (employed) {
                component.set('v.page', 'GetPayStubs');
            } else {
                component.set('v.page', 'SelfEmployedQuestion');
            }
        } 
    },

    setEmployment: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Employed__c', true);
            component.set('v.lead.Not_Employed__c', false);
        } else {
            component.set('v.lead.Employed__c', false);
            component.set('v.lead.Not_Employed__c', true);
        }
    },

    setEmploymentLength: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Year_Employment__c', true);
            component.set('v.lead.Employed_less_than_a_year__c', false);
        } else {
            component.set('v.lead.Year_Employment__c', false);
            component.set('v.lead.Employed_less_than_a_year__c', true);
        }
    },

    setSelfEmployment: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Self_Employed__c', true);
            component.set('v.lead.Not_Self_Employed__c', false);
        } else {
            component.set('v.lead.Self_Employed__c', false);
            component.set('v.lead.Not_Self_Employed__c', true);
        }
    },

    setRetired: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Retired__c', true);
            component.set('v.lead.Not_Retired__c', false);
        } else {
            component.set('v.lead.Retired__c', false);
            component.set('v.lead.Not_Retired__c', true);
        }
    },

    setVeteran: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Veteran_Disability__c', true);
            component.set('v.lead.No_Veteran_Disability__c', false);
        } else {
            component.set('v.lead.Veteran_Disability__c', false);
            component.set('v.lead.No_Veteran_Disability__c', true);
        }
    },

    setAlimony: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Reliant_on_Alimony_Child_Support_Other__c', true);
            component.set('v.lead.Not_Reliant_on_Alimony_Child_Support_Oth__c', false);
        } else {
            component.set('v.lead.Reliant_on_Alimony_Child_Support_Other__c', false);
            component.set('v.lead.Not_Reliant_on_Alimony_Child_Support_Oth__c', true);
        }
    },

    saveAndAskSelfEmployed : function(component, event, helper) {
        var longerThanYear = component.get('v.lead.Year_Employment__c');
        var shorterThanYear = component.get('v.lead.Employed_less_than_a_year__c');
        if (!longerThanYear && !shorterThanYear) {
            alert('Plese select an option with regards to your length of employment.')
        } else {
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
        }
    },

    getTaxReturns : function(component, event, helper) {
        var selfEmployed = component.get('v.lead.Self_Employed__c');
        var notSelfEmployed = component.get('v.lead.Not_Self_Employed__c');
        if (!selfEmployed && !notSelfEmployed) {
            alert('Please choose an option.');
        } else {
            if (selfEmployed) {
                component.set('v.page', 'GetTaxReturns');
            } else {
                component.set('v.page', 'RetirementQuestion');
            }
        }
    },

    saveAndAskRetirement : function(component, event, helper) {
        component.set('v.page', 'RetirementQuestion');
    },

    getRetirementIncome : function(component, event, helper) {
        var retired = component.get('v.lead.Retired__c');
        var notRetired = component.get('v.lead.Not_Retired__c');
        if (!retired && !notRetired) {
            alert('Please choose an option.');
        } else {
            if (retired) {
                component.set('v.page', 'GetRetirementIncome');
            } else {
                component.set('v.page', 'VeteranQuestion');
            }
        }
    },

    saveAndAskVeteran : function(component, event, helper) {
        component.set('v.page', 'VeteranQuestion');
    },

    getVeteranIncome : function(component, event, helper) {
        var veteran = component.get('v.lead.Veteran_Disability__c');
        var notVeteran = component.get('v.lead.No_Veteran_Disability__c');
        if (!veteran && !notVeteran) {
            alert('Please choose an option');
        } else {
            if (veteran) {
                component.set('v.page', 'GetVeteranIncome');
            } else {
                component.set('v.page', 'AlimonyQuestion');
            }
        }
    },

    saveAndAskAlimony : function(component, event, helper) {
        component.set('v.page', 'AlimonyQuestion');
    },

    getAlimonyIncome : function(component, event, helper) {
        const lead = component.get('v.lead');
        var alimony = component.get('v.lead.Reliant_on_Alimony_Child_Support_Other__c');
        var noAlimony = component.get('v.lead.Not_Reliant_on_Alimony_Child_Support_Oth__c');
        if (!alimony && !noAlimony) {
            alert('Please choose an option.');
        } else {
            if (alimony) {
                component.set('v.page', 'GetAlimonyIncome');
            } else {
                var leadToSave = {
                    sobjectType: 'Lead',
                    Id: lead.Id,
                    Monthly_Income__c: lead.Monthly_Income__c,
                    Monthly_Income_Details__c: lead.Monthly_Income_Details__c,
                    Monthly_Income_2__c: lead.Monthly_Income_2__c,
                    Monthly_Income_Details_2__c: lead.Monthly_Income_Details_2__c,
                    Employed__c: lead.Employed__c,
                    Not_Employed__c: lead.Not_Employed__c,
                    Year_Employment__c: lead.Year_Employment__c,
                    Employed_less_than_a_year__c: lead.Employed_less_than_a_year__c,
                    Self_Employed__c: lead.Self_Employed__c,
                    Not_Self_Employed__c: lead.Not_Self_Employed__c,
                    Retired__c: lead.Retired__c,
                    Not_Retired__c: lead.Not_Retired__c,
                    Veteran_Disability__c: lead.Veteran_Disability__c,
                    No_Veteran_Disability__c: lead.No_Veteran_Disability__c,
                    Reliant_on_Alimony_Child_Support_Other__c: lead.Reliant_on_Alimony_Child_Support_Other__c,
                    Not_Reliant_on_Alimony_Child_Support_Oth__c: lead.Not_Reliant_on_Alimony_Child_Support_Oth__c,
                };
                var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
                leadPromise.then($A.getCallback(function resolve(retVal) {
                    component.set('v.page', 'OtherIncome');
                }));
            }
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
            Employed__c: lead.Employed__c,
            Not_Employed__c: lead.Not_Employed__c,
            Year_Employment__c: lead.Year_Employment__c,
            Employed_less_than_a_year__c: lead.Employed_less_than_a_year__c,
            Self_Employed__c: lead.Self_Employed__c,
            Not_Self_Employed__c: lead.Not_Self_Employed__c,
            Retired__c: lead.Retired__c,
            Not_Retired__c: lead.Not_Retired__c,
            Veteran_Disability__c: lead.Veteran_Disability__c,
            No_Veteran_Disability__c: lead.No_Veteran_Disability__c,
            Reliant_on_Alimony_Child_Support_Other__c: lead.Reliant_on_Alimony_Child_Support_Other__c,
            Not_Reliant_on_Alimony_Child_Support_Oth__c: lead.Not_Reliant_on_Alimony_Child_Support_Oth__c,
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
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Employed_less_than_a_year__c: lead.Employed_less_than_a_year__c,
            Year_Employment__c: lead.Year_Employment__c,
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            helper.handleAttachment(component, event, helper, helper.PAYSTUB);
        }));
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