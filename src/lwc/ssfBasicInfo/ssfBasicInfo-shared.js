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

const getNewRestLead = (appType, zipCode, productName, utilityId) => {
    return {
        applicationType: appType,
        zipCode: zipCode,
        productName: productName,
        utilityId: utilityId,
        financialDocs: []
    }
}

const getNewRestPropertyAccount = (isResiAppType, zipCode) => {
    return { 
        billingPostalCode: isResiAppType ? '' : zipCode, 
        utilityAccountLogs: [] 
    }
}

const getNewRestUtilityAccountLog = (ualCount, zipCode, utilityId, isFileUpload) => {
    return {
        localid: ualCount,
        name: `Utility Account ${ualCount}`,
        servicePostalCode: zipCode,
        utilityId: utilityId,
        doNotDelete: false,
        showUpload: isFileUpload,
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


const setRemainingFields = (restLead, propertyAccount, sameBillingAddress, sameHomeAddress, isResiAppType, product, rateClasses) => {
    if (sameBillingAddress) {
        propertyAccount = matchBillingAddress(propertyAccount);
    }
    if (sameHomeAddress) {
        restLead = matchHomeAddress(restLead, propertyAccount);
    }
    propertyAccount.name = isResiAppType ? `${restLead.firstName} ${restLead.lastName}` : restLead.businessName;
    restLead.propertyAccounts = [propertyAccount];
    restLead.numberOfContractDocs = getNumberOfContractDocs(restLead, product, rateClasses);
    
    return restLead;
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
            propAcct.forEach(ual => {
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