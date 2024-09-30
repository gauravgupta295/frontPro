import { api, LightningElement, track, wire } from 'lwc';
import { getRecord} from "lightning/uiRecordApi";
import getInvoices from '@salesforce/apex/SBR_3_0_InvoiceDA.getInvoicesForOrder';
import buildRequest from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.buildRequest';
import loadOrderFields from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.loadOrderFields';
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile';
import ORDER_OBJECT from '@salesforce/schema/Order';
import ACCOUNT_ID from '@salesforce/schema/Order.AccountId';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import customDataTableCSSInvoiceContainerTable from '@salesforce/resourceUrl/customDataTableInvoiceContainerTable';
import { loadStyle } from 'lightning/platformResourceLoader';

const columns1 = [
    {label: 'Sequence',
        fieldName: 'Invoice_Sequence_Number__c',
        type: 'button',
        initialWidth: 200,
        sortable: true,
        typeAttributes: {
            label: {fieldName: 'Invoice_Sequence_Number__c'},
            variant: 'base',
            }
        },
    //{ label: 'Sequence', fieldName: 'Invoice_Sequence_Number__c', sortable: true },
    { label: 'Invoice Date', filedName: 'Invoice_Date__c', type: 'date', sortable: true },
    { label: 'Invoice Amount', fieldName: 'Total_invoice_Amount__c', type: 'currency', sortable: true,   cellAttributes: { alignment: 'left' } },
    { label: 'Invoice Status', fieldName: 'Order_Status__c', sortable: true },
    { label: 'Job Site Branch', fieldName: 'Job_Site__c', sortble: true },
];

export default class Sbr_3_0_invoiceContainerCmp extends NavigationMixin (LightningElement) {

    @api recordId;
    @api objectApiName;
    @track invoiceDataPresent=false;
    @track noItemsMsg = "There are no invoices available for this record.";
    isMobile = false;
    @api isMobileRequestView = false;
    lineItemClass;
    requestHeader;
    @track showAssetList = true;
    listClass;
    fileRetrieved = false;
    @track data = [];
    columns = [
        {label: 'Sequence',
        fieldName: 'Invoice_Sequence_Number__c',
        type: 'button',
        initialWidth: 200,
        sortable: true,
        typeAttributes: {
            label: {fieldName: 'Invoice_Sequence_Number__c'},
            variant: 'base',
            }
        },
        // {label: 'Sequence', fieldName: 'Invoice_Sequence_Number__c', type: 'number', sortable: true},
        {label: 'Date', fieldName: 'Invoice_Date__c', type: 'date-local', sortable: true},
        {label: 'Invoice Amount', fieldName: 'Total_invoice_Amount__c', type: 'currency',  cellAttributes: { alignment: 'left' }, sortable: true},
        {label: 'Status', fieldName: 'Order_Status__c', type: 'text', sortable: true}
    ];
    accountId;
    selectedStatus = 'OP';
    fromDate;
    toDate;
    selectedAge = '0';
    allData = [];

    
    defaultSortDirection = 'asc';
    @track sortBy;
    @track sortDirection;

    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    orderObjectInfo;
    loadMoreDataMobile(event) {
        if (event.target.scrollTop > event.target.scrollHeight - (event.target.offsetHeight) && !this.mobileIsLoading) {
            this.mobileIsLoading = true;
            new Promise(
                (resolve, reject) => {
                    setTimeout(() => {
                        this.getOrderAssetData(this.rowsOffset, true, false);
                        resolve();
                    }, 3000);
                }).then(
                    () => this.mobileIsLoading = false
                );
          
        }
    }

