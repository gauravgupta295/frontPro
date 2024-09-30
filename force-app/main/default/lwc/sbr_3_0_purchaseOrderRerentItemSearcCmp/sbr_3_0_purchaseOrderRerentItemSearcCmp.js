import { LightningElement, track, wire, api } from 'lwc';
import getProduct from '@salesforce/apex/SBR_3_0_POItemSearchController.getProduct';
import getProductCategoryOptions from '@salesforce/apex/SBR_3_0_RerentPOItemSearchController.getProductCategoryOptions';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPOLineItem from '@salesforce/apex/SBR_3_0_RerentPOItemSearchController.createPOLineItem';
import createBulkPOLineItem from '@salesforce/apex/SBR_3_0_RerentPOItemSearchController.createBulkPOLineItem';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
//Message Channel
import { MessageContext, publish } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import mobileView from './mobile.html';
import desktopView from './desktop.html';
//import desktopView from './mobile.html';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';


const FIELDS = ['Purchase_Order__c.Status__c']
const SMALL_FORM_FACTOR = "Small";

const columns = [
    { label: 'Item Category', fieldName: 'Product_Category__c', type: 'text', sortable: 'true' },
    { label: 'Item Sub-Category', fieldName: 'Product_Sub_Category__c', type: 'text', sortable: 'true' },
    { label: 'Cat Class', fieldName: 'Product_SKU__c', type: 'text', sortable: 'true' },
    { label: 'Item Name', fieldName: 'Name', type: 'text', sortable: 'true' },
    { label: 'Image', fieldName: 'Primary_Image_URL__c', type: 'image', sortable: 'false' },
];

const PRODUCT_FIELDS = ['Product_Category__c', 'Product_Sub_Category__c', 'Cat_Class_Sort_Index__c', 'Product_SKU__c', 'Stock_class__c', 'Name', 'Primary_Image_URL__c', 'Unit_Cost_of_Inventory__c', 'Item_Number__c', 'Bulk_Item__c'];

export default class Sbr_3_0_purchaseOrderRerentItemSearcCmp extends LightningElement {
    @wire(MessageContext)
    messageContext
    @api recordId;
    @track data;
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    @track filterVisibility = false;
    @track totalNoOfRecords = 0;
    @track sortByName;
    @track isLoaded = true;
    @track selectedSuperCategory = '';
    @track selectedCategory = '';
    @track selectedSubCategory = '';
    @track optionsSuperCategory = [];
    @track optionsCategory = [];
    @track optionsSubCategory = [];

    @track onrowselection = false;
    @track singleRow = false;
    @track singleUnitCost;
    @track catclass;
    @track selectedRows = [];
    isCheckboxChecked = true;
    showErrorMessage = true;
    @track showQtyErrorBox = false;
    errorMessage = "Please enter a valid value equal to or greater than 1";
    @track isDisable=false;

    @track title;
    @track selectedRowCount = 0;
    @track quantity = 1;
    @track costperitem;
    @track newSingleUnitCost;
    @track newSingleUnitValue;
    @track singleRecordId;
    @track singleItemNumber;
    rowIds = [];
    @track componentIds = ['1'];
    @api updatedValue = [];
    @track rowDataList = [];
    @api myMap = [];
    myMap2 = new Map();
    dataToRefresh;
    productType = ' Product_Type__c = \'Cat-Class\' ';
    catClass = '';
    catIds = [];

    showAddToPurchaseOrderButton = true;
    enabledRowCount = 0;
    salesVisibility = false

