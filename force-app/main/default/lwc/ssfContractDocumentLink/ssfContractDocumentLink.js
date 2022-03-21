/**
 * Created by rebeccanachison on 1/24/22.
 */

import {LightningElement, api} from 'lwc';

export default class SsfContractDocumentLink extends LightningElement {

    @api contractId;
    @api contractTitle;
    @api hasError;

    get linkClass() {
        return this.hasError ? 'ssf-contract-document-link__link ssf-contract-document-link__has-error' : 'ssf-contract-document-link__link';
    }

    handleFilePreview() {
        const filePreviewEvent = new CustomEvent('filepreview', {
            detail: {
                id: this.contractId,
            }
        });
        this.dispatchEvent(filePreviewEvent);
    }
}