/* Uses Signature Pad library https://github.com/szimek/signature_pad */

import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import saveSignature from '@salesforce/apex/SimpleSignupFormController.saveSignature';
import signaturePadScript from '@salesforce/resourceUrl/SignaturePad';

export default class SsfSignature extends LightningElement {

    @api label;
    @api helpMessage;
    hasValidationError = false;

    signaturePadInitialized = false;
    // canvasWidth = 400;
    canvasHeight = 95;

    get canvasWidth() {
        let fullWidth = window.screen.width - 32 - 24 - 32 - 24; // screen width - center panel padding - content region padding - page container padding - p padding
        return Math.min(400, fullWidth);
    }

    get canvasWrapperStyle() {
        return `width:${this.canvasWidth}px`;
    }

    renderedCallback() {
        if (this.signaturePadInitialized) {
            return;
        }
        this.signaturePadInitialized = true;

        Promise.all([
            loadScript(this, signaturePadScript)
        ])
        .then(() => {
            this.initialize();
        })
        .catch(error => {
            //log error
            console.log(error);
        });
    }

    initialize() {
        const canvas = this.template.querySelector('canvas.ssf-signature__canvas');
        this.signaturePad = new SignaturePad(canvas, {
            backgroundColor: 'rgba(255,255,255,0)',
            penColor: '#0D2727', // Perch Forest green
        });
        // remove error styling after signature drawn
        this.signaturePad.onEnd = () => { this.hasValidationError = false };
    }

    // clear the signature from canvas
    handleClearClick() {
        this.signaturePad.clear();
    }

    // handler for continue click on parent
    // checks for non-empty signature
    @api handleCheckSignature() {
        return !this.signaturePad.isEmpty();
    }

    // handler to perform save operation
    @api handleSaveSignature(leadId) {
        this.addTimestampToImage()
        //convert to png image
        let dataURL = this.signaturePad.toDataURL('image/png');
        //convert to base64 encoding
        let convertedDataURI = dataURL.replace(/^data:image\/(png|jpg);base64,/, '');
        //save signature image as a content document, return content version id to use in image url for conga merge template
        return saveSignature({
            fileContent: convertedDataURI,
            leadId: leadId
        });
    }

    addTimestampToImage() {
        let timestamp = Date();
        this.signaturePad._ctx.fillStyle = '#000';
        this.signaturePad._ctx.font = '10px sans-serif';
        this.signaturePad._ctx.fillText(timestamp, 0, 10);
    }

    @api handleAddValidationError() {
        this.hasValidationError = true;
    }

    @api get required() {
        return this._required;
    }

    set required(value) {
        this._required = value === 'string' || !!value;
    }

    get formElementClass() {
        return this.hasValidationError ? 'slds-form-element slds-has-error' : 'slds-form-element';
    }

}