/**
 * Created by rebeccanachison on 4/22/22.
 */

import {LightningElement, api, track} from 'lwc';
import getGeocodeResults from '@salesforce/apex/GeocoderAPIService.getGeocodeResults';

export default class SSFAddress extends LightningElement {

    @api objectName;
    @api label;
    @api street;
    @api subpremise;
    @api city;
    @api state;
    @api stateOptions;
    @api zip;
    @api latitude;
    @api longitude;
    @api fieldNames;
    @api fieldLevelHelp;
    @api index;
    @api zipCodeInput;
    @api utilityZipCodesServed;

    handleOnChange(event) {
        const setAddressEvent = new CustomEvent('setaddress', {
            detail: {
                field: event.target.name,
                value: event.target.value,
                object: this.objectName
            }
        });
        this.dispatchEvent(setAddressEvent);
    }

    @api geocodeAddresses() {
        try {
            return getGeocodeResults({
                addressInput: this.street,
                cityInput: this.city,
                stateInput: this.state,
                zipCodeInput: this.zip
            });
        } catch (error) {
            // geocodeAddresses is called by ssfBasicInfoShared.js
            // throw error for ssfBasicInfoShared.js to handle
            throw error;
        }
    }

    @api focusStreet() {
        this.template.querySelector('lightning-input[data-name="street"]').focus();
        return;
    }

    validateUtilityZip() {
        let isValid = true;
        // only validate for utility account log address
        if (this.objectName !== 'utilityAccountLog') {
            return isValid;
        }
        isValid = this.utilityZipCodesServed.includes(this.zip);
        let error = `Invalid ZIP Code or ZIP Code not in the same Utility area as the previously-entered ZIP Code ${this.zipCodeInput}.
             Please enter a ZIP Code in the same Utility area as ${this.zipCodeInput} or restart your application.`;

        const zipElement = this.template.querySelector(`[data-name="zip"]`);
        if (!isValid) {
            zipElement.setCustomValidity(error);
        } else {
            zipElement.setCustomValidity('');
        }
        zipElement.reportValidity();
        return isValid;
    }

    @api reportValidity() {
        return this.checkValidity();
    }

    @api checkValidity() {
        let isValid = true;
        let allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return isValid && this.validateUtilityZip();
    }

    @api get required() {
        return this._required;
    }

    set required(value) {
        this._required = value === 'string' || !!value;
    }
}