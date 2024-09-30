import { LightningElement, api, track } from "lwc";
import deleteLineItems from '@salesforce/apex/SBR_3_0_LineItemCartCmpController.deleteLineItems';
import { getRecord, createRecord, deleteRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductKitComponents from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents';
import checkBulkFlag from '@salesforce/apex/SBR_3_0_LineItemCartCmpController.getLineItemBulkFlag';

const USER_FIELDS = [
    'User.Id',
    'User.Name',
    'User.Profile.Name'
  ];

export default class Sbr_3_0_lineItemsGridSectionCmp extends LightningElement {
    @track kitComps = []; // SAL-27182
    @track showKitComps = false;

    ADMIN_PROFILE_NAME = 'System Administrator';
    @track kitCompArray = [];
    @track showCustomKitItem = false;
    isLoading = false;
    @track lineItems = [];  //All Line Items
    @track disableEdit = false;
    @track lineId = '';
    @track selectedItemGroup = '';
    @track lineItemEditorDisplay = false;
    @track itemListDisplay = true;
    @api recordId;
    @api objectApiName;//SF-5291,SF-5292
    @api companyCode;//SF-5291,SF-5292
    @track itemSelected;
    @track selectedRowsCount = 0;
    removeNotChecked = true;
    delayTimeout;
    @api isMobile;
    @api label;
    @api accname;
    @api recordTypeName;
    @api iconName;
    @api columns;
    //@api disableRemoveItem;
    @api disableBulkEdit;
    //@api records;
    @api draftValues;
    @api draftErrors;
    @api parentRecord;
    @api currentUserRecord;
    @api reload = false;
    @api existingLineItems;//SF-6105
    localUserRecord;
    @track _records=[];
    @api 
    get records(){
        return this._records;
    }

    set records(value){
        // Disable Remove for Forced AddOns - Mobile
        if(value){
            this._records = JSON.parse(JSON.stringify(value));
            this._records = this._records?.map(record=>{
                return{
                    ...record,
                    disableMobileRemoveItem: (this._disableMobileRemoveItem || record.forcedItem) && !(record?.Name == 'Fuel Convenience Charge'), //SF-5879
                    disableMobileQuantityEdit: ((this.isRental || (record.lineItemType == 'VR' || record.lineItemType == 'RI')) && record?.forcedItem), // Rental Forced Addon edit should be disabled
                    showRates: this.isRental || (record.lineItemType == 'VR' || record.lineItemType == 'RI') || (record.hasKit && !record.SalesforceManagedKit),// show rates for Rental & unmanaged kits - SF-7654
                    isSalesOrAncillary : this.isSalesOrAncillary || (record.lineItemType == 'VS' || record.lineItemType == 'SI' || record.lineItemType == 'YC' || record.lineItemType == 'XC') || (record.lineItemType == 'YC' || record.lineItemType == 'XC'),
                    hideSubtotal : this.label && this.label.toLowerCase().startsWith('items'),
                    showKitComp : false
                }
            });
        } 
    }

    _disableRemoveItem = true;
    _disableMobileRemoveItem = true;
    _iconName = 'standard:lead_list';
    currentSelectedRows = [];

    removeItems = (event) => {
        this.isLoading = true;
        
        event.stopPropagation();
        this.closeModal(event);
        if (this.isMobile) {
            let removeItemsIndexArray = [];
            let indexOfItemsSelected = [];
            let recordIdsToDelete = [];
            let selectedRows = [];
            let itemsSelected = [];
            let removeItemRows;

            var elems = this.template.querySelectorAll('lightning-input');
            elems.forEach((element, index) => {
                if (element.checked) {
                    removeItemsIndexArray.push(element.value);
                    indexOfItemsSelected.push(index);
                    selectedRows.push(element.value);
                    itemsSelected.push(element);
                }
            });

            for (let i = removeItemsIndexArray.length - 1; i >= 0; i--) {
                let currIndex = removeItemsIndexArray[i];
                recordIdsToDelete.push(currIndex);
            }
            
            if (this.objectApiName === 'Order' || this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Cart__c') {
                deleteLineItems({ lineIds: recordIdsToDelete })
                    .then((data) => {
                        this.records = this.records.filter(row => !selectedRows.includes(row.Id));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Line Items deleted.',
                                variant: 'success',
                            }),
                        );
                        this.isLoading = false;
                    })
                    .catch((error) => {

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting Line Items',
                                message: error?.message,
                                variant: 'error',
                            }),
                        );
                        this.isLoading = false;
                    });
            } 
            //SAL-26125
            else if(this.objectApiName == undefined){ 
                                this.records = this.records.filter(row => !selectedRows.includes(row.Id));
                                this.updateLineItemGridData(this.records);
                                this.isLoading = false;
                                
                        }
            else {
                removeItemRows = recordIdsToDelete.map(row => deleteRecord(row));

                Promise.all(removeItemRows)
                    .then(deletedItems => {
                        this.lineItems = this.lineItems.filter(row => !selectedRows.includes(row.Id));
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Line Items deleted.',
                                variant: 'success',
                            }),
                        );
                        this.isLoading = false;
                    })
                    .catch(deletedItemsError => {
                        console.error('item delete error:', deletedItemsError.body.message);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting Line Items',
                                message: deletedItemsError.body?.message,
                                variant: 'error',
                            }),
                        );
                        this.isLoading = false;
                    });
            }

            this.itemSelected = false;
        } else {
            this.isLoading = true;
            let selectedRows = this.itemsToRemove;
            let removeItemRows;

            if (this.objectApiName === 'Order') {
                deleteLineItems({ lineIds: selectedRows })
                    .then((data) => {
                        this.lineItems = this.lineItems.filter(row => !selectedRows.includes(row.Id));
                        this.updateLineItemGridData(this.lineItems);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Line Items deleted.',
                                variant: 'success',
                            }),
                        );
                        this.isLoading = false;
                    })
                    .catch((error) => {

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting Line Items',
                                message: error,
                                variant: 'error',
                            }),
                        );
                        this.isLoading = false;
                    });
            } else {
                removeItemRows = selectedRows.map(row => deleteRecord(row));

                Promise.all(removeItemRows)
                    .then(deletedItems => {
                        this.updateLineItemsTable();
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Line Items deleted.',
                                variant: 'success',
                            }),
                        );
                        this.isLoading = false;
                    })
                    .catch(deletedItemsError => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error deleting Line Items',
                                message: deletedItemsError.body?.message,
                                variant: 'error',
                            }),
                        );
                        this.isLoading = false;
                    });
            }
            this.template.querySelector(".removeModal").toggleModal();
        }
    }

    //method to toggle item selected sticky footer when line items are selected/deselected
    handleRowSelection(event) {
        let tempArray = JSON.parse(JSON.stringify(this.records));
        let r = event.target;
        let i = tempArray.findIndex(e => e.Id === r.value);
        let elements = this.template.querySelectorAll('lightning-input');
        let element = elements[i];
        element.checked = r.checked;
        setTimeout(() => {
            this.getRowInfos(elements);
        }, 200);
    }

    getRowInfos(arr) {
        this.selectedRowsCount = 0;
        this.itemSelected = false;
        for (let j = 0; j < arr.length; j++) {
            if (arr[j].checked) {
                //this.itemSelected = true;
                this.selectedRowsCount++;
            }
        }
        this.itemSelected = this.selectedRowsCount > 0 ? true : false;
    }


    //method to handle actions in the selection panel on mobile
    selectionPanelActions(event) {
        switch (event.target.value) {
            case 'selectAll':
                let elems = this.template.querySelectorAll('lightning-input');
                elems.forEach((element) => {
                    element.checked = true;
                });
                this.getRowInfos(elems);
                break;
            case 'remove':
                this.removeItems();
                break;
        }
    }

    toggleRemoveModal() {
        this.template.querySelector(".removeModal").toggleModal();
    }

    closeModal(ev) {
        this.template.querySelector(".removeModal").closeModal(ev);
    }
    @api
    get disableRemoveItem() {
        return this._disableRemoveItem;
    }

    set disableRemoveItem(value) {
        this._disableRemoveItem = value;
    }

    getIsRemoveItemDisabled(){

    }

     get disableBulkEdit() {
        let currentUserProfileName = this.currentUserRecord.fields.Profile?.value?.fields?.Name?.value;
        switch (this.objectApiName) {
            case 'SBQQ__Quote__c':
                return ((!this.records && this.records.length == 0) || 
                ((this.parentRecord.fields.Rentalman_Quote_Id__c?.value || this.parentRecord.fields.SBQQ_Status_Reason__c?.value == 'Converted') && currentUserProfileName !== this.ADMIN_PROFILE_NAME));
            case 'Order':
                return ((!this.records && this.records.length == 0) || 
                ((this.parentRecord.fields.Reservation_Order_Number__c?.value || 
                this.parentRecord.fields.Contract_Order_Number__c?.value) && currentUserProfileName !== this.ADMIN_PROFILE_NAME));
            default:
                return (!this.records && this.records.length == 0);
          }
    }

    get iconName() {
        return this._iconName;
    }

    set iconName(value) {
        this._iconName = value;
    }

    get isRecordListNotEmpty() {
        return this.records?.length > 0;
    }

    get showHeaderButtons() {
        return this.objectApiName != undefined && this.objectApiName != 'Cart__c';
    }

    get isQuoteOrOrder() {
        if (this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Order') {
            return true;
        } else {
            return false;
        }
    }

    get isAncillary(){
        return this.label && this.label.toLowerCase().includes('ancillary');
    }

    get isRentalOrSales(){
        return this.isRental || this.isSales;
    }

    get isSalesOrAncillary(){
        return this.isAncillary || this.isSales;
    }

    get isRentalOrSalesOrDelivery(){
        return this.isRental || this.isSales;
    }

    get isRentalOrSalesOrAncillary(){
        return this.isRental || this.isSales || this.isAncillary;
    }

    get isDelivery(){
        return this.label && this.label.toLowerCase().includes('delivery');
    }

    get isRental(){
        return this.label && this.label.toLowerCase().includes('rental');
    }
    get isSales(){
        return this.label && this.label.toLowerCase().includes('sales');
    }

    get itemListDisplayClass() {
        return this.itemListDisplay ? 'hidden-mob-container show' : 'hidden-mob-container';
    }
    get lineItemEditorDisplayClass() {
        return this.lineItemEditorDisplay ? 'hidden-mob-container show' : 'hidden-mob-container';
    }

    connectedCallback() {
        if(this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Order'){
            let currentUserProfileName = this.currentUserRecord.fields.Profile?.value?.fields?.Name?.value;
            switch (this.objectApiName) {
                case 'SBQQ__Quote__c':
                    if(this.parentRecord.fields.Rentalman_Quote_Id__c?.value && currentUserProfileName !== this.ADMIN_PROFILE_NAME){
                            this._disableMobileRemoveItem = true;
                    } else {
                        this._disableMobileRemoveItem = false;
                    }
                    break;
                case 'Order':
                    if((this.parentRecord.fields.Reservation_Order_Number__c?.value || 
                        this.parentRecord.fields.Contract_Order_Number__c?.value) && currentUserProfileName !== this.ADMIN_PROFILE_NAME){
                            this._disableMobileRemoveItem = true;
                    } else {
                        this._disableMobileRemoveItem = false;
                    }
                    break;
            }
        }
        else {
            this._disableMobileRemoveItem = false;
        }

    }


    handleLineItemSelection(event) {
        let selectedRows = event.target.getSelectedRows();
        //SF-5303
        this.currentSelectedRows = [];
        selectedRows.forEach(row => {
            if(!row?.quantityEditable){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Info',
                        message: 'Row selection is not allowed.Please update quantity of the Rental Item this Add On is associated to', 
                        variant: 'info'
                    })
                );
            }else{
                this.currentSelectedRows.push(row.Id);
            }
        });
        selectedRows = selectedRows.filter(item => item?.quantityEditable);

        if (this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Order') {
            let currentUserProfileName = this.currentUserRecord.fields.Profile?.value?.fields?.Name?.value;
            switch (this.objectApiName) {
                case 'SBQQ__Quote__c':
                    if (this.parentRecord.fields.Rentalman_Quote_Id__c?.value && currentUserProfileName !== this.ADMIN_PROFILE_NAME) {
                        this._disableRemoveItem = true;
                    } else if (selectedRows.length > 0) {
                        this._disableRemoveItem = false;
                    } else {
                        this._disableRemoveItem = true;
                    }
                    break;
                case 'Order':
                    if ((this.parentRecord.fields.Reservation_Order_Number__c?.value ||
                        this.parentRecord.fields.Contract_Order_Number__c?.value) && currentUserProfileName !== this.ADMIN_PROFILE_NAME) {
                        this._disableRemoveItem = true;
                    } else if (selectedRows.length > 0) {
                        this._disableRemoveItem = false;
                    } else {
                        this._disableRemoveItem = true;
                    }
                    break;
                default:
                    this._disableRemoveItem = selectedRows.length > 0 ? false : true;

            }
        }
        else {
            this._disableRemoveItem = selectedRows.length > 0 ? false : true;
        }
    }

    handleItemAction(event) {
        let selectedRows = this.template.querySelector('c-sbr_3_0_custom-line-items').selectedRows;
        const itemActionEvent = new CustomEvent('handleitemaction', {
            'detail': {
                'buttonName': event.target.dataset.name,
                'selectedRows': selectedRows,
                'isRental': event.target.dataset.isRental,
                'isSales': event.target.dataset.isSales
            }
        });
        this.dispatchEvent(itemActionEvent);

    }

    // SAL-26337
    getGridName(record) {
        let result = '';
        if (record === 'rental') {
            result = 'rental'
        } else if (record === 'sales/misc') {
            result = 'sales';
        } else if (record === 'delivery') {
            result = 'delivery';
        } else {
            result = 'ancillary';
        }
        return result;
    }

    //method to toggle line item editor on mobile
    editLineItemHandler(event) {
        // SAL-26337
        this.gridName = this.getGridName(this.label.split(' ')[0].toLowerCase());


        // SAL-26439
        if (this.gridName !== 'ancillary' && this.objectApiName !== 'Cart__c') {
            this.lineId = (event.target.getAttribute('id')).slice(0, 18);
            this.selectedItemGroup = event.target.getAttribute('data-groupid') ? event.target.getAttribute('data-groupid') : '';


            this.itemListDisplay = false;
            this.lineItemEditorDisplay = true;
    
            setTimeout(() => {
                this.template.querySelector("c-sbr_3_0_line-item-editor-cmp").populateLineData(this.lineId, this.selectedItemGroup, this.recordId,this.existingLineItems); //SF-6105
        }, 500);

        //add event here to tell parent (linteItemsCmp to hide the other accordions that did not activate the edit)
        const lineItemEditEvent = new CustomEvent('lineitemedit', {
            'detail': {
                'grid': this.gridName
            }
        });
        this.dispatchEvent(lineItemEditEvent);
        }
    }

    handleDeleteActionMobile(event) {

        const itemActionEvent = new CustomEvent('handleitemaction', {
            'detail': {
                'buttonName': event.target.dataset.name,
                'selectedRows': event.target.dataset.element,
                'isRental': event.target.dataset.isRental,
                'isSales': event.target.dataset.isSales
            }
        });
        this.dispatchEvent(itemActionEvent);
    }

    @api
    closeLineItemEditor() {
        this.lineItemEditorDisplay = false;
        this.itemListDisplay = true;
        //add event here to unhide hidden accordions
        const closeLineItemEdit = new CustomEvent('closelineedit');
        this.dispatchEvent(closeLineItemEdit);
    }
    @api
    repopulateLineItems(updatedRecordId){
        notifyRecordUpdateAvailable([{ recordId: updatedRecordId }]);
        this.listInfoRecordId = this.recordId.valueOf();
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Line Item was successfully saved',
            variant: 'success',
        }));
        this.closeLineItemEditor();
        this.isLoading = false;
    }
    //SF-7551
    toggleSpinner(event){
        this.isLoading = false;
    }

    @api//SF-6105
    async mobileSaveQuoteLine() {
        let savedData;
        try {
            this.isLoading = true;
            savedData = await this.template.querySelector("c-sbr_3_0_line-item-editor-cmp").saveData();
            if(savedData){
                const updatedRecordId = this.objectApiName == 'SBQQ__Quote__c' ? savedData.Id : savedData[0].Id;
                await notifyRecordUpdateAvailable([{ recordId: updatedRecordId }]);
                this.listInfoRecordId = this.recordId.valueOf();

                if (this.objectApiName == 'SBQQ__Quote__c') {
                    this.repopulateLineItems(updatedRecordId);
                }
                else {  // SF-6894
                    checkBulkFlag({ lineItemId: updatedRecordId })
                      .then(result => {
                        if (result) {
                          this.repopulateLineItems(updatedRecordId);
                        }
                        else {
                          window.clearTimeout(this.delayTimeout);
                          this.isLoading = true;
                          this.delayTimeout = setTimeout(() => {
                            this.repopulateLineItems(updatedRecordId);
                          }, 10000);
                        }
                      })
                      .catch(error => {
                        console.log('Error in getting a response from get line item bulk flag ' + error.message);
                      })
                }
                

                /*
                await notifyRecordUpdateAvailable([{ recordId: updatedRecordId }]);
                this.listInfoRecordId = this.recordId.valueOf();
                window.clearTimeout(this.delayTimeout);
                this.isLoading = true;
                this.delayTimeout = setTimeout(() => {
                    notifyRecordUpdateAvailable([{ recordId: updatedRecordId }]);
                    this.listInfoRecordId = this.recordId.valueOf();
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'Line Item was successfully saved',
                        variant: 'success',
                    }));
                    this.closeLineItemEditor();
                    this.isLoading = false;
                }, 10000);*/
            }
        } catch (error) {
            console.log('error: ' + error);
            this.isLoading = false;
    
            // Trigger error toast
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Error updating Line Item',
                variant: 'error',
            }));
        } /*finally {
            this.isLoading = false;
            if(savedData){
                this.closeLineItemEditor();
            }
        }*/
        }
    handleRowAction(event) {
        let selectedRows = this.template.querySelector('c-sbr_3_0_custom-line-items').selectedRows;
        const rowActionEvent = new CustomEvent('handlerowaction', {
            'detail': {
                'newEvent': event,
                'selectedRows': selectedRows
            }
        });
        this.dispatchEvent(rowActionEvent);

    }
    
    handleRowSave(event) {
        let selectedRows = this.template.querySelector('c-sbr_3_0_custom-line-items').selectedRows;
        const rowActionEvent = new CustomEvent('handlerowsave', {
            'detail': {
                'newEvent': event,
                'selectedRows': selectedRows
            }
        });
        this.dispatchEvent(rowActionEvent);

    }
    mobileEditQuantity(event) {
        let updatedLineId = event.target.dataset.lineid;
        let updatedQuantity = event.target.value;
        let updatedcatClass=event.target.dataset.catclass;//SF-5291,SF-5292 added  data-catclass
        const rowActionEvent = new CustomEvent('handlequantitysave', {
            'detail': {
                'lineid': updatedLineId,
                'quantity': updatedQuantity,
                'catclass':updatedcatClass //SF-5291,SF-5292 added  data-catclass
            }
        });
        this.dispatchEvent(rowActionEvent);

    }

     //SF-8109
    showKitComponents(event) {
        let index = Number(event.currentTarget.dataset.id);

        if(this._records[index].showKitComp == false){
            this.resetShowKitCmp();
            this.isLoading = true; // SAL-27182
            this.getKitItems(this._records[index], index);
        }else{
           this.resetShowKitCmp();
        }
    }

    //SF-8109
    resetShowKitCmp(){
        this._records.forEach(record => {record.showKitComp = false});
    }


    async getKitItems(lineItem, index) {
        let data = []; 
        try {
            let productId = lineItem.product ? lineItem.product : lineItem.Product;
            data = await getProductKitComponents({ productId: JSON.parse(JSON.stringify(productId)) });
            this.kitComps = JSON.parse(data);

            // SF-7534 : update quantity of kit items
            if (Array.isArray(this.kitComps) && this.kitComps.length) {
                this.kitComps.forEach(el => {el.SBQQ__Quantity__c = el.SBQQ__Quantity__c * lineItem.Quantity});
            }

            //change for SF-5877
            const itemActionEvent = new CustomEvent('showkits', {
                'detail': {
                    'kits': JSON.parse(data),
                    'index': index
                }
            });
            this.dispatchEvent(itemActionEvent);
            
            this.isLoading = false;// SAL-27182
            this._records[index].showKitComp = true;
        } catch (error) {
            this.isLoading = false;// SAL-27182
            console.log(error);
        };
    }
    // SAL-26789
    showNotes(event) {
        const id = event.target.title;
        const updatedData = { showNoteItem: true }
        this.records = this.records.map((item) => (item.Id === id ? { ...item, ...updatedData } : item));
    }
    // SAL-26789
    hideNotes(event) {
        const id = event.target.title;
        const updatedData = { showNoteItem: false }
        this.records = this.records.map((item) => (item.Id === id ? { ...item, ...updatedData } : item));
    }

}