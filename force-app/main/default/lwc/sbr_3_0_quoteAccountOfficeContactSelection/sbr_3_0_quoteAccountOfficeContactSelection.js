/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACCOUNT_LOOKUP_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c';
import ACCOUNT_OFFICE_LOOKUP_FIELD from '@salesforce/schema/SBQQ__Quote__c.Office_Account__c';
import ACCOUNT_PARENTID_FIELD from '@salesforce/schema/Account.ParentId';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
// import QUOTE_NAME_FIELD from '@salesforce/schema/SBQQ__Quote__c.Quote_Name__c';
// import QUOTE_ORDERED_BY_FIELD from '@salesforce/schema/SBQQ__Quote__c.Ordered_by__c';

export default class Sbr_3_0_quoteAccountOfficeContactSelection extends NavigationMixin(LightningElement) {

    accountLookupField = ACCOUNT_LOOKUP_FIELD;
    officeAccountLookupField = ACCOUNT_OFFICE_LOOKUP_FIELD;
    
    @api accountId;
    @api officeAccountId;
    @api relatedRecordId;
    @api quoteName;
    @api orderedBy; 
    @api minStartDate
    
    defaultOfficeAccountId;
    isChangeAccount=false;
    @track isAccountSelected = false;
    @track isOrderedByButtonDisabled = true;

    @track durationSelection
    @track selectedAccount;
    @track selectedOfficeAccount;
    @track selectedContact;
    @track customLineStyle;
    
    // @wire(getRecord, { recordId: '$selectedAccount', fields: [ACCOUNT_PARENTID_FIELD]})
    // wiredAccount;
    @wire(getRecord, { recordId: '$officeAccountId', fields: [ACCOUNT_PARENTID_FIELD]})
    wiredOfficeAccount({error, data}) {
        if (data) {
            console.log('Wired Office Provision');
            this.selectedOfficeAccount = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.selectedOfficeAccount = undefined;
        }
    }


    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;
    
    connectedCallback() {
        console.log('LWC Loading');
        this.minStartDate = new Date();
        console.log(this.minStartDate);
        if(this.accountId !== undefined) {
            this.isAccountSelected = true;
        }
        if(this.orderedBy !== undefined) {
            this.isOrderedByButtonDisabled = false;
        }
    }

    renderedCallback() {
        let footer = this.template.querySelector('.customfooter');
        let width = footer.getBoundingClientRect().width + 24
        this.customLineStyle = "position: absolute; width: " + width + "px; margin-left: -12px; margin-right: 12px";
    }

    handleNext(event) {
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }

    handleOrderedByChange(event){
        if(event.detail.selectedRecord !== undefined) {
            this.orderedBy = event.detail.selectedRecord.Id;
            this.isOrderedByButtonDisabled = false;
            console.log('Selected Contact: ', this.orderedBy);
        }
        else {
            this.orderedBy = '';
            this.isOrderedByButtonDisabled = true;
        }
    }

    handleOfficeAccount(event){
        if(event.detail.selectedRecord !== undefined) {
            this.officeAccountId = event.detail.selectedRecord.Id;
            console.log('Selected Office Account: ', this.officeAccountId);
        }
        else {
            this.officeAccountId = '';
        }
    }

    handleAccountChange(event){
        if(event.detail.selectedRecord !== undefined) {
            this.isChangeAccount=true;
            this.accountId =  event.detail.selectedRecord.Id; 
            this.isAccountSelected = true;
            console.log('Selected Account: ', event.detail.selectedRecord.Id);
        }
        else {
            this.isAccountSelected = false;
            this.isChangeAccount = false;
            this.isOrderedByButtonDisabled = true;
            this.accountId = ''; 
            this.officeAccountId = '';
            this.orderedBy = '';
        }
    }

    get account(){
        if(this.accountId !== undefined) {
            console.log('Get Account Standard');
            return this.accountId;
        }
        else if(this.officeAccountId !== undefined) {
            console.log('Get Account Is Office Account');
            console.log(getFieldValue(this.selectedOfficeAccount, ACCOUNT_PARENTID_FIELD));
            return getFieldValue(this.selectedOfficeAccount, ACCOUNT_PARENTID_FIELD);
        }
        else if(this.isBillingAccount){
            console.log('Get Account Is Billing Account');
            return this.relatedRecordId;
        }
    }

    set account(value){
        console.log('Set Account');
        this.accountId = value;
    }

    get officeAccount(){
        if (this.officeAccountId !== undefined) {

            console.log('Get Office Account');
            return this.officeAccountId;
        }
        return '';

    }

    set officeAccount(value) {
        this.officeAccountId = value;
        this.officeWhere = value;
        console.log('Setting')
    }

    get officeRtId(){
        if(this.accountObjectInfo.data !== undefined) {
            const rtis = this.accountObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(rti => rtis[rti].name === 'Office');
        }
        return;
    }

    get officeWhere() {
        if(this.account !== undefined && this.account !== null) {
            this.officeAccountWhereClause = 'ParentId = \'' + this.account + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        }
        else {
            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
        }
        return this.officeAccountWhereClause;
    }

    set officeWhere(value) {
        if(this.account !== undefined && this.account !== null) {
            this.officeAccountWhereClause = 'ParentId = \'' + value + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        }
        else {
            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
        }
    }

    get isOfficeAccount(){
        if(this.objectApiName === 'Account' && this.accRtId === this.officeRtId) {
            return true;
        }
        return false;
    }

    get orderedByWhere() {
        if(this.account !== undefined && this.account !== null) {
            this.orderedByWhereClause = 'AccountId = \'' + this.account +  '\'';
        }
        return this.orderedByWhereClause;
    }

    set orderedByWhere(value) {
        if(this.account !== undefined && this.account !== null) {
            this.orderedByWhereClause = 'AccountId = \'' + value +  '\'';
        }// AccountId = '{!AcctId.recordId}'
    }
}