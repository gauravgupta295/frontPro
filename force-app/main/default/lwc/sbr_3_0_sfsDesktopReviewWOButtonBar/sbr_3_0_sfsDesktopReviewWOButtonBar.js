import { LightningElement, api } from 'lwc';
import {FlowNavigationBackEvent,FlowNavigationNextEvent} from "lightning/flowSupport";


export default class SBR_3_0_Review_WO_Button_Bar extends LightningElement {

    @api recordId;
    @api nextButtonLabel;

    connectedCallback()
    {
        if(!this.nextButtonLabel)
        {
            this.nextButtonLabel = 'Close Work Order';
        }
    }
    handleNext(){
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
    
    handleCancel(event){
        window.location.href=`${window.location.origin}/lightning/r/WorkOrder/${this.recordId}/view`;
     }
}