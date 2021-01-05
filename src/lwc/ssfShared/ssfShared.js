import {makeRequest} from 'c/httpRequestService';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import insertLog from '@salesforce/apex/Logger.insertLog';
import getZipcodeDataForResumeApp from '@salesforce/apex/SimpleSignupFormController.getZipcodeDataForResumeApp';

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
        component.zipCodeInput = leadPromise.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode;
        component.resiApplicationType = leadPromise.applicationType === 'Residential';
        component.underwriting = leadPromise.underwritingCriteria;
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

    // Retrieve ZIP Code data on resumed application if on info or agree page
    // Current screens beyond 'agree' do not require zipcode data (applicant already signed)
    if (component.loc === 'info' || component.loc === 'agree') {
        try {
            component.zipCodeResponse = await getZipcodeDataForResumeApp({
                zip: component.zipCodeInput,
                utilityId: JSON.parse(component.leadJSON).utilityId,
            });
        } catch (error) {
            handlePromiseError(component, error, 'getZipCodeData', 'Error');
        }
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

const setLocation = (component) => {
    switch (component.loc) {
        case 'info':
            component.showBasicInfoPage();
            break;
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

export {
    loadApplication,
    retrieveApplication
}