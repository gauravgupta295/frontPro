import { LightningElement, api, wire, track } from 'lwc';
import getReceiptDetails from '@salesforce/apex/SBR_3_0_PurchaseOrderReceiptCntrl.getReceiptDetails';
import createPOReceipts from '@salesforce/apex/SBR_3_0_PurchaseOrderReceiptCntrl.createPOReceipts';
import getUserLocation from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getUserLocation';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { getRecord,notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Id from "@salesforce/user/Id";
//Message Channel
import { MessageContext, publish, subscribe  } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';

const FIELDS = ['Purchase_Order__c.ShipTo_Location__c','Purchase_Order__c.ShipTo_Type__c ']

const columnsReceiver = [
    { label: 'Seq #', fieldName: "Receiver_Seq__c", cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Rvd Date', fieldName: "Date_Received__c", cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Item Number', fieldName: "itemNumber", cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Item Description', fieldName: 'itemDesc', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Status', fieldName: 'Status__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Adj/Crd', fieldName: 'Adjust_Credit_Ind__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Reason', fieldName: 'Reason_Code__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Qty', fieldName: 'Quantity_Received__c', type: 'number', typeAttributes: { minimumFractionDigits: 2 }, cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'U/M', fieldName: 'Units__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'currency', typeAttributes: { minimumFractionDigits: 3 }, cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Extended Cost', fieldName: 'extendedCost', type: 'currency', typeAttributes: { minimumFractionDigits: 3 }, cellAttributes: { class: { fieldName: 'controlEditField1' } } }
];

export default class Sbr_3_0_PurchaseOrderReceiptReceiverCmp extends LightningElement {
    @wire(MessageContext)
    messageContext
    @api recordId;
    columnsReceiver = columnsReceiver;
    @api receiptRec = [];
    isDisabled = true;
    receiverLabel;
    receiverLabel2;
    totalCost = 0;
    @track receiverRec = [];
    activeSections = ['Receiver #'];
    // Nikhil
    showModalOnMakeAdj = false
    nextModal = false
    creditReason;
    @track columnsReceiptAdj = []
    @track selectedRows = [];
    @track selectedRowIds = [];
    @track dataReceiptAdj = [];
    isCSSLoaded = false;
    draftValues;
    okToProcess = true;
    profileBranch;
    @track selectedRowName=[];
    @track receivedInHandQty=[];
    shipLocation;
    poDataToRefresh;
    dataToRefresh;
    shipType;
    userLocationDetail=[];
    userId=Id;

