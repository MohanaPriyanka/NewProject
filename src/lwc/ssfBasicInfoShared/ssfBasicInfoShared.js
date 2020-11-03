/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

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
        servicePostalCode: component.zipinput,
        utilityId: component.utilityId,
        doNotDelete: false,
        showUpload: component.isFileUpload,
        utilityBills: []
    }
}

const validateUtilityAccountLog = (utilityAccountLog) => {
    if(utilityAccountLog &&
        utilityAccountLog.utilityAccountNumber &&
        utilityAccountLog.serviceStreet &&
        utilityAccountLog.serviceState &&
        utilityAccountLog.serviceCity &&
        utilityAccountLog.servicePostalCode) {
            return true;
        }

    return false;
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
    component.restLead.numberOfContractDocs = getNumberOfContractDocs(component.restLead, component.selectedProduct, component.selectedRateClasses);
}

const getNumberOfContractDocs = (lead, product, rateClasses) => {
    if (product.standaloneDisclosureForm === false) {
        return 1;
    }
    if (rateClasses && rateClasses.length > 0) {
        const rateClassObj = Object.fromEntries(rateClasses.map(
            rateClass => ([rateClass.name, rateClass])
        ));

        let allSuppress = true;
        lead.propertyAccounts.forEach(propAcct => {
            propAcct.utilityAccountLogs.forEach(ual => {
                if (!ual.rateClass || !rateClassObj.hasOwnProperty(ual.rateClass)
                    || !rateClassObj[ual.rateClass].suppressDisclosureForm) {
                    allSuppress = false;
                }
            });
        });

        if (allSuppress) {
            return 1;
        }
    }
    return 2;
}

const verifyUtilityAccountEntry = (cmp, event, eventField) => {
    // Retrieve DOM element for UA# re-entry field
    const index = event.target.dataset.rowIndex;
    let ualNumReentryInputElement = cmp.template.querySelector(`[data-ual-number-reentry-index="${index}"]`);

    // Retrieve current stored values for input fields
    const ualNum = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumber.replace('-','');
    const ualNumReentry = cmp.propertyAccount.utilityAccountLogs[index].utilityAccountNumberReentry.replace('-','');

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

export {  
    getFinDocFileTypes,
    getUnderwritingHelpText,
    getNewRestLead,
    getNewRestPropertyAccount,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    setRemainingFields,
    setComponentUnderwritingVals,
    handleUnderwritingChange,
    getNumberOfContractDocs,
    verifyUtilityAccountEntry
}