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
    @track getEmail;
    @track getZip;
    @track getBasicInfo;
    @track getAgreements;
    @track readyState = false;
    @track showSpinner = false;
    @track spinnerMessage = 'Loading...';

    @wire(CurrentPageReference) pageRef;

    loc = '';
    init = true;
    underwriting = 'FICO'; // Defaulted to FICO

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        loadApplication(this);
    }

    renderedCallback() {
        if (this.getEmail) {
            this.readyState = true;
            const inputBox = this.template.querySelector(`[data-id=emailEntry]`);
            inputBox.focus();
        }
    }

    resumeApp() {
        retrieveApplication(this);
    }

    get containerStyles() {
        if (!this.readyState || this.init) {
            this.init = false;
            return 'page-container no-display';
        } else if (this.readyState) {
            return 'page-container fade-in';
        } else {
            return 'page-container';
        }
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            const inputBox = this.template.querySelector('lightning-input');
            inputBox.reportValidity();
            if (inputBox.checkValidity()) {
                retrieveApplication(this);
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

    handleNavigateBackToBasicInfo(event) {
        this.showBasicInfoPage();
    }

    setUnderwritingMethod(event) {
        this.underwriting = event.detail;
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
        this.readyState = false;
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = true;
        this.getAgreements = false;
    }

    showAgreementsPage() {
        this.readyState = false;
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = true;
    }

    showPaymentPage() {
        this.readyState = false;
        this.getEmail = false;
        this.getZip = false;
        this.getBasicInfo = false;
        this.getAgreements = false;
        this.showSpinner = false;
        window.scrollTo(0,0);
        const consentsCompleteEvent = new CustomEvent('consentscomplete', {
            detail: JSON.parse(this.leadJSON)
        });
        this.dispatchEvent(consentsCompleteEvent);
    }

    handleReadyStateEvent(event) {
        const location = event.detail;
        switch (location) {
            case 'info':
                this.showBasicInfoPage();
                break;
            default:
                this.readyState = true;
        }
    }

    handleResetReadyStateEvent() {
        this.readyState = false;
    }

    handleSpinnerMessageEvent(event) {
        this.spinnerMessage = event.detail;
    }

    toggleLoadingSpinner(event) {
        const turnOff = event.detail.toggleOff;
        this.showSpinner = !turnOff;
    }
}