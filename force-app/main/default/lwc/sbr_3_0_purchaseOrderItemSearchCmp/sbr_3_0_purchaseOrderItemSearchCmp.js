import { LightningElement, track, wire, api } from 'lwc';
import getProduct from '@salesforce/apex/SBR_3_0_POItemSearchController.getProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
//import updateProduct from '@salesforce/apex/SBR_3_0_ItemSearch_Controller.updateProduct';
//import updateBulkProduct from '@salesforce/apex/SBR_3_0_ItemSearch_Controller.updateBulkProduct';
//import updateBulkProduct2 from '@salesforce/apex/SBR_3_0_POItemSearchController.updateBulkProduct2';
import createPOLineItem from '@salesforce/apex/SBR_3_0_POItemSearchController.createPOLineItem';
import createBulkPOLineItem from '@salesforce/apex/SBR_3_0_POItemSearchController.createBulkPOLineItem';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
//Message Channel
import { MessageContext, publish } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import mobileView from './mobile.html';
import desktopView from './desktop.html';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
//import desktopView from './mobile.html';



const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Type__c']
const SMALL_FORM_FACTOR = "Small";

const columns = [
    { label: 'Part/Item #', fieldName: 'Item_Number__c', type: 'text', sortable: 'true' },
    { label: 'Stock/Vendor', fieldName: 'Stock_class__c', type: 'text', sortable: 'true' },
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: 'true' },
];

export default class Sbr_3_0_purchaseOrderItemSearchCmp extends LightningElement {
    @wire(MessageContext)
    messageContext
    @api recordId;
    @api listcost=[];
    @track data;
    @track columns = columns;
    @track sortBy;
    @track sortDirection;
    filterVisibility = false;
    @track totalNoOfRecords = 0;
    @track sortByName;
    @track isLoaded = false;
    @track onrowselection = false;
    @track selectedRecords = [];
    @track selectedRows = [];
    @track multipleRows=false;
    @track singleRow=false;
    @track title;
    @track selectedRowCount=0;
    @track singleUnitCost;
    @track quantity=1;
    @track costperitem;
    @track newSingleUnitCost;
    @track newSingleUnitValue;
    @track singleRecordId;
    @track singleItemNumber;
    @track stockclass;
    @track stockstatus;
    @track itemclass;
     rowIds=[];
    @track componentIds=['1'];
    @api updatedValue=[];
    @track rowDataList=[];
    @api myMap=[];
    productId;
    myMap2=new Map();
    dataToRefresh;
    draftValues=[];
    selectedRowIds = [];
    showErrorMessage = true;
    salesVisibility = false
    isCSSLoaded = false;
    @track showQtyErrorBox = false;
    errorMessage = "Please enter a valid value equal to or greater than 1";

    productType = ' Product_Type__c =\'MISC Charge Items\'';
    defaultOption = "Miscellaneous";
    stockVendorInput = '';
    partItemNoInput = '';
    enabledRowCount = 0;
    showAddToPurchaseOrderButton = true;
    deviceType;
    poType;
    // isOneStepPO = false;
    

    get options() {
        return [
            { label: 'Miscellaneous', value: 'Miscellaneous' },
            { label: 'Sales', value: 'Sales' },
        ];
    }

    /*
    get options2() {
        return [
            { label: 'Miscellaneous', value: 'Miscellaneous' },
            //{ label: 'Sales', value: 'Sales' },
        ];
    }
    */

