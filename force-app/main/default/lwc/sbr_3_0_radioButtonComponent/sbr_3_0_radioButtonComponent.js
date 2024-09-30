import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class Sbr_3_0_radioButtonComponent extends LightningElement {

    @api radioGroupLabel;
    @api radioGroupValue;
    @api optionsLabelString;
    @api optionsValueString;
    @api isDisabled;
    @api isRequired;
    options = [];

    connectedCallback(){
        let optionsLabelList = this.optionsLabelString.split(',');
        let optionsValueList = this.optionsValueString.split(',');
        for(let i = 0; i < optionsLabelList.length; i++){
            this.options.push({ label: optionsLabelList[i], value: optionsValueList[i] });
        }
    }

    handleChange(event){
        this.radioGroupValue = event.target.value;
        this.dispatchFlowAttributeChangeEvent('radioGroupValue');
    }

    dispatchFlowAttributeChangeEvent(attributeName){
        this.dispatchEvent(new FlowAttributeChangeEvent(attributeName, this[attributeName]));
    }
}