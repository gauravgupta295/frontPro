import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import refreshQuoteRates from '@salesforce/apex/SBR_3_0_API_Rates.refreshQuoteRates';

export default class Sbr_3_0_QuoteRateRefresh extends LightningElement {
    @api recordId;

    @track isError = false;
    @track isSuccess = false;
    @track isCloseDisabled = true;
    @track isRetryDisabled = true;

    @track message;

    @track showSpinner = false;
    @track isMobile = false;

    connectedCallback(){
        console.log('Record Id: ' + this.recordId);
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        this.refreshRate();
    }

    refreshRate(){
        this.callValueChangeEvent();
        this.showSpinner = true;
        this.message = 'Updating pricing based on current selections...';
        this.isError = false;
        this.isSuccess = false;
        this.isCloseDisabled = true;
        this.isRetryDisabled = true;
        refreshQuoteRates({quoteId: this.recordId})
        .then(result => {
            console.log('Success: ');
            console.log(result);
            this.isSuccess = true;
            this.showSpinner = false;
            this.isCloseDisabled = false;
            this.isRetryDisabled = true;
            this.message = 'Quote Rate Refreshed Successfully';
            this.callValueChangeEvent();
        })
        .catch(error =>{
            console.log('Error: ');
            console.log(error);
            let errorMessage = 'Failed to retrieve pricing. Please try again. If issues persist, notify your System Administrator';
            if(error.body && error.body.message && error.body.message === 'Sales Reps can only access this function for records they own. Please reach out to your manager if you need to update this record.'){
                errorMessage = error.body.message;
            }
            this.isError = true;
            this.showSpinner = false;
            this.isCloseDisabled = false;
            this.isRetryDisabled = false;
            this.message = errorMessage;
            this.callValueChangeEvent();
        })
        
    }

    handleCloseClick(){
        //this.dispatchEvent(new CloseActionScreenEvent());
      //  eval("$A.get('e.force:refreshView').fire();");
      const closeQA = new CustomEvent('close');
      // Dispatches the event.
      this.dispatchEvent(closeQA);
    }

    @api
    handleRetryClick(){
        this.refreshRate();
    }

    callValueChangeEvent(){
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: {
                "isCloseDisabled": this.isCloseDisabled,
                "isRetryDisabled": this.isRetryDisabled
            }
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
    }
}