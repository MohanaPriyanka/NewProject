/**
 * Created by jeff on 1/16/21.
 */

import {LightningElement, track, api} from 'lwc';

export default class SsfInfoBox extends LightningElement {

    @track wrapperStyles = 'info-box-wrapper';

    closeOverlay() {
        this.postCloseEvent();
    }

    postCloseEvent() {
        const defaultStyles = this.wrapperStyles;
        this.wrapperStyles += ' fade-out';
        window.setTimeout(() => {
            this.dispatchEvent(new CustomEvent('close'));
            this.wrapperStyles = defaultStyles;
        }, 200);
    }

    get wrapperStyles() {
        return this.wrapperStyles;
    }
}