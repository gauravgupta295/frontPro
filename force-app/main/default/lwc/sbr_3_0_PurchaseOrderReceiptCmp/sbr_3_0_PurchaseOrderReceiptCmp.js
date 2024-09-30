import { LightningElement, api,wire, track } from 'lwc';
import getReceiptRecords from '@salesforce/apex/SBR_3_0_PurchaseOrderReceiptCntrl.getReceiptRecords';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from "lightning/refresh";
//Message Channel
import { MessageContext, APPLICATION_SCOPE, subscribe, publish } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';

const columnsReceiverComment = [
    { label: 'Rsv #', fieldName: "Receiver_Number__c"},
    { label: 'Seq #', fieldName: "Receiver_Seq__c"},
    { label: 'Comments', fieldName: "Messages__c"}
    ];

export default class Sbr_3_0_PurchaseOrderReceiptCmp extends LightningElement {
    subscription;
    @wire(MessageContext)
    messageContext
    @api recordId;
    columnsReceiverComment = columnsReceiverComment;
    activeSections = ['Receiver Comments'];
    @track receiptRec = [];
    @track receiptRcvRec = [];
    totalCost = 0;
    receiverLabel;
    dataToRefresh=[];
    isRender = false;
    isRefresh = false;

    connectedCallback() {
        this.isRender = false;
        //Subscribe to the message channel
        this.subscription = subscribe(this.messageContext, PurchaseOrderLineItemMessageChannel,
            (result) => {
                if (result != undefined) {
                    this.isRender = true;
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

    @wire(getReceiptRecords, { recordId: '$recordId' })
        wiredReceiptRecord(result){
            this.dataToRefresh = result;
            if(result.data){
                this.isRender = true;
                console.log('OUTPUT : ', result);
                this.receiptRec = result.data.receiptRec;
                this.receiverLabel = 'Receiver Comments ('+this.receiptRec.length.toString()+')'
                this.receiptRcvRec = result.data.receiptRcvRec;
                console.log('this.receiptRcvRec.length:', this.receiptRcvRec.length);
                this.totalCost = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 3}).format(result.data.totalCost);
            }
            else{
                console.log('error',result.error);
            }
    }

    handleSectionToggle() {
        console.log('toggle');
    }

    async handleRefresh(event) {
        if (event.detail == 'Success') {
            this.isRefresh = true;
            await refreshApex(this.dataToRefresh);
            this.template.querySelectorAll('c-sbr_3_0_-purchase-order-receipt-receiver-cmp').forEach(elem =>
                elem.orchestrateData('reRender')
            );
            const payload = {
                recordId: this.recordId,
                recordUpdated: this.isRefresh
            };
            publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
            this.isRefresh = false;
        }
    }
}