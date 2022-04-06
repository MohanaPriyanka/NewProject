import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import partnerSellsLMI from '@salesforce/apex/SimpleSignupFormController.partnerSellsLMI';
import { onLoad, proceedWithUtility, checkForSubmit, submitForm } from 'c/ssfZipCheckShared';

export default class SsfZipCheck extends NavigationMixin(LightningElement) {
    @api resiApplicationType;
    @api partnerId;
    @api zipCodeInput;
    @api applicationType;

    @track selectedUtility;
    @track showModal = false;
    @track underwritingOptions = [];
    @track utilityOptions;
    @track zipCodeResponse;
    @track showLMI = false;

    lmiIconUrl = staticResourceFolder + '/Icon_Perch_LMI.png';
    resiIconUrl = staticResourceFolder + '/Icon_Perch_House.png';
    bizIconUrl = staticResourceFolder + '/Icon_Perch_Business.png';


    connectedCallback() {
        onLoad(this);
        if(this.partnerId != null) {
            this.partnerSellsLMI();
        }
    }

    renderedCallback() {
        const inputBox = this.template.querySelector('lightning-input');
        if (inputBox && !this.showModal) {
            inputBox.focus();
        }
    }

    partnerSellsLMI() {
        partnerSellsLMI({partnerId: this.partnerId})
        .then(result => {
            this.showLMI = result;
        })
    }

    proceedWithSelectedUtility() {
        proceedWithUtility(this);
    }

    checkForSubmit(event) {
        checkForSubmit(this, event);
    }

    submitZip(event) {
        submitForm(this);
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    applicationTypeOnChangeResi(event) {
        this.resiApplicationType = true;
        this.applicationType = 'Residential'
    }
    
    applicationTypeOnChangeBiz(event) {
        this.resiApplicationType = false;
        this.applicationType = 'Non-Residential'
    }

    applicationTypeOnChangeLMI(event) {
        this.resiApplicationType = true;
        this.applicationType = 'LMI';
    }

    closeModal(event) {
        this.showModal = false;
    }

    get getContainerStyle() {
        if (this.showModal) {
            return 'slds-backdrop slds-backdrop_open';
        }
        return '';
    }

    get getResiButtonStyle() {
        let style = 'icon-button';
        if (this.resiApplicationType && this.applicationType !== 'LMI') {
            style += ' selected';
        }
        return style;
    }

    get getBizButtonStyle() {
        let style = 'icon-button';
        if (!this.resiApplicationType) {
            style += ' selected';
        }
        return style;
    }

    get getLMIButtonStyle() {
        let style = 'icon-button';
        if (this.applicationType === 'LMI') {
            style += ' selected';
        }
        return style;
    }

    get getIconContainerStyle() {
        let style = 'icon-button-group-container slds-wrap';
        if(!this.showLMI) {
            style = 'two-button-container slds-wrap';
        }
        return style;
    }
}