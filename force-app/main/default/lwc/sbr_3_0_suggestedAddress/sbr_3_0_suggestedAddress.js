import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class Sbr_3_0_suggestedAddress extends LightningElement {

    @api street;
    @api city;
    @api state;
    @api country;
    @api zip;
    @api lat;
    @api lng;

    @api streetSuggested;
    @api citySuggested;
    @api stateSuggested;
    @api countrySuggested;
    @api zipSuggested;
    @api latSuggested;
    @api lngSuggested;

    @api useSuggestedAddress = false;
    
    connectedCallback(){
        this.useSuggestedAddress = true;
        if (!this.latSuggested && !this.lngSuggested) {
            this.useSuggestedAddress = false;
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    suggestedSelected(){
        this.useSuggestedAddress = true;
    }

    defaultSelected(){
        this.useSuggestedAddress = false;
    }
}