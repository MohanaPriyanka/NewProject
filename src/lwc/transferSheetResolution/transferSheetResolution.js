import { LightningElement, api} from 'lwc';

export default class transferSheetResolution extends LightningElement {
    @api recordNumber;
    @api picklistOptions;

    get picklistOptions() {
        return [
            { label: 'Use Utility', value: 'UseUtility' },
            { label: 'Use Salesforce', value: 'UseSalesforce' },
        ];
    }

    handlechange(event) {
        if (event.detail.value == 'UseUtility'){
            const utilEvent = new CustomEvent('useutility', {detail: this.recordNumber});
            this.dispatchEvent(utilEvent);
        } else if (event.detail.value == 'UseSalesforce'){
            const sfEvent = new CustomEvent('usesalesforce', {detail: this.recordNumber});
            this.dispatchEvent(sfEvent);
        }
    }
}