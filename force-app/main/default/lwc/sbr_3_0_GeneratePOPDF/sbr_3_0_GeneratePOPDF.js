import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import RETRIEVE_WAIT_TIME from '@salesforce/label/c.SBR_3_0_POPDFAdobeRetrieveWaitingTime';
import GENERATE_MESSAGE from '@salesforce/label/c.SBR_3_0_POPDFGenerateMessage';
import EMAIL_MESSAGE from '@salesforce/label/c.SBR_3_0_POPDFEmailMessage';

import generatePDF from '@salesforce/apex/SBR_3_0_GeneratePOPDFController.generatePDF';
import retrievePDF from '@salesforce/apex/SBR_3_0_GeneratePOPDFController.retrievePDF';

export default class Sbr_3_0_GeneratePOPDF extends LightningElement {

    @api recordId;
    @api downloadFile;
    @api sendEmail = false;

    connectedCallback() {
        this.showToast('INFO', this.message, 'info');
        this.genPDF();
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
                this.showToast('ERROR', res.errorMessage.toString(), 'error');
                this.closePopup();
            }
        })
        .catch(error => {
            console.log('Error ==>> ', error);
            this.showToast('ERROR', error.toString(), 'error');
            this.closePopup();
        })
    }

    retPDF(repoId, accToken, endpoint){
        let data = {
            'repoId'        : repoId,
            'endPoint'      : endpoint,
            'authToken'     : accToken,
            'purchaseOrderId'   : this.recordId,
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
                this.showToast('ERROR', res.errorMessage.toString(), 'error');
                this.closePopup();
            }
        })
        .catch(error => {
            console.log('Error ==>> ', error);
            this.showToast('ERROR', error.toString(), 'error');
            this.closePopup();
        })
    }


    downloadORSendFile(res){
        this.showToast('SUCCESS', (this.sendEmail ? 'Email has been sent successfully.' : ''), 'success');
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

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title   : title,
            message : message,
            variant : variant,
        }));
    }
}