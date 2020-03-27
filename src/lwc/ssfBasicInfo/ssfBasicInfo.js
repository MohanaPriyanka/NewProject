/**
 * Created by PeterYao on 2/24/2020.
 */

import {LightningElement, track, api, wire} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getUSStateOptions } from 'c/util';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {makeRequest} from 'c/httpRequestService';

export default class SsfBasicInfo extends NavigationMixin(LightningElement) {
    @api zipinput;
    @track showSpinner;
    @track spinnerMessage;
    @track firstName;
    @track lastName;
    @track email;
    @track phone;
    @track sameBillingAddress = true;
    @track billingStreet;
    @track billingCity;
    @track billingState;
    @track billingZip;
    @track sameHomeAddress = true;
    @track homeStreet;
    @track homeCity;
    @track homeState;
    @track homeZip;
    @track selectedUtility;
    @api utilityOptions;
    @track utilityAccounts;
    @track utilityAccountSection;
    @track stateOptions;
    @track referralName;
    @api resiApplicationType;
    @track businessName;
    @track businessTitle;
    @track businessPhone;
    applicationType;
    utilityAccountCount = 1;
    @api selectedProduct;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (!this.utilityAccounts) {
            this.utilityAccounts = [{
                id: 1,
                name: `Utility Account 1`,
                utilityAccountNumber: '',
                street: '',
                state: '',
                city: '',
                zip: this.zipinput
            }];
            this.utilityAccountSection = 1;
        }
        if (!this.billingZip) {
            this.billingZip = this.zipinput;
        }
        if (!this.stateOptions) {
            this.stateOptions = getUSStateOptions();
        }
        if (!this.utilityOptions) {
            this.utilityOptions = [];
        } else if (this.utilityOptions.length === 1) {
            this.selectedUtility = this.utilityOptions[0].value;
        }
        if (this.resiApplicationType) {
            this.applicationType = 'Residential';
        } else {
            this.applicationType = 'Non-Residential';
        }
        if (this.pageRef && this.pageRef.state && this.pageRef.state.mock) {
            this.mockData();
        }
    }

    mockData() {
        this.firstName = 'Peter';
        this.lastName = 'Testcase';
        this.email = 'pyao@bluewavesolar.com';
        this.phone = 1231231234;
        this.utilityAccounts[0].utilityAccountNumber = '123';
        this.utilityAccounts[0].nameOnAccount = 'Peter testcase';
        this.utilityAccounts[0].street = '123 Main';
        this.utilityAccounts[0].state = 'MA';
        this.utilityAccounts[0].city = 'Boston';
        this.utilityAccounts[0].zip = this.zipinput;
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    phoneOnChange(event) {
        const strippedPhone = event.target.value.replace(/\D/g,'');
        event.target.setCustomValidity("");
        if(strippedPhone.length === 10) {
            this[event.target.name] = strippedPhone.substr(0,3) + '-' + strippedPhone.substr(3,3) + '-' + strippedPhone.substr(6,4);
        } else {
            this[event.target.name] = strippedPhone;
            event.target.setCustomValidity("Please enter a 10-digit phone number");
        }
    }

    billingAddressToggle(event) {
        this.sameBillingAddress = event.target.checked;
    }

    homeAddressToggle(event) {
        this.sameHomeAddress = event.target.checked;
    }

    utilityAccountOnChange(event) {
        this.utilityAccounts[event.target.dataset.rowIndex][event.target.name] = event.target.value;
    }
    addAnotherUtilityAccount() {
        if (!this.lastUtilityAccountValid()) {
            return;
        }
        this.utilityAccountCount++;
        this.utilityAccounts.push({
            id:this.utilityAccountCount,
            name: `Utility Account ${this.utilityAccountCount}`,
            utilityAccountNumber: '',
            street: '',
            state: '',
            city: '',
            zip: this.zipinput
        });
        setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
    }

    lastUtilityAccountValid() {
        let index = this.utilityAccountCount - 1;
        if (this.utilityAccounts[index] &&
            this.utilityAccounts[index].utilityAccountNumber &&
            this.utilityAccounts[index].street &&
            this.utilityAccounts[index].state &&
            this.utilityAccounts[index].city &&
            this.utilityAccounts[index].zip) {
            return true;
        }
        this.showWarningToast('Warning', 'Please complete this utility account before adding another');
        return false;
    }

    handleUtilityAccountMenu(event) {
        const selectedItemValue = event.detail.value;
        const utilityAccountIndex = event.target.name;
        if (selectedItemValue === 'remove') {
            this.utilityAccounts.splice(utilityAccountIndex, 1);
        }
    }

    applicationValid() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (!allValid) {
            this.showWarningToast('Warning!', 'Please verify your application before submitting');
            return false;
        }
        return true;
    }

    submitApplication() {
        if (!this.applicationValid()) {
            return;
        }
        if (this.pageRef && this.pageRef.state && this.pageRef.state.partnerId) {
            this.partnerId = this.pageRef.state.partnerId;
        }
        if (this.pageRef && this.pageRef.state && this.pageRef.state.salesRepId) {
            this.salesRepId = this.pageRef.state.salesRepId;
        }
        if (this.sameBillingAddress) {
            this.billingStreet = this.utilityAccounts[0].street;
            this.billingCity = this.utilityAccounts[0].city;
            this.billingState = this.utilityAccounts[0].state;
            this.billingZip = this.utilityAccounts[0].zip;
        }
        if (this.sameHomeAddress) {
            this.homeStreet = this.utilityAccounts[0].street;
            this.homeCity = this.utilityAccounts[0].city;
            this.homeState = this.utilityAccounts[0].state;
            this.homeZip = this.utilityAccounts[0].zip;
        }
        let restLead = {
            applicationType: this.applicationType,
            firstName: this.firstName,
            lastName: this.lastName,
            email : this.email,
            mobilePhone : this.phone,
            streetAddress: this.homeStreet,
            city: this.homeCity,
            state: this.homeState,
            zipCode: this.homeZip,
            productName: this.selectedProduct,
            referralName: this.referralName,
            partnerId: this.partnerId?this.partnerId:null,
            salesRepId: this.salesRepId?this.salesRepId:null,
            propertyAccounts: [
                {
                    name: `${this.firstName} ${this.lastName}`,
                    billingStreet: this.billingStreet,
                    billingCity: this.billingCity,
                    billingState: this.billingState,
                    billingPostalCode: this.billingZip,
                }
            ]
        };
        if (!this.resiApplicationType) {
            restLead.businessName = this.businessName;
            restLead.businessTitle = this.businessTitle;
            restLead.businessPhone = this.businessPhone;
        }
        restLead.propertyAccounts[0].utilityAccountLogs = this.utilityAccounts.map(
            ({utilityAccountNumber, nameOnAccount, street, city, state, zip}) => {
                return {
                    utilityAccountNumber,
                    nameOnAccount,
                    serviceStreet: street,
                    serviceCity: city,
                    serviceState: state,
                    servicePostalCode: zip
                };
            }
        );
        this.showSpinner = true;
        window.setTimeout(() => {
            this.spinnerMessage = 'Saving your application';
        }, 3000);
        window.setTimeout(() => {
            this.spinnerMessage = 'We\'ll generate documents next.\r\nThis may take a minute, please stand by.';
        }, 6000);
        this.createLead(restLead).then(
            (resolveResult) => {
                this.dispatchEvent(new CustomEvent('leadcreated', {detail: resolveResult}));
                this.showSpinner = false;
            },
            (rejectResult) => {
                this.showSpinner = false;
                let errors = JSON.parse(rejectResult).errors;
                let message = '';
                if (errors && errors[0]) {
                    message += errors[0];
                } else {
                    message += rejectResult;
                }
                this.showWarningToast('Sorry, we ran into a technical problem!', message);
            }
        );
    }

    createLead = (restLead) => {
        let calloutURI = '/apply/services/apexrest/v3/leads';
        let options = {
            headers: {name: 'Content-Type', value:'application/json'},
            body: JSON.stringify(restLead)
        };
        return makeRequest(calloutURI, 'POST', options);
    };

    showWarningToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }
}