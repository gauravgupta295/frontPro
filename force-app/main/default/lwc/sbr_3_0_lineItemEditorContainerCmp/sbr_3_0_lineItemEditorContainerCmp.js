import { LightningElement, track, api } from 'lwc';


export default class Sbr_3_0_lineItemEditorContainerCmp extends LightningElement {
    @track orderId;
    @track groupId;
    
    openModal(){
        this.orderId = this.template.querySelector("lightning-input[data-my-id=orderId]").value;
        this.groupId = this.template.querySelector("lightning-input[data-my-id=groupId]").value;
        console.log('this is my order id: ', this.orderId);
        console.log('this is my group id: ', this.groupId);
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }

    onSave = (event) => {
        event.stopPropagation();
        this.template.querySelector("c-sbr_3_0_line-item-editor-cmp").saveData();
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
    }
}