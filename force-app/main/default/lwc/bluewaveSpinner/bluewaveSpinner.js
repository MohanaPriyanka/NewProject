/**
 * Created by peteryao on 2/28/20.
 */

import {LightningElement, track, api} from 'lwc';

export default class BluewaveSpinner extends LightningElement {
    @api spinnerMessage;
    @api show;
    @api fadeIn;
    @api fadeOut() {
        this.styles = 'fade-out';
        window.setTimeout(() => {
            this.setStyles();
        }, 300);
    }
    @track styles = '';

    connectedCallback() {
        this.setStyles();
    }

    get messageBoxStyles() {
        return `slds-align--absolute-center slds-spinner_container background-box slds-p-around_medium  ${this.styles}`;
    }

    setStyles() {
        if (this.fadeIn) {
            this.styles = 'fade-in';
        } else {
            this.styles = '';
        }
    }

    get containerStyles() {
        return `slds-spinner_container ${this.styles}`;
    }

}