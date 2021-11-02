import { LightningElement } from 'lwc';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import companyLogoPath from '@salesforce/label/c.SSF_Company_Logo';
import companyWebsite from '@salesforce/label/c.SSF_Company_Website';

export default class SsfHeader extends LightningElement {
    logoUrl = staticResourceFolder + '/' + companyLogoPath;
    label = {
        companyWebsite
    }
}