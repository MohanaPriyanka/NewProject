import { makeRequest } from 'c/httpRequestService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertLog from '@salesforce/apex/Logger.insertLog';
import { getZipCodeCapacity } from 'c/zipCodeService';

const loadApplication = (component) => {
    // If no URL parameters set, provide default experience
    const urlParams = component.pageRef.state;
    if (!urlParams || !component.pageRef) {
        component.showGetZipCodeCapacityPage();
        return;
    }

    // Set misc properties based on URL params, if they exist
    if (urlParams.partnerId) {
        component.resiApplicationType = false;
        component.partnerId = urlParams.partnerId;
    }
    if (urlParams.salesRepId) {
        component.salesRepId = urlParams.salesRepId;
    }
    if (urlParams.campaignId) {
        component.campaignId = urlParams.campaignId;
    }
    if (urlParams.mock) {
        component.mock = urlParams.mock;
    }

    // If resuming an application, process passed-in lead id & other details
    // Otherwise, provide default experience with or without zip already entered
    if (urlParams.leadid) {
        component.leadId = urlParams.leadid;
        component.loc = urlParams.loc ? urlParams.loc : '';
        processResumeAppLink(component, urlParams);
    } else {
        component.zipCodeInput = urlParams.zip ? urlParams.zip : '';
        component.showGetZipCodeCapacityPage();
    }
}

const processResumeAppLink = (component, urlParams) => {
    if (urlParams.email) {
        component.email = urlParams.email;
        if (!component.leadJSON) {
            retrieveApplication(component);
        }
    } else {
        // lead provided without email, need to verify applicant email for security purposes
        component.showEnterEmailPage();
    }
}

// Get application (Lead) from database and post-process for resumed application
const retrieveApplication = async (component) => {
    component.showSpinner = true;
    component.spinnerMessage = 'Retrieving your application...';

    // Get Lead record from server corresponding to application
    let leadPromise;
    try {
        leadPromise = await getLead(component, component.leadId, component.email);
        component.leadJSON = JSON.stringify(leadPromise);
    } catch (error) {
        let fail = typeof error === 'object' ? error : JSON.parse(error);
        if (fail.errors[0].substr(0,21) === 'Invalid authorization') {
            showInvalidAuthorizationToast(component);
        } else {
            handlePromiseError(component, error, 'getLead', 'Error');
        }
        return;
    }

    // Set component parameters based on retrieved Lead
    component.zipCodeInput = leadPromise.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode;
    component.resiApplicationType = leadPromise.applicationType === 'Residential';
    component.isFico = setIsFico(component.resiApplicationType, leadPromise.underwritingCriteria);

    // Check zip code capacity and set component fields based on result
    let zipPromise;
    try {
        zipPromise = await checkZipCodeCapacity(component);
        component.zipCodeResponse = JSON.stringify(zipPromise);
    } catch (error) {
        handlePromiseError(component, error, 'getZipCodeCapacity', 'Error');
        return;
    }

    // Set component parameters based on retrieved zipcode check
    if (zipPromise.ficoUnderwriting) {
        component.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
    }
    if (zipPromise.finDocsUnderwriting) {
        component.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
    }

    // Set application page to start on based on URL params, lead, and capacity
    setLocation(component);

    component.showSpinner = false;
}

const getLead = async (component, leadId, email) => {
    let calloutURI = '/apply/services/apexrest/v3/leads?leadId=' + leadId + '&email=' + email;
    let options = {
        headers: {name: 'Content-Type', value:'application/json'}
    };
    return makeRequest(calloutURI, 'GET', options);
}

const handlePromiseError = (component, promiseRejection, methodName, severity) => {
    insertLog({
        className: 'ssf',
        methodName: methodName,
        message: JSON.stringify(promiseRejection),
        severity: severity
    });
    showGenericErrorToast(component);
}

const showInvalidAuthorizationToast = (component) => {
    component.showSpinner = false;
    component.dispatchEvent(new ShowToastEvent({
        title: 'Authentication Failure',
        message: 'The email address you provided does not match the application on file.',
        variant: 'warning'
    }));
}

