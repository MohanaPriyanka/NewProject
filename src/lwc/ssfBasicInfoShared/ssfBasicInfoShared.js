import {getUSStateOptionsFull} from 'c/util';
import findDuplicateUALs from '@salesforce/apex/SimpleSignupFormController.findDuplicateUALs';
import { toggleLoadingSpinnerEvent, modifySpinnerMessageEvent, handlePromiseError, resetReadyStateEvent } from "c/ssfShared";
import {makeRequest} from "c/httpRequestService";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

// Perform tasks when first instancing component
const onLoad = (cmp) => {
    handleZipCheck(cmp);
    handleNewOrExistingApp(cmp);
    setUnderwriting(cmp, cmp.resumedApp);

    if (!cmp.restLead.partnerId) {
        cmp.restLead.partnerId = cmp.partnerId;
    }
    if (!cmp.restLead.salesRepId) {
        cmp.restLead.salesRepId = cmp.salesRepId;
    }
    if (!cmp.restLead.campaignId) {
        cmp.restLead.campaignId = cmp.campaignId;
    }
    // if there are no utility accounts, add an empty one so the form will show fields to enter data
    if (cmp.propertyAccount && cmp.propertyAccount.utilityAccountLogs
        && cmp.propertyAccount.utilityAccountLogs.length === 0) {
        cmp.addUtilityAccount();
    }
    // set the values to properly display the utility portion of the form
    cmp.utilityAccountCount = cmp.propertyAccount.utilityAccountLogs.length;
    cmp.utilityAccountSection = cmp.utilityAccountCount;

    // if certain property values didn't come in from the api, find their values
    if (!cmp.stateOptions) {
        cmp.stateOptions = getUSStateOptionsFull();
    }
}

const handleZipCheck = (cmp) => {
    if (!cmp.zipCheckResponse) {
        return;
    }
    cmp.zipCheckResponse = JSON.parse(cmp.zipCheckResponse);
    cmp.collectRateClass = cmp.zipCheckResponse.collectRateClass;

    // Set ZIP Code
    if (cmp.zipCheckResponse.zipCode) {
        cmp.zipinput = cmp.zipCheckResponse.zipCode;
    }
    // Set Product
    if (cmp.zipCheckResponse.products && cmp.zipCheckResponse.products.length > 0) {
        cmp.selectedProduct = cmp.zipCheckResponse.products[0];
    }
    // Set Utility, Data Collection Method
    if (cmp.zipCheckResponse.utilities && cmp.zipCheckResponse.utilities.length > 0 && cmp.zipCheckResponse.utilities[0].utilityId) {
        let selectedUtility = cmp.zipCheckResponse.utilities[0];
        cmp.utilityId = selectedUtility.utilityId;
        if (selectedUtility.dataCollectionMethod) {
            cmp.isFileUpload = (selectedUtility.dataCollectionMethod !== 'EDI');
        }
        else {
            cmp.isFileUpload = true;
        }
    } else {
        cmp.isFileUpload = true;
    }
    // Set Rate Classes, if needed
    if (cmp.zipCheckResponse.rateClasses) {
        cmp.rateClassObj = Object.fromEntries(cmp.zipCheckResponse.rateClasses.map(
            rateClass => ([rateClass.name, rateClass])
        ));
        if (cmp.collectRateClass) {
            if (cmp.zipCheckResponse.rateClasses.length === 0) {
                cmp.collectRateClass = false;
            }
            else {
                cmp.rateClassOptions = cmp.zipCheckResponse.rateClasses.map(
                    rateClass => ({ value: rateClass.name, label: rateClass.name })
                );
            }
        }
    }
    // Toggle if PoD ID should be collected (new applications only... see resumeAppSetOtherParams() for resume apps)
    if (cmp.zipCheckResponse.collectPOD) {
        cmp.collectPOD = true;
    }
}

const handleNewOrExistingApp = (cmp) => {
    // if a lead has already been created, have the form show existing values
    if (cmp.leadJson) {
        cmp.resumedApp = true;
        cmp.restLead = JSON.parse(cmp.leadJson);
        cmp.propertyAccount = cmp.restLead.propertyAccounts[0];
        resumeAppSetUALs(cmp);
        resumeAppSetAddressFlags(cmp);
    }
    // if no lead exists, set default values for restLead and propertyAccount
    else {
        cmp.restLead = getNewRestLead(cmp);
        cmp.propertyAccount = getNewRestPropertyAccount(cmp);
    }
}

