import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sbr_3_0_assetInquiryContainerCmp extends LightningElement {
    isMobile = false;
    tabsPanelHeight;
    
    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }
    renderedCallback(){
        if(!this.isMobile){
            this.tabsPanelHeight = this.template.querySelector('.tabs-container').offsetHeight - 64;
        }
    }
    showToast(evt) {
        const event = new ShowToastEvent({
            title: 'Error Message',
            message: 'Please contact your System Administrator. Error: ' + evt.detail,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}