    connectedCallback() {
        console.log('recordId:', this.recordId);
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: ['Name', 'Stock_class__c','Stock_Status__c', 'Class__c' , 'Item_Number__c', 'Last_Cost__c'], filterBy: this.productType })
            .then(result => 
            {
                this.dataToRefresh = result;
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = result.length;
            })
            .catch(error => {
                console.log('no Data');
            })
        this.template.addEventListener('childCustomEvent',this.handleRowSelection.bind(this));
        this.handleFormFactor();
    }

    renderedCallback(){
        if(!this.singleRow){
            let isValidated = true;
                [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-comp")].forEach((element) => {
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
         if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
        this.setFocusOnFirstElement();
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
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {

            console.log('PO Data', data);
            console.log('status of PO >>',JSON.stringify(data.fields.Status__c.value));

            this.poType = data.fields.Type__c.value;
            console.log('poType >>>  : ', this.poType);
            this.statusValue = data.fields.Status__c.value;

            /*
            if (this.poType === 'Standard Purchase Order - One Step') {
                this.isOneStepPO = true;
            }else{
                this.isOneStepPO = false;
            }
            */
            
            if (this.statusValue === 'Cancelled'|| this.statusValue === 'Received' ) {
                this.showAddToPurchaseOrderButton = false;
                console.log('this.showAddToPurchaseOrderButton :>> ', this.showAddToPurchaseOrderButton);
                this.enabledRowCount = 0;
                
            }else{
                this.showAddToPurchaseOrderButton = true;
                console.log('this.showAddToPurchaseOrderButton in else :>> ', this.showAddToPurchaseOrderButton);
                this.enabledRowCount = 10;
            }
            

        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }


    doSorting(event) {
        this.sortByName = event.detail.fieldName == 'Item_Number__c' ? 'Part/Item #' : event.detail.fieldName == 'Stock_class__c' ? 'Stock/Vendor' : 'Name';
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
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

    handleDropDown(event) {
        console.log(this.recordId);
        this.data = [];
        this.isLoaded = true;
        this.productType = event.detail.value == 'Miscellaneous' ? 'Product_Type__c = \'MISC Charge Items\'' : 'Product_Type__c IN (\'Merchandise\',\'Parts\')';
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: ['Name', 'Stock_class__c', 'Stock_Status__c', 'Class__c' ,'Item_Number__c','Last_Cost__c'], filterBy: this.productType })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = this.data.length;
            })
            .catch(error => {
                console.log('no Data');
            })
    }

    handleSearch(event) {
        if(event.keyCode === 13){
        this.isLoaded = true;
        console.log(this.productType);
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: ['Name', 'Stock_class__c', 'Stock_Status__c', 'Class__c' ,'Item_Number__c', 'Last_Cost__c'], filterBy: (this.productType + ' and (Stock_class__c Like \'%' + event.target.value + '%\' or Item_Number__c Like \'%' + event.target.value + '%\' or Name Like \'%' + event.target.value + '%\')') })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = this.data.length;
            })
            .catch(error => {
                console.log('no Data');
            })
        }
    }

    handleFilter(event) {
        console.log('filter');
        this.filterVisibility = this.filterVisibility ? false : true;
        
    }
     handleRadioButtonChange(event) {
        console.log('sales');
        this.salesVisibility = true;     
        //this.data = 'slds-hide';   
        console.log('radio id--> ' + event.currentTarget.dataset.id);
        const val =  event.currentTarget.dataset.id; 
        //const ucost =  event.currentTarget.dataset.cost;
         const filtertest = this.data.find(option => option.Id === val);
         console.log(filtertest); 
         this.singleUnitCost = filtertest.Last_Cost__c;
          console.log('UnitCost',this.singleUnitCost ); 
         this.title = filtertest.Name;
        console.log('ProductName',this.title); 
        this.productId = filtertest.Id; 
        console.log('ProductId',this.productId); 
        this.singleItemNumber=filtertest.Item_Number__c;
        this.stockclass=filtertest.Stock_class__c;
        this.stockstatus=filtertest.Stock_Status__c;
        this.itemclass=filtertest.Class__c;  
        this.singleRecordId=filtertest.Id;
        

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
              /*const val =  event.target.dataset.id;  
              //const filtertest = this.data.find(option => option.Id === val);
              //console.log(filtertest); 
              this.showQtyErrorBox = false;
            //this.recordId = filtertest.Id;
            this.singleRecordId=filtertest.Id;
            this.newSingleUnitValue=filtertest.singleUnitCost;
            this.singleItemNumber=filtertest.Item_Number__c;
            this.singleQuantity=filtertest.quantity;
            this.stockclass=filtertest.Stock_class__c;
            this.stockstatus=filtertest.Stock_Status__c;
            this.itemclass=filtertest.Class__c;*/
            this.newSingleUnitValue=this.singleUnitCost;
            this.singleQuantity=this.quantity;

            createPOLineItem({recordId:this.recordId,singleRecordId:this.singleRecordId, newSingleUnitValue:this.newSingleUnitValue, singleItemNumber:this.singleItemNumber, singleQuantity:this.singleQuantity,stockclass:this.stockclass,stockstatus:this.stockstatus,itemclass:this.itemclass})
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
            this.dataRefresh();
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

    handleStockVendorInput(event) {
        this.stockVendorInput = event.target.value;
    }

    handlePartItemNoInput(event) {
        this.partItemNoInput = event.target.value;
    }

    handleApply(event) {
        this.data = [];
        this.isLoaded = true;
        this.template.querySelector('lightning-input[data-name=searchBox]').value = '';
        let whereClause = (this.productType + (this.stockVendorInput != '' ? ' and Stock_class__c Like \'%' + this.stockVendorInput + '%\'' : '') + (this.partItemNoInput != '' ? ' and Item_Number__c Like \'%' + this.partItemNoInput + '%\'' : ''));
        console.log(whereClause);
        getProduct({ recordId: this.recordId, objectName: 'Product2', fieldName: ['Name', 'Stock_class__c', 'Stock_Status__c', 'Class__c' ,'Item_Number__c', 'Last_Cost__c'], filterBy: whereClause })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = this.data.length;
            })
            .catch(error => {
                console.log('no Data');
            })
            this.handleCancel();
    }

    handleCancel() {
        console.log(this.stockVendorInput);
        this.filterVisibility = false;
        console.log(this.stockVendorInput);
    }

    handleReset() {
        console.log('reset method');
        this.template.querySelector('lightning-input[data-name=stockVendor]').value = this.stockVendorInput = '';
        this.template.querySelector('lightning-input[data-name="partItemNo"]').value = this.partItemNoInput = '';
    }

    handleClose() {
        this.filterVisibility = false;    
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        const rowID = event.detail.config.value;
        console.log('deselected Id : ', rowID, event);
        const selectionAction = event.detail.config.action;
        if (selectionAction == "rowDeselect") {
           
            console.log('Map after deleting Row in  handleRowSelection: ',rowID,  this.myMap2);
            this.myMap2.delete(rowID);
        }
        
        if(this.selectedRows.length>0) {
            this.onrowselection=true;
            this.title=this.selectedRows[0].Name;
            this.singleUnitCost=this.selectedRows[0].Last_Cost__c;
            this.selectedRowCount=this.selectedRows.length;
            if (this.selectedRowCount===1) {
                this.singleRow=true;
            } else {
                this.singleRow=false;
                this.quantity=1;
            }
        } else {
            this.onrowselection=false;
            this.quantity=1;
        }

        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-comp")].forEach((element) => {
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

    getSelectedRecords()
    {
        var selectedRecords=this.template.querySelector("lightning-datatable").getSelectedRows();
        if (selectedRecords.length>0)
        {
            
            this.listSelectedRecords=selectedRecords;
               
        }
    }

    async dataRefresh(){
        this.template.querySelector('lightning-datatable').selectedRows=[]; 
        await refreshApex(this.dataToRefresh);
    }
   

    handleAddPurchaseOrder() {
        let isSelfValidated = true;
        isSelfValidated = [
            ...this.template.querySelectorAll("lightning-input")
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if (isSelfValidated) {
            this.showQtyErrorBox = false;
            // Old Code STARTS....................................................
            this.singleRecordId=this.selectedRows[0].Id;
            this.newSingleUnitValue=this.singleUnitCost;
            this.singleItemNumber=this.selectedRows[0].Item_Number__c;
            this.singleQuantity=this.quantity;
            this.stockclass=this.selectedRows[0].Stock_class__c;
            this.stockstatus=this.selectedRows[0].Stock_Status__c;
            this.itemclass=this.selectedRows[0].Class__c;

            createPOLineItem({
                recordId:this.recordId,
                singleRecordId:this.singleRecordId, 
                newSingleUnitValue:this.newSingleUnitValue, 
                singleItemNumber:this.singleItemNumber, 
                singleQuantity:this.singleQuantity,
                stockclass:this.stockclass,
                stockstatus:this.stockstatus,
                itemclass:this.itemclass
            })
            .then(()=>{
                this.dispatchEvent(
                        new ShowToastEvent({
                            message : 'Added to Purchase Order Successfully',
                            title : 'Success',
                            variant : 'Success'
                    })
                );
                this.onrowselection=false;
                
                this.template.querySelector("lightning-datatable").selectedRows=[]; 
                refreshApex(this.dataToRefresh);
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
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
                        title : 'Error while adding to Purchase Order',
                        message : error.body.message ,
                        variant : 'error'
                    })
                );
            })
            this.dataRefresh();
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
    }

    handleAddPurchaseOrder2() {
        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-comp")].forEach((element) => {
            if (element.checkValidity() === false) {
            isValidated = false;
            }
        });
        if(isValidated){
            this.showQtyErrorBox = false;
            // Old Code STARTS....................................................
            this.singleQuantity=this.quantity;

            let rowIdkeys = Array.from(this.myMap2.keys());
            let rowIdValues =  Array.from(this.myMap2.values());
            let updatedvalues = rowIdValues.map(value => value.updatedValue);
            let unitCostValues = rowIdValues.map(value => value.unitCostValue);
            let stockClassValues = rowIdValues.map(value => value.stockClassValue);
            let itemNumberValues = rowIdValues.map(value => value.itemNumber);
            console.log("##### rowIdkeys : "+rowIdkeys);
            console.log("##### rowIdValues : "+rowIdValues);
            console.log("##### updatedvalues : "+updatedvalues);
            console.log("##### unitCostValues : "+unitCostValues);
            console.log("##### stockClassValues : "+stockClassValues);
            console.log("##### itemNumberValues : "+itemNumberValues);
            createBulkPOLineItem({
                recordId:this.recordId,
                RowsIds:rowIdkeys, 
                RowsCostValues:unitCostValues,
                RowsItemNumbers:itemNumberValues,
                values:updatedvalues,
                selectedRowsStockValues:stockClassValues
            })
            .then(()=>{
                this.dispatchEvent(
                        new ShowToastEvent({
                            message : 'Added to Purchase Order Successfully',
                            title : 'Success',
                            variant : 'Success'
                    })
                );
                this.onrowselection=false;
                this.template.querySelector("lightning-datatable").selectedRows=[]; 
                refreshApex(this.dataToRefresh); 
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                this.myMap2.clear();
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
                        title : 'Error while Adding to Purchase Order',
                        message : error.body.message ,
                        variant : 'error'
                    })
                );
                //Publish to message channel
                const payload = {
                    recordId: this.recordId,
                    recordUpdated: false
                };
                publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
            });
            // Old Code STARTS....................................................
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
        // ******************************************************
    }

    decreaseQuantity(event)
    {
        if(this.quantity>1)
        {  
            this.quantity--;    
        }
    }

    increaseQuantity(event)
    {
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

    removeAll(event)
    {
        this.onrowselection=false;
        this.template.querySelector("lightning-datatable").selectedRows=[]; 
        refreshApex(this.dataToRefresh);
        this.myMap2.clear(); 
    }

    handleValueChange(event)
    {
        const rowId=event.detail.rowId;
        const updatedValue=event.detail.updatedQuantity;
        const unitCostValue = event.detail.unitCostValue;
        const itemNumber=event.detail.itemNumber;
        const stockClassValue=event.detail.stockValues;
               console.log("event.detail.updatedQuantity---->"+event.detail.updatedQuantity);
        this.myMap2.set(rowId,{updatedValue: updatedValue,unitCostValue: unitCostValue,itemNumber: itemNumber,stockClassValue: stockClassValue});

        const RowsIds = this.selectedRows.map(row => row.Id);
        console.log('Selected Rows',JSON.stringify(RowsIds));
        for (const [rowId, _] of this.myMap2) {
            if (!RowsIds.includes(rowId)) {
                // If not present, remove it from myMap2
                this.myMap2.delete(rowId);
            }
        }        
    }

    handleCloseNotification(){
        this.showErrorMessage = false;
    }
     
    handleCloseRow(event)
    {
        const rowId=event.detail.rowId;
        console.log(rowId);
        this.selectedRows=this.selectedRows.filter((row) => row.Id != rowId);
        console.log(JSON.stringify(this.selectedRows));
        let dt = this.template.querySelector('lightning-datatable');
        dt.selectedRows = this.selectedRows.map(x=>x.Id); 
        console.log(JSON.stringify(this.selectedRows.length));
        this.myMap2.delete(rowId);
        /*if (this.selectedRows.length === 1) {
            this.singleRow = true;
        }*/
        if(this.selectedRows.length===0)
        {
            this.onrowselection=false;
            this.template.querySelector("lightning-datatable").selectedRows=[]; 
            this.refresDataTable();
            this.myMap2.clear();
        }
        let isValidated = true;
            [...this.template.querySelectorAll("c-sbr_3_0_product-unit-cost-comp")].forEach((element) => {
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
    
    async refresDataTable(){
        refreshApex(this.dataToRefresh);
    }
}