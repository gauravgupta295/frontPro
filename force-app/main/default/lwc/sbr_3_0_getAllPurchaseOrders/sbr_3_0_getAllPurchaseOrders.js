import { LightningElement, api, wire,track } from 'lwc';
import Id from "@salesforce/user/Id";
import getObjectRecords from '@salesforce/apex/SBR_3_0_POSearchController.getObjectRecords';
import getPOSearchResults from '@salesforce/apex/SBR_3_0_POSearchController.getPOSearchResults';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from 'lightning/navigation';

const SMALL_FORM_FACTOR = "Small";

const columns = [
    
    { label: 'Purchase Order #', fieldName: 'recordURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, tooltip: { fieldName: 'Name' }, target: '_self'}, initialWidth: 150, wrapText: true, sortable: 'true' },
    { label: 'Vendor #', fieldName: 'Vendor_Number__c', type: 'text', initialWidth: 150, wrapText: true, sortable: 'true' },
    { label: 'Vendor Name', fieldName: 'vendorRecordURL', typeAttributes: { label: { fieldName: 'Vendor_Name_Text__c' }, tooltip: { fieldName: 'Vendor_Name_Text__c' },  target: '_self'}, type: 'url', initialWidth: 275, wrapText: true, sortable: 'true' },
    { label: 'Status', fieldName: 'Status__c', type: 'text', cellAttributes: { class: { fieldName: 'className' } }, initialWidth: 100, wrapText: true, sortable: 'true' },
    { label: 'Type', fieldName: 'Type__c', type: 'text', initialWidth: 200,  wrapText: true, sortable: 'true' },
    { label: 'Issue Date', fieldName: 'formattedIssueDate', type: 'date', initialWidth: 100, wrapText: true, sortable: 'true', 
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
    }},
    { label: 'Ordered By', fieldName: 'OrderedBy_Name__c', type: 'text', initialWidth: 180, wrapText: true, sortable: 'true' },
    { label: 'Location', fieldName: 'Location__c', type: 'text', initialWidth: 100, wrapText: true, sortable: 'true' },
    { label: 'Ship To', fieldName: 'ShipTo__c', type: 'text', initialWidth: 100, wrapText: true, sortable: 'true' },
];

const userLocationFields = ['Id', 'Name', 'Branch__c'];

const poFields = ['Id', 'Name', 'Vendor__c', 'Vendor_Number__c', 'Vendor_Name_Text__c', 'OrderedBy__r.Name', 'Vendor__r.Name',
                  'Status__c', 'Type__c', 'Issue_Date__c', 'OrderedBy_Name__c', 'Location__c', 'ShipTo__c'];


export default class Sbr_3_0_getAllPurchaseOrders extends NavigationMixin(LightningElement) {

    currentUserId = Id;
    userLocation;
    userBranchId;
    filterClause = 'Id != null and Status__c IN (\'Draft\', \'Open\', \'Partially Received\', \'Back Order\')';
    userLocationFilter = '';
    locatio

    dataToRefresh;
    allRecords;
    columns = columns;
    totalNoOfRecords = 0;

    @track isSearch=false;
    
    @api searchString;

    sortBy;
    sortDirection;
    error;

    recordList = [];

    renderedCallback() {
        if(!this.isMobileView){
            const self = this;
            document.addEventListener("click", (event) => {
            let hasNode = false;
            const path = event.composedPath();
            Array.prototype.forEach.call(path, function (entry) {
                if (entry.nodeName == "c-sbr_3_0_po-search-filter") {
                hasNode = true;
                }
            });
            if (!hasNode && path.length > 0) {
                if (self.template.querySelector("c-sbr_3_0_po-search-filter")) {
                self.template
                    .querySelector("c-sbr_3_0_po-search-filter")
                    .closeFilterDropDown();
                }
            }
            });
        }
      }

    connectedCallback(){
        this.userLocationFilter = `User__c = '${this.currentUserId}'`;
        getObjectRecords({objectName: 'User_Location__c', 
                          fieldName: userLocationFields, 
                          filterBy: this.userLocationFilter, 
                          recLimit : 1, 
                          orderByField : 'Name' })
            .then((data) => {
                if (data) {
                    this.userLocation = data;
                    if(data.length > 0){
                        this.userBranchId = data[0].Branch__c;
                        this.filterClause = this.filterClause + ` and Branch_Location__c = '${this.userBranchId}'`;
                    }                
                }
            })
            .catch((error) => {
                this.error = error;
                console.error(this.error);
            });
    }
    
    
    @wire (getObjectRecords, { objectName: 'Purchase_Order__c', 
                               fieldName: poFields, 
                               filterBy: '$filterClause', 
                               recLimit : 50, 
                               orderByField : 'Issue_Date__c DESC' })
    wiredPurchaseOrders(result){
        this.dataToRefresh = result;
        if(result.data){
            this.allRecords = result.data;
            this.processRecords();
        }
        else if (result.error) {
            this.error = result.error;
            console.error(this.error);
        }    
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
        // return true;
    }

