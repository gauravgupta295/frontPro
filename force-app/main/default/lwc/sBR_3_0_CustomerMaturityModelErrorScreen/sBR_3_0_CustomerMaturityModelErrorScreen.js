import { LightningElement,api } from 'lwc';

export default class SBR_3_0_CustomerMaturityModelErrorScreen extends LightningElement {
    @api isServerDown;
    @api errorMessage;
    @api errorMessageRec;
    @api isRecommendationTab;
    
    refreshPage() {
        const event = new CustomEvent('refresh');
        this.dispatchEvent(event);
    }
}