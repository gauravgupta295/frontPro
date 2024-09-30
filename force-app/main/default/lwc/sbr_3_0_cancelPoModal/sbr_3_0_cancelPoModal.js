import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';

export default class Sbr_3_0_cancelPoModal extends LightningElement {
    @api recordId;

    handleYesClick() {
        console.log('Record id is ' + this.recordId);

        const fields = {};
        fields['Id'] = this.recordId;
        fields['Status__c'] = 'Cancelled';

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                console.log('Record updated successfully');
                this.closeAction();
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                console.error('Error updating record', error);
            });
    }

    handleNoClick() {
        this.closeAction();
        this.dispatchEvent(new CustomEvent('close'));
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}