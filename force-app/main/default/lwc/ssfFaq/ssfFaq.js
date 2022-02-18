/**
 * Created by JesseFox_GearsCRM on 7/6/2020.
 */

import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import faq1Question from '@salesforce/label/c.SSF_FAQ1_Question';
import faq1Answer from '@salesforce/label/c.SSF_FAQ1_Answer';
import faq2Question from '@salesforce/label/c.SSF_FAQ2_Question';
import faq2Answer from '@salesforce/label/c.SSF_FAQ2_Answer';
import faq3Question from '@salesforce/label/c.SSF_FAQ3_Question';
import faq3Answer from '@salesforce/label/c.SSF_FAQ3_Answer';
import faq4Question from '@salesforce/label/c.SSF_FAQ4_Question';
import faq4Answer from '@salesforce/label/c.SSF_FAQ4_Answer';
import faq5Question from '@salesforce/label/c.SSF_FAQ5_Question';
import faq5Answer from '@salesforce/label/c.SSF_FAQ5_Answer';
import faq6Question from '@salesforce/label/c.SSF_FAQ6_Question';
import faq6Answer from '@salesforce/label/c.SSF_FAQ6_Answer';

export default class SsfFaq extends LightningElement {
    @api isExpanded;
    label = {
        faq1Question,
        faq1Answer,
        faq2Question,
        faq2Answer,
        faq3Question,
        faq3Answer,
        faq4Question,
        faq4Answer,
        faq5Question,
        faq5Answer,
        faq6Question,
        faq6Answer
    };

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }
    
    get assistiveText() {
        return this.isExpanded ? 'Collapse Section' : 'Expand Section';
    }

    get buttonIconStyle() {
        let style = 'accordion-button__icon top';
        if (this.isExpanded) {
            style += ' rotate';
        }
        return style;
    }

    onButtonIconClick(event) {
        this.isExpanded = !this.isExpanded;
    }
}