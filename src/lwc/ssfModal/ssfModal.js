import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class ModalPopupLWC extends LightningElement {
    @api show;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }

    openModal() {
        this.show = true;
    }
}