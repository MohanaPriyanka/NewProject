import { LightningElement, track, api, wire} from 'lwc';
import updateFileCategory from '@salesforce/apex/ContentService.setCategoryOnContentVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class bwFileUpload extends LightningElement {
    @api recordId;
    @api categoryType;
    @api acceptedFileTypes;

    get acceptedFormats() {
        return this.acceptedFileTypes;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        let idList = [];
        var i;
        for (i = 0; i < uploadedFiles.length; i++) {
            idList.push(uploadedFiles[i].documentId);
        }
        updateFileCategory({
            documentIdList : idList,
            category : this.categoryType
        })
        .catch((error) => {
            const event = new ShowToastEvent({
                title: 'Could not update Category on File: error',
                message: error.errorCode + ', ' + error.body.message,
            });
            this.dispatchEvent(event);
        });
    }
}