const showGenericErrorToast = (component) => {
    component.showSpinner = false;
    component.dispatchEvent(new ShowToastEvent({
        title: 'Sorry, we ran into a technical problem',
        message: 'Please contact Customer Care for help',
        variant: 'warning'
    }));
}

const setIsFico = (resiApplicationType, underwritingMethodSelected) => {
    // if residential app, leave default isFico = true on application
    if (resiApplicationType) {
        return true;
    }
    // if SMB app, check for underwriting method selected previously, or leave as default
    switch (underwritingMethodSelected) {
        case 'Financial Review' :
            return false;
        default :
            return true;
    }
}

const checkZipCodeCapacity = async (component) => {
    const utilityId = component.leadJSON.utilityId;
    return getZipCodeCapacity(component.zipCodeInput, component.partnerId, utilityId);
}

const setLocation = (component) => {
    let lead = JSON.parse(component.leadJSON);
    const zipcodeResponse = JSON.parse(component.zipCodeResponse);
    const location = component.loc;
    const basicInfoValidation = validateBasicInfoCompleted(zipcodeResponse, lead, location);

    if (!basicInfoValidation.isValid) {
        if (basicInfoValidation.detail === 'no_capacity') {
            //TODO: show error screen
            component.showBasicInfoPage();
        } else {
            component.showBasicInfoPage();
        }
        return;
    }

    switch (location) {
        case 'pay' :
            component.showPaymentPage();
            break;
        case 'agree' :
            component.showAgreementsPage();
            break;
        default :
            component.showBasicInfoPage();
    }
}

// Verify that all basic info fields are complete before advancing in the application
const validateBasicInfoCompleted = (capacity, lead, loc) => {

    // First verify that capacity exists and we have all required fields
    const hasCapacity = capacity.hasCapacity && !!capacity.products && capacity.products.length !== 0;
    const hasUtilities = !!capacity.utilities && !!lead.utilityId;
    const hasCapacityZip = !!capacity.zipCode;

    if (!hasCapacity || !hasUtilities || !hasCapacityZip) {
        if (loc !== 'pay') { // For payment page, let user through, they have already signed contract
            return validationFailure('no_capacity');
        }
    }

    if (!lead.firstName) {
        return validationFailure('missing_firstName');
    }
    if (!lead.lastName) {
        return validationFailure('missing_lastName');
    }
    if (!lead.email) {
        return validationFailure('missing_email');
    }
    if (!lead.productName) {
        return validationFailure('missing_productName');
    }
    if (lead.applicationType !== 'Residential' && lead.applicationType !== 'Non-Residential') {
        return validationFailure('invalid_applicationType');
    }
    if (lead.applicationType !== 'Residential' && (!lead.businessName || !lead.businessTitle)) {
        return validationFailure('missing_businessNameOrTitle');
    }
    if (!lead.propertyAccounts || lead.propertyAccounts.length === 0) {
        return validationFailure('missing_propertyAccount');
    }

    for (let i=0; i<lead.propertyAccounts.length; i++) {
        const propertyAccount = lead.propertyAccounts[i];
        if (!propertyAccount.billingStreet || !propertyAccount.billingCity
            || !propertyAccount.billingState || !propertyAccount.billingPostalCode) {
            return validationFailure('missing_propertyAccountAddress');
        }
        if (!propertyAccount.utilityAccountLogs || propertyAccount.utilityAccountLogs.length === 0) {
            return validationFailure('missing_UAL');
        }
        for (let j=0; j<propertyAccount.utilityAccountLogs.length; j++) {
            const ual = propertyAccount.utilityAccountLogs[j];
            if (!ual.nameOnAccount || !ual.serviceStreet || !ual.serviceCity
                || !ual.serviceState || !ual.servicePostalCode) {
                return validationFailure('missing_UALaddress');
            }
        }
    }

    // default validation pass if reached
    return {
        isValid: true,
        detail: null
    };
}

const validationFailure = (reason) => {
    return {
        isValid: false,
        detail: reason
    };
}

export {
    loadApplication,
    retrieveApplication
}