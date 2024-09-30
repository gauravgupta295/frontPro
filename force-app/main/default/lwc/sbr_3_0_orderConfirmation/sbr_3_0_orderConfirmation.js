import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Sbr_3_0_orderConfirmation extends NavigationMixin(LightningElement)  {

    @api
    isConfirmed = false;
    @api
    message = '';
    @api
    heading = '';
    @track mobileMainDiv = '';

    connectedCallback() {
        if(FORM_FACTOR === 'Small'){
            this.mobileMainDiv = 'mobileMainDiv';
        }
    }

    handleConfirm(event) {
        this.isConfirmed = true;
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
    handleCancel(event) {
        this.isConfirmed = false;
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}