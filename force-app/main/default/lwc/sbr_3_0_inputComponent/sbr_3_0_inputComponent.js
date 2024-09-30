import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class Sbr_3_0_inputComponent extends LightningElement {
    @api fieldLabel;
    @api fieldValueText;
    @api fieldValueNumber;
    @api fieldValueBoolean;
    @api fieldType;
    @api numberFormatter;
    @api fieldLevelHelp;
    @api isDisabled;
    @api isRequired;
    @api calledFrom = 'LWC';

    get isCheckboxField(){
        return (this.fieldType && (this.fieldType == 'toggle' || this.fieldType == 'checkbox'));
    }

    get isNumberField(){
        return (this.fieldType && this.fieldType == 'number');
    }

    handleChange(event){
        // Added for Estimated Labor Hours input on Flow "SBR 3.0 DamageEstimator Screen on WO"
        if(this.fieldLabel && this.fieldLabel == 'Labor Hours'){
            this.fieldValueBoolean = true;
            this.dispatchFlowAttributeChangeEvent('fieldValueBoolean');
        }

        this[event.currentTarget.dataset.id] = event.target.value;
        if(this.calledFrom == 'Flow'){
            this.dispatchFlowAttributeChangeEvent(event.currentTarget.dataset.id);
        } else {
            this.dispatchValueChangeEvent({fieldName : this.fieldLabel, fieldValue : event.target.value});
        }
    }

    dispatchFlowAttributeChangeEvent(attributeName){
        this.dispatchEvent(new FlowAttributeChangeEvent(attributeName, this[attributeName]));
    }

    dispatchValueChangeEvent(eventDetail){
        this.dispatchEvent(new CustomEvent("changedata", { detail: eventDetail }));
    }
}