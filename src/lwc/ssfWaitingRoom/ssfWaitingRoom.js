/**
 * Created by LindsayHolmes_GearsCRM on 7/6/2020.
 */

import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';
import factText1 from '@salesforce/label/c.SSF_WaitingRoom1_Text';
import factText2 from '@salesforce/label/c.SSF_WaitingRoom2_Text';
import factText3 from '@salesforce/label/c.SSF_WaitingRoom3_Text';
import factUrl1 from '@salesforce/label/c.SSF_WaitingRoom1_Url';
import factUrl2 from '@salesforce/label/c.SSF_WaitingRoom2_Url';
import factUrl3 from '@salesforce/label/c.SSF_WaitingRoom3_Url';


export default class SsfWaitingRoom extends LightningElement {
    @api show;
    loadingGifUrl = staticResourceFolder + '/Icon_Loading.gif';
    intervalSeconds = 6;
    items = [
        {
            icon: staticResourceFolder + '/Icon_EarthLeaf.png',
            alt: 'icon of earth with leaves',
            text: factText1,
            href: factUrl1
        }, {
            icon: staticResourceFolder + '/Icon_EarthLeaf.png',
            alt: 'icon of earth with leaves',
            text: factText2,
            href: factUrl2
        },
        {
            icon: staticResourceFolder + '/Icon_EarthLeaf.png',
            alt: 'icon of earth with leaves',
            text: factText3,
            href: factUrl3
        }
    ];
    
    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }
}