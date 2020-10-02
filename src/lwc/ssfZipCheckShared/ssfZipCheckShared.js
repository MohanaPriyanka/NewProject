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
    
    if(component.zipCodeInput && !component.zipCodeResponse) {
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
        if(inputBox.checkValidity()) {
            getZipCapacity_shared(component, null);
        }
    }
}

const getZipCapacity_shared = (component, utilityId) => {
    getZipCodeCapacity(component.zipCodeInput, component.partnerId, utilityId).then(
        (resolveResult) => {
            component.showSpinner = false;
            component.zipCodeResponse = JSON.stringify(resolveResult);
            if (resolveResult.hasCapacity && resolveResult.products.length >= 1) {
                if(resolveResult.utilities && resolveResult.utilities.length === 1) {
                    if(resolveResult.ficoUnderwriting) {
                        component.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
                    }
                    if(resolveResult.finDocsUnderwriting) {
                        component.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
                    }
                    component.selectedUtility = resolveResult.utilities[0];
                    component.showModal = false;
                    
                    const capacityCheckCompleteEvent = new CustomEvent('capacitycheckcomplete', {
                        detail: {
                            zipCodeResponse: component.zipCodeResponse,
                            underwritingOptions: component.underwritingOptions,
                            resiApplicationType: component.resiApplicationType
                        }
                    });
                    component.dispatchEvent(capacityCheckCompleteEvent);
                } else if(resolveResult.utilities && resolveResult.utilities.length > 1) {
                    component.utilityOptions = resolveResult.utilities.map(
                        utility => {
                            return {value: JSON.stringify(utility), label: utility.name};
                        }
                    );
                    component.showModal = true;
                }
            } else {
                const evt = new ShowToastEvent({
                    title: 'Sorry, your zip code is not eligible for service at this time',
                    message: 'Please check later',
                    variant: 'warning'
                });
                component.dispatchEvent(evt);
            }
        },
        (rejectResult) => {
            component.showSpinner = false;
            insertLog({
                className: 'ssf',
                methodName: 'getZipCodeCapacity',
                message: JSON.stringify(rejectResult),
                severity: 'Error'
            });
            const evt = new ShowToastEvent({
                title: 'Sorry, we ran into a technical problem',
                message: 'Please contact Customer Care for help',
                variant: 'warning'
            });
            component.dispatchEvent(evt);
        }
    );
}


export {
    connCallback,
    proceedWithSelectedUtility_shared,
    checkForSubmit_shared,
    getZipCapacity_shared
}