import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import getTemplates from '@salesforce/apex/SBR_3_0_GeneratePDFDocQuote.getTemplates';
import submitTemplate from '@salesforce/apex/SBR_3_0_GeneratePDFDocQuote.buildRequest';
import loadQuoteFields from '@salesforce/apex/SBR_3_0_GeneratePDFDocQuote.loadQuoteFields';
import RetrieveFile from '@salesforce/apex/SBR_3_0_GeneratePDFDocQuote.RetrieveFile';
import SaveFile from '@salesforce/apex/SBR_3_0_GeneratePDFDocQuote.saveFile';
import AdobeScriptSrc from '@salesforce/resourceUrl/AdobeScriptSrc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import QUOTE_ACCOUNT_LOOKUP_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { generateUrl } from 'lightning/fileDownload'; 

/* import getTemplates from '@salesforce/apex/SBR_3_0_quoteSelectorController.getTemplates';
import submitTemplate from '@salesforce/apex/SBR_3_0_quoteSelectorController.buildRequest';
import loadQuoteFields from '@salesforce/apex/SBR_3_0_quoteSelectorController.loadQuoteFields';
import RetrieveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.RetrieveFile';
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile'; */

export default class Sbr_3_0_quoteSelector extends  NavigationMixin (LightningElement) {
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
    quoteData;
    isChangeFileName = false;
    @api fileName;

    isFileLoaded = false;
    timerId;
    isTimerKilled = false;

    modalStyle = "height:20rem;position:relative";

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [QUOTE_ACCOUNT_LOOKUP_FIELD]
    }) 

    connectedCallback() {
        if(FORM_FACTOR === 'Small'){
           this.modalStyle = "height:36rem;position:relative"
        }
        loadScript(this, AdobeScriptSrc).then(() => {
            console.log('loadScript run->adobe viewer.js from script tag');
        }).catch(err => {
            console.log(err);
        });
        console.log('recordId : ', this.recordId);
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
        loadQuoteFields({ recordId: this.recordId}).then(
            result => {
                this.quoteData = result.data;
                this.pdfTitle = result.pdfTitle;
                this.fileName = result.pdfTitle;
            }
        )
    }
    renderedCallback() {
        /* loadScript(this, AdobeScriptSrc).then(() => {
            console.log('loadScript run->adobe viewer.js from script tag');
        }).catch(err => {
            console.log(err);
        }); */
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
        let dateToday = new Date();
        console.log('Time: at Submit clicked->' + dateToday.toISOString());
        
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
            console.log('Apex Submit clicked');
            console.log('templateId->'+this.value);
            console.log('quoteData->' + this.quoteData);
            console.log('pdfName->'+this.pdfTitle);

            submitTemplate({ quoteMap: this.quoteData, templateId: this.value, pdfName: this.pdfTitle }).then(
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
                            console.log('Time: before Sleep->'+dateToday.toISOString());
                           /*  this.timerId = setTimeout(() => {                       
                                this.retriveFileFromRepoId();
                            }, 3000); */

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
            )}
        
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
                   //Enable the 'Get File' button after 10 sec
                   console.log('File Retrieval still in-progress for repoId:'+this.fileRepo);
                   let timerGetFileButton = setTimeout(() => {                       
                       this.displayGetFileButton();
                   }, 10000);
                }
            }
        ).catch(err => {
            console.log(err);
        });
    }

    displayPDF(result) {
        //const ADOBE_KEY = '80a7233f94134d00b16e08dab3a774f4'; 
        //let adobeDCView = null;
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
        let dateToday = new Date();
        console.log('Time: after Sleep->'+dateToday.toISOString());
        RetrieveFile({ repoId: this.fileRepo, endPoint, authToken}).then(
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
                    //Enable the 'Get File' button after 10 sec
                    console.log('File Retrieval still in-progress');
                    let timerGetFileButton = setTimeout(() => {                       
                        this.displayGetFileButton();
                    }, 10000);
                }
            }
        ).catch(err => {
            console.log(err);
        });
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
                objectApiName:'SBQQ__Quote__c',
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