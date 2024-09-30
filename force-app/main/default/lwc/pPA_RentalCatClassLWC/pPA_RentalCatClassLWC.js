import { LightningElement, wire, api, track } from 'lwc';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteModal from 'c/pPA_ConfirmDeleteModalLWC';
import detailsModal from 'c/pPA_RecordDetailsModalLWC'

const action1 = [
    { label: 'View', name: 'view' }
];

const action2 = [
    { label: 'View', name: 'view' },
    { label: 'Delete', name: 'delete' }
];

const col1 = [
    { label: 'Product', fieldName: 'PPA_Product_Name__c', type: 'text'},
    { label: 'CatClass', fieldName: 'PPA_CatClass__c', type: 'text', cellAttributes: {alignment: 'left'}},
    { label: 'Rates Loaded', fieldName: 'PPA_Rates_Loaded__c', type: 'boolean', cellAttributes: {alignment: 'left'}},
    { label: 'Rental Revenue', fieldName: 'PPA_Rental_Revenue__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Times Rented', fieldName: 'PPA_Times_Rented__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Current Day', fieldName: 'PPA_Old_Day__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Current Week', fieldName: 'PPA_Old_Week__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Current Month', fieldName: 'PPA_Old_Month__c', type: 'currency', cellAttributes: {alignment: 'left'}},         
    { label: 'New Day', fieldName: 'PPA_New_Day__c', type: 'currency', editable: false, cellAttributes: {alignment: 'left'}},
    { label: 'New Week', fieldName: 'PPA_New_Week__c', type: 'currency', editable: false , cellAttributes: {alignment: 'left'}},
    { label: 'New Month', fieldName: 'PPA_New_Month__c', type: 'currency',editable: false, cellAttributes: {alignment: 'left'}},
    { label: 'Changed D%', fieldName: 'PPA_Change_Day__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Changed W%', fieldName: 'PPA_Change_Week__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Changed M%', fieldName: 'PPA_Change_Month__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { type: 'action', typeAttributes: { rowActions: action1 } }
];


const col2 = [
    { label: 'Product', fieldName: 'PPA_Product_Name__c', type: 'text'},
    { label: 'CatClass', fieldName: 'PPA_CatClass__c', type: 'text', cellAttributes: {alignment: 'left'}},
    { label: 'Rates Loaded', fieldName: 'PPA_Rates_Loaded__c', type: 'boolean', cellAttributes: {alignment: 'left'}},
    { label: 'Rental Revenue', fieldName: 'PPA_Rental_Revenue__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Times Rented', fieldName: 'PPA_Times_Rented__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Current Day', fieldName: 'PPA_Old_Day__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Current Week', fieldName: 'PPA_Old_Week__c', type: 'currency', cellAttributes: {alignment: 'left'}},
    { label: 'Current Month', fieldName: 'PPA_Old_Month__c', type: 'currency', cellAttributes: {alignment: 'left'}},         
    { label: 'New Day', fieldName: 'PPA_New_Day__c', type: 'currency', editable: true, cellAttributes: {alignment: 'left'}},
    { label: 'New Week', fieldName: 'PPA_New_Week__c', type: 'currency', editable: true , cellAttributes: {alignment: 'left'}},
    { label: 'New Month', fieldName: 'PPA_New_Month__c', type: 'currency',editable: true, cellAttributes: {alignment: 'left'}},
    { label: 'Changed D%', fieldName: 'PPA_Change_Day__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Changed W%', fieldName: 'PPA_Change_Week__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { label: 'Changed M%', fieldName: 'PPA_Change_Month__c', type: 'number', cellAttributes: {alignment: 'left'}},
    { type: 'action', typeAttributes: { rowActions: action2 } }
];

export default class PPA_RentalCatClassLWC extends LightningElement {
    @api recordId; // Record Id passed from the PriceList home page
    @api superCat;
    @api catClassRecs;
    @api selectedRows;
    @api editFlag;
    col1 = col1;
    col2 = col2;
    colDisplay;
    error;
    
    connectedCallback() {
        if(this.editFlag == true) {
            this.colDisplay = this.col2;
        }
        else {
            this.colDisplay = this.col1;
        }
    }

    async handleSave(event) {
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });

        try {
            const recordUpdatePromises = records.map((record) => 
                updateRecord(record)
            );
            await Promise.all(recordUpdatePromises);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records updated successfully',
                    variant: 'success'
                })
            );

            console.log('Before Reload');
            //await refreshApex(this.dataToRefresh);
            this.template.querySelector("lightning-datatable").draftValues = [];
            this.dispatchEvent(new CustomEvent('refreshparent',  {
                detail: { superCat: this.superCat}
            }));
            console.log('After Reload');
        }
        catch(error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    handleRowAction(event) {
        const record = event.detail.row;
        const actionName = event.detail.action.name;

        if(actionName == 'view') {
            this.viewDetails(record.Id);
        }

        if(actionName == 'delete') {
            this.deleteRecord(record.Id);
        }
    }

    async viewDetails(recordId) {
        const result = await detailsModal.open({
            size: 'large',
            description: 'This is to view record details',
            objectName: 'PPA_Rental_CatClass__c',
            recordId: recordId,
            layout: 'Full'
        });
    }

    async deleteRecord(recordId) {
        const result = await deleteModal.open({
            size: 'small',
            description: 'This is a delete confirmation modal',
            modalHeader: 'Delete Cat-Class',
            modalBody: 'Are you sure you want to delete this Cat-Class?'
        });

        if(result == 'OK') {
            deleteRecord(recordId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted successfully',
                        variant: 'success'
                    })
                );    

                this.template.querySelector("lightning-datatable").draftValues = [];
                this.dispatchEvent(new CustomEvent('refreshparent',  {
                    detail: { superCat: this.superCat}
                }));
            });    
        }
    }


}