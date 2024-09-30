import { LightningElement, track, wire, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_editPOInternalComments extends LightningElement {

    @api rowId;
    @api comments;
    @track isShowModal = true;
    comment = '';
    isAddCommentsPopupVisibile=true;
    disableSaveButton=true;

    connectedCallback() {
        this.comment = this.comments;
    }

    handleComment(event) {
        this.comment = event.target.value;
        if(this.comment)
        this.disableSaveButton=false;
        else
        this.disableSaveButton=true;
    }

    hideModalClose() {
        this.isShowModal = false;
        this.sendModalStateToParent();
    }

    sendModalStateToParent(event) {
        const selectedEvent = new CustomEvent("progressvaluechange", {
            detail: false
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    handleSave(event) {
        const selectedEvent = new CustomEvent("addcomments", {
            detail: { comment: this.comment, rowId: this.rowId }
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
        //return true;
    }

    handleCancelMobile(){
        this.isAddCommentsPopupVisibile=false;
        this.sendEventToParent();
    }

    sendEventToParent(){
        console.log('Insidepopup')
        const failedModalClosedEvent = new CustomEvent("handlemodalclose", {detail: false});
        this.dispatchEvent(failedModalClosedEvent);
    }

}