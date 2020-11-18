import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { onLoad,
         onRender,
         disclosureSigned,
         creditCheckSigned,
         communitySolarAgreementSigned,
         displayDocument,
         showDisclosureApproval,
         showCreditCheckApproval,
         showCSAgreementApproval,
         consentsComplete,
         getCreditCheckLabel,
         navigateBack
} from 'c/ssfAgreementsShared';

export default class SsfAgreements extends LightningElement {
    @api leadJson;
    @api isFico;

    @track disclosures;
    @track creditCheck;
    @track csAgreement;
    @track showDisclosures = true;
    @track showCreditCheck;
    @track showCSAgreement;
    @track disclosureIcon = 'utility:record';
    @track creditCheckIcon = 'utility:routing_offline';
    @track csAgreementIcon = 'utility:routing_offline';
    @track moreCreditCheck = false;
    @track moreCSAgreement = false;
    @track consentEmail;
    @track documentUrl;
    @track contractDocuments;
    @track csAgreementDocumentId;
    @track disclosureDocumentId;
    @track showContractDocument;
    @track showSpinner;
    @track spinnerMessage;

    lead;
    documentPollerId;
    documentPollerTimeoutId;
    mostRecentDocDate;

    get supportsDataUri() {
        // trident = IE
        const navua = window.navigator.userAgent.toLowerCase();
        return !(navua.indexOf("trident") > -1 || navua.indexOf("edge") > -1);
    };

    get creditCheckLabel() {
        return getCreditCheckLabel(this);
    }

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css')
        onLoad(this);
        window.scrollTo(0, 0);
    }

    renderedCallback() {
        onRender(this);
    }

    hideContractDocument(event) {
        this.showContractDocument = false;
    }

    disclosureChecked(event) {
        disclosureSigned(this, event);
    }

    creditCheckChecked(event) {
        creditCheckSigned(this, event);
    }

    showLessCreditCheck(event) {
        this.moreCreditCheck = false;
    }

    showMoreCreditCheck(event) {
        this.moreCreditCheck = true;
    }

    csAgreementChecked(event) {
        communitySolarAgreementSigned(this, event);
    }

    filePreview(event) {
        displayDocument(this, event);
    }

    showLessCSAgreement(event) {
        this.moreCSAgreement = false;
    }

    showMoreCSAgreement(event) {
        this.moreCSAgreement = true;
    }

    showDisclosureApproval(event) {
        showDisclosureApproval(this);
    }

    showCreditCheckApproval(event) {
        showCreditCheckApproval(this);
    }

    showCSAgreementApproval(event) {
        showCSAgreementApproval(this);
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            this.continueAgreement(event);
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleBackButton(event) {
        navigateBack(this);
    }

    continueAgreement(event) {
        consentsComplete(this);
    }
}