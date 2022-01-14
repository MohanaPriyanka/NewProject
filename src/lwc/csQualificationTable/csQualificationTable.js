import {LightningElement, track, api} from 'lwc';
import getMatches from '@salesforce/apex/AskYoda.getQualificationMatches';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'

export default class CSQualificationTable extends LightningElement {
    @track matches;
    @track sssMap = new Map();
    @api leadId;
    @api zipCode;
    @api partner;
    @api product;
    @api underwriting;
    @api fico;
    @api utility;
    tableHasContents = true;

    connectedCallback() {
        this.getMatches();
    }

    getMatches() {
        getMatches({
            leadId: this.leadId,
            product: this.product,
            partner: this.partner,
            zipCode: this.zipCode,
            underwriting: this.underwriting
        })
        .then(result => {
            this.highlightMatches(result);
        })
        .catch(error => {
            console.log(error);
        });
    }

    highlightMatches(result) {
        let formattedDataMap = new Map();
        let i;
        try {
            for (i = 0; i < result.length; i++) {
                let match = {}
                match.sssMatch = result[i].completeMatch;
                match.sssName = result[i].sss.Name;

                match.sssOpen = result[i].sss.Open__c;
                match.isOpen = result[i].isOpen;

                match.sssProduct = result[i].sss.Product__r.Name;
                match.sssUtility = result[i].sss.Utility__r.Name;

                match.sssTerritories = result[i].sss.Service_Territories__c;
                match.hasLZ = result[i].hasLZ;

                match.sssCapacity = result[i].sss.Capacity_Available_to_be_Reserved__c;
                match.hasCapacity = result[i].hasCapacity;

                match.underwritingOptions = result[i].underwritingOptions;
                match.isUnderwritten = result[i].isUnderwritten;

                match.sssPartners = result[i].eligiblePartners;
                match.hasPartner = result[i].hasPartner;

                formattedDataMap.set(match.sssName, match)
            }
            this.sssMap = formattedDataMap;
            this.tableHasContents = this.sssMap.size > 0;
        } catch (err) {
            const event = new ShowToastEvent({
                title: 'System Error Reading SSS List',
                mode: 'sticky',
                message: 'ERROR THROWN: ' + err
            });
            this.dispatchEvent(event);
        }
        this.refreshDataTable();
    }

    refreshDataTable() {
        this.matches = this.sssMap.values();
    }
}