import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class LWCModal extends LightningModal {
    @api isModalOpen = false;
    @api pleaseprovideanycomments;
    additionalComments = '';
    showErrorMessage = false;
    handleSave() {
        this.additionalComments = this.template.querySelector('lightning-textarea').value;

        const event = new CustomEvent('feedbacksubmission', {
            detail: { additionalComments: this.additionalComments }
        });
        this.dispatchEvent(event);
    }

    handleClose() {
        const closeModalEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeModalEvent);
    }
    handleInputChange(event) {
        this.additionalComments = event.target.value;
        const inputLength = this.additionalComments.length;
        if (inputLength == 255) {
            this.warningMessage = 'You have exceeded the character limit of 255.';
            this.showErrorMessage = true;
        } else {
            this.warningMessage = '';
            this.showErrorMessage = false;
        }
    }
}