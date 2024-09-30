import { LightningElement, api, wire, track } from 'lwc';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord, deleteRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import editRecordModal from 'c/sbr_3_0_editRerentLineItemModal';
import editStandardModal from 'c/sbr_3_0_editPOLineItemModal';
import deletePOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.deletePOLineItems';
import cancelPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItems';
import cancelPOLineItem from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.cancelPOLineItem';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';

import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";
const FIELDS = ['Purchase_Order__c.Status__c']

const actions = [
    //{ label: 'View Sales History', name: 'sales_history', disabled:true},
    { label: 'Remove', name: 'remove' },
    { label: 'Cancel Item', name: 'Cancel Item', disabled: false }
];


export default class Sbr_3_0_RerentPOLineItemComp extends LightningElement {
    subscription;
    @wire(MessageContext)
    messageContext
    @api recordId;
    @api itemtype;
    colDisplay5 = [];
    colDisplay4 = [];
    sumOfUnitCost = 0;
    fldsItemValues = [];
    lineItems = [];
    saleslineItems = [];
    isMisc = false;
    cardTitle = '';
    cardIcon = '';
    inputvalue;
    Buttontrue = true;
    actions = actions;
    isDraftStatus = true;
    reRentRecordList = [];
    removeItemsSalesList = [];
    selSalesItemsCount;
    @track isModalOpen2 = false;
    @track isModalOpen = false;
    showSalesSelectAll = false;


