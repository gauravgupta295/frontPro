import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import RETRIEVE_WAIT_TIME from '@salesforce/label/c.AdobeRetrieveFileWaitTime';
import GENERATE_MESSAGE from '@salesforce/label/c.WOInvoiceGenerateMessage';
import EMAIL_MESSAGE from '@salesforce/label/c.WOInvoiceEmailMessage';
import EMPTY_EMAIL_MESSAGE from '@salesforce/label/c.WOInvoiceEmailError';

import generatePDF from '@salesforce/apex/SBR_3_0_GenerateWOPDFController.generatePDF';
import retrievePDF from '@salesforce/apex/SBR_3_0_GenerateWOPDFController.retrievePDF';
import sendCustomNotification from '@salesforce/apex/SBR_3_0_CustomNotificationClass.sendCustomNotification';
import executeQuery from '@salesforce/apex/SBR_3_0_CustomQueryController.executeQuery';
//import { log } from '../utilsImageCapture/utilsImageCapture';

export default class Sbr_3_0_GenerateWOPDF extends LightningElement {

    @api recordId;
    @api downloadFile;
    @api sendEmail = false;
    @api customerEmail = false;
    @api emailValue;
  

    NotificationWrapper = {
        title : 'Download Complete',
        body : 'File has been downloaded successfully',
        customNotificationType : '',
        targetId:this.recordId
    }

        connectedCallback() {
        if(this.sendEmail && !this.customerEmail){
                this.showToast('ERROR', EMPTY_EMAIL_MESSAGE, 'error', 'dismissible');
                this.closePopup();
            } else {
            this.showToast('INFO', this.message, 'info', 'dismissible');
            this.genPDF();
        }
        }

    get message(){
        return this.sendEmail ? EMAIL_MESSAGE : GENERATE_MESSAGE;
    }

    genPDF() {
        generatePDF({
            recordId  : this.recordId,
            sendEmail : this.sendEmail
        })
        .then(result => {
            let res = JSON.parse(result);
            let status = res.status;
            if(status == 'In Progress'){
                setTimeout(() => {
                    this.retPDF(res.repoId, res.accToken, res.endpoint);
                }, RETRIEVE_WAIT_TIME);
            } else if(status == 'Complete'){
                this.downloadORSendFile(res);
            } else {
                this.showToast('ERROR', res.errorMessage.toString(), 'error', 'dismissible');
                this.closePopup();
            }
        })
        .catch(error => {
            console.log('Error ==>> ', error);
            this.showToast('ERROR', error.toString(), 'error', 'dismissible');
            this.closePopup();
        })
    }

    retPDF(repoId, accToken, endpoint){
        let data = {
            'repoId'        : repoId,
            'endPoint'      : endpoint,
            'authToken'     : accToken,
            'workOrderId'   : this.recordId,
            'executionFrom' : 'Aura',
            'sendEmail'     : this.sendEmail,
        }
        retrievePDF({
            data : JSON.stringify(data)
        })
        .then(result => {
            let res = JSON.parse(result);
            let status = res.status;
            if(status == 'Complete'){
                this.downloadORSendFile(res);
            } else if(status == 'In Progress'){
                setTimeout(() => {
                    this.retPDF(repoId, accToken, endpoint);
                }, RETRIEVE_WAIT_TIME);
            } else {
                this.showToast('ERROR', res.errorMessage.toString(), 'error', 'dismissible');
                this.closePopup();
            }
        })
        .catch(error => {
            console.log('Error ==>> ', error);
            this.showToast('ERROR', error.toString(), 'error', 'dismissible');
            this.closePopup();
        })
    }


    downloadORSendFile(res){
        this.showToast('SUCCESS', (this.sendEmail ? 'Email has been sent successfully.' : ''), 'success', 'sticky');
        this.sendCustomNotificationToUser();
        if(this.downloadFile){
            this.donwloadFile(res.fileBody, res.fileName);
        } else {
            this.closePopup();
        }
    }

    donwloadFile(fileBody, fileName){
        var a = document.createElement("a");
        a.setAttribute("download", fileName);
        a.setAttribute("href", `data:application/pdf;base64,${fileBody}`);
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        this.closePopup();
    }

    closePopup(){
        this.dispatchEvent(new CustomEvent("close", {}));
    }

    showToast(title, message, variant, mode) {
        this.dispatchEvent(new ShowToastEvent({
            title   : title,
            message : message,
            variant : variant,
            mode    : mode 
        }));
    }

    /**
     * @author | Shubham Tunkikar
     * @description | Will send Bell Icon Notification to the loggedin user.
     */
    sendCustomNotificationToUser()
    {
        var fieldsToQuery = 'SF_PS_RM_WO_Number__c';
        var objectAPIName = 'WorkOrder';
        var whereConditions = 'WHERE Id = \'' + this.recordId + '\'';
        // Query Related WO information
        executeQuery({fieldsCSV: fieldsToQuery, objAPIName: objectAPIName, whereClause: whereConditions}).then((resp) =>{
            if(resp && Array.isArray(resp) && resp.length > 0)
            {
                let latestRecordData = resp[0];
                // Prepare Notification Data to be sent.
                this.NotificationWrapper.body = 'PDF File has been downloaded successfully for WO: '+ latestRecordData?.SF_PS_RM_WO_Number__c;
                this.NotificationWrapper.targetId = this.recordId;
                //Get Custom Notification Type Id
                executeQuery({fieldsCSV: 'DeveloperName', objAPIName: 'CustomNotificationType', whereClause: 'WHERE DeveloperName = \'PDF_Downloaded\''}).then((res) =>{
                    if(res && Array.isArray(res) && res.length > 0)
                    {
                        let latestNotificationType = res[0];
                        this.NotificationWrapper.customNotificationType = latestNotificationType.Id;
                        // Send Custom Notification To the loggedin User.
                        sendCustomNotification({strWrapp:JSON.stringify(this.NotificationWrapper)});
                    }
                })
            }
        }).catch((err)=>{
            console.log(JSON.stringify(err));
        })
    }
}