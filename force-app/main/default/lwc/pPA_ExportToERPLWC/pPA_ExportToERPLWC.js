import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getItemsReadyForExport from '@salesforce/apex/PPA_ExportToERPController.getItemsReadyForExport';
import exportSelectedPriceLists from '@salesforce/apex/PPA_ExportPriceListsToCSV.exportSelectedPriceLists';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ExportToERPModal from 'c/pPA_ExportToERPModalLWC';
import { loadStyle } from 'lightning/platformResourceLoader';
import PPALWCCSS from '@salesforce/resourceUrl/PPA_lwcCSS';

const actions = [
    { label: 'Override', name: 'override' }
];

const col1 = [
    { label: '', type: 'button-icon', typeAttributes: {iconName: { fieldName: 'priorityicon' }, iconClass: {fieldName: 'iconClass'}, variant: 'bare'}, hideDefaultActions: true, initialWidth: 10},
    { label: 'Verification Status', fieldName: 'PPA_Verification_Status__c', type: 'text', hideDefaultActions: true, cellAttributes: { class: { fieldName: 'statusClass'}}},
    { label: 'Customer #', fieldName: 'PPA_Customer_No__c', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'Customer Name', fieldName: 'PPA_Customer_Name__c', type: 'text', hideDefaultActions: true,sortable: true},
    { label: 'Price List Name', fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: {alignment: 'left', class: 'slds-p-vertical_none slds-m-vertical_none'}, hideDefaultActions: true, sortable: true, initialWidth: 500},
    { label: 'Version #', fieldName: 'PPA_Version__c', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'Record Type', fieldName: 'PPA_Record_Type_Name__c', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'Status', fieldName: 'PPA_Status__c', type: 'text', hideDefaultActions: true, sortable: true},
    { label: 'Free Rental', fieldName: 'PPA_Free_Rental__c', type: 'boolean', hideDefaultActions: true, sortable: true},
    { label: 'Free Transportation', fieldName: 'PPA_Free_Transportation__c', type: 'boolean', hideDefaultActions: true, sortable: true},
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class ExportToERP extends LightningElement {
    priceListData;
    dataToRefresh;
    colDisplay = col1;
    showSpinner = false;
    isCSSLoaded = false;
    sortDirection;
    sortedBy;

    renderedCallback() {
        if(!this.isCSSLoaded) {
            loadStyle(this, PPALWCCSS + '/PPAlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

    @wire(getItemsReadyForExport)
    wiredTransportationRates(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.priceListData = result.data.map((record) =>({
            ...record,
            priorityicon: this.getIconMarkup(record.PPA_Verification_Status__c),
            iconClass: this.getIconClass(record.PPA_Verification_Status__c),
            statusClass: 'ppa-export-' + record.PPA_Verification_Status__c,
        }));
            this.showSpinner = false;
        } 
        else if (result.error) {
            this.error = result.error.body.message;
            this.showSpinner = false;
        }
    }
    
    //Custom rendering function for the "verification status" column
    getIconMarkup(verificationStatus) {
        const icons = {
            Verified: 'utility:success',
            Unverified: 'utility:clear',
            Overridden: 'utility:success',
        };
        
        return icons[verificationStatus] || '';         
    }

    getIconClass(verificationStatus) {
        const classes = {
            Verified: 'slds-icon-text-success',
            Unverified: 'slds-icon-text-error',
            Overridden: 'slds-icon-text-success',
        };
        
        return classes[verificationStatus] || '';
    }

    handleExport() {
         // Get all selected rows from the datatable
         const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows(); 
         //Filtre out "Unverified" prices from selected rows
         const verifiedRows = selectedRows.filter((row) => row.PPA_Verification_Status__c !== 'Unverified');
         const selectedPriceListIds = verifiedRows.map((row) => row.Id); 

         if (selectedPriceListIds.length > 0) { 
            this.showSpinner = true;
            console.log(selectedPriceListIds);
            // Call the export method in the controller class
            exportSelectedPriceLists({ priceListIds: selectedPriceListIds }) 
            .then((result) => { 
                // Handle successful export
                this.showSuccessToast(result); 
                // After export, remove the exported Price Lists from the view
                refreshApex(this.dataToRefresh);
                this.showSpinner = false; 
            })
            .catch((error) => { 
                console.error('Error exporting Price Lists:', error); 
                // Handle error
                this.showErrorToast(error.body.message); 
                this.showSpinner = false; 
            }); 
        } else { 
            // If no records are selected, display a warning toast
            this.showWarningToast(); 
        }
    }    
  
    handleRowAction(event) {
        const recordId = event.detail.row.Id;
        const verStatus = event.detail.row.PPA_Verification_Status__c;
        const action = event.detail.action.name;

        if(action == 'override' && recordId != null && verStatus == 'Unverified') {
            this.handleOverride(recordId);
        }

        if(action == 'view' && recordId != null) {
            window.location.href = '/' + recordId;
        }
    }    

    async handleOverride(recordId) {
        //you will need to call a modal lwc to allow for Cancel, Submit and option Over-ride reason
        const result = await ExportToERPModal.open({
            size: 'small',
            description: 'This is to open the Confirm Override Modal',
            recordId: recordId
        });

        if(result == 'OK') {
            refreshApex(this.dataToRefresh);
        }
    }

    showSuccessToast(numRecords) {
        const toastEvent = new ShowToastEvent({
            title: 'Success!',
            message: numRecords + ' record(s) successfully submitted for export.',
            variant: 'success'
        });
        
        this.dispatchEvent(toastEvent);
    }
        
    showErrorToast(errorMessage) {
        const toastEvent = new ShowToastEvent({
            title: 'Error!',
            message: errorMessage,
            variant: 'error'
        });
        
        this.dispatchEvent(toastEvent);
    }
        
    showWarningToast() {
        const toastEvent = new ShowToastEvent({
            title: 'Warning!',
            message: 'Please select at least one record to export.',
            variant: 'warning'
        });
        
        this.dispatchEvent(toastEvent);
    }

    onHandleSort(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        
        let sortedData = [...this.priceListData];

            if (sortDirection === 'asc'){
                sortedData = sortedData.slice().sort((a,b) => (a[fieldName] > b[fieldName]) ? 1 : -1);
            }
            else if (sortDirection === 'desc'){
                sortedData = sortedData.slice().sort((a,b) => (a[fieldName] < b[fieldName]) ? 1 : -1);
            }

        this.priceListData = sortedData;
        this.sortDirection = sortDirection;
        this.sortedBy = fieldName;
    }
}