    connectedCallback() {
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: PRODUCT_FIELDS, filterBy: this.productType })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = result.length;
                console.log(this.data);
            })
            .catch(error => {
                this.isLoaded = false;
                console.log('no Data');
            })
        this.template.addEventListener('childCustomEvent', this.handleRowSelection.bind(this));
        this.getOptionsSuperCategory();
        this.getOptionsCategory();
        this.getOptionsSubCategory();
        this.handleFormFactor();
    }
    
    renderedCallback(){
        if(!this.singleRow){
            let isChildValidated = true;
                [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-rerent-comp")].forEach((element) => {
                if (element.checkValidity() === false) {
                isChildValidated = false;
                }
            });

            if(isChildValidated){
                this.showQtyErrorBox = false;
            } else{
                this.showQtyErrorBox = true;
            }
        }
        if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
        this.setFocusOnFirstElement()
        //Scroll to sales div
        const salesVisDiv = this.template.querySelector('[data-id="salesVisDiv"]');
        if (salesVisDiv != undefined) {
            salesVisDiv.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
        }
    }

    setFocusOnFirstElement() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        window.setTimeout(() => {
            if (!this._rendered) {
                let ele = this.template.querySelector('[data-name="inputQuantity"]');
                if (ele && ele.focus) {
                    ele.focus();
                    this._rendered = true;
                }
            }
        }, 5);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {

            console.log('PO Data', data);
            console.log('status of PO >>',JSON.stringify(data.fields.Status__c.value));

            this.statusValue = data.fields.Status__c.value;
            // if (this.statusValue === 'Open' || this.statusValue === 'Back Order' || this.statusValue === 'Partially Received') {
            if (this.statusValue === 'Draft') {
                this.showAddToPurchaseOrderButton = true;
                console.log('this.showAddToPurchaseOrderButton :>> ', this.showAddToPurchaseOrderButton);
                this.enabledRowCount = 10;
            }else{
                this.showAddToPurchaseOrderButton = false;
                console.log('this.showAddToPurchaseOrderButton in else :>> ', this.showAddToPurchaseOrderButton);
                this.enabledRowCount = 0;
            }

        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    doSorting(event) {
        this.sortByName = event.detail.fieldName == 'Product_Category__c' ? 'Item Category' : event.detail.fieldName == 'Product_Sub_Category__c' ? 'Item Sub-Category' : event.detail.fieldName == 'Product_SKU__c' ? 'Cat Class' : 'Name';
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    render() {
        return (this.isMobileView === true) ?  mobileView:desktopView;
    }
    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
    handleFormFactor() {
        if (FORM_FACTOR === "Large") {
            this.deviceType = "Desktop/Laptop";
        } else if (FORM_FACTOR === "Medium") {
            this.deviceType = "Tablet";
        } else if (FORM_FACTOR === "Small") {
            this.deviceType = "Mobile";
        }
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }

    handleSearch(event) {
        if (event.keyCode === 13) {
            this.isLoaded = true;
            console.log(this.productType);
            getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: PRODUCT_FIELDS, filterBy: (this.productType + ' and (Product_SKU__c Like \'%' + event.target.value + '%\') ') })
                .then(result => {
                    this.isLoaded = false;
                    this.data = result;
                    this.totalNoOfRecords = this.data.length;
                })
                .catch(error => {
                    this.isLoaded = false;
                    console.log('no Data');
                })
        }
    }

    handleFilter(event) {
        console.log('filter');
        this.filterVisibility = this.filterVisibility ? false : true;
    }

    handleItemSuperCategoryInput(event) {
        this.selectedSuperCategory = event.target.value;
    }

    handleItemCategoryInput(event) {
        this.selectedCategory = event.target.value;
    }

    handleItemSubCategoryInput(event) {
        this.selectedSubCategory = event.target.value;
    }

    handleCatClassInput(event) {
        this.catClass = event.target.value;
    }

    handleApply(event) {
        this.data = [];
        this.isLoaded = true;
        this.template.querySelector('lightning-input[data-name=searchBox]').value = '';
        let whereClause = (this.productType + (this.selectedSuperCategory != '' ? ' and Super_Category__c =\'' + this.selectedSuperCategory + '\'' : '') + (this.selectedCategory != '' ? ' and Product_Category__c = \'' + this.selectedCategory + '\'' : '') + (this.selectedSubCategory != '' ? ' and Product_Sub_Category__c = \'' + this.selectedSubCategory + '\'' : '') + (this.catClass != '' ? ' and Product_SKU__c Like \'%' + this.catClass + '%\'' : ''));
        console.log(whereClause);
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: PRODUCT_FIELDS, filterBy: whereClause })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = this.data.length;
            })
            .catch(error => {
                this.isLoaded = false;
                console.log('no Data');
            })
            this.filterVisibility = false;
    }

    handleCancel() {
        this.filterVisibility = false;
        console.log('reset method');
    }

    handleReset() {
        console.log('reset method');
        this.template.querySelector('lightning-combobox[data-name=itemSuperCategory]').value = this.selectedSuperCategory = '';
        this.template.querySelector('lightning-combobox[data-name=itemCategory]').value = this.selectedCategory = '';
        this.template.querySelector('lightning-combobox[data-name=itemSubCategory]').value = this.selectedSubCategory = '';
        this.template.querySelector('lightning-input[data-name=catClass]').value = this.catClass = '';
    }

    handleClose() {
        this.filterVisibility = false;
        this.salesVisibility = false;
    }

    getOptionsSuperCategory() {
        getProductCategoryOptions({ filterLevel: 1, isSubCategory: false, orderByName: true })
            .then(result => {
                if (result.length > 0) {
                    result.forEach((superCat) => {
                        this.optionsSuperCategory.push({
                            label: superCat.Name,
                            value: superCat.Name
                        });
                    });
                }
            })
            .catch(error => {
                console.log('no Data');
            })
    }

    getOptionsCategory() {
        getProductCategoryOptions({ filterLevel: 2, isSubCategory: false, orderByName: true })
            .then(result => {
                if (result.length > 0) {
                    let catList = [];
                    for (var i = 0; i < result.length; i++) {
                        if (!catList.includes(result[i].Name)) {
                            catList.push(result[i].Name);
                        }
                    }

                    catList.forEach((cat) => {
                        this.optionsCategory.push({
                            label: cat,
                            value: cat
                        });
                    });
                }
            })
            .catch(error => {
                console.log('no Data');
            })
    }

    getOptionsSubCategory() {
        getProductCategoryOptions({ filterLevel: null, isSubCategory: true, orderByName: true })
            .then(result => {
                if (result.length > 0) {
                    let subCatList = [];
                    for (var i = 0; i < result.length; i++) {
                        if (!subCatList.includes(result[i].Name)) {
                            subCatList.push(result[i].Name);
                        }
                    }

                    subCatList.forEach((subCat) => {
                        this.optionsSubCategory.push({
                            label: subCat,
                            value: subCat
                        });
                    });
                }
            })
            .catch(error => {
                console.log('no Data');
            })
    }


    /* -------------------------Sachin Khambe code starts---------------------------------------------------- */

    handleRowSelection(event) {

        this.selectedRows = event.detail.selectedRows;
        const rowID = event.detail.config.value;
        console.log('deselected Id : ', rowID, event);
        const selectionAction = event.detail.config.action;
        if (selectionAction == "rowDeselect") {
            console.log('Map after deleting Row in  handleRowSelection: ', rowID, this.myMap2);
            this.myMap2.delete(rowID);
        }

        if (this.selectedRows.length > 0) {
            console.log('inside if of  handleRowSelection : ');
            this.onrowselection = true;

            this.title = this.selectedRows[0].Name;
            this.singleUnitCost = this.selectedRows[0].Unit_Cost_of_Inventory__c;
            this.selectedRowCount = this.selectedRows.length;

            if (this.selectedRowCount === 1) {
                console.log('inside 2nd if of  handleRowSelection : ');
                if (this.selectedRows[0].Bulk_Item__c == true) {
                    this.isDisable = false;
                    this.isCheckboxChecked = false;

                } else {
                    this.isDisable = true;
                    this.isCheckboxChecked = true;
                }

                this.singleRow = true;
            } else {
                this.singleRow = false;
                this.quantity = 1;
            }
        }
        else {
            this.onrowselection = false;
            this.quantity = 1;
            console.log('CheckRowSelection in else', this.onrowselection);
        }

        console.log('CheckRowSelection', this.onrowselection);
        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-rerent-comp")].forEach((element) => {
            if (element.checkValidity() === false) {
            isValidated = false;
            }
        });
        if(isValidated){
            this.showQtyErrorBox = false;
        } else{
            this.showQtyErrorBox = true;
        }
    }

    getSelectedRecords() {
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length > 0) {
            this.selectedIds = ids.replace(/^,/, '');
            this.listSelectedRecords = selectedRecords;
            //console.log(this.listSelectedRecords);
            alert(this.selectedIds);
        }
    }

    handleAddPurchaseOrder() {
        let isSelfValidated = true;
        isSelfValidated = [
            ...this.template.querySelectorAll("lightning-input")
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        console.log("isSelfValidated: "+isSelfValidated);
        console.log("handleAddPurchaseOrder showQtyErrorBox:"+this.showQtyErrorBox);

        if (isSelfValidated) {
            this.showQtyErrorBox = false;
            console.log('Into 1st method', this.selectedRows);
            this.singleRecordId = this.selectedRows[0].Id;
            console.log('singleRecordId == ', JSON.stringify(this.singleRecordId));

            this.newSingleUnitValue = this.singleUnitCost;
            console.log('newSingleUnitValue == ', JSON.stringify(this.newSingleUnitValue));

            this.singleQuantity = this.quantity;
            console.log('singleQuantity == ', JSON.stringify(this.singleQuantity));

            this.catclass = this.selectedRows[0].Product_SKU__c;
            console.log('catclass == ', JSON.stringify(this.catclass));


            createPOLineItem({ recordId: this.recordId, singleRecordId: this.singleRecordId, newSingleUnitValue: this.newSingleUnitValue, singleItemNumber: this.singleItemNumber, singleQuantity: this.singleQuantity, catclass: this.catclass })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: 'Added to Purchase Order Successfully',
                            title: 'Success',
                            variant: 'Success'
                        })
                    );
                    this.onrowselection = false;

                    this.template.querySelector("lightning-datatable").selectedRows = [];
                    refreshApex(this.dataToRefresh);
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    this.quantity = 1;
                    //Publish to message channel
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: true
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error while Adding to Purchase Order',
                            message: error.body.message,
                            variant: 'success'
                        })
                    );
                    //Publish to message channel
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: false
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                })
        } else {
            this.showQtyErrorBox = true;
            this.template.querySelector("c-sbr_3_0_message-box").show();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error while adding to Purchase Order",
                    message: "Input values are not correct!",
                    variant: "error"
                })
            );
        }   
    }

    handleAddPurchaseOrder2() {
        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-rerent-comp")].forEach((element) => {
            if (element.checkValidity() === false) {
            isValidated = false;
            }
        });
        if(isValidated){
            this.showQtyErrorBox = false;
            // Old Code STARTS....................................................
            let rowIdkeys = Array.from(this.myMap2.keys());
            let rowIdValues = Array.from(this.myMap2.values());

            console.log('rowIdkey >> : ', JSON.stringify(rowIdkeys));
            console.log('rowIdValue >> : ', JSON.stringify(rowIdValues));

            let updatedvalues = rowIdValues.map(value => value.updatedValue);
            let unitCostValues = rowIdValues.map(value => value.unitCostValue);
            let catClassValues = rowIdValues.map(value => value.catClassValue);

            console.log('updatedvalues >> : ', JSON.stringify(updatedvalues));
            console.log('unitCostValues >> : ', JSON.stringify(unitCostValues));
            console.log('catClassValues >> : ', JSON.stringify(catClassValues));

            createBulkPOLineItem({ recordId: this.recordId, RowsIds: rowIdkeys, RowsCostValues: unitCostValues, values: updatedvalues, selectedRowsCatClassValues: catClassValues })
                .then(() => {
                    console.log('success');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            message: 'Added to Purchase Order Successfully',
                            title: 'Success',
                            variant: 'Success'
                        })
                    );
                    this.onrowselection = false;
                    this.template.querySelector('lightning-datatable').selectedRows = [];
                    refreshApex(this.dataToRefresh);
                    notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                    this.myMap2.clear();
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: true
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                })
                .catch(error => {
                    console.log('error');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error while Adding to Purchase Order',
                            message: error.body.message,
                            variant: 'success'
                        })
                    );
                    //Publish to message channel
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: false
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                })
        } else{
            this.showQtyErrorBox = true;
            this.template.querySelector("c-sbr_3_0_message-box").show();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error while adding to Purchase Order",
                    message: "Input values are not correct!",
                    variant: "error"
                })
            );

        }
    }

    decreaseQuantity(event) {

        console.log('-- quantityyy--', this.quantity);
        if (this.quantity > 1) {
            this.quantity--;
            console.log('-- quantityyy-1', this.quantity);
        }
    }

    increaseQuantity(event) {
        this.quantity++;

    }

    changeQuantity(event)
    {
        this.quantity = event.detail.value;
        if(this.quantity===null)
        {
            this.quantity=0;
        }
    }

    removeAll(event) {
        //this.componentIds=[];
        this.onrowselection = false;
        this.template.querySelector("lightning-datatable").selectedRows = [];
        refreshApex(this.dataToRefresh);
        this.myMap2.clear();
    }

    handleValueChange(event) {
        console.log('intoo  handleValueChange ', this.myMap2);

        const rowId = event.detail.rowId;
        const updatedValue = event.detail.updatedQuantity;
        const unitCostValue = event.detail.unitCostValue;
        const catClassValue = event.detail.catClassValues;

        this.myMap2.set(rowId, { updatedValue: updatedValue, unitCostValue: unitCostValue, catClassValue: catClassValue });

        const RowsIds = this.selectedRows.map(row => row.Id);
        for (const [rowId, _] of this.myMap2) {
            if (!RowsIds.includes(rowId)) {
                this.myMap2.delete(rowId);
            }
        }
        console.log('handleValueChange myMap2>>>>> ', this.myMap2);
    }

    handleCloseNotification() {
        this.showErrorMessage = false;
    }

    async handleCloseRow(event) {
        const rowId = event.detail.rowId;

        console.log('ROw Id after close >', rowId);
        console.log('ROw updatedQuantity after close >', event.detail.updatedQuantity);
        console.log('<<<selected rows Before delete >', JSON.stringify(this.selectedRows));

        this.selectedRows = this.selectedRows.filter((row) => row.Id != rowId);
        this.selectedRowCount = this.selectedRows.length;

        let dt = this.template.querySelector('lightning-datatable');
        dt.selectedRows = this.selectedRows.map(x => x.Id);

        console.log('no. of selected rows after delete >', JSON.stringify(this.selectedRows.length));
        console.log('selected rows after delete >', JSON.stringify(this.selectedRows));


        this.myMap2.delete(rowId);
        console.log('Map after deleting Row : ', this.myMap2);

        /*if (this.selectedRows.length === 1) {
            this.singleRow = true;
        }*/
        if (this.selectedRows.length === 0) {
            this.onrowselection = false;
            this.template.querySelector("lightning-datatable").selectedRows = [];
            this.refresDataTable();
            this.myMap2.clear();

        }
        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-rerent-comp")].forEach((element) => {
            if (element.checkValidity() === false) {
            isValidated = false;
            }
        });
        if(isValidated){
            this.showQtyErrorBox = false;
        } else{
            this.showQtyErrorBox = true;
        }
    }

    async refresDataTable() {
        refreshApex(this.dataToRefresh);
    }

    /* -------------------------Sachin Khambe code ends---------------------------------------------------- */

    // Nikhil
    handleRadioButtonChange(event) {
        console.log('sales');
        this.salesVisibility = true;     
        //this.data = 'slds-hide';   
        console.log('radio id--> ' + event.currentTarget.dataset.id);
        const val =  event.currentTarget.dataset.id; 
        //const ucost =  event.currentTarget.dataset.cost;
        const filtertest = this.data.find(option => option.Id === val);
        console.log(filtertest);
        this.singleRecordId=filtertest.Id; 
        //this.singleUnitCost = filtertest.Last_Cost__c;
        this.singleUnitCost = filtertest.Unit_Cost_of_Inventory__c;
        console.log('UnitCost',this.singleUnitCost ); 
        this.singleItemNumber=filtertest.Item_Number__c;

        this.productId = filtertest.Id; 
        console.log('ProductId',this.productId); 
        this.stockclass=filtertest.Stock_class__c;
        this.stockstatus=filtertest.Stock_Status__c;
        this.itemclass=filtertest.Class__c;  
        this.catClass = filtertest.Product_SKU__c;
        console.log('catClass :',this.catClass);
        this.title = filtertest.Name;
        console.log('ProductName',this.title); 
    } 
    
    handleAddPurchaseOrderMobile(event) {
        
        let isSelfValidated = true;
        isSelfValidated = [
            ...this.template.querySelectorAll("lightning-input")
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        
         if (isSelfValidated) {

            this.newSingleUnitValue=this.singleUnitCost;
            this.singleQuantity=this.quantity;

            //createPOLineItem({ recordId:this.recordId, singleRecordId:this.singleRecordId, newSingleUnitValue:this.newSingleUnitValue, singleItemNumber:this.singleItemNumber, singleQuantity:this.singleQuantity, stockclass:this.stockclass, stockstatus:this.stockstatus, itemclass:this.itemclass})
            createPOLineItem({ recordId: this.recordId, singleRecordId: this.singleRecordId, newSingleUnitValue: this.newSingleUnitValue, singleItemNumber: this.singleItemNumber, singleQuantity: this.singleQuantity, catclass: this.catClass })
            .then(()=>{
                this.dispatchEvent(
                        new ShowToastEvent({
                            message : 'Added to Purchase Order Successfully',
                            title : 'Success',
                            variant : 'Success'
                    })
                );
               this.template.querySelector("lightning-input");
                refreshApex(this.dataToRefresh);      
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                this.quantity = 1;
                const payload = {
                    recordId: this.recordId,
                    recordUpdated: true
                };
                publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title : 'Error while adding to Purchase Order',
                        message : error.body.message ,
                        variant : 'error'
                    })
                );
            })
            //this.dataRefresh();
            refreshApex(this.dataToRefresh);
            //Publish to message channel
            const payload = {
                recordId: this.recordId,
                recordUpdated: false
            };
            publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload); 
            // Old Code ENDS....................................................
        } else {
            this.showQtyErrorBox = true;
            this.template.querySelector("c-sbr_3_0_message-box").show();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error while adding to Purchase Order",
                    message: "Input values are not correct!",
                    variant: "error"
                })
            );
        }
        this.handleSalesClose();   
     }

    handleSalesClose() {
        this.salesVisibility = false;
        this.quantity=1;
        this.connectedCallback();
    }

}