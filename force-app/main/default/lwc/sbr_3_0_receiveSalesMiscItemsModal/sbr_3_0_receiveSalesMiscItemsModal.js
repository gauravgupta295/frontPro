import { LightningElement, api, wire } from 'lwc';
import LABELS from "c/sbr_3_0_poCustomLabelsCmp";
import getUserProductItems from '@salesforce/apex/SBR_3_0_POReceiveItems.getUserProductItemsByProductIds';
import receiveMiscItems from '@salesforce/apex/SBR_3_0_POReceiveItems.receiveMiscItems';
//Message Channel
import { MessageContext, publish } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Item Number', fieldName: "Item_Number__c", initialWidth: 200, wrapText: true, sortable: 'true' },
    { label: 'Item Description', fieldName: 'Item_Description_Calc__c', type: 'text', initialWidth: 200, wrapText: true, sortable: 'true' },
    { label: 'Manufacturing #', fieldName: 'Manufacturer__c', type: 'text', initialWidth: 200, wrapText: true, sortable: 'true' },
    { label: 'Cat Class', fieldName: 'CatClass__c', type: 'text', initialWidth: 200, wrapText: true, sortable: 'true' },
    { label: 'Serial #', fieldName: 'serialNumber', initialWidth: 120, editable: true},
    { label: 'Bin 1', fieldName: 'bin1', initialWidth: 90, editable: true },
    { label: 'Bin 2', fieldName: 'bin2', initialWidth: 90, editable: true }
];

export default class Sbr_3_0_receiveSalesMiscItemsModal extends LightningElement {

    @api purchaseOrderId;
    @api receiveItemType;
    @api receiveItemsInput;

    @wire(MessageContext)
    messageContext;

    productIds = [];
    productItems = [];
    receiveItemsDraft = [];
    receiveItemsFinal = [];
    draftValues = [];
    
    receiveItemsMessage = LABELS.RECEIVE_ITEMS_MESSAGE;
    errorMessage = LABELS.RECEIVE_ITEMS_ERROR_MESSAGE;

    columns = columns;
    receiverComments;

    showErrorMessage = false;
    showSpinner = false;
    showTable = false;
    isDisabled = false;

    sortBy;
    sortDirection;
    error;

    connectedCallback() {
        this.isDisabled = (this.receiveItemsInput && this.receiveItemsInput.length > 0) ? false : true;
        if(this.receiveItemType && this.receiveItemType.toUpperCase() === 'SALE'){
            this.showTable = true;
            this.getProductItems();
        }
        else {
            this.showTable = false;
            this.receiveItemsMessage = 'Enter comments below if needed. Otherwise, simply click Receive Item(s) to create the Receipt.';
        }
    }

    getProductItems(){
        if (this.receiveItemsInput.length > 0) {
            this.productIds = this.receiveItemsInput.map(item => item.Item_Desc__c);
            getUserProductItems({productIds : this.productIds})
            .then((data) => {
                this.productItems = data;
            })
            .catch((error) => {
                this.error = error;
                console.error(this.error);
            })
            .finally(() => {
                this.fillDataTable();
            })
        }
    }

    fillDataTable() {
        let bin1;
        let bin2;
        let bin3;
        let serialNumber;
        if (this.receiveItemsInput.length > 0) {
            let dataTableArray = [];
            this.receiveItemsInput.forEach(item => {
                let draftItem = {...item, bin1, bin2, bin3, serialNumber};
                if(this.productItems.length > 0 && this.productItems.some(pi => pi.Product2Id === item.Item_Desc__c)){
                    let prodItem = this.productItems.find(pi => pi.Product2Id === item.Item_Desc__c)
                    draftItem.bin1 = prodItem.SM_PS_Bin_Location_1__c;
                    draftItem.bin2 = prodItem.SM_PS_Bin_Location_2__c;
                    draftItem.bin3 = prodItem.SM_PS_Bin_Location_3__c;
                    draftItem.serialNumber = prodItem.SerialNumber;
                }
                dataTableArray.push(draftItem);
            });            
            this.receiveItemsDraft = dataTableArray;
        }
    }


    handleCommentChange(event){
        this.receiverComments = event.detail.value;
    }

    handleCancel(event){
        this.template.querySelector('lightning-datatable').draftValues = [];
        this.dispatchEvent(new CustomEvent("closereceiveitem", {
            detail : {
                action : 'Cancel'
            }
        }));
    }

