import { LightningElement, api, wire, track } from 'lwc';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord, deleteRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import editRecordModal from 'c/sbr_3_0_poLineItemEditModal';
import deletePOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.deletePOLineItems';
import cancelPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItems';
import cancelPOLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItem';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Type__c']

const actions = [
    //{ label: 'View Sales History', name: 'sales_history', disabled:true},
    { label: 'Remove', name: 'remove' },
    { label: 'Cancel Item', name: 'Cancel Item' }
];

const assetcolumns2 = [
    {
        label: 'Item Number', type: 'button', typeAttributes: {
            label: { fieldName: "Item_Number__c" },
            name: "edit",
            variant: "base",
            disabled: true
        }
    },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
    { label: 'Qty', fieldName: 'Quantity__c', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },
    { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },
]

export default class Sbr_3_0_purchaseOrderLineItems extends LightningElement {
    subscription;
    @wire(MessageContext)
    messageContext
    @api recordId;
    @api itemtype;
    colDisplay5 = [];
    colDisplay4 = [];
    sumOfUnitCost = 0;
    /*sumOfQuantity = 0; */
    fldsItemValues = [];
    lineItems = [];
    assetlineItems = [];
    saleslineItems = [];
    isMisc = false;
    cardTitle = '';
    cardIcon = '';
    inputvalue;
    Buttontrue = true;
    AssetButtontrue = true;
    actions = actions;
    showAddLineItemButton = false;
    enabledRowCount;
    createnewItemButton = false;
    isCancelledReceived = true;
    selectedRowIds = [];
    selectedSalesRows = [];
    isOneStepPO = false;
    openEditScreen = false;
    lineItemRecId;
    removeItemsSalesList = [];
    removeItemsAssetsList = [];
    selSalesItemsCount;
    showSalesSelectAll = false;

