import { LightningElement, api } from 'lwc';
import getcarrier from '@salesforce/apex/sbr_3_0_carrierSearch.getcarrier';
import getSearchResults from '@salesforce/apex/sbr_3_0_carrierSearch.getSearchResults';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import FORM_FACTOR from "@salesforce/client/formFactor";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";

const SMALL_FORM_FACTOR = "Small";

const columns = [
    { label: 'Carrier Name', fieldName: 'Name', type: 'button', initialWidth: 300, typeAttributes: { label: { fieldName: 'Name' }, variant: "base", disabled: { fieldName: 'accountDisabled' } }, wrapText: true, sortable: 'true'  },
    { label: 'Carrier Number', fieldName: 'Carrier_Num__c', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Phone Number', fieldName: 'Main_Phone__c', type: 'phone', wrapText: true, sortable: 'true' },
    { label: 'Cargo Liability', fieldName: 'Liability_Insurance__c', type: 'currency', cellAttributes: {alignment: 'left'}, wrapText: false, sortable: 'true' },
];

const carrierFields = ['Name', 'Carrier_Num__c', 'Main_Phone__c', 'Liability_Insurance__c', 'Id'];

export default class Sbr_3_0_carriersearch extends LightningElement {
    @api label;
    @api placeholder;
    @api hasRequired;
    @api searchIconName;
    @api carrierId;
    @api carrierNum;

    columns = columns;
    searchKey = '';
    data = [];
    recordList = [];
    totalNoOfRecords = 0;
    errorMessage = '';
    showErrorMessage = false;
    hasRecords = true;
    sortBy;
    sortDirection;
    showModal = false;
    @api getCarrierNameFromParent = '';
    noContentimageUrl = noContentSvg;
    _rendered = false;
    recLimit;
    
    connectedCallback() {
        this.recLimit = (this.isMobileView) ? 10 : 100;
        this.showAllResults();
    }
    renderedCallback() {
        this.setFocusOnFirstElement();
    }
    
    showAllResults() {
        // Call Apex method to retrieve all records without any filters
        getcarrier({recLimit : this.recLimit})
            .then(result => {
                // Handle the retrieved records
                if (result && result.length > 0) {
                    // Update the data property to display all records
                    this.data = result;                   
                    this.totalNoOfRecords = result.length;
                    this.hasRecords = this.data.length == 0 ? false : true;
                    this.processRecords();        
                    Object.preventExtensions(this.data);
                    this.totalNoOfRecords = this.data.length;
                        
                    if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper') != null){
                        this.createRecordListForMobile();
                    }
                    /*this.data = this.data.map((car) => ({
                    ...car,
                    accountDisabled: (car.Status__c === 'I') ? true : false
                }));*/
                } else {
                    // Display a message or handle the case where no records are found
                    console.log('No records found.');
                }
            })
            .catch(error => {
                console.error('Error fetching all records: ', error);
            });
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;      
    }

    handleSearch(event) {
        if (event.keyCode === 13) {
            let searchString = event.target.value
            this.processSearch(searchString);
        }
    }

    handleSearchMobile(event) {
       // console.log('search');
        let searchString = event.detail.value

        this.processSearch(searchString);
    }

    handleKeyPress(event) {
        event.preventDefault();
        this.showModal = true;
        this.showAllResults();
        return false;
    }

    processSearch(searchString){
        getSearchResults({ searchString: searchString })
            .then(result => {
                this.data = result;
                this.hasRecords = this.data.length == 0 ? false : true;
                this.totalNoOfRecords = this.data.length;
                this.processRecords();
                if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper') != null){
                    this.createRecordListForMobile();
                }
                console.log('this.data', this.data);

            })
            .catch(error => {
                console.log(error);
            });
    }
    

    handleOpenModal(event) {
        this.showModal = true;
        this.showAllResults();
    }

    handleCloseModal(event) {
        this.showModal = false;
        this.setFocusOnReturn();
    }

    handleClearCarrier(event) {
        if (!event.target.value.length) {
            this.getCarrierNameFromParent = '';
            let elem = this.template.querySelector('[data-id="carrierSearch"]');
            elem.value = event.target.value;
            elem.reportValidity();
            const oEvent = new CustomEvent("carrierclear", {
                detail: { selectedRecord: event.target.value }
            });
            this.dispatchEvent(oEvent);
        }
        this.handleOpenModal(event);
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

    handleRowAction(event) {
        const record = event.detail.row;
        this.processCarrierSearch(record);        
    }

    
    handleRowSelect(event){
        const record = event.detail.record;
        this.processCarrierSearch(record);
    }

    processCarrierSearch(record){
        try{
            this.showModal = false;
            let elem = this.template.querySelector('[data-id="carrierSearch"]');
            elem.value = record.Name;
            elem.reportValidity();
            this.dispatchEvent(new FlowAttributeChangeEvent('carrierId', record.Id ));
            this.dispatchEvent(new FlowAttributeChangeEvent('carrierNum', record.Carrier_Num__c));
            elem.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
            this.lookupUpdatehandler(record.Id,record.Carrier_Num__c);
        }
        catch(error){
            console.log(error);
        }
    }

    lookupUpdatehandler(recId, carrierNumber) {
        const oEvent = new CustomEvent("carrierselect", {
            detail: { selectedRecord: recId, carrierNum : carrierNumber }
        });
        this.dispatchEvent(oEvent);
    }

    handleClear(event) {
        if (!event.target.value.length) {
            this.showAllResults();
        }
    }

    handleMobileClear(event) {
        this.showAllResults();
    }

    processRecords() {
                    this.data = this.data.map(car => {
                    return {
                    ...car,
                    accountDisabled: car.Status__c === 'I'  ? true : false
                    };
            });
        Object.preventExtensions(this.data);
        this.totalNoOfRecords = this.data.length;
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
                // record.hasStatus = true;
                // record.statusText = 'Active';
                record.hasSelectEvent = !rec.accountDisabled;
                record.isRowDisabled = rec.accountDisabled;
                let columns = [];
                let col={};
                col.type = 'text';
                col.key = 0;
                col.label='Carrier Number';
                col.value=rec.Carrier_Num__c;
                columns.push(col);

                let col1={};
                col1.type = 'text';
                col1.key = 1;
                col1.label='Phone Number';
                col1.value=rec.Main_Phone__c;
                columns.push(col1);

                let col2={};
                col2.type = 'text';
                col2.key = 2;
                col2.label='Cargo Liability';
                col2.value=rec.Liability_Insurance__c;
                columns.push(col2);
                record.columns = columns;
                this.recordList.push(record);

            });
        }
        this.template.querySelector('c-sbr_3_0_po-mobile-custom-wrapper').refreshRecords(this.recordList);
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

    setFocusOnReturn() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        window.setTimeout(() => {
            let ele = this.template.querySelector('[data-id="carrierSearch"]');
            if (ele && ele.focus) {
                ele.focus();
                ele.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
            }
        }, 5);
    }
}