import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
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

    resiIconUrl = staticResourceFolder + '/Icon_House.png';
    bizIconUrl = staticResourceFolder + '/Icon_City.png';

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        onLoad(this);
    }

    renderedCallback() {
        const inputBox = this.template.querySelector('lightning-input');
        if (inputBox && !this.showModal) {
            inputBox.focus();
        }
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
    }
    
    applicationTypeOnChangeBiz(event) {
        this.resiApplicationType = false;
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
        if (this.resiApplicationType) {
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
}