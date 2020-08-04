/**
 * Created by PeterYao on 2/24/2020.
 */

import {LightningElement, track, api, wire} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getUSStateOptionsFull } from 'c/util';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class SsfBasicInfo extends NavigationMixin(LightningElement) {
    @api zipinput;
    @api leadJson;
    @api selectedUtility;
    @api resiApplicationType;
    @api selectedProduct;

    @track restLead;
    @track propertyAccount;
    @track showSpinner;
    @track spinnerMessage;
    @track sameBillingAddress = true;
    @track sameHomeAddress = true;
    @track utilityAccountSection;
    @track stateOptions;
    utilityAccountCount = 0;
    resumedApp = false;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        // if a lead has already been created, have the form show existing values
        if(this.leadJson) {
            this.resumedApp = true;
            this.restLead = JSON.parse(this.leadJson);
            this.propertyAccount = this.restLead.propertyAccounts[0];
            if(this.propertyAccount.utilityAccountLogs) {
                for(let i=0; i < this.propertyAccount.utilityAccountLogs.length; i++) {
                    this.propertyAccount.utilityAccountLogs[i].localid = i+1;
                    this.propertyAccount.utilityAccountLogs[i].name = `Utility Account ${i+1}`;
                    this.propertyAccount.utilityAccountLogs[i].doNotDelete = true;
                    this.propertyAccount.utilityAccountLogs[i].showUpload = (this.propertyAccount.utilityAccountLogs[i].utilityBills);
                }
            }
            this.sameBillingAddress = this.propertyAccount.billingStreet == this.propertyAccount.utilityAccountLogs[0].serviceStreet;
            this.sameHomeAddress = this.restLead.streetAddress == this.propertyAccount.utilityAccountLogs[0].serviceStreet;
        } 
        // if no lead exists, set default values for restLead and propertyAccount
        else {
            this.restLead = {
                applicationType: this.resiApplicationType ? 'Residential' : 'Non-Residential',
                zipCode: this.zipinput,
                productName: this.selectedProduct,
                utilityId: this.selectedUtility
            }
            this.propertyAccount = { 
                billingPostalCode: this.resiApplicationType ? '' : this.zipinput, 
                utilityAccountLogs: [] 
            };
        }

        if(!this.restLead.partnerId) {
            this.restLead.partnerId = this.pageRef && this.pageRef.state && this.pageRef.state.partnerId ? this.pageRef.state.partnerId : null;
        }

        if(!this.restLead.salesRepId) {
            this.restLead.salesRepId = this.pageRef && this.pageRef.state && this.pageRef.state.salesRepId ? this.pageRef.state.salesRepId : null;
        }

        if(!this.restLead.campaignId) {
            this.restLead.campaignId = this.pageRef && this.pageRef.state && this.pageRef.state.campaignId ? this.pageRef.state.campaignId : null;
        }

        // if there are no utility accounts, add an empty one so the form will show fields to enter data
        if(this.propertyAccount && this.propertyAccount.utilityAccountLogs && this.propertyAccount.utilityAccountLogs.length === 0) {
            this.addUtilityAccount();
        }
        // set the values to properly display the utility portion of the form
        this.utilityAccountCount = this.propertyAccount.utilityAccountLogs.length;
        this.utilityAccountSection = this.utilityAccountCount;
        
        // if certain property values didn't come in from the api, find their values
        if (!this.stateOptions) {
            this.stateOptions = getUSStateOptionsFull();
        }
        if (this.pageRef && this.pageRef.state && this.pageRef.state.mock) {
            this.mockData();
        }
    }

    mockData() {
        this.restLead.firstName = 'Peter';
        this.restLead.lastName = 'Testcase';
        this.restLead.email = 'pyao@bluewavesolar.com';
        if(this.resiApplicationType) {
            this.restLead.mobilePhone = 1231231234;
        } else {
            this.restLead.businessPhone = 1231231234;
        }
        this.propertyAccount.utilityAccountLogs[0].utilityAccountNumber = '123';
        this.propertyAccount.utilityAccountLogs[0].nameOnAccount = 'Peter testcase';
        this.propertyAccount.utilityAccountLogs[0].serviceStreet = '123 Main';
        this.propertyAccount.utilityAccountLogs[0].serviceState = 'MA';
        this.propertyAccount.utilityAccountLogs[0].serviceCity = 'Boston';
        this.propertyAccount.utilityAccountLogs[0].servicePostalCode = this.zipinput;
    }


    // handle changes in form entries
    genericOnChange(event) {
        this.restLead[event.target.name] = event.target.value;
    }

    phoneOnChange(event) {
        const strippedPhone = event.target.value.replace(/\D/g,'');
        event.target.setCustomValidity("");
        if(strippedPhone.length === 10) {
            this.restLead[event.target.name] = strippedPhone.substr(0,3) + '-' + strippedPhone.substr(3,3) + '-' + strippedPhone.substr(6,4);
        } else {
            this.restLead[event.target.name] = strippedPhone;
            event.target.setCustomValidity("Please enter a 10-digit phone number");
        }
    }

    utilityAccountOnChange(event) {
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex][event.target.name] = event.target.value;
    }

    propertyAccountOnChange(event) {
        this.propertyAccount[event.target.name] = event.target.value;
    }

    billingAddressToggle(event) {
        this.sameBillingAddress = event.target.checked;
    }

    homeAddressToggle(event) {
        this.sameHomeAddress = event.target.checked;

    }

    addAnotherUtilityAccount() {
        if (!this.lastUtilityAccountValid()) {
            return;
        }
        
        this.addUtilityAccount();
    }

    addUtilityAccount() {
        this.utilityAccountCount++;
        this.propertyAccount.utilityAccountLogs.push({
            localid:this.utilityAccountCount,
            name: `Utility Account ${this.utilityAccountCount}`,
            servicePostalCode: this.zipinput,
            utilityId: this.selectedUtility.utilityId,
            doNotDelete: false,
            showUpload: true,
            utilityBills: []
        });
        setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
    }

    handleUtilityAccountMenu(event) {
        const selectedItemValue = event.detail.value;
        const utilityAccountIndex = event.target.name;
        if (selectedItemValue === 'remove') {
            this.propertyAccount.utilityAccountLogs.splice(utilityAccountIndex, 1);
            this.utilityAccountCount -= 1;
            setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
        }
    }


    // perform validations
    lastUtilityAccountValid() {
        let index = this.utilityAccountCount - 1;
        if (this.propertyAccount.utilityAccountLogs[index] &&
            this.propertyAccount.utilityAccountLogs[index].utilityAccountNumber &&
            this.propertyAccount.utilityAccountLogs[index].serviceStreet &&
            this.propertyAccount.utilityAccountLogs[index].serviceState &&
            this.propertyAccount.utilityAccountLogs[index].serviceCity &&
            this.propertyAccount.utilityAccountLogs[index].servicePostalCode) {
            return true;
        }
        this.showWarningToast('Warning', 'Please complete this utility account before adding another');
        return false;
    }

    applicationValid() {
        var allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        this.propertyAccount.utilityAccountLogs.forEach(ual => {
            if(!ual.utilityBills || ual.utilityBills.length === 0) {
                allValid = false;
                this.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
                    if(element.index === ual.index) {
                        element.addError();
                    }
                });
            }
        });
        
        if (!allValid) {
            this.showWarningToast('Warning!', 'Please verify your application before submitting');
            return false;
        }
        
        this.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
            element.removeError();
        });
        return true;
    }


    // submit form
    submitApplication() {
        if (!this.applicationValid()) {
            return;
        }

        if (this.sameBillingAddress) {
            this.propertyAccount.billingStreet = this.propertyAccount.utilityAccountLogs[0].serviceStreet;
            this.propertyAccount.billingCity = this.propertyAccount.utilityAccountLogs[0].serviceCity;
            this.propertyAccount.billingState = this.propertyAccount.utilityAccountLogs[0].serviceState;
            this.propertyAccount.billingPostalCode = this.propertyAccount.utilityAccountLogs[0].servicePostalCode;
        }
        if (this.sameHomeAddress) {
            this.restLead.streetAddress = this.propertyAccount.utilityAccountLogs[0].serviceStreet;
            this.restLead.city = this.propertyAccount.utilityAccountLogs[0].serviceCity;
            this.restLead.state = this.propertyAccount.utilityAccountLogs[0].serviceState;
            this.restLead.zipCode = this.propertyAccount.utilityAccountLogs[0].servicePostalCode;
        }
        this.propertyAccount.name = this.resiApplicationType ? `${this.restLead.firstName} ${this.restLead.lastName}` : this.restLead.businessName;
        this.restLead.propertyAccounts = [this.propertyAccount];

        this.showSpinner = true;
        window.setTimeout(() => {
            this.spinnerMessage = 'Saving your application';
        }, 3000);
        window.setTimeout(() => {
            this.spinnerMessage = 'We\'ll generate documents next.\r\nThis may take a minute, please stand by.';
        }, 6000);

        if(!this.resumedApp) {
            this.createLead(this.restLead).then(
                (resolveResult) => {
                    this.dispatchEvent(new CustomEvent('leadcreated', { detail: resolveResult }));
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
        } else {
            this.patchApplication(this.restLead).then(
                (resolveResult) => {
                    this.dispatchEvent(new CustomEvent('leadcreated', { detail: resolveResult }));
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
    }

    createLead = (restLead) => {
        let calloutURI = '/apply/services/apexrest/v3/leads';
        let options = {
            headers: {name: 'Content-Type', value:'application/json'},
            body: JSON.stringify(restLead)
        };
        return makeRequest(calloutURI, 'POST', options);
    };

    patchApplication = (restLead) => {
        let calloutURI = '/apply/services/apexrest/v3/application';
        let options = {
            headers: {name: 'Content-Type', value:'application/json'},
            body: JSON.stringify(restLead)
        };
        return makeRequest(calloutURI, 'PATCH', options);
    };

    showWarningToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }

    handleUpload(event) {
        let files = event.detail;
        let index = event.target.dataset.rowIndex;
        let ual = this.propertyAccount.utilityAccountLogs[index];
        files.forEach(file => {
            ual.utilityBills.push({
                id: file
            }); 
        });
    }
}