const resumeAppSetUALs = (cmp) => {
    if (cmp.propertyAccount.utilityAccountLogs) {
        let account = cmp.propertyAccount;
        for (let i=0; i < account.utilityAccountLogs.length; i++) {
            account.utilityAccountLogs[i].localid = i+1;
            account.utilityAccountLogs[i].name = `Utility Account ${i+1}`;
            account.utilityAccountLogs[i].doNotDelete = true;
            account.utilityAccountLogs[i].showUpload = cmp.isFileUpload &&
                (!account.utilityAccountLogs[i].utilityBills || account.utilityAccountLogs[i].utilityBills.length === 0);
            account.utilityAccountLogs[i].utilityAccountNumberReentry = account.utilityAccountLogs[i].utilityAccountNumber;
            account.utilityAccountLogs[i].podIdReentry = account.utilityAccountLogs[i].podId;

            if (account.utilityAccountLogs[i].rateClass) {
                cmp.selectedRateClasses.push(cmp.rateClassObj[account.utilityAccountLogs[i].rateClass]);
            }
        }
    }
}

const resumeAppSetAddressFlags = (cmp) => {
    const firstUal = cmp.propertyAccount.utilityAccountLogs[0];
    const leadBillingStreetZip = `${cmp.propertyAccount.billingStreet} ${cmp.propertyAccount.billingPostalCode}`;
    const leadContactStreetZip = `${cmp.restLead.streetAddress} ${cmp.restLead.zipCode}`;
    const leadFirstUalStreetZip = `${firstUal.serviceStreet} ${firstUal.servicePostalCode}`;
    cmp.sameBillingAddress = leadBillingStreetZip === leadFirstUalStreetZip;
    cmp.sameHomeAddress = leadContactStreetZip === leadFirstUalStreetZip;
}

const getFinDocFileTypes = () => {
    return ['.png', '.jpg', '.jpeg', '.pdf', '.zip'];
}

const getUnderwritingHelpText = () => {
    return '<p>Guarantor (FICO) underwriting is only available for a select group of customers. Please select Financial Documents if the applicant’s annual cost exceeds the amount below for their utility and rate class:' +
    '<ul><br>' +
    '   <li>CMP – Small Commercial: $55,000</li>' +
    '   <li>CMP – Medium Commercial: $55,000</li>' +
    '   <li>Versant Bangor Hydro – Small Commercial: $60,000</li>' +
    '   <li>Versant Bangor Hydro – Medium Commercial: $60,000</li>' +
    '   <li>Versant Maine Public – Small Commercial: $50,000</li>' +
    '   <li>Versant Maine Public – Medium Commercial: $50,000</li>' +
    '</ul></p>';
}

const setUnderwriting = (component, resumedApp) => {
    if (!resumedApp) {
        newApplicationUnderwriting(component);
    } else {
        resumedAppUnderwriting(component);
    }
    handleUnderwritingChange(component);
}

const newApplicationUnderwriting = (component) => {
    if (!component.zipCheckResponse.underwrite) {
        component.underwriting = 'None';
        component.restLead.underwritingCriteria = 'None';
    }
    else if (component.resiApplicationType  || component.underwritingOptions.length === 0) {
        component.underwriting = 'FICO';
        component.restLead.underwritingCriteria = 'FICO';
    }
    else if (!component.resiApplicationType) {
        if (component.underwritingOptions.length === 1) {
            // One underwriting option provided in zip check for SMB app
            let option = component.underwritingOptions[0].value;
            component.underwriting = option;
            component.restLead.underwritingCriteria = option;
        }
        else {
            // More than one underwriting option provided in zip check for SMB app
            component.showUnderwritingOptions = true;
        }
    }
}

const resumedAppUnderwriting = (component) => {
    // For resumed apps (or back button movement), set underwriting based on Lead data and disable modification
    component.showUnderwritingOptions = false;
    component.underwriting = component.restLead.underwritingCriteria;
    component.disableUnderwritingFields = true;
}

// notify parent ssf/ssfDTC of underwriting option to pass to ssfAgreements/ssfAgreementsDTC
const handleUnderwritingChange = (component) => {
    const underwritingChangeEvent = new CustomEvent('underwritingchange', {detail: component.underwriting});
    component.dispatchEvent(underwritingChangeEvent);
}

const getNewRestLead = (component) => {
    return {
        applicationType: component.resiApplicationType ? 'Residential' : 'Non-Residential',
        zipCode: component.zipinput,
        productName: component.selectedProduct.name,
        utilityId: component.utilityId,
        financialDocs: [],
        noPayment: !component.zipCheckResponse.collectPayment,
    }
}

const getNewRestPropertyAccount = (component) => {
    return {
        billingPostalCode: component.resiApplicationType ? '' : component.zipinput,
        utilityAccountLogs: []
    }
}

