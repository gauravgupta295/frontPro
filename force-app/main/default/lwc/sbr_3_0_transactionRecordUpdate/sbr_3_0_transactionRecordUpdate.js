import { LightningElement, api, track } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sbr_3_0_transactionRecordUpdate extends LightningElement {

    // Define the channel name for Change Data Capture events
    channelName = '/data/Transaction__ChangeEvent';
    @api recordId;
    subscription = null;

    // Invoked when the component is connected to the DOM
    connectedCallback() {
    this.subscribeToTransactionDataCapture();
    }

    // Subscribe to the Change Data Capture event channel
    subscribeToTransactionDataCapture() {
        if (this.subscription) {
            return;
        }
        subscribe(this.channelName, -1, this.handleTransactionChangeEvent).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            console.log('Subscription Response ' + JSON.stringify(this.subscription, null, 2));
        }).catch(error => {
            console.error('Error subscribing to CDC event: ', JSON.stringify(error));
        });
    }

    // Handle the Change Data Capture event
    handleTransactionChangeEvent = (response) => {
        const eventMessage = response.data.payload;
        const changeEventHeader = eventMessage.ChangeEventHeader;

        console.log('Event Message:', JSON.stringify(eventMessage, null, 2));


        const errorCode = eventMessage.Error_Code__c || '';
        const transactionSuceeded = eventMessage.Transaction_Succeeded__c || false; 
        const transactionId = changeEventHeader.recordIds[0];

        const changedFields = changeEventHeader.changedFields || [];

        if (transactionId === this.recordId) {
            if (changedFields.includes('Error_Code__c') || changedFields.includes('Transaction_Succeeded__c')) {
                if ((errorCode || !transactionSuceeded)) {
                    this.displayError('An error occurred while processing the transaction.');
                } else {
                }
            }
        }
    }

    // Display an error toast message
    displayError(errorMessage) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
        });
        this.dispatchEvent(event);
    }

    // Invoked when the component is disconnected from the DOM
    disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('unsubscribe() response: ', JSON.stringify(response));
            });
        }
    }

}