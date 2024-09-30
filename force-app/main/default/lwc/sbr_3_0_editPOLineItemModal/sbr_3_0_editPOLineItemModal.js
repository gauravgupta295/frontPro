import { LightningElement,track,api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import LightningModal from 'lightning/modal';


export default class Sbr_3_0_editPOLineItemModal extends LightningModal {
    @api recordId;
    @api modalHeader;
    @api unitCost;
    @api lastCost;

    pctIncrease;
    showPctIncrease;
    pctIncreaseMsg;

    renderedCallback() {
        var objHeader = this.template.querySelector('lightning-modal-header');
        objHeader.label = this.modalHeader;
        this.calculateDiff(this.unitCost);
    }

    costUpdated(event) {
        const unitCost = event.detail.value;
        this.calculateDiff(unitCost);
    }

    calculateDiff(unitCost) {
        if(this.lastCost != undefined && this.lastCost > 0) {
            this.pctIncrease = ((unitCost - this.lastCost) / this.lastCost).toFixed(2) * 100;
            if(this.pctIncrease != 0) {
                this.showPctIncrease = true;
                if(this.pctIncrease > 0) {
                    this.pctIncreaseMsg = ' Unit Cost is ' + this.pctIncrease.toString() + '% above last purchase';
                }
                else {
                    this.pctIncrease = this.pctIncrease * -1;
                    this.pctIncreaseMsg = ' Unit Cost is ' + this.pctIncrease.toString() + '% below last purchase';
                }
            }
        }
    }

    handleCancel() {
        this.close();
    }

    handleSave(event) {
        console.log('came in here');
        const btn = this.template.querySelector(".hidden");
        if(btn) {
            btn.click();
        }
    }

    handleSuccess(event) {
        console.log('onsuccess event recordEditForm', event.detail.id);
        const payload = event.detail;
        console.log(JSON.stringify(payload));
        this.close("OK");
    }

    handleSubmit(event) {
        console.log('Inside Submite Method');
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        console.log('onsubmit event recordEditForm'+ fields);
    }
}