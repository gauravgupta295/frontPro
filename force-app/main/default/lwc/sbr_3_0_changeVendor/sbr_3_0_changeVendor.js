import { LightningElement,track, wire, api } from 'lwc';
import getVendorName from '@salesforce/apex/SBR_3_0_ChangeVendorController.getVendorName';
import getSearchResults from '@salesforce/apex/SBR_3_0_ChangeVendorController.getSearchResults';
import updateVendor from '@salesforce/apex/SBR_3_0_ChangeVendorController.updateVendor';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import MODAL_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_modalCSS';
import { loadStyle} from 'lightning/platformResourceLoader';
import FORM_FACTOR from "@salesforce/client/formFactor";
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";

const SMALL_FORM_FACTOR = "Small";

const columns = [
    { label: 'Vendor Name', initialWidth: 300, fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name' }, variant: "base", disabled: { fieldName: 'accountDisabled' } }, wrapText: true, sortable: 'true' },
    { label: 'Vendor Number', initialWidth: 150, fieldName: 'Vendor_Account_Number__c', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Vendor Status', initialWidth: 150, fieldName: 'currStatus', type: 'text', cellAttributes: { class: { fieldName: 'className' } }, wrapText: true, sortable: 'true' },
    { label: 'Billing Street', initialWidth: 200, fieldName: 'BillingStreet', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Billing State/Province', initialWidth: 150, fieldName: 'BillingState', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Zip/Postal Code', initialWidth: 150, fieldName: 'BillingPostalCode', type: 'text', wrapText: true, sortable: 'true' },
];

const vendorFields = ['Name', 'Vendor_Account_Number__c', 'ToLabel(Vendor_Status__c)', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'Id'];

export default class Sbr_3_0_changeVendor extends LightningElement {

    data;
    columns = columns; 
    sortBy;
    sortDirection;
    filterVisibility=false;
    totalNoOfRecords=0;
    recordList = [];
    recordType='RecordType.Name =\'Vendor\'';
    @api recordId;
    @api hideModal=false;
    @api searchString;
    getsearchvalue = '';
    hidecheckbox =true;
    isCssLoaded = false;
    noContentimageUrl = noContentSvg;
    hasRecords = true;

    renderedCallback(){
        this.setFocusOnFirstElement();
    }
    connectedCallback() {
        if (!this.isCSSLoaded) {
            Promise.all([
                //loadStyle(this, MODAL_CSS + '/POmodal.css'),
                loadStyle(this, PO_CSS + '/POlwc.css')
            ]).then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
                console.log('RecordId', this.recordId);
                this.getVendors();
            }).catch(error => {
                window.console.log('error loading CSS');
            });
        }
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
    getVendors() {
        getVendorName({ recordId: this.recordId, objectName: 'Account', fieldName: vendorFields, filterBy: this.recordType })
            .then(result => {
                this.data = result;
                this.hasRecords = this.data.length == 0 ? false : true;
                this.processRecords();
                if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table') != null){
                        this.createRecordListForMobile();
                    }
                    
            })
            .catch(error => {
                console.log(error);
            });
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;        
    }

    handleSearch(event) {
        if(event.keyCode === 13){
            console.log('RecordId',this.recordId);
            this.searchString = [event.target.value];
            getSearchResults({ recordId: this.recordId, searchString: event.target.value})
            .then(result => {
                this.data = result;
                this.hasRecords = this.data.length == 0 ? false : true;
                this.processRecords();
                if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table') != null){
                        this.createRecordListForMobile();
                    }
            })
            .catch(error => {
                console.log(error);
            });
        }
    }
    
    handlefilter(event) {
        console.log('filter');
        this.filterVisibility = this.filterVisibility ? false : true;
    }
    
    handleClear(event) {
        if (!event.target.value.length) {
            this.getVendors();
        }
    }

    createRecordListForMobile(){
        this.recordList = [];
        if(this.data.length > 0){
            this.data.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.headerText = rec.Name;
                record.hasStatus = true;
                record.statusText = ((rec.Vendor_Status__c === 'Hold Payment and Purchasing' || rec.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'On-Hold' : rec.Vendor_Status__c);
                record.hasSelectEvent = !rec.accountDisabled;
                record.isRowDisabled = rec.accountDisabled;
                let columns = [];
                let col={};
                col.type = 'text';
                col.key = 0;
                col.label='Vendor Number';
                col.value=rec.Vendor_Account_Number__c;
                columns.push(col);

                /*let col1={};
                col1.type = 'text';
                col1.key = 1;
                col1.label='Vendor Status';
                col1.value = rec.Vendor_Status__c;
                columns.push(col1); */

                let col2={};
                col2.type = 'text';
                col2.key = 2;
                col2.label='Billing Street';
                col2.value=rec.BillingStreet;
                columns.push(col2);
                record.columns = columns;

                let col3={};
                col3.type = 'text';
                col3.key = 3;
                col3.label='Billing State/Province';
                col3.value=rec.BillingState;
                columns.push(col3);
                record.columns = columns;

                let col4={};
                col4.type = 'text';
                col4.key = 4;
                col4.label='Zip/Postal Code';
                col4.value=rec.BillingPostalCode;
                columns.push(col4);
                record.columns = columns;
                this.recordList.push(record);
            });
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table').refreshRecords(this.recordList);
    }

    
    handleRowSelect(event){
        const record = event.detail.record;
        // this.template.querySelector("lightning-input[data-id='vendorSearch']").value = record.Name;
        // this.template.querySelector("lightning-input[data-id='vendorSearch']").reportValidity();
        // this.dispatchEvent(new FlowAttributeChangeEvent('VendorId', record.Id ));
        // this.dispatchEvent(new FlowAttributeChangeEvent('vendorNum', record.Vendor_Account_Number__c));
        //this.showModal = false;
        this.updateVendorRecord(this.recordId,record.Id);
    }
    
    updateVendorRecord(recordId, venRecId) {
        let evntTitle = 'Error';
        let evntType = 'Error updating records. Please Contact your System Administrator';
        let evntMsg = 'error';
        updateVendor({ recordId: recordId, vendorRecordId: venRecId })
            .then(result => {
                console.log('--result--' + result);
                if (result == 'Success') {
                    evntTitle = 'Success';
                    evntType = 'success';
                    evntMsg = 'Record updated successfully';
                }
                const event = new ShowToastEvent({
                    title: evntTitle,
                    message: evntMsg,
                    variant: evntType
                });
                this.dispatchEvent(event);
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.handleCloseModal();
                //this.showModal = false;
            })
            .catch(error => {
                console.log('--error--' + JSON.stringify(error));
                console.log(error);
                const event = new ShowToastEvent({
                    title: evntTitle,
                    message: evntMsg,
                    variant: evntType
                });
                this.dispatchEvent(event);
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
                this.handleCloseModal();
            });
    }
    async handleRowAction(event){
        const venRecord = event.detail.row;
        console.log('VendorId', venRecord.Id);
        console.log('PurchaseOrderId', this.recordId);
        await this.updateVendorRecord(this.recordId, venRecord.Id);
    }
    reload(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    getSearchValue(event){
        this.data = event.detail;
        this.hasRecords = this.data.length == 0 ? false : true;
        this.processRecords();
        if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table') != null) {
            this.createRecordListForMobile();
        }
    }
    handleSorting(event) {
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
    processRecords() {
        this.data = this.data.map(acc => {
            return {
                ...acc,
                className: (acc.Vendor_Status__c === 'Hold Payment and Purchasing' || acc.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'onhold' : (acc.Vendor_Status__c === 'Active') ? 'active' : 'none',
                currStatus: (acc.Vendor_Status__c === 'Hold Payment and Purchasing' || acc.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'On-Hold' : acc.Vendor_Status__c,
                accountDisabled: (acc.Vendor_Status__c == 'Hold Payment and Purchasing' || acc.Vendor_Status__c == 'Hold for Purchasing (Orders)') ? true : false
            };
        });
        Object.preventExtensions(this.data);
        this.totalNoOfRecords = this.data.length;
    }
    handleCloseModal() {
        this.hideModal = true;
        this.dispatchEvent(new CustomEvent('close'));
    }
    setFocusOnFirstElement() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        window.setTimeout(() => {
            if (!this._rendered) {
                let ele = this.template.querySelector('[data-name="searchBox"]');
                if (ele && ele.focus) {
                    ele.focus();
                    this._rendered = true;
                }
            }
        }, 5);
    }
}