    connectedCallback() {
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        this.noItemsMsg = "There are no invoices available for this record.";
        if (this.isMobileRequestView) {
            this.listClass = "item-list-ctr slds-scrollable_y request-list";
            this.lineItemClass = "line-item slds-p-around_medium request-view-item";
        } else {
            this.lineItemClass = "line-item slds-p-around_medium";
            this.listClass = "item-list-ctr slds-scrollable_y";
        }
        this.getInvoiceData();
        loadOrderFields({ recordId: this.recordId}).then(
            result => {
                this.pdfTitle = result.orderNumber;
                if(result.contractNumber != null){
                    this.rmId = result.contractNumber;
                    this.companyId = result.companyId;
                    this.seqNum = this.Invoice_Sequence_Number__c;
                   
               }
            }
        ).catch(err => {
            
            this.spinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `Loading Order fields failed.`,
                    variant: 'error',
                }),
            );
            this.handleCancel();
          });
    }
    renderedCallback() {
        
        Promise.all([
            loadStyle( this, customDataTableCSSInvoiceContainerTable)
            ]).then(() => {
              
            })
            .catch(error => {
                
        });

    }

    updateShowAssetList(event) {
        this.showAssetList = !event.detail.filtersOpen;
    }

    get assetListDisplayClass() {
        return this.showAssetList ? 'show' : 'hide';
    }
    
  
    getInvoiceData() {
        getInvoices({orderId: this.recordId})
        .then((data) => {
            if (data.length > 0) {
               let tempData = JSON.parse(JSON.stringify(data));
                this.invoiceDataPresent=true;
                this.allData = tempData.map(row => {
                    return {
                        ...row,
                        sequence: row?.Invoice_Sequence_Number__c,
                        date: row?.Invoice_Date__c,
                        amount: row?.Total_invoice_Amount__c,
                        status: row?.Order_Status__c
                    }
                });
                
                this.filterInvoiceData('All', null, null, '0');
            }
            else{
                this.invoiceDataPresent=false;
            }            
        });
    }
    
    filterInvoiceData(status, fromDate, toDate, age) {
       
        let filteredData = this.allData;
        
        if (status && status!= 'All' && status!= 'All Statuses') {
            filteredData = filteredData.filter(row => row.status === status);
        }
        if (fromDate) {
            filteredData = filteredData.filter(row => new Date(row.date.concat('T00:00:00')) >= new Date(fromDate.concat('T00:00:00')));
       }
        if (toDate) {
            filteredData = filteredData.filter(row => new Date(row.date.concat('T00:00:00')) <= new Date(toDate.concat('T00:00:00')));
        }
        if (age != null && age!=0 ) {
            age = parseInt(age);
            filteredData = filteredData.filter(row => {
                let today = new Date(new Date().setHours(0,0,0,0));
                let fromAge = new Date(new Date().setDate(today.getDate() - (age + 1)));
                fromAge.setHours(0,0,0,0);
                let toAge = new Date(new Date().setDate(today.getDate() - (age + 30)));
                toAge.setHours(0,0,0,0);
                let rowDate = new Date(row.date.concat('T00:00:00'));
                if (age == 0) {
                    return (rowDate <= today && rowDate >= toAge);
                } else if (age != 120) {
                    return (rowDate <= fromAge && rowDate >= toAge);
                } else {
                    return (rowDate < fromAge);
                }
            });
        }
        
        this.data = filteredData;
    }

    getPDF(event){
       buildRequest({ rentanlManId: this.rmId, companyCode : this.companyId, seqNum:this.seqNum}).then(
        result => {
            this.spinner = false;
            if(result.status === 'InComplete'){
                this.spinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `System failed to retrieve the PDF. Please try again, contact Support if the problem persists.`,
                        variant: 'error',
                    }),
                );
            }else{
                this.fileRetrieved = true;    
                this.displayPDF(result);

            }
        }
    )}

    displayPDF(result){
        const ADOBE_KEY = '80a7233f94134d00b16e08dab3a774f4'; 
        let adobeDCView = null;
        const responseFile = new Blob([result.body], {
            type: 'application/pdf',
        });
        let responseFileURL = URL.createObjectURL(responseFile);
        
        let fileReader = new FileReader();
        let blobArrayBuffer;
        fileReader.readAsArrayBuffer(responseFile);

        fileReader.onloadend = function() {
            blobArrayBuffer = fileReader.result;                    
        }; 
        
        let arrayBuffer = this.base64ToArrayBuffer(result.base64Body);
        let arrayBufferBlob = new Blob([arrayBuffer], {
            type: 'application/pdf',
        });
       
        let arrayBufferBlobURL = URL.createObjectURL(arrayBufferBlob);
        const a = document.createElement('a');        
        a.href = arrayBufferBlobURL;

        //tablet or ipad browser, open in new window
        if(FORM_FACTOR ==='Medium'){
            //a.target = '_blank';
            //a.click();
        }
            //auto download on laptop/Desktop
        if(FORM_FACTOR === 'Large'){
            a.download = this.pdfTitle+'.pdf';
            // a.click();
        }

        this.fileData = {
            'filename': this.pdfTitle,
            'base64': result.base64Body,
            'recordId': this.recordId
        }
        this.savePDFToSF();

    }


    savePDFToSF(){
       const {base64, filename, recordId} = this.fileData
        SaveFile({ base64, filename, recordId }).then(
            result => {

                this.fileSaved = result.status == 'SUCCESS' ? true : false;
                this.spinner = false;
                this.fileData = null;

                if (this.fileSaved) {                   
                    this.previewHandler(result);
                    //Navigate to Files in Mobile app
                    if(FORM_FACTOR === 'Small'){
                        this.navigateToFilesHome(recordId);
                    }
                  
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `File Saved to Salesforce.`,
                            variant: 'success',
                        }),
                    );
                }
            }
        ).catch(err => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `File Not Saved to Salesforce due to errors.`,
                    variant: 'error',
                }),
            );
        });
    }

    navigateToFilesHome(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: recordId,
                objectApiName:'Order',
                relationshipApiName: 'AttachedContentDocuments',
                actionName: 'view'
            },
        }
        );
    }

    previewHandler(result){
        const url = generateUrl(result.contentDocumentId); 
        window.open(url,'_blank');
    }

    base64ToArrayBuffer(base64) {
        var bin = window.atob(base64);
        var len = bin.length;
        var uInt8Array = new Uint8Array(len);
        for (var i = 0; i < len; i++) {
            uInt8Array[i] = bin.charCodeAt(i);
        }
        return uInt8Array.buffer;
    }

    handleFilterUpdate(event) {
        let data = event.detail;
        if (data) {
            this.selectedStatus = data.selectedStatus;
            this.fromDate = data.selectedFromDate;
            this.toDate = data.selectedToDate;
            this.selectedAge = data.selectedAge;
            this.filterInvoiceData(this.selectedStatus, this.fromDate, this.toDate, this.selectedAge);
        }
    }
    onHandleSort(event) {
        
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
        /*const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;*/
    }
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }    
    handleRowActions(event){
        const actionName = event.detail.action.name;
        this.seqNum = event.detail.row.Invoice_Sequence_Number__c;
        this.getPDF(event);

    }
}