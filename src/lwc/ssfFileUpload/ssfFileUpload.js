import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import formFactorName from '@salesforce/client/formFactor';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import getDummyRecordId from  '@salesforce/apex/SimpleSignupFormController.getDummyRecordId';
import unlinkDocsFromDummy from '@salesforce/apex/SimpleSignupFormController.unlinkDocsFromDummyRecord';
import { reduceErrors } from "c/ldsUtils";
import insertLog from '@salesforce/apex/Logger.insertLog';

export default class SsfFileUpload extends LightningElement {
    @api required;
    @api inputText = 'Please select a file for upload.';
    @api index;
    @api recordId;
    @api categoryType;
    @api hasHelpText;
    @api acceptedFileTypes = ['.png', '.jpg', '.jpeg', '.pdf'];

    @track showSpinner = false;
    @track success = false;
    @track isError = false;
    @track isUtilityBill = this.categoryType === 'Customer Utility Bill';
    @track smallFormFactor = formFactorName === 'Small';
    @track documents = [];
    @track fileName;
    @track fileUrl;
    @track helpTextVisible = false;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        this.getDummyRecordForFileUpload(4);
    }

    getDummyRecordForFileUpload(numberOfRetries) {
        // A dummy record for the file upload is necessary for cases when the record to which the file should be attached
        // has not yet been created, and the relevant operations are taking place in the context of a site guest user.
        // Many other methods of achieving this upload were attempted (including a custom file upload component),
        // and none were successful in connecting the uploaded file to the new record.
        getDummyRecordId({})
        .then(result => {
            this.recordId = result;
        })
        .catch(error => {
            if (numberOfRetries === 0) {
                insertLog({
                    className: 'ssf',
                    methodName: 'getDummyRecordId',
                    message: 'Unable to find dummy record ID for site guest user file upload. ' + reduceErrors(error),
                    severity: 'Error'
                });
            }
        })
        .finally(() => {
           if (!this.recordId && numberOfRetries > 0) {
               numberOfRetries--;
               this.getDummyRecordForFileUpload(numberOfRetries);
           }
        });
    }

    handleUploadFinished(event) {
        this.showSpinner = true;
        var uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.documents.push(file.documentId);
        });
        this.removeDummyContentLinks();
    }

    removeDummyContentLinks() {
        unlinkDocsFromDummy({ documents: this.documents, category: this.categoryType })
        .then(() => {
            this.inputText = 'File uploaded successfully';
            this.success = true;
            this.showSpinner = false;
            const uploadEvent = new CustomEvent('fileuploaded', { detail: this.documents });
            this.dispatchEvent(uploadEvent);
        })
    }

    @api
    addError() {
        this.isError = true;
    }

    @api
    removeError() {
        this.isError = false;
    }

    hideHelp() {
        this.helpTextVisible = false;
    }

    toggleHelp() {
        this.helpTextVisible = !this.helpTextVisible;
    }

    get tooltipClasses() {
        let css = 'tooltip';
        if (this.isUtilityBill) {
            css += ' tooltip__utility';
        } else {
            css += ' tooltip__general';
        }
        return css;
    }
}