import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RECORDTYPE from '@salesforce/schema/PPA_Price_List__c.RecordType.Name';
import STATUS from '@salesforce/schema/PPA_Price_List__c.PPA_Status__c';
import RECORDTYPENAME from '@salesforce/schema/PPA_Price_List__c.RecordType.DeveloperName';
import WEEK_ERROR from '@salesforce/schema/PPA_Price_List__c.PPA_Week_Errors_Found__c';

export default class PPA_DisplayPriceListBadgesLWC extends LightningElement {
    @api recordId;
    recordType;
    recordTypeName;
    status;
    statusClass;
    weekError = false;

    @wire(getRecord, { recordId: '$recordId', fields: [RECORDTYPE, RECORDTYPENAME, STATUS, WEEK_ERROR] })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.recordType = getFieldValue(this.record, RECORDTYPE);
            this.recordTypeName = getFieldValue(this.record, RECORDTYPENAME);
            this.status = getFieldValue(this.record, STATUS);
            this.weekError = getFieldValue(this.record, WEEK_ERROR);

            if(this.recordTypeName == 'PPA_Renewal_Denied') {
                this.recordTypeName = 'PPA_Renewal';
                this.recordType = 'Renewal';
            }

            if(this.recordTypeName == 'PPA_Extension_Denied') {
                this.recordTypeName = 'PPA_Extension';
                this.recordType = 'Extension';
            }

            switch(this.status) {
                case 'Draft':
                case 'Upcoming':
                case '+ 90 Days':
                case 'Pending Approval':
                    this.statusClass = 'statusInitial';
                    break;
                
                case 'Approved':
                case 'Completed':
                    this.statusClass = 'statusCompleted';
                    break;
                
                case 'Denied':
                    this.statusClass = 'statusDenied';
                    break;
            }

            this.error = null;
        } else if (error) {
            this.error = error;
        }
    }
}