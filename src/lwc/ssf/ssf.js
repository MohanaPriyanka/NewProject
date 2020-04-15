/**
 * Created by PeterYao on 2/24/2020.
 */

import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import {makeRequest} from 'c/httpRequestService';
import { getZipCodeCapacity } from 'c/zipCodeService';
import insertLog from '@salesforce/apex/Logger.insertLog';

export default class Ssf extends NavigationMixin(LightningElement) {
    @api leadId;
    @api email;

    @track showSpinner = false;
    @track spinnerMessage;
    @track getZip;
    @track getBasicInfo;
    @track getAgreements;
    @track hasCapacity;
    @track utilities;
    @track utilityOptions;
    @track zipCodeInput;
    @track leadJSON;
    @track selectedProduct;
    @track zipCodeResponse;
    @track resiApplicationType = true;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (!this.utilityOptions) {
            this.utilityOptions = [];
        }

        if(this.pageRef && this.pageRef.state && this.pageRef.state.leadid && this.pageRef.state.email) {
            this.getZip = false;
            this.leadId = this.pageRef.state.leadid;
            this.email = this.pageRef.state.email;
            if(!this.leadJSON) {
                this.getLead();
            } else {
                this.getBasicInfo = true;
            }
        } else {
            this.getZip = true;
            if (this.pageRef && this.pageRef.state && this.pageRef.state.partnerId) {
                this.resiApplicationType = false;
            }
        }
    }

    getLead() {
        this.showSpinner = true;
        this.spinnerMessage = 'Retrieving your application...';
        let calloutURI = '/apply/services/apexrest/v3/leads?leadId=' + this.leadId + '&email=' + this.email;
        let options = {
            headers: {name: 'Content-Type', value:'application/json'}
        };
        
        makeRequest(calloutURI, 'GET', options)
            .then(
                (resolveResult) => {
                    this.leadJSON = JSON.stringify(resolveResult);
                    this.zipCodeInput = resolveResult.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode;
                    this.resiApplicationType = resolveResult.applicationType === 'Residential';
                    this.selectedProduct = resolveResult.productName;
                    return getZipCodeCapacity(this.zipCodeInput, this.pageRef.state.partnerId);
                }
            )
            .then(
                (zipResolveResult) => {
                    this.showSpinner = false;
                    if(zipResolveResult.utilities && zipResolveResult.utilities.length >= 1) {
                        this.utilityOptions = zipResolveResult.utilities.map(
                            ({name}) => {
                                return {value: name, label: name};
                            }
                        );
                    }
                    this.getBasicInfo = true;
                }
            )
            .catch(
                (rejectResult) => {
                    this.showSpinner = false;
                    insertLog({
                        className: 'ssf',
                        methodName: 'getLead',
                        message: JSON.stringify(rejectResult),
                        severity: 'Error'
                    });
                    const evt = new ShowToastEvent({
                        title: 'Sorry, we ran into a technical problem',
                        message: 'Please contact Customer Care for help',
                        variant: 'warning'
                    });
                    this.dispatchEvent(evt);
                }
            );
    }

    renderedCallback() {
        const inputBox = this.template.querySelector('lightning-input');
        if (inputBox) {
            inputBox.focus();
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    applicationTypeOnChange(event) {
        this.resiApplicationType = event.target.checked;
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            const inputBox = this.template.querySelector('lightning-input');
            inputBox.reportValidity();
            if(inputBox.checkValidity()) {
                this.submitZip();
            }
        }
    }

    submitZip() {
        this.showSpinner = true;
        this.spinnerMessage = 'Checking for projects...';
        let partnerId;
        if (this.pageRef && this.pageRef.state && this.pageRef.state.partnerId) {
            partnerId = this.pageRef.state.partnerId;
        }
        getZipCodeCapacity(this.zipCodeInput, partnerId).then(
            (resolveResult) => {
                this.showSpinner = false;
                this.zipCodeResponse = resolveResult;
                if (this.zipCodeResponse.hasCapacity && this.zipCodeResponse.products.length >= 1) {
                    this.utilityOptions = this.zipCodeResponse.utilities.map(
                        ({name}) => {
                            return {value: name, label: name};
                        }
                    );
                    // Just picking the first one - could be a picklist if we found multiple products (SREC/SMART)
                    this.selectedProduct = this.zipCodeResponse.products[0];
                    const evt = new ShowToastEvent({
                        title: 'Success!',
                        message: 'Your ZIP Code is eligible.',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                    this.getZip = false;
                    this.getBasicInfo = true;
                } else {
                    const evt = new ShowToastEvent({
                        title: 'Sorry, your zip code is not eligible for service at this time',
                        message: 'Please check later',
                        variant: 'warning'
                    });
                    this.dispatchEvent(evt);
                }
            },
            (rejectResult) => {
                this.showSpinner = false;
                insertLog({
                    className: 'ssf',
                    methodName: 'submitZip',
                    message: JSON.stringify(rejectResult),
                    severity: 'Error'
                });
                const evt = new ShowToastEvent({
                    title: 'Sorry, we ran into a technical problem',
                    message: 'Please contact Customer Care for help',
                    variant: 'warning'
                });
                this.dispatchEvent(evt);
            }
        );
    }

    handleLeadCreation(event) {
        this.leadJSON = JSON.stringify(event.detail);
        this.getAgreements = true;
        this.getBasicInfo = false;
    }

    handleConsentsComplete(event) {
        const consentsCompleteEvent = new CustomEvent('consentscomplete', {
            detail: event.detail
        });
        this.dispatchEvent(consentsCompleteEvent);
    }
}