/**
 * Created by rebeccanachison on 10/4/21.
 */

import {LightningElement, api} from 'lwc';

export default class CustomerPortalProjectDetails extends LightningElement {

    @api project;
    @api showModal;

    handleCloseModal() {
        const closeEvent = new CustomEvent('closemodal', {
            detail: {showModal: false}
        });
        this.dispatchEvent(closeEvent);
    }

}