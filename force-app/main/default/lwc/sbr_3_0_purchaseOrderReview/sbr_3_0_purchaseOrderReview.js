import { LightningElement, wire, api, track } from 'lwc';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import NAME_FIELD from "@salesforce/schema/Purchase_Order__c.Name";
import { refreshApex } from '@salesforce/apex';
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
import FORM_FACTOR from '@salesforce/client/formFactor';

const SMALL_FORM_FACTOR = "Small";
/*Start - Yash code*/
const columns = [
    {
        label: 'Item Number',
        fieldName: 'Item_Number__c'
    },
    {
        label: 'Item Description',
        fieldName: 'Item_Description_Calc__c'
    },
    {
        label: 'Qty',
        fieldName: 'Quantity__c',
        type: 'number',
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: true,
        typeAttributes: { minimumFractionDigits: 2 }
    },
    {
        label: 'Unit Cost',
        fieldName: 'Unit_Cost__c',
        type: 'number',
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: true,
        typeAttributes: { minimumFractionDigits: 3 }
    },
    {
        label: 'Extended Cost',
        fieldName: 'Total_Cost_Calc__c',
        type: 'currency',
        cellAttributes: { alignment: 'right' },
        hideDefaultActions: true,
        typeAttributes: { minimumFractionDigits: 3 }
    }

];

/*End - Yash code*/
const fields = [NAME_FIELD];


export default class Sbr_3_0_purchaseOrderReviewLwc extends LightningElement {
    subscription;
    @wire(MessageContext)
    messageContext
    @api recordId;
    @track totallineItems = [];
    @track columns = columns;

    totalQty;
    totalExtendedCost;
    totalSalesQty = 0;
    colDisplay4 = [];
    salesCost = 0;
    totalSalesCost = 0;
    totalLabel;
    lineItems = [];
    purchaseOrderComments;
    record = [];
    salesRecordList = [];
    activeSections = ['Sales'];

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
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }


    @wire(getRecord, { recordId: "$recordId", fields })
    purchaseOrder;

    get recName() {
        return getFieldValue(this.purchaseOrder.data, NAME_FIELD);
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
                        refreshApex(this.totallineItems);
                    }
                }
            }
        );
    }

    createRecordListForMobile(records, type) {
        this.salesRecordList = [];
        if (records.length > 0) {
            records.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.isHeaderLink = false;
                record.isEditEnabled = true;
                record.headerText = rec.Item_Number__c;
                record.hasCheckbox = false;
                record.hasSelectEvent = false;
                record.hasStatus = false;
                record.hasSearch = false;
                record.isVendorFilter = false;
                record.isPurchaseOrderFilter = false;
                record.hasButtonsMenu = true;
                record.noHeaderSection = true;
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
                this.salesRecordList.push(record);
                this.salesRecordList.push({ isLineSeparator: true });

            });
        }

        this.template.querySelector('[data-id="salesCmp"]').refreshRecords(this.salesRecordList);


    }


    @wire(getPOLineItems, { purchaseOrderID: '$recordId' })
    wiredLineItems(result) {
        console.log(JSON.stringify(result));
        if (result.data) {
            this.totallineItems = result.data;
            if (this.totallineItems.length > 0) {
                this.totalSalesQty = 0;
                this.salesCost = 0;
                this.totallineItems.forEach(item => {
                    let salesQty = parseFloat(this.totalSalesQty) + (parseFloat(item.Quantity__c) || 0);
                    this.totalSalesQty = salesQty.toFixed(2);
                    this.salesCost += parseInt(item.Total_Cost_Calc__c) || 0;
                });
                this.totalSalesCost = this.totallineItems.reduce((sum, record) => sum + (record.Total_Cost_Calc__c || 0), 0);
                this.totalSalesCost = this.formatCurrency(this.totalSalesCost);
            } else {
                this.salesCost = 0;
                this.totalSalesQty = 0;
            }
            if (this.isMobileView) {
                this.createRecordListForMobile(this.totallineItems, 'salesCmp');
            }
        }
    }
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3 }).format(value);
    }
    handleEditScreen(event) {
        this.lineItemRecId = event.detail.recordId;
        this.openEditScreen = true;
    }

}