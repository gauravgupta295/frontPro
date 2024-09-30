/* Importing necessary modules and dependencies */
import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchContacts from "@salesforce/apex/SBR_3_0_MakeADepositController.getContact";
import getContactEmail from '@salesforce/apex/SBR_3_0_MakeADepositController.getContactEmail'
import sendEmailWithAttachment from '@salesforce/apex/SBR_3_0_MakeADepositController.sendEmailWithAttachment';
import getRelatedFilesByRecordId from '@salesforce/apex/SBR_3_0_filePreviewAndDownloadController.getRelatedFilesByRecordId'
/* Import other labels as needed */
import SelectMethod from '@salesforce/label/c.SBR_3_0_Select_Method';
import GeneratePdf from '@salesforce/label/c.SBR_3_0_Generate_PDF';
import EmailCheck from '@salesforce/label/c.SBR_3_0_EmailCheck';
import Print from '@salesforce/label/c.SBR_3_0_Print';
import EmailMessage from '@salesforce/label/c.SBR_3_0_Email_Message';
import PrintMessage from '@salesforce/label/c.SBR_3_0_Print_Message';
import AuthorizedContact from '@salesforce/label/c.SBR_3_0_AuthorizedContact';
import AuthContact from '@salesforce/label/c.SBR_3_0_AuthContact';
import ErrorForScreen from '@salesforce/label/c.SBR_3_0_ErrorForScreen';
import Email from '@salesforce/label/c.sbr_3_0_emailOnly';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';

import DefaultTemplate from "./sbr_3_0_generatePdf.html";
import mobileTemplate from "./sbr_3_0_generatePdfMobileTemplate.html";

/* Initialize class */
export default class Sbr_3_0_generatePdf extends LightningElement {

    /* Defining labels */
    label = {
        SelectMethod,
        GeneratePdf,
        EmailMessage,
        Email,
        Print,
        AuthorizedContact,
        ErrorForScreen,
        AuthContact,
        PrintMessage,
        EmailCheck
    };
    @wire(MessageContext)
    messageContext;
    /*Start:This method added by sreekar for handling dynamic pdf urls for both mobile and desktop*/
    @wire(getRelatedFilesByRecordId, { recordId: '$orderrecId' })
    wiredResult({ data, error }) {
        if (data) {
            if (window.matchMedia("(max-width: 480px)").matches) {
                this.filesList = Object.keys(data).map(item => ({
                    "label": data[item],
                    "value": item,
                    "url": `salesforce1://sObject/${item}/download`
                }))
                if (this.filesList.length > 0) {
                    console.log('file url is' + this.filesList[0].url)
                    this.fileUrl = this.filesList[0].url
                }
            }
            else {
                this.filesList = Object.keys(data).map(item => ({
                    "label": data[item],
                    "title": data[item].split('#')[1],
                    "value": item,
                    "url": `/sfc/servlet.shepherd/document/download/${item}`,
                    "pdfurl": `/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${data[item].split('#')[0]}`
                }))
                if (this.filesList.length > 0) {
                    console.log('file url is' + this.filesList[0].url)
                    this.fileUrl = this.filesList[0].url
                    this.pdfUrl = this.filesList[0].pdfurl
                    this.pdfName = this.filesList[0].title
                }
            }

        }
        if (error) {
            console.log(error)
        }
    }
    /*End:This method added by sreekar for handling dynamic pdf urls for both mobile and desktop*/


    /* Define other tracked properties and APIs */
    limitValue = 10;
    isValid = false;
    @track initialContact;
    @track initialEmail;
    @track initialBody;
    @track attachmentName;
    @track attachmentContent;
    @api selectedRecordName;
    @track wiredContacts;
    @api recid;
    @track isChecked = false;
    @track isCheckedPrint = false;
    @track isCheckedEmail = true;
    @track showError = false;
    @track isEmail = true;
    @track pdfIframe;
    @track pdfPrint = 'https://sunbeltrentals--ft2.sandbox.my.salesforce.com/sfc/p/7X0000008sxC/a/7X0000001ADf/LuENOlbc09E4mnVXR8ymaBcy5yR1_dthYRK2R1v9.OQ';
    @api pdfName;
    @api pdfUrl;
    @track fileUrl
    isMobile = false;
    /**
     * Handles changes in the email input field.
     * @param {Event} event - The event object containing the email value.
     */
    handleEmailChange(event) {
        this.initialEmail = event.detail.value;
        //this.checkInputValidity();
    }

    /**
     * Handles changes in the print checkbox.
     * @param {Event} event - The event object containing the checkbox value.
     */

    connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;  /*added by Sreekar*/
        this.orderrecId = this.recid
        console.log('connected call back recid' + this.recid)
    }

    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    handlePrintCheckboxChange(event) {
        this.isCheckedPrint = event.target.checked;
        if (this.isCheckedPrint) {
            this.showError = false;
        }
    }

    /**
    * Handles changes in the body textarea.
    * @param {Event} event - The event object containing the textarea value.
    */
    handleBodyChange(event) {
        // Retrieve the value of the text area
        const textAreaValue = event.target.value;
        this.initialBody = textAreaValue;
    }

    /**
     * Fetches contacts from Salesforce using an Apex method.
     */
    @wire(fetchContacts, { orderId: '$orderrecId' })
    wiredContacts({ error, data }) {
        if (data) {
            // Assign the returned contacts to the contacts property
            const [firstContact] = data;
            if (firstContact.Id != null && firstContact.Id != undefined) { this.initialContact = firstContact.Id; }
            /*added by Sreekar*/
            if (firstContact.Email != null && firstContact.Email != undefined) { this.initialEmail = firstContact.Email; }
        } else if (error) {
            // Handle any errors
            console.error('Error fetching contacts:', error);
        }
    }

    /**
     * Sends an email with attachment using an Apex method.
     */
    sendEmail() {
        sendEmailWithAttachment({
            toAddress: this.initialEmail,
            subject: this.initialBody,
            body: this.initialBody,
            attachmentName: this.pdfName,
            attachmentBody: this.pdfUrl
        })
            //updated by sreekar
            .then((result) => {
                // Email sent successfully
                if (result == 'Success') {
                    const toastEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'PDF has been sent',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.closeModal();
                }

            })
            .catch(error => {
                // Error occurred while sending email
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error sending email: ',// error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(toastEvent);
                this.closeModal();
            });
    }

    /**
     * Checks the validity of the input fields.
     */
    checkInputValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("emailid")) {
                    let emailcmp = this.template.querySelector(".emailClass");
                    let regExp = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                    if (!(regExp.test(this.initialEmail)) || (this.initialEmail == null) || (this.initialEmail == "")) {
                        this.isValid = false;
                        emailcmp.setCustomValidity("Enter Valid Email");
                    } else {
                        this.isValid = true;
                        emailcmp.setCustomValidity("");
                    }
                    emailcmp.reportValidity();
                }
            }, true);
        // Check record validity
        const isRecordCorrect = [...this.template.querySelectorAll('lightning-record-picker')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("conid")) {
                    let recordcmp = this.template.querySelector(".conClass");
                    if ((this.initialContact == null) || (this.initialContact == "")) {
                        this.isValid = false;
                        recordcmp.setCustomValidity("Select contact to proceed");
                    } else {
                        this.isValid = true;
                        recordcmp.setCustomValidity("");
                    }
                    recordcmp.reportValidity();
                }
            }, true);
    }

    /**
     * Handles changes in the email checkbox.
     * @param {Event} event - The event object containing the checkbox value.
     */
    handleEmailCheckboxChange(event) {
        this.isCheckedEmail = event.target.checked;
        if (this.isCheckedEmail) {
            this.isEmail = true;
            this.showError = false;
        } else {
            this.isEmail = false;
        }
    }

    /**
     * Opens a new window to download the PDF.
     */
    downloadPDF() {
        // added by sreekar
        if (this.filesList.length > 0) {
            console.log('file url is' + this.filesList[0].url)
            this.fileUrl = this.filesList[0].url
        }
        // window.open(this.pdfUrl, '_blank');

    }

    /**
     * Closes the modal by dispatching a CloseActionScreenEvent.
     */
    closeModal() {
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
    }

    /**
   * Handles changes in the lightning-record-picker component.
   * @param {Event} event - The event object containing the selected record id.
   */
    handleChange(event) {
        const selectedRecordId = event.detail.recordId;
        if (selectedRecordId) {
            // Fetch the contact record based on the selected record id
            this.fetchContactEmail(selectedRecordId);
        }
    }

    /**
     * Fetches the email of the selected contact.
     * @param {String} contactId - The ID of the selected contact.
     */
    fetchContactEmail(contactId) {
        getContactEmail({ contactId: contactId })
            .then(result => {
                this.initialEmail = result.Email;
            })
            .catch(error => {
                console.error('Error fetching contact email:', error);
            });
    }

    /**
    * Handles the submission of the form.
    */
    handleSubmit() {
        //  this.checkInputValidity();      
        //  if(this.isValid){    
        if (this.isCheckedPrint || this.isCheckedEmail) {
            if (this.isCheckedPrint && this.isCheckedEmail) {
                this.isChecked = true;
                this.showError = false;
                if (this.initialBody == null || this.initialBody == undefined || this.initialBody == "") {
                    this.initialBody = 'Please find Attached PDF for Deposits';
                }
                this.sendEmail();
                window.print();
            } else if (this.isCheckedPrint) {
                this.isChecked = true;
                this.showError = false;
                // const pdfWindow= window.open(this.pdfUrl, '_blank');
                Window.print();
                this.closeModal();
            } else if (this.isCheckedEmail) {
                this.isChecked = true;
                this.showError = false;
                if (this.initialBody == null || this.initialBody == undefined || this.initialBody == "") {
                    this.initialBody = 'Please find Attached PDF for Deposits';
                }
                this.sendEmail();
            }
        }
        if (!this.isChecked) {
            this.showError = true;
        } else {
            this.showError = false;
            //const pdfWindow= window.open(this.pdfUrl, '_blank');              
            // this.closeModal();
        }
    }

    /**
    * Executes after the component's content has been rendered.
    * Adds custom styles to the DOM elements dynamically.
    */
    renderedCallback() {
        if (this.isLoaded) return;
        if (!this.isMobile) {
            const STYLE = document.createElement("style");
            STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
                max-width: 40rem;
                min-width: 40rem; 
                min-height: 40rem; 
            }`;
            this.template.querySelector('.generate-pdf-container').appendChild(STYLE);

            const hideExtraCloseIcon = document.createElement("style");
            hideExtraCloseIcon.innerText = `.slds-button_icon-bare{
                content-visibility :hidden;
                visibility: collapse;
            }`;
            this.template.querySelector('.generate-pdf-container').appendChild(hideExtraCloseIcon);

            const STYLE1 = document.createElement("style");
            STYLE1.innerText = `.slds-modal__close{
                content-visibility :visible;
            }`;
            this.template.querySelector('.slds-modal__header').appendChild(STYLE1);
        }
        this.isLoaded = true;
    }
}