import { LightningElement, track, api, wire} from 'lwc';
import updateFileCategory from '@salesforce/apex/ContentService.setCategoryOnContentVersion';

export default class bwFileUpload extends LightningElement {
    @api recordId;
    @api categoryType;
    @api acceptedFileTypes;

    get acceptedFormats() {
        return this.acceptedFileTypes;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        updateFileCategory({
            contentDocumentId: uploadedFiles[0].documentId,
            category: this.categoryType
        })
        .catch((error) => {
            alert('Could not update Category on File: error' + error.errorCode + ', ' + error.body.message);
        });
    }
}