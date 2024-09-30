import { LightningElement, api } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class Sbr_3_0_retailEstimatorComp extends LightningElement {
    @api retailPartsCost;
    @api retailLaborCost;
    @api retailMiscCost;
    @api retailTotalCost;
    @api retailDeductibleCost;
    @api readOnly;
    @api displayDeductible;

    get totalCost() {
        return +this.retailPartsCost + +this.retailLaborCost + + this.retailMiscCost;
    }
    fieldLableAttributeMap = {
        'Parts $':'retailPartsCost',
        'Labor $':'retailLaborCost',
        'Misc $':'retailMiscCost',
        'Total $':'retailTotalCost',
        'Deductible $':'retailDeductibleCost'
    }

    connectedCallback()
    {
        this.retailDeductible = 6;
    }

    handleChangeData(event)
    {
        debugger;
        if(event?.detail)
        {
            this[this.fieldLableAttributeMap[event.detail.fieldName]] = event.detail.fieldValue;
            //Dispatch flow Attribute change event
            this.dispatchFlowAttributeChangeEvent(this.fieldLableAttributeMap[event.detail.fieldName]);
        }
    }

    dispatchFlowAttributeChangeEvent(attributeName)
    {
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            attributeName,
            this[attributeName]
        );
        this.dispatchEvent(attributeChangeEvent);
    }

    getTotalValue()
    {

    }
}