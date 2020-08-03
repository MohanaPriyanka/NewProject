import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import getDummyRecordId from  '@salesforce/apex/SimpleSignupFormController.getDummyRecordId';
import unlinkDocsFromDummy from '@salesforce/apex/SimpleSignupFormController.unlinkDocsFromDummyRecord';
import insertLog from '@salesforce/apex/Logger.insertLog';

export default class SsfFileUpload extends LightningElement {
    @api required;
    @api inputText;
    @api index;
    @api recordId;

    @track showSpinner = false;
    @track success = false;
    @track isError = false;
    @track documents = [];
    @track fileName;
    @track fileUrl;
    @track helpTextVisible = false;
    
    acceptedFileTypes = ['.png', '.jpg', '.jpeg', '.pdf'];


    // a dummy record for the file upload is necessary for cases when the record to which the file should be attached
    // has not yet been created, and the relevant operations are taking place in the context of a site guest user.
    // many other methods of achieving this upload were attempted (including a custom file upload component),
    // and none were successful in connecting the uploaded file to the new record.

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        if(!this.inputText) {
            this.inputText = 'Please select a file for upload.';
        }
        if(!this.categoryType) {
            this.categoryType = 'Customer Utility Bill';
        }
        if(!this.recordId) {
            getDummyRecordId({ })
                .then(result => {
                    this.recordId = result;
                })
                .catch(error => {
                    insertLog({
                        className: 'ssf',
                        methodName: 'getDummyRecordId',
                        message: 'Unable to find dummy record ID for site guest user file upload. ' + JSON.stringify(error.body.message),
                        severity: 'Error'
                    });
                })
        }
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
            .then(result => {
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

    showHelp() {
        this.helpTextVisible = true;
    }

    hideHelp() {
        this.helpTextVisible = false;
    }

    toggleHelp() {
        this.helpTextVisible = !this.helpTextVisible;
    }

    get getHelpClass() {
        var classes = 'slds-popover slds-popover_tooltip slds-nubbin_left-top slds-text-align_left ms-help-popup-in-header';
        if(this.helpTextVisible) {
            return classes;
        }
        return classes + ' slds-hide';
    }
}