    getSearchValue(event) {
        this.allRecords = event.detail;
        this.isSearch=true;
        this.processRecords();        
    }

    @api handleSearch(searchVal) {
        if(searchVal){
            this.searchString = searchVal;
            getPOSearchResults({ searchString: searchVal })
                .then(result => {
                    this.allRecords = result;
                    this.isSearch=true;
                    //Appending record Id
                    this.processRecords();
                })
                .catch(error => {
                    console.log(error);
                });
        }
        else{
            this.allRecords = this.dataToRefresh.data;
            this.isSearch = false;
            this.processRecords();
        }
    }

    processRecords(){
        // let formattedReqDate = new Date(this.requestedDate).toLocaleDateString('en-US', { timeZone: 'UTC' });
        // this.requestedDate = formattedReqDate;
        this.allRecords = this.allRecords.map(item => {
            return {
                ...item,
                recordURL: '/' + item.Id,
                vendorRecordURL: item.Vendor__c ? '/' + item.Vendor__c : '',
                className: (item.Status__c === 'Open') ? 'active' : 
                                    (item.Status__c === 'Draft') ? 'draft'   : 
                                    (item.Status__c === 'Cancelled') ? 'cancelled' : 
                                    (item.Status__c === 'Received') ? 'received' :
                                    (item.Status__c === 'Back Order') ? 'backorder' : 
                                    (item.Status__c === 'Partially Received') ? 'patrec' : 'none',
                formattedIssueDate: new Date(item.Issue_Date__c).toLocaleDateString('en-US', { timeZone: 'UTC' })
            };
        });
        Object.preventExtensions(this.allRecords);
        this.totalNoOfRecords = this.allRecords.length;
        if(this.isMobileView){
            if(this.totalNoOfRecords > 25){
                if(!this.isSearch){
                    this.allRecords=this.allRecords.slice(0, 25);
                }
                
            }
        this.createRecordListForMobile();
        }
    }

    handleReset(event){
        this.handleSearch();
    }

    handleSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    
    sortData(fieldname, direction) {
        fieldname = (fieldname === 'recordURL') ? 'Name' : 
                    ((fieldname === 'vendorRecordURL') ? 'Vendor_Name_Text__c' : fieldname);
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

    handleDivClick(event){
        this.dispatchEvent(new CustomEvent('filterblur'));
    }

    handleNoAction(event){
        event.stopPropagation();
    }

 
    createRecordListForMobile(){
        this.recordList = [];
        if(this.allRecords.length > 0){
            this.allRecords.forEach(rec => {
                let record = {};
                record.record = rec;
                record.recordId = rec.Id;
                record.hasHeader = true;
                record.headerText = rec.Name;
                record.hasStatus = true;
                record.statusText = rec.Status__c;
                record.hasSelectEvent = true;
        /*
                if(rec.Status__c === 'Open' || rec.Status__c === 'Draft'){
                    record.hasButtonsMenu = true;
                    let menuItems = [];
                    let menuItem = {};
                    menuItem.label = 'Edit PO';
                    menuItem.value = 'editpo';
                    menuItems.push(menuItem);
                    record.menuItems = menuItems;
                }
        */

                record.isHeaderLink = true;
                record.url = {};
                record.url.label = 'Purchase Order';
                record.url.link = rec.recordURL;
                record.url.value = rec.Name;
                record.url.target = '_blank';

                let columns = [];
                let col0={};
                col0.type = 'text';
                col0.key = 0;
                col0.label='Vendor Number';
                col0.value=rec.Vendor_Number__c;
                columns.push(col0);
                
                let col1={};
                col1.type = 'url';
                col1.key = 1;
                col1.label='Vendor Name';
                col1.value = rec.Vendor_Name_Text__c;
                let recUrl = {};
                recUrl.label = 'Vendor Name';
                recUrl.link = rec.vendorRecordURL;
                recUrl.value = rec.Vendor_Name_Text__c;
                recUrl.target = '_blank';
                col1.url = recUrl;
                columns.push(col1);

                let col2={};
                col2.type = 'text';
                col2.key = 2;
                col2.label='Type';
                col2.value=rec.Type__c;
                columns.push(col2);

                let col3={};
                col3.type = 'text';
                col3.key = 0;
                col3.label='Issue Date';
                col3.value=rec.formattedIssueDate;
                columns.push(col3);

                let col4={};
                col4.type = 'text'; // 'url';
                col4.key = 1;
                col4.label='Ordered By';
                col4.value=rec.OrderedBy_Name__c;
                columns.push(col4);

                let col5={};
                col5.type = 'text';
                col5.key = 2;
                col5.label='Location';
                col5.value=rec.Location__c;
                columns.push(col5);

                let col6={};
                col6.type = 'text';
                col6.key = 2;
                col6.label='Ship To';
                col6.value=rec.ShipTo__c;
                columns.push(col6);

                record.columns = columns;
                this.recordList.push(record);

            });
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper').refreshRecords(this.recordList);
    }

    handleEditPO(event){
        let recordId = event.detail.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'edit',
            },
        });
    }
}