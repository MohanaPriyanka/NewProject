import { LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { loadApplication, retrieveApplication } from 'c/ssfShared';

export default class Ssf extends NavigationMixin(LightningElement) {
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
    isFico = true;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        loadApplication(this);
    }

    resumeApp() {
        retrieveApplication(this);
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            const inputBox = this.template.querySelector('lightning-input');
            inputBox.reportValidity();
            if (inputBox.checkValidity()) {
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

    showPaymentPage() {
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = false;
        
        const consentsCompleteEvent = new CustomEvent('consentscomplete', {
            detail: JSON.parse(this.leadJSON)
        });
        this.dispatchEvent(consentsCompleteEvent);
    }
}