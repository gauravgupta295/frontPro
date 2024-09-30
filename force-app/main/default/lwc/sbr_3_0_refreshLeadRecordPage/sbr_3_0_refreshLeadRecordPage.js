import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sbr_3_0_refreshLeadRecordPage extends LightningElement {
    channelName = '/event/SBR_3_0_Events__e';
    isSubscribeDisabled = false;
    isUnsubscribeDisabled = false;
    subscription = {};


    connectedCallback(){
        this.handleSubscribe()
    }
    handleSubscribe() {
        subscribe(this.channelName, -1, this.messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        })
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        })
    }

    messageCallback = (response) => {
        let eventSource = response.data.payload.Generated_From__c;
        console.log('Event generated from: ', JSON.stringify(eventSource));
        if (eventSource === 'Lead Conversion') {
            window.location.reload();
        }
        if (eventSource === 'Job Site Update') {
            const event = new ShowToastEvent({
                message: 'Job Site Updated Successfully!',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
            setTimeout(function() {window.location.reload()}, 5000);
        }
    }
}