const getNewRestUtilityAccountLog = (component) => {
    return {
        localid: component.utilityAccountCount,
        name: `Utility Account ${component.utilityAccountCount}`,
        utilityId: component.utilityId,
        doNotDelete: false,
        showUpload: component.isFileUpload,
        utilityBills: []
    }
}

const validateUtilityAccountLog = (cmp, index) => {
    let ualDomElements = [...cmp.template.querySelectorAll(`[data-row-index="${index}"]`)];
    return ualDomElements.reduce((validSoFar, inputCmp) => {
        let domElementValid = true;
        if (inputCmp.nodeName !== 'C-SSF-FILE-UPLOAD') {
            inputCmp.reportValidity();
            domElementValid = inputCmp.checkValidity();
        }
        return validSoFar && domElementValid;
    }, true);
}

const validateServiceZipCode = (cmp, event) => {
    let fieldsToDisplayError = [];
    let fieldsToClearError = [];
    let zipCodeInput = cmp.zipinput;

    if (event !== null) {
        // Perform realtime validation for single field change onblur
        const index = event.target.dataset.rowIndex;
        checkIfZipcodeSupported(cmp, index, fieldsToDisplayError, fieldsToClearError);
    } else {
        // Perform validation for every UAL's zipcode field
        const utilityAccountLogs = cmp.propertyAccount.utilityAccountLogs;
        for (let index=0; index < utilityAccountLogs.length; index++) {
            checkIfZipcodeSupported(cmp, index, fieldsToDisplayError, fieldsToClearError);
        }
    }

    if (fieldsToDisplayError.length !== 0) {
        let error = `Invalid ZIP Code or ZIP Code not in the same Utility area as the previously-entered ZIP Code ${zipCodeInput}. 
            Please enter a ZIP Code in the same Utility area as ${zipCodeInput} or restart your application.`;
        fieldsToDisplayError.forEach(fieldElement => {
            fieldElement.setCustomValidity(error);
            fieldElement.reportValidity();
        });
    }
    if (fieldsToClearError.length !== 0) {
        fieldsToClearError.forEach(fieldElement => {
            fieldElement.setCustomValidity('');
            fieldElement.reportValidity();
        });
    }
}

const findDuplicateUAL = (cmp, event) => {
    const index = event.target.dataset.rowIndex;
    let enteredAccountNumber = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumber;
    findDuplicateUALs({ualNumber: enteredAccountNumber})
    .then(result => {
        if (result === 'No Duplicate Found') {
            //clear error messages
            let field = cmp.template.querySelector(`[data-ual-number-index="${index}"]`);
            field.setCustomValidity('');
            field.reportValidity();
        } else if (result === 'Application in Review') {
            let error = 'An application has already been submitted for this Utility Account';
            let field = cmp.template.querySelector(`[data-ual-number-index="${index}"]`);
            field.setCustomValidity(error);
            field.reportValidity();
        } else {
            // found incomplete duplicate SSF Application
            // show modal that allows user to send continue application email
            let error = 'An application is already in process for this Utility Account.';
            let field = cmp.template.querySelector(`[data-ual-number-index="${index}"]`);
            field.setCustomValidity(error);
            field.reportValidity();
            cmp.showModal = true;
            cmp.duplicateLeadId = result;
        }
    })
    .catch(error => {
        //no duplicate found - continue as usual
    });
}

const checkIfZipcodeSupported = (cmp, index, fieldsToDisplayError, fieldsToClearError) => {
    const zipCodesSupported = cmp.zipCheckResponse.utilityZipCodesServed;
    let enteredZipCode = cmp.propertyAccount.utilityAccountLogs[index].servicePostalCode;
    if (!zipCodesSupported.includes(enteredZipCode)) {
        fieldsToDisplayError.push(locateZipCodeField(cmp, index));
    } else {
        fieldsToClearError.push(locateZipCodeField(cmp, index));
    }
}

const locateZipCodeField = (cmp, index) => {
    return cmp.template.querySelector(`[data-ual-zip-index="${index}"]`);
}

const setRemainingFields = (component, sameHomeAddressAsFirstUA) => {
    if (component.sameHomeAddress) {
        component.restLead.streetAddress = component.propertyAccount.utilityAccountLogs[0].serviceStreet;
        component.restLead.city = component.propertyAccount.utilityAccountLogs[0].serviceCity;
        component.restLead.state = component.propertyAccount.utilityAccountLogs[0].serviceState;
        component.restLead.zipCode = component.propertyAccount.utilityAccountLogs[0].servicePostalCode;
    }
    if (component.sameBillingAddress) {
        component.propertyAccount = matchBillingAddress(component.propertyAccount);
    }
    if (sameHomeAddressAsFirstUA) {
        component.restLead = matchHomeAddress(component.restLead, component.propertyAccount);
    }
    component.propertyAccount.name = component.resiApplicationType ? `${component.restLead.firstName} ${component.restLead.lastName}` : component.restLead.businessName;
    component.restLead.propertyAccounts = [component.propertyAccount];
}

