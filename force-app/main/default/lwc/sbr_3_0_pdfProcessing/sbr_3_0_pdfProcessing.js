/* Importing necessary modules and dependencies */
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

/* Import other labels as needed */
import GeneratingPDF from '@salesforce/label/c.SBR_3_0_GeneratingPDF';
import PDFMessage from '@salesforce/label/c.SBR_3_0_GeneratingPDFMessage';

import DefaultTemplate from "./sbr_3_0_pdfProcessing.html";
import mobileTemplate from "./sbr_3_0_pdfProcessingMobileTemplate.html";
import loadOrderFields from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.loadOrderFields';
import buildRequest from '@salesforce/apex/SBR_3_0_ResContrctOrderPdfController.buildRequest';
import FORM_FACTOR from '@salesforce/client/formFactor';
import SaveFile from '@salesforce/apex/SBR_3_0_quoteSelectorController.saveFile';

/* Initialize class */
export default class Sbr_3_0_pdfProcessing extends NavigationMixin (LightningElement) {

    /* Defining labels */
    label = {
        GeneratingPDF,
        PDFMessage,
    };

    /* Define other tracked properties and APIs */
    @track showButtons = true;
    @track success = false;
    @track processing = true;
    @track failure = false;
    @api recid;
    isMobile = false;
    isLoaded = false;
    isValidOrderRecord = false;
    fileSaved = false;
    fileData;
    @api pdfTitle;
    rmId;
    companyId;
    seqNum;

    /**
    * Handles the success scenario when a click event is triggered.
    * Updates the processing and success states accordingly.
    */
    @api handleOnclickSuccess() {
        this.processing = false;
        this.success = true;
    }

    /**
    * Executes when the component is connected to the DOM.
    * If there's an error, sets a timeout to handle error scenario.
    * Otherwise, sets a timeout to handle success scenario.
    */
    connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        console.log("inside pdf processing");

        loadOrderFields({ recordId: this.recid })
        .then((result) => {
            this.pdfTitle = result.orderNumber;
            if (result.isValidOrderRecord === "N") {
            this.dispatchEvent(
                new ShowToastEvent({
                title: "Error",
                message: `Please submit the Reservation to generate the PDF.`,
                variant: "error"
                })
            );
            } else if (result.contractNumber != null) {
            this.rmId = result.contractNumber;
            this.companyId = result.companyId;
            this.seqNum = result.seqNum;
            console.log('rmid',this.rmId);
            if(this.rmId && this.companyId && this.seqNum){
                this.handleRetrievePdf();
            } 
            }
        })
        .catch((err) => {
            console.log("err" + JSON.stringify(err));
            this.dispatchEvent(
            new ShowToastEvent({
                title: "Error",
                message: `Loading Order fields failed.`,
                variant: "error"
            })
            );
        });
    }

    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }


    handleRetrievePdf() {
        buildRequest({
          rentanlManId: this.rmId,
          companyCode: this.companyId,
          seqNum: this.seqNum
        })
          .then((result) => {
            if (result.status === "InComplete") {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: `System failed to retrieve the PDF. Please try again, contact Support if the problem persists.`,
                  variant: "error"
                })
              );
            } else {
              const responseFile = new Blob([result.body], {
                type: "application/pdf"
              });
              let responseFileURL = URL.createObjectURL(responseFile);
    
              let fileReader = new FileReader();
              let blobArrayBuffer;
              fileReader.readAsArrayBuffer(responseFile);
    
              fileReader.onloadend = function () {
                blobArrayBuffer = fileReader.result;
              };
    
              let arrayBuffer = this.base64ToArrayBuffer(result.base64Body);
              let arrayBufferBlob = new Blob([arrayBuffer], {
                type: "application/pdf"
              });
    
              let arrayBufferBlobURL = URL.createObjectURL(arrayBufferBlob);
              if (FORM_FACTOR !== "Small") {
                const a = document.createElement("a");
                a.href = arrayBufferBlobURL;
                a.target = "_blank";
                a.download = this.pdfTitle + ".pdf";
              }
              this.fileData = {
                filename: this.pdfTitle,
                base64: result.base64Body,
                recordId: this.recid
              };
              this.savePDFToSF();
              this.handleOnclickSuccess();
            }
          })
          .catch((err) => {
            console.log(err);
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error",
                message: `System failed to retrieve the PDF. Please try again, contact Support if the problem persists.`,
                variant: "error"
              })
            );
          });
      }
    
      base64ToArrayBuffer(base64) {
        var bin = window.atob(base64);
        var len = bin.length;
        var uInt8Array = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
          uInt8Array[i] = bin.charCodeAt(i);
        }
        return uInt8Array.buffer;
      }
    
        savePDFToSF() {
            const { base64, filename, recordId } = this.fileData;
            SaveFile({ base64, filename, recordId })
            .then((result) => {
                this.fileSaved = result.status == "SUCCESS" ? true : false;
                this.fileData = null;
                if (this.fileSaved) {
                //Navigate to Files in Mobile app
                if (FORM_FACTOR === "Small") {
                    this.navigateToFilesHome(recordId);
                }
                }
            })
            .catch((err) => {
                console.log(err);
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

    /**
    * Executes after the component's content has been rendered.
    * Adds custom styles to the DOM elements dynamically.
    */
    renderedCallback() {
        // If already loaded, return
        if (this.isLoaded) return;
        if (!this.isMobile) {
            // Create and style modal close button
            const hideCloseIcon = document.createElement("style");
            hideCloseIcon.innerText = `.slds-modal__close{
                content-visibility :hidden;
            }`;
            // Create and style modal container
            const STYLE = document.createElement("style");
            STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
                max-width: 35rem;
                min-width: 30rem;
            }`;
            // Append styles to the payment processing container
            this.template.querySelector('.payment-processing-container').appendChild(STYLE);
            this.template.querySelector('.payment-processing-container').appendChild(hideCloseIcon);
        }
        // Mark the component as loaded
        this.isLoaded = true;
    }
}