import {getUSStateOptionsFull} from 'c/util';

// Perform tasks when first instancing component
const onLoad = (cmp) => {

    handleZipCheck(cmp);
    handleNewOrExistingApp(cmp);
    setComponentUnderwritingVals(cmp);

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
    if (cmp.mock) {
        mockData(cmp);
    }
}

const handleZipCheck = (cmp) => {
    if (cmp.zipCheckResponse) {
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
    }
}

const handleNewOrExistingApp = (cmp) => {
    // if a lead has already been created, have the form show existing values
    if (cmp.leadJson) {
        cmp.resumedApp = true;
        cmp.restLead = JSON.parse(cmp.leadJson);
        cmp.propertyAccount = cmp.restLead.propertyAccounts[0];
        if (cmp.propertyAccount.utilityAccountLogs) {
            let account = cmp.propertyAccount;
            for (let i=0; i < account.utilityAccountLogs.length; i++) {
                account.utilityAccountLogs[i].localid = i+1;
                account.utilityAccountLogs[i].name = `Utility Account ${i+1}`;
                account.utilityAccountLogs[i].doNotDelete = true;
                account.utilityAccountLogs[i].showUpload =
                    cmp.isFileUpload && (!account.utilityAccountLogs[i].utilityBills || account.utilityAccountLogs[i].utilityBills.length === 0);
                account.utilityAccountLogs[i].utilityAccountNumberReentry = account.utilityAccountLogs[i].utilityAccountNumber;

                if (account.utilityAccountLogs[i].rateClass) {
                    cmp.selectedRateClasses.push(cmp.rateClassObj[account.utilityAccountLogs[i].rateClass]);
                }
            }
        }
        cmp.sameBillingAddress = cmp.propertyAccount.billingStreet === cmp.propertyAccount.utilityAccountLogs[0].serviceStreet;
        cmp.sameHomeAddress = cmp.restLead.streetAddress === cmp.propertyAccount.utilityAccountLogs[0].serviceStreet;
        resumeAppSetProduct(cmp);
    }
    // if no lead exists, set default values for restLead and propertyAccount
    else {
        cmp.restLead = getNewRestLead(cmp);
        cmp.propertyAccount = getNewRestPropertyAccount(cmp);
    }
}

// Ensure we're setting the selected product based on restLead returned by server (resume app only)
// Someone internal may have changed the product for the customer in the backend, reflect that change here
const resumeAppSetProduct = (cmp) => {
    let possibleProducts = new Map();
    cmp.zipCheckResponse.products.forEach(product => {
        possibleProducts.set(product.name, product);
    });
    const productOnLead = possibleProducts.get(cmp.restLead.productName);
    // If no match found, set selectedProduct default, which is cmp.zipCheckResponse.products[0]
    cmp.selectedProduct = productOnLead ? productOnLead : cmp.selectedProduct;
}

const getFinDocFileTypes = () => {
    return ['.png', '.jpg', '.jpeg', '.pdf', '.zip'];
}

const getUnderwritingHelpText = () => {
    return '<p>The FICO underwriting option is only available for a select group of customers. Please select the financial review option if the applicant’s annual cost exceeds the amount below for their utility and rate class.' + 
    '<ul>' +
    '   <li>CMP – Small Commercial: $55,000</li>' +
    '   <li>CMP – Medium Commercial: $55,000</li>' +
    '   <li>Versant Bangor Hydro – Small Commercial: $60,000</li>' +
    '   <li>Versant Bangor Hydro – Medium Commercial: $60,000</li>' +
    '   <li>Versant Maine Public – Small Commercial: $50,000</li>' +
    '   <li>Versant Maine Public – Medium Commercial: $50,000</li>' +
    '</ul></p>';
}

// set cmp values on underwriting based on if a residential or biz app to control cmp behavior
const setComponentUnderwritingVals = (component) => {
    const isResiApplication = component.resiApplicationType;

    if (isResiApplication) {
        component.showUnderwritingOptions = false;
        component.restLead.underwritingCriteria = 'FICO';
    }
    else {
        // no underwriting options provided in zip check
        if (!component.underwritingOptions || component.underwritingOptions.length === 0) {
            component.showUnderwritingOptions = false;
            component.restLead.underwritingCriteria = 'FICO';
        }
        // one underwriting option provided in zip check
        else if (component.underwritingOptions.length === 1) {
            let option = component.underwritingOptions[0].value;
            component.showUnderwritingOptions = false;
            component.restLead.underwritingCriteria = option;
            component.isFico = option === 'FICO';
        }
        // more than one underwriting option provided in zip check
        else {
            // We want "Apply with Guarantor or Financial Documents?" to appear for biz apps in ssfBasicInfo page
            component.showUnderwritingOptions = true;
        }
    }

    handleUnderwritingChange(component);
}

// notify parent ssf/ssfDTC of underwriting option to pass to ssfAgreements/ssfAgreementsDTC
const handleUnderwritingChange = (component) => {
    const isFico = component.isFico;
    const underwritingChangeEvent = new CustomEvent('underwritingchange', {detail: isFico});
    component.dispatchEvent(underwritingChangeEvent);
}

const getNewRestLead = (component) => {
    return {
        applicationType: component.resiApplicationType ? 'Residential' : 'Non-Residential',
        zipCode: component.zipinput,
        productName: component.selectedProduct.name,
        utilityId: component.utilityId,
        financialDocs: []
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

const validateUtilityAccountLog = (utilityAccountLog) => {
    return !!(utilityAccountLog &&
              utilityAccountLog.utilityAccountNumber &&
              utilityAccountLog.serviceStreet &&
              utilityAccountLog.serviceState &&
              utilityAccountLog.serviceCity &&
              utilityAccountLog.servicePostalCode);
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
    if (!cmp.resiApplicationType && !cmp.isFico && (!cmp.restLead.financialDocs || cmp.restLead.financialDocs.length ===0)) {
        cmp.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
            if (element.categoryType === 'Financial Review Documents') {
                element.addError();
            }
        });
    }

    if (!allValid) {
        cmp.showWarningToast('Warning!', 'Please verify your application before submitting');
        return false;
    }

    cmp.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
        element.removeError();
    });
    return true;
}

const mockData = (cmp) => {
    cmp.restLead.firstName = 'Peter';
    cmp.restLead.lastName = 'Testcase';
    cmp.restLead.email = 'pyao@bluewavesolar.com';
    if (cmp.resiApplicationType) {
        cmp.restLead.mobilePhone = 1231231234;
    }
    else {
        cmp.restLead.businessPhone = 1231231234;
    }
    cmp.propertyAccount.utilityAccountLogs[0].utilityAccountNumber = '123';
    cmp.propertyAccount.utilityAccountLogs[0].nameOnAccount = 'Peter Testcase';
    cmp.propertyAccount.utilityAccountLogs[0].serviceStreet = '123 Main';
    cmp.propertyAccount.utilityAccountLogs[0].serviceState = 'MA';
    cmp.propertyAccount.utilityAccountLogs[0].serviceCity = 'Boston';
    cmp.propertyAccount.utilityAccountLogs[0].servicePostalCode = cmp.zipinput;
}

export {  
    getFinDocFileTypes,
    getUnderwritingHelpText,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    setRemainingFields,
    handleUnderwritingChange,
    verifyUtilityAccountEntry,
    validateServiceZipCode,
    applicationValid,
    onLoad,
    resumeAppSetProduct
}