const verifyUtilityAccountEntry = (cmp, event, eventField) => {
    // Retrieve DOM element for UA# re-entry field
    const index = event.target.dataset.rowIndex;
    let ualNumReentryInputElement = cmp.template.querySelector(`[data-ual-number-reentry-index="${index}"]`);

    // Retrieve current stored values for input fields
    const ualNum = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumber.replaceAll('-','');
    const ualNumReentry = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumberReentry.replaceAll('-','');

    // Retrieve state booleans... assess if we want to run validation in real-time
    const ualNumChangeValidate = eventField === 'utilityAccountNumber' && !!ualNumReentry;
    const ualNumReentryChangeValidate = eventField === 'utilityAccountNumberReentry' && !!ualNum;

    // Set or clear error state on Re-entry field if conditions we are monitoring are subject to validation
    if (ualNumChangeValidate || ualNumReentryChangeValidate) {
        if (ualNum !== ualNumReentry) {
            ualNumReentryInputElement.setCustomValidity('The Utility Account Numbers you entered do not match');
        } else {
            ualNumReentryInputElement.setCustomValidity('');
        }
        ualNumReentryInputElement.reportValidity();
    }
}

const verifyPODEntry = (cmp, event, eventField) => {
    // Retrieve DOM element for POD ID re-entry field
    const index = event.target.dataset.rowIndex;
    let podIdReentryInputElement = cmp.template.querySelector(`[data-pod-id-reentry-index="${index}"]`);

    // Retrieve current stored values for input fields
    const podId = cmp.propertyAccount.utilityAccountLogs[index].podId;
    const podIdReentry = cmp.propertyAccount.utilityAccountLogs[index].podIdReentry;

    // Retrieve state booleans... assess if we want to run validation in real-time
    const podIdChangeValidate = eventField === 'podId' && !!podIdReentry;
    const podIdReentryChangeValidate = eventField === 'podIdReentry' && !!podId;

    // Set or clear error state on Re-entry field if conditions we are monitoring are subject to validation
    if (podIdChangeValidate || podIdReentryChangeValidate) {
        if (podId !== podIdReentry) {
            podIdReentryInputElement.setCustomValidity('The PoD ID values you entered do not match');
        } else {
            podIdReentryInputElement.setCustomValidity('');
        }
        podIdReentryInputElement.reportValidity();
    }
}

const matchBillingAddress = (propertyAccount) => {
    propertyAccount.billingStreet = propertyAccount.utilityAccountLogs[0].serviceStreet;
    propertyAccount.billingCity = propertyAccount.utilityAccountLogs[0].serviceCity;
    propertyAccount.billingState = propertyAccount.utilityAccountLogs[0].serviceState;
    propertyAccount.billingPostalCode = propertyAccount.utilityAccountLogs[0].servicePostalCode;
    return propertyAccount;
}

const matchHomeAddress = (restLead, propertyAccount) => {
    restLead.streetAddress = propertyAccount.utilityAccountLogs[0].serviceStreet;
    restLead.city = propertyAccount.utilityAccountLogs[0].serviceCity;
    restLead.state = propertyAccount.utilityAccountLogs[0].serviceState;
    restLead.zipCode = propertyAccount.utilityAccountLogs[0].servicePostalCode;
    return restLead;
}

const applicationValid = (cmp) => {
    // Check all UAL zips, even if on a resume app, to ensure we service those zips
    validateServiceZipCode(cmp, null);

    var allValid = [...cmp.template.querySelectorAll('lightning-input'), ...cmp.template.querySelectorAll('lightning-combobox')]
    .reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    if (cmp.isFileUpload) {
        var uploadValid = true;
        cmp.propertyAccount.utilityAccountLogs.forEach(ual => {
            if (!ual.utilityBills || ual.utilityBills.length === 0) {
                uploadValid = false;
            }
        });
        if (!uploadValid) {
            allValid = false;
            cmp.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
                if (element.categoryType === 'Customer Utility Bill') {
                    element.addError();
                }
            });
        }
    }
    if (!cmp.resiApplicationType && cmp.underwriting === 'Financial Review' &&
        (!cmp.restLead.financialDocs || cmp.restLead.financialDocs.length === 0))
    {
        cmp.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
            if (element.categoryType === 'Financial Review Documents') {
                element.addError();
            }
        });
    }

    if (!allValid) {
        showWarningToast(cmp,'Warning!', 'Please verify your application before submitting');
        return false;
    }

    cmp.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
        element.removeError();
    });
    return true;
}

