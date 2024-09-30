import { LightningElement, track, wire, api } from 'lwc';
import getContract from '@salesforce/apex/sbr_3_0_PurchaseOrderContractSearch.getContract';
import getSearchResults from '@salesforce/apex/sbr_3_0_PurchaseOrderContractSearch.getSearchResults';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import FORM_FACTOR from "@salesforce/client/formFactor";

const columns = [
    { label: 'Contract Number', initialWidth: 150, fieldName: 'Contract_Order_Number__c', type: 'button', typeAttributes: { label: { fieldName: 'Contract_Order_Number__c' }, variant: "base" }, wrapText: true, sortable: 'true' },
    { label: 'Account Name', initialWidth: 150, fieldName: 'accountName', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Account Number', initialWidth: 150, fieldName: 'accountNumber', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Status', initialWidth: 100, fieldName: 'Status', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Contract Start Date', initialWidth: 180, fieldName: 'EffectiveDate', type: 'date', wrapText: true, sortable: 'true', typeAttributes: { month: "2-digit", day: "2-digit", year: "2-digit" } },
    { label: 'Contract End Date', initialWidth: 180, fieldName: 'EndDate', type: 'date', wrapText: true, sortable: 'true', typeAttributes: { month: "2-digit", day: "2-digit", year: "2-digit" } },
];

const contractFields = ['Contract_Order_Number__c', 'Account.Name', 'Account.RM_Account_Number_Display__c', 'Status', 'EffectiveDate', 'EndDate', 'Id', 'Name', 'AccountId', 'OrderNumber', 'Start_Date__c'];


export default class Sbr_3_0_purchaseOrderContractSearchModal extends LightningElement {


    data;
    columns = columns;
    sortBy;
    sortDirection;
    filterVisibility = false;
    totalNoOfRecords = 0;
    @api searchString;
    getsearchvalue = '';
    hidecheckbox = true;
    isCssLoaded = false;
    accountName;
    @api recordId;
    @api openModal;
    accountNumber;

    // @api openAddFrieghtModal;



    connectedCallback() {
        if (!this.isCSSLoaded) {
            Promise.all([
                loadStyle(this, PO_CSS + '/POlwc.css')
            ]).then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
                console.log('RecordId', this.recordId);
                this.getContracts();
            }).catch(error => {
                window.console.log('error loading CSS');
            });
        }
    }


    getContracts() {
        console.log('inside getContracts : ');

        getContract({ recordId: this.recordId, objectName: 'Order', fieldName: contractFields })
            .then(result => {
                console.log('inside getContract>> : ');

                if (result && result.length > 0) {
                    // Iterate through each record
                    result.forEach(record => {
                        if (record.Account) {
                            const accountName = record.Account.Name;
                            const accountNumber = record.Account.RM_Account_Number_Display__c;

                            console.log('accountName >> : ', JSON.stringify(accountName));
                            console.log('RM_Account_Number_Display__c >> : ', JSON.stringify(accountNumber));

                            // Process the record or store the values as needed
                        } else {
                            console.error('Account Name not found in the result.');
                        }
                    });

                    this.data = result;
                    // console.log('result : ', JSON.stringify(result));
                    console.log('Contract_Order_Number__c> >  : ', JSON.stringify(result.Contract_Order_Number__c));
                    this.processRecords();
                } else {
                    console.error('No records found.');
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleSearch(event) {
        if (event.keyCode === 13) {
            console.log('RecordId', this.recordId);
            this.searchString = [event.target.value];
            getSearchResults({ recordId: this.recordId, searchString: event.target.value })
                .then(result => {
                    this.data = result;
                    this.processRecords();
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

    handleCancel(event) {
        console.log('in cancel event');
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('closecontractmodal'));
        this.openModal = false;
        this.getContracts();
    }
    handleClear(event) {
        if (!event.target.value.length) {
            this.getContracts();
        }
    }

    handleRowAction(event) {
    
        const record = event.detail.row;
        console.log('record>>> : ', JSON.stringify(record));
        const selectEvent = new CustomEvent('selectrecords', {
            detail: { record },
        });
        this.dispatchEvent(selectEvent);

        // Refresh contract search result and reset filters
        this.getContracts();

    }

    reload() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    getSearchValue(event) {
        this.data = event.detail;
        this.processRecords();
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
        console.log('into processRecords >> : ');

        this.data = this.data.map(con => {
            console.log('into processRecords map >> : ');
            return {
                ...con,
                accountName: con.Account ? con.Account.Name : null,
                accountNumber: con.Account ? con.Account.RM_Account_Number_Display__c : null,
            };
        });

        Object.preventExtensions(this.data);
        this.totalNoOfRecords = this.data.length;
    }

}