import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PREVIOUS_TTM_RA from '@salesforce/schema/PPA_Price_List__c.PPA_Previous_TTM_RA_Display__c';
import CURRENT_TTM_RA from '@salesforce/schema/PPA_Price_List__c.PPA_Current_TTM_RA_Display__c';
import CUSTOMER_TTM from '@salesforce/schema/PPA_Price_List__c.PPA_Customer_TTM__c';
import CORPLINK_TTM from '@salesforce/schema/PPA_Price_List__c.PPA_CorpLink_TTM__c';
import BELOW_AT_ABOVE from '@salesforce/schema/PPA_Price_List__c.PPA_Below_At_Above_Market__c';
import BELOW_MARKET from '@salesforce/schema/PPA_Price_List__c.PPA_Below_Market_Display__c';
import AT_MARKET from '@salesforce/schema/PPA_Price_List__c.PPA_At_Market_Display__c';
import ABOVE_MARKET from '@salesforce/schema/PPA_Price_List__c.PPA_Above_Market_Display__c';
import RECORDTYPE from '@salesforce/schema/PPA_Price_List__c.RecordType.Name';
import STATUS from '@salesforce/schema/PPA_Price_List__c.PPA_Status__c';
import RECORDTYPENAME from '@salesforce/schema/PPA_Price_List__c.RecordType.DeveloperName';
import WEEK_ERROR from '@salesforce/schema/PPA_Price_List__c.PPA_Week_Errors_Found__c';

export default class PPA_PriceListKeyMetricsLWC extends LightningElement {
    @api recordId;
    prevTTM_RA;
    currTTM_RA;
    customerTTM;
    corpLinkTTM;
    belowMarket;
    atMarket;
    aboveMarket;
    belowAtAbove;

    @wire(getRecord, { recordId: '$recordId', fields: [PREVIOUS_TTM_RA, CURRENT_TTM_RA, CUSTOMER_TTM, CORPLINK_TTM, BELOW_MARKET, AT_MARKET, ABOVE_MARKET, BELOW_AT_ABOVE] })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.prevTTM_RA = getFieldValue(this.record, PREVIOUS_TTM_RA);
            this.currTTM_RA = getFieldValue(this.record, CURRENT_TTM_RA);
            this.customerTTM = getFieldValue(this.record, CUSTOMER_TTM);
            this.corpLinkTTM = getFieldValue(this.record, CORPLINK_TTM);
            this.belowMarket = getFieldValue(this.record, BELOW_MARKET);
            this.atMarket = getFieldValue(this.record, AT_MARKET);
            this.aboveMarket = getFieldValue(this.record, ABOVE_MARKET);
            this.belowAtAbove = getFieldValue(this.record, BELOW_AT_ABOVE);

            this.error = null;
        } else if (error) {
            this.error = error;
        }
    }
}