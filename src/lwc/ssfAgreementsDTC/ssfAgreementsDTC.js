import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import {
    onLoad,
    onRender,
    disclosureSigned,
    creditCheckSigned,
    communitySolarAgreementSigned,
    displayDocument,
    showCreditCheckApproval,
    consentsComplete,
    navigateBack,
    getText,
} from 'c/ssfAgreementsShared';

export default class SsfAgreementsDTC extends LightningElement {
    @api leadJson;
    @api underwriting;

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

    lead;
    documentPollerId;
    documentPollerTimeoutId;
    esignDisclosureUrl = getText(this, 'esignUrl');
    version = 'DTC';

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css')
        onLoad(this);
        window.scrollTo(0, 0);
    }

    renderedCallback() {
        onRender(this);
    }

    get supportsDataUri() {
        // trident = IE
        const navua = window.navigator.userAgent.toLowerCase();
        return !(navua.indexOf("trident") > -1 || navua.indexOf("edge") > -1);
    };

    get creditCheckLabel() {
        return getText(this, 'creditCheckLabel');
    }

    get isFicoUnderwriting() {
        return this.underwriting === 'FICO';
    }

    get isFinDocsUnderwriting() {
        return this.underwriting === 'Financial Review';
    }

    get isUtilityDataConsentOnly() {
        return this.underwriting === 'None';
    }

    get renderCreditCheckLanguage() {
        return this.isFicoUnderwriting || this.isFinDocsUnderwriting || this.isUtilityDataConsentOnly;
    }

    get continueButtonLabel() {
        return this.lead.noPayment ? 'Finish' : 'Continue';
    }

    get ficoLanguageFirstSegment() {
        return getText(this, 'fico1');
    }

    get ficoLanguageSecondSegment() {
        return getText(this, 'fico2');
    }

    get finDocsLanguageFirstSegment() {
        return getText(this, 'finDocs1');
    }

    get finDocsLanguageSecondSegment() {
        return getText(this, 'finDocs2');
    }

    get utilityDataReviewLanguage(){
        return getText(this, 'utilityDataReview')
    }

    get disclosureLanguageFirstSegment() {
        return getText(this, 'disclosure1');
    }

    get disclosureLanguageSecondSegment() {
        return getText(this, 'disclosure2');
    }

    get agreementLanguageFirstSegment() {
        return getText(this, 'agree1');
    }

    get agreementLanguageSecondSegment() {
        return getText(this, 'agree2');
    }

    get agreementLanguageThirdSegment() {
        return getText(this, 'agree3');
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

    showCreditCheckApproval(event) {
        showCreditCheckApproval(this);
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