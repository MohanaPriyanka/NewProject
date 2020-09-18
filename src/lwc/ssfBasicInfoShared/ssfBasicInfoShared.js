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


const setRemainingFields = (component, sameHomeAddress) => {
    if (component.sameBillingAddress) {
        component.propertyAccount = matchBillingAddress(component.propertyAccount);
    }
    if (sameHomeAddress) {
        component.restLead = matchHomeAddress(component.restLead, component.propertyAccount);
    }
    component.propertyAccount.name = component.resiApplicationType ? `${component.restLead.firstName} ${component.restLead.lastName}` : component.restLead.businessName;
    component.restLead.propertyAccounts = [component.propertyAccount];
    component.restLead.numberOfContractDocs = getNumberOfContractDocs(component.restLead, component.selectedProduct, component.selectedRateClasses);
}

export {  
    getFinDocFileTypes,
    getUnderwritingHelpText,
    getNewRestLead,
    getNewRestPropertyAccount,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    setRemainingFields
}


// ///////////////////////////////////
//      Helper Methods
// ///////////////////////////////////
function matchBillingAddress(propertyAccount) {
    propertyAccount.billingStreet = propertyAccount.utilityAccountLogs[0].serviceStreet;
    propertyAccount.billingCity = propertyAccount.utilityAccountLogs[0].serviceCity;
    propertyAccount.billingState = propertyAccount.utilityAccountLogs[0].serviceState;
    propertyAccount.billingPostalCode = propertyAccount.utilityAccountLogs[0].servicePostalCode;
    return propertyAccount;
}

function matchHomeAddress(restLead, propertyAccount) {
    restLead.streetAddress = propertyAccount.utilityAccountLogs[0].serviceStreet;
    restLead.city = propertyAccount.utilityAccountLogs[0].serviceCity;
    restLead.state = propertyAccount.utilityAccountLogs[0].serviceState;
    restLead.zipCode = propertyAccount.utilityAccountLogs[0].servicePostalCode;
    return restLead;
}

function getNumberOfContractDocs(lead, product, rateClasses) {
    if(product.standaloneDisclosureForm === false) {
        return 1;
    }

    if(rateClasses && rateClasses.length > 0) {
        const rateClassObj = Object.fromEntries(rateClasses.map(
            rateClass => ([rateClass.name, rateClass])
        ));

        let allSuppress = true;
        lead.propertyAccounts.forEach(propAcct => {
            propAcct.utilityAccountLogs.forEach(ual => {
                if(!ual.rateClass || !rateClassObj.hasOwnProperty(ual.rateClass) || !rateClassObj[ual.rateClass].suppressDisclosureForm) {
                    allSuppress = false;
                }
            });
        });

        if(allSuppress) {
            return 1;
        }
    }

    return 2;
}