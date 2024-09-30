import { LightningElement, api, wire } from 'lwc';
import Id from "@salesforce/user/Id";
import getVendorName from '@salesforce/apex/SBR_3_0_ChangeVendorController.getVendorName';
import getSearchResults from '@salesforce/apex/SBR_3_0_ChangeVendorController.getSearchResults';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import PO_OBJECT from '@salesforce/schema/Purchase_Order__c';
import { getObjectInfo} from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from "@salesforce/client/formFactor";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import USER_NAME from "@salesforce/schema/User.Name";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

const SMALL_FORM_FACTOR = "Small";

const columns = [
    { label: 'Vendor Name', initialWidth: 300, fieldName: 'Name', type: 'button', typeAttributes: { label: { fieldName: 'Name' }, variant: "base", disabled: { fieldName: 'accountDisabled' } }, wrapText: true, sortable: 'true' },
    { label: 'Vendor Number', initialWidth: 150, fieldName: 'Vendor_Account_Number__c', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Vendor Status', initialWidth: 150, fieldName: 'currStatus', type: 'text', cellAttributes: { class: { fieldName: 'className' } }, wrapText: true, sortable: 'true' },
    { label: 'Billing Street', initialWidth: 200, fieldName: 'BillingStreet', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Billing State/Province', initialWidth: 150, fieldName: 'BillingState', type: 'text', wrapText: true, sortable: 'true' },
    { label: 'Zip/Postal Code', initialWidth: 120, fieldName: 'BillingPostalCode', type: 'text', wrapText: true, sortable: 'true' },
];

const vendorFields = ['Name', 'Vendor_Account_Number__c', 'ToLabel(Vendor_Status__c)', 'BillingStreet', 'BillingState', 'BillingPostalCode', 'Id'];

export default class Sbr_3_0_customVendorSearchCmp extends LightningElement {
    @api currentUserId = Id;
    data;
    columns = columns;
    dataToRefresh;
    sortBy;
    sortDirection;
    filterVisibility = false;
    totalNoOfRecords = 0;
    recordList = [];
    recordType = 'RecordType.Name =\'Vendor\'';
    @api recordId;
    showModal = false;
    @api availableActions = [];
    @api searchString;
    isCssLoaded = false;
    error;
    errorMessage = '';
    showErrorMessage = false;
    fromTheFlow = false;
    @api vendorId;
    @api source;
    @api accountId;
    vendorVal = '';
    poRecTypes = [];
    poRecTypeVals = [];
    @api poRecTypeVal = '';
    @api poRecTypeName = '';
    hasValueOrderedBy = true;
    vendorSearchIcon = 'utility:search';
    vendorInfoCancelled = false;
    hasRecords = true;
    noContentimageUrl = noContentSvg;

    currentUserName = '';
    currentUser= {};

    connectedCallback() {
        console.log('intoo connectedcallback >>: ');
        console.log('currentUserId >> : ', this.currentUserId);
        this.fromTheFlow = (this.source == 'Flow') ? true : false;
        if (this.accountId) {
            this.recordId = this.accountId;
        }
        this.getVendors();
    }
    renderedCallback() {
        this.setFocusOnFirstElement();
        if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

    getVendors() {
        getVendorName({ recordId: this.recordId, objectName: 'Account', fieldName: vendorFields, filterBy: this.recordType })
            .then(result => {
                this.data = result;
                this.hasRecords = this.data.length == 0 ? false : true;
                //console.log('getVendors: ' + this.data);
                this.processRecords();
                if (this.accountId) {
                    let venRec = this.data.filter(item => item.Id == this.accountId);
                    if (venRec != undefined && venRec.length > 0 && !this.vendorInfoCancelled) {
                        this.vendorVal = venRec[0].Name;
                        this.vendorSearchIcon = 'standard:account';
                        this.showHideVendorInfoError(this.vendorVal);
                        this.dispatchEvent(new FlowAttributeChangeEvent('vendorId', venRec[0].Id));
                    }
                }
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


    @wire(getRecord, {
        recordId: "$currentUserId",
        fields: [USER_NAME]
    })
    wiredUser({ error, data }) {

        console.log('OUTPUT data : ', JSON.stringify(data));
        if (data) {
            this.currentUser = data;
            this.currentUserName = data.fields.Name.value;
            console.log('currentUser >> : ', this.currentUser);
            console.log('currentUserName >> : ', this.currentUserName);

        } else if (error) {
            console.error('Error fetching user data:', JSON.stringify(error));
            this.currentUser = undefined;
            this.currentUserName = '';
        }
    }

    @wire(getObjectInfo, { objectApiName: PO_OBJECT })
    poRecTypeResults({ error, data }) {
        if (data) {            
            this.poRecTypes = Object.entries(data.recordTypeInfos).map(([k, v]) => ({
                id: k,
                defaultRecType: v.defaultRecordTypeMapping,
                name: v.name,
                master: v.master
            }));
            let recTypes = this.poRecTypes.filter(item => item.master == false);
            recTypes = recTypes.sort(
                (p1, p2) => (p1.name < p2.name) ? 1 : (p1.name > p2.name) ? -1 : 0),
                [recTypes[0], recTypes[1]] = [recTypes[1], recTypes[0]];
            for (let i = 0; i < recTypes.length; i++) {
                this.poRecTypeVals.push({
                    label: recTypes[i].name,
                    value: recTypes[i].id
                })
            }
            this.poRecTypeVal = recTypes[0].id;
            this.poRecTypeName = recTypes[0].name;
            //console.log('recTypes:', recTypes);
            this.error = undefined;
        } else if (error) {
            //console.log(error);
            this.error = error;
        }
    }

    handlePORecChange(event) {
        const selectedOption = event.detail.value;
        this.poRecTypeVal = selectedOption;
        this.poRecTypeName = this.poRecTypeVals.filter(x => x.value == this.poRecTypeVal)[0].label;
    }
    handleSearch(event) {
        if (event.keyCode === 13) {
            //console.log('recordId', this.recordId);
            this.searchString = [event.target.value];
            getSearchResults({ recordId: this.recordId, searchString: event.target.value })
                .then(result => {
                    this.data = result;
                    this.hasRecords = this.data.length == 0 ? false : true;
                    //console.log('this.data', this.data);
                    this.processRecords();
                    if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table') != null){
                        this.createRecordListForMobile();
                    }
                })
                .catch(error => {
                    this.error = result.error;
                    console.log(error);
                });
        }
    }
    getSearchValue(event) {
        this.data = event.detail;
        this.hasRecords = this.data.length == 0 ? false : true;
        this.processRecords();
        if (this.isMobileView && this.template.querySelector('c-sbr_3_0_po-mobile-custom-data-table') != null) {
            this.createRecordListForMobile();
        }
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
    handlefilter(event) {
        //console.log('filter');
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

    handleKeyPress(event) {
        event.preventDefault();
        this.showModal = true;
        return false;
    }

    selectedUserHandler(event) {
        if (event.detail.selectedRecord !== undefined) {
            this.currentUserId = event.detail.selectedRecord.Id;
            this.hasValueOrderedBy = true;
        }
        else {
            this.currentUserId = event.detail.selectedRecord;
            this.hasValueOrderedBy = false;
        }
    }
    handleOpenModal(event) {
        this.showModal = true;
        this.getVendors();
    }
    handleRowSelect(event) {
        const record = event.detail.record;
        this.processVendorSearch(record);
    }
    handleRowAction(event) {
        const record = event.detail.row;
        //console.log(record);
        this.processVendorSearch(record);
    }
    processVendorSearch(record) {
        this.vendorVal = record.Name;
        this.vendorSearchIcon = 'standard:account';
        let inputElem = this.template.querySelector("input[data-id='vendorSearch']");
        inputElem.value = this.vendorVal;
        this.showHideVendorInfoError(this.vendorVal);
        this.dispatchEvent(new FlowAttributeChangeEvent('vendorId', record.Id));
        this.showModal = false;
    }
    handleClearVendor(event) {
        event.preventDefault();
        this.vendorSearchIcon = 'utility:search';
        let inputElem = this.template.querySelector("input[data-id='vendorSearch']");
        inputElem.value = '';
        this.vendorVal = '';
        this.vendorInfoCancelled = true;
        this.showHideVendorInfoError(this.vendorVal);
    }
    handleCloseModal(event) {
        this.showModal = false;
        this.vendorInfoCancelled = true;
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
    checkValidity() {
        let hasVendorInfo = true;
        const allValid = [
            ...this.template.querySelectorAll("lightning-input")]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        //Check for vendor info
        let inputElem = this.template.querySelector("input[data-id='vendorSearch']");
        if(inputElem.value == '') {
            hasVendorInfo = false;
            this.showHideVendorInfoError(inputElem.value);
        }
        
        return (allValid && hasVendorInfo && this.hasValueOrderedBy);
    }

    // To handle next click
    handleNext() {
        if (this.checkValidity() && this.availableActions.find((action) => action === "NEXT")) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
    showHideVendorInfoError(vendorValue) {
        let divForm = this.template.querySelector("div[data-id='divForm']");
        let divError = this.template.querySelector("div[data-id='divError']");
        if(vendorValue) {
            if (divForm.classList.contains('slds-has-error')) {
                divForm.classList.remove('slds-has-error');
            }
            if (!divError.classList.contains('slds-hide')) {
                divError.classList.add('slds-hide');
            }
        }
        else {
            if (!divForm.classList.contains('slds-has-error')) {
                divForm.classList.add('slds-has-error');
            }
            if (divError.classList.contains('slds-hide')) {
                divError.classList.remove('slds-hide');
            }
        }
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