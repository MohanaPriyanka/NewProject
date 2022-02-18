import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import formFactorName from '@salesforce/client/formFactor';
import sendContinueApplicationEmail from '@salesforce/apex/SimpleSignupFormController.sendContinueApplicationEmail'
import emailPartnerSupport from '@salesforce/label/c.SSF_Email_Partner_Support';

export default class duplicateModal extends LightningElement {
    @api show;
    @api leadId;

    @track isPhone;
    @track emailSent;

    label = {
        emailPartnerSupport,
        emailPartnerSupportLink: 'mailto:' + emailPartnerSupport
    }

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        this.isPhone = (formFactorName === 'Small');
    }

    openModal() {
        this.show = true;
    }

    closeModal() {
        this.show = false;
    }

    sendEmail() {
        sendContinueApplicationEmail({leadId: this.leadId})
        this.emailSent = true;
    }
}