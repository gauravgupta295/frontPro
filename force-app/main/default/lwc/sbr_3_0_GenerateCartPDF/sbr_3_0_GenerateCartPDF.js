import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import getTemplates from '@salesforce/apex/SBR_3_0_CartPDFDocController.getTemplates';
import submitTemplate from '@salesforce/apex/SBR_3_0_CartPDFDocController.buildRequest';
import loadCartFields from '@salesforce/apex/SBR_3_0_CartPDFDocController.loadCartFields';
import RetrieveFile from '@salesforce/apex/SBR_3_0_CartPDFDocController.RetrieveFile';
import SaveFile from '@salesforce/apex/SBR_3_0_CartPDFDocController.saveFile';
import AdobeScriptSrc from '@salesforce/resourceUrl/AdobeScriptSrc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import NAME_FIELD from '@salesforce/schema/Cart__c.Name';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 

export default class sbr_3_0_GenerateCartPDF extends  NavigationMixin (LightningElement) {
    value;
    templates = [];
    @api recordId;
    getFile = false;
    fileRepo;
    pdf;
    fileRetrieved = false;
    spinner = false;
    fileSaved = false;
    fileData;
    @api pdfTitle;
    @api isAuraCmp;
    httpCalloutMap;
    disableSubmitButton = true;
    disableGetFileButton = true;
    cartData;
    isChangeFileName = false;
    isCartItemsAvailable = true;
    @api fileName;

