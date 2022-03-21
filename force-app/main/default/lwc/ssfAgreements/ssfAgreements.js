import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import companyPrivacyPolicyLink from '@salesforce/label/c.SSF_Company_Privacy_Policy_Link';
import companyShortName from '@salesforce/label/c.SSF_Company_Short_Name';
import {
    onLoad,
    onRender,
    displayDocument,
    showApproval,
    showNextApproval,
    consentsComplete,
    navigateBack,
    getText,
} from 'c/ssfAgreementsHelper';

export default class SsfAgreements extends LightningElement {
    @api leadJson;
    @api underwriting;
    @api version;

    @track disclosures;
    @track creditCheck;
    @track phoneConsent;
    @track communitySolarAgreement;
    @track showDisclosures = true;
    @track showCreditCheck;
    @track showPhoneConsent;
    @track showCommunitySolarAgreement;
    @track disclosuresIcon = 'utility:record';
    @track creditCheckIcon = 'utility:routing_offline';
    @track phoneConsentIcon = 'utility:routing_offline';
    @track communitySolarAgreementIcon = 'utility:routing_offline';
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
    label = {
        companyPrivacyPolicyLink,
        companyShortName
    }

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

    get isPartner() {
        return this.version === 'PARTNER';
    }

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
        return !this.showCommunitySolarAgreement ? 'Next' : this.lead.noPayment ? 'Finish' : 'Continue';
    }

    get ficoLanguage() {
        return getText(this, 'fico');
    }

    get finDocsLanguage() {
        return getText(this, 'finDocs');
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

    get phoneConsentLanguage() {
        return getText(this, 'phoneConsent');
    }

    hideContractDocument(event) {
        this.showContractDocument = false;
    }

    filePreview(event) {
        displayDocument(this, event);
    }

    handleApprovalChecked(event) {
        this[event.target.name] = event.target.checked;
    }

    handleCarouselPreviewClick(event) {
        showApproval(this, event.currentTarget.dataset.id);

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
        if (this.continueButtonLabel === 'Next') {
            showNextApproval(this);
            return;
        }
        consentsComplete(this);
    }
}