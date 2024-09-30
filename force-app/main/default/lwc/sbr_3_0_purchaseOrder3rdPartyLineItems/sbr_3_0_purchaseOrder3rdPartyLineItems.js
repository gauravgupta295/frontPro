import { LightningElement, api, wire, track } from 'lwc';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import editRecordModal from 'c/sbr_3_0_poLineItemEditModal';
import deletePOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.deletePOLineItems';
import cancelPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItems';
import cancelPOLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItem';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import addFreightCmp from 'c/sbr_3_0_add3rdPartyHaulerLineItemModal';
import editFreightCmp from 'c/sbr_3_0_edit3rdPartyHaulerLineItemModal';
import editStandardRecordModal from 'c/sbr_3_0_poLineItemEditModal';
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";

const FIELDS = ['Purchase_Order__c.Status__c']

const actions = [
    /*{ label: 'View Sales History', name: 'sales_history', disabled:true},*/
    { label: 'Remove', name: 'remove' },
    { label: 'Cancel Item', name: 'Cancel Item', disabled: false }
];

[
    {
        label: 'Item Number', type: 'button', typeAttributes: {
            label: { fieldName: "Item_Number__c" },
            name: "edit",
            variant: "base",
            disabled: { fieldName: 'accountDisabled' }
        }
    },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c' },
    { label: 'Item Status', fieldName: 'Status__c' },
    { label: 'Qty', fieldName: 'Quantity__c', editable: false, cellAttributes: { alignment: 'right' } },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', editable: false, type: 'number', cellAttributes: { alignment: 'right' } },
    { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },


    {
        type: 'action',
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'right',
        }
    }
];

