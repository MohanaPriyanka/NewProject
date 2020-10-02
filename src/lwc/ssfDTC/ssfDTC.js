/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
 */

import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getZipCodeCapacity } from 'c/zipCodeService';
import { makeRequest } from 'c/httpRequestService';
import insertLog from '@salesforce/apex/Logger.insertLog';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { validateBasicInfoCompleted, getNumberOfDocsForExistingLead } from 'c/ssfShared';

export default class SsfDTC extends NavigationMixin(LightningElement) {
    @api leadId;
    @api email;

    @track resiApplicationType = true;
    @track partnerId;
    @track zipCodeInput;
    @track zipCodeResponse;
    @track leadJSON;
    @track underwritingOptions = [];
    @track salesRepId;
    @track campaignId;
    @track mock;
    @track getEmail;
    @track getZip;
    @track getBasicInfo;
    @track getAgreements;
    @track showSpinner = false;
    @track spinnerMessage;

    @wire(CurrentPageReference) pageRef;

    loc = '';
    isFico;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');

        if(this.pageRef && this.pageRef.state) {
            if(this.pageRef.state.partnerId) {
                this.resiApplicationType = false;
                this.partnerId = this.pageRef.state.partnerId;
            }

            if(this.pageRef.state.salesRepId) {
                this.salesRepId = this.pageRef.state.salesRepId;
            }

            if(this.pageRef.state.campaignId) {
                this.campaignId = this.pageRef.state.campaignId;
            }

            if(this.pageRef.state.mock) {
                this.mock = this.pageRef.state.mock;
            }
            
            if(this.pageRef.state.leadid) {
                this.leadId = this.pageRef.state.leadid;
                if(this.pageRef.state.loc) {
                    this.loc = this.pageRef.state.loc;
                }
                if(this.pageRef.state.email) {
                    this.email = this.pageRef.state.email;
                    if(!this.leadJSON) {
                        this.getLead();
                    } else {
                        this.showBasicInfoPage();
                    }
                } else {
                    this.showEnterEmailPage();
                }
            } else if(this.pageRef.state.zip) {
                this.zipCodeInput = this.pageRef.state.zip;
                this.showGetZipCodeCapacityPage();
            } else {
                this.showGetZipCodeCapacityPage();
            }
        } else {
            this.showGetZipCodeCapacityPage();
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
                    this.getZipCodeCapacity(resolveResult.utilityId, true);
                }
            )
            .catch(
                (rejectResult) => {
                    this.showSpinner = false;
                    let fail = typeof rejectResult === 'object' ? rejectResult : JSON.parse(rejectResult);
                    if(fail.errors && fail.errors[0].substr(0,21) === 'Invalid authorization') {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Authentication Failure',
                            message: 'The email address you provided does not match the application on file.',
                            variant: 'warning'
                        }));
                    } else {
                        insertLog({
                            className: 'ssf',
                            methodName: 'getLead',
                            message: rejectResult,
                            severity: 'Error'
                        });
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Sorry, we ran into a technical problem',
                            message: 'Please contact Customer Care for help',
                            variant: 'warning'
                        }));
                    }
                }
            );
    }

    getZipCodeCapacity(utilityId, setLocation) {
        getZipCodeCapacity(this.zipCodeInput, this.partnerId, utilityId).then(
            (resolveResult) => {
                this.showSpinner = false;
                this.zipCodeResponse = JSON.stringify(resolveResult);
                if(resolveResult.ficoUnderwriting) {
                    this.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
                }
                if(resolveResult.finDocsUnderwriting) {
                    this.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
                }

                if(setLocation) {
                    this.setLocation();
                } else {
                    this.showBasicInfoPage();
                }
            },
            (rejectResult) => {
                this.showSpinner = false;
                insertLog({
                    className: 'ssf',
                    methodName: 'getZipCodeCapacity',
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

    setLocation() {
        if(validateBasicInfoCompleted(this.zipCodeResponse, this.leadJSON)) {
            if(this.loc == 'pay') {
                this.showPaymentPage(JSON.parse(this.leadJSON));
            } else if(this.loc == 'agree') {
                let lead = JSON.parse(this.leadJSON);
                if(!lead.numberOfContractDocs) {
                    const capacity = JSON.parse(this.zipCodeResponse);
                    lead.numberOfContractDocs = getNumberOfDocsForExistingLead(lead, capacity);
                    this.leadJSON = JSON.stringify(lead);
                }
                this.showAgreementsPage();
            } else {
                this.showBasicInfoPage();
            }
        } else {
            this.showBasicInfoPage();
        }
    }

    // ///////////////////////////////////
    //      EVENT HANDLING
    // ///////////////////////////////////
    checkForSubmit(event) {
        if (event.which === 13) {
            const inputBox = this.template.querySelector('lightning-input');
            inputBox.reportValidity();
            if(inputBox.checkValidity()) {
                this.getLead();
            }
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleCapacityCheckComplete(event) {
        this.zipCodeResponse = event.detail.zipCodeResponse;
        this.underwritingOptions = event.detail.underwritingOptions;
        this.resiApplicationType = event.detail.resiApplicationType;
        this.showBasicInfoPage();
    }

    handleLeadCreation(event) {
        this.leadJSON = JSON.stringify(event.detail);
        this.showAgreementsPage();
    }

    handleConsentsComplete(event) {
        this.showPaymentPage(event.detail);
    }

    setUnderwritingMethod(event) {
        this.isFico = event.detail;
    }

    // ///////////////////////////////////
    //      PAGE DISPLAY HANDLING
    // ///////////////////////////////////
    showEnterEmailPage() {
        this.getEmail = true;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = false;
    }

    showGetZipCodeCapacityPage() {
        this.getEmail = false;
        this.getZip = true;
        this.getBasicInfo = false;
        this.getAgreements = false;
    }

    showBasicInfoPage() {
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = true;
        this.getAgreements = false;
    }

    showAgreementsPage() {
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = true;
    }

    showPaymentPage(lead) {
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = false;
        
        const consentsCompleteEvent = new CustomEvent('consentscomplete', {
            detail: lead
        });
        this.dispatchEvent(consentsCompleteEvent);
    }
}