import { LightningElement, api } from 'lwc';
import updatePOStatus from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.updatePOStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Sbr_3_0_purchaseOrderReopenPO extends LightningElement {

    _recordId;
    @api set recordId(value) {
        this._recordId = value;
        this.reopenPO();
        }

    get recordId() {
        return this._recordId;
    }

    async reopenPO() {
        updatePOStatus({ recordId: this.recordId})
         .then((result)=>{
             this.data=result;
            this.dispatchEvent(
                    new ShowToastEvent({
                        message : 'PO opened Successfully',
                        title : 'Success',
                        variant : 'Success'
                })
            );
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.closeAction();
            this.dispatchEvent(new CustomEvent('close'));
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'Error while Reopening PO',
                    message : error.body.message ,
                    variant : 'error'
                })
            );
        })
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    
}