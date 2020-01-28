import { LightningElement, track, api } from 'lwc';

const columns = [
    { label: 'Customer Name', fieldName: 'customerName', type: 'text' },
    { label: 'Utility Number', fieldName: 'sf_utilityNumber' , type: 'text'},
    { label: 'Credits', fieldName: 'sf_credits', type: 'currency' },
    { label: 'Credit Value', fieldName: 'sf_creditValue', type: 'currency'},
    { label: 'Match Status', fieldName: 'matchStatus', type: 'text'},
    { label: 'Resolution', fieldName: 'resolution', type: 'text'},
    { label: 'Utility Number', fieldName: 'tr_utilityNumber' , type: 'text'},
    { label: 'Credits', fieldName: 'tr_credits', type: 'currency' },
    { label: 'Credit Value', fieldName: 'tr_creditValue', type: 'currency'},
];

const dataMock = [
    {   matchStatus : 'MATCH', resolution : 'Not Needed', customerName : 'Joe Smo',
        sf_utilityNumber : '123-456', sf_percentShare : 0.01, sf_credits : 23.45,
        tr_utilityNumber : '123-456', tr_percentShare : 0.01, tr_customerName : 'Joe Smo', tr_credits : 23.45
    },
    {   matchStatus : 'MATCH', resolution : 'Not Needed', customerName : 'Joe Smo',
        sf_utilityNumber : '123-456', sf_percentShare : 0.01, sf_credits : 23.45,
        tr_utilityNumber : '123-456', tr_percentShare : 0.01, tr_customerName : 'Joe Smo', tr_credits : 23.45
    },
];


export default class BasicDatatable extends LightningElement {
    @track data = dataMock;
    @track columns = columns;
    @api recordId;
    @api categoryTypeTransfer = 'Transfer Sheet';
    @api fileTypes = ['.csv'];
}