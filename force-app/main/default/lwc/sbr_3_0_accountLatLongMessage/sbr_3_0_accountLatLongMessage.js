import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_STREET_LAT_LONG_STATUS_FIELD from '@salesforce/schema/Account.Street_Address_LatLong_Status__c';
import ACCOUNT_STREET_LAT_LONG_ERROR_FIELD from '@salesforce/schema/Account.Street_Address_LatLong_error__c';
import ACCOUNT_OVERRIDE_LAT_LONG_STATUS_FIELD from '@salesforce/schema/Account.Override_Address_LatLong_Status__c';
import ACCOUNT_OVERRIDE_LAT_LONG_ERROR_FIELD from '@salesforce/schema/Account.Override_Address_LatLong_error__c';
const FIELDS = [ACCOUNT_STREET_LAT_LONG_STATUS_FIELD, ACCOUNT_STREET_LAT_LONG_ERROR_FIELD, ACCOUNT_OVERRIDE_LAT_LONG_STATUS_FIELD, ACCOUNT_OVERRIDE_LAT_LONG_ERROR_FIELD];

export default class Sbr_3_0_accountLatLongMessage extends LightningElement {
    @api recordId;

    @track streetLatLongError = '';
    @track streetLatLongFetching = false;

    @track overrideLatLongError = '';
    @track overrideLatLongFetching = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            
        } else if (data) {
            if(data.fields.Street_Address_LatLong_Status__c.value === 'Error'){
                this.streetLatLongError = 'Error Fetching Street Address Latitude and Longitude: ' + data.fields.Street_Address_LatLong_error__c.value;
            } else if(data.fields.Street_Address_LatLong_Status__c.value === 'Fetching'){
                this.streetLatLongFetching = true;
                this.streetLatLongError = '';
            }

            if(data.fields.Override_Address_LatLong_Status__c.value === 'Error'){
                this.overrideLatLongError = 'Error Fetching Override Address Latitude and Longitude: ' + data.fields.Override_Address_LatLong_error__c.value;
            } else if(data.fields.Override_Address_LatLong_Status__c.value === 'Fetching'){
                this.overrideLatLongFetching = true;
                this.overrideLatLongError = '';
            }
        }
    }
}