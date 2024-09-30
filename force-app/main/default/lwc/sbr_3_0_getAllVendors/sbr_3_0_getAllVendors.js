import { LightningElement, api, track } from 'lwc';
import getVendorName from '@salesforce/apex/SBR_3_0_ChangeVendorController.getVendorName';
import getSearchResults from '@salesforce/apex/SBR_3_0_ChangeVendorController.getSearchResults';
import FORM_FACTOR from "@salesforce/client/formFactor";

const SMALL_FORM_FACTOR = "Small";

const actions = [
    {
        label: 'Start PO',
        name: 'startpo',
        title: 'Start PO',
        variant: 'border-filled',
        alternativeText: 'Start PO'
    }
];
const columns = [
    // {label: 'Vendor Name', type: 'button', typeAttributes: {label: { fieldName: "Name" },name: "edit",variant: "base"}},
    { label: 'Vendor Name', initialWidth: 300, fieldName: 'recordURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, tooltip: { fieldName: 'Name' }, target: '_self' }, wrapText: true, sortable: 'true' },
    { label: 'Vendor Number', initialWidth: 150, fieldName: 'Vendor_Account_Number__c', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Vendor Status', initialWidth: 150, fieldName: 'currStatus', type: 'text', cellAttributes: { class: { fieldName: 'className' } }, wrapText: true, sortable: 'true' },
    { label: 'Billing Street', initialWidth: 200, fieldName: 'BillingStreet', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Billing State/Province', initialWidth: 150, fieldName: 'BillingState', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Zip/Postal Code', initialWidth: 120, fieldName: 'BillingPostalCode', type: 'text', wrapText: true, sortable: 'true' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
        cellAttributes: { class: { fieldName: 'hideButtonClass' } }
    }
];
const vendorFields = ['Name', 'Vendor_Account_Number__c', 'ToLabel(Vendor_Status__c)', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'Id'];
export default class Sbr_3_0_getAllVendors extends LightningElement {
    allRecords;
    columns = columns;
    totalNoOfRecords = 0;
    @track isSearch = false;

    recordType = 'RecordType.Name =\'Vendor\'';
    @api recordId;
    @api searchString;
    isCSSLoaded = false;
    sortBy;
    sortDirection;
    renderFlow = false;
    bShowModalFlow = false;
    inputVariables;
    recordList = [];

    connectedCallback() {
        console.log('recordId', this.recordId);
        this.getVendors(this.recordType);
    }

    renderedCallback() {
        if (!this.isMobileView) {
            const self = this;
            document.addEventListener("click", (event) => {
                let hasNode = false;
                const path = event.composedPath();
                Array.prototype.forEach.call(path, function (entry) {
                    if (entry.nodeName == "c-sbr_3_0_changevendorfilter") {
                        hasNode = true;
                    }
                });
                if (!hasNode && path.length > 0) {
                    if (self.template.querySelector("c-sbr_3_0_changevendorfilter")) {
                        self.template
                            .querySelector("c-sbr_3_0_changevendorfilter")
                            .closeFilterDropDown();
                    }
                }
            });
        }
    }

    @api getVendors(filterClause) {
        if (filterClause == 'default') {
            this.isSearch = false;
        }
        //called from parent component
        filterClause = (filterClause == 'default') ? this.recordType : filterClause;
        getVendorName({ recordId: this.recordId, objectName: 'Account', fieldName: vendorFields, filterBy: filterClause })
            .then(result => {
                this.allRecords = result;
                this.processRecords();
            })
            .catch(error => {
                console.log(error);
            });
    }
    getSearchValue(event) {
        this.allRecords = event.detail;
        this.isSearch=true;
        this.processRecords();
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    handleReset() {
        this.handleSearch();
    }

    handleStartPO(event) {
        let recordId = event.detail.id;
        this.inputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: recordId
            }
        ];
        //Once set to true the flow will run
        this.renderFlow = true;
        this.bShowModalFlow = true;
    }

    @api handleSearch(searchVal) {
        this.searchString = searchVal;
        getSearchResults({ recordId: this.recordId, searchString: searchVal })
            .then(result => {
                this.allRecords = result;
                this.isSearch=true;
                this.processRecords();
            })
            .catch(error => {
                console.log(error);
            });
    }
    handleSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    sortData(fieldname, direction) {
        fieldname = (fieldname === 'recordURL') ? 'Name' : fieldname;
        let parseData = JSON.parse(JSON.stringify(this.allRecords));
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
        this.allRecords = parseData;
    }

    createRecordListForMobile() {
        this.recordList = [];
        if (this.allRecords.length > 0) {
            this.allRecords.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.headerText = rec.Name;
                record.hasStatus = true;
                record.statusText = ((rec.Vendor_Status__c === 'Hold Payment and Purchasing' || rec.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'On-Hold' : rec.Vendor_Status__c);
                record.hasSelectEvent = true;
                if (rec.Vendor_Status__c != 'Hold Payment and Purchasing' && rec.Vendor_Status__c != 'Hold for Purchasing (Orders)') {
                    record.hasButtonsMenu = true;
                    let menuItems = [];
                    let menuItem = {};
                    menuItem.label = 'Start PO';
                    menuItem.value = 'startpo';
                    menuItems.push(menuItem);
                    record.menuItems = menuItems;
                }
                record.isHeaderLink = true;
                record.url = {};
                record.url.label = 'Vendor Name';
                record.url.link = rec.recordURL;
                record.url.value = rec.Name;
                record.url.target = '_blank';

                let columns = [];
                let col = {};
                col.type = 'text';
                col.key = 1;
                col.label = 'Vendor Number';
                col.value = rec.Vendor_Account_Number__c;
                columns.push(col);

                let col1 = {};
                col1.type = 'text';
                col1.key = 2;
                col1.label = 'Vendor Status';
                col1.value = rec.Vendor_Status__c;
                columns.push(col1);

                let col2 = {};
                col2.type = 'text';
                col2.key = 3;
                col2.label = 'Billing Street';
                col2.value = rec.BillingStreet;
                columns.push(col2);
                record.columns = columns;

                let col3 = {};
                col3.type = 'text';
                col3.key = 4;
                col3.label = 'Billing State/Province';
                col3.value = rec.BillingState;
                columns.push(col3);
                record.columns = columns;

                let col4 = {};
                col4.type = 'text';
                col4.key = 5;
                col4.label = 'Zip/Postal Code';
                col4.value = rec.BillingPostalCode;
                columns.push(col4);
                record.columns = columns;
                this.recordList.push(record);

            });
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper').refreshRecords(this.recordList);
    }

    handleCloseModal() {
        this.renderFlow = false;
        this.bShowModalFlow = false;
    }
    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action == 'startpo') {
            // Populate the array with the data that you want to pass to the flow
            this.inputVariables = [
                {
                    name: 'recordId',
                    type: 'String',
                    value: row.Id
                }
            ];
            //Once set to true the flow will run
            this.renderFlow = true;
            this.bShowModalFlow = true;
        }
    }
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'CANCELLED') {
            this.renderFlow = false;
            this.bShowModalFlow = false;
        }
    }

    handleDivClick(event) {
        this.dispatchEvent(new CustomEvent('filterblur'));
    }

    handleNoAction(event) {
        event.stopPropagation();
    }

    processRecords() {
        //Appending record Id
        this.allRecords = this.allRecords.map(item => {
            return {
                ...item,
                recordURL: '/' + item.Id,
                className: (item.Vendor_Status__c === 'Hold Payment and Purchasing' || item.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'onhold' : (item.Vendor_Status__c === 'Active') ? 'active' : 'none',
                currStatus: (item.Vendor_Status__c === 'Hold Payment and Purchasing' || item.Vendor_Status__c === 'Hold for Purchasing (Orders)') ? 'On-Hold' : item.Vendor_Status__c,
                hideButtonClass: (item.Vendor_Status__c == 'Hold Payment and Purchasing' || item.Vendor_Status__c == 'Hold for Purchasing (Orders)') ? 'hideButton' : 'showButton'
            };
        });
        Object.preventExtensions(this.allRecords);
        this.totalNoOfRecords = this.allRecords.length;
        if (this.isMobileView) {
            if (this.totalNoOfRecords > 25) {
                if (!this.isSearch) {
                    this.allRecords = this.allRecords.slice(0, 25);
                }
            }
            this.createRecordListForMobile();
        }
    }
}