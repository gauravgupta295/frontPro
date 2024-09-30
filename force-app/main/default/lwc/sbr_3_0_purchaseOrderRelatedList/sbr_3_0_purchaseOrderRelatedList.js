import { LightningElement, api, wire,track } from 'lwc';
import Id from "@salesforce/user/Id";
import getPOsFromVendor from '@salesforce/apex/SBR_3_0_POSearchController.getPOsFromVendor';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from 'lightning/navigation';

const SMALL_FORM_FACTOR = "Small";

const columns = [
    
     { label: 'Purchase Order #', fieldName: 'recordURL', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, tooltip: { fieldName: 'Name' }, target: '_self'}, initialWidth: 150, wrapText: true, sortable: 'true' },
    { label: 'Status', fieldName: 'Status__c', type: 'text', cellAttributes: { class: { fieldName: 'className' } }, initialWidth: 100, wrapText: true, sortable: 'true' },
    { label: 'Type', fieldName: 'Type__c', type: 'text', initialWidth: 200,  wrapText: true, sortable: 'true' },
    { label: 'Issue Date', fieldName: 'formattedIssueDate', type: 'date', initialWidth: 100, wrapText: true, sortable: 'true', 
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
    }},
    { label: 'Req Date', fieldName: 'formattedReqDate', type: 'date', initialWidth: 100, wrapText: true, sortable: 'true', 
        typeAttributes: {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
    }},
    { label: 'Ship Date', fieldName: 'formattedShipDate', type: 'date', initialWidth: 100, wrapText: true, sortable: 'true', 
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
                  
export default class Sbr_3_0_purchaseOrderRelatedList extends LightningElement {
    @api prop1;
     
     
    @api recordId;
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

   /* renderedCallback() {
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
      }*/

     @wire (getPOsFromVendor, { vendorId: '$recordId' })
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

    connectedCallback(){
       /* this.userLocationFilter = `User__c = '${this.currentUserId}'`;
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
            });*/
           
    }
    
    
    

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

   getSearchValue(event) {
        this.allRecords = event.detail;
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
                formattedIssueDate: (item.Issue_Date__c) ? new Date(item.Issue_Date__c).toLocaleDateString('en-US', { timeZone: 'UTC' }):'',
                formattedReqDate: (item.Requested_Date__c) ? new Date(item.Requested_Date__c).toLocaleDateString('en-US', { timeZone: 'UTC' }) : '',
                formattedShipDate: (item.Ship_Date__c) ? new Date(item.Ship_Date__c).toLocaleDateString('en-US', { timeZone: 'UTC' }) : ''
            };
        });
        Object.preventExtensions(this.allRecords);
        this.totalNoOfRecords = this.allRecords.length;
        if(this.isMobileView){
            /*if(this.totalNoOfRecords > 25){
                if(!this.isSearch){
                    this.allRecords=this.allRecords.slice(0,25);
                }
                
            }*/
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
                record.headerText =rec.Name;
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
                /*let col0={};
                col0.type = 'url';
                col0.key = 1;
                col0.label='Purchase Order #';
                col0.value = rec.Name;
                let recUrl = {};
                recUrl.label = 'Purchase Order';
                recUrl.link = rec.recordURL;
                recUrl.value = rec.Name;
                recUrl.target = '_blank';
                col0.url = recUrl;
                columns.push(col0);
                */

              /*  let col1={};
                col1.type = 'text';
                col1.key = 0;
                col1.label='Status';
                col1.value=rec.Status__c;
                columns.push(col1);*/
                
             

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
                col4.type = 'text';
                col4.key = 0;
                col4.label='Req Date';
                col4.value=rec.formattedReqDate;
                columns.push(col4);

                let col5={};
                col5.type = 'text';
                col5.key = 0;
                col5.label='Ship Date';
                col5.value=rec.formattedShipDate;
                columns.push(col5);

                let col6={};
                col6.type = 'text'; // 'url';
                col6.key = 1;
                col6.label='Ordered By';
                col6.value=rec.OrderedBy_Name__c;
                columns.push(col6);

                let col7={};
                col7.type = 'text';
                col7.key = 2;
                col7.label='Location';
                col7.value=rec.Location__c;
                columns.push(col7);

                let col8={};
                col8.type = 'text';
                col8.key = 2;
                col8.label='Ship To';
                col8.value=rec.ShipTo__c;
                columns.push(col8);

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