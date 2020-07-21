/**
 * Created by JesseFox_GearsCRM on 7/6/2020.
 */

import { LightningElement, api, track } from 'lwc';

export default class SsfFooterCollapsible extends LightningElement {
    @api heading;
    @track isExpanded;

    get assistiveText() {
        return this.isExpanded ? 'Collapse Section' : 'Expand Section';
    }

    get buttonIconStyle() {
        let style = 'accordion-button__icon';
        if (this.isExpanded) {
            style += ' rotate';
        }
        return style;
    }

    onButtonIconClick(event) {
        this.isExpanded = !this.isExpanded;
    }
}