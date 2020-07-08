import { LightningElement } from 'lwc';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class SsfHeader extends LightningElement {
    logoUrl = staticResourceFolder + '/BluewaveLogo_White.png';
}