import { LightningElement, wire,api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import FORM_FACTOR from "@salesforce/client/formFactor";
import  {getRecord}  from 'lightning/uiRecordApi';
import RECORD_TYPE from '@salesforce/schema/Purchase_Order__c.RecordTypeId';
const SMALL_FORM_FACTOR = "Small";
const poFields = [RECORD_TYPE];

export default class Sbr_3_0_itemSearchMobileWrapper extends LightningElement {
    quickLinks = [];
    @api recordId;
    record;
    error;
    dataToRefresh;
    searchString;
    isCSSLoaded = false;
    hasRendered = false;
    vendorClass = 'slds-show';
    purchaseOrderClass = 'slds-hide';


     @wire(getRecord, { recordId: '$recordId', fields: poFields })
    wiredRecord(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.record = result.data;
            console.log('Record Id:', this.recordId);
        }
         else if (result.error) {
            this.error = result.error;
            console.error(this.error);
        }
    }

   
    renderedCallback() {
        if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.refs.vendors.classList.add('activeTab');
        }
    }

    handleClick(event) {
        let tabVal = event.currentTarget.dataset.id;
        if (tabVal === 'vendors') {
            this.refs.vendors.classList.add('activeTab');
            this.refs.purchaseOrders.classList.remove('activeTab');
            this.vendorClass = 'slds-show';
            this.purchaseOrderClass = 'slds-hide';
        }
        else if (tabVal === 'purchaseOrders') {
            this.refs.purchaseOrders.classList.add('activeTab');
            this.refs.vendors.classList.remove('activeTab');
            this.purchaseOrderClass = 'slds-show';
            this.vendorClass = 'slds-hide';
        }
    }
    
}