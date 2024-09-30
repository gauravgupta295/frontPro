import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Sbr_3_0_Close_Estimator_Unbilled_Popup extends LightningModal
{
    @api estimatorId;
    @api reasonCode;
    reasonValue;
    pickListValues =
    [
        {  "label": "C1 - Salesmen Customer Goodwill",  "value": "C1 - Salesmen Customer Goodwill" },
        {  "label": "C2 - Timing of Communication",  "value": "C2 - Timing of Communication" },
        {  "label": "C3 - Lack of Details to Provide",  "value": "C3 - Lack of Details to Provide" },
        {  "label": "C4 - National Account Agreement",  "value": "C4 - National Account Agreement" },
        {  "label": "C5 - Cleanup of Old Estimates",  "value": "C5 - Cleanup of Old Estimates" },
        {  "label": "C6 - Managers Discretion",  "value": "C6 - Managers Discretion" },
        {  "label": "C7 - Auto-Closed",  "value": "C7 - Auto-Closed" }
    ];

    connectedCallback() {
        this.reasonValue = this.getReasonValue();
    }

    getReasonValue()
    {
        for(let i =0; i < this.pickListValues.length; i++)
        {
            if(this.pickListValues[i].value === this.reasonCode)
            {
                return this.pickListValues[i].value;
            }
        }
        return null;
    }

    handleValueChange(event)
    {
        this.reasonValue = event.target.value;
    }

    handleSave()
    {
        this.reasonValue = this.template.querySelector('lightning-combobox').value;
        if(!this.reasonValue || this.reasonValue === '')
        {
            //Give a validation error for selecting a value
            return;
        }
        //Throw an event which will get captured from parent and save the record accordingly.
        let saveEvent = new CustomEvent('save_unbilled', { detail: {reasonValue: this.reasonValue} });
        this.dispatchEvent(saveEvent);
    }

    handleCancel()
    {
        let cancelEvent = new CustomEvent('cancel_unbilled');
        this.dispatchEvent(cancelEvent);
    }
}