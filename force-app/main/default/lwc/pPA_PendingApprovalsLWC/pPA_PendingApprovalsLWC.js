import { LightningElement, wire } from 'lwc';
import getPendingApproval from '@salesforce/apex/PPA_PendingApprovalsLWCController.getPendingApproval';
import { refreshApex } from '@salesforce/apex';


const col1 = [
    { label: 'Price List Name', fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: {alignment: 'left', class: 'slds-p-vertical_none slds-m-vertical_none'}, hideDefaultActions: true, sortable: true, initialWidth: 500},
    { label: 'Type', fieldName: 'PPA_Record_Type_Name__c', type: 'text', cellAttributes: {alignment: 'left'}, hideDefaultActions: true, initialWidth: 100},
    { label: 'Start Date', fieldName: 'PPA_Start_Date__c', type: 'date-local', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric'}, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'End Date', fieldName: 'PPA_End_Date__c', type: 'date-local', typeAttributes: {day: 'numeric', month: 'numeric', year: 'numeric'},cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'Customer TTM', fieldName: 'PPA_Customer_TTM__c', type: 'currency', cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'At Market', fieldName: 'PPA_At_Market_Display__c', type: 'percent', typeAttributes: {minimumFractionDigits: '2'}, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'Current TTM RA', fieldName: 'PPA_Current_TTM_RA_Display__c', type: 'percent', typeAttributes: {minimumFractionDigits: '2'}, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'RA Improvement %', fieldName: 'PPA_RA_Improvement_Display__c', type: 'percent', typeAttributes: {minimumFractionDigits: '2'}, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'Rate Type', fieldName: 'PPA_Rate_Type__c', type: 'text', cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
];

export default class PPA_PendingApprovalsLWC extends LightningElement {
    allRecords;
    dataLoaded = false;

    colDisplay = col1;

    @wire(getPendingApproval)
    wiredCatclass(result) {
        console.log(result);
        this.dataToRefresh = result;
        if (result.data) {
            this.allRecords = result.data;

            if(this.allRecords.length > 0) {
                this.dataLoaded = true;
            }

            this.error = null;
        } else if (result.error) {
            this.error = result.error;
            console.log(this.error);
        }
    }

    handleRefresh() {
        refreshApex(this.dataToRefresh);
    }
    
    handleRowAction(event) {
        const record = event.detail.row;
        const actionName = event.detail.action.name;

        if(actionName == 'view') {
            this.viewDetails(record.Id);
        }
    }

    viewDetails(recordId) {
        window.location.href = "/" + recordId;
    }
}