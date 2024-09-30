import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import buildRequest from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.buildRequest';
import loadOrderFields from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.loadOrderFields';
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 

export default class Sbr_3_0_generateReservationContractOrderPDF extends  NavigationMixin (LightningElement) {

    @api recordId;
    isValidOrderRecord = false;
    orderRecordType;
    reservationNumber;
    contractNumber
    spinner = false;
    fileSaved = false;
    fileData;
    @api pdfTitle;
    @api isAuraCmp;
    rmId;
    companyId;
    seqNum;

   /*  @wire(getRecord, {
        recordId: '$recordId',
        fields: [ORDER_NUMBER]
    })  */

    connectedCallback() {
        this.spinner = true;
        this.pdfTitle = 'Order';

        loadOrderFields({ recordId: this.recordId}).then(
            result => {
                this.spinner = false;
                this.pdfTitle = result.orderNumber;
               if(result.isValidOrderRecord === 'N'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: `Please submit the Reservation to generate the PDF.`,
                            variant: 'error',
                        }),
                    );
                    this.handleCancel();
               }else if(result.contractNumber != null){
                    this.rmId = result.contractNumber;
                    this.companyId = result.companyId;
                    this.seqNum = result.seqNum;
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
        });
      
    }
    
    getPDF(event){
        this.spinner = true;
        buildRequest({ rentanlManId: this.rmId, companyCode : this.companyId, seqNum:this.seqNum}).then(
        result => {
            this.spinner = false;
            console.log('result',result);
            if(result.status === 'InComplete'){
                this.spinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `System failed to retrieve the PDF. Please try again, contact Support if the problem persists.`,
                        variant: 'error',
                    }),
                );
                this.handleCancel();
            }else{

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
                if (FORM_FACTOR !== 'Small') {
                    const a = document.createElement('a');        
                    a.href = arrayBufferBlobURL;
                    a.target = '_blank';
                    a.download = this.pdfTitle + '.pdf';
                   // a.click();
                }
                this.fileData = {
                    'filename': this.pdfTitle,
                    'base64': result.base64Body,
                    'recordId': this.recordId
                }
                this.savePDFToSF();
                //this.handleCancel();
            }
           
        }
    ).catch(err => {
            console.log(err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `System failed to retrieve the PDF. Please try again, contact Support if the problem persists.`,
                    variant: 'error',
                }),
            );
            this.handleCancel();
        });
    }

    handleCancel() {
        if(this.isAuraCmp !=undefined || this.isAuraCmp !=null){
            this.callValueChangeEvent();
        }else{
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
    }
    callValueChangeEvent(){
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: {
                "isCancelClicked": true
            }
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
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
                    if (FORM_FACTOR === 'Small') {
                        this.navigateToFilesHome(recordId);
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `File Saved to Salesforce.`,
                            variant: 'success',
                        }),
                    );
                    this.handleCancel();
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
}