    handleReceiveItems(event) {
        console.log(this.receiveItemType.toUpperCase());
        let serializedItems = [];
        if(this.receiveItemType && this.receiveItemType.toUpperCase() === 'SALE'){
            this.receiveItemsFinal = []; 

            let draftValues = this.template.querySelector('lightning-datatable').draftValues;
            if(draftValues && draftValues.length > 0){
                draftValues.forEach(x=> {
                    let index = this.receiveItemsDraft.findIndex(y => y.Id === x.Id);
                    Object.keys(x).forEach(key => {
                        this.receiveItemsDraft[index][key] = x[key];
                    })                    
                })    
            }
           
            this.receiveItemsDraft.forEach(x=>{
                if(x.Item_Desc__r.Track_by_Serial_Number__c === true && !x.serialNumber){
                    serializedItems.push(x.Item_Number__c.toString());
                }
            })

            if(serializedItems.length > 0){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Serial number needed',
                        message: 'Following item(s) are tracked by serial number: ' +serializedItems.join(", "),
                        variant: 'error',
                        mode : "sticky"
                    })
                );
                return;
            }
            else{
                this.receiveItemsDraft.forEach(x => {
                    let poReceipt = {};
                    poReceipt.Purchase_Order__c = x.Purchase_Order__c;
                    poReceipt.PO_Line_Item__c = x.Id;
                    poReceipt.Item_Type__c = x.Item_Type__c;
                    poReceipt.Quantity_Received__c = x.receivedQty;
                    poReceipt.Serial_Number__c = x.serialNumber;
                    poReceipt.Bin_1__c = x.bin1;
                    poReceipt.Bin_2__c = x.bin2;
                    poReceipt.Last_Cost__c = x.Last_Cost__c;
                    poReceipt.Unit_Cost__c = x.Unit_Cost__c;
                    poReceipt.Status__c = x.Status__c;        
                    poReceipt.Units__c = (x.Units__c && x.Units__c.includes('(')) ? x.Units__c.match(/\(([^)]+)\)/)[1] : x.Units__c;
                    poReceipt.Messages__c = this.receiverComments;
                    this.receiveItemsFinal.push(poReceipt);
                })
            }
        }
        else if(this.receiveItemType && this.receiveItemType.toUpperCase() === 'ASSET' || 
                this.receiveItemType && this.receiveItemType.toUpperCase() === '3RD PARTY'){
            this.receiveItemsFinal = [];
            this.receiveItemsInput.forEach(x => {
                let poReceipt = {};
                poReceipt.Purchase_Order__c = x.Purchase_Order__c;
                poReceipt.PO_Line_Item__c = x.Id;
                poReceipt.Item_Type__c = x.Item_Type__c;
                poReceipt.Quantity_Received__c = (this.receiveItemType && this.receiveItemType.toUpperCase() === 'ASSET') 
                                                    ? x.receivedAssetQty : x.receivedQty;                
                poReceipt.Last_Cost__c = x.Last_Cost__c;
                poReceipt.Unit_Cost__c = x.Unit_Cost__c;
                poReceipt.Status__c = x.Status__c;        
                poReceipt.Units__c = (x.Units__c && x.Units__c.includes('(')) ? x.Units__c.match(/\(([^)]+)\)/)[1] : x.Units__c;
                poReceipt.Messages__c = this.receiverComments;
                this.receiveItemsFinal.push(poReceipt);
            })
        }
        this.handleSaveRecords();
        
    }
    
    async handleSaveRecords() {
        this.showSpinner = true;
        this.showErrorMessage = false;
        if (this.receiveItemsFinal.length > 0) {
            let receiveItemsString = JSON.stringify(this.receiveItemsFinal);
            await receiveMiscItems({ purchaseOrderId: this.purchaseOrderId, receiveItemsString: receiveItemsString, receiverComments: this.receiverComments })
                .then(result => {
                    const payload = {
                        recordId: this.purchaseOrderId,
                        recordUpdated: true
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                    this.dispatchEvent(new CustomEvent("closereceiveitem", {
                        detail : {
                            action : 'Save',
                            receiveItemType : this.receiveItemType
                        }
                    }));
                })
                .catch(error => {
                    console.log('--error--' + JSON.stringify(error));
                    console.log(error);
                    this.showErrorMessage = true;
                });
        }
        this.showSpinner = false;
    }

    handleSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.receiveItemsDraft));
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
        this.receiveItemsDraft = parseData;
    }

}