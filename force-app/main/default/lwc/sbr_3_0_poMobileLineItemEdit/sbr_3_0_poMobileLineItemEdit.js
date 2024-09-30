import { LightningElement, api, track, wire } from 'lwc';
import getPOLineItembyId from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItembyId';
import getProductItemByProductAndLocation from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getProductItemByProductAndLocation';
import { refreshApex } from '@salesforce/apex';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UNIT_TYPES from '@salesforce/schema/PO_Line_Item__c.Units__c';

import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

const objectFields = {
    recordTypeId: { apiName: 'RecordTypeId' },
    quantity: { apiName: 'Quantity__c' },
    unit: { apiName: 'Units__c' },
    unitCost: { apiName: 'Unit_Cost__c' },
    committedDate: { apiName: 'Due_Date__c' },
    availableEarlyDate: { apiName: 'Request_Date__c' },
    dropShipment: { apiName: 'Drop_Shipment__c' },
    equipmentNumber: { apiName: 'Equipment_Num__c', length: 10 },
    messages: { apiName: 'Messages__c' },
}

export default class Sbr_3_0_poMobileLineItemEdit extends LightningElement {

    @api recordId;
    headerLabel = '';
    poLineItemRecord = {};
    productItem = {};
    dataToRefresh;
    recordTypeId;


    unitTypes = [];
    lastCost;
    showPctIncrease;
    pctIncreaseMsg;

    objectFields = objectFields;
    error;
    isCSSLoaded = false;

    renderedCallback() {
        this.headerLabel = this.poLineItemRecord.Item_Number__c;
        if (!this.isCSSLoaded) {
            loadStyle(this, POLWCCSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

    @wire(getPOLineItembyId, { poLineItemId: '$recordId' })
    wiredData(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.poLineItemRecord = JSON.parse(JSON.stringify(result.data));
            this.recordTypeId = this.poLineItemRecord.RecordTypeId;
            this.lastCost = this.poLineItemRecord.Last_Cost__c;
            this.calculateDiff();
            if (this.poLineItemRecord && this.poLineItemRecord.Item_Desc__c && this.poLineItemRecord.Purchase_Order__r.Branch_Location__c) {
                try{
                    this.getProductItemByProductAndLocation();
                }
                catch(error){
                    console.log('error',error);
                }
            }
        }
        else {
            this.error = result.error;
            console.log('wire',this.error);
        }
    }

    getProductItemByProductAndLocation() {
        getProductItemByProductAndLocation({ productId: this.poLineItemRecord.Item_Desc__c, orderLocationId: this.poLineItemRecord.Purchase_Order__r.Branch_Location__c })
            .then(data => {
                if (data) {
                    this.productItem = JSON.parse(JSON.stringify(data));
                }
            })
            .catch(error => {
                this.error = error;
                console.log('get',this.error);
            })
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: UNIT_TYPES })
    unitTypeValues({ error, data }) {
        if (data) {
            this.unitTypes = [{ label: '--None--', value: '', selected: true }, ...data.values];
            //this.unitTypes = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
        } else if (error) {
            this.error = error;
            console.log('unit',this.error);
            this.unitTypes = undefined;
        }
    }

    calculateDiff() {
        this.showPctIncrease = false;
        if (this.poLineItemRecord.Unit_Cost__c) {
            let unitCost = this.poLineItemRecord.Unit_Cost__c;
            if (this.lastCost && this.lastCost > 0) {
                let pctIncrease = (((unitCost - this.lastCost) / this.lastCost) * 100).toFixed(2);
                if (pctIncrease != 0) {
                    this.showPctIncrease = true;
                    let change = (pctIncrease > 0) ? 'above' : 'below';
                    this.pctIncreaseMsg = `Unit Cost is ${Math.abs(pctIncrease)}% ${change} last purchase.`;
                }
            }
        }
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        // Pricing Info
        if (field === 'orderQuantity') {
            this.poLineItemRecord.Quantity__c = event.target.value;
        }
        else if (field === 'unit') {
            this.poLineItemRecord.Units__c = event.detail.value;
        }
        else if (field === 'unitCost') {
            this.poLineItemRecord.Unit_Cost__c = event.target.value;
            this.calculateDiff();
        }
        // Shipping Info
        else if (field === 'committedDate') {
            this.poLineItemRecord.Due_Date__c = event.target.value;
        }
        else if (field === 'availableEarlyDate') {
            this.poLineItemRecord.Request_Date__c = event.target.value;
        }
        else if (field === 'dropShipment') {
            this.poLineItemRecord.Drop_Shipment__c = event.target.checked;
        }
        // Additional Info
        else if (field === 'equipmentNumber') {
            this.poLineItemRecord.Equipment_Num__c = event.target.value;
        }
        // Messages
        else if (field === 'messages') {
            this.poLineItemRecord.Messages__c = event.target.value;
        }
    }

    handleCancel() {
        console.log('close');
        refreshApex(this.dataToRefresh);
        console.log('close');
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleSave() {
        /* Yash - Code start - For validate the neagtive values for Unit cost*/
        let allValid = true;

        const inputs = this.template.querySelectorAll('[data-validation="true"]');
        inputs.forEach(inputCmp => {
            const fieldName = inputCmp.getAttribute('data-field');

            if (fieldName === 'unitCost' && parseFloat(inputCmp.value) < 0) {
                inputCmp.setCustomValidity('Unit Cost cannot be negative.');
                allValid = false;
            } else {
                inputCmp.setCustomValidity('');
            }
            inputCmp.reportValidity();
        });

        if (!allValid) {
            return;
        }
        /* Yash - Code end*/

        if (allValid) {
            // to update the PO Line Item record
            const fields = {};
            fields['Id'] = this.recordId;
            fields[objectFields.recordTypeId.apiName] = this.poLineItemRecord.RecordTypeId;
            fields[objectFields.quantity.apiName] = this.poLineItemRecord.Quantity__c;
            fields[objectFields.unit.apiName] = this.poLineItemRecord.Units__c;
            fields[objectFields.unitCost.apiName] = this.poLineItemRecord.Unit_Cost__c;
            fields[objectFields.committedDate.apiName] = this.poLineItemRecord.Due_Date__c;
            fields[objectFields.availableEarlyDate.apiName] = this.poLineItemRecord.Request_Date__c;
            fields[objectFields.dropShipment.apiName] = this.poLineItemRecord.Drop_Shipment__c;
            fields[objectFields.equipmentNumber.apiName] = this.poLineItemRecord.Equipment_Num__c;
            fields[objectFields.messages.apiName] = this.poLineItemRecord.Messages__c;

            const recordInput = { fields };

            try {
                this.showSpinner = true;
                await updateRecord(recordInput)
                console.log('Record updated successfully');
                this.showSpinner = false;
                await getRecordNotifyChange([{ recordId: this.recordId }]);
                await refreshApex(this.dataToRefresh);
                this.handleCancel();
            }
            catch (error) {
                this.showSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'An error occurred while trying to update the record.',
                        variant: 'error'
                    })
                );
            }
            console.log('After updateRecord');
        }
    }
}