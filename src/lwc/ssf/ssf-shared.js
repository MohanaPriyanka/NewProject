/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

const validateBasicInfoCompleted = (zipResponseJSON, leadJSON) => {
    const capacity = JSON.parse(zipResponseJSON);
    if(!capacity.zipCode) {
        return false;
    }
    if(!capacity.products || capacity.products.length === 0) {
        return false;
    }
    if(!capacity.utilities || capacity.utilities.length !== 1) {
        return false;
    }

    let lead = JSON.parse(leadJSON);
    if(!lead.firstName || !lead.lastName || !lead.email || !lead.productName 
        || (lead.applicationType != 'Residential' && lead.applicationType != 'Non-Residential')) {
            return false;
    }
    if(lead.applicationType != 'Residential' && (!lead.businessName || !lead.businessTitle)) {
        return false;
    }
    if(!lead.propertyAccounts || lead.propertyAccounts.length === 0) {
        return false;
    }
    for(let i=0; i<lead.propertyAccounts.length; i++) {
        const propertyAccount = lead.propertyAccounts[i];
        if(!propertyAccount.billingStreet || !propertyAccount.billingCity || !propertyAccount.billingState || !propertyAccount.billingPostalCode) {
            return false;
        }
        if(!propertyAccount.utilityAccountLogs || propertyAccount.utilityAccountLogs.length == 0) {
            return false;
        }
        for(let j=0; j<propertyAccount.utilityAccountLogs.length; j++) {
            const ual = propertyAccount.utilityAccountLogs[j];
            if(!ual.nameOnAccount || !ual.serviceStreet || !ual.serviceCity || !ual.serviceState || !ual.servicePostalCode) {
                return false;
            }
        }
    }
    
    return true;
}


const getNumberOfDocsForExistingLead = (lead,capacity) => {
    return getNumberOfContractDocs(lead, capacity.products[0], capacity.rateClasses);
}

export { validateBasicInfoCompleted, getNumberOfDocsForExistingLead }