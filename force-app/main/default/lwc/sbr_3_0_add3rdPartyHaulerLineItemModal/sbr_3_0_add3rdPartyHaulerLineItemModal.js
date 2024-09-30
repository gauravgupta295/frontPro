import { LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import addFreightLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.addFreightLineItem';
import getEventOption from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getEventOption';
import getPOLineItembyId from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getFreightDetailsById';
import { getRecord } from 'lightning/uiRecordApi';

const usageOptions = [
{ label: "Delivery", value: "D" },
{ label: "Pickup", value: "P" },
{ label: "Transfer", value: "T" },
{ label: "Special Event", value: "S" },
];

const reasonOptions = [
{ label: "FRT PLANNING CHALLENGES", value: "FRT PLANNING CHALLENGES" },
{ label: "FRT DRIVER DOT COMPLIANCE", value: "FRT DRIVER DOT COMPLIANCE" },
{ label: "FRT GEARSHIFT TRANSFER", value: "FRT GEARSHIFT TRANSFER" },
{ label: "FRT LONG HAUL", value: "FRT LONG HAUL" },
{ label: "FRT LARGE PROJECT", value: "FRT LARGE PROJECT" },
{ label: "FRT DEMAND EXCEEDS CAPACITY", value: "FRT DEMAND EXCEEDS CAPACITY" },
{ label: "FRT EMPLOYEE PTO", value: "FRT EMPLOYEE PTO" },
{ label: "FRT TRUCK OUT OF SERVICE", value: "FRT TRUCK OUT OF SERVICE" }
];


const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Company_Code__c', 'Purchase_Order__c.Type__c'];

export default class Sbr_3_0_add3rdPartyHaulerLineItemModal extends LightningModal {
    @api recordId;
    @api addFreightLabel;
    @api poId;
    openAddFreightModal = true;
    usageOptions = usageOptions;
    reasonOptions = reasonOptions;
    selectedUsage = "D";
    isDeliverPickup = true;
    isSpecialEvent = false;
    contract = '';
    transfer = '';
    reasonValue = '';
    freightCost = '';
    eventNo = '';
    equipment = '';
    proNum = '';
    message = '';
    disableSave = false;
    specialEventError = '';
    isValid = true;
    contractId;
    transferId;
    eventOptions = [];

    connectedCallback() {
        console.log('label',this.addFreightLabel);
        getEventOption()
        .then(data => 
        {
            console.log('Data--------->',data);
            data.forEach((eventOp) => {
                this.eventOptions.push({
                    label: eventOp.Name,
                    value: eventOp.Event_Number__c.toString()
                });
            });
        })
        .catch(error => {
            console.log('no Data');
        })

        if(this.addFreightLabel=='Edit Freight'){
            getPOLineItembyId({ poLineItemId: this.recordId })
            .then(result => 
            {
                console.log('result---->',result);
                this.selectedUsage = result.Freight_Type__c;
                this.isDeliverPickup = result.Freight_Type__c == "D" || result.Freight_Type__c == "P" ? true : false;
                this.isSpecialEvent = result.Freight_Type__c == "D" || result.Freight_Type__c == "P" || result.Freight_Type__c == "T" ? false : true;
                this.contract = (this.isDeliverPickup || this.isSpecialEvent) && result.Contract_Num__c != undefined  ? result.Contract_Num__c : this.contract;
                this.contractId = (this.isDeliverPickup || this.isSpecialEvent) && result.Contract_Number__c != undefined  ? result.Contract_Number__c : this.contractId;
                this.transfer = (!this.isDeliverPickup || this.isSpecialEvent) && result.Transfer_Num__c != undefined ? result.Transfer_Num__c : this.transfer;
                this.transferId = (this.isDeliverPickup || this.isSpecialEvent) && result.Transfer_Num__c != undefined  ? result.Transfer_Num__c : this.transferId;
                this.reasonValue = result.Freight_Reason__c;
                this.freightCost = result.Unit_Cost__c;
                this.eventNo = this.isSpecialEvent ? result.AcctNumber__c.toString() : this.eventNo;
                this.equipment = this.isSpecialEvent ? result.Equipment_Num__c : this.equipment;
                this.proNum = result.Pro_Number__c;
                this.message = result.Messages__c;
                this.companyCode = result.Company_Code__c;
            })
            .catch(error => {
                console.log('no Data');
            })
        }
    }

    @track openChildModal = false;
    @track openTransferModal = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('Company code of PO >>', data.fields.Company_Code__c.value);
            this.companyCode = data.fields.Company_Code__c.value;
            console.log('Company code of PO >>', this.companyCode);


        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    handleUsageChange(event) {
        this.isDeliverPickup = event.detail.value == "D" || event.detail.value == "P" ? true : false;
        this.isSpecialEvent = event.detail.value == "D" || event.detail.value == "P" || event.detail.value == "T" ? false : true;
        this.selectedUsage = event.detail.value;
    }

    handleContractChange(event) {
        console.log(event.detail.value);
        this.contract = event.detail.recordId != null ? event.detail.recordId : '';
        console.log('handleContractChange>>>');
        if(this.isSpecialEvent){
            this.template.querySelector("lightning-input[data-name='contractse']").value = event.target.value;
        }
        else{
            this.template.querySelector("lightning-input[data-name='contract']").value = event.target.value;
        }
    }
      handleTransferChange(event) {
        console.log(this.transfer);
        console.log(event.target.checkValidity());
        this.transfer = event.detail.value != null ? event.detail.value : '';
        if(this.isSpecialEvent){
            this.template.querySelector("lightning-input[data-name='transferse']").value = event.target.value;
        }
        else{
            this.template.querySelector("lightning-input[data-name='transfer']").value = event.target.value;
        }
    }

    /* ................................. sachin khambe code ends............................................>> */
    handleContractFocus() {
        console.log('into handleContractFocus : ');
        this.openChildModal = true;
        this.openAddFreightModal = false;
    }
     handleTransferFocus() {
        console.log('into handleContractFocus : ');
        this.openTransferModal = true;
        this.openAddFreightModal = false;
    }

    handleCloseContractModal(event) {
        console.log('in cancel event of parent');
        this.openChildModal = false;
        this.openAddFreightModal = true;
    }
    handleCloseTransferModal(event) {
        console.log('in cancel event of parent');
        this.openTransferModal = false;
        this.openAddFreightModal = true;
    }
    handleSelectedContract(event) {
        this.openAddFreightModal = true;
        this.openChildModal = false;
        const selectedRecord = event.detail.record;
        console.log('Selected Record in Parent: ', JSON.stringify(selectedRecord));
        //this.contract = selectedRecord.Name;
        this.contract = selectedRecord.Contract_Order_Number__c;
        this.contractId = selectedRecord.Id;
        console.log('contract >>>  : ', this.contract);
        window.setTimeout(() => {
            if (this.isSpecialEvent) {
                this.template.querySelector("lightning-input[data-name='contractse']").value = this.contract;
                this.template.querySelector('lightning-input[data-name=contractse]').reportValidity();
            }
            else {
                this.template.querySelector("lightning-input[data-name='contract']").value = this.contract;
                this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            }
        }, 5);
    }
     handleSelectedTransfer(event) {
        this.openAddFreightModal = true;
        this.openTransferModal = false;
        const selectedRecord = event.detail.record;
        console.log('Selected Record in Parent: ', JSON.stringify(selectedRecord));
        //this.contract = selectedRecord.Name;
        this.transfer = selectedRecord.tnumber;
        this.transferId = selectedRecord.Id;
        console.log('contract >>>  : ', this.transfer);
        console.log('contract >>>  : ', this.transferId);
        window.setTimeout(() => {
            if (this.isSpecialEvent) {
                this.template.querySelector("lightning-input[data-name='transferse']").value = this.transfer;
                this.template.querySelector('lightning-input[data-name=transferse]').reportValidity();
            }
            else {
                this.template.querySelector("lightning-input[data-name='transfer']").value = this.transfer;
                this.template.querySelector('lightning-input[data-name=transfer]').reportValidity();
            }
        }, 5);
    }
        
        //console.log(' this.template.querySelector>>>>>', this.template.querySelector("lightning-input[data-name='contract']").value);
        



    /* ................................. sachin khambe code ends............................................>> */


  

    handleReasonChange(event) {
        console.log(event.detail.value);
        this.reasonValue = event.detail.value;
    }

    handleFreightChange(event) {
        console.log(event.detail.value);
        this.freightCost = event.detail.value;
    }

    handleEventChange(event) {
        console.log(event.detail);
        this.eventNo = event.detail.value != null ? event.detail.value : '';
    }

    handleEquipmentChange(event) {
        console.log(event.detail.value);
        this.equipment = event.detail.value;
    }

    handleProNumberChange(event) {
        console.log(event.detail.value);
        this.proNum = event.detail.value;
    }

    handleMessageChange(event) {
        console.log(event.detail.value);
        this.message = event.detail.value;
    }

    handleValidation() {
        console.log('valid');
        console.log('Delivery',this.isDeliverPickup);
        console.log('SE',this.isSpecialEvent);
        console.log('Transfer',this.transfer);
        if (this.isSpecialEvent && ((this.contract !== '' && this.transfer !== '') || (this.contract === '' && this.transfer === ''))) {
            this.template.querySelector('lightning-input[data-name=contractse]').setCustomValidity('Enter either Contract # or Transfer #');
            this.template.querySelector('lightning-input[data-name=contractse]').reportValidity();
            this.template.querySelector('lightning-input[data-name=transferse]').setCustomValidity('Enter either Contract # or Transfer #');
            this.template.querySelector('lightning-input[data-name=transferse]').reportValidity();
            console.log('either');
            this.isValid = false;
        }
        if (this.isDeliverPickup && this.contract === '') {
            this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            console.log('del');
            this.isValid = false;
        }
        if (!this.isDeliverPickup && !this.isSpecialEvent && this.transfer === '') {
            this.template.querySelector('lightning-input[data-name=transfer]').reportValidity();
            console.log('trans');
            this.isValid = false;
        }
        if (this.reasonValue === '') {
            if (!this.isSpecialEvent) {
                this.template.querySelector('lightning-combobox[data-name=reasonvalue]').reportValidity();

            }
            else {
                this.template.querySelector('lightning-combobox[data-name=reasonvaluese]').reportValidity();
            }
            console.log('reason');
            this.isValid = false;
        }
        if (this.freightCost === '') {
            if (!this.isSpecialEvent) {
                this.template.querySelector('lightning-input[data-name=freightcost]').reportValidity();
            }
            else {
                this.template.querySelector('lightning-input[data-name=freightcostse]').reportValidity();
            }
            console.log('cost');
            this.isValid = false;
        }
        if (this.isSpecialEvent && this.eventNo === '') {
            this.template.querySelector('lightning-combobox[data-name=eventnose]').reportValidity();
            console.log('event');
            this.isValid = false;
        }
        if (this.isSpecialEvent && this.equipment === '') {
            this.template.querySelector('lightning-input[data-name=equipmentse]').reportValidity();
            console.log('equip');
            this.isValid = false;
        }
    }

    handleSave() {
        this.isValid = true;
        this.handleValidation();
        console.log(this.companyCode);
        if (this.isValid) {
            addFreightLineItem({
                recId: this.recordId,
                companyCode: this.companyCode,
                usage: this.selectedUsage,
                contract: this.contractId,
                transfer: this.transfer,
                freightReason: this.reasonValue,
                freightCost: this.freightCost,
                eventId: this.eventNo,
                equipment: this.equipment,
                proNum: this.proNum,
                message: this.message,
                isUpdate: this.addFreightLabel == 'Edit Freight'
            })
                .then(result => {
                    console.log('saved');
                    this.close('OK');
                })
                .catch(error => {
                    console.log('no Data');
                })
        }
    }

    handleCancel() {
        this.close(this.recordId);
    }
}