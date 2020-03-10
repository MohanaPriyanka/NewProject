/**
 * Created by PeterYao on 2/24/2020.
 */

import {LightningElement, track, api, wire} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getUSStateOptions } from 'c/util';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SsfBasicInfo extends NavigationMixin(LightningElement) {
    @api zipinput;
    @track showSpinner;
    @track spinnerMessage;
    @track firstName;
    @track lastName;
    @track email;
    @track phone;
    @track billingStreet;
    @track billingCity;
    @track billingState;
    @track billingZip;
    @api zipCodeResponse;
    @track selectedUtility;
    @api utilityOptions;
    @track utilityAccounts;
    @track utilityAccountSection;
    @track stateOptions;
    @track referralName;
    @track applicationType;
    utilityAccountCount = 1;
    @api selectedProduct;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (!this.utilityAccounts) {
            this.utilityAccounts = [{
                id: 1,
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
        if (!this.applicationType) {
            this.applicationType = 'Residential';
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
        this.billingStreet = '1 Main';
        this.billingCity = 'Boston';
        this.billingState = 'MA';
        this.billingZip = '02144';
        this.utilityAccounts[0].utilityAccountNumber = '123';
        this.utilityAccounts[0].nameOnAccount = 'Peter testcase';
        this.utilityAccounts[0].street = '123 Main';
        this.utilityAccounts[0].state = 'MA';
        this.utilityAccounts[0].city = 'Boston';
        this.utilityAccounts[0].zip = '02144';
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    utilityAccountOnChange(event) {
        this.utilityAccounts[event.target.dataset.rowIndex][event.target.name] = event.target.value;
        if (event.target.dataset.rowIndex === '0') {
            switch(event.target.name) {
                case 'street':
                    this['billingStreet'] = event.target.value;
                    break;
                case 'city':
                    this['billingCity'] = event.target.value;
                    break;
                case 'state':
                    this['billingState'] = event.target.value;
                    break;
                case 'zip':
                    this['billingZip'] = event.target.value;
                    break;
            }
        }
    }
    addAnotherUtilityAccount() {
        if (!this.lastUtilityAccountValid()) {
            return;
        }
        this.utilityAccountCount++;
        this.utilityAccounts.push({
            id:this.utilityAccountCount,
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
        if (this.zipCodeResponse.loadZones) {
            // TODO: W-015322 Handle multiple load zones in SSF
            this.loadZone = this.zipCodeResponse.loadZones[0];
        }
        let restLead = {
            applicationType: this.applicationType,
            firstName: this.firstName,
            lastName: this.lastName,
            email : this.email,
            mobilePhone : this.phone,
            streetAddress: this.billingStreet,
            city: this.billingCity,
            state: this.billingState,
            zipCode: this.billingZip,
            productName: this.selectedProduct,
            referralName: this.referralName,
            eiaId: this.selectedUtility,
            loadZone: this.loadZone?this.loadZone:'',
            partnerId: this.partnerId?this.partnerId:'',
            salesRepId: this.salesRepId?this.salesRepId:'',
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
            this.spinnerMessage = 'We\'ll generate documents next';
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
        return new Promise(function(resolve, reject) {
            let calloutURI = '/apply/services/apexrest/v3/leads';
            const xmlHttpRequest = new XMLHttpRequest();
            xmlHttpRequest.onreadystatechange = function() {
                if (this.readyState === 4) {
                    const response = JSON.parse(this.responseText);
                    if (this.status === 200 || this.status === 201) {
                        if (response.data) {
                            resolve(response.data);
                        } else {
                            reject(this.responseText);
                        }
                    } else {
                        reject(this.responseText);
                    }
                }
            };
            xmlHttpRequest.open('POST', calloutURI, true);
            xmlHttpRequest.setRequestHeader('Content-Type', 'application/json');
            xmlHttpRequest.send(JSON.stringify(restLead));
        });
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