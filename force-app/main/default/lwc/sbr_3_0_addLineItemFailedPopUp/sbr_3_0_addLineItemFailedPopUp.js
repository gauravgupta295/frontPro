import { LightningElement,track,api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_addLineItemFailedPopUp extends LightningElement {

    @track showPopUp = false;
    isModalOpen = true;
    openCreateModal=true;
    openCreateModal = false;
    showLineItemFields = true;
    @api recordId;
    isAddLineItemFailedPopupVisibile = true;

handleclose(){
    this.sendEventToParent();
}

    handlehandleFailedPopUp() {
        this.showPopUp = true;
    }


    // openModal() {
    //     // to open modal set isModalOpen tarck value as true
    //     this.isModalOpen = true;
    // }

    sendEventToParent(){
        console.log('Insidepopup')
        const failedModalClosedEvent = new CustomEvent("handlemodalclose", {detail: false});
        this.dispatchEvent(failedModalClosedEvent);
    }
    closeModal(event) {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.sendEventToParent();

    }

    handleCloseMobile()
    {
        this.isAddLineItemFailedPopupVisibile=false;
        this.sendEventToParent();
    }

    handleCreateModal(){
        this.openCreateModal = false;
    }
    handleCreatePOButton(event) {
        this.showLineItemFields = false;
        this.openCreateModal=true;
        this.isModalOpen = false;
        this.addLineItemfailedModal=false;
        console.log('openCreateModal--',openCreateModal);
        console.log('recordId--',this.recordId);  
        console.log('this.showLineItemFields--',this.showLineItemFields);
        const failedModalClosedEvent = new CustomEvent("handleaddLineItemClose", {detail: false});
        this.dispatchEvent(failedModalClosedEvent);
        
    }
    handlSavePo(){
        const handleSavePoReload = new CustomEvent("handlesaveporeload", {detail: false});
        this.dispatchEvent(handleSavePoReload);
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

}