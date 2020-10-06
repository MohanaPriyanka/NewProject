/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

import { getNumberOfContractDocs } from 'c/ssfBasicInfoShared';

const validateBasicInfoCompleted = (zipResponseJSON, leadJSON) => {
    const capacity = JSON.parse(zipResponseJSON);
    const lead = JSON.parse(leadJSON);

    if (!capacity.zipCode) {
        return false;
    }
    if (!capacity.products || capacity.products.length === 0) {
        return false;
    }
    if (!capacity.utilities || capacity.utilities.length !== 1) {
        return false;
    }
    if (!lead.firstName || !lead.lastName || !lead.email || !lead.productName
        || (lead.applicationType !== 'Residential' && lead.applicationType !== 'Non-Residential')) {
            return false;
    }
    if (lead.applicationType !== 'Residential' && (!lead.businessName || !lead.businessTitle)) {
        return false;
    }
    if (!lead.propertyAccounts || lead.propertyAccounts.length === 0) {
        return false;
    }

    for (let i=0; i<lead.propertyAccounts.length; i++) {
        const propertyAccount = lead.propertyAccounts[i];
        if (!propertyAccount.billingStreet || !propertyAccount.billingCity
            || !propertyAccount.billingState || !propertyAccount.billingPostalCode) {
            return false;
        }
        if (!propertyAccount.utilityAccountLogs || propertyAccount.utilityAccountLogs.length === 0) {
            return false;
        }
        for (let j=0; j<propertyAccount.utilityAccountLogs.length; j++) {
            const ual = propertyAccount.utilityAccountLogs[j];
            if (!ual.nameOnAccount || !ual.serviceStreet || !ual.serviceCity
                || !ual.serviceState || !ual.servicePostalCode) {
                return false;
            }
        }
    }
    
    return true;
}

const getNumberOfDocsForExistingLead = (lead,capacity) => {
    return getNumberOfContractDocs(lead, capacity.products[0], capacity.rateClasses);
}

const onResumeSetIsFico = (component, restlead, resiApplicationType) => {
    // if residential app, leave default isFico = true on application
    if (resiApplicationType) {
        return;
    }

    // if SMB app, check for underwriting method, or leave as default
    const underwritingSelection = restlead.underwritingCriteria;
    switch (underwritingSelection) {
        case 'Financial Review' :
            component.isFico = false;
            break;
        default :
            // use default isFico value
    }
}

export {
    validateBasicInfoCompleted,
    getNumberOfDocsForExistingLead,
    onResumeSetIsFico
}