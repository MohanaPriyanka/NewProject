({
    doInit : function(component, event, helper) {
        if (component.get('v.abbrevStates') && component.get('v.abbrevStates').length === 0) {
            helper.getUSStates(component, 'v.abbrevStates', true);
        }
        if (component.get('v.years') && component.get('v.years').length === 0) {
            let years = [];
            for (let i = 0; i <= 50; i++) {
                years.push(i);
            }
            component.set('v.years', years);
        }
    },

    anyTypesSelected : function(component, event, helper) {
        let applicant = component.get('v.applicant');
        return (applicant.Employed__c ||
                applicant.Self_Employed__c ||
                applicant.Retired__c ||
                applicant.Veteran_Disability__c ||
                applicant.Other_Income__c);
    },

    saveIncomeType : function(component, event, helper) {
        let params = event.getParam('arguments');
        if (!params) {
            return;
        }

        let applicant = params.passedApplicant;
        let sobjectType = params.passedApplicantType;
        let piLocked = params.passedPILocked;
        let callback = params.callback;

        // Make a copy of applicant with just the fields that we want to save, since it may include
        // child objects which can't be passed
        let totalIncome = 0;
        let applicantCopy = {
            'sobjectType': sobjectType,
            'Id': applicant.Id,
            'Employed__c': applicant.Employed__c,
            'Self_Employed__c': applicant.Self_Employed__c,
            'Retired__c': applicant.Retired__c,
            'Veteran_Disability__c': applicant.Veteran_Disability__c,
            'Other_Income__c': applicant.Other_Income__c,
            'Annual_Income_Currency__c': 0
        };
        if (applicant.Employed__c) {
            applicantCopy.Employer_Name__c = applicant.Employer_Name__c;
            applicantCopy.Employer_State__c = applicant.Employer_State__c;
            applicantCopy.Employer_Years__c = applicant.Employer_Years__c;
            applicantCopy.Employer_Months__c = applicant.Employer_Months__c;
            applicantCopy.Employer_Annual_Salary__c = applicant.Employer_Annual_Salary__c;
            totalIncome += parseFloat(applicant.Employer_Annual_Salary__c);
        }
        if (applicant.Self_Employed__c) {
            applicantCopy.Self_Employment_Annual_Salary__c = applicant.Self_Employment_Annual_Salary__c;
            totalIncome += parseFloat(applicant.Self_Employment_Annual_Salary__c);
        } else {
            applicantCopy.Self_Employment_Annual_Salary__c = null;
        }
        if (applicant.Retired__c) {
            applicantCopy.Retirement_Annual_Salary__c = applicant.Retirement_Annual_Salary__c;
            totalIncome += parseFloat(applicant.Retirement_Annual_Salary__c);
        } else {
            applicantCopy.Retirement_Annual_Salary__c = null;
        }
        if (applicant.Veteran_Disability__c) {
            applicantCopy.Veteran_Annual_Salary__c = applicant.Veteran_Annual_Salary__c;
            totalIncome += parseFloat(applicant.Veteran_Annual_Salary__c);
        } else {
            applicantCopy.Veteran_Annual_Salary__c = null;
        }
        if (applicant.Other_Income__c) {
            applicantCopy.Monthly_Income__c = applicant.Monthly_Income__c;
            applicantCopy.Monthly_Income_Details__c = applicant.Monthly_Income_Details__c;
            applicantCopy.Monthly_Income_2__c = applicant.Monthly_Income_2__c;
            applicantCopy.Monthly_Income_Details_2__c = applicant.Monthly_Income_Details_2__c;
            applicantCopy.Annual_Income_Currency__c += applicant.Monthly_Income__c * 12;
            totalIncome += parseFloat(applicant.Monthly_Income__c * 12);
            if (applicant.Monthly_Income_2__c) {
                totalIncome += parseFloat(applicant.Monthly_Income_2__c * 12);
            }
        } else {
            applicantCopy.Monthly_Income__c = null;
            applicantCopy.Monthly_Income_Details__c = null;
            applicantCopy.Monthly_Income_2__c = null;
            applicantCopy.Monthly_Income_Details_2__c = null;
        }
        if (piLocked) {
            callback(totalIncome);
        } else {
            let applicantPromise = helper.saveSObject(component, applicantCopy.Id, sobjectType, null, null, applicantCopy);
            applicantPromise.then($A.getCallback(function resolve(retVal) {
                callback(totalIncome);
            }));
        }
    }
})