    isFileLoaded = false;
    timerId;
    isTimerKilled = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD]
    }) 

    connectedCallback() {
        console.log('this.recordId->' + this.recordId);
        if (this.recordId) {
            loadCartFields({ recordId: this.recordId}).then(
                result => {
                    console.log('result->'+result.data);
                    if (result.data == null) {
                        this.spinner = false;
                        this.isCartItemsAvailable = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: `To generate a PDF, at least one Cart Item must be associated to the Cart record.!`,
                                variant: 'error',
                            }),
                        );
                        this.handleCancel();
                    } else {
                        this.cartData = result.data;
                        this.pdfTitle = result.pdfTitle;
                        this.fileName = result.pdfTitle;
                    }
                    
                }
            )
            getTemplates({ recordId: this.recordId}).then(
                result => {
                    let tempArray = [];
                    for (var i = 0; i < result.length; i++) {
                        console.log(result[i].Name + result[i].Id);
                        tempArray.push({ label: result[i].Name, value: result[i].Id });
                    }
                    this.templates = tempArray;
                }
            )
        }        
    }
    handleChange(event) {
        this.value = event.detail.value;
        this.disableSubmitButton = false;
    }
    handleChecked(event) {
        this.isChangeFileName = event.target.checked;
        if (!this.isChangeFileName) {
            this.fileName = this.pdfTitle;
        }
    }
    handleFileNameChange(event) {
        this.fileName = event.detail.value;
    }
   
    submitTemplate(event) {
        let templateRecordId = this.value;
        let isValidationPassed = true;

        if (this.fileName === undefined || this.fileName === '' || this.fileName.length === 0) {
            isValidationPassed = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `You must enter new file name to generate PDF document.`,
                    variant: 'error',
                }),
            );
        } else if (templateRecordId === null || templateRecordId === undefined) {
            isValidationPassed = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `You must select a template to generate PDF document.`,
                    variant: 'error',
                }),
            );
        } else {
            isValidationPassed = true;
            this.pdfTitle = this.fileName;
        }
        
        if (isValidationPassed) {
            this.spinner = true;
            submitTemplate({ cartMap: this.cartData, templateId: this.value, pdfName: this.pdfTitle }).then(
                result => {
                    if (result.contentDocumentId != undefined || result.contentDocumentId != null) {
                        this.fileRetrieved = true;
                        this.previewHandler(result);
                        //Navigate to Files in Mobile app
                        if(FORM_FACTOR === 'Small'){
                            this.navigateToFilesHome(recordId);
                        }
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: `File retrieved.`,
                                variant: 'success',
                            }),
                        );
                        if(this.isAuraCmp !=undefined || this.isAuraCmp !=null){
                            this.callValueChangeEvent();
                        }else{
                            this.dispatchEvent(new CloseActionScreenEvent());
                        }
                    } else {
                        this.httpCalloutMap = {
                            'endPoint': result.httpDocGenEndPoint,
                            'authToken': result.httpDocGenAuthToken
                        }
                        if(result.status == 'InComplete'){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: `Request was not successful. Please try again later.!`,
                                    variant: 'error',
                                }),
                            );
                            this.dispatchEvent(new CloseActionScreenEvent());
                        }
                        if (result.status == 'false') {
                            this.fileRepo = result.body;
                            this.timerId = setInterval(() => {                       
                                this.retriveFileFromRepoId();
                            }, 1000);
                        }
                        else{ 
                            this.fileRetrieved = true;  
                            this.displayPDF(result);
                        }
                    }
                }
            ).catch(err => {
                console.log(err);
            });
        }
        
    }

    getFlie(event) {
        this.spinner = true;
        this.fileRetrieved = false;
        const {endPoint, authToken} = this.httpCalloutMap;
        RetrieveFile({ repoId: this.fileRepo, endPoint, authToken }).then(
            result => {

                this.spinner = false;
                this.pdf = result.body;

                if(result.status === 'BadRequest'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: `Request was not successful. Please try again later.!`,
                            variant: 'error',
                        }),
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
                if(result.status === 'Complete'){
                    this.fileRetrieved = true;
                    this.displayPDF(result);
                }else if(result.status === 'InComplete'){
                    this.fileRetrieved = false;
                    this.getFile = true;
                    this.disableGetFileButton = true;
                   //Enable the 'Get File' button after 20 sec
                   console.log('File Retrieval still in-progress for repoId:'+this.fileRepo);
                   let timerGetFileButton = setTimeout(() => {                       
                       this.displayGetFileButton();
                   }, 20000);
                }
            }
        ).catch(err => {
            console.log(err);
        });
    }

    displayPDF(result){
        // This Client Id works fine for all 'force.com' domain. This needs to be changed for prod org if its diffent domain.
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
         if(FORM_FACTOR === 'Large' && this.isTimerKilled){
            //a.download = this.pdfTitle + '.pdf';
            a.target = '_blank';
            this.isFileLoaded = true; 
            let dateToday = new Date();
            a.click();
            console.log('Time: file loaded on UI->'+dateToday.toISOString());
        }

        this.fileData = {
            'filename': this.pdfTitle,
            'base64': result.base64Body,
            'recordId': this.recordId
        }
        this.savePDFToSF();
    }

    saveFile(event) {
        this.spinner = true;
        const {base64, filename, recordId} = this.fileData
        SaveFile({ base64, filename, recordId }).then(
            result => {
                this.fileSaved = result.status == 'SUCCESS' ? true : false;
                this.spinner = false;
                this.fileData = null;

                if (this.fileSaved) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `File Saved to Salesforce.`,
                            variant: 'success',
                        }),
                    );
                    
                    if(this.isAuraCmp !=undefined || this.isAuraCmp !=null){
                        this.callValueChangeEvent();
                    }else{
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }
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

    base64ToArrayBuffer(base64) {
        var bin = window.atob(base64);
        var len = bin.length;
        var uInt8Array = new Uint8Array(len);
        for (var i = 0; i < len; i++) {
          uInt8Array[i] = bin.charCodeAt(i);
        }
        return uInt8Array.buffer;
    }
    handleCancel() {
        if(this.isAuraCmp !=undefined || this.isAuraCmp !=null){
            this.callValueChangeEvent();
        }else{
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
    }
    get showTemplateCondition() { 
        return (this.getFile === false && this.fileRetrieved === false);
    }
    get showGetFileCondition() { 
        return (this.getFile === true && this.fileRetrieved === false);
    }
    displayGetFileButton(){
        this.disableGetFileButton = false;
    }
    get showFileNameCondition() { 
        return (this.getFile === false && this.fileRetrieved === false && this.disableSubmitButton === false );
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

    retriveFileFromRepoId() {
        this.spinner = true;
        this.fileRetrieved = false;
        const { endPoint, authToken } = this.httpCalloutMap;
        console.log('this.fileRepo->'+this.fileRepo);
        RetrieveFile({ repoId: this.fileRepo, endPoint, authToken}).then(
            result => {
                this.spinner = false;
                this.pdf = result.body;
                console.log('retriveFileFromRepoId.result->'+result);
                if(result.status === 'BadRequest'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: `Request was not successful. Please try again later.!`,
                            variant: 'error',
                        }),
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
                if(result.status == 'Complete' ){
                    this.fileRetrieved = true;
                    //clear the timerInterval
                    if ((this.timerId != undefined || this.timerId != null) && !this.isTimerKilled) {
                        console.log('this.timerId->'+this.timerId);
                        clearInterval(this.timerId);
                        console.log('kill timer');
                        this.isTimerKilled = true;
                        console.log('Killed timerId->'+this.timerId);
                        //this.displayPDF(result);
                    }
                    if(this.isTimerKilled && !this.isFileLoaded) {
                        this.displayPDF(result);
                    }
                }else if(result.status === 'InComplete'){
                    this.fileRetrieved = false;
                    this.getFile = true;
                    this.disableGetFileButton = true;
                    //Enable the 'Get File' button after 20 sec
                    console.log('File Retrieval still in-progress');
                    let timerGetFileButton = setTimeout(() => {                       
                        this.displayGetFileButton();
                    }, 20000);
                }
            }
        ).catch(err => {
            console.log(err);
        });
    }
    savePDFToSF(){
        const {base64, filename, recordId} = this.fileData
        SaveFile({ base64, filename, recordId }).then(
            result => {

                this.fileSaved = result.status == 'SUCCESS' ? true : false;
                this.spinner = false;
                this.fileData = null;

                if (this.fileSaved) {
                    if (!this.isFileLoaded) {
                        this.previewHandler(result);
                    }
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
                    if(this.isAuraCmp !=undefined || this.isAuraCmp !=null){
                        this.callValueChangeEvent();
                    }else{
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }
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
                objectApiName:'Cart__c',
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