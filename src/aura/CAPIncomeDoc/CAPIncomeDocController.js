({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        if (lead) {
            component.set('v.docsRequested', lead.Docs_Requested__c);
        }
        if (lead && lead.Product_Program__c === "MSLP") {
            helper.handleNavEvent(component, event, helper, 'MSLPTechnicalConfirm');
            if (event.getParam("eventType") === "INITIATED" &&
                event.getParam("stageName") === component.get("v.STAGENAME")) {
                helper.parseAttachments(component, helper, lead);
            }
        } else {
            helper.handleNavEvent(component, event, helper, 'EmployedQuestion');
        }

        var now = new Date();
        // getMonth starts at 0, and we need to collect W-2s through April (per Mickey at Avidia)
        if (now.getMonth() <= 3) {
            component.set('v.inFirstQuarter', true);
            component.set('v.lastYear', now.getFullYear() - 1);
        } else {
            component.set('v.inFirstQuarter', false);
        }
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            helper.parseAttachments(component, helper);
        }
    },

    saveTCAskEmployed : function(component, event, helper) {
        if (helper.checkProjectIDErrors(component)) {
            helper.logError("CAPIncomeDocController", "saveTCAskEmployed", helper.checkProjectIDErrors(component));
            return;
        }
        if (!component.get('v.tcDocs') ||
            component.get('v.tcDocs').length === 0) {
            alert('Please upload your technical confirmation before continuing');
            return;
        }

        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Project_Identification_Number__c: lead.Project_Identification_Number__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            component.set('v.page', 'EmployedQuestion');
        }));
    },

    getPayStubs : function(component, event, helper) {
        var lead = component.get('v.lead');
        var employed = component.get('v.lead.Employed__c');
        var notEmployed = component.get('v.lead.Not_Employed__c');
        if (!employed && !notEmployed) {
            alert('Please choose an option.');
        } else {
            var leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Employed__c: lead.Employed__c,
                Not_Employed__c: lead.Not_Employed__c
            };
            var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
            promise.then($A.getCallback(function resolve(retVal) {
                if (employed) {
                    component.set('v.page', 'GetPayStubs');
                } else {
                    component.set('v.page', 'SelfEmployedQuestion');
                }
            }));
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
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Year_Employment__c: (value==='true'?true:false),
            Employed_less_than_a_year__c: (value==='true'?false:true)
        };
        var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        promise.then($A.getCallback(function resolve(retVal) {
            if (value == 'true') {
                component.set('v.lead.Year_Employment__c', true);
                component.set('v.lead.Employed_less_than_a_year__c', false);
            } else {
                component.set('v.lead.Year_Employment__c', false);
                component.set('v.lead.Employed_less_than_a_year__c', true);
            }
        }));
    },

    setCoAppEmploymentLength: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        var contact = {
            sobjectType: 'Contact',
            Id: lead.CoApplicant_Contact__c,
            Year_Employment__c: (value==='true'?true:false),
            Employed_less_than_a_year__c: (value==='true'?false:true)
        };
        var promise = helper.saveSObject(component, contact.Id, 'Contact', null, null, contact);
        promise.then($A.getCallback(function resolve(retVal) {
            if (value == 'true') {
                component.set('v.lead.CoApplicant_Contact__r.Year_Employment__c', true);
                component.set('v.lead.CoApplicant_Contact__r.Employed_less_than_a_year__c', false);
            } else {
                component.set('v.lead.CoApplicant_Contact__r.Year_Employment__c', false);
                component.set('v.lead.CoApplicant_Contact__r.Employed_less_than_a_year__c', true);
            }
        }));
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
        var primaryPaystubs = component.get('v.primaryPaystubs');
        var longerThanYear = component.get('v.lead.Year_Employment__c');
        var shorterThanYear = component.get('v.lead.Employed_less_than_a_year__c');
        var jointPaystubs = component.get('v.jointPaystubs');
        var coAppLongerThanYear = component.get('v.lead.CoApplicant_Contact__r.Year_Employment__c');
        var coAppShorterThanYear = component.get('v.lead.CoApplicant_Contact__r.Employed_less_than_a_year__c');
        if ((primaryPaystubs || component.get('v.lead.Application_Type__c') === 'Individual') && !longerThanYear && !shorterThanYear) {
            alert('Please specify your length of employment.')
            return;
        }
        if (jointPaystubs && component.get('v.lead.Application_Type__c') === 'Joint' && !coAppLongerThanYear && !coAppShorterThanYear) {
            alert('Please specify ' + component.get('v.lead.Co_Applicant_First_Name__c') + '\'s employment length.')
            return;
        }
        if ((!component.get('v.paystubs') || component.get('v.paystubs').length === 0) &&
            !component.get('v.isLargeFile')) {
            alert('Please upload paystubs as income documentation before continuing');
            return;
        }

        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Year_Employment__c: lead.Year_Employment__c,
            Employed_less_than_a_year__c: lead.Employed_less_than_a_year__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        if (lead.Application_Type__c === 'Joint') {
            if (lead.CoApplicant_Contact__c) {
                var contact = {
                    sobjectType: 'Contact',
                    Id: lead.CoApplicant_Contact__c,
                    Year_Employment__c: lead.CoApplicant_Contact__r.Year_Employment__c,
                    Employed_less_than_a_year__c: lead.CoApplicant_Contact__r.Employed_less_than_a_year__c
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
                component.set('v.boxFileUploader', false);
                component.set('v.isLargeFile', false);
            }));
        }
    },

    getTaxReturns : function(component, event, helper) {
        var lead = component.get('v.lead');
        var selfEmployed = component.get('v.lead.Self_Employed__c');
        var notSelfEmployed = component.get('v.lead.Not_Self_Employed__c');
        if (!selfEmployed && !notSelfEmployed) {
            alert('Please choose an option.');
        } else {
            var leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Self_Employed__c: lead.Self_Employed__c,
                Not_Self_Employed__c: lead.Not_Self_Employed__c
            };
            var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
            promise.then($A.getCallback(function resolve(retVal) {
                if (selfEmployed) {
                    component.set('v.page', 'GetTaxReturns');
                } else {
                    component.set('v.page', 'RetirementQuestion');
                }
            }));
        }
    },

    saveAndAskRetirement : function(component, event, helper) {
        if ((!component.get('v.lastYearReturns') || component.get('v.lastYearReturns').length === 0 ||
            !component.get('v.twoYearReturns') || component.get('v.twoYearReturns').length === 0 ) &&
            !component.get('v.isLargeFile')){
            alert('Please document self-employment income by uploading two years of federal tax returns');
            return;
        }
        component.set('v.page', 'RetirementQuestion');
    },

    getRetirementIncome : function(component, event, helper) {
        var lead = component.get('v.lead');
        var retired = component.get('v.lead.Retired__c');
        var notRetired = component.get('v.lead.Not_Retired__c');
        if (!retired && !notRetired) {
            alert('Please choose an option.');
        } else {
            var leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Retired__c: lead.Retired__c,
                Not_Retired__c: lead.Not_Retired__c
            };
            var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
            promise.then($A.getCallback(function resolve(retVal) {
                if (retired) {
                    component.set('v.page', 'GetRetirementIncome');
                } else {
                    component.set('v.page', 'VeteranQuestion');
                }
            }));
        }
    },

    saveAndAskVeteran : function(component, event, helper) {
        if ((!component.get('v.retirementIncome') ||
            component.get('v.retirementIncome').length === 0) &&
            !component.get('v.isLargeFile')){
            alert('Please upload supporting retirement income documentation');
            return;
        }
        component.set('v.page', 'VeteranQuestion');
    },

    getVeteranIncome : function(component, event, helper) {
        var lead = component.get('v.lead');
        var veteran = component.get('v.lead.Veteran_Disability__c');
        var notVeteran = component.get('v.lead.No_Veteran_Disability__c');
        if (!veteran && !notVeteran) {
            alert('Please choose an option');
        } else {
            var leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                No_Veteran_Disability__c: lead.No_Veteran_Disability__c,
                Veteran_Disability__c: lead.Veteran_Disability__c
            };
            var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
            promise.then($A.getCallback(function resolve(retVal) {
                if (veteran) {
                    component.set('v.page', 'GetVeteranIncome');
                } else {
                    component.set('v.page', 'AlimonyQuestion');
                }
            }));
        }
    },

    saveAndAskAlimony : function(component, event, helper) {
        if ((!component.get('v.veteranIncome') ||
            component.get('v.veteranIncome').length === 0) &&
            !component.get('v.isLargeFile')){
            alert('Please upload supporting veteran income documentation');
            return;
        }
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
                var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, lead);
                promise.then($A.getCallback(function resolve(retVal) {
                    component.set('v.page', 'GetAlimonyIncome');
                }));
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
        if (!lead.Monthly_Income__c && !lead.Monthly_Income_2__c) {
            errorMessage += 'Please enter a Monthly Income Amount, or go back and choose to No to relying on Alimony, Child Support, or Separate Maintenance Payments.';
        }
        if (lead.Monthly_Income__c && !lead.Monthly_Income_Details__c) {
            errorMessage += 'Please provide a details for the Monthly Income Amount';
        }
        if (lead.Monthly_Income_2__c && !lead.Monthly_Income_Details_2__c) {
            errorMessage += 'Please provide a details for the Second Monthly Income Amount';
        }
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
        const lead = component.get('v.lead');
        let leadToSave;
        if (lead.Status === 'Awaiting Info Requested from Customer') {
            leadToSave = {
                sobjectType: 'Lead',
                Status: 'Under BlueWave Review',
                Id: lead.Id,
                Unfinished_Lead__c: false
            };
        } else {
            leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Unfinished_Lead__c: false
            };
        }
        helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave)
        .then($A.getCallback(function resolve() {
            return helper.insertPartnerTaskFunction(component, event, helper);
        }))
        .then($A.getCallback(function resolve() {
            helper.finishStage(component, event, helper);
        }));
    },

    handleTC : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.TC_DOC);
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

    goBack : function(component, event, helper) {
        var pageMap = new Map();
        pageMap.set('EmployedQuestion', 'MSLPTechnicalConfirm');
        pageMap.set('GetPayStubs', 'EmployedQuestion');
        pageMap.set('SelfEmployedQuestion', 'EmployedQuestion');
        pageMap.set('GetTaxReturns', 'SelfEmployedQuestion');
        pageMap.set('RetirementQuestion', 'SelfEmployedQuestion');
        pageMap.set('GetRetirementIncome', 'RetirementQuestion');
        pageMap.set('VeteranQuestion', 'RetirementQuestion');
        pageMap.set('GetVeteranIncome', 'VeteranQuestion');
        pageMap.set('AlimonyQuestion', 'VeteranQuestion');
        pageMap.set('GetAlimonyIncome', 'AlimonyQuestion');
        pageMap.set('OtherIncome', 'AlimonyQuestion');
        component.set('v.page', pageMap.get(event.getSource().get('v.name')));
    },
})