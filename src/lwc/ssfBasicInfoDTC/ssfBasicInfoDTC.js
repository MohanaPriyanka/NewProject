/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
 */

import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getUSStateOptionsFull } from 'c/util';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import { loadStyle } from 'lightning/platformResourceLoader';
import formFactorName from '@salesforce/client/formFactor';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { getFinDocFileTypes,
         getUnderwritingHelpText,
         getNewRestLead,
         getNewRestPropertyAccount,
         getNewRestUtilityAccountLog,
         validateUtilityAccountLog,
         setRemainingFields,
         setComponentUnderwritingVals,
         handleUnderwritingChange} from 'c/ssfBasicInfoShared';

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
        this.isPhone = (formFactorName === 'Small');
        
        if(this.zipCheckResponse) {
            this.zipCheckResponse = JSON.parse(this.zipCheckResponse);
            this.collectRateClass = this.zipCheckResponse.collectRateClass;
            if(this.zipCheckResponse.zipCode) {
                this.zipinput = this.zipCheckResponse.zipCode;
            }

            if(this.zipCheckResponse.products && this.zipCheckResponse.products.length > 0) {
                this.selectedProduct = this.zipCheckResponse.products[0];
            }

            if(this.zipCheckResponse.utilities && this.zipCheckResponse.utilities.length > 0 && this.zipCheckResponse.utilities[0].utilityId) {
                let selectedUtility = this.zipCheckResponse.utilities[0];
                this.utilityId = selectedUtility.utilityId;
    
                if(selectedUtility.dataCollectionMethod) {
                    this.isFileUpload = (selectedUtility.dataCollectionMethod !== 'EDI');
                } else {
                    this.isFileUpload = true;
                }
            } else {
                this.isFileUpload = true;
            }

            if(this.zipCheckResponse.rateClasses) {
                this.rateClassObj = Object.fromEntries(this.zipCheckResponse.rateClasses.map(
                    rateClass => ([rateClass.name, rateClass])
                ));

                if(this.collectRateClass) {
                    if(this.zipCheckResponse.rateClasses.length === 0) {
                        this.collectRateClass = false;
                    } else {
                        this.rateClassOptions = this.zipCheckResponse.rateClasses.map(
                            rateClass => ({ value: rateClass.name, label: rateClass.name })
                        );
                    }
                }
            }
        }

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
                    this.propertyAccount.utilityAccountLogs[i].showUpload = (this.isFileUpload && (!this.propertyAccount.utilityAccountLogs[i].utilityBills || this.propertyAccount.utilityAccountLogs[i].utilityBills.length === 0));
                    
                    if(this.propertyAccount.utilityAccountLogs[i].rateClass) {
                        this.selectedRateClasses.push(this.rateClassObj[this.propertyAccount.utilityAccountLogs[i].rateClass]);
                    }
                }
            }
            this.sameBillingAddress = this.propertyAccount.billingStreet == this.propertyAccount.utilityAccountLogs[0].serviceStreet;
            this.sameHomeAddress = this.restLead.streetAddress == this.propertyAccount.utilityAccountLogs[0].serviceStreet;
        } 
        // if no lead exists, set default values for restLead and propertyAccount
        else {
            this.restLead = getNewRestLead(this);
            this.propertyAccount = getNewRestPropertyAccount(this);
        }

        setComponentUnderwritingVals(this, this.resiApplicationType);

        if(!this.restLead.partnerId) {
            this.restLead.partnerId = this.partnerId;
        }

        if(!this.restLead.salesRepId) {
            this.restLead.salesRepId = this.salesRepId;
        }

        if(!this.restLead.campaignId) {
            this.restLead.campaignId = this.campaignId;
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
        if (this.mock) {
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
        this.propertyAccount.utilityAccountLogs[0].nameOnAccount = 'Peter Testcase';
        this.propertyAccount.utilityAccountLogs[0].serviceStreet = '123 Main';
        this.propertyAccount.utilityAccountLogs[0].serviceState = 'MA';
        this.propertyAccount.utilityAccountLogs[0].serviceCity = 'Boston';
        this.propertyAccount.utilityAccountLogs[0].servicePostalCode = this.zipinput;
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

    utilityAccountOnChange(event) {
        this.propertyAccount.utilityAccountLogs[event.target.dataset.rowIndex][event.target.name] = event.target.value;        
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

    applicationValid() {
        var allValid = [...this.template.querySelectorAll('lightning-input'), ...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if(this.isFileUpload) {
            var uploadValid = true;
            this.propertyAccount.utilityAccountLogs.forEach(ual => {
                if(!ual.utilityBills || ual.utilityBills.length === 0) {
                    uploadValid = false;
                }
            });
            if(!uploadValid) {
                allValid = false;    
                this.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
                    if(element.categoryType === 'Customer Utility Bill') {
                        element.addError();
                    }
                });
            }
        }
        if(!this.resiApplicationType && !this.isFico && (!this.restLead.financialDocs || this.restLead.financialDocs.length ===0)) {
            this.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
                if(element.categoryType === 'Financial Review Documents') {
                    element.addError();
                }
            });
        }
        
        if(!allValid) {
            this.showWarningToast('Warning!', 'Please verify your application before submitting');
            return false;
        }
        
        this.template.querySelectorAll('c-ssf-file-upload').forEach(element => {
            element.removeError();
        });
        return true;
    }

    // upsert Lead into Salesforce, submit form
    submitApplication() {

        // if application invalid, cease upsert
        if (!this.applicationValid()) {
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

    getNumberOfDocs() {
        if(!this.selectedProduct || !this.selectedProduct.standaloneDisclosureForm) {
            return 1;
        }

        if(this.selectedRateClasses.length === 0) {
            return 2;
        }

        let allSuppress = true;
        this.selectedRateClasses.forEach(rateClass => {
            if(!rateClass.suppressDisclosureForm) {
                allSuppress = false;
            }
        });

        if(allSuppress) {
            return 1;
        }

        return 2;
    }

    toggleHelp() {
        this.helpTextVisible = !this.helpTextVisible;
    }

    get underwritingHelpText() {
        return getUnderwritingHelpText();
    }
}