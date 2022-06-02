import {getUSStateOptionsFull} from 'c/util';
import findDuplicateUALs from '@salesforce/apex/SimpleSignupFormController.findDuplicateUALs';
import {toggleLoadingSpinnerEvent, modifySpinnerMessageEvent, postErrorLogEvent, resetReadyStateEvent, showGenericErrorToast} from "c/ssfShared";
import {makeRequest} from "c/httpRequestService";
import {accountInputMask} from 'c/inputMask';
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
    if (!cmp.restLead.customerType) {
        cmp.restLead.customerType = cmp.customerType;
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
        cmp.uanPrefix = selectedUtility.uanPrefix ? selectedUtility.uanPrefix : '';
        cmp.podIdPrefix = selectedUtility.podIdPrefix ? selectedUtility.podIdPrefix : '';
        cmp.uanLength = selectedUtility.uanLength;
        cmp.podIdLength = selectedUtility.podIdLength;
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

const resetUnderwriting = (component) => {
    resetUnderwritingOptions(component);
    resetApplicationUnderwriting(component);
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

const resetUnderwritingOptions = (component) => {
    component.underwritingOptions = [];
    if (component.selectedSystem.ficoUnderwriting) {
        component.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
    }
    if (component.selectedSystem.finDocsUnderwriting) {
        component.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
    }
}

const resetApplicationUnderwriting = (component) => {
    if (!component.selectedSystem.underwrite) {
        component.underwriting = 'None';
        component.restLead.underwritingCriteria = 'None';
        component.showUnderwritingOptions = false;
    }
    else if (component.resiApplicationType  || component.underwritingOptions.length === 0) {
        component.underwriting = 'FICO';
        component.restLead.underwritingCriteria = 'FICO';
        component.showUnderwritingOptions = false;
    }
    else if (!component.resiApplicationType) {
        if (component.underwritingOptions.length === 1) {
            // One underwriting option provided in zip check for SMB app
            let option = component.underwritingOptions[0].value;
            component.underwriting = option;
            component.restLead.underwritingCriteria = option;
        }
        else {
            // More than one underwriting option provided in zip check for SMB app - set default back to FICO
            component.underwriting = 'FICO';
            component.restLead.underwritingCriteria = null;
            component.showUnderwritingOptions = true;
        }
    }
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
    let utilityAccountLog = {
        localid: component.utilityAccountCount,
        name: `Utility Account ${component.utilityAccountCount}`,
        utilityId: component.utilityId,
        doNotDelete: false,
        showUpload: component.isFileUpload,
        utilityBills: [],
        utilityAccountNumber: component.uanPrefix,
        utilityAccountNumberReentry: component.uanPrefix
    };
    if (component.collectPOD) {
        utilityAccountLog.podId = component.podIdPrefix;
        utilityAccountLog.podIdReentry = component.podIdPrefix;
    }
    return utilityAccountLog;
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

const validateAddresses = async (cmp) => {
    try {
        const addresses = cmp.template.querySelectorAll('c-ssf-address');
        const resultMap = {};
        for (const address of addresses) {
            const objectName = address.objectName;
            const object = objectName === 'utilityAccountLog' ? cmp.propertyAccount.utilityAccountLogs[address.index] : cmp[objectName];
            if (object.hasOverride || !object.hasUnverifiedAddress) {
                // move on to next object if already user chose to override or address was already verified
                continue;
            }
            // get results from Google Geocoder API
            let result = await address.geocodeAddresses();
            if (result.isExactMatch) {
                // if address was entered correctly set lat/lng, remove unverified flag, reset override flag
                const latitudeField = addressFields[objectName]?.latitude;
                const longitudeField = addressFields[objectName]?.longitude;
                object[latitudeField] = result.latitude;
                object[longitudeField] = result.longitude;
                object.hasUnverifiedAddress = false;
                object.hasOverride = false;
            } else {
                // otherwise put together object address suggestions
                const key = objectName === 'utilityAccountLog' ? `utilityAccountLog${address.index}` : objectName;
                // map of object name to name for the validation modal headers
                const nameMap = {
                    'restLead': 'Contact Address',
                    'propertyAccount': 'Billing Address',
                    [`utilityAccountLog${address.index}`]: `Utility Account ${address.index + 1}`
                }
                const input = address.subpremise && address.subpremise.length ? `${address.street} ${address.subpremise}, ${address.city} ${address.state} ${address.zip}` : `${address.street}, ${address.city} ${address.state} ${address.zip}`;
                // map each object to its list of suggestions, object-specific field names, header name, current input, and subpremise
                resultMap[key] = {
                    addresses: result.addresses,
                    fields: addressFields[objectName],
                    name: nameMap[key],
                    input: input,
                    subpremise: address.subpremise
                };
            }
        }
        if (Object.keys(resultMap).length) {
            // open the validation modal if any objects weren't an exact match
            const modal = cmp.template.querySelector('c-ssf-address-validation-modal');
            modal.setSuggestions(resultMap);
            // open modal, hide loading spinner, and return to info view
            cmp.showAddressValidationModal = true;
            toggleLoadingSpinnerEvent(cmp, true, 'waitingRoom');
            cmp.dispatchEvent(new CustomEvent('readystate'));
            return false;
        }
        return true;
    } catch (error) {
        toggleLoadingSpinnerEvent(cmp, true, 'waitingRoom');
        cmp.dispatchEvent(new CustomEvent('readystate'));
        postErrorLogEvent(cmp, error, null, 'ssfBasicInfoShared', 'validateAddresses', 'Error');
        showGenericErrorToast(cmp);
        return false;
    }
}

const handleValidateAccountNumber = (cmp, event) => {
    const index = event.target.dataset.rowIndex;
    const eventField = event.target.name;
    const isUtilityAccountNumber = eventField === 'utilityAccountNumber';
    const type = isUtilityAccountNumber ? 'uan' : 'podId';
    const typeName = isUtilityAccountNumber ? 'Utility Account Number' : 'PoD ID value';
    const selectorName = isUtilityAccountNumber ? 'ual-number' : 'pod-id';
    const inputElement = cmp.template.querySelector(`[data-${selectorName}-index="${index}"]`);
    const numCleaned = cmp.propertyAccount.utilityAccountLogs[index][eventField].replaceAll(/[^a-zA-Z0-9]/g,'');

    // Set or clear error state on field if input is too short
    if (cmp[`${type}Length`] && numCleaned.length !== cmp[`${type}Length`]) {
        let numError = cmp[`${type}Prefix`].length ? `The ${typeName} must be ${cmp[`${type}Length`]} characters long, starting in ${cmp[`${type}Prefix`]}.` : `The ${typeName} must be ${cmp[`${type}Length`]} characters long.`;
        inputElement.setCustomValidity(numError);
        inputElement.reportValidity();
    } else {
        inputElement.setCustomValidity('');
        inputElement.reportValidity();
        if (isUtilityAccountNumber) {
            findDuplicateUAL(cmp,event);
        }
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

const setRemainingFields = (component, sameHomeAddressAsFirstUA) => {
    if (component.sameHomeAddress) {
        component.restLead.streetAddress = component.propertyAccount.utilityAccountLogs[0].serviceStreet;
        component.restLead.city = component.propertyAccount.utilityAccountLogs[0].serviceCity;
        component.restLead.state = component.propertyAccount.utilityAccountLogs[0].serviceState;
        component.restLead.zipCode = component.propertyAccount.utilityAccountLogs[0].servicePostalCode;
        component.restLead.hasUnverifiedAddress = component.propertyAccount.utilityAccountLogs[0].hasUnverifiedAddress;
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
    const ualNum = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumber.replaceAll(/[^a-zA-Z0-9]/g,'');
    const ualNumReentry = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumberReentry.replaceAll(/[^a-zA-Z0-9]/g,'');

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
    propertyAccount.hasUnverifiedAddress = propertyAccount.utilityAccountLogs[0].hasUnverifiedAddress;
    return propertyAccount;
}

const matchHomeAddress = (restLead, propertyAccount) => {
    restLead.streetAddress = propertyAccount.utilityAccountLogs[0].serviceStreet;
    restLead.city = propertyAccount.utilityAccountLogs[0].serviceCity;
    restLead.state = propertyAccount.utilityAccountLogs[0].serviceState;
    restLead.zipCode = propertyAccount.utilityAccountLogs[0].servicePostalCode;
    restLead.hasUnverifiedAddress = propertyAccount.utilityAccountLogs[0].hasUnverifiedAddress;
    return restLead;
}

const applicationValid = (cmp) => {

    validateContactEmail(cmp); // Check to ensure emails are valid

    let allValid = [...cmp.template.querySelectorAll('lightning-input'), ...cmp.template.querySelectorAll('lightning-combobox'), ...cmp.template.querySelectorAll('c-ssf-address')]
    .reduce((validSoFar, inputCmp) => {
        inputCmp.reportValidity();
        return validSoFar && inputCmp.checkValidity();
    }, true);

    if (cmp.isFileUpload) {
        let uploadValid = true;
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

const validateContactEmail = (cmp) => {
    const regex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    let contactEmailField = cmp.template.querySelector(`[data-field-name="contactEmail"]`);
    if (!cmp.restLead || !cmp.restLead.email) {
        // matches OOTB wording for checkValidity() error message
        contactEmailField.setCustomValidity('Complete this field.');
    } else if (!cmp.restLead.email.match(regex)) {
        contactEmailField.setCustomValidity('Invalid email address entered. Please check your inputs.');
    } else {
        contactEmailField.setCustomValidity('');
    }
    contactEmailField.reportValidity();
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
    let hasValidAddresses = await validateAddresses(cmp);
    if (!hasValidAddresses) {
        return;
    }
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
        toggleLoadingSpinnerEvent(cmp, true, 'waitingRoom');
        cmp.dispatchEvent(new CustomEvent('readystate'));
        postErrorLogEvent(cmp, error, null,'ssfBasicInfoShared', 'insertLead', 'Error');
        let errorObject = JSON.parse(error);
        if (errorObject.errors && errorObject.errors[0].includes('there is only capacity for customers living in a disadvantaged community')) {
            cmp.showSpinner = false;
            cmp.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorObject.errors[0],
                variant: 'warning'
            }));
            return;
        }
        showGenericErrorToast(cmp);
    }
}

const patchLead = async (cmp) => {
    try {
        let patchResult = await patchApplication(cmp.restLead);
        cmp.dispatchEvent(new CustomEvent('leadcreated', {detail: patchResult}));
    } catch (error) {
        toggleLoadingSpinnerEvent(cmp, true, 'waitingRoom');
        cmp.dispatchEvent(new CustomEvent('readystate'));
        postErrorLogEvent(cmp, error, null, 'ssfBasicInfoShared', 'patchLead', 'Error');
        showGenericErrorToast(cmp);
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

const handleAccountNumberInputMask = (cmp, event, type) => {
    const regexGroups = `${type}RegexGroups`;
    const format = `${type}Format`;
    const prefix = `${type}Prefix`;
    const length = `${type}Length`;
    if (!cmp.zipCheckResponse.utilities || !cmp.zipCheckResponse.utilities.length) {
        return;
    }
    let utility = cmp.zipCheckResponse.utilities[0];
    let maskedInput = accountInputMask(event.target.value, utility[regexGroups], utility[format], utility[prefix], utility[length]);
    event.target.value = maskedInput;
    cmp.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex][event.target.name] = maskedInput;
}

const handleSetAddress = (cmp, event) => {
    // called when user changes any address field input
    const objectName = event.detail.object;
    const object = objectName === 'utilityAccountLog' ? cmp.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex] : cmp[objectName];
    const field = event.detail.field;
    object[field] = event.detail.value;
    // reset unverified and override fields now that the address has changed
    // subpremise not a part of verification
    if (field === 'subpremise') {
        return;
    }
    object['hasUnverifiedAddress'] = true;
    object['hasOverride'] = false;
}

const handleUpdateAddresses = (cmp, event) => {
    // called when the user accepts or overrides changes from the ssfAddressValidationModal
    if (!event.detail.objects && !event.detail.objects.length) {
        return;
    }
    for (const objectInfo of event.detail.objects) {
        const objectName = objectInfo.objectName;
        const object = objectName.startsWith('utilityAccountLog') ? cmp.propertyAccount.utilityAccountLogs[parseInt(objectName.substring(17))] : cmp[objectName];
        for (const field in objectInfo.address) {
            object[field] = objectInfo.address[field];
        }
    }
    // focus on street field to get user attention
    let element;
    const objectName = event.detail.objects[0].objectName;
    if (objectName.startsWith('utilityAccountLog')) {
        element = cmp.template.querySelector(`c-ssf-address[data-object="utilityAccountLog"][data-row-index="${objectName.substring(17)}"]`);
    } else {
        element = cmp.template.querySelector(`c-ssf-address[data-object="${objectName}"]`);
    }
    element.focusStreet();
}

// map of object name to object-specific field names so address fields can be set dynamically
const addressFields = {
    'restLead': {
        street: 'streetAddress',
        city: 'city',
        state: 'state',
        zipCode: 'zipCode'
    },
    'propertyAccount': {
        street: 'billingStreet',
        city: 'billingCity',
        state: 'billingState',
        zipCode: 'billingPostalCode'
    },
    'utilityAccountLog': {
        street: 'serviceStreet',
        city: 'serviceCity',
        state: 'serviceState',
        zipCode: 'servicePostalCode',
        latitude: 'latitude',
        longitude: 'longitude'
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
    applicationValid,
    onLoad,
    findDuplicateUAL,
    getText,
    submitApplication,
    validateContactEmail,
    handleAccountNumberInputMask,
    handleValidateAccountNumber,
    handleSetAddress,
    handleUpdateAddresses,
    resetUnderwriting,
    addressFields
}