const assetcolumns = [
    { label: 'Item Number', fieldName: 'Item_Number__c' },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c' },
    { label: 'Quantity', fieldName: 'Quantity__c', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },
    { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },
    { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true },

    {
        type: 'action',
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'right',
        }
    }
];

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
    @track saleslineItems = [];
    @track salesRecordList = [];
    isMisc = false;
    cardTitle = '';
    cardIcon = '';
    inputvalue;
    Buttontrue = true;
    AssetButtontrue = true;
    selectedRowIds = [];
    actions = actions;
    showRemoveModal = false;
    @track removeItems = [];
    @track selectedSalesRows = [];
    columns = [
        {
            label: 'Item Number', type: 'button', typeAttributes: {
                label: { fieldName: "Item_Number__c" },
                name: "edit",
                variant: "base",
                disabled: { fieldName: 'accountDisabled'}, cellAttributes: { class: { fieldName: 'controlEditField1'}}
            }
        },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c' },
        { label: 'Item Status', fieldName: 'Status__c' },
        /*Start - Yash code*/
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', editable: false, cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', editable: false, type: 'number', cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
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
            label: 'Item Number', type: 'button', typeAttributes: {
                label: { fieldName: "Item_Number__c" },
                name: "edit",
                variant: "base",
                disabled: true
            }

        },
        { label: 'Item Description', fieldName: 'Item_Description_Calc__c' },
        { label: 'Item Status', fieldName: 'Status__c' },
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', editable: false, cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 2 }  },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', editable: false, type: 'number', cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 }  },
    ];
    assetcolumns = assetcolumns;
    selectedRowId;
    showEditPOComponent = false;
    openModal = false;
    draftValues = [];
    dataToRefresh;
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
    poStatus=[];
    activeSections = ['Sales', 'Asset'];
    companyCode;
    callModal;
    record = [];
    rowIds = [];
    selectedRows = [];
    selectedRowsQuantity = [];
    POdataToRefresh;
    showRemoveSalesButton = false;
    showCancelSalesButton = false;
    showRemoveAssetButton = false;
    showRemove = false;
    statusValue;
    showAddLineItemButton = true;
    isCancelledReceived = false;
    showAddFreight = true;

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
        //Scroll to removeItemCmp div
        const removeItemCmp = this.template.querySelector('[data-id="removeItemCmp"]');
        if (removeItemCmp != undefined) {
            removeItemCmp.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
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
                        refreshApex(this.dataToRefresh);
                    }
                }
            }
        );
    }
    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    @wire(getPOLineItems, { purchaseOrderID: '$recordId' })
    wiredLineItems(result) {
        this.dataToRefresh = result;

        if (result.data) {
            console.log('result.data ===>> ', (result.data));
            //this.assetlineItems = this.splitItemTypes(result.data,'Asset');
            this.saleslineItems = this.splitItemTypes(result.data, 'Sales');
            this.totalSalesQty = this.saleslineItems.reduce((sum, record) => sum + (record.Quantity__c || 0), 0);
            this.totalSalesQty = this.totalSalesQty.toFixed(2);
            //this.totalAssetQty = this.assetlineItems.reduce((sum, record) => sum + (record.Quantity__c || 0), 0);
            this.totalSalesCost = this.saleslineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
            //this.totalAssetsCost = this.assetlineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
            this.salesLabel = '3rd Party Hauler Items (' + this.saleslineItems.length.toString() + ')';
            //this.assetLabel = 'Assets (' + this.assetlineItems.length.toString() + ')';
            this.totalSalesCost = this.formatCurrency(this.totalSalesCost);
            //this.totalAssetsCost = this.formatCurrency(this.totalAssetsCost);
            this.processRecords();
            this.processRecords1();
             if (this.isMobileView) {
                this.createRecordListForMobile(this.saleslineItems, 'Sales');
                
            }
        }
        this.Buttontrue = true;


    }
    processRecords1() {
        this.saleslineItems = this.saleslineItems.map(item => {
            return {
                ...item,
                controlEditField1: (item.Status__c == 'Received' || item.Status__c == 'Cancelled' || item.oldPOItem__c===true) ? "slds-text-color_inverse-weak" : "",
                controlEditField: (item.Status__c == 'Received') ? false : true,
                //accountDisabled: (item.Status__c == 'Received') ? true : false,
                className: (item.Status__c == 'Received' || item.Status__c == 'Cancelled' || item.oldPOItem__c==true) ? 'slds-cell-edit slds-text-color_inverse-weak lockedRow' : 'slds-cell-edit',
            };
        });
    }
    /*Start - Yash code*/
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(value);
    }
    /*End - Yash code*/
    /*     wire method for fetching PO data to operate Remove Button
           US = FRONT-15116 
           Sachin Khambe */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {

            console.log('PO Data', data);
            console.log('status of PO >>', JSON.stringify(data.fields.Status__c.value));

            this.statusValue = data.fields.Status__c.value;
        
            if (this.statusValue === 'Draft') {
                this.showRemoveSalesButton = true;
                this.showRemoveAssetButton = true;
                this.showAddFreight = true;
            }
            if (this.statusValue === 'Open') {
                this.enabledRowCount = 10;
                this.isCancelledReceived = false;
                this.showAddFreight = false;
                this.showCancelSalesButton = true;
            }
            if (this.statusValue === 'Back Order' || this.statusValue === 'Partially Received'){
                this.enabledRowCount = 10;
                this.isCancelledReceived = true;
                this.showAddFreight = false;
                this.showCancelSalesButton = true;
            }
            //else if (this.statusValue === 'Open') {
            //  this.showCancelSalesButton=true;
            //}
            if (this.statusValue === 'Cancelled' || this.statusValue === 'Received') {
                this.showAddLineItemButton = false;
                this.enabledRowCount = 0;
                this.isCancelledReceived = true;
                this.showAddFreight = false;
            }
          else {
                this.showAddLineItemButton = true;
                //this.enabledRowCount = '10';
                //this.isCancelledReceived=false;
            }

        } else if (error) {
            console.log(error);
            this.error = error;
        }

    }


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
        this.showSpinner = true;
        this.okToProcess = true;
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);

            return { fields };
        });

        try {
            if (this.okToProcess) {
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
                //refreshApex(this.refreshTable);

                // Display fresh data in the datatable
                await refreshApex(this.dataToRefresh);
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
    /* -----------------------------------------------Shubham Code Ends------------------------------------------------------------ */

    handleEditPO() {
        this.openModal = true;
    }
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.activeSectionsMessage = openSections;
    }
    handleSalesRowChange(event) {
        this.selectedRowIds = [];
        this.selectedRows = [];
        let clickableRow = [];
        console.log('inside salesrowChange Method');
        event.detail.selectedRows.forEach(row => {
            if (row.RecordTypeName__c == 'Standard_Purchase_Order' || this.statusValue === 'Draft') {
                console.log('This Is inside Row If 1');
                console.log('row.RecordTypeName__c===>', row.RecordTypeName__c);
                if (row.Status__c == 'Open' || row.Status__c == 'Partially Received' || row.Status__c == 'Draft' || row.Status__c == undefined) {
                    //the datatable only needs the row id
                    console.log('This Is inside Row If 2');
                    console.log('row.Status__c===>', row.Status__c);
                    this.selectedRowIds = [...this.selectedRowIds, row.Id];
                    //but to be able to acess the selected records you need to save them in a different variable
                    clickableRow.push(row);


                }
            }
            if (row.RecordTypeName__c != 'Standard_Purchase_Order') {
                console.log('This Is inside Row If 3');
                console.log('row.RecordTypeName__c===>', row.RecordTypeName__c);
                console.log('row.Status__c===>', row.Status__c);
                //this.enabledRowCount=0;
            }
        })
        this.selectedRows = clickableRow;
        console.log('selectedRows', this.selectedRows);
        if (this.selectedRows.length > 0) {
            this.Buttontrue = false;
            this.enabledRowCount = 10;
            console.log('this.Buttontrue', this.Buttontrue);
        } else {
            this.Buttontrue = true;
        }

        let POLids = new Set();
        for (let i = 0; i < this.selectedRows.length; i++) {
            console.log('selectedRows.length----> ', this.selectedRows.length);
            POLids.add(this.selectedRows[i].Id);
            console.log('POLids set----> ', POLids);
        }

        this.rowIds = Array.from(POLids);
        console.log('rowIds---->', this.rowIds);
        console.log('rowIds---->2', JSON.stringify(this.rowIds));

    }

    handleRowLevelAct(event) {
        this.record = event.detail.row;
        this.callModal = this.record.Item_Number__c;
        console.log('ItemNumber', this.record.Item_Number__c);
        const actionName = event.detail.action.name;

        console.log('Row Id', this.record.Id);
        console.log(actionName);
        console.log('Record type', this.record.RecordTypeName__c);
        switch (actionName) {
            case 'edit':
                this.openEditModal(this.record.Id, this.record.Item_Description_Calc__c, this.record.Last_Cost__c, this.record.Unit_Cost__c, this.record.Purchase_Order__c, this.record.RecordTypeName__c);
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
     createRecordListForMobile(records, type) {
        this.salesRecordList = [];
        this.removeItemsSalesList = [];
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
                
                this.salesRecordList.push(record);
                
            });
        }
        if (type == 'Sales' && this.salesRecordList.length > 0) {
            this.template.querySelector('[data-id="salesCmp"]').refreshRecords(this.salesRecordList);
        }
        else if (type == 'Asset' && this.assetsRecordList.length > 0) {
            this.template.querySelector('[data-id="assetCmp"]').refreshRecords(this.assetsRecordList);
        }
    }
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
            this.showRemove = true;
        }
        else {
            this.showRemove = false;
        }
    }

    async openEditModal(recordId, modalHeader, lastCost, unitCost, pid, recordType) {
        console.log(lastCost);
        console.log(unitCost);
        console.log('Record type -->', recordType);

        const str = this.callModal;
        const substr = 'FR';
        var result = '';
        console.log('Test Sub String', str.includes(substr));

        if (recordType === 'Third_Party_Hauler') {
            result = await addFreightCmp.open({
                size: "small",
                recordId: recordId,
                addFreightLabel: 'Edit Freight',
                description: 'Accessible description of modal\'s purpose'
            });
        }
        else {
            result = await editStandardRecordModal.open({
                size: 'medium',
                modalHeader: modalHeader,
                description: 'Accessible description of modal\'s purpose',
                recordId: recordId
            });
        }

        if (result == "OK") {
            console.log('OK');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record was updated successfully',
                    variant: 'success'
                })
            );
            //getRecordNotifyChange([{ recordId: recordId }]);
            refreshApex(this.dataToRefresh);
            console.log('OK');
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

    @track isModalOpen = false;

    handleModalState() {
        this.isModalOpen = false;
    }

    handleDeleteModal(event) {
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



                return refreshApex(this.dataToRefresh);

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
        return refreshApex(this.dataToRefresh);
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
                accountDisabled: (car.Status__c === 'Cancelled' || car.Status__c == 'Received' || car.oldPOItem__c==true) ? true : false,
            };
        });
        Object.preventExtensions(this.data2);
        //this.totalNoOfRecords = this.result.data.length;
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        if (this.statusValue === 'Open') {
            if (row.RecordTypeName__c === 'Standard_Purchase_Order') {
                if (row.Status__c === 'Cancelled' || row.Status__c === 'Received' || row.Status__c === 'Back Order') {
                    actions.push({
                        label: 'Cancel Item', name: 'Cancel Item', disabled: true
                    })
                }
                else {
                    actions.push({
                        label: 'Cancel Item', name: 'Cancel Item'
                    })
                }
            } else {
                actions.push({
                    label: 'Cancel Item', name: 'Cancel Item', disabled: true
                })
            }
        } else {
            actions.push({
                label: 'Remove', name: 'remove'
            })
        }
        doneCallback(actions);
    }
    /* -----------------------------------------------Abhishek Code Stops------------------------------------------------------------ */


    /*handleCreatePOButton(event) {
        console.log('openCreateModal--',this.openCreateModal);
        this.openCreateModal=true;
        console.log('openCreateModal--',this.openCreateModal);
    }*/

    async handleAddFreight() {
        console.log('into handleAddFreight');
        const result = await addFreightCmp.open({
            size: "small",
            recordId: this.recordId,
            addFreightLabel: 'Add Freight'
        });
        console.log(result);
        refreshApex(this.dataToRefresh);
    }

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
    handleSalesItemRemove(event) {
        let recordId = event.detail.id;
        console.log('recordId:', recordId);
        let removeItemsArray = [];
        if (this.selectedSalesRows.length > 0) {
            removeItemsArray = this.saleslineItems.filter(x => this.selectedSalesRows.includes(x.Id));
            console.log('inside selected rows');
        }
        else if (this.saleslineItems.length > 0) {
            removeItemsArray = this.saleslineItems.filter(x => x.Id == recordId);
        }
        else {
            removeItemsArray = this.saleslineItems;
        }
        this.removeItems = removeItemsArray;
        this.showRemoveModal = true;
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
}