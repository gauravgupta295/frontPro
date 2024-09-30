import { LightningElement, api, track } from 'lwc';
export default class Sbr_3_0_confirmPOLineItemsCancelModal extends LightningElement {

@track isShowModal = true;

    

connectedCallback() {
            console.log('in connected callback ' +this.isShowModal);

}

    sendModalStateToParent(event){
        const selectedEvent = new CustomEvent("progressvaluechange", {
      detail: false
    });

    // Dispatches the event.
        this.dispatchEvent(selectedEvent);


        }

    hideModalBox() {  
        console.log('in child js 1  '+this.isShowModal);
        this.isShowModal = false;
        console.log('in child js 2  '+this.isShowModal);
        this.sendModalStateToParent();

    }

    handleYesClick(event){
        console.log('in child cmp');
       const selectedEvent = new CustomEvent("deletelineitem", {
      detail: false
    });

    // Dispatches the event.
        this.dispatchEvent(selectedEvent);


    }

}