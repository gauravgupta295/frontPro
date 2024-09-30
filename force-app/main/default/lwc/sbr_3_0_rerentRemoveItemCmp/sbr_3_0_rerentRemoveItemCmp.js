import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import FORM_FACTOR from '@salesforce/client/formFactor';
import deletePOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.deletePOLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const SMALL_FORM_FACTOR = "Small";
export default class Sbr_3_0_rerentRemoveItemCmp extends LightningElement {
    _records;
    isCSSLoaded = false;
    @track recordList = [];
    @track selectedRows = [];

    @api
    set records(value) {
        this._records = value;
    }
    get records() {
        return this._records;
    }
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
        let elem = this.template.querySelector('[data-id="removeItemCmp"]');
        if(elem) {
            elem.refreshRecords(this.recordList);
            elem.checkAll = true;
        }
    }
    connectedCallback() {
        if (this.records.length > 0) {
            this.records.forEach(currentItem => {
                this.selectedRows.push(currentItem.Id);
            });
        }
        this.createRecordListForMobile();
    }

    handleCheckboxChange(event) {
        const recordId = event.detail.id;
        console.log('recordId:', recordId);
        //Push to array when checkbox is checked
        if (event.detail.checked && !this.selectedRows.includes(recordId)) {
            this.selectedRows.push(recordId);
        }
        else {
            //Remove from array when checkbox is unchecked
            let index = this.selectedRows.indexOf(recordId);
            if (index > -1) {
                this.selectedRows.splice(index, 1);
            }
        }
    }

    handleRemoveItems() {
        let returnVal = 'Success';
        if (this.selectedRows.length > 0) {
            deletePOLineItems({ selectedRowIDs: this.selectedRows })
                .then(result => {
                    if (result == true) {
                        returnVal = 'Success';
                    }
                    else {
                        returnVal = 'Error';
                    }
                })
                .catch(error => {
                    console.log(error);
                    returnVal = 'Error';
                })
                .finally(() => {
                    this.dispatchEvent(new CustomEvent('remove', {
                        detail: {
                            output: returnVal
                        }
                    }));
                });
        }
        else {
            const evt = new ShowToastEvent({
                title: '',
                message: 'Please select one or more records to remove.',
                variant: 'warning',
            });
            this.dispatchEvent(evt);
        }
    }

    handleGoBack() {
        this.dispatchEvent(new CustomEvent('close', {
            detail: {
                selectedRows: this.selectedRows
            }
        }));
    }
    createRecordListForMobile() {
        this.recordList = [];
        if (this.records.length > 0) {
            this.records.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.isHeaderLink = false;
                record.isEditEnabled = true;
                record.headerText = rec.Item_Number__c;
                record.hasCheckbox = true;
                record.isCheckboxChecked = true;
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
                this.recordList.push(record);
            });
        }
    }
}