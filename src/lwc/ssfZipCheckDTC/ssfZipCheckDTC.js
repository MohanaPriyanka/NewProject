/**
 * Created by lindsayholmes_gearscrm on 2020-09-14
 */

import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import { connCallback, proceedWithSelectedUtility_shared, checkForSubmit_shared, getZipCapacity_shared } from 'c/ssfZipCheckShared';

export default class SsfZipCheckDTC extends NavigationMixin(LightningElement) {
    @api resiApplicationType;
    @api partnerId;
    @api zipCodeInput;

    @track zipCodeResponse;
    @track underwritingOptions = [];

    @track showSpinner = false;
    @track showModal = false;
    @track spinnerMessage;
    @track utilityOptions;
    @track selectedUtility;

    resiIconUrl = staticResourceFolder + '/Icon_House.png';
    bizIconUrl = staticResourceFolder + '/Icon_City.png';


    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
        connCallback(this);
    }

    renderedCallback() {
        const inputBox = this.template.querySelector('lightning-input');
        if (inputBox && !this.showModal) {
            inputBox.focus();
        }
    }



    // ///////////////////////////////////
    //      FORM EVENTS
    // ///////////////////////////////////
    proceedWithSelectedUtility() {
        proceedWithSelectedUtility_shared(this);
    }

    checkForSubmit(event) {
        checkForSubmit_shared(this, event);
    }

    submitZip(event) {
        getZipCapacity_shared(this, null);
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


    // ///////////////////////////////////
    //      STYLING
    // ///////////////////////////////////
    get getContainerStyle() {
        if(this.showModal || this.showSpinner) {
            return 'slds-backdrop slds-backdrop_open';
        }
        return '';
    }

    get getResiButtonStyle() {
        let style = 'icon-button';
        if(this.resiApplicationType) {
            style += ' selected';
        }
        return style;
    }

    get getBizButtonStyle() {
        let style = 'icon-button';
        if(!this.resiApplicationType) {
            style += ' selected';
        }
        return style;
    }
}