const showWarningToast = (cmp, title, message) => {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: 'warning',
        mode: 'pester',
        duration: 3000,
    });
    cmp.dispatchEvent(evt);
}

const submitApplication = async (cmp, partnerVersion) => {
    if (!applicationValid(cmp)) {
        return;
    }
    resetReadyStateEvent(cmp);
    if (partnerVersion) {
        modifySpinnerMessageEvent(cmp, 'Saving the application...');
        toggleLoadingSpinnerEvent(cmp, false);
        window.setTimeout(() => {
            modifySpinnerMessageEvent(cmp,`We'll generate documents next.\r\nThis may take a minute, please stand by.`);
        }, 4000);
    } else {
        toggleLoadingSpinnerEvent(cmp, false, 'waitingRoom');
    }

    // set remaining fields on restLead, including some address fields
    setRemainingFields(cmp, false);
    if (!cmp.resumedApp) {
        await insertLead(cmp);
    }
    else {
        await patchLead(cmp);
    }
}

const insertLead = async (cmp) => {
    try {
        let insertResult = await createLead(cmp.restLead);
        cmp.dispatchEvent(new CustomEvent('leadcreated', { detail: insertResult }));
    } catch (error) {
        cmp.dispatchEvent(new CustomEvent('readystate'));
        handlePromiseError(cmp, error, 'insertLead', 'Error');
    }
}

const patchLead = async (cmp) => {
    try {
        let patchResult = await patchApplication(cmp.restLead);
        cmp.dispatchEvent(new CustomEvent('leadcreated', {detail: patchResult}));
    } catch (error) {
        cmp.dispatchEvent(new CustomEvent('readystate'));
        toggleLoadingSpinnerEvent(cmp, true);
        handlePromiseError(cmp, error, 'patchLead', 'Error');
    }
}

const createLead = (restLead) => {
    let calloutURI = '/apply/services/apexrest/v3/leads';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify(restLead)
    };
    return makeRequest(calloutURI, 'POST', options);
};

const patchApplication = (restLead) => {
    let calloutURI = '/apply/services/apexrest/v3/application';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify(restLead)
    };
    return makeRequest(calloutURI, 'PATCH', options);
};

const getText = (cmp, identifier) => {
    switch (identifier) {
        case 'underwritingHelptext':
            return getUnderwritingHelpText();
        case 'ualNumLabel':
            return getUalNumFieldLabel(cmp);
        case 'ualNumReentryLabel':
            return getUalNumReentryFieldLabel(cmp);
        case 'podLabel':
            return getPodFieldLabel(cmp);
        case 'podReentryLabel':
            return getPodReentryFieldLabel(cmp);
        case 'businessNameLabel':
            return getBusinessNameLabel(cmp);
        case 'businessTitleLabel':
            return getJobTitleFieldLabel(cmp);
        default:
            return null;
    }
}

const getUalNumFieldLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Large') {
        return 'Utility Account Number';
    }
    else {
        return 'Account Number';
    }
}

const getUalNumReentryFieldLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Small' || formFactor === 'Medium') {
        return 'Re-Enter Account #';
    }
    else {
        return 'Re-Enter Utility Account Number';
    }
}

const getPodFieldLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Small' || formFactor === 'Medium') {
        return 'Point of Delivery ID';
    }
    else {
        return 'Point of Delivery ID (PoD)';
    }
}

const getPodReentryFieldLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Small' || formFactor === 'Medium') {
        return 'Re-Enter PoD ID';
    }
    else {
        return 'Re-Enter Point of Delivery ID';
    }
}

const getBusinessNameLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Large') {
        return 'Name of Business or Organization';
    } else {
        return 'Name of Business';
    }
}

const getJobTitleFieldLabel = (cmp) => {
    const formFactor = cmp.formFactor;
    if (formFactor === 'Medium' || formFactor === 'Small') {
        return 'Job Title or Affiliation';
    } else {
        return 'Job Title or Organizational Affiliation';
    }
}

export {
    getFinDocFileTypes,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    setRemainingFields,
    handleUnderwritingChange,
    verifyUtilityAccountEntry,
    verifyPODEntry,
    validateServiceZipCode,
    applicationValid,
    onLoad,
    findDuplicateUAL,
    getText,
    submitApplication
}