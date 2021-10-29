/**
 * Created by JesseFox_GearsCRM on 7/6/2020.
 */
import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import companyLogoPath from '@salesforce/label/c.SSF_Company_Logo';
import companyShortName from '@salesforce/label/c.SSF_Company_Short_Name';
import companyWebsite from '@salesforce/label/c.SSF_Company_Website';
import companyResourceCenterLink from '@salesforce/label/c.SSF_Resource_Center_Link';
import companyFacebookLink from '@salesforce/label/c.SSF_Facebook_Link';
import companyFacebookIcon from '@salesforce/label/c.SSF_Facebook_Icon';
import companyLinkedinLink from '@salesforce/label/c.SSF_Linkedin_Link';
import companyLinkedinIcon from '@salesforce/label/c.SSF_Linkedin_Icon';
import companyTwitterLink from '@salesforce/label/c.SSF_Twitter_Link';
import companyTwitterIcon from '@salesforce/label/c.SSF_Twitter_Icon';
import companySupportEmail from '@salesforce/label/c.SSF_Support_Email';
import companyAddress1 from '@salesforce/label/c.SSF_Company_Address_1';
import companyAddress2 from '@salesforce/label/c.SSF_Company_Address_2';
import insideSalesPhone from '@salesforce/label/c.SSF_Inside_Sales_Phone';

const TEN_DIGITS_CAPTURE_GROUPS = /(\d{3})(\d{3})(\d{4})/;
const PHONE_FORMAT = '($1) $2-$3';

export default class SsfFooter extends LightningElement {
    @api isExpanded;
    logoUrl = staticResourceFolder + '/' + companyLogoPath;
    phoneSrc = 'tel:+1' + insideSalesPhone;
    phoneFormatted = insideSalesPhone.replace(TEN_DIGITS_CAPTURE_GROUPS, PHONE_FORMAT);
    label = {
        companyShortName,
        companyWebsite,
        companyFacebookLink,
        companyFacebookIcon,
        companyLinkedinLink,
        companyLinkedinIcon,
        companyTwitterLink,
        companyTwitterIcon,
        companyResourceCenterLink,
        companySupportEmail,
        companySupportEmailLink: "mailto:" + companySupportEmail,
        companyAddress1,
        companyAddress2
    }
    
    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }
}