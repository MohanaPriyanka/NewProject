/**
 * Created by JesseFox_GearsCRM on 7/6/2020.
 */

import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class SsfFooter extends LightningElement {
    @api isExpanded;
    logoUrl = staticResourceFolder + '/BluewaveLogo_White.png';
    
    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }
}