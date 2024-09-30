import { LightningElement, api, wire, track } from 'lwc';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import getUserLocation from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getUserLocation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { updateRecord, deleteRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import editRecordModal from 'c/sbr_3_0_poLineItemEditModal';
import removeBackOrderQtyStatus from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.removeBackOrderQtyStatus';
import updatePOStatusToReceived from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.updatePOStatusToReceived';
import deletePOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.deletePOLineItems';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { getRecord } from 'lightning/uiRecordApi';
import Id from "@salesforce/user/Id";
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.ShipTo_Location__c', 'Purchase_Order__c.ShipTo_Type__c', 'Purchase_Order__c.ShipTo_Name__c'];

const actions = [
    //{ label: 'View Sales History', name: 'sales_history', disabled: true },
    //{ label: 'Cancel B/O', name: 'remove'} 
];


const assetcolumns = [
    { label: 'Item Number', fieldName: 'Item_Number__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Status', fieldName: 'Status__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    /*Start - Yash code*/
    { label: 'Ord Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Rcd Qty', fieldName: 'receivedAssetQty', type: 'number', editable: { fieldName: 'controlEditField' }, type: 'number', displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'B/O Qty', fieldName: 'Open_Order_Qty__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField' } }, typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1', fieldName: 'my-vertical-padding' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
    { label: 'Extended Cost', fieldName: 'extendedCost', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
    /*End - Yash code*/
    { label: 'Equipment #', fieldName: 'Equipment_Num__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Cat Class', fieldName: 'Item_Class__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Serial #', fieldName: 'ShouldBeRemoved', cellAttributes: { class: { fieldName: 'controlEditField1' } } }
];
const assetcolumns2 = [
    { label: 'Item Number', fieldName: 'Item_Number__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Status', fieldName: 'Status__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    /*Start - Yash code*/
    { label: 'Ord Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Rcd Qty', fieldName: 'receivedAssetQty', type: 'number', type: 'number', displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'B/O Qty', fieldName: 'Open_Order_Qty__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField' } }, typeAttributes: { minimumFractionDigits: 2 } },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1', fieldName: 'my-vertical-padding' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
    { label: 'Extended Cost', fieldName: 'extendedCost', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
    /*End - Yash code*/
    { label: 'Equipment #', fieldName: 'Equipment_Num__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Cat Class', fieldName: 'Item_Class__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Serial #', fieldName: 'ShouldBeRemoved', cellAttributes: { class: { fieldName: 'controlEditField1' } } }
];

export default class Sbr_3_0_ReceiveItemsPOLineItemComp extends LightningElement {
    subscription;
    @wire(MessageContext)
    messageContext
    @api recordId;
    @api itemtype;
    selectedRowIds = [];
    selectedRowIdsAsset = [];
    colDisplay5 = [];
    colDisplay4 = [];
    sumOfUnitCost = 0;
    /*sumOfQuantity = 0; */
    fldsItemValues = [];
    lineItems = [];
    @track assetlineItems = [];
    @track saleslineItems = [];
    isMisc = false;
    cardTitle = '';
    cardIcon = '';
    inputvalue;
    userId = Id;
    branchName;
    userLocationDetail = [];
    shipLocation;
    shipType;
    profileBranch;
    shipToName;
    Buttontrue = true;
    AssetButtontrue = true;
    actions = actions;
    columns = [
        { label: 'Item Number', fieldName: "Item_Number__c", },
        { label: 'Manufacturer #', fieldName: 'Manufacturer__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Status', fieldName: 'Status__c', cellAttributes: { fieldName: 'controlEditField', class: { fieldName: 'controlEditField1' } } },
        /*Start - Yash code*/
        { label: 'Ord Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Rcd Qty', fieldName: 'receivedQty', type: 'number', editable: { fieldName: 'controlEditField' }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { maximumFractionDigits: 2 } },
        { label: 'B/O Qty', fieldName: 'Open_Order_Qty__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'U/M', fieldName: 'Units__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', editable: { fieldName: 'controlEditField' }, type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'className' } }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { currencyDisplayAs: 'formatted', minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'extendedCost', type: 'currency', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
        /*End - Yash code*/
        {
            type: 'action',
            typeAttributes: {
                //rowActions: actions,
                menuAlignment: 'right',
                rowActions: this.getRowActions.bind(this)
            }
        }
    ];
    columns2 = [
        {
            label: 'Item Number', fieldName: "Item_Number__c", type: 'button', typeAttributes: {
                label: { fieldName: "Item_Number__c" },
                name: "edit",
                variant: "base",
                disabled: true
            }
        },
        { label: 'Manufacturer #', fieldName: 'Manufacturer__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Status', fieldName: 'Status__c', cellAttributes: { fieldName: 'controlEditField', class: { fieldName: 'controlEditField1' } } },
        { label: 'Ord Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' }, typeAttributes: { minimumFractionDigits: 2 } } },
        { label: 'Rcd Qty', fieldName: 'receivedQty', type: 'number', displayReadOnlyIcon: '!controlEditField', typeAttributes: { maximumFractionDigits: 2 } },
        { label: 'B/O Qty', fieldName: 'Open_Order_Qty__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'U/M', fieldName: 'Units__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'className' } }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 3 } },
        //{ label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right',  class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true },
        { label: 'Extended Cost', fieldName: 'extendedCost', type: 'currency', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } }
    ];
    assetcolumns = assetcolumns;
    assetcolumns2;
    selectedRowId;
    showEditPOComponent = false;
    openModal = false;
    draftValues = [];
    dataToRefresh;
    poDataToRefresh = []
    showSpinner = false;
    okToProcess = true;
    activeSectionMessage = '';
    salesLabel;
    assetLabel;
    totalSalesQty;
    totalAssetQty;
    totalSalesCost;
    totalAssetsCost;
    openCreateModal = false;
    activeSections = ['Sales', 'Asset'];
    companyCode;
    showitems = true;
    selectedRows = [];
    selectedRowAsset = [];
    statusValue;
    enabledRowCount;
    isCancelledReceived = false;

    rowIds = [];
    showRemoveSalesButton = false;
    showRemoveAssetButton = false;
    showModalOnCancelBOQty = false
    selectedPOlineItem;

    openReceiveItemModal = false;
    receiveLineItems = [];

    isCSSLoaded = false;

    receiveItemType;


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
    connectedCallback() {
        //Subscribe to the message channel
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
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.poDataToRefresh = result;
        if (result.data) {
            console.log('PO Data', result.data);
            console.log('status of PO >>', JSON.stringify(result.data.fields.Status__c.value));
            this.statusValue = result.data.fields.Status__c.value;
            this.shipLocation = result.data.fields.ShipTo_Location__c.value;
            this.shipToName = result.data.fields.ShipTo_Name__c.value;
            console.log('this.Location >>', this.shipToName);
            console.log('this.Location >>', this.shipLocation);
            this.shipType = result.data.fields.ShipTo_Type__c.value;
            console.log('this.shipType >>', this.shipType);
            if (this.statusValue === 'Draft') {
                this.showitems = false;
                this.salesLabel = 'Sales/Misc Items';
                this.assetLabel = 'Asset';
            }
            else {
                this.showitems = true;
            }
            if (this.statusValue === 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') {
                this.showRemoveAssetButton = true;

            }

            if (this.statusValue === 'Received' || this.statusValue === 'Cancelled') {
                this.enabledRowCount = 0;
                this.isCancelledReceived = true;
                this.assetcolumns = assetcolumns2;
            }
            else {
                this.enabledRowCount = '';
                this.isCancelledReceived = false;
            }


            //Get PO Line Items
            // getPOLineItems({ purchaseOrderID: this.recordId })
            //     .then((data) => {
            //         console.log('RecordId', this.recordId);
            //         this.dataToRefresh = data;
            //         if (data) {
            //             console.log('data ===>> ', (data));
            //             this.assetlineItems = this.splitItemTypes(data, 'Asset');
            //             this.processRecords1();
            //             this.saleslineItems = this.splitItemTypes(data, 'Sales');
            //             this.processRecords();
            //             console.log('this.statusValue', this.statusValue);
            //             if (this.statusValue === 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') {
            //                 console.log('inside OPen Status');
            //                 this.salesLabel = 'Sales/Misc Items (' + this.saleslineItems.length.toString() + ')';
            //                 this.assetLabel = 'Assets (' + this.assetlineItems.length.toString() + ')';
            //             }
            //             else {
            //                 this.salesLabel = 'Sales/Misc Items';
            //                 this.assetLabel = 'Assets';
            //             }
            //         }
            //     }).catch(error => {
            //         console.log(error);
            //     });
        } else if (result.error) {
            console.log(result.error);
            this.error = result.error;
        }
    }
    @wire(getPOLineItems, { purchaseOrderID: '$recordId' })
    wiredLineItems(result) {
        this.dataToRefresh = result;
        if (result.data) {
            console.log('result.data ===>> ', (result.data));
            this.assetlineItems = this.splitItemTypes(result.data, 'Asset');
            this.processRecords1();
            this.saleslineItems = this.splitItemTypes(result.data, 'Sales');
            this.processRecords();
            console.log('this.statusValue', this.statusValue);
            if (this.statusValue === 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') {
                console.log('inside OPen Status');
                this.salesLabel = 'Sales/Misc Items (' + this.saleslineItems.length.toString() + ')';
                this.assetLabel = 'Assets (' + this.assetlineItems.length.toString() + ')';
            }
            else {
                this.salesLabel = 'Sales/Misc Items';
                this.assetLabel = 'Assets';
            }

            /*this.saleslineItems.forEach(row => {
                if(row.Status__c==='Received'){
                    this.enabledRowCount=0;
                }else{
                    this.enabledRowCount='';
                }
            });*/
        }
    }
    @wire(getUserLocation, { loggedUserId: '$userId' })
    wiredLocation({ error, data }) {
        if (data && data.length > 0) {
            this.userLocationDetail = data;
            this.profileBranch = this.userLocationDetail[0].ProfileBranche__c;
            this.branchName = this.userLocationDetail[0].ProfileBranche__r.Name;

            console.log('this.profileBranch...', this.profileBranch);
            console.log('this.branchName...', this.branchName);
            console.log('this.userLocationDetail...', this.userLocationDetail);
        }
        else if (error) {
            console.log(error);
        }
    }

    processRecords() {
        console.log('saleslineItems ', this.saleslineItems)
        this.saleslineItems = this.saleslineItems.map(item => {
            let receivedQty;
            return {
                ...item,
                controlEditField1: (item.Status__c == 'Received') ? "slds-text-color_inverse-weak" : "",
                controlEditField: (item.Status__c == 'Received') ? false : true,
                className: (item.Status__c == 'Received') ? 'slds-cell-edit slds-text-color_inverse-weak lockedRow' : 'slds-cell-edit',
                receivedQty: receivedQty
            };
        });
        this.saleslineItems = this.saleslineItems.filter(x => x.Status__c !== 'Cancelled');
    }
    processRecords1() {
        this.assetlineItems = this.assetlineItems.map(item => {
            let receivedAssetQty;
            return {
                ...item,
                controlEditField1: (item.Status__c == 'Received') ? "slds-text-color_inverse-weak" : "",
                controlEditField: (item.Status__c == 'Received') ? false : true,
                className: (item.Status__c == 'Received') ? 'slds-cell-edit slds-text-color_inverse-weak lockedRow' : 'slds-cell-edit',
                receivedAssetQty: receivedAssetQty
            };
        });
    }
    /*Start - Yash code*/
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(value);
    }
    /*End - Yash code*/


    splitItemTypes(lineItems, type) {
        var tempArray = [];

        for (var i = 0; i < lineItems.length; i++) {
            if (type == 'Asset') {
                if (lineItems[i].PO_Requisition__c != null) {
                    tempArray.push(lineItems[i]);
                }
            }
            else {
                if (lineItems[i].PO_Requisition__c == null) {
                    tempArray.push(lineItems[i]);
                }
            }
        }

        return tempArray;
    }

    async saveHandleAction(event) {
        this.showSpinner = true;
        this.okToProcess = true;
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            /* Start - Yash code */
            if (fields.Unit_Cost__c < 0) {
                const evt = new ShowToastEvent({
                    message: 'Negative values are not allowed for Unit Cost.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
            /* End - Yash code */
            return { fields };
        });
        event.detail.draftValues.forEach(x => {
            let index = this.saleslineItems.findIndex(y => y.Id === x.Id);
            /* if (x.receivedQty != null && (x.receivedQty <= this.saleslineItems[index].Quantity__c)) {
                this.saleslineItems[index].receivedQty = x.receivedQty;
            }*/
            /* ------------------------------------------------FRONT-13061 Code Start------------------------------------*/
            if (x.receivedQty != null && (x.receivedQty > this.saleslineItems[index].Quantity__c || x.receivedQty > this.saleslineItems[index].Open_Order_Qty__c)) {
                const evt = new ShowToastEvent({
                    message: 'Unable to receive items. Cannot receive more than what was ordered.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.okToProcess = false;
            }
            else {
                this.saleslineItems[index].receivedQty = x.receivedQty;
            }
            if (x.Unit_Cost__c != null && x.Unit_Cost__c != this.saleslineItems[index].Unit_Cost__c) {
                const evt = new ShowToastEvent({
                    message: 'Receipt amount does not equal original PO amount. Please confirm this is correct before proceeding.',
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.saleslineItems[index].Unit_Cost__c = x.Unit_Cost__c;
            }
            console.log('x.Unit_Cost__c', x.Unit_Cost__c);
            console.log('this.saleslineItems[index].Last_Cost__c', this.saleslineItems[index].Unit_Cost__c);
            if (this.saleslineItems[index].Last_Cost__c != null && this.saleslineItems[index].Last_Cost__c != 0 && x.Unit_Cost__c != null && x.Unit_Cost__c > this.saleslineItems[index].Last_Cost__c) {
                var percentage = ((x.Unit_Cost__c - this.saleslineItems[index].Last_Cost__c) / this.saleslineItems[index].Last_Cost__c) * 100;
                const evt = new ShowToastEvent({
                    message: 'Cost for ' + this.saleslineItems[index].Item_Number__c + ' is ' + percentage.toFixed(2) + '% more than last cost in file',
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
            if (this.saleslineItems[index].Last_Cost__c != null && this.saleslineItems[index].Last_Cost__c != 0 && x.Unit_Cost__c != null && x.Unit_Cost__c < this.saleslineItems[index].Last_Cost__c) {
                var percentage = ((this.saleslineItems[index].Last_Cost__c - x.Unit_Cost__c) / this.saleslineItems[index].Last_Cost__c) * 100;
                const evt = new ShowToastEvent({
                    message: 'Cost for ' + this.saleslineItems[index].Item_Number__c + ' is ' + percentage.toFixed(2) + '% less than last cost in file',
                    variant: 'warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
            /* ------------------------------------------------FRONT-13061 Code Start------------------------------------*/
            if (x.Unit_Cost__c != null && x.Unit_Cost__c === this.saleslineItems[index].Unit_Cost__c) {
                this.saleslineItems[index].Unit_Cost__c = x.Unit_Cost__c;
            }
            if (!Number.isNaN(this.saleslineItems[index].receivedQty)) {
                console.log('Qty--->',this.saleslineItems[index].receivedQty);
                //this.saleslineItems[index].Total_Cost_Calc__c= ((this.saleslineItems[index].receivedQty)*(this.saleslineItems[index].Unit_Cost__c));
                this.saleslineItems[index].extendedCost = ((this.saleslineItems[index].receivedQty) * (this.saleslineItems[index].Unit_Cost__c));
            }
        });

        try {
            if (this.okToProcess) {
                this.handleReceivedQty();
                this.template.querySelector('lightning-datatable').draftValues = [];
            }
        }
        catch (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: 'Error in Updating Records',
                    variant: 'error'
                })
            );
        };
        this.showSpinner = false;
    }
    async saveAssetHandleAction(event) {
        this.showSpinner = true;
        this.okToProcess = true;
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);

            return { fields };
        });
        event.detail.draftValues.forEach(x => {
            let index = this.assetlineItems.findIndex(y => y.Id === x.Id);
            console.log('index---', index);
            /*if (x.receivedAssetQty != null && x.receivedAssetQty <= this.assetlineItems[index].Quantity__c) {
                this.assetlineItems[index].receivedAssetQty = x.receivedAssetQty;
                console.log('Qty---', this.assetlineItems[index].receivedAssetQty);
            }*/
            if (x.receivedAssetQty != null && (x.receivedAssetQty > this.assetlineItems[index].Quantity__c || x.receivedAssetQty > this.assetlineItems[index].Open_Order_Qty__c)) {
                const evt = new ShowToastEvent({
                    message: 'Unable to receive items. Cannot receive more than what was ordered.',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
                this.okToProcess = false;
            }
            else {
                this.assetlineItems[index].receivedAssetQty = x.receivedAssetQty;
            }
            if (!Number.isNaN(this.assetlineItems[index].receivedAssetQty)) {
                //this.assetlineItems[index].Total_Cost_Calc__c= ((this.assetlineItems[index].receivedAssetQty)*(this.assetlineItems[index].Unit_Cost__c));
                this.assetlineItems[index].extendedCost = ((this.assetlineItems[index].receivedAssetQty) * (this.assetlineItems[index].Unit_Cost__c));
            }
            //console.log('Total---',this.assetlineItems[index].Total_Cost_Calc__c);
            console.log('Total---', this.assetlineItems[index].extendedCost);
        });
        this.handleAssetReceiveQty();
        try {
            if (this.okToProcess) {
                this.template.querySelector('[data-id="AssetTable"]').draftValues = [];
            }
        }
        catch (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: 'Error in Updating Records',
                    variant: 'error'
                })
            );
        };
        this.showSpinner = false;
    }

    handleEditPO() {
        this.showEditPOComponent = true;
    }
    handleAutoFill() {
        this.saleslineItems = this.reloadSalesLineItems(this.saleslineItems);
        this.handleReceivedQty();
    }
    reloadSalesLineItems(oldList) {
        console.log('Inside Reload');
        var tempArray = [];
        for (var i = 0; i < oldList.length; i++) {
            tempArray.push(oldList[i]);
        }
        if (this.statusValue == 'Open') {
            console.log('Inside Open Status');
            this.selectedRows.forEach(x => {
                let index = tempArray.findIndex(y => y.Id === x.Id);
                tempArray[index].receivedQty = x.Quantity__c;
                tempArray[index].Unit_Cost__c = x.Unit_Cost__c;
                //tempArray[index].Total_Cost_Calc__c=((tempArray[index].receivedQty)*(tempArray[index].Unit_Cost__c));
                tempArray[index].extendedCost = ((tempArray[index].receivedQty) * (tempArray[index].Unit_Cost__c));
                //console.log('this.saleslineItems[index].receivedQty',tempArray[index].Total_Cost_Calc__c);
                console.log('this.saleslineItems[index].receivedQty', tempArray[index].extendedCost);
            });
        }
        if (this.statusValue == 'Back Order') {
            console.log('Inside Back Order Status');
            this.selectedRows.forEach(x => {
                let index = tempArray.findIndex(y => y.Id === x.Id);
                tempArray[index].receivedQty = x.Open_Order_Qty__c;
                tempArray[index].Unit_Cost__c = x.Unit_Cost__c;
                console.log('this.saleslineItems[index].receivedQty', tempArray[index].receivedQty);
            });
        }
        if (this.statusValue == 'Partially Received') {
            console.log('Inside Back Order Status');
            this.selectedRows.forEach(x => {
                let index = tempArray.findIndex(y => y.Id === x.Id);
                tempArray[index].receivedQty = x.Open_Order_Qty__c;
                tempArray[index].Unit_Cost__c = x.Unit_Cost__c;
                console.log('this.saleslineItems[index].receivedQty', tempArray[index].receivedQty);
            });
        }
        return tempArray;
    }
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.activeSectionsMessage = openSections;
    }

    handleSalesRowChange(event) {
        this.selectedRowIds = [];
        this.selectedRows = [];
        console.log('inside salesrowChange Method');
        event.detail.selectedRows.forEach(row => {
            if (row.Status__c == 'Open' || row.Status__c == 'Back Order' || row.Status__c == 'Partially Received' || row.Status__c == 'Draft' || row.Status__c == null) { //use your condition here
                //the datatable only needs the row id
                this.selectedRowIds = [...this.selectedRowIds, row.Id];
                //but to be able to acess the selected records you need to save them in a different variable
                this.selectedRows.push(row);
            }
        });
        this.handleReceivedQty();
    }
    handleAssetRowChange(event) {
        this.selectedRowAsset = [];
        this.selectedRowIdsAsset = [];
        console.log('Inside Asset Row Change');
        event.detail.selectedRows.forEach(row => {
            if (row.Status__c == 'Open' || row.Status__c == 'Back Order' || row.Status__c == 'Partially Received' || row.Status__c == 'Draft' || row.Status__c == null) { //use your condition here
                //the datatable only needs the row id
                this.selectedRowIdsAsset = [...this.selectedRowIdsAsset, row.Id];
                //but to be able to acess the selected records you need to save them in a different variable
                this.selectedRowAsset.push(row);
            }
        });

        console.log('selectedRows', JSON.stringify(this.selectedRowAsset));
        this.handleAssetReceiveQty();
    }
    /*Start - Yash code*/
    handleReceivedQty() {
        if (this.selectedRows.length > 0) {
            this.Buttontrue = false;
        } else {
            this.Buttontrue = true;
        }
        let POLids = new Set();
        var rcdQty = 0;
        var rcdAmt = 0;
        for (let i = 0; i < this.selectedRows.length; i++) {
            POLids.add(this.selectedRows[i].Id);
            console.log('POLids', POLids);
            console.log('extended cost-->',this.selectedRows[i].extendedCost);

            // Allow negative values for receivedQty
            rcdQty = rcdQty + Number(this.selectedRows[i].receivedQty || 0);

            if (this.selectedRows[i].Unit_Cost__c != null && this.selectedRows[i].receivedQty != null && this.selectedRows[i].receivedQty != undefined) {
                // Allow negative values for Unit_Cost__c
                this.selectedRows[i].extendedCost = ((this.selectedRows[i].receivedQty || 0) * (this.selectedRows[i].Unit_Cost__c || 0));
                console.log('this.selectedRows[i].Unit_Cost__c', this.selectedRows[i].receivedQty);
                console.log('this.selectedRows[i].Unit_Cost__c', this.selectedRows[i].Unit_Cost__c);
                console.log('this.saleslineItems[i].extendedCost', this.selectedRows[i].extendedCost);

                rcdAmt = rcdAmt + this.selectedRows[i].extendedCost;
            }

            console.log('rcdAmt---->', rcdAmt);
        }

        this.rowIds = Array.from(POLids);
        this.totalSalesQty = rcdQty.toFixed(2);
        console.log('rcdQty', rcdQty);
        this.totalSalesCost = rcdAmt;
        this.totalSalesCost = this.formatCurrency(this.totalSalesCost);
    }
    /*End - Yash code*/

    handleAssetReceiveQty() {
        if (this.selectedRowAsset.length > 0) {
            this.AssetButtontrue = false;
            console.log('inside if', this.AssetButtontrue);
        } else {
            this.AssetButtontrue = true;
        }

        let POLids = new Set();
        var rcdQty = 0;
        var rcdAmt = 0;
        for (let i = 0; i < this.selectedRowAsset.length; i++) {
            POLids.add(this.selectedRowAsset[i].Id);
            console.log('POLids', POLids);
            if (this.selectedRowAsset[i].receivedAssetQty >= 0) {
                rcdQty = rcdQty + Number(this.selectedRowAsset[i].receivedAssetQty);
                console.log('rcdQty--->', rcdQty);
            }
            /*if(this.selectedRows[i].receivedAssetQty=='' || this.selectedRows[i].receivedAssetQty==null || this.selectedRows[i].receivedAssetQty==undefined){
                 this.selectedRows[i].receivedAssetQty=0;
            }*/
            console.log('this.assetlineItems[i].Unit_Cost__c', this.selectedRowAsset[i].Unit_Cost__c);
            if (this.selectedRowAsset[i].Unit_Cost__c >= 0 && this.selectedRowAsset[i].receivedAssetQty != '' && this.selectedRowAsset[i].receivedAssetQty != null && this.selectedRowAsset[i].receivedAssetQty != undefined) {
                //this.assetlineItems[i].Total_Cost_Calc__c= ((this.assetlineItems[i].receivedAssetQty)*(this.assetlineItems[i].Unit_Cost__c));
                this.selectedRowAsset[i].extendedCost = ((this.selectedRowAsset[i].receivedAssetQty) * (this.selectedRowAsset[i].Unit_Cost__c));
                //console.log('Total_Cost_Calc__c---->',this.assetlineItems[i].Total_Cost_Calc__c);
                //rcdAmt=rcdAmt+this.selectedRowAsset[i].Total_Cost_Calc__c;
                rcdAmt = rcdAmt + this.selectedRowAsset[i].extendedCost;
            }
            console.log('rcdQty---->', rcdQty);
            console.log('rcdAmt---->', rcdAmt);
        }
        this.rowIds = Array.from(POLids);
        this.totalAssetQty = rcdQty;
        this.totalAssetsCost = rcdAmt;
        this.totalAssetsCost = this.formatCurrency(this.totalAssetsCost);
    }
    handleRowLevelAct(event) {
        const record = event.detail.row;
        const actionName = event.detail.action.name;

        console.log('Row Id', record.Id);
        console.log(actionName);
        this.selectedPOlineItem = record.Id;

        switch (actionName) {
            /*case 'edit':
                this.openEditModal(record.Id, record.Item_Description_Calc__c, record.Last_Cost__c, record.Unit_Cost__c,record.Purchase_Order__c);
                break;*/

            case 'sales_history':
                // TBD - this may not be implemented here
                break;

            case 'remove':
                //this.deleteRow(record.Id);
                this.showModalOnCancelBOQty = true
                break;
        }
    }

    async openEditModal(recordId, modalHeader, lastCost, unitCost, pid) {
        console.log(lastCost);
        console.log(unitCost);

        // if modal closed with X button, promise returns result = 'undefined'
        // if modal closed with OK button, promise returns result = 'okay'
        const result = await editRecordModal.open({
            // `label` is not included here in this example.
            // it is set on lightning-modal-header instead
            size: 'medium',
            modalHeader: modalHeader,
            description: 'Accessible description of modal\'s purpose',
            recordId: recordId
        });

        if (result == "OK") {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record was updated successfully',
                    variant: 'success'
                })
            );
            refreshApex(this.dataToRefresh);
        }
    }

    async deleteRow(recordId) {
        this.showLoadingSpinner = true;
        deleteRecord(recordId)
            .then(() => {
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Line Item has been deleted successfully',
                        variant: 'success'
                    })
                );

                refreshApex(this.dataToRefresh);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while deleting record',
                        message: error.body.message,
                        variant: 'success'
                    })
                );
            });
    }


    /* -----------------------------------------------Sachin Code Starts------------------------------------------------------------ */

    // Delete PO Line Items confirmation modal
    // Author : Sachin Khambe 
    // User Story : FRONT-15116 >> FRONT-15725 

    @track isModalOpen = false;

    handleModalState() {
        this.isModalOpen = false;
    }

    handleOpenReceiveItemModal(event) {
        this.receiveItemType = event.currentTarget.dataset.value;
        this.receiveLineItems = [];
        if (this.receiveItemType === 'Sale') {
            let selRows = Array.from(this.template.querySelector('[data-id="SaleItemTable"]').selectedRows);
            if (selRows && selRows.length > 0) {
                selRows.forEach(x => {
                    if (this.saleslineItems.some(element => element.Id === x &&
                        !(element.hasOwnProperty('Status__c') && element.Status__c.toUpperCase() === 'RECEIVED') &&
                        (element.receivedQty && element.receivedQty > 0))) {
                        this.receiveLineItems.push(this.saleslineItems.find(element => element.Id === x));
                    }
                })
            }
        }
        if (this.receiveItemType === 'Asset') {
            let selRows = Array.from(this.template.querySelector('[data-id="AssetTable"]').selectedRows);
            if (selRows && selRows.length > 0) {
                selRows.forEach(x => {
                    if (this.assetlineItems.some(element => element.Id === x &&
                        !(element.hasOwnProperty('Status__c') && element.Status__c.toUpperCase() === 'RECEIVED') &&
                        (element.receivedAssetQty && element.receivedAssetQty > 0))) {
                        this.receiveLineItems.push(this.assetlineItems.find(element => element.Id === x));
                    }
                })
            }
        }
        if (this.receiveLineItems.length > 0) {
            this.openReceiveItemModal = true;
        }
    }

    handleCloseReceiveItemModal(event) {
        if (event.detail.action.toUpperCase() !== 'CANCEL') {
            const succesEvent = new ShowToastEvent({
                title: 'Success',
                message: 'The item(s) were successfully received. Navigate to Receipts to print if needed.',
                variant: 'success'
            });
            this.dispatchEvent(succesEvent);
            refreshApex(this.dataToRefresh);
            refreshApex(this.poDataToRefresh);
            if (event.detail.receiveItemType.toUpperCase() === 'SALE') {
                this.template.querySelector('[data-id="SaleItemTable"]').selectedRows = [];
                this.totalSalesQty = '';
                this.totalSalesCost = '';
                this.Buttontrue = true;
            }
            else if (event.detail.receiveItemType.toUpperCase() === 'ASSET') {
                this.template.querySelector('[data-id="AssetTable"]').selectedRows = [];
                this.totalAssetQty = '';
                this.totalAssetsCost = '';
                this.AssetButtontrue = true;
            }
        }
        this.openReceiveItemModal = false;
    }

    handleYesButton() {
        this.isModalOpen = false;
        console.log('rowIds ====> ' + this.rowIds);

        deletePOLineItems({ selectedRowIDs: this.rowIds })
            .then(result => {
                console.log('result ====> ' + result);

                // showing success message
                if (result == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!!',
                            message: ' PO Line Items are deleted.',
                            variant: 'success'
                        }),
                    );
                }
                // Clearing selected row indexs 
                this.template.querySelector('lightning-datatable').selectedRows = [];

                return refreshApex(this.dataToRefresh);

            })
            .catch(error => {
                window.console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while getting PO Line Items',
                        message: error.message,
                        variant: 'error'
                    }),
                );
            });
    }



    /* -----------------------------------------------Sachin Code Starts------------------------------------------------------------ */

    /* -----------------------------------------------Vishesh Code Starts------------------------------------------------------------ */

    handleCreatePOButton(event) {
        console.log('openCreateModal--', this.openCreateModal);
        this.openCreateModal = true;
        console.log('openCreateModal--', this.openCreateModal);
    }

    /* -----------------------------------------------Vishesh Code Ends------------------------------------------------------------ */
    handleSaveOnAddPOL() {
        refreshApex(this.dataToRefresh);


    }
    async handleReload() {
        console.log('Inside reload');
        refreshApex(this.dataToRefresh);
    }
    handleAddLineItem(event) {

        this.addLineItem();
    }
    async modalCloseHandler() {
        console.log('Test');
        refreshApex(this.dataToRefresh);
        this.openCreateModal = false;
    }

    /**
     *  Added by Nikhil as a part of FRONT-11934
     ***/
    getRowActions(row, doneCallback) {
        const actions = [];

        if (this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') {
            if (row.Status__c === 'Back Order' || row.Status__c === 'Partially Received') {
                actions.push({
                    label: 'Cancel B/O', name: 'remove'
                })
            } else {
                actions.push({
                    label: 'Cancel B/O', name: 'remove', disabled: true
                })
            }
        } else {
            actions.push({
                label: 'Cancel B/O', name: 'remove', disabled: true
            })
        }
        doneCallback(actions);
    }

    handleBackOrderModalClose(event) {
        this.showModalOnCancelBOQty = false;
    }

    handleBackOrderModal(event) {
        this.showModalOnCancelBOQty = false;

        removeBackOrderQtyStatus({ selectedRowID: this.selectedPOlineItem })
            .then((result) => {
                console.log('result ====> ' + result);
                refreshApex(this.dataToRefresh);
                updatePOStatusToReceived({ recordId: this.recordId })
                    .then((result) => {
                        console.log('result PO ====> ' + result);
                        refreshApex(this.poDataToRefresh);
                        getRecordNotifyChange([{ recordId: this.recordId }]);
                    })
                    .catch((error) => {
                        console.log('error ====> ' + error);
                    });
            })
            .catch((error) => {
                console.log('error ====> ' + error);
                window.console.log(error);
            });
    }
    /*************************************End code of FRONT-11934***************************************/
}