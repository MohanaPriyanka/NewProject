/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getZipCodeCapacity } from 'c/zipCodeService';
import insertLog from '@salesforce/apex/Logger.insertLog';
import { postReadyStateEvent, modifySpinnerMessageEvent, toggleLoadingSpinnerEvent } from "c/ssfShared";

const onLoad = (component) => {
    modifySpinnerMessageEvent(component, 'Checking availability...');
    if (!component.utilityOptions) {
        component.utilityOptions = [];
    }
    if (component.zipCodeInput && !component.zipCodeResponse) {
        getCapacity(component, null);
    } else {
        postReadyStateEvent(component, null);
    }
}

const proceedWithUtility = (component) => {
    component.selectedUtility = JSON.parse(component.selectedUtility);
    getCapacity(component, component.selectedUtility.utilityId);
}

const checkForSubmit = (component, event) => {
    if (event.which === 13) {
        submitForm(component);
    }
}

const submitForm = (component) => {
    const inputBox = component.template.querySelector('lightning-input');
    inputBox.reportValidity();
    if (inputBox.checkValidity()) {
        getCapacity(component, null);
    }
}

const getCapacity = async (component, utilityId) => {
    toggleLoadingSpinnerEvent(component, false);
    try {
        let check = await getZipCodeCapacity(component.zipCodeInput, component.partnerId, utilityId);
        component.zipCodeResponse = JSON.stringify(check);
        if (check.utilities && check.utilities.length > 1) {
            multipleUtilitiesFound(component, check);
        } else if (check.hasCapacity && check.products.length >= 1 && check.utilities.length === 1) {
            capacityFound(component, check);
        } else {
            noCapacity(component);
        }
    } catch (exception) {
        console.log(exception);
        postReadyStateEvent(component, null);
        toggleLoadingSpinnerEvent(component, true);
        insertLog({
            className: 'ssf',
            methodName: 'getZipCodeCapacity',
            message: `Error: ${exception}`,
            severity: 'Error'
        });
        const evt = new ShowToastEvent({
            title: 'Sorry, we ran into a technical problem',
            message: 'Please contact Customer Care for help',
            variant: 'warning'
        });
        component.dispatchEvent(evt);
    }
}

const capacityFound = (component, check) => {
    toggleLoadingSpinnerEvent(component, true);
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
}

const noCapacity = (component) => {
    window.setTimeout(() => {
        toggleLoadingSpinnerEvent(component, true);
        postReadyStateEvent(component, null);
        const evt = new ShowToastEvent({
            title: 'Sorry, your zip code is not eligible for service at this time',
            message: 'Please check later',
            variant: 'warning'
        });
        component.dispatchEvent(evt);
    }, 300);
    component.showModal = false;
}

const multipleUtilitiesFound = (component, check) => {
    toggleLoadingSpinnerEvent(component, true);
    component.utilityOptions = check.utilities.map(
        utility => {
            return {value: JSON.stringify(utility), label: utility.name};
        }
    );
    component.showModal = true;
}

export {
    onLoad,
    proceedWithUtility,
    checkForSubmit,
    submitForm,
    getCapacity
}