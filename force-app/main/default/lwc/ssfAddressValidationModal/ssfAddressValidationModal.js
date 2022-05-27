/**
 * Created by rebeccanachison on 4/22/22.
 */

import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import formFactorName from '@salesforce/client/formFactor';

export default class SSFAddressValidationModal extends LightningElement {

    @api show;

    @track isPhone;
    @track suggestionSets = [];

    suggestionMap;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        this.isPhone = (formFactorName === 'Small');
    }

    @api setSuggestions(suggestionMap) {
        this.suggestionMap = suggestionMap;
        this.suggestionSets = [];
        for (const [key, objectInfo] of Object.entries(suggestionMap)) {
            const object = {
                key: key,
                name: objectInfo.name,
                input: objectInfo.input
            };
            const set = [];
            objectInfo.addresses.forEach(suggestion => {
                const label = objectInfo.subpremise && objectInfo.subpremise.length ? `Suggestion: ${suggestion.street} ${objectInfo.subpremise}, ${suggestion.city}, ${suggestion.state} ${suggestion.zipCode}` : `Suggestion: ${suggestion.street}, ${suggestion.city}, ${suggestion.state} ${suggestion.zipCode}`;
                set.push({
                    label: label,
                    value: suggestion.id
                });
            })
            if (set.length > 0) {
                set.push({
                    label: 'Do not change, use unverified address',
                    value: 'override'
                });
                object.firstResult = set[0].value;
            }
            object.results = set;
            object.hasResults = set.length > 0;
            this.suggestionSets.push(object);
        }
    }

    setAddress(event) {
        let id = event.detail.value;
    }

    acceptSuggestions() {
        const objects = [];
        const checkboxes = this.template.querySelectorAll('lightning-input[data-type="checkbox"]');
        const radioGroups = this.template.querySelectorAll('lightning-radio-group');
        checkboxes.forEach(checkbox => {
           if (!checkbox.checked) {
               // user did not select to override validation
               // don't do anything
               return;
           }
            // user selected to override validation
            // get object name, set as unverified, and flag as overridden
            const objectName = checkbox.name;
            const object = {objectName};
            object.address = {
                'hasUnverifiedAddress': true,
                'hasOverride': true
            };
            // add to our list of objects to update
            objects.push(object);
        });
        radioGroups.forEach(radioGroup => {
            // get the object name and use it to find the relevant list of suggestions
            const value = radioGroup.value;
            const objectName = radioGroup.name;
            const suggestion = this.suggestionMap[objectName];
            const object = {objectName};
            object.address = {};
            // if user chose to override, set as unverified, flag as overridden, and remove any lat/lng values
            // add to our list of objects to update and move on to next object
            if (value === 'override') {
                object.address['hasUnverifiedAddress'] = true;
                object.address['hasOverride'] = true;
                object.address[suggestion.fields.latitude] = null;
                object.address[suggestion.fields.longitude] = null;
                objects.push(object);
                return;
            }
            // find the suggested address the user chose from its id
            let address = suggestion.addresses.filter(address => address.id === value);
            if (!address.length) {
                // should not be possible, but should add error here
                return;
            }
            address = address[0];
            for (const [field, fieldName] of Object.entries(suggestion.fields)) {
                // set the address fields using the object-specific field names
                object.address[fieldName] = address[field];
            }
            object.address['hasUnverifiedAddress'] = false;
            // add to list of objects to update
            objects.push(object);
        });
        const updateAddressesEvent = new CustomEvent('updateaddresses', {
            detail: { objects }
        });
        this.dispatchEvent(updateAddressesEvent);
        this.closeModal();
    }

    closeModal() {
        const closeModalEvent = new CustomEvent('closemodal', {
            detail: {
                field: 'showAddressValidationModal',
                value: false
            }
        });
        this.dispatchEvent(closeModalEvent);
    }

    get title() {
        let title = 'We couldn\'t find ';
        if (this.suggestionMap && Object.keys(this.suggestionMap).length > 1) {
            title += 'some ';
        } else {
            title += 'one ';
        }
        title += 'of those addresses';
        return title;
    }

    get buttonContainerClass() {
        return this.isPhone ? 'slds-align_absolute-center' : '';
    }

    get closeButtonWrapperClass() {
        return this.isPhone ? '' : 'slds-float_left';
    }

    get closeButtonClass() {
        let css = 'slds-button slds-button_neutral';
        if (this.isPhone) {
            css += 'slds-m-around_small';
        }
        return css;
    }

    get agreeButtonWrapperClass() {
        return this.isPhone ? '' : 'slds-float_right';
    }

    get agreeButtonClass() {
        let css = 'slds-button slds-button_brand';
        if (this.isPhone) {
            css += 'slds-m-around_small';
        }
        return css;
    }

}