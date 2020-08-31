/**
 * Created by PeterYao on 2/24/2020.
 */

import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { makeRequest } from 'c/httpRequestService';
import { getZipCodeCapacity } from 'c/zipCodeService';
import insertLog from '@salesforce/apex/Logger.insertLog';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class Ssf extends NavigationMixin(LightningElement) {
    @api leadId;
    @api email;

    @track showSpinner = false;
    @track showModal = false;
    @track spinnerMessage;
    @track getZip;
    @track enterEmail;
    @track getBasicInfo;
    @track getAgreements;
    @track utilityOptions;
    @track zipCodeInput;
    @track leadJSON;
    @track selectedUtility;
    @track zipCodeResponse;
    @track partnerId;
    @track underwritingOptions = [];
    @track resiApplicationType = true;
    @wire(CurrentPageReference) pageRef;
    loc = '';

    resiIconUrl = staticResourceFolder + '/Icon_House.png';
    bizIconUrl = staticResourceFolder + '/Icon_City.png';

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');

        if (!this.utilityOptions) {
            this.utilityOptions = [];
        }

        if(this.pageRef && this.pageRef.state) {
            if(this.pageRef.state.partnerId) {
                this.resiApplicationType = false;
                this.partnerId = this.pageRef.state.partnerId;
            }
            if(this.pageRef.state.leadid) {
                this.getZip = false;
                this.leadId = this.pageRef.state.leadid;
                if(this.pageRef.state.loc) {
                    this.loc = this.pageRef.state.loc;
                }
                if(this.pageRef.state.email) {
                    this.email = this.pageRef.state.email;
                    if(!this.leadJSON) {
                        this.getLead();
                    } else {
                        this.getBasicInfo = true;
                    }
                } else {
                    this.enterEmail = true;
                }
            } else if(this.pageRef.state.zip) {
                this.getZip = true;
                this.zipCodeInput = this.pageRef.state.zip;
                this.showSpinner = true;
                this.spinnerMessage = 'Checking for projects...';
                this.getZipCodeCapacity(null, false);
            } else {
                this.getZip = true;
            }
        } else {
            this.getZip = true;
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
                    console.log('resolveResult:')
                    console.log(resolveResult);
                    this.leadJSON = JSON.stringify(resolveResult);
                    this.zipCodeInput = resolveResult.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode;
                    this.resiApplicationType = resolveResult.applicationType === 'Residential'; 
                    
                    if(resolveResult.utilityId) {
                        this.getZipCodeCapacity(resolveResult.utilityId, true);
                    } else {
                        this.getZipCodeCapacity(null, false);
                    }
                }
            )
            .catch(
                (rejectResult) => {
                    console.log('rejectResult:')
                    console.log(rejectResult);
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

    renderedCallback() {
        const inputBox = this.template.querySelector('lightning-input');
        if (inputBox && !this.showModal) {
            inputBox.focus();
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    applicationTypeOnChangeResi() {
        this.resiApplicationType = true;
    }
    
    applicationTypeOnChangeBiz() {
        this.resiApplicationType = false;
    }

    closeModal() {
        this.showModal = false;
    }

    proceedWithSelectedUtility() {
        this.showSpinner = true;
        this.selectedUtility = JSON.parse(this.selectedUtility);
        this.getZipCodeCapacity(this.selectedUtility.utilityId, false);
    }

    getZipCodeCapacity(utilityId, setLocation) {
        getZipCodeCapacity(this.zipCodeInput, this.partnerId, utilityId).then(
            (resolveResult) => {
                this.showSpinner = false;
                this.zipCodeResponse = JSON.stringify(resolveResult);
                if (resolveResult.hasCapacity && resolveResult.products.length >= 1) {
                    if(resolveResult.utilities && resolveResult.utilities.length === 1) {
                        if(resolveResult.ficoUnderwriting) {
                            this.underwritingOptions.push({label: 'Guarantor', value: 'FICO'});
                        }
                        if(resolveResult.finDocsUnderwriting) {
                            this.underwritingOptions.push({label: 'Financial Documents', value: 'Financial Review'});
                        }
                        this.selectedUtility = resolveResult.utilities[0];
                        this.showModal = false;
                        this.getZip = false;
                        this.enterEmail = false;

                        if(setLocation) {
                            this.setLocation();
                        } else {
                            this.getBasicInfo = true;
                        }
                    } else if(resolveResult.utilities && resolveResult.utilities.length > 1) {
                        this.utilityOptions = resolveResult.utilities.map(
                            utility => {
                                return {value: JSON.stringify(utility), label: utility.name};
                            }
                        );
                        this.getZip = true;
                        this.showModal = true;
                    }
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
        if(this.loc == 'pay') {
            this.dispatchEvent(new CustomEvent('consentscomplete', { detail: JSON.parse(this.leadJSON) }));
        } else if(this.loc == 'agree') {
            this.getAgreements = true;
            this.getBasicInfo = false;
        } else {
            this.getBasicInfo = true;
        }
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            const inputBox = this.template.querySelector('lightning-input');
            inputBox.reportValidity();
            if(inputBox.checkValidity()) {
                if(this.getZip) {
                    this.getZipCodeCapacity(null, false);
                } else if(this.enterEmail) {
                    this.getLead();
                }
            }
        }
    }

    submitZip(event) {
        this.getZipCodeCapacity(null, false);
    }

    handleLeadCreation(event) {
        this.leadJSON = JSON.stringify(event.detail);
        this.getAgreements = true;
        this.getBasicInfo = false;
        this.enterEmail = false;
    }

    handleConsentsComplete(event) {
        const consentsCompleteEvent = new CustomEvent('consentscomplete', {
            detail: event.detail
        });
        this.dispatchEvent(consentsCompleteEvent);
    }

    // ///////////////////////////////////
    //      STYLING
    // ///////////////////////////////////
    get getContainerStyle() {
        if(this.showModal || this.showSpinner) {
            return 'slds-backdrop slds-backdrop_open';
        }
        return '';
    }

    get getResiButtonStyle() {
        let style = 'icon-button';
        if(this.resiApplicationType) {
            style += ' selected';
        }
        return style;
    }

    get getBizButtonStyle() {
        let style = 'icon-button';
        if(!this.resiApplicationType) {
            style += ' selected';
        }
        return style;
    }
}