import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class Sbr_3_0_ToastMessage extends LightningElement {

    @api errorMessage;

    connectedCallback() {
        this.showToast();
        setTimeout(() => {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
            console.log("navigate finish");
        }, 10);
    }

    showToast() {
        const event = new ShowToastEvent({
            title: '',
            message: this.errorMessage,
            variant: 'error',
            mode: 'sticky',
        });
        this.dispatchEvent(event);
    }
}