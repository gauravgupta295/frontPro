import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';
import overrideVerificationStatus from '@salesforce/apex/PPA_ExportToERPController.overrideVerificationStatus';

export default class PPA_ExportToERPModalLWC extends LightningModal {
    @api recordId;
    comments;

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleConfirm() {
        // Perform the required action here, such as calling the Apex method.
        // For now, we'll just log a message and notify the caller component.
        console.log('Performing action with comments: ' + this.comments);
       
        // Call the Apex method to override verification status for selected Price Lists
        overrideVerificationStatus({ priceListId: this.recordId, overrideReason: this.comments })
        .then(result => {            
            this.close('OK');
        })
        .catch(error => {
            console.error('Error overriding Verification Status:', error);
        });
    }

    handleCancel() {
        // Notify the caller component that the action was canceled.
        this.close('CANCEL');
    }
}