import { LightningElement } from 'lwc';
export default class SBR_3_0_CancelBackOrderQtyOrderModal extends LightningElement {
    
    isShowModal = true

    hideModalBox() {
        this.isShowModal = false
        const selectedEvent = new CustomEvent("closebackorder", {
            detail: false
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    handleYesClick() {
        this.isShowModal = false
        const selectedEvent = new CustomEvent("yesbackorder", {
            detail: false
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

}