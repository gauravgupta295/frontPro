import { LightningElement, api, wire } from 'lwc';
import getInvoiceList from '@salesforce/apex/SBR_3_0_InvoiceTableCmpController.getInvoiceList';
import buildRequest from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.buildRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile';
import { NavigationMixin } from 'lightning/navigation';
import customDataTableCSSInvoiceTable from '@salesforce/resourceUrl/customDataTableInvoiceTable';
import { loadStyle } from 'lightning/platformResourceLoader';

const columns = [
    { label: 'Contract #',fieldName: 'Contract_Number__c', sortable: true },
    {label: 'Sequence',
        type: 'button',
        typeAttributes: {
            label: {fieldName: 'Invoice_Sequence_Number__c'},
            variant: 'base',
        }
    },
    { label: 'Invoice Date', fieldName: 'Invoice_Date__c', type: 'date', sortable: true },
    { label: 'Invoice Amount', fieldName: 'Total_invoice_Amount__c', type: 'currency', sortable: true ,cellAttributes: { alignment: 'left' },},
    { label: 'Invoice Status', fieldName: 'Order_Status__c', sortable: true },
    { label: 'Sourcing Branch', fieldName: 'sourcingBranchName', sortable: true },
];


const columnsMobile = [
    { label: 'Contract #',fieldName: 'Contract_Number__c',sortable: true 
},
    {label: 'Sequence',
        type: 'button',
        initialWidth: 200,
        typeAttributes: {
            label: {fieldName: 'Invoice_Sequence_Number__c'},
            variant: 'base',
        }
    },
    { label: 'Invoice Date', fieldName: 'Invoice_Date__c', type: 'date', sortable: true },
    { label: 'Invoice Amount', fieldName: 'Total_invoice_Amount__c', type: 'currency', sortable: true ,cellAttributes: { alignment: 'left' },},
    { label: 'Invoice Status', fieldName: 'Order_Status__c', sortable: true },
    { label: 'Sourcing Branch', fieldName: 'sourcingBranchName', sortable: true },
];

export default class Sbr_3_0_invoiceTableCmp extends  NavigationMixin (LightningElement) {
    @api recordId;
    invoiceData;
    preFilterData;
    columns = columns;
    columnsMobile=columnsMobile;
    dateFilter;
    statusFilter;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    seqNum;
    companyId;
    rmId;
    pdfTitle;
    errorMessage;
    invoiceAmount;
    invoiceAmountTable;
    isMobile;
     

    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
     }
    
    renderedCallback() {
        
        Promise.all([
            loadStyle( this, customDataTableCSSInvoiceTable)
            ]).then(() => {
 
            })
            .catch(error => {
                
        });

    }

    @wire(getInvoiceList, {accountId: '$recordId'})
    invoiceList({error, data}){
        // SF-7873 Added data.lenth condition as data[0] throws error when no records
        if(data && data.length > 0){
            this.invoiceAmount = data[0].Total_invoice_Amount__c;
            this.invoiceData= data.map(invoiceData => {
                return {
                    ...invoiceData,
                    sourcingBranchName: invoiceData.Order__r && invoiceData.Order__r.Sourcing_Branch__r ? invoiceData.Order__r.Sourcing_Branch__r.Name : ''
                    
                    
                }
            });
            
           this.preFilterData = data.map(invoiceData => {
                return {
                    ...invoiceData,
                    sourcingBranchName: invoiceData.Order__r && invoiceData.Order__r.Sourcing_Branch__r ? invoiceData.Order__r.Sourcing_Branch__r.Name:''
                   
                }
            });
        }
    
        else if(error){
            this.errorMessage = error.body.message || 'Unknown error';
        }
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
                objectApiName:'Account',
                relationshipApiName: 'AttachedContentDocuments',
                actionName: 'view'
            },
        }
        );
    }

    get dateOptions(){
        return [
            { label: 'Over 30', value: '30'},
            { label: 'Over 60', value: '60'},
            { label: 'Over 90', value: '90'},
            {label: 'Over 120', value: '120'}
        ]
    }

    get statusOptions(){
        return [
            {label: 'OP-open', value: 'OP-open' },
            {label: 'HL-Held', value: 'HL-Held'},
            {label: 'IN-Invoiced', value: 'IN-Invoiced'},
            {label: 'PD-Paid', value: 'PD-Paid'},
            {label: 'EQ-Equipment Sale Quote', value: 'EQ-Equipment Sale Quote'},
            {label: 'ER-Equipment Sale Reservation', value: 'ER-Equipment Sale Reservation'},
            {label: 'RP-Rental Purchase', value: 'RP-Rental Purchase'},
            {label: 'RQ-Rental Purchase Quote', value: 'RQ-Rental Purchase Quote'},
            {label: 'FL-Filled', value: 'FL-Filled'},
            {label: 'CN-Cancelled', value: 'CN-Cancelled'},
            {label: 'CP-Completed', value: 'CP-Completed'},
            {label: 'CM-Sales credit memo', value: 'CM-Sales credit memo'}
        ]
    }


    filterStatus(event){
        this.statusFilter = event.detail.value;
        if(this.preFilterData)  // SF-7873
            this.invoiceData = this.getStatusFilter(this.statusFilter); 
    }

    filterDate(event){
       this.dateFilter = event.detail.value;
       if(this.preFilterData)   // SF-7873
            this.invoiceData = this.getTimeFilter(this.dateFilter);
        
    }

    getTimeFilter(days){
        let postFilterData = [];
        for(let i = 0; i < this.preFilterData.length; i++){
            var currentDate = new Date();
            var assignedDate = new Date(this.preFilterData[i].Invoice_Date__c);
            var timeDifference = currentDate.getTime() - assignedDate.getTime();
            let timePassed = timeDifference / (1000 * 3600 * 24);
            if(timePassed <= days){
                postFilterData.push(this.preFilterData[i]);
            }
        }
        return postFilterData;       
    }

    getStatusFilter(status){
        let satusAPI = status.split('-')[1];
        let postFilterData = [];
        for(let i = 0; i < this.preFilterData.length; i++){
            if(this.preFilterData[i].Order_Status__c == satusAPI){
                
                postFilterData.push(this.preFilterData[i]);
            }
        }
       return postFilterData; 
    }

    clearFilter(){
        this.invoiceData = this.preFilterData;
        this.dateFilter = 'Date Filter';
        this.statusFilter = 'Status Filter';
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
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

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.invoiceData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.invoiceData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleRowActions(event){
        const actionName = event.detail.action.name;
        this.seqNum = event.detail.row.Invoice_Sequence_Number__c;
        this.rmId=event.detail.row.Contract_Number__c;
        this.companyId=event.detail.row.Invoice_number__c.substring(0, 2);
        this.pdfTitle=event.detail.row.Contract_Number__c;
        this.getPDF(event);

    }

}