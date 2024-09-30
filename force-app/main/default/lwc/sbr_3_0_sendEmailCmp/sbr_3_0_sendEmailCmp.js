import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import WO_WO_NUMBER_FIELD from '@salesforce/schema/WorkOrder.WorkOrderNumber';
import WO_RECORD_TYPE_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Record_Type__c';
import WO_JOB_LOCATION_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Job_Location__c';
import WO_PO_NUMBER_FIELD from '@salesforce/schema/WorkOrder.SF_PS_PONumber__c';
import sendEmail from '@salesforce/apex/SBR_3_0_SendEmailCmpController.sendEmail';

const EMAIL_REGEX = /^(([^<>()[\]\\.,;:\s@']+(\.[^<>()[\]\\.,;:\s@']+)*)|('.+'))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

export default class Sbr_3_0_sendEmailCmp extends LightningElement {
    @api recordId;
    @track files = [];
    toAddress = [];
    showSpinner = false;
    filesData = [];
    workOrderDetails;

    get acceptedFormats() {
        return ['.pdf'];
    }

    @wire(getRecord, { recordId: '$recordId', fields: [WO_WO_NUMBER_FIELD, WO_RECORD_TYPE_FIELD, WO_JOB_LOCATION_FIELD, WO_PO_NUMBER_FIELD]}) 
    workOrderDetails({error, data}) {
        if (data) {
            this.workOrderDetails = {
                'workOrderNumber' : data.fields.WorkOrderNumber.value,
                'recordTypeC' : data.fields.SF_PS_Record_Type__c.value,
                'jobLocationC' : data.fields.SF_PS_Job_Location__c.value,
                'poNumberC' : data.fields.SF_PS_PONumber__c.value
            }
        }
    }

    handleUploadFinished(event) {
        let uploadedAttachment = event.target.files;
        this.files = [...this.files, ...uploadedAttachment];
        let fileName = uploadedAttachment[0].name;
        
        let reader = new FileReader();
        reader.onload = () => {
            let fileContent = reader.result.split(',')[1];
            let attachment = {
                'fileName': fileName.replace(/\s+/g, ''), // removing whitespaces from the fileName
                'fileContent': fileContent,
                'disposition': 0,
                'mimeType': 'application/pdf'
            };
            this.filesData.push(attachment);
        }
        reader.readAsDataURL(uploadedAttachment[0]);
    }

    handleRemove(event) {
        let index = event.target.dataset.index;
        this.files.splice(index, 1);
        this.filesData.splice(index, 1);
    }

    handleToAddressChange(event) {
        this.toAddress = event.detail.selectedValues;
    }

    validateEmails(emailAddressList) {
        let areEmailsValid;
        if(emailAddressList.length > 1) {
            areEmailsValid = emailAddressList.reduce((accumulator, next) => {
                let isValid = this.emailValidityCheck(next);
                return accumulator && isValid;
            });
        }
        else if(emailAddressList.length > 0) {
            areEmailsValid = this.emailValidityCheck(emailAddressList[0]);
        }
        return areEmailsValid;
    }

    emailValidityCheck(email) {
        return EMAIL_REGEX.test(email.toLowerCase());
    }

    handleSendEmail() {
        this.showSpinner = true;

        if (this.toAddress.length == 0) {
            this.showToast('Error', 'Please add a Recipient', 'error');
            this.showSpinner = false;
        } else if (!this.validateEmails(this.toAddress)) {
            this.showToast('Error', 'Invalid Email Address', 'error');
            this.showSpinner = false;
        } else {
            let emailDetails = {
                'toAddresses': this.toAddress,
                'recordId': this.recordId,
                'workOrderDetails' : this.workOrderDetails,
                'attachmentData': this.filesData
            };

            sendEmail({ emailDetails: JSON.stringify(emailDetails)})
            .then(result => {
                this.reset();
                if(result == 'success') {
                    this.showToast('Success', 'Email sent successfully', 'success');
                    this.showSpinner = false;
                } else {
                    this.showToast('Error', 'Email could not be sent. Please try again', 'error');
                    this.showSpinner = false;
                }
            })
            .catch((error) => {
                this.reset();
                this.showSpinner = false;
                this.showToast('Error', 'Email could not be sent', 'error');
            });
        }
    }

    reset(){
        this.toAddress = [];
        this.files = [];
        this.filesData = [];
        this.template.querySelectorAll('c-sbr_3_0_send-email-input-cmp').forEach((input) => input.reset());
    }

    showToast(title, msg, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}