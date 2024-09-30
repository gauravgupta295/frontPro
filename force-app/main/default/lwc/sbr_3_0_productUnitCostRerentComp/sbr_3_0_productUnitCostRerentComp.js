import { LightningElement, wire, track, api } from 'lwc';
export default class Sbr_3_0_productUnitCostRerentComp extends LightningElement {
    @api record;
    @track recordName;
    @api unitCost;
    @track quantity = 1;
    @track costperitem;
    @api updatedQuantity;
    @api rowId;
    @track bulItemCheckbox;
    recordId;
    isCheckboxChecked = true;
    @track isDisable=false;

    multiMap = new Map();

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

    connectedCallback() {
        this.recordName = this.record.Name;
        this.recordId = this.record.Id;
        console.log('CCB this.recordId : ', this.recordId);
        this.unitCost = this.record.Unit_Cost_of_Inventory__c;
        this.catClassValue = this.record.Product_SKU__c;
        
        if (this.record.Bulk_Item__c == true) {
            this.isDisable = false;
            this.isCheckboxChecked = false;

        } else {
            this.isDisable = true;
            this.isCheckboxChecked = true;
        }
        const updatedQuantity = 1;
        const rowId = this.recordId;
        const unitCostValue = this.unitCost;
        const catClassValues = this.catClassValue;
        this.dispatchEvent(new CustomEvent('valuechange', { detail: { rowId, updatedQuantity, unitCostValue, catClassValues } }));
    }

    decreaseQuantity(event) {
        if (this.quantity > 1) {
            this.quantity--;
            const updatedQuantity = this.quantity;
            const rowId = this.recordId;
            const unitCostValue = this.unitCost;
            const catClassValues = this.catClassValue;
            console.log('decreaseQuantity this.recordId : ', this.recordId);
            this.dispatchEvent(new CustomEvent('valuechange', { detail: { rowId, updatedQuantity, unitCostValue, catClassValues } }));
        }
    }
    increaseQuantity(event) {
        this.quantity++;
        if (this.quantity === null) {
            this.quantity = 1;
        }
        const updatedQuantity = this.quantity;
        const rowId = this.recordId;
        const unitCostValue = this.unitCost;
        console.log('increaseQuantity this.recordId : ', this.recordId);
        const catClassValues = this.catClassValue;
        this.dispatchEvent(new CustomEvent('valuechange', { detail: { rowId, updatedQuantity, unitCostValue, catClassValues } }));
    }
    changeQuantity(event)
    {
        this.quantity = event.detail.value;
        const updatedQuantity = this.quantity;
        const rowId = this.recordId;
        const unitCostValue = this.unitCost;
        const catClassValues = this.catClassValue;
        this.dispatchEvent(new CustomEvent('valuechange', { detail: { rowId, updatedQuantity, unitCostValue, catClassValues } }));
    }

    handleDelete() {
        const card = this.template.querySelector('lightning-card');
        card.parentElement.removeChild(card);

        const rowId = this.recordId;
        const updatedQuantity = this.quantity;
        const unitCostValue = this.unitCost;
        const catClassValues = this.catClassValue;
        console.log('handleDelete this.recordId : ', this.recordId);
        console.log('after Delete this.updatedQuantity: ', JSON.stringify(updatedQuantity));
        this.dispatchEvent(new CustomEvent('close', { detail: { rowId, updatedQuantity, unitCostValue, catClassValues } }));
    }
}