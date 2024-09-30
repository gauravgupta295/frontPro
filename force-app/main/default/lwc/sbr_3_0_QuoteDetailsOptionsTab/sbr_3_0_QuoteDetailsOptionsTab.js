import { LightningElement, api, wire } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';

import EXTERNAL_NOTES from "@salesforce/schema/SBQQ__Quote__c.External_Notes__c";
import INTERNAL_NOTES from "@salesforce/schema/SBQQ__Quote__c.Internal_Notes__c";
import DELIVERY_INST from "@salesforce/schema/SBQQ__Quote__c.Delivery_Special_Instructions__c";

import FORM_FACTOR from "@salesforce/client/formFactor";

const SMALL_FORM_FACTOR = "Small"; 


export default class Sbr_3_0_QuoteDetailsOptionsTab extends LightningElement {
    @api recordId;
    @api objectApiName;

    isOpen = false;
    externalNotes;
    internalNotes;
    deliveryInst;



    @wire(getRecord, { recordId: '$recordId', fields: [EXTERNAL_NOTES, INTERNAL_NOTES, DELIVERY_INST] })
    wiredRecord({ error, data }) {
        if (data) {
            this.externalNotes = data.fields.External_Notes__c.value;
            this.internalNotes = data.fields.Internal_Notes__c.value;
            this.deliveryInst = data.fields.Delivery_Special_Instructions__c.value;
            this.toggleSection();
            console.log("DATA", data);


        } else if (error) {
            console.error('Error loading record', error);
        }

       
    }

    get isMobile() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    toggleSection() {
        this.isOpen = !this.isOpen;
    }
}