import { LightningElement, track, api, wire } from 'lwc';
import getUASBs from '@salesforce/apex/TransferSheetService.getTransferFromId';
import insertUASBs from '@salesforce/apex/TransferSheetService.handleTransferSheetResolutions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class BasicDatatable extends LightningElement {
    @track uasbdata;
    @track uasbMap = new Map();
    @track apexData;
    @track allResolved;
    @api recordId;
    @api categoryTypeTransfer = 'Transfer Sheet';
    @api fileTypes = ['.csv'];

    get options() {
        return [
            {label: 'Use Utility', value: 'UseUtility'},
            {label: 'Use Salesforce', value: 'UseSalesforce'},
        ];
    }

    connectedCallback() {
        this.refreshData();
    }

    refreshData(){
        getUASBs({transferRecordId: this.recordId})
        .then(result => {
            this.apexData = JSON.stringify(result);
            this.readApexData(result);
        })
        .catch(error => {
            if (error.body.message.includes('NoTransferSheet')){
                const event = new ShowToastEvent({
                    title: 'Please upload a Transfer Sheet File To Continue',
                });
                this.dispatchEvent(event);
            } else {
                const event = new ShowToastEvent({
                    title: 'Could not load UASB list',
                    message: error.errorCode + ', ' + error.body.message,
                });
                this.dispatchEvent(event);
            }
        });
    }

    readApexData(dataFromApex) {
        let formattedDataMap = new Map();
        var i;
        for (i = 0; i < dataFromApex.length; i++) {
            let uasbData = new Object();
            uasbData.Uniqueid = dataFromApex[i].SfUASB.Schedule_Z_Subscription__c;
            uasbData.customername = dataFromApex[i].SfUASB.PreGen_Name_on_Account__c;
            uasbData.sfutilityaccount = dataFromApex[i].SfUASB.PreGen_Utility_Acct__c;
            uasbData.sfproduction = dataFromApex[i].SfUASB.Subscription_Production_kWh_Static__c;
            uasbData.sfcredits = dataFromApex[i].SfUASB.Credits_Allocated__c;
            uasbData.sfcreditvalue = dataFromApex[i].SfUASB.NMC_Rate__c;
            uasbData.trutilityaccount = dataFromApex[i].UtilUASB.PreGen_Utility_Acct__c;
            uasbData.trproduction = dataFromApex[i].UtilUASB.Subscription_Production_kWh_Static__c;
            uasbData.trcredits = dataFromApex[i].UtilUASB.Credits_Allocated__c;
            uasbData.trcreditvalue = dataFromApex[i].UtilUASB.NMC_Rate__c;
            if (dataFromApex[i].Status === 'MATCH') {
                uasbData.isMatch = true;
                uasbData.Resolution = 'UseSalesforce';
            } else if (dataFromApex[i].Status === 'CREDIT_MISMATCH') {
                uasbData.isCreditMismatch = true;
            } else if (dataFromApex[i].Status === 'MISSING_BILL') {
                uasbData.Uniqueid = 'missingBill' + i;
                uasbData.isMissingBill = true;
                uasbData.Resolution = 'UseSalesforce';
            } else if (dataFromApex[i].Status === 'MISSING_TRANSFER') {
                uasbData.isMissingTransfer = true;
            } else {
                const event = new ShowToastEvent({title: 'Record without Match Status: ' + dataFromApex[i]});
                this.dispatchEvent(event);
            }
            formattedDataMap.set(uasbData.Uniqueid, uasbData);
        }
        this.uasbMap = formattedDataMap;
        console.log(formattedDataMap.values());
        this.refreshDataTable();
    }

    refreshDataTable() {
        this.uasbdata = this.uasbMap.values();
        this.checkForAllResolved();
    }

    utilityResolution(event) {
        this.setResolution(event.detail, 'UseUtility');
    }

    salesforceResolution(event) {
        this.setResolution(event.detail, 'UseSalesforce');
    }

    setResolution(uniqueRowId, resolutionText) {
        let updatedRecord = this.uasbMap.get(uniqueRowId);
        updatedRecord.Resolution = resolutionText;
        this.uasbMap.set(uniqueRowId, updatedRecord);
        this.checkForAllResolved();
        this.refreshDataTable();
    }

    checkForAllResolved() {
        let booleanAllClear = true;
        let dataMap = this.uasbMap;
        for (let lineItem of dataMap.values()) {
            if (lineItem.Resolution !== 'UseUtility' &&
                lineItem.Resolution !== 'UseSalesforce'){
                booleanAllClear = false;
                break;
            }
        }
        this.allResolved = booleanAllClear;
    }

    insertBills(){
        this.allResolved = false;
        let dataList = [];
        for (let lineItem of this.uasbMap.values()) {
            dataList.push(JSON.stringify(lineItem));
        }
        insertUASBs({pregenBills : this.apexData, overrideValues : dataList})
        .then(result => {
            const event = new ShowToastEvent({
                title: 'Success! UASBs Inserted',
            });
            this.dispatchEvent(event);
        })
        .catch(error => {
            const event = new ShowToastEvent({
                title: 'Could not load UASB list',
                message: error.errorCode + ', ' + error.body.message,
            });
            this.dispatchEvent(event);
        });
    }
}