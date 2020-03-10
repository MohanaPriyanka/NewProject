/**
 * Created by peteryao on 2/28/20.
 */

import {LightningElement, api, track} from 'lwc';

export default class BluewaveSpinner extends LightningElement {
    @api spinnerMessage;
    @api show;

    renderedCallback() {
        const span = this.template.querySelector('span');
        if (span) {
            span.classList.remove("spinner-message");
            span.classList.add("spinner-message");
        }
    }
}