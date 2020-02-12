/**
 * Created by peteryao on 2/6/20.
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getZipCodeCapacity } from 'c/zipCodeService';
import { getUSStateOptions } from 'c/util';
import insertLog from '@salesforce/apex/Logger.insertLog';

export default class Switch extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track zipCodeInput;
    @track firstName;
    @track lastName;
    @track email;
    @track phone;
    @track billingStreet;
    @track billingCity;
    @track billingState;
    @track billingZip;
    @track hasCapacity;
    @track zipCodeResponse = false;
    @track selectedUtility;
    @track utilityOptions;
    @track utilityAccounts;
    @track utilityAccountSection;
    @track stateOptions;
    @track referralCode;
    utilityAccountCount = 1;
    @wire(CurrentPageReference) pageRef;

    connectedCallback() {
        if (!this.utilityAccounts) {
            this.utilityAccounts = [{
                id: 1,
                utilityAccountNumber: '',
                street: '',
                state: '',
                city: '',
                zip: ''
            }];
            this.utilityAccountSection = 1;
        }
        if (!this.stateOptions) {
            this.stateOptions = getUSStateOptions();
        }
        if (!this.utilityOptions) {
            this.utilityOptions = [];
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    utilityAccountOnChange(event) {
        this.utilityAccounts[event.target.dataset.rowIndex][event.target.name] = event.target.value;
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            this.submitZip();
        }
    }

    checkForTab(event) {
        if (event.which === 9) {

        }
    }

    submitZip() {
        this.showSpinner = true;
        let partnerId;
        if (this.pageRef && this.pageRef.state && this.pageRef.state.partnerId) {
            partnerId = this.pageRef.state.partnerId;
        }
        getZipCodeCapacity(this.zipCodeInput, partnerId).then(
            (resolveResult) => {
                this.showSpinner = false;
                this.zipCodeResponse = resolveResult;
                this.hasCapacity = this.zipCodeResponse.hasCapacity;
                if (this.hasCapacity) {
                    for (let u in this.zipCodeResponse.utilities) {
                        this.utilityOptions.push({
                            value: this.zipCodeResponse.utilities[u].name,
                            label: this.zipCodeResponse.utilities[u].name
                        });
                    }
                    if (this.zipCodeResponse.utilities.length === 1) {
                        this.selectedUtility = this.zipCodeResponse.utilities[0].name;
                    }
                    const evt = new ShowToastEvent({
                        title: 'We have capacity for you!',
                        message: 'Please provide your information to apply',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                } else {
                    const evt = new ShowToastEvent({
                        title: 'Sorry, no capacity at this time',
                        message: 'Please check later',
                        variant: 'warning'
                    });
                    this.dispatchEvent(evt);
                }
            },
            (rejectResult) => {
                this.showSpinner = false;
                insertLog({
                    className: 'switch',
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

    addAnotherUtilityAccount() {
        this.utilityAccountCount++;
        this.utilityAccounts.push({
            id:this.utilityAccountCount,
            utilityAccountNumber: '',
            street: '',
            state: '',
            city: '',
            zip: ''
        });
        setTimeout(() => this.utilityAccountSection = this.utilityAccountCount);
    }

    handleUtilityAccountMenu(event) {
        const selectedItemValue = event.detail.value;
        const utilityAccountIndex = event.target.name;
        if (selectedItemValue === 'copy') {
            this.utilityAccounts[utilityAccountIndex].street = this.billingStreet;
            this.utilityAccounts[utilityAccountIndex].city = this.billingCity;
            this.utilityAccounts[utilityAccountIndex].state = this.billingState;
            this.utilityAccounts[utilityAccountIndex].zip = this.billingZip;
        } else if (selectedItemValue === 'remove') {
            this.utilityAccounts.splice(utilityAccountIndex, 1);
        }
    }

    handleMoreLess(event) {
        let targetId = event.target.dataset.targetId;
        let moreText = this.template.querySelector('[data-id="' + targetId + '"]');
        let dots = this.template.querySelector('[data-id="' + targetId + 'Dots"]');

        if (dots.style.display === "none") {
            dots.style.display = "inline";
            moreText.style.display = "none";
            event.target.innerHTML = "[Show more]";
        } else {
            dots.style.display = "none";
            moreText.style.display = "inline";
            event.target.innerHTML = "[Show less]";
        }
    }

    submitApplication() {
        insertLog({
            className: 'switch',
            methodName: 'submitApplication',
            message: JSON.stringify(this.utilityAccounts),
            severity: 'Error'
        });
    }
}