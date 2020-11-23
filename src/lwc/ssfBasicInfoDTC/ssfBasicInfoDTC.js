import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import { loadStyle } from 'lightning/platformResourceLoader';
import formFactorName from '@salesforce/client/formFactor';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import {
    onLoad,
    getFinDocFileTypes,
    getUnderwritingHelpText,
    getNewRestUtilityAccountLog,
    validateUtilityAccountLog,
    setRemainingFields,
    handleUnderwritingChange,
    verifyUtilityAccountEntry,
    validateServiceZipCode,
    applicationValid,
} from 'c/ssfBasicInfoShared';

export default class SsfBasicInfo extends NavigationMixin(LightningElement) {
    @api leadJson;
    @api resiApplicationType;
    @api zipCheckResponse;
    @api underwritingOptions;
    @api partnerId;
    @api salesRepId;
    @api campaignId;
    @api mock;

    @track zipinput;
    @track collectRateClass;
    @track selectedUtility;
    @track selectedProduct;
    @track rateClassOptions;
    @track rateClassObj;
    @track utilityId;
    @track restLead;
    @track propertyAccount;
    @track stateOptions;
    @track selectedRateClasses = [];
    @track showSpinner;
    @track sameBillingAddress = true;
    @track sameHomeAddress = true;
    @track utilityAccountSection;
    @track isFileUpload;
    @track showUnderwritingOptions;
    @track showAddress;
    @track isPhone;
    @track helpTextVisible;

    isFico = true;
    utilityAccountCount = 0;
    resumedApp = false;
    finDocFileTypes = getFinDocFileTypes();

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        onLoad(this);
        this.isPhone = (formFactorName === 'Small');
    }

    // handle changes in form entries
    genericOnChange(event) {
        this.restLead[event.target.name] = event.target.value;

        if (event.target.name === 'underwritingCriteria') {
            // need to handle applicant's selection on underwriting field, either FICO or Financial Documents
            this.isFico = event.target.value === 'FICO';
            handleUnderwritingChange(this);
        }
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

    preventDefaultEvent(event) {
        event.preventDefault();
    }

    utilityAccountOnChange(event) {
        let eventField = event.target.name;
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex][eventField] = event.target.value;
        if (eventField === 'utilityAccountNumber' || eventField === 'utilityAccountNumberReentry') {
            verifyUtilityAccountEntry(this, event, eventField);
        }
        if (eventField === 'servicePostalCode' && event.target.value.length === 5) {
            validateServiceZipCode(this, event);
        }
    }

    handleZipEntry(event) {
        validateServiceZipCode(this, event);
    }

    rateClassOnChange(event) {
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex].rateClass = event.target.value;
        this.selectedRateClasses.push(this.rateClassObj[event.target.value]);
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
        this.propertyAccount.utilityAccountLogs.push(getNewRestUtilityAccountLog(this));
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
        if(validateUtilityAccountLog(this.propertyAccount.utilityAccountLogs[index])) {
            return true;
        }
        this.showWarningToast('Warning', 'Please complete this utility account before adding another');
        return false;
    }

    // upsert Lead into Salesforce, submit form
    submitApplication() {

        // if application invalid, cease upsert
        if (!applicationValid(this)) {
            return;
        }

        // set remaining fields on restLead, including some address fields
        setRemainingFields(this, this.sameHomeAddress);
        this.showSpinner = true;
        
        if (!this.resumedApp) {
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
        }
        else {
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
            body: JSON.stringify(this.restLead)
        };

        return makeRequest(calloutURI, 'POST', options);
    };

    patchApplication = (restLead) => {
        let calloutURI = '/apply/services/apexrest/v3/application';
        let options = {
            headers: {name: 'Content-Type', value:'application/json'},
            body: JSON.stringify(this.restLead)
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

    handleUtilityBillUpload(event) {
        let files = event.detail;
        let index = event.target.dataset.rowIndex;
        let ual = this.propertyAccount.utilityAccountLogs[index];
        files.forEach(file => {
            ual.utilityBills.push({
                id: file
            }); 
        });
    }

    handleFinancialDocsUpload(event) {
        let files = event.detail;
        files.forEach(file => {
            this.restLead.financialDocs.push({
                id: file
            }); 
        });
    }

    toggleHelp() {
        this.helpTextVisible = !this.helpTextVisible;
    }

    get underwritingHelpText() {
        return getUnderwritingHelpText();
    }
}