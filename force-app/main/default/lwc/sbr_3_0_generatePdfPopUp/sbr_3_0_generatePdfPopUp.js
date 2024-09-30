import { LightningElement,track } from 'lwc';
import FORM_FACTOR from "@salesforce/client/formFactor";

const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_generatePdfPopUp extends LightningElement {
    @track isModalOpen = false;
    


    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }

    handleCloseModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }

    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        this.isModalOpen = false;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
}