    columns = [
        {
            label: 'Item Number',
            type: 'button',
            typeAttributes: {
                label: { fieldName: "Item_Number__c" },
                name: "edit",
                variant: "base",
                disabled: { fieldName: 'lineItemDisabled' }
            }, cellAttributes: { class: { fieldName: 'controlEditField1' } }
        },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Item Status', fieldName: 'Status__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Qty', fieldName: 'Quantity__c', editable: { fieldName: 'isEditable' }, cellAttributes: { alignment: 'right', class: { fieldName: 'className' }, style: { fieldName: 'cellStyle' } }, displayReadOnlyIcon: '!controlEditField', type: 'number', typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', editable: { fieldName: 'isEditable' }, type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'className' }, style: { fieldName: 'cellStyle' } }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
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
            label: 'Item Number', type: 'button', typeAttributes: {
                label: { fieldName: "Item_Number__c" },
                name: "edit",
                variant: "base",
                disabled: true
            }, cellAttributes: { class: { fieldName: 'controlEditField1' } }
        },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Item Status', fieldName: 'Status__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'className' }, style: { fieldName: 'cellStyle' } }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'className' }, style: { fieldName: 'cellStyle' } }, displayReadOnlyIcon: '!controlEditField', typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
    ];

    /*Start - Yash code*/
    assetcolumns = [
        { label: 'Item Number', fieldName: 'Item_Number__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c', cellAttributes: { class: { fieldName: 'controlEditField1' } } },
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', editable: false, cellAttributes: { alignment: 'right', class: { fieldName: 'className' }, style: { fieldName: 'cellStyle' } }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, editable: false, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right', class: { fieldName: 'controlEditField1' } }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
        {
            type: 'action',
            typeAttributes: {
                menuAlignment: 'right',
                rowActions: this.getRowActionsAsset.bind(this)
            }
        }
    ];
    /*End - Yash code*/

    //assetcolumns = assetcolumns;
    selectedRowId;
    selectedRows = [];
    selectedRowsStatus = [];
    selectedRowsQuantity = [];
    showEditPOComponent = false;
    openModal = false;
    openModal2 = false;
    draftValues = [];
    dataToRefresh;
    data2 = [];
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
    openCreateModalDraft = false;
    activeSections = ['Sales', 'Asset'];
    companyCode;
    record = [];
    salesRecordList = [];
    assetsRecordList = [];
    rowIds = [];
    cancelStatus = false;
    POdataToRefresh = [];
    showRemoveSalesButton = false;
    showCancelSalesButton = false;
    showRemoveAssetButton = false;
    statusValue;
    poType;
    temp = [];
    selectedRows = [];
    showRemoveMobile = false;
    showRemoveAsset = false;
    showRemoveSalesMobile = false;
    tempSales;
    tempAsset;
    isEditClose = false;
    showRemoveModal = false;
    @track removeItems = [];



    isCSSLoaded = false;
    renderedCallback() {
        if (!this.isCSSLoaded) {
            loadStyle(this, POLWCCSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
        if(this.isEditClose){
            this.createRecordListForMobile(this.saleslineItems, 'Sales');
            this.createRecordListForMobile(this.assetlineItems, 'Asset');
            this.isEditClose = false;
        }
    }
    connectedCallback() {
        this.processRecords;
        //Subscribe to the message channel
        this.subscription = subscribe(this.messageContext, PurchaseOrderLineItemMessageChannel,
            (result) => {
                if (result != undefined) {
                    let recId = result.recordId;
                    let recUpd = result.recordUpdated;
                    if (recUpd == true) {
                        this.recordId = recId;
                        refreshApex(this.dataToRefresh);
                        refreshApex(this.POdataToRefresh);
                    }
                }
            }
            , { scope: APPLICATION_SCOPE }
        );
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
        //return true;
    }
    // handleRefresh(){
    // refreshApex(this.dataToRefresh);
    // refreshApex(this.POdataToRefresh);
    // }
    handleSalesCheckboxChange(event) {
        const recordId = event.detail.id;
        console.log('recordId:', recordId);
        //Push to array when checkbox is checked
        if (event.detail.checked) {
            this.selectedSalesRows.push(recordId);
        }
        else {
            //Remove from array when checkbox is unchecked
            let index = this.selectedSalesRows.indexOf(recordId);
            if (index > -1) {
                this.selectedSalesRows.splice(index, 1);
            }
        }
        console.log('selectedSalesRows', JSON.stringify(this.selectedSalesRows));
        if (this.selectedSalesRows.length > 0) {
            this.showRemoveSalesMobile = true;
            this.showSalesSelectAll = true;
            this.selSalesItemsCount = this.selectedSalesRows.length;
        }
        else {
            this.showRemoveSalesMobile = false;
            this.selSalesItemsCount = 0;
            this.showSalesSelectAll = false;
        }
        if (this.selectedSalesRows.length == this.saleslineItems.length) {
            this.showSalesSelectAll = false;
        }
    }


    handleAssetCheckboxChange(event) {
        const recordId = event.detail.id;
        console.log('recordId:', recordId);
        //Push to array when checkbox is checked
        if (event.detail.checked) {
            this.selectedRows.push(recordId);
        }
        else {
            //Remove from array when checkbox is unchecked
            let index = this.selectedRows.indexOf(recordId);
            if (index > -1) {
                this.selectedRows.splice(index, 1);
            }
        }
        console.log('selectedRows', JSON.stringify(this.selectedRows));
        if (this.selectedRows.length > 0) {
            this.showRemoveAsset = true;
        }
        else {
            this.showRemoveAsset = false;
        }
    }

    handleSalesItemRemove(event) {
         console.log('staretd event');
        let recordId = event.detail.id;
        //console.log('recordId:', recordId);
         console.log('record id', this.recordId );
        let removeItemsArray = [];
        if (this.selectedSalesRows.length > 0) {
            removeItemsArray = this.saleslineItems.filter(x => this.selectedSalesRows.includes(x.Id));
            console.log('inside selected rows');
        }
        else if (this.saleslineItems.length > 0) {
            removeItemsArray = this.saleslineItems.filter(x => x.Id == this.recordId);
        }
        else {
            removeItemsArray = this.saleslineItems;
             console.log('inside removeitems arrauys');
        }
        this.removeItems = removeItemsArray;
        this.showRemoveModal = true;
    }

    handleAssetItemRemove(event) {
        let recordId = event.detail.id;
        console.log('recordId:', recordId);
        let removeItemsArray = [];
        if (this.selectedAssetRows.length > 0) {
            removeItemsArray = this.assetlineItems.filter(x => this.selectedAssetRows.includes(x.Id));
        }
        else if (this.assetlineItems.length > 0) {
            removeItemsArray = this.assetlineItems.filter(x => x.Id == recordId);
        }
        else {
            removeItemsArray = this.assetlineItems;
        }
        this.removeItems = removeItemsArray;
        this.showRemoveModal = true;
    }
    createRecordListForMobile(records, type) {
        this.salesRecordList = [];
        this.assetsRecordList = [];
        this.removeItemsSalesList = [];
        this.removeItemsAssetsList = [];
        if (records.length > 0) {
            records.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.isHeaderLink = true;
                record.isEditEnabled = true;
                record.headerText = rec.Item_Number__c;
                record.hasCheckbox = true;
                record.hasSelectEvent = false;
                record.hasStatus = false;
                record.hasSearch = false;
                record.isVendorFilter = false;
                record.isPurchaseOrderFilter = false;
                record.hasButtonsMenu = true;
                record.noHeaderSection = true;
                let menuItems = [];
                let menuItem = {};
                menuItem.label = 'Remove';
                menuItem.value = 'remove';
                menuItems.push(menuItem);
                record.menuItems = menuItems;
                let columns = [];
                /*let col={};
                col.type = 'button';
                col.key = 0;
                col.label='Item Number';
                col.value=rec.Item_Number__c;
                columns.push(col);*/

                let col1 = {};
                col1.type = 'text';
                col1.key = 1;
                col1.label = 'Item Description';
                col1.value = rec.Item_Description_Calc__c;
                columns.push(col1);

                let col2 = {};
                col2.type = 'number';
                col2.key = 2;
                col2.label = 'Qty';
                col2.value = rec.Quantity__c.toFixed(2);
                columns.push(col2);
                record.columns = columns;

                let col3 = {};
                col3.type = 'currency';
                col3.key = 3;
                col3.label = 'Unit Cost';
                col3.value = rec.Unit_Cost__c.toFixed(3);
                columns.push(col3);
                record.columns = columns;

                let col4 = {};
                col4.type = 'currency';
                col4.key = 4;
                col4.label = 'Extended Cost';
                col4.value = rec.Total_Cost_Calc__c;
                columns.push(col4);
                record.columns = columns;
                if (type == 'Sales') {
                    this.salesRecordList.push(record);
                }
                else if (type == 'Asset') {
                    this.assetsRecordList.push(record);
                }
            });
        }
        if (type == 'Sales' && this.salesRecordList.length > 0) {
            this.template.querySelector('[data-id="salesCmp"]').refreshRecords(this.salesRecordList);
        }
        else if (type == 'Asset' && this.assetsRecordList.length > 0) {
            this.template.querySelector('[data-id="assetCmp"]').refreshRecords(this.assetsRecordList);
        }
    }
    handleRowSelect(event) {
        const record = event.detail.record;

    }
    
    @wire(getPOLineItems, { purchaseOrderID: '$recordId' })
    wiredLineItems(result) {
        this.dataToRefresh = result;

        if (result.data) {
            console.log('result.data ===>> ', (result.data));
            this.assetlineItems = this.splitItemTypes(result.data, 'Asset');
            this.saleslineItems = this.splitItemTypes(result.data, 'Sales');
            this.totalSalesQty = this.saleslineItems.reduce((sum, record) => sum + (record.Quantity__c || 0), 0);
            this.totalSalesQty = this.totalSalesQty.toFixed(2);
            this.totalAssetQty = this.assetlineItems.reduce((sum, record) => sum + (record.Quantity__c || 0), 0);
            this.totalAssetQty = this.totalAssetQty.toFixed(2);
            this.totalSalesCost = this.saleslineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
            this.totalAssetsCost = this.assetlineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
            this.salesLabel = 'Sales/Misc Items (' + this.saleslineItems.length.toString() + ')';
            this.assetLabel = 'Assets (' + this.assetlineItems.length.toString() + ')';
            this.totalSalesCost = this.formatCurrency(this.totalSalesCost);
            this.totalAssetsCost = this.formatCurrency(this.totalAssetsCost);

            this.data2 = result.data;
            console.log('DatatoRefresh ===>> ', this.data2);
            this.processRecords();
            Object.preventExtensions(this.data2);

            /*--------------------------------Vishesh Code Start---------------------------------------------------*/
            /*this.saleslineItems.forEach(row => {
                if(row.Status__c==='Cancelled'){
                    this.enabledRowCount=0;
                }else{
                    this.enabledRowCount='';
                }
            });*/
            /*--------------------------------Vishesh Code End---------------------------------------------------*/
            /*Start - Yash code*/
            this.processRecords1();
            this.processAssetRecords();
            /*End - Yash code*/
            if (this.isMobileView) {
                this.createRecordListForMobile(this.saleslineItems, 'Sales');
                this.createRecordListForMobile(this.assetlineItems, 'Asset');
            }
        }
    }

    /*Start - Yash code*/
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(value);
    }
    /*End - Yash code*/

    processRecords1() {
        this.saleslineItems = this.saleslineItems.map(item => {
            /*Start - Yash code*/
            var isEditable = item.Status__c != 'Received';
            /*End - Yash code*/
            return {
                ...item,
                controlEditField1: (item.Status__c == 'Received') ? "slds-text-color_inverse-weak" : "",
                controlEditField: (item.Status__c == 'Received') ? false : true,
                accountDisabled: (item.Status__c == 'Received') ? true : false,
                className: (item.Status__c == 'Received') ? 'slds-cell-edit slds-text-color_inverse-weak lockedRow' : 'slds-cell-edit',
                /*Start - Yash code*/
                isEditable: isEditable,
                cellStyle: isEditable ? '' : 'padding-right: 9px;'
                /*End - Yash code*/
            };
        });
    }

    /*Start - Yash code*/
    processAssetRecords() {
        this.assetlineItems = this.assetlineItems.map(item => {
            var isEditable = item.Status__c != 'Received';
            return {
                ...item,
                controlEditField1: (item.Status__c == 'Received') ? "slds-text-color_inverse-weak" : "",
                controlEditField: (item.Status__c == 'Received') ? false : true,
                className: (item.Status__c == 'Received') ? 'slds-cell-edit slds-text-color_inverse-weak lockedRow' : 'slds-cell-edit',
                isEditable: isEditable
            };
        });
    }
    /*End - Yash code*/

    /*     wire method for fetching PO data to operate Remove Button
           US = FRONT-15116 
           Sachin Khambe */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.POdataToRefresh = result;
        if (result.data) {

            console.log('PO Data', result.data);
            console.log('status of PO >>', JSON.stringify(result.data.fields.Status__c.value));

            this.statusValue = result.data.fields.Status__c.value;
            this.poType = result.data.fields.Type__c.value;
            console.log('poType >>  : ', this.poType);
            /*
            if (this.statusValue === 'Draft') {
                this.showRemoveSalesButton = true;
                this.showRemoveAssetButton = true;
                this.isCancelledReceived = false;
            }
            else {
                this.showRemoveSalesButton = false;
                this.showRemoveAssetButton = false;
                console.log('intoo elseee..> : ');
            }

            if (this.statusValue === 'Open') {
                this.showCancelSalesButton = true;
                //this.processRecords2();
                this.cancelStatus = true;
            }
            */

            if (this.poType === 'Standard Purchase Order') {
                this.isOneStepPO = false;
                if (this.statusValue === 'Received' || this.statusValue === 'Cancelled') {
                    this.showAddLineItemButton = false;
                    this.createnewItemButton = false;
                    //this.hidecheck = true;
                    this.enabledRowCount = 0;
                    this.isCancelledReceived = true;
                    this.assetcolumns = assetcolumns2;
                    //accountDisabled=true;
                } else {
                    this.showAddLineItemButton = true;
                    this.createnewItemButton = true;
                    this.enabledRowCount = '';
                    this.isCancelledReceived = false;
                }

                if (this.statusValue === 'Draft') {
                    this.showRemoveSalesButton = true;
                    this.showRemoveAssetButton = true;
                    this.isCancelledReceived = false;
                }
                else {
                    this.showRemoveSalesButton = false;
                    this.showRemoveAssetButton = false;
                    console.log('intoo elseee..> : ');
                }

                if (this.statusValue === 'Open') {
                    this.showCancelSalesButton = true;
                    //this.processRecords2();
                    this.cancelStatus = true;
                }

                if (this.statusValue === 'Open' || this.statusValue === 'Partially Received' || this.statusValue === 'Back Order') {
                    this.assetcolumns = assetcolumns2;
                }
            }

            /* Harshal's Code Start's */
            if (this.poType === 'Standard Purchase Order - One Step') {
                console.log('intoo OS SP If >> : ');
                this.createnewItemButton = false;
                this.isOneStepPO = true;
                if (this.statusValue === 'Draft') {
                    console.log('Into Remove Button>> :', this.statusValue);

                    this.showRemoveSalesButton = true;
                    console.log('this.showRemoveSalesButton >> : ', this.showRemoveSalesButton);
                    this.showAddLineItemButton = true;
                    this.isCancelledReceived = false;
                }
                if (this.statusValue != 'Draft') {
                    console.log('Into Remove Button>> :', this.statusValue);
                    this.showAddLineItemButton = false;
                    this.showRemoveSalesButton = false;
                    this.isCancelledReceived = true;

                }
            }
            console.log('this.createnewItemButton >> 1 : ', this.createnewItemButton);
            console.log('this.showRemoveSalesButton >> 1 : ', this.showRemoveSalesButton);

        } else if (result.error) {
            console.log(result.error);
            this.error = result.error;
        }
    }
    /* Harshal's Code End's */


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
        /* -----------------------------------------------Shubham Code Starts------------------------------------------------------------ */
        try {
            this.showSpinner = true;

            const records = event.detail.draftValues.slice().map((draftValue) => {
                const fields = Object.assign({}, draftValue);
                /* Start - Yash code */
                if (fields.Unit_Cost__c < 0) {
                    throw new Error('Negative values are not allowed for Unit Cost.');
                }
                /* End - Yash code */
                return { fields };
            });

            const recordUpdatePromises = records.map((record) =>
                updateRecord(record)
            );
            await Promise.all(recordUpdatePromises);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records updated successfully',
                    variant: 'success'
                })
            );

            // Refresh the datatable
            await refreshApex(this.dataToRefresh);
            await refreshApex(this.POdataToRefresh);
            this.template.querySelector('lightning-datatable').draftValues = [];
        } catch (error) {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: error.message || 'An error occurred while updating records',
                    variant: 'error'
                })
            );
        } finally {
            this.showSpinner = false;
        }
    }
    /* -----------------------------------------------Shubham Code Ends------------------------------------------------------------ */

    handleEditPO() {
        this.showEditPOComponent = true;
    }
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.activeSections = openSections;
    }
    handleSalesRowChange(event) {
        //this.selectedRows = event.detail.selectedRows;
        this.selectedRowIds = [];
        this.selectedRows = [];
        var hasReceived = false;

        console.log('inside salesrowChange Method');
        event.detail.selectedRows.forEach(row => {
            if (row.Status__c == 'Open' || row.Status__c == 'Back Order' || row.Status__c == 'Partially Received' || row.Status__c == 'Draft' || row.Status__c == null) { //use your condition here
                //the datatable only needs the row id
                this.selectedRowIds = [...this.selectedRowIds, row.Id];
                //but to be able to acess the selected records you need to save them in a different variable
                this.selectedRows.push(row);
            }
        });

        /* Start - Yash code */
        this.Buttontrue = this.selectedRows.length === 0;
        /* End - Yash code */

        /*Sachin Khambe................*/
        let POLids = new Set();
        for (let i = 0; i < this.selectedRows.length; i++) {
            //console.log('selectedRows.length----> ' , selectedRows.length);
            POLids.add(this.selectedRows[i].Id);
            console.log('POLids set----> ', POLids);
        }

        this.rowIds = Array.from(POLids);
        console.log('rowIds---->', this.rowIds);
        console.log('rowIds---->2', JSON.stringify(this.rowIds));
        /*Sachin Khambe................*/

    }

    handleAssetRowChange(event) {
        const selectedRows = event.detail.selectedRows;
        console.log('selectedRows', selectedRows);
        if (selectedRows.length > 0) {
            this.AssetButtontrue = false;
            console.log('this.AssetButtontrue', this.AssetButtontrue);
        } else {
            this.AssetButtontrue = true;
        }

        /*Sachin Khambe................*/
        let POLids = new Set();
        for (let i = 0; i < selectedRows.length; i++) {
            console.log('selectedRows.length----> ', selectedRows.length);
            POLids.add(selectedRows[i].Id);
            console.log('POLids set----> ', POLids);
        }
        this.rowIds = Array.from(POLids);
        console.log('rowIds---->', this.rowIds);
        console.log('rowIds---->2', JSON.stringify(this.rowIds));

        /*Sachin Khambe................*/
    }

    handleRowLevelAct(event) {
        this.record = event.detail.row;
        console.log('Record', this.record); //
        this.callModal = this.record.Item_Number__c; //
        console.log('ItemNumber', this.record.Item_Number__c);
        const actionName = event.detail.action.name;

        console.log('Row Id', this.record.Id);
        console.log(actionName);

        switch (actionName) {
            case 'edit':
                this.openEditModal(this.record.Id, this.record.Item_Description_Calc__c, this.record.Last_Cost__c, this.record.Unit_Cost__c, this.record.Purchase_Order__c);
                break;

            case 'sales_history':
                // TBD - this may not be implemented here
                break;

            case 'remove':
                this.deleteRow(this.record.Id);
                break;

            case 'Cancel Item':
                this.isModalOpen3 = true;
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

    handleDeleteModal(event) {

        console.log('1..in remove item button method  ' + this.isModalOpen);
        this.isModalOpen = true;
        console.log('2..in remove item button method  ' + this.isModalOpen);


    }


    handleCancelModal(event) {

        console.log('1..in remove item button method  ' + this.isModalOpen);
        this.isModalOpen = true;
        console.log('2..in remove item button method  ' + this.isModalOpen);
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
                this.Buttontrue = true;
                refreshApex(this.dataToRefresh);

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



    /* -----------------------------------------------Sachin Code Stops------------------------------------------------------------ */

    /* -----------------------------------------------Abhishek Code Starts------------------------------------------------------------ */
    // Cancel PO Line Items confirmation modal
    // Author : Abhishek Hiremath
    // User Story : FRONT-15116 >> FRONT-20159 

    @track isModalOpen2 = false;

    handleModalState2() {
        this.isModalOpen2 = false;
    }

    handleCancelModal2(event) {


        this.isModalOpen2 = true;

    }

    handleYesButton2() {
        this.isModalOpen2 = false;
        //this.selectedRowsStatus=this.selectedRows.map(value => value.Status__c);
        this.selectedRowsQuantity = this.selectedRows.map(value => value.Quantity__c);
        console.log('Status ====> ' + this.selectedRowsStatus);
        console.log('Quantity ====> ' + this.selectedRowsQuantity);
        cancelPOLineItems({ recordId: this.recordId, selectedRowIDs: this.rowIds })
            .then(result => {
                console.log('result ====> ' + result);

                // showing success message
                if (result == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!!',
                            message: ' PO Line Items are cancelled.',
                            variant: 'success'
                        }),
                    );
                }

                this.processRecords();
                Object.preventExtensions(this.data2);
                // Clearing selected row indexs 
                this.template.querySelector('lightning-datatable').selectedRows = [];
                this.Buttontrue = true;
                refreshApex(this.dataToRefresh);

            })
            .catch(error => {
                window.console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while cancelling PO Line Items',
                        message: error.message,
                        variant: 'error'
                    }),
                );
            });
        this.processRecords();
        Object.preventExtensions(this.data2);
        //refreshApex(this.dataToRefresh);
    }

    @track isModalOpen3 = false;

    handleModalState3() {
        this.isModalOpen3 = false;
    }

    handleCancelModal3(event) {


        this.isModalOpen3 = true;

    }

    handleYesButton3() {
        this.isModalOpen3 = false;
        const rowId = this.record.Id;
        console.log('RowId', rowId);
        cancelPOLineItem({ recordId: this.recordId, selectedRowID: rowId })
            .then(result => {
                console.log('result ====> ' + result);
                // showing success message
                if (result == true) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success!!',
                            message: ' PO Line Item is cancelled.',
                            variant: 'success'
                        }),
                    );
                }
                refreshApex(this.dataToRefresh);
            })
            .catch(error => {
                window.console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while cancelling PO Line Item',
                        message: error.message,
                        variant: 'error'
                    }),
                );
            });
        this.processRecords();
        refreshApex(this.dataToRefresh);
    }

    processRecords() {
        console.log('ProcessRecords', this.saleslineItems);
        this.saleslineItems = this.saleslineItems.map(car => {
            return {
                ...car,
                lineItemDisabled: (car.Status__c === 'Cancelled' || car.Status__c === 'Received') ? true : false, /* Changes for 'Received' by Yash*/
            };
        });
    }

    processRecords2() {
        const actionButtons = [{
            'label': 'Cancel Item',
            'name': 'Cancel Item',
            disabled: { fieldName: 'removeDisabled' }
        }];
        let actions = { type: 'action', typeAttributes: { rowActions: actionButtons } };
        this.columns.pop();
        this.columns.push(actions);
        console.log('ProcessRecords', this.saleslineItems);

        this.saleslineItems = this.saleslineItems.map(car => {
            return {
                ...car,
                removeDisabled: (this.statusValue === 'Open') ? true : false
            };
        });
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        //Start - Yash code
        if (this.statusValue == 'Draft') {
            actions.push({
                label: 'Remove', name: 'remove'
            })
        } else {
            if (row.Status__c !== 'Cancelled' && row.Status__c !== 'Received') {
                actions.push({
                    label: 'Cancel Item', name: 'Cancel Item'
                })
            }
            else {
                actions.push({
                    label: 'Cancel Item', name: 'Cancel Item', disabled: true
                })
            }
        }
        doneCallback(actions);
        //End - Yash code
    }

    getRowActionsAsset(row, doneCallback) {
        let actions = [];

        if (this.statusValue === 'Draft' && row.Status__c !== 'Received') {
            actions.push(
                { label: 'Remove', name: 'remove' }
            );
        } else {
            actions.push(
                { label: 'Remove', name: 'remove', disabled: true }
            );
        }
        doneCallback(actions);
    }


    /* -----------------------------------------------Abhishek Code Stops------------------------------------------------------------ */

    /* -----------------------------------------------Vishesh Code Starts------------------------------------------------------------ */

    handleCreatePOButton(event) {
        this.openCreateModal = true;
    }

    handleCreatePOButtonDraft(event) {
        this.openCreateModalDraft = true;
    }


    /* -----------------------------------------------Vishesh Code Ends------------------------------------------------------------ */
    handleSaveOnAddPOL() {
        refreshApex(this.dataToRefresh);
    }
    async handleReload() {
        console.log('Inside reload');
        refreshApex(this.dataToRefresh);
    }
    async modalCloseHandler() {
        refreshApex(this.dataToRefresh);
        this.openCreateModal = false;
    }

    async modalCloseHandlerDraft() {
        refreshApex(this.dataToRefresh);
        this.openCreateModalDraft = false;

    }

    handleEditScreen(event) {
        this.openEditScreen = true;
        this.lineItemRecId = event.detail.recordId;
    }

    handleEditClose() {
        this.openEditScreen = false;
        this.isEditClose = true;
        refreshApex(this.dataToRefresh);
        refreshApex(this.POdataToRefresh);
    }
    handleRemoveItemClose(event) {
        this.showRemoveModal = false;
        console.log(event.detail);
    }
    handleRemoveItem(event) {
        this.showRemoveModal = false;
        console.log(event.detail.output);
        this.dispatchEvent(
            new ShowToastEvent({
                title: event.detail.output,
                message: event.detail.output == 'Success' ? 'Records updated successfully' : 'Error occurred. Please contact your administrator.',
                variant: event.detail.output == 'Success' ? 'success' : 'error'
            })
        );
        refreshApex(this.dataToRefresh);
    }

    handleSelectAllSales(event) {
        this.selectedSalesRows = [];
        let eventType = event.currentTarget.dataset.id;
        if (eventType === 'select') {
            this.saleslineItems.forEach(currentItem => {
                this.selectedSalesRows.push(currentItem.Id);
            });
            this.selSalesItemsCount = this.selectedSalesRows.length;
        }
        else {
            this.selectedSalesRows = [];
            this.showRemoveSalesMobile = false;
            this.selSalesItemsCount = this.selectedSalesRows.length;
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper').checkAll = this.showSalesSelectAll;
        this.showSalesSelectAll = !this.showSalesSelectAll;
    }
}