    connectedCallback() {
        this.orchestrateData('initalRender');
        this.subscription = subscribe(this.messageContext, PurchaseOrderLineItemMessageChannel,
            (result) => {
                if (result != undefined) {
                    let recId = result.recordId;
                    let recUpd = result.recordUpdated;
                    if (recUpd == true) {
                        this.recordId = recId;
                        refreshApex(this.poDataToRefresh);
                        refreshApex(this.dataToRefresh);
                    }
                }
            }
        );
    }
    @api orchestrateData(renderType) {
        if (renderType == 'reRender') {
            this.receiverRec = [];
        }

        this.totalCost = 0;
        
        console.log(JSON.stringify(this.receiptRec));
        this.receiptRec = JSON.parse(JSON.stringify(this.receiptRec));
        this.receiverLabel2 = 'Receiver # ' + this.receiptRec[0].Receiver_Number__c;
        this.receiverLabel = 'Receiver # ' + this.receiptRec[0].Receiver_Number__c + ' (' + this.receiptRec.length.toString() + ')';
        for (let i = 0; i < this.receiptRec.length; i++) {
            this.receiverRec.push(this.receiptRec[i]);
            console.log(this.receiverRec);
            this.receiverRec[i].extendedCost = this.receiverRec[i].Quantity_Received__c * this.receiverRec[i].Unit_Cost__c;
            this.receiverRec[i].itemNumber = this.receiptRec[i].PO_Line_Item__r.Item_Number__c;
            this.receiverRec[i].itemDesc = this.receiptRec[i].PO_Line_Item__r.Item_Description_Calc__c;
            this.totalCost += this.receiverRec[i].extendedCost;
        }
        this.totalCost = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(this.totalCost);
        console.log('this.totalCost--',this.totalCost);
        this.receiverRec = this.receiverRec.map(car => {
            return {
                ...car,
                controlEditField1: (car.Status__c === 'RA' || car.Status__c === 'PD' || car.Adjust_Credit_Ind__c == 'ADJ' || car.Adjust_Credit_Ind__c == 'CRD') ? "slds-text-color_inverse-weak" : "",
            };
        });
    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.poDataToRefresh = result;
        if (result.data) {
            console.log('PO Data', result.data);
            this.shipLocation = result.data.fields.ShipTo_Location__c.value;
            this.shipType=result.data.fields.ShipTo_Type__c.value;
            console.log('this.shipType >>', this.shipType);
	    } 
    }
    renderedCallback() {
        if (!this.isCSSLoaded) {
            loadStyle(this, POLWCCSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }
    @wire(getUserLocation, {loggedUserId:'$userId'})
    wiredLocation({data }) {
        if (data && data.length > 0) {
            this.userLocationDetail = data;
            console.log('this.userLocationDetail...', this.userLocationDetail);
            this.profileBranch = this.userLocationDetail[0].ProfileBranche__c;
            this.branchName = this.userLocationDetail[0].ProfileBranche__r.Name;

            console.log('this.profileBranch...', this.profileBranch);
            console.log('this.branchName...', this.branchName);
            console.log('this.userLocationDetail...', this.userLocationDetail);
        }
    }
     /*@wire(getQuantityOnHand, { itemName: this.selectedRowName, shipLoc:this.shipLocation, recordId:'$recordId'})
        wiredLocation({ error, data }) {
            console.log('inside getQuantityOnHand');
            if (data.length > 0) {
                this.receivedInHandQty=data;
                console.log('this.receivedInHandQty',this.receivedInHandQty);
            }
        }*/

    handleSectionToggle() {
        console.log('toggle');
    }

    handleSelection(event) {
        this.selectedRowIds = [];
        this.selectedRows = [];
        event.detail.selectedRows.forEach(row => {
            if (row.Status__c == 'RC' && row.Adjust_Credit_Ind__c != 'ADJ' && row.Adjust_Credit_Ind__c != 'CRD') { //use your condition here
                //the datatable only needs the row id
                this.selectedRowIds.push(row.Id);
                console.log('this.selectedRowID--->',JSON.stringify(this.selectedRowIds));
                this.selectedRowName.push(row.itemDesc);
                console.log('this.selectedRowName--->',JSON.stringify(this.selectedRowName));
                //but to be able to acess the selected records you need to save them in a different variable
                this.selectedRows.push(row);
            }
        });
        if (this.selectedRows.length > 0 && (this.shipLocation!=null || this.shipLocation!=undefined)){
            console.log('Inside ShipLoc Method');
            console.log('this.selectedRowName',JSON.stringify(this.selectedRowName));
            console.log('this.shipLocation',this.shipLocation);
            /*getQuantityOnHand({ itemName: this.selectedRowName, shipLoc:this.shipLocation})
            .then((result) => {
                console.log('inside getQuantityOnHand');
                if (result && result.length > 0) {
                    this.receivedInHandQty = result.data;
                    console.log('this.receivedInHandQty', this.receivedInHandQty);
                }
            }).catch((err) => {
                console.log(err);
            });*/
            this.isDisabled = false;
        }
        else {
            this.isDisabled = true;
        }
    }

    /**
     *  Added by Nikhil as a part of FRONT-11627
     ***/
    handleClick() {
        this.showModalOnMakeAdj = true;
    }

    handleCloseReceiptModal() {
        this.showModalOnMakeAdj = false;
    }
    handleReceiptAdjust(event) {
        this.showModalOnMakeAdj = false;
        this.nextModal = true;
        this.creditReason = event.detail.creditReason;
        this.getReceiptInfo();
    }
    handleClose() {
        this.nextModal = false;
    }

    getReceiptInfo() {
        getReceiptDetails({ receiptIds: this.selectedRowIds })
            .then((result) => {
                console.log('Result---1',result);
                this.dataReceiptAdj=result;
                console.log('this.dataReceiptAdj---1',JSON.stringify(this.dataReceiptAdj));
                console.log('this.dataReceiptAdj.length',JSON.stringify(this.dataReceiptAdj.length));
                    for (let i = 0; i < this.dataReceiptAdj.length; i++) {
                        this.receivedInHandQty.push(this.dataReceiptAdj[i].Qty_On_Hand__c);
                    }
            
                console.log('this.receivedInHandQty',JSON.stringify(this.receivedInHandQty));

                this.processRecords();
            })
            .catch((error) => {
                console.log('error ====> ' + error);
            });
            
        this.updateColumns();
    }

    updateColumns() {
        this.columnsReceiptAdj = [
            { label: 'Rcd #', fieldName: "needToCheck", hideDefaultActions: true },
            { label: 'Seq #', fieldName: "Receiver_Seq__c", hideDefaultActions: true },
            { label: 'Rvd Date', fieldName: "Date_Received__c", hideDefaultActions: true },
            { label: 'Item Number', fieldName: "itemNumber", hideDefaultActions: true },
            { label: 'Item Description', fieldName: 'itemDescription', hideDefaultActions: true },
            { label: 'Original Qty', fieldName: 'Quantity_Received__c', hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 2 } },
            { label: 'Original Cost', fieldName: 'Unit_Cost__c', hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 } }
        ]

        switch (this.creditReason) {
            case 'CC Cost Change':
                this.columnsReceiptAdj.push({ label: 'Correct Cost', initialWidth: 120, fieldName: 'correctedCost', editable: true, hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 }});
                break;
            case 'DA Damaged':
                this.columnsReceiptAdj.push({ label: 'Correct Cost', initialWidth: 120, fieldName: 'correctedCost', editable: true, hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 } });
                this.columnsReceiptAdj.push({ label: 'Correct Quantity', initialWidth: 120, fieldName: 'correctedQty', editable: true, hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 2 } });
                break;
            case 'OV Overage':
                this.columnsReceiptAdj.push({ label: 'Correct Cost', initialWidth: 120, fieldName: 'correctedCost', editable: true, hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 } });
                this.columnsReceiptAdj.push({ label: 'Correct Quantity', initialWidth: 120, fieldName: 'correctedQty', editable: true, hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 3 } });
                break;
            case 'QC Quantity Change':
                this.columnsReceiptAdj.push({ label: 'Correct Quantity', initialWidth: 120, fieldName: 'correctedQty', editable: true, hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 2 } });
                break;
            case 'SH Shortage':
                this.columnsReceiptAdj.push({ label: 'Correct Cost', initialWidth: 120, fieldName: 'correctedCost', editable: true, hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 } });
                this.columnsReceiptAdj.push({ label: 'Correct Quantity', initialWidth: 120, fieldName: 'correctedQty', editable: true, hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 2 } });
                break;
            case 'WP Wrong Price':
                this.columnsReceiptAdj.push({ label: 'Correct Cost', initialWidth: 120, fieldName: 'correctedCost', editable: true, hideDefaultActions: true, type: 'currency', typeAttributes: { minimumFractionDigits: 3 } });
                break;
            case 'WQ Wrong Quantity':
                this.columnsReceiptAdj.push({ label: 'Correct Quantity', initialWidth: 120, fieldName: 'correctedQty', editable: true, hideDefaultActions: true, type: 'number', typeAttributes: { minimumFractionDigits: 2 } });
                break;
        }
    }

    processRecords() {
        this.dataReceiptAdj = this.dataReceiptAdj.map(item => {
            return {
                ...item,
                itemNumber: item.PO_Line_Item__r.Item_Number__c,
                itemDescription: item.PO_Line_Item__r.Item_Description_Calc__c,
                correctedCost: '',
                correctedQty: '',
                id: item.Id,
                comboId: JSON.stringify({ Id: item.Id, PO_Line_Item__c: item.PO_Line_Item__c }),
            };
        });
        Object.preventExtensions(this.dataReceiptAdj);
    }
    handleBack() {
        this.nextModal = false;
        this.showModalOnMakeAdj = true;
    }
    /*************************************End code of FRONT-11627***************************************/

    async handleSave() {
        if (this.shipType === 'Branch') {
            console.log('this.shipType',this.shipType);
            if (this.shipLocation != this.profileBranch) {
                const evt = new ShowToastEvent({
                    message: 'Receipt location is different from screen location. Cannot create an adjustment',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                return;
            }
        }
        for(let i=0;i<this.receivedInHandQty.length;i++){
            console.log('this.receivedInHandQty.length()',this.receivedInHandQty.length);
            if(this.receivedInHandQty[i]==0){
                if (this.creditReason == 'DA Damaged' || this.creditReason=='OV Overage' || this.creditReason=='QC Quantity Change' || this.creditReason=='SH Shortage' || this.creditReason=='WQ Wrong Quantity') {
                const evt = new ShowToastEvent({
                    message: 'Location quantity on hand is 0. Item cannot be adjusted.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                okToProceed = false;
                }
            }
        }
        var okToProceed = true;
        let orgRows = this.template.querySelector('[data-id="receiptAdjustment"]').data;
        const orgRowsMap = new Map();
        orgRows.map((obj) => {
            orgRowsMap.set(obj.Id, obj);
        });
        console.log("orgRowsMap: ", orgRowsMap);
        let changedRows = this.template.querySelector('[data-id="receiptAdjustment"]').draftValues;
        console.log("changedRows: ", changedRows);
        changedRows = changedRows.map(item => {
            if (item.hasOwnProperty("correctedQty")) {
                item.Quantity_Received__c = item.correctedQty;
                delete item.correctedQty;
            }
            if (item.hasOwnProperty("correctedCost")) {
                console.log("item.correctedCost: ", item.correctedCost);
                item.Unit_Cost__c = item.correctedCost;
                delete item.correctedCost;
                if (item.Unit_Cost__c < 0) {
                    const evt = new ShowToastEvent({
                        message: 'Negative values are not allowed for Correct Cost.',
                        variant: 'error',
                        // mode: 'sticky'
                    });
                    return this.dispatchEvent(evt);
                }
            }
            if (item.hasOwnProperty("comboId")) {
                let jsonRes = JSON.parse(item.comboId);
                item.PO_Line_Item__c = jsonRes.PO_Line_Item__c;
                item.Id = jsonRes.Id;
                delete item.comboId;
            }
            return item;
        });
        console.log('changedRows:', changedRows);
        const chgRowsMap = new Map();
        changedRows.map((obj) => {
            chgRowsMap.set(obj.Id, obj);
        });
        console.log("chgRowsMap: ", chgRowsMap);
        //FRONT-11629
        for (let [key, chgVal] of chgRowsMap) {
            //console.log(key + " is " + chgVal);
            let orgMapVal = orgRowsMap.get(key);
            console.log('chgVal.Quantity_Received__c',chgVal.Quantity_Received__c);
            console.log('chgVal.Qty_On_Hand__c',chgVal.Qty_On_Hand__c);
            if ((this.creditReason == 'DA Damaged' || this.creditReason=='OV Overage' || this.creditReason=='QC Quantity Change' || this.creditReason=='SH Shortage' || this.creditReason=='WQ Wrong Quantity') && (chgVal.Quantity_Received__c > this.receivedInHandQty)){
                console.log('Inside Error If Condition');
                const evt = new ShowToastEvent({
                    message: 'Quantity to be adjusted is greater than locations quantity on hand.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                okToProceed = false;
            }
            if ((chgVal.Quantity_Received__c == orgMapVal.Quantity_Received__c) || (chgVal.Unit_Cost__c == orgMapVal.Unit_Cost__c)) {
                const evt = new ShowToastEvent({
                    message: 'Some or all of the values were not changed.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                okToProceed = false;
            }
        }
        if (okToProceed && changedRows.length > 0) {
            let records = JSON.stringify(changedRows);
            const updateOutPut = await createPOReceipts({ poReceipts: records, reason: this.creditReason, poRecId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: (updateOutPut == 'Success' ? 'Success' : 'Error'),
                    message: (updateOutPut == 'Success' ? 'Records updated successfully' : 'Error updating records. Please Contact your System Administrator'),
                    variant: (updateOutPut == 'Success' ? 'success' : 'error')
                })
            );
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            const selectedEvent = new CustomEvent("refresh", {
                detail: updateOutPut
            });
            this.dispatchEvent(selectedEvent);
            this.isDisabled = true;
            this.selectedRowIds = [];
        }
        refreshApex(this.dataToRefresh);
        this.nextModal = false;
        
    }
}