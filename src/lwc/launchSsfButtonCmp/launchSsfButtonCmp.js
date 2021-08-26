/**
 * Created by aingram on 8/23/21.
 */

import {LightningElement} from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getNewApplicationLink from '@salesforce/apex/PartnerSSFLinkController.getNewApplicationLink';

export default class LaunchSsfButtonCmp extends NavigationMixin(LightningElement)  {
    ssfURL;
    error;
    renderButton = false;

    connectedCallback() {
        getNewApplicationLink()
        .then(result => {
            console.log(result);
            this.ssfURL = result;
            this.renderButton = result == null ? false : true;

        })
        .catch(error => {
            this.error = error;
        });
    }

    openLink() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                "url": this.ssfURL,
            }
        });
    }

}