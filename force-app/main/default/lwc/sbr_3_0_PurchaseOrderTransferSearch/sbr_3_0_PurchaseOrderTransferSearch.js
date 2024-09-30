import { LightningElement, track, wire, api } from 'lwc';
import getTransfer from '@salesforce/apex/sbr_3_0_PurchaseOrderTransferSearch.getTransfer';
import getSearchResults from '@salesforce/apex/sbr_3_0_PurchaseOrderTransferSearch.getSearchResults';
import { CloseActionScreenEvent } from 'lightning/actions';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import FORM_FACTOR from "@salesforce/client/formFactor";

const columns = [
    { label: 'Transfer Number', initialWidth: 150, fieldName: 'tnumber', type: 'button', typeAttributes: { label: { fieldName: 'tnumber' }, variant: "base" }, wrapText: true, sortable: 'true' },
    { label: 'Source Location', initialWidth: 150, fieldName: 'sbranch', type: 'number', wrapText: true, sortable: 'true' },
    { label: 'Destination Location', initialWidth: 150, fieldName: 'dbranch', type: 'number', wrapText: true, sortable: 'true' },
    { label: 'Needed', initialWidth: 100, fieldName: 'needed', type: 'date', wrapText: true, sortable: 'true', typeAttributes: { month: "2-digit", day: "2-digit", year: "2-digit" } },
    { label: 'Ordered by', initialWidth: 180, fieldName: 'orderedby', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Status', initialWidth: 180, fieldName: 'status', type: 'text', wrapText: true, sortable: 'true' },
];

const transferFields = ['RM_Transfer_Number__c', 'Receiving_Branch_Name__c', 'Sending_Branch_Name__c', 'Status__c', 'Transfer_Date__c', 'Ordered_By_Name__c'];


export default class Sbr_3_0_purchaseOrderTransferSearchModal extends LightningElement {
    data = [];
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
    tnumber;
    isEqp=false;


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
        console.log('inside ProductTransfer : ');
        getTransfer({ recordId: this.recordId, objectName: 'Internal_Order__c', fieldName: transferFields })
            .then(result => {
                console.log('inside getContract>> : ');

                if (result && result.length > 0) {
                     //Iterate through each record
                     this.data = result.map(x => {
                        return {
                            ...x,
                            tnumber : x.RM_Transfer_Number__c,
                            sbranch : x.Sending_Branch_Name__c,
                            dbranch : x.Receiving_Branch_Name__c,
                            needed : x.Transfer_Date__c,
                            orderedby : x.Ordered_By_Name__c,
                            status : x.Status__c,
                        }
                     })
                    this.totalNoOfRecords = this.data.length;
                    console.log('result : ', JSON.stringify(result));
                    console.log('TransferNumber> >  : ', JSON.stringify(result.RM_Transfer_Number__c));
                     this.hasRecords = this.data.length == 0 ? false : true;
                    //this.processRecords();
                    Object.preventExtensions(this.data);
                    this.totalNoOfRecords = this.data.length
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
            console.log('SearchString', this.searchString);
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
        // const childComponent = this.template.querySelector('c-sbr_3_0_purchase_order_contract_search_filtr');

        // if (childComponent) {
        //     console.log('intooo handleRowAction : ');
        //     // Call the handleReset method of the child component
        //     childComponent.handleReset(event);
        // }
        const record = event.detail.row;
        console.log('record>>> : ', JSON.stringify(record));
        const selectEvent = new CustomEvent('selectrecords', {
            detail: { record },
        });
        this.dispatchEvent(selectEvent);

        // Refresh contract search result and reset filters
        //this.getContracts();
        //this.processRecords();

    }

    reload() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    getSearchValue(event) {
        this.data = event.detail.data;
        this.isEqp = event.detail.isEqp;
        console.log('Searchvalue',this.data);
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
        Object.preventExtensions(this.data);
        this.totalNoOfRecords = this.data.length;
        this.data = this.data.map(con => {
            console.log('into processRecords map >> : ');
            if(this.isEqp){
            return {
                ...con,
                tnumber: con.Transfer_Number__r?con.Transfer_Number__r.RM_Transfer_Number__c : null,
                sbranch:con.Transfer_Number__r?con.Transfer_Number__r.Sending_Branch_Name__c : null,
                dbranch :con.Transfer_Number__r?con.Transfer_Number__r.Receiving_Branch_Name__c:null,
                needed : con.Transfer_Number__r?con.Transfer_Number__r.Transfer_Date__c:null,
                orderedby :con.Transfer_Number__r?con.Transfer_Number__r.Ordered_By_Name__c:null,
                status : con.Transfer_Number__r?con.Transfer_Number__r.Status__c:null,
                //destinationLocation: con.Receiving_Branch__r.Branch_Location_Number__c,
            };
            }
            else{
                return {
                ...con,
                tnumber: con.RM_Transfer_Number__c?con.RM_Transfer_Number__c : null,
                sbranch:con.Sending_Branch_Name__c?con.Sending_Branch_Name__c : null,
                dbranch :con.Receiving_Branch_Name__c?con.Receiving_Branch_Name__c:null,
                needed : con.Transfer_Date__c?con.Transfer_Date__c:null,
                orderedby :con.Ordered_By_Name__c?con.Ordered_By_Name__c:null,
                status : con.Status__c?con.Status__c:null,
                //destinationLocation: con.Receiving_Branch__r.Branch_Location_Number__c,


            }
            }
        });
        Object.preventExtensions(this.data);
        this.totalNoOfRecords = this.data.length;


       
    }

}