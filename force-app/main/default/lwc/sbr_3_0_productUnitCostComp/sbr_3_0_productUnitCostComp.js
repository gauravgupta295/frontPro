import { LightningElement,wire,track,api } from 'lwc';
export default class sbr_3_0_productUnitCostComp extends LightningElement {
    @api record;
    @track recordName;
    @api unitCost;
    @track quantity=1;
    @track costperitem;
    recordId;
    @api updatedQuantity;
    @api rowId;

    @api
    checkValidity() {
        let isSelfValidated = false;
        isSelfValidated = [
            ...this.template.querySelectorAll("lightning-input")
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        return isSelfValidated;
    }

    connectedCallback()
    {
        this.recordName=this.record.Name;
        this.recordId=this.record.Id;
        this.unitCost=this.record.Last_Cost__c;
        this.stockvalue=this.record.Stock_class__c;
        this.itemnumber=this.record.Item_Number__c;

        const updatedQuantity=1;
        const rowId=this.recordId;
        const unitCostValue = this.unitCost;
        const stockValues = this.stockvalue;
        const itemNumber=this.itemnumber;
        this.dispatchEvent(new CustomEvent('valuechange',{detail:{rowId,updatedQuantity,unitCostValue,stockValues,itemNumber}}));      
    }

    changeQuantity(event)
    {
        this.quantity = event.detail.value;
        
        this.unitCost=this.record.Last_Cost__c;
        this.stockvalue=this.record.Stock_class__c;
        this.itemnumber=this.record.Item_Number__c;

        const updatedQuantity=this.quantity;
        const rowId=this.recordId;
        const unitCostValue = this.unitCost;
        const stockValues = this.stockvalue;
        const itemNumber=this.itemnumber;
        this.dispatchEvent(new CustomEvent('valuechange',{detail:{rowId,updatedQuantity,unitCostValue,stockValues,itemNumber}}));
    }

    decreaseQuantity(event)
    {
        if(this.quantity>1)
        {
            this.quantity--;
            this.unitCost=this.record.Last_Cost__c;
            this.stockvalue=this.record.Stock_class__c;
            this.itemnumber=this.record.Item_Number__c;
            const updatedQuantity=this.quantity;
            const rowId=this.recordId;
            const unitCostValue = this.unitCost;
            const stockValues = this.stockvalue;
            const itemNumber=this.itemnumber;
            this.dispatchEvent(new CustomEvent('valuechange',{detail:{rowId,updatedQuantity,unitCostValue,stockValues,itemNumber}}));
        }
    }

    increaseQuantity(event)
    {
        this.quantity++;
        if(this.quantity===null)
        {
            this.quantity=1;
        }
        this.unitCost=this.record.Last_Cost__c;
        this.stockvalue=this.record.Stock_class__c;
        this.itemnumber=this.record.Item_Number__c;

        const updatedQuantity=this.quantity;
        const rowId=this.recordId;
        const unitCostValue = this.unitCost;
        const stockValues = this.stockvalue;
        const itemNumber=this.itemnumber;
        this.dispatchEvent(new CustomEvent('valuechange',{detail:{rowId,updatedQuantity,unitCostValue,stockValues,itemNumber}}));
    }

    handleDelete()
    {
        const card=this.template.querySelector('lightning-card');
        console.log(card);
        card.parentElement.removeChild(card);
        const rowId=this.recordId;
        const updatedQuantity=this.quantity;
        const unitCostValue = this.unitCost;
        const stockValues = this.stockvalue;
        const itemNumber=this.itemnumber;
        this.dispatchEvent(new CustomEvent('close',{detail:{rowId,updatedQuantity,unitCostValue,stockValues,itemNumber}}));
    }
}