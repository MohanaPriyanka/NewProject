({
    doInit : function(component, event, helper) {
        const lead = component.get('v.lead');
        helper.parseAttachments(component, helper, lead);
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

    allDocsCollected : function(component, event, helper) {
        let applicant = component.get('v.applicant');
        return (component.get('v.isLargeFile') ||
                (!applicant.Employed__c ||
                 (applicant.Employed__c && component.get('v.paystubs').length !== 0)) &&
                (!applicant.Self_Employed__c ||
                 (applicant.Self_Employed__c && component.get('v.lastYearReturns').length !== 0)) &&
                (!applicant.Self_Employed__c ||
                 (applicant.Self_Employed__c && component.get('v.twoYearReturns').length !== 0)) &&
                (!applicant.Retired__c ||
                 (applicant.Retired__c && component.get('v.retirementIncome').length !== 0)) &&
                (!applicant.Veteran_Disability__c ||
                 (applicant.Veteran_Disability__c && component.get('v.veteranIncome').length !== 0)) &&
                (!applicant.Other_Income__c ||
                 (applicant.Other_Income__c && component.get('v.otherIncome').length !== 0)));
    },

    docsToBeCollected : function(component, event, helper) {
        let returnMessage = '';
        let applicant = component.get('v.applicant');
        if (applicant.Employed__c && component.get('v.paystubs').length === 0) {
            returnMessage += 'Paystubs are required for employed applicants\n';
        }
        if (applicant.Self_Employed__c &&
            ((component.get('v.lastYearReturns').length === 0) || component.get('v.twoYearReturns').length === 0)) {
            returnMessage += 'Tax returns are required for self-employed applicants\n';
        }
        if (applicant.Retired__c && component.get('v.retirementIncome').length === 0) {
            returnMessage += 'Retirement income documentation is required for retired applicants\n';
        }
        if (applicant.Veteran_Disability__c && component.get('v.veteranIncome').length === 0) {
            returnMessage += 'Documentation is required to support veteran or disability income\n';
        }
        if (applicant.Other_Income__c && component.get('v.otherIncome').length === 0) {
            if (applicant.Monthly_Income_Details__c) {
                returnMessage += 'Documentation is required for ' + applicant.Monthly_Income_Details__c;
            }
            if (applicant.Monthly_Income_Details_2__c) {
                returnMessage += 'Documentation is required for ' + applicant.Monthly_Income_Details_2__c;
            }
        }
        return returnMessage;
    },
})