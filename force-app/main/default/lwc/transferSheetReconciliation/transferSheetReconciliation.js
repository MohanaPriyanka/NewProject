import { LightningElement, track, api, wire } from 'lwc';
import getUASBs from '@salesforce/apex/TransferSheetService.getTransferFromId';
import insertUASBs from '@salesforce/apex/TransferSheetService.handleTransferSheetResolutions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BasicDatatable extends LightningElement {
    @api recordId;
    @api categoryTypeTransfer = 'Transfer Sheet';
    @api fileTypes = ['.csv'];
    @api UCB;

    @track allResolved;
    @track apexData;
    @track readyState = false;
    @track uasbData;
    @track uasbMap = new Map();

    connectedCallback() {
        this.refreshData();
    }

    get titleSupplement() {
        return this.UCB ? '(UCB)' : '';
    }

    get options() {
        return [
            {label: 'Use Utility', value: 'UseUtility'},
            {label: 'Use Salesforce', value: 'UseSalesforce'},
        ];
    }

    get missingTransferHelptext() {
        return `If you don't want to create bill, choose Use Utility, if you want to create bill as we calculated it, choose Use Salesforce`;
    }

    async refreshData() {
        this.readyState = false;
        await getUASBs({
            transferRecordId: this.recordId
        })
        .then(result => {
            this.apexData = JSON.stringify(result);
            this.readApexData(result);
            this.readyState = true;
        })
        .catch(error => {
            const errorMessage = error.body && error.body.message ? error.body.message : '_';
            if (errorMessage.includes('Bills Already Generated')){
                this.showToast('Bills Already Generated for this Transfer', null, 'warning', 'pester');
            } else if (errorMessage.includes('There is another transfer')) {
                this.showToast('Older Un-billed Transfer Found', errorMessage, 'warning', 'sticky');
            } else {
                this.showToast('Could not load UASB list', errorMessage, 'warning', 'sticky');
            }
            this.readyState = true;
        });
    }

    readApexData(dataFromApex) {
        let formattedDataMap = new Map();
        try {
            let i;
            for (i = 0; i < dataFromApex.length; i++) {
                let uasbData = {};
                this.setRowValues(uasbData, dataFromApex[i]);
                this.setRowMatchData(uasbData, dataFromApex[i], i);
                formattedDataMap.set(uasbData.uniqueId, uasbData);
            }
            this.uasbMap = formattedDataMap;
        } catch (err){
            this.showToast('System Error Reading UASB List', 'ERROR THROWN: ' + err, 'error', 'sticky');
        }
        this.refreshDataTable();
    }

    setRowValues(uasbData, dataFromApex) {
        uasbData.customerName = this.setCustomerName(uasbData, dataFromApex);
        uasbData.trUtilityAccount = dataFromApex.utilUASB.PreGen_Utility_Acct__c;
        uasbData.sfUtilityAccount = dataFromApex.sfUASB.PreGen_Utility_Acct__c;
        uasbData.exceptionPrefix = this.getExceptionPrefix(dataFromApex.sfUASB);
        uasbData.uniqueId = dataFromApex.sfUASB.Schedule_Z_Subscription__c;
        if (this.UCB) {
            uasbData.sfNewAvailableCredits = dataFromApex.sfUASB.New_available_credits__c;
            uasbData.sfTotalAvailableCredits = dataFromApex.sfUASB.Total_Available_Credits__c;
            uasbData.sfNetMemberCredits = dataFromApex.sfUASB.Net_Member_Credits__c;
            uasbData.sfEndingBankedCredits = dataFromApex.sfUASB.Ending_Banked_Credits__c;
            uasbData.sfCDGSponsorPayment = dataFromApex.sfUASB.CDG_Sponsor_Payment__c;
            uasbData.sfUtilityAdminFee = dataFromApex.sfUASB.Utility_Admin_Fee__c;
            uasbData.trNewAvailableCredits = dataFromApex.utilUASB.New_available_credits__c;
            uasbData.trTotalAvailableCredits = dataFromApex.utilUASB.Total_Available_Credits__c;
            uasbData.trNetMemberCredits = dataFromApex.utilUASB.Net_Member_Credits__c;
            uasbData.trEndingBankedCredits = dataFromApex.utilUASB.Ending_Banked_Credits__c;
            uasbData.trCDGSponsorPayment = dataFromApex.utilUASB.CDG_Sponsor_Payment__c;
            uasbData.trUtilityAdminFee = dataFromApex.utilUASB.Utility_Admin_Fee__c;
        } else {
            uasbData.sfProduction = dataFromApex.sfUASB.Subscription_Production_kWh_Static__c;
            uasbData.sfCredits = dataFromApex.sfUASB.Credits_Allocated__c;
            uasbData.sfCreditValue = dataFromApex.sfUASB.NMC_Rate__c;
            uasbData.trProduction = dataFromApex.utilUASB.Subscription_Production_kWh_Static__c;
            uasbData.trCredits = dataFromApex.utilUASB.Credits_Allocated__c;
            uasbData.trCreditValue = dataFromApex.utilUASB.NMC_Rate__c;
        }
    }

    getExceptionPrefix(uasb) {
        if (uasb.PreGen_IsPreGen__c) {
            return 'FINALED_';
        } else if (uasb.Early_Removal__c) {
            return 'REMOVED_';
        }
        return ''
    }

    setCustomerName(uasbData, dataFromApex) {
        let returnVal;
        const customerName = dataFromApex.sfUASB.PreGen_Name_on_Account__c;
        if (customerName) {
            let cutoff = Math.min(customerName.length, 15);
            returnVal = dataFromApex.sfUASB.PreGen_Name_on_Account__c.substring(0, cutoff);
            if (dataFromApex.sfUASB.Externally_Serviced__c) {
                cutoff = Math.min(customerName.length, 5);
                returnVal = dataFromApex.sfUASB.PreGen_Name_on_Account__c.substring(0, cutoff) + '**EXTERNAL';
            }
        }
        return returnVal;
    }

    setRowMatchData(uasbData, dataFromApex, iteration) {
        switch (dataFromApex.status) {
            case 'MATCH':
                uasbData.isMatch = true;
                uasbData.resolution = 'UseSalesforce';
                uasbData.rowStyle = 'slds-theme_shade';
                uasbData.leftPanelStyle = 'slds-p-around--xx-small';
                uasbData.rightPanelStyle = 'slds-p-around--xx-small';
                break;
            case 'CREDIT_MISMATCH':
                uasbData.isCreditMismatch = true;
                uasbData.resolution = 'UseUtility';
                uasbData.rowStyle = 'slds-theme_shade slds-theme_warning';
                uasbData.leftPanelStyle = 'slds-p-around--xx-small';
                uasbData.rightPanelStyle = 'slds-p-around--xx-small';
                break;
            case 'MISSING_BILL':
                uasbData.uniqueId = 'missingBill' + iteration;
                uasbData.isMissingBill = true;
                uasbData.resolution = 'UseSalesforce';
                uasbData.rowStyle = 'slds-theme_shade';
                uasbData.leftPanelStyle = 'slds-p-around--xx-small slds-theme_error';
                uasbData.rightPanelStyle = 'slds-p-around--xx-small';
                break;
            case 'MISSING_TRANSFER':
                uasbData.isMissingTransfer = true;
                uasbData.rowStyle = 'slds-theme_shade';
                uasbData.leftPanelStyle = 'slds-p-around--xx-small';
                uasbData.rightPanelStyle = 'slds-p-around--xx-small slds-theme_error';
                break;
            default:
                this.showToast('Record without Match Status: ' + dataFromApex, null, 'info', 'sticky');
        }
    }

    refreshDataTable() {
        this.uasbData = this.uasbMap.values();
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
        updatedRecord.resolution = resolutionText;
        this.uasbMap.set(uniqueRowId, updatedRecord);
        this.checkForAllResolved();
        this.refreshDataTable();
    }

    checkForAllResolved() {
        let booleanAllClear = true;
        let dataMap = this.uasbMap;
        for (let lineItem of dataMap.values()) {
            if (lineItem.resolution !== 'UseUtility' && lineItem.resolution !== 'UseSalesforce') {
                booleanAllClear = false;
                break;
            }
        }
        this.allResolved = booleanAllClear;
    }

    insertBills() {
        this.readyState = false;
        this.allResolved = false;
        let dataList = [];
        for (let lineItem of this.uasbMap.values()) {
            dataList.push(JSON.stringify(lineItem));
        }
        insertUASBs({
            pregenBills : this.apexData,
            overrideValues : dataList
        })
        .then(result => {
            this.showToast('Success! UASBs Inserted', null, 'success', 'pester');
            this.readyState = true;
        })
        .catch(error => {
            const err = error.body.message;
            this.showToast('Could not insert UASBs', err ? err : '_', 'error', 'sticky');
            this.readyState = true;
        });
    }

    showToast(title, message, variant, mode) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            mode: mode,
            message: message,
            variant: variant
        }));
    }
}