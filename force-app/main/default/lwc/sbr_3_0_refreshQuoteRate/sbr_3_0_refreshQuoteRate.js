import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import refreshQuoteRates from '@salesforce/apex/SBR_3_0_API_Rates.refreshQuoteRates';

export default class Sbr_3_0_refreshQuoteRate extends LightningElement {
    _recordId;

    @api set recordId(value) {
        this._recordId = value;
    }
    
    get recordId() {
        return this._recordId;
    }

    @api invoke(){
        let initialEvent = new ShowToastEvent({
            title: 'Refresh Quote Rate',
            message: 'Updating pricing based on current selections...'
        });
        this.dispatchEvent(initialEvent);
        refreshQuoteRates({quoteId: this._recordId})
        .then(result => {
            setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();");
           }, 1000); 
            console.log('Result: ' + this._recordId);
            console.log(result);
            let successEvent = new ShowToastEvent({
                title: 'Refresh Quote Rate',
                variant: 'success',
                message: 'Quote Rate Refreshed Successfully'
            });
            this.dispatchEvent(successEvent);
        })
        .catch(error =>{
            console.log('Error: ');
            console.log(error);
            let failedEvent = new ShowToastEvent({
                title: 'Refresh Quote Rate',
                variant: 'error',
                mode: 'sticky',
                message: 'Failed to retrieve pricing. Please try again. If issues persist, notify your System Administrator'
            });
            this.dispatchEvent(failedEvent);
        })
        
    }
}