    //if PO status is "Draft"
    columns = [
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
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 2 } },
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right' }, typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },
        {
            type: 'action',
            typeAttributes: {
                menuAlignment: 'right',
                rowActions: this.getRowActions.bind(this)
            }
        }
    ];

    //if PO status is other than "Draft"
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
        { label: 'Qty', fieldName: 'Quantity__c', type: 'number', cellAttributes: { alignment: 'right' },typeAttributes: { minimumFractionDigits: 2 }},
        { label: 'Unit Cost', fieldName: 'Unit_Cost__c', type: 'number', cellAttributes: { alignment: 'right' },typeAttributes: { minimumFractionDigits: 3 } },
        { label: 'Extended Cost', fieldName: 'Total_Cost_Calc__c', type: 'currency', cellAttributes: { alignment: 'right' }, hideDefaultActions: true, typeAttributes: { minimumFractionDigits: 3 } },

    ];

    selectedRowId;
    showEditPOComponent = false;
    openModal = false;
    draftValues = [];
    dataToRefresh;
    showSpinner = false;
    okToProcess = true;
    activeSectionMessage = '';
    salesLabel;
    totalSalesQty;
    totalSalesCost;
    openCreateModal = false;
    selectedRowsQuantity = [];
    selectedSalesRows = [];
    activeSections = ['Sales'];
    companyCode;
    recordType;
    callModal;
    record = [];
    rowIds = [];
    POdataToRefresh;
    showRemoveSalesButton = false;
    showCancelSalesButton = false;
    statusValue;
    showAddLineItemButton = false;
    enabledRowCount;
    hidecheck = false;

    isCSSLoaded = false;
    openEditScreen = false;
    openEditScreenStandard = false;
    showRemoveSalesMobile = false;
    showRemoveModal = false;
    @track removeItems = [];

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
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
        if(this.isEditClose){
            this.createRecordListForMobile(this.saleslineItems);
            this.isEditClose = false;
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

    @wire(getPOLineItems, { purchaseOrderID: '$recordId' })
    wiredLineItems(result) {
        this.dataToRefresh = result;

        if (result.data) {
            console.log('result.data ===>> ', (result.data));
            this.saleslineItems = this.splitItemTypes(result.data, 'Sales');
            this.totalSalesQty = this.saleslineItems.reduce((sum, record) => sum + (record.Quantity__c || 0), 0);
            this.totalSalesQty = this.totalSalesQty.toFixed(2);
            this.totalSalesCost = this.saleslineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
            this.salesLabel = 'Rerent Items';
            this.totalSalesCost = this.formatCurrency(this.totalSalesCost);

            this.recordType = this.dataToRefresh.data.RecordTypeName__c;
            console.log('this.recordType--', this.recordType);
            this.Buttontrue = true;

            for (var i = 0; i < this.saleslineItems.length; i++) {
                //const status;
                console.log('Inside loop');
                if (this.saleslineItems[i].Status__c == 'Cancelled') {
                    this.hidecheck = true;
                } else {
                    this.hidecheck = false;
                }
            }
            this.processRecords();
            if (this.isMobileView) {
                this.createRecordListForMobile(this.saleslineItems);
            }
        }

    }
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(value);
    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            console.log('PO Data', data);

            console.log('status of PO >>', JSON.stringify(data.fields.Status__c.value));
            this.statusValue = data.fields.Status__c.value;
            if (this.statusValue === 'Draft') {
                this.showRemoveSalesButton = true;
                this.isDraftStatus = true;
            }
            else {
                this.showCancelSalesButton = false; // making this false because Cancel Item Button should not visible on Open rerent PO. - Sachin Khambe - FRONT-11936
                this.isDraftStatus = false;
            }


            if (this.statusValue === 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received' || this.statusValue === 'Cancelled' || this.statusValue === 'Received') {
                this.showAddLineItemButton = false;
                //this.hidecheck = true;
                this.enabledRowCount = 0;
                //this.processPORecords2();
            } else {
                this.showAddLineItemButton = true;
                //this.enabledRowCount = '';
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
        this.showEditPOComponent = true;
    }
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.activeSections = openSections;
    }
    handleSalesRowChange(event) {
        this.selectedRows = event.detail.selectedRows;
        console.log('selectedRows', this.selectedRows);
        if (this.selectedRows.length > 0) {
            this.Buttontrue = false;
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
        console.log('Record', this.record);
        this.callModal = this.record.Item_Number__c;
        console.log('ItemNumber', this.record.Item_Number__c);
        const actionName = event.detail.action.name;
        console.log(actionName);

        //Call Rates LWC 
        //this.callRateMethod();

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
    async openEditModal(recordId, modalHeader, lastCost, unitCost, pid, recordType) {
        console.log(lastCost);
        console.log(unitCost);
        const str = this.callModal;
        const substr = '*RR';
        console.log('Test Sub String', str.includes(substr));
        let result;

        if (recordType === 'Rerent') {
            result = await editRecordModal.open({
                // `label` is not included here in this example.
                // it is set on lightning-modal-header instead
                size: 'medium',
                modalHeader: modalHeader,
                description: 'Accessible description of modal\'s purpose',
                recordId: recordId


            });
        } else {
            result = await editStandardModal.open({
                size: 'medium',
                modalHeader: modalHeader,
                description: 'Accessible description of modal\'s purpose',
                recordId: recordId
            });
        }

        console.log('result', result);

        if (result == "OK") {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record was updated successfully',
                    variant: 'success'
                })
            );
            getRecordNotifyChange([{ recordId: recordId }]);
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

    /* -----------------------------------------------Abhishek Code Starts------------------------------------------------------------ */
    // Cancel PO Line Items confirmation modal
    // Author : Abhishek Hiremath
    // User Story : FRONT-20159 

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
        refreshApex(this.dataToRefresh);
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
        console.log('PO Status', this.statusValue);
        this.saleslineItems = this.saleslineItems.map(car => {
            return {
                ...car,
                accountDisabled: (car.Status__c === 'Cancelled' || this.statusValue == 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') ? true : false

            };
        });
        Object.preventExtensions(this.saleslineItems);
        //this.totalNoOfRecords = this.result.data.length;
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        if (this.statusValue === 'Draft') {
            actions.push({
                label: 'Remove', name: 'remove'
            })
        }
        doneCallback(actions);
    }



    /* -----------------------------------------------Abhishek Code Stops------------------------------------------------------------ */

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
        this.openCreateModal = false;
        refreshApex(this.dataToRefresh);
    }
    handleCreatePOButton(event) {
        this.openCreateModal = true;
    }
    createRecordListForMobile(records) {
        this.reRentRecordList = [];
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
                col3.value = rec.Unit_Cost__c;
                columns.push(col3);
                record.columns = columns;

                let col4 = {};
                col4.type = 'currency';
                col4.key = 4;
                col4.label = 'Extended Cost';
                col4.value = rec.Total_Cost_Calc__c;
                columns.push(col4);
                record.columns = columns;
                this.reRentRecordList.push(record);
            });
        }
        if (this.reRentRecordList.length > 0) {
            this.template.querySelector('[data-id="salesCmp"]').refreshRecords(this.reRentRecordList);
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
            console.log('inside removeitems arrauys');
        }
        this.removeItems = removeItemsArray;
        this.showRemoveModal = true;
    }

    handleEditScreen(event) {
        console.log('recordId:' + event.detail.recordId);
        let recTypeArr = Object.values(this.dataToRefresh.data);
        let currRecType = recTypeArr.filter(x => x.Id == event.detail.recordId);
        let currRecTypeName = currRecType[0].RecordTypeName__c;
        console.log('currRecTypeName:', currRecTypeName);
        if (currRecTypeName != 'Rerent'){
            console.log('this.recordType----',this.recordType);
            this.openEditScreenStandard=true;
            
        }else{
            this.openEditScreen = true;
        }
        this.lineItemRecId = event.detail.recordId;
    }

    handleRemoveItemClose(event) {
        this.showRemoveModal = false;
        console.log(event.detail);
    }
    handleRemoveItem(event) {
        this.showRemoveModal = false;
        this.showRemoveSalesMobile = false;
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

    handleEditClose(event) {
        this.openEditScreen = false;
        this.openEditScreenStandard=false;
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