({
    checkPIErrors : function(component) {
        var errorMessage = "";
        var lead = component.get("v.lead");
        errorMessage += this.getFieldError(component, {'fieldValue': lead.FirstName,
                                                       'fieldId': "firstNameElement",
                                                       'errorMessage': "Enter your first name without special characters"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LastName,
                                                       'fieldId': "lastNameElement",
                                                       'errorMessage': "Enter your last name without special characters"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Phone,
                                                       'fieldId': "phoneElement",
                                                       'fieldType' : "phone",
                                                       'errorMessage': "Enter your phone number, e.g. 555-555-1212"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Email,
                                                       'fieldId': "emailElement",
                                                       'fieldType': "email",
                                                       'errorMessage': "Enter your email"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LASERCA__Home_Address__c,
                                                       'fieldId': "homeAddressElement",
                                                       'errorMessage': "Enter your street address"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LASERCA__Home_City__c,
                                                       'fieldId': "cityElement",
                                                       'errorMessage': "Enter your city"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LASERCA__Home_Zip__c,
                                                       'fieldId': "zipCodeElement",
                                                       'allowLetters': false,
                                                       'allowSpaces': false,
                                                       'errorMessage': "Enter your 5 digit zip code"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.lived_residence_six_months__c,
                                                       'fieldId': "ownHouseElement",
                                                       'fieldType': "uncheckedCheckbox",
                                                       'errorMessage': "You need to own the house where solar panels will be installed"});
        return errorMessage;
    },

    checkSSNErrors : function(component) {
        var errorMessage = "";
        var lead = component.get("v.lead");
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LASERCA__SSN__c,
                                                       'fieldId': "ssnElement",
                                                       'fieldType': "ssn",
                                                       'errorMessage': "Enter your nine digit social security number, e.g. 000-00-0000 or 123456789"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.LASERCA__Birthdate__c,
                                                       'fieldId': "birthdateElement",
                                                       'fieldType': "date",
                                                       'errorMessage': "Enter your birthdate, e.g. 01/01/1980"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Annual_Income_Currency__c,
                                                       'fieldId': "incomeElement",
                                                       'fieldType': "currency",
                                                       'errorMessage': "Enter your income, and 0 if you aren't reporting any income"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Monthly_Mortgage_Tax_and_Insurance__c,
                                                       'fieldId': "mortgageElement",
                                                       'fieldType': "currency",
                                                       'errorMessage': "Enter your approximate monthly mortgage, and 0 if you don't have a mortgage"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Credit_Check_Acknowledged__c,
                                                       'fieldId': "creditCheckElement",
                                                       'fieldType': "uncheckedCheckbox",
                                                       'errorMessage': "Please give permission to access your credit history"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.Privacy_Policy_Acknowledged__c,
                                                       'fieldId': "privacyPolicyElement",
                                                       'fieldType': "uncheckedCheckbox",
                                                       'errorMessage': "Please acknowledge privacy policies"});
        return errorMessage;
    },

    checkCoAppPIErrors : function(component) {
        var errorMessage = "";
        var lead = component.get("v.lead");
        var firstname = lead.CoApplicant_Contact__r.FirstName||'Co-Applicant';
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.FirstName,
                                                       'fieldId': "coAppFirstNameElement",
                                                       'errorMessage': "Enter the co-applicant's first name without special characters"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LastName,
                                                       'fieldId': "coAppLastNameElement",
                                                       'errorMessage': "Enter " + firstname + "'s last name without special characters"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.Phone,
                                                       'fieldId': "coAppPhoneElement",
                                                       'fieldType' : "phone",
                                                       'errorMessage': "Enter " + firstname + "'s phone number, e.g. 555-555-1212"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.Email,
                                                       'fieldId': "coAppEmailElement",
                                                       'fieldType': "email",
                                                       'errorMessage': "Enter " + firstname + "'s email"});
        if (!component.get("v.coAppAddressSame")) {
            errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Home_Address__c,
                                                           'fieldId': "coAppHomeAddressElement",
                                                           'errorMessage': "Enter " + firstname + "'s street address"});
            errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Home_City__c,
                                                           'fieldId': "coAppCityElement",
                                                           'errorMessage': "Enter " + firstname + "'s city"});
            errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Home_State__c,
                                                           'fieldId': "coAppStateElement",
                                                           'errorMessage': "Enter " + firstname + "'s state"});
            errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Home_Zip__c,
                                                           'fieldId': "coAppZipCodeElement",
                                                           'allowLetters': false,
                                                           'allowSpaces': false,
                                                           'errorMessage': "Enter " + firstname + "'s 5 digit zip code"});
        }
        return errorMessage;
    },

    checkCoAppSSNErrors : function(component) {
        var errorMessage = "";
        var lead = component.get("v.lead");
        var firstname = lead.CoApplicant_Contact__r.FirstName||'Co-Applicant';
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c,
                                                       'fieldId': "coAppSSNElement",
                                                       'fieldType': "ssn",
                                                       'errorMessage': "Enter " + firstname + "'s nine digit social security number, e.g. 000-00-0000 or 123456789"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.LASERCA__Co_Applicant_DOB__c,
                                                       'fieldId': "coAppBirthdateElement",
                                                       'fieldType': "date",
                                                       'errorMessage': "Enter " + firstname + "'s birthdate, e.g. 01/01/1980"});
        errorMessage += this.getFieldError(component, {'fieldValue': lead.CoApplicant_Contact__r.Income__c,
                                                       'fieldId': "coAppIncomeElement",
                                                       'fieldType': "currency",
                                                       'errorMessage': "Enter " + firstname + "'s income, and 0 if they aren't reporting any income"});
        return errorMessage;
    },

    saveLead : function(component, event, helper, options) {
        // Make a copy of the lead to update, since we can't update child objects
        // like CoApplicant_Contact
        var lead = component.get("v.lead");
        if (lead.LASERCA__SSN__c) {
            lead.LASERCA__SSN__c = lead.LASERCA__SSN__c.replace(/-/g,"");
        }
        if (lead.CoApplicant_Contact__r && lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c) {
            lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c =
                lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c.replace(/-/g,"");
        }
            
        var leadClone = helper.cleanLead(component);
        var leadPromise, contactPromise;

        if (lead.Application_Type__c === 'Joint') {
            if (lead.CoApplicant_Contact__r) {
                if (component.get("v.coAppAddressSame")) {
                    lead.CoApplicant_Contact__r.LASERCA__Home_Address__c = lead.LASERCA__Home_Address__c;
                    lead.CoApplicant_Contact__r.LASERCA__Home_City__c = lead.LASERCA__Home_City__c;
                    lead.CoApplicant_Contact__r.LASERCA__Home_State__c = lead.LASERCA__Home_State__c;
                    lead.CoApplicant_Contact__r.LASERCA__Home_Zip__c = lead.LASERCA__Home_Zip__c;
                }
                var contact = {sobjectType: 'Contact',
                               FirstName : lead.CoApplicant_Contact__r.FirstName,
                               LastName : lead.CoApplicant_Contact__r.LastName,
                               Phone: lead.CoApplicant_Contact__r.Phone,
                               Email: lead.CoApplicant_Contact__r.Email,
                               Lead__c: lead.Id,
                               LASERCA__Home_Address__c: lead.CoApplicant_Contact__r.LASERCA__Home_Address__c,
                               LASERCA__Home_City__c: lead.CoApplicant_Contact__r.LASERCA__Home_City__c,
                               LASERCA__Home_State__c: lead.CoApplicant_Contact__r.LASERCA__Home_State__c,
                               LASERCA__Home_Zip__c:  lead.CoApplicant_Contact__r.LASERCA__Home_Zip__c,
                               LASERCA__Social_Security_Number__c:
                               lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c,
                               LASERCA__Co_Applicant_DOB__c: lead.CoApplicant_Contact__r.LASERCA__Co_Applicant_DOB__c,
                               Income__c: lead.CoApplicant_Contact__r.Income__c,
                               Credit_Check_Acknowledged__c: lead.CoApplicant_Contact__r.Credit_Check_Acknowledged__c,
                               Privacy_Policy_Acknowledged__c: lead.CoApplicant_Contact__r.Privacy_Policy_Acknowledged__c,
                               Other_Bank_Executive__c: lead.CoApplicant_Contact__r.Other_Bank_Executive__c,
                               Avidia_Service_Provider__c: lead.CoApplicant_Contact__r.Avidia_Service_Provider__c,
                               Type_of_Avidia_Service_Provider__c: lead.CoApplicant_Contact__r.Type_of_Avidia_Service_Provider__c}
                if (leadClone.CoApplicant_Contact__c) {
                    contact.Id = leadClone.CoApplicant_Contact__c;
                    contactPromise = helper.saveSObject(component, contact.Id, 'Contact', null, null, contact);
                } else {
                    contactPromise = helper.insertSObject(component, contact);
                }
                contactPromise.then($A.getCallback(function resolve(retVal) {
                    delete leadClone['CoApplicant_Contact__r'];
                    helper.copyCoAppToLead(contact, lead);
                    helper.copyCoAppToLead(contact, leadClone);
                    lead.CoApplicant_Contact__c = retVal.Id;
                    leadClone.CoApplicant_Contact__c = retVal.Id;
                    return(helper.saveSObject(component, leadClone.Id, 'Lead', null, null, leadClone));
                })).then($A.getCallback(function resolve(retVal) {
                    helper.finishPage(component, event, helper, options);
                }));
            } else {
                leadPromise = helper.saveSObject(component, leadClone.Id, 'Lead', null, null, leadClone);
                leadPromise.then($A.getCallback(function resolve(retVal) {
                    helper.finishPage(component, event, helper, options);
                }));
            }
        } else {
            // Individual application, blank out CoApp info if it was set
            leadClone.CoApplicant_Contact__c = null;
            leadClone.Co_Applicant_First_Name__c = null;
            leadClone.Co_Applicant_Last_Name__c = null;
            leadClone.Co_Applicant_Phone__c = null;
            leadClone.Co_Applicant_Email__c = null;
            leadClone.Co_Applicant_Date_of_Birth__c = null;
            leadClone.Co_Applicant_Income__c = null;
            leadClone.Co_Applicant_Address__c = null;
            leadClone.Co_Applicant_Income__c = null;
            delete lead['CoApplicant_Contact__c'];
            delete lead['CoApplicant_Contact__r'];
            delete lead['CoApplicant_Contact__c'];
            delete lead['Co_Applicant_First_Name__c'];
            delete lead['Co_Applicant_Last_Name__c'];
            delete lead['Co_Applicant_Phone__c'];
            delete lead['Co_Applicant_Email__c'];
            delete lead['Co_Applicant_Date_of_Birth__c'];
            delete lead['Co_Applicant_Income__c'];
            delete lead['Co_Applicant_Address__c'];
            delete lead['Co_Applicant_Income__c'];
            leadPromise = helper.saveSObject(component, leadClone.Id, 'Lead', null, null, leadClone);
            leadPromise.then($A.getCallback(function resolve(value) {
                helper.finishPage(component, event, helper, options);
            }));
        }
    },

    copyCoAppToLead : function(contact, lead) {
        lead.Co_Applicant_First_Name__c = contact.FirstName;
        lead.Co_Applicant_Last_Name__c = contact.LastName;
        lead.Co_Applicant_Phone__c = contact.Phone;
        lead.Co_Applicant_Email__c = contact.Email;
        lead.Co_Applicant_Date_of_Birth__c = contact.LASERCA__Co_Applicant_DOB__c;
        lead.Co_Applicant_Income__c = contact.Income__c
        lead.Co_Applicant_Address__c =
            (contact.LASERCA__Home_Address__c||'') + ', ' +
            (contact.LASERCA__Home_City__c||'') + ', ' +
            (contact.LASERCA__Home_State__c||'') + ' ' +
            (contact.LASERCA__Home_Zip__c||'');
        lead.LASERCA__Social_Security_Number__c =
            contact.LASERCA__Social_Security_Number__c;
    },

    finishPage : function(component, event, helper, options) {
        if (options.finish) {
            helper.finishStage(component, event, helper);
        } else {
            component.set('v.page', options.nextPage);
        }
    },

})
