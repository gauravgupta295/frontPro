import { LightningElement, api, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class SBR_3_0_VendorAccountStatusWidget extends LightningElement {

@api recordId;
vendorStatus;

    @wire(getRecord, { recordId: '$recordId', fields: 'Account.Vendor_Status__c' })
    wiredRecord(result) {
        if (result.data) {
            this.vendorStatus = result.data.fields.Vendor_Status__c.displayValue;
            console.log('Status', this.vendorStatus);
        }
        else if (result.error) {
            console.log(error);
        }
    }        
}