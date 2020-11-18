import { LightningElement, track, api, wire } from 'lwc';

import getMatches from '@salesforce/apex/CSQualificationService.getQualificationMatches';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class CSQualificationTable extends LightningElement {
    @track matches;
    @track sssMap = new Map();
    @api zipCode;
    @api partner;
    @api product;
    @api fico;
    @api utility;

    connectedCallback() {
        this.getMatches();
    }

    getMatches() {
        getMatches({product: this.product, partner: this.partner, zipCode: this.zipCode, fico: this.fico, utility: this.utility})
        .then(result => {
            this.highlightMatches(result);
        })
        .catch(error => {
            var errorMessage = '_'
            if (error.body.message) {
                errorMessage = error.body.message;
            }
            const event = new ShowToastEvent({title: 'Error Generating Table', mode: 'sticky'});
            this.dispatchEvent(event);
        });
    }

    highlightMatches(result) {
        let formattedDataMap = new Map();
        var i;
        try {
            for (i = 0; i < result.length; i++) {
                let match = new Object()
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

                match.sssFICO = result[i].sss.Credit_Score_Requirement__c;
                match.minFICO = result[i].minFICO;

                match.sssPartners = result[i].eligiblePartners;
                match.hasPartner = result[i].hasPartner;

                formattedDataMap.set(match.sssName, match)
            }
            this.sssMap = formattedDataMap;
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