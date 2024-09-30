import { LightningElement, wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import TRANSPORT_OBJECT from '@salesforce/schema/PPA_Transportation__c';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import TRANSPORT_TYPE from '@salesforce/schema/PPA_Transportation__c.PPA_Transportation_Type__c';

export default class PPA_TransportationLWC extends LightningElement {
    @api recordId; // Record Id passed from the PriceList Record Page
    @api transType;
    transTypeRecordTypeId;
    transTypes = [];
    error;

    priceListRecordId;

    @wire(getObjectInfo, { objectApiName: TRANSPORT_OBJECT })
    results({ error, data }) {
        if (data) {
            this.transTypeRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.transTypeRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$transTypeRecordTypeId', fieldApiName: TRANSPORT_TYPE })
    transportTypeValues({ error, data }) {
        if (data) {
            this.transTypes = [...data.values];
            this.transTypes = this.transTypes.sort((a, b) => (a.label > b.label) ? 1 : -1);
            this.priceListRecordId = this.recordId;
        } else if (error) {
            this.error = error;
            this.transTypes = undefined;
        }
    }
}