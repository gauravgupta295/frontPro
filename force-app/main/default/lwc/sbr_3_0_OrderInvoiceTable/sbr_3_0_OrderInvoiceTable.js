import { LightningElement, api, wire } from 'lwc';
import getInvoiceList from '@salesforce/apex/SBR_3_0_InvoiceTableCmpController.getInvoiceListForOrder';
import buildRequest from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.buildRequest';
import loadOrderFields from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.loadOrderFields';
import RetrieveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.RetrieveFile';
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    // { label: 'Sequence', fieldName: 'Invoice_Sequence_Number__c', sortable: true, type: 'url',  typeAttributes: { label: { fieldName: 'Sequence' }, name: 'Sequence'} },
    {label: 'Sequence',
        type: 'button',
        initialWidth: 200,
        typeAttributes: {
            label: {fieldName: 'Invoice_Sequence_Number__c'},
            variant: 'base',
        }
    },
    // { type: 'button', typeAttributes: { label: 'Sequence', fieldName: 'Invoice_Sequence_Number__c', variant: 'base' } },
    { label: 'Invoice Date', filedName: 'Invoice_Date__c', type: 'date', sortable: true },
    { label: 'Invoice Amount', fieldName: 'Total_invoice_Amount__c', type: 'currency', sortable: true },
    { label: 'Invoice Status', fieldName: 'Order_Status__c', sortable: true },
    { label: 'Job Site Branch', fieldName: 'Job_Site__c', sortble: true },
];

export default class Sbr_3_0_OrderInvoiceTable extends NavigationMixin (LightningElement) {
    @api recordId;
    @api pdfTitle;
    invoiceData;
    preFilterData;
    columns = columns;
    dateFilter;
    statusFilter;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    fileRetrieved = false;
    rmId;
    companyId;
    seqNum;

    @wire(getInvoiceList, {orderId: '$recordId'})
    invoiceList({error, data}){
        if(data){
            console.log('Inside InvoiceList');
            this.invoiceData = data;
            console.log(this.invoiceData);
            //console.log('Invoice sequence number '+data[0].Invoice_Sequence_Number__c);
            this.preFilterData = data;
        }
        else{
            console.log("Error detected: ", error);
        }
    }
    connectedCallback() {
        console.log('Inside CC');
        console.log('this.recordId '+this.recordId);
        loadOrderFields({ recordId: this.recordId}).then(
            result => {
                this.pdfTitle = result.orderNumber;
                if(result.contractNumber != null){
                    this.rmId = result.contractNumber;
                    this.companyId = result.companyId;
                    this.seqNum = this.Invoice_Sequence_Number__c;
                    console.log(this.rmId);
                    console.log(this.companyId);
                    //console.log(Invoice_Sequence_Number__c);
               }
            }
        ).catch(err => {
            console.log('err'+JSON.stringify(err));
            this.spinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `Loading Order fields failed.`,
                    variant: 'error',
                }),
            );
            this.handleCancel();
            console.log(err);
        });
    
    }

    getPDF(event){
        console.log('Inside GetPDF');
        console.log(this.rmId);
        console.log(this.companyId);
        console.log(this.seqNum);
        buildRequest({ rentanlManId: this.rmId, companyCode : this.companyId, seqNum:this.seqNum}).then(
        result => {
            this.spinner = false;
            if(result.status === 'InComplete'){
                console.log('Incomplete');
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
        console.log('pdftitle ->'+this.pdfTitle);
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
            console.log(err);
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
    
    get dateOptions(){
        return [
            { label: 'Over 30', value: 30},
            { label: 'Over 60', value: 60},
            { label: 'Over 90', value: 90},
            {label: 'Over 120', value: 120}
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


    filterStatus(){
        this.statusFilter = event.target.value;
        this.invoiceData = this.getStatusFilter(this.statusFilter);
    }

    filterDate(){
        this.dateFilter = event.target.value;
        this.invoiceData = this.getTimeFilter(this.dateFilter);
    }

    getTimeFilter(days){
        let postFilterData = [];
        for(let i = 0; i < this.preFilterData.length; i++){
            var currentDate = new Date();
            var assignedDate = new Date(this.preFilterData[i].Invoice_Date__c);
            console.log('assigned Date: ', assignedDate);
            var timeDifference = currentDate.getTime() - assignedDate.getTime();
            let timePassed = timeDifference / (1000 * 3600 * 24);
            if(timePassed <= days){
                postFilterData.push(this.preFilterData[i]);
            }
        }
        return postFilterData;       
    }

    getStatusFilter(status){
        let postFilterData = [];
        for(let i = 0; i < this.preFilterData.length; i++){
            if(this.preFilterData[i] == status){
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

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.invoiceData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.invoiceData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
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

    handleRowActions(event){
        console.log('Inside Handle Row Action');
        const actionName = event.detail.action.name;
        this.seqNum = event.detail.row.Invoice_Sequence_Number__c;
        console.log('Inside HandleRowAction Invoice_Sequence_Number__c'+ this.seqNum);
        console.log('Inside HandleRowAction Invoice_Sequence_Number__c'+ event.detail.row.Invoice_Sequence_Number__c);
        this.getPDF(event);

    }
}