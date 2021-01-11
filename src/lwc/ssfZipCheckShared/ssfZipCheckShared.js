/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getZipCodeCapacity } from 'c/zipCodeService';
import insertLog from '@salesforce/apex/Logger.insertLog';


const connCallback = (component) => {
    if (!component.utilityOptions) {
        component.utilityOptions = [];
    }
    
    if (component.zipCodeInput && !component.zipCodeResponse) {
        component.showSpinner = true;
        component.spinnerMessage = 'Checking for projects...';
        getZipCapacity_shared(component, null);
    }
}

const proceedWithSelectedUtility_shared = (component) => {
    component.showSpinner = true;
    component.selectedUtility = JSON.parse(component.selectedUtility);
    getZipCapacity_shared(component, component.selectedUtility.utilityId);
}

const checkForSubmit_shared = (component, event) => {
    if (event.which === 13) {
        const inputBox = component.template.querySelector('lightning-input');
        inputBox.reportValidity();
        if (inputBox.checkValidity()) {
            getZipCapacity_shared(component, null);
        }
    }
}

const getZipCapacity_shared = async (component, utilityId) => {
    try {
        let check = await getZipCodeCapacity(component.zipCodeInput, component.partnerId, utilityId);
        component.zipCodeResponse = JSON.stringify(check);
        if (check.utilities && check.utilities.length > 1) {
            component.utilityOptions = check.utilities.map(
                utility => {
                    return {value: JSON.stringify(utility), label: utility.name};
                }
            );
            component.showModal = true;
        } else if (check.hasCapacity && check.products.length >= 1 && check.utilities.length === 1) {
            if (check.ficoUnderwriting) {
                component.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
            }
            if (check.finDocsUnderwriting) {
                component.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
            }
            component.selectedUtility = check.utilities[0];
            component.showModal = false;
            component.dispatchEvent(new CustomEvent('capacitycheckcomplete', {
                detail: {
                    zipCodeResponse: component.zipCodeResponse,
                    underwritingOptions: component.underwritingOptions,
                    resiApplicationType: component.resiApplicationType
                }})
            );
        } else {
            const evt = new ShowToastEvent({
                title: 'Sorry, your zip code is not eligible for service at this time',
                message: 'Please check later',
                variant: 'warning'
            });
            component.dispatchEvent(evt);
        }
        component.showSpinner = false;
    } catch (exception) {
        insertLog({
            className: 'ssf',
            methodName: 'getZipCodeCapacity',
            message: JSON.stringify(exception),
            severity: 'Error'
        });
        component.showSpinner = false;
        const evt = new ShowToastEvent({
            title: 'Sorry, we ran into a technical problem',
            message: 'Please contact Customer Care for help',
            variant: 'warning'
        });
        component.dispatchEvent(evt);
    }
}


export {
    connCallback,
    proceedWithSelectedUtility_shared,
    checkForSubmit_shared,
    getZipCapacity_shared
}