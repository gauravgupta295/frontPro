import { LightningElement, track, api, wire } from 'lwc';
import searchProductsToAddLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.searchProductsToAddLineItem';
import addPOLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.addPOLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Company_Code__c', 'Purchase_Order__c.Type__c']

export default class Sbr_3_0_purchaseOrderAddLineItem extends LightningElement {

    @track showLineItemFields = false;
    @track itemNumber = '';
    @track qty = '';
    @track unitcost = '';
    @track errorMessage;

    @api recordId;
    @api itemid;
    companyCode;
    fieldError = false;
    isLineItemLoaded = false;
    disableSaveButton = true;
    poRecordType;
    isAddLineItemInputsVisibile = false;


    addLineItemfailedModal = false;
    failedModalOpen = false;

    connectedCallback() {
        this.recordId = this.recordId;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.companyCode = data.fields.Company_Code__c.value;
            this.poRecordType = data.fields.Type__c.value;
        } else if (error) {
            this.error = error;
        }
    }

    handleAddLineItem() {
        this.showLineItemFields = true;
    }
    handleAddLineItemMobile(){
        this.isAddLineItemInputsVisibile = true;
    }
    handleCancelMobile(){
        this.isAddLineItemInputsVisibile = false;
    }

    handleItemNumberChange(event) {
        this.itemNumber = event.target.value;
        if (this.itemNumber == '') {
            this.disableSaveButton = true;
        }
    }

    handleFailedModal(event) {
        console.log('Insideaddlintem')
        this.addLineItemfailedModal = false;
        console.log('handleFailedModal calling.... : ');
        this.handleSavePoReload();
    }

    handleSavePoReload() {
        const refreshPOLDataEvent = new CustomEvent('refreshpoldata');
        this.dispatchEvent(refreshPOLDataEvent);
        this.resetFields();
    }


    handleItemNumberBlur() {
        if (this.itemNumber) {
            searchProductsToAddLineItem({
                companyCode: this.companyCode,
                itemNumber: this.itemNumber
            })
                .then(result => {
                    if (result.length != 0) {
                        console.log('result for blurr method : ', result);
                        this.fieldError = false;
                        this.itemid = result[0].Id;
                        this.itemNumber = result[0].Item_Number__c;
                        // If 1 record returned, allow user to tab to next field
                        this.template.querySelector(`lightning-input[data-id="Quantity Field"]`).focus();
                        this.disableSaveButton = false;
                    } else {
                        // Otherwise display error message
                        this.fieldError = true;
                        this.errorMessage = 'Item not found';
                        this.addLineItemfailedModal = true;
                        this.disableSaveButton = true;

                    }
                })
                .catch(error => {
                    this.fieldError = true;
                    this.errorMessage = error.body.message; // Display Apex error message
                });
        }
    }
    handleQtyChange(event) {
        this.qty = event.target.value;
    }
    handleUnitCostChange(event) {
        this.unitcost = event.target.value;

    }
    handleSave() {
        // Validate inputs
        this.isLineItemLoaded = true;
        
        if (this.itemNumber === '' || this.qty === '' || this.unitcost === '' || this.unitcost <= 0) { //Removed 'this.qty <= 0' Conditoin By Yash
            this.fieldError = true;
            this.errorMessage = 'Please enter valid values for all fields';
            this.isLineItemLoaded = false;
            return;
        }

        /*Start - Yash code*/
        const parsedQty = parseFloat(this.qty);
        const roundedQty = isNaN(parsedQty) ? '' : parsedQty.toFixed(2);
        /*End - Yash code*/

        // Call Apex method to save line item
        addPOLineItem({
            recordId: this.recordId,
            newItem: false,
            productId: this.itemid,
            quantity: roundedQty,
            cost: this.unitcost,
            itemNumber: this.itemNumber,
            companyCode: this.companyCode,
            poRecordType: this.poRecordType

        })
            .then(result => {
                this.isLineItemLoaded = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        message: 'PO Line Item(s) added Successfully',
                        title: 'Success',
                        variant: 'Success'
                    })
                );
                this.disableSaveButton = true;
                
                // Reset inputs and hide fields
                this.resetFields();
                // Signal to parent component to refresh data
                const refreshPOLDataEvent = new CustomEvent('refreshpoldata');
                this.dispatchEvent(refreshPOLDataEvent);
                this.isAddLineItemInputsVisibile = false;
            })
            .catch(error => {
                this.isLineItemLoaded = false;
                console.log('isLineItemLoaded :catch ', this.isLineItemLoaded);
                console.log('Inside Catch', error.body.message);
                this.errorMessage = error.body.message; // Display Apex error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while Adding to Purchase Order',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

        this.resetFields();

    }
    handleCancel() {
        this.resetFields();
    }
    resetFields() {
        this.itemNumber = '';
        this.qty = '';
        this.unitcost = '';
        this.errorMessage = '';
        this.showLineItemFields = false;
    }
    get errorMessageExists() {
        return !!this.errorMessage;
    }

    handleFailedPopUp() {
        this.popup();

    }
}