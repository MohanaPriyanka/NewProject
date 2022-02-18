/**
 * Created by rebeccanachison on 9/30/21.
 */

import {LightningElement, api} from 'lwc';

import TREES_ICON from '@salesforce/resourceUrl/treesIcon';
import HOUSE_ICON from '@salesforce/resourceUrl/houseIcon';
import SUBSCRIBER_ICON from '@salesforce/resourceUrl/subscriberIcon';

export default class CustomerPortalProjectHeader extends LightningElement {

    treesIcon = TREES_ICON;
    houseIcon = HOUSE_ICON;
    subscriberIcon = SUBSCRIBER_ICON;

    @api project;

    get hasSubscribers() {
        return this.project.Subscribers__c != null;
    }

}