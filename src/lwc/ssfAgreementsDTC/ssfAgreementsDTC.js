/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
 */

import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { connCallback,
         rendCallback,
         disclosureChecked_shared,
         creditCheckChecked_shared,
         csAgreementChecked_shared,
         filePreview_shared,
         showDisclosureApproval_shared,
         showCreditCheckApproval_shared,
         showCSAgreementApproval_shared,
         continueAgreement_shared,
         getCreditCheckLabel } from 'c/ssfAgreementsShared';

export default class SsfAgreementsDTC extends LightningElement {
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
        var navua = window.navigator.userAgent.toLowerCase();
        // trident = IE
        if(navua.indexOf("trident") > -1 || navua.indexOf("edge") > -1) {
            return false;
        }
        return true;
    };

    get creditCheckLabel() {
        return getCreditCheckLabel(this);
    }

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css')
        connCallback(this);
    }

    renderedCallback() {
        rendCallback(this);
    }

    hideContractDocument(event) {
        this.showContractDocument = false;
    }

    disclosureChecked(event) {
        disclosureChecked_shared(this, event);
    }

    creditCheckChecked(event) {
        creditCheckChecked_shared(this, event);
    }

    showLessCreditCheck(event) {
        this.moreCreditCheck = false;
    }

    showMoreCreditCheck(event) {
        this.moreCreditCheck = true;
    }

    csAgreementChecked(event) {
        csAgreementChecked_shared(this, event);
    }

    filePreview(event) {
        filePreview_shared(this, event);
    }

    showLessCSAgreement(event) {
        this.moreCSAgreement = false;
    }

    showMoreCSAgreement(event) {
        this.moreCSAgreement = true;
    }

    showDisclosureApproval(event) {
        showDisclosureApproval_shared(this);
    }

    showCreditCheckApproval(event) {
        showCreditCheckApproval_shared(this);
    }

    showCSAgreementApproval(event) {
        showCSAgreementApproval_shared(this);
    }

    checkForSubmit(event) {
        if (event.which === 13) {
            this.continueAgreement(event);
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    continueAgreement(event) {
        continueAgreement_shared(this);
    }
}