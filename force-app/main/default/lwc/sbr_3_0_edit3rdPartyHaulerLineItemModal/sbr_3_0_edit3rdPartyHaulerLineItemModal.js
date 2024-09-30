import {  LightningElement, api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import addFreightLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.addFreightLineItem';
import { getRecord } from 'lightning/uiRecordApi';
import getEventOption from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getEventOption';
import getPOLineItembyId from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItembyId';

const usageOptions = [
    { label: "Delivery", value: "Delivery" },
    { label: "Pickup", value: "Pickup" },
    { label: "Transfer", value: "Transfer" },
    { label: "Special Event", value: "Special Event" },
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

const objectFields = {
    recordTypeId: {apiName :'RecordTypeId'},
    quantity: {apiName :'Quantity__c'},
    unit: {apiName :'Units__c'},
    unitCost: {apiName :'Unit_Cost__c'},
    committedDate: {apiName :'Due_Date__c'},
    availableEarlyDate: {apiName :'Request_Date__c'},
    dropShipment: {apiName :'Drop_Shipment__c'},
    equipmentNumber: {apiName :'Equipment_Num__c', length : 10},
    messages: {apiName :'Messages__c'},
    freightReason: {apiName : 'Freight_Reason__c'},
    contract: {apiName :'Contract_Num__c'},
    transfer: {apiName:'Transfer_Num__c'},
    eventNo: {apiName:'AcctNumber__c'},
    reasonValue: {apiName:'Freight_Reason__c'},
    
}  

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Company_Code__c', 'Purchase_Order__c.Type__c'];

export default class Sbr_3_0_edit3rdPartyHaulerLineItemModal extends LightningModal {
    @api recordId;
    openModal = true;
    usageOptions = usageOptions;
    reasonOptions = reasonOptions;
    selectedUsage = "Delivery";
    isDeliverPickup = true;
    isSpecialEvent = false;
    contract = '';
    transfer = '';
    reasonValue = '';
    freightCost = '';
    freightReason = '';
    eventNo = '';
    equipment = '';
    proNum = '';
    message = '';
    disableSave = false;
    specialEventError = '';
    addFreightLabel='Edit Freight';
    isValid = true;
    eventOptions = [];
    @track poLineItemRecord = {};

    @track openChildModal = false;
    // @api recordId;
    // @track contract;

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
    @wire(getEventOption)
    getEvent({ error, data }) {
        if (data) {
            console.log('Data--------->',data);
            data.forEach((eventOp) => {
                        this.eventOptions.push({
                            label: eventOp.Name,
                            value: eventOp.Event_Number__c.toString()
                        });
                    });
        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    @wire(getPOLineItembyId, {poLineItemId : '$recordId'})
    getPOLineItem(result){
        this.dataToRefresh = result;
        if(result.data){
            this.poLineItemRecord = JSON.parse(JSON.stringify(result.data));
            this.recordTypeId = this.poLineItemRecord.RecordTypeId;
            this.lastCost = this.poLineItemRecord.Last_Cost__c; 
            this.contract=this.poLineItemRecord.Contract_Num__c;  
            this.unitCost=this.poLineItemRecord.Unit_Cost__c;  
            this.transfer=this.poLineItemRecord.Transfer_Num__c;
            this.eventNo=this.poLineItemRecord.AcctNumber__c.toString();
            console.log('this.eventNo---->',this.eventNo);     
            this.reasonValue=this.poLineItemRecord.Freight_Reason__c;
            this.equipmentNumber=this.poLineItemRecord.Equipment_Num__c;
            console.log('this.equipmentNumber---->',this.equipmentNumber);
            console.log('this.transfer---->',this.transfer);
            console.log('this.contract---->',this.contract);
        }
        else if(result.error) {
            this.error = result.error;
            console.error(this.error);
        }
    }

    handleInputChange(event){
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
        else if (field === 'freightReason') {
            this.poLineItemRecord.Freight_Reason__c = event.target.value;
        }
        else if (field === 'contract') {
            this.poLineItemRecord.Freight_Reason__c = event.target.value;
        }
    }

    handleUsageChange(event) {
        this.isDeliverPickup = event.detail.value == "Delivery" || event.detail.value == "Pickup" ? true : false;
        this.isSpecialEvent = event.detail.value == "Delivery" || event.detail.value == "Pickup" || event.detail.value == "Transfer" ? false : true;
        this.selectedUsage = event.detail.value;
        console.log('this.event Number', this.eventNo);
    }

    handleContractChange(event) {
        console.log(event.detail.value);
        this.contract = event.detail.recordId != null ? event.detail.recordId : '';
    }

    // sachin khambe >>
    handleContractFocus() {
        // Set openChildModal to true to show the child component as a modal
        console.log('into handleContractFocus : ');
        this.openChildModal = true;
    }

    handleCloseContractModal(event){
        console.log('in cancel event of parent');
        this.openChildModal = false;
    }
    handleSelectedContract(event){
        // console.log('in handleSelectedContract event of parent', event.detail.value);
        const selectedRecord = event.detail.record;
        console.log('Selected Record in Parent: ',JSON.stringify(selectedRecord));
        // this.contract = selectedRecord.Name;
        this.contract = selectedRecord.Contract_Order_Number__c;
        console.log('contract >>>  : ', this.contract);
        this.openChildModal = false;
        
    }

    handleSelectContract(){
        console.log('valid');
        var isEitherInValid = false; 
        if (this.isSpecialEvent && this.contract !== '') {
            this.template.querySelector('lightning-input[data-name=contract]').setCustomValidity('Enter either Contract # ');
            this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            console.log('either');
            this.isValid = false;
            //isEitherValid = true;
        }
    }
        // sachin khambe >>


    handleTransferChange(event) {
        console.log(this.transfer);
        console.log(event.target.checkValidity());
        this.transfer = event.detail.recordId != null ? event.detail.recordId : '';
    }

    handleReasonChange(event) {
        console.log(event.detail.value);
        this.reasonValue = event.detail.value;
    }

    handleFreightChange(event) {
        console.log(event.detail.value);
        this.freightCost = event.detail.value;
    }

    handleEventChange(event) {
        console.log(event.detail.value);
        this.eventNo = event.detail.recordId != null ? event.detail.recordId : '';
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
        var isEitherInValid = false; 
        if (this.isSpecialEvent && ((this.contract !== '' && this.transfer !== '') || (this.contract === '' && this.transfer === ''))) {
            this.template.querySelector('lightning-input[data-name=contract]').setCustomValidity('Enter either Contract # or Transfer #');
            this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            this.template.querySelector('lightning-record-picker[data-name=transferse]').setCustomValidity('Enter either Contract # or Transfer #');
            this.template.querySelector('lightning-record-picker[data-name=transferse]').reportValidity();
            console.log('either');
            this.isValid = false;
            isEitherValid = true;
        }
        else if(this.isValid && isEitherInValid){
            
            this.template.querySelector('lightning-input[data-name=contract]').setCustomValidity('');
            this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            this.template.querySelector('lightning-record-picker[data-name=transferse]').setCustomValidity('');
            this.template.querySelector('lightning-record-picker[data-name=transferse]').reportValidity();
        }
        if(this.isDeliverPickup && this.contract === ''){
            this.template.querySelector('lightning-input[data-name=contract]').reportValidity();
            console.log('del');
            this.isValid = false;
        }
        if(!this.isDeliverPickup && !this.isSpecialEvent && this.transfer === ''){
            this.template.querySelector('lightning-record-picker[data-name=transfer]').reportValidity();
            console.log('trans');
            this.isValid = false;
        }
        if(this.reasonValue === ''){
            if(!this.isSpecialEvent){
            this.template.querySelector('lightning-combobox[data-name=reasonvalue]').reportValidity();

            }
            else{
            this.template.querySelector('lightning-combobox[data-name=reasonvaluese]').reportValidity();
            }
            console.log('reason');
            this.isValid = false;
        }
        if(this.freightCost === ''){
            if(!this.isSpecialEvent){
            this.template.querySelector('lightning-input[data-name=freightcost]').reportValidity();
            }
            else{
            this.template.querySelector('lightning-input[data-name=freightcostse]').reportValidity();
            }
            console.log('cost');
            this.isValid = false;
        }
        if(this.isSpecialEvent && this.eventNo === ''){
            this.template.querySelector('lightning-record-picker[data-name=eventnose]').reportValidity();
            console.log('event');
            this.isValid = false;
        }
        if(this.isSpecialEvent && this.equipment === ''){
            this.template.querySelector('lightning-input[data-name=equipmentse]').reportValidity();
            console.log('equip');
            this.isValid = false;
        }
    }

    handleSave() {
        this.isValid = true;
        this.handleValidation();
        console.log(this.companyCode);
        if(this.isValid){
        addFreightLineItem({
            poId: this.recordId,
            companyCode: this.companyCode,
            usage: this.selectedUsage,
            contract: this.contract,
            transfer: this.transfer,
            freightReason: this.reasonValue,
            freightCost: this.freightCost,
            eventId: this.eventNo,
            equipment: this.equipment,
            proNum: this.proNum,
            message: this.message
        })
            .then(result => {
                console.log('saved');
                this.close(this.recordId);
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