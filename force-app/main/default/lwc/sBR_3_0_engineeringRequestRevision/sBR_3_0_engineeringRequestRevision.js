import { LightningElement, api, wire } from 'lwc';
import createEngReqRevision from "@salesforce/apex/SBR_3_0_EngineeringRequestRevision.cloneEngineeringRequest";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import revisionSuccess from '@salesforce/label/c.Revision_Success';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation'


export default class SBR_3_0_engineeringRequestRevision extends NavigationMixin(LightningElement) {
    progress = 0;
    isProgressing = false;
    isDisabled = true;
    @api recordId;
    @api message = '';
    error;
   
    connectedCallback() {
        //Check Validation to show error or call updateOrders()
        this.isProgressing = true;
        console.log('recId'+this.recordId);
        setTimeout(() => {
            console.log('recId'+this.recordId);
            this.createRevision();
        }, 5);
    }

    createRevision() {
        createEngReqRevision({engRequestId : this.recordId, originalRequestId : null}).
            then(response => {
                console.log('response1'+response);
              //  this.isProgressing = false;
                this.message = revisionSuccess;
                this.showToastMessage('', revisionSuccess, 'success', 'sticky');
                this.closeAction();

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: response,
                        objectApiName: 'Engineering_Request__c',
                        actionName: 'view'
                    },
                });
            }).catch(error => {
                console.log('Error:'+ error.body.message);
                this.isProgressing = false;
                this.message = error.body.message;
                console.log('this.message:'+ this.message);
               this.showToastMessage('', error.body.message, 'error', 'sticky');
               this.closeAction();

            })
    }
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToastMessage(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );

    }
}