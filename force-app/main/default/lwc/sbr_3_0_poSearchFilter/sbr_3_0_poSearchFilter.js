import { LightningElement, api, track, wire } from "lwc";
import Id from "@salesforce/user/Id";
import getObjectRecords from '@salesforce/apex/SBR_3_0_POSearchController.getObjectRecords';
import getObjectRecordsWithLineItems from '@salesforce/apex/SBR_3_0_POSearchController.getObjectRecordsWithLineItems';
const BASE_CLASSES = "slds-dropdown slds-dropdown_fluid filter-options inner-dropdown-element";
const FLOW_IDENTIFIER = "/flow/";
import PURCHASE_ORDER from '@salesforce/schema/Purchase_Order__c';
//import PO_LINE_ITEM from '@salesforce/schema/PO_Line_Item__c';
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import PO_STATUS_FIELD from '@salesforce/schema/Purchase_Order__c.Status__c';
import FORM_FACTOR from "@salesforce/client/formFactor";

const userLocationFields = ['Id', 'Name', 'Branch__c'];
const poFields = ['Id', 'Name', 'Vendor__c', 'Vendor_Number__c', 'Vendor_Name_Text__c', 'OrderedBy__r.Name', 'Vendor__r.Name',
    'Status__c', 'Type__c', 'Issue_Date__c', 'OrderedBy_Name__c', 'Location__c', 'ShipTo__c'];

const poFields1 = ['Id','Name','Purchase_Order__r.Id', 'Purchase_Order__r.Name', 'Purchase_Order__r.Vendor__c', 'Purchase_Order__r.Vendor_Number__c',
    'Purchase_Order__r.Vendor_Name_Text__c', 'Purchase_Order__r.Status__c', 'Purchase_Order__r.Type__c', 'Purchase_Order__r.Issue_Date__c', 'Purchase_Order__r.OrderedBy_Name__c', 'Purchase_Order__r.Location__c',
    'Purchase_Order__r.ShipTo__c'];
const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_poSearchFilter extends LightningElement {

    //functional properties
    openDropDown = false;
    closeDropdown = true;
    delaytimeout;

    currentUserId = Id;
    userLocation;
    userBranchId = '';
    userLocationFilter = '';

    isBranchOnly = true;
    isFilterByItemOnly = false;
    poNumber = '';
    itemNumber = '';
    accName = '';
    accType = '';
    accNumber = '';
    status = '';
    type = '';
    location = '';
    shipTo = '';
    startDate = '';
    endDate = '';
    recordType = 'RecordType.Name =\'Vendor\'';
    filters = [];
    searchResults;
    companyCode;

    error;
    mobileFilterOpen = false;

    _recordTypes = [];
    _statusList = [];


    get recordTypes() {
        return this._recordTypes;
    }

    connectedCallback() {
        this.computeFilterCSS();
        this.userLocationFilter = `User__c = '${this.currentUserId}'`;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    @wire(getObjectRecords, { objectName: 'User_Location__c', fieldName: userLocationFields, filterBy: '$userLocationFilter', recLimit: 1 })
    getUserLocation({ error, data }) {
        if (data) {
            this.userLocation = data;
            if (data.length > 0) {
                this.userBranchId = data[0].Branch__c;
            }
        } else if (error) {
            this.error = error;
            console.error(this.error);
        }
    }

    @wire(getObjectInfo, { objectApiName: PURCHASE_ORDER })
    poObjectInfo;

    @wire(getObjectInfo, { objectApiName: PURCHASE_ORDER })
    poRecordTypes({ data, error }) {
        if (data) {
            // Returns a map of record type Ids 
            let recordTypes = data.recordTypeInfos;
            this._recordTypes = [{ Id: "", label: "--None--", value: "" }];
            Object.keys(recordTypes).forEach(element => {
                if (!recordTypes[element].name.toUpperCase().includes('MASTER')) {
                    let recordType = { Id: element, label: recordTypes[element].name, value: recordTypes[element].name };
                    this._recordTypes.push(recordType);
                }
            });
            this._recordTypes = this._recordTypes.sort((a, b) => (a.label > b.label) ? 1 : -1);
        }
        else if (error) {
            this.error = error;
            console.log(error.body.message);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: "$poObjectInfo.data.defaultRecordTypeId",
        fieldApiName: PO_STATUS_FIELD
    })
    poStatus({ data, error }) {
        if (data) {
            this._statusList = [{ Id: "", label: "--None--", value: "" }];
            let statusValues = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
            statusValues.forEach(element => {
                let status = { Id: null, label: element.value, value: element.value };
                this._statusList.push(status);
            })
        }
        else if (error) {
            this.error = error;
            console.log(error.body.message);
        }
    }

    get statusOptions() {
        // console.log('status is',this._statusList);
        return this._statusList;

    }



    handleBranchOnly(event) {
        this.isBranchOnly = event.detail.checked;
    }
    //priya
    handleFilterByItemOnly(event) {
        this.isFilterByItemOnly = event.detail.checked;
        this.poNumber = '';
        this.itemNumber = '';
        this.accNumber = '';
        this.accName = '';
        this.status = '';
        this.type = '';
        this.location = '';
        this.shipTo = '';
        this.startDate = '';
        this.endDate = '';
    }
    //priya
    get computedDropDownClasses() {
        if (this.openDropDown || this.mobileFilterOpen) {
            return `${BASE_CLASSES} is-filter-open`;
        } else {
            return BASE_CLASSES;
        }
    }
    //Method to handle readonly input click
    handleInputClick(event) {
        if (this.isMobileView) {
            this.mobileFilterOpen = !this.mobileFilterOpen;
        }
        else {
            this.toggleOpenDropDown();
        }
        this.adjustHeight();
    }

    //Method to toggle openDropDown
    toggleOpenDropDown() {
        this.openDropDown = !this.openDropDown;
    }
    //getter setter for labelClass
    get labelClass() {
        return this.fieldLabel && this.fieldLabel !== ""
            ? "slds-form-element__label slds-show"
            : "slds-form-element__label slds-hide";
    }

    handleFilterChange(event) {
        if (event.target.label === "Item #") {
            this.itemNumber = event.target.value;
            console.log('itemNumber is', this.itemNumber);
        } //priya
        if (event.target.dataset.label === "poNumber") {
            this.poNumber = event.target.value;
        }
        else if (event.target.dataset.label === "vendorNumber") {
            this.accNumber = event.target.value;
        }
        else if (event.target.dataset.label === "vendorName") {
            this.accName = event.target.value;
        }
        else if (event.target.dataset.label === "status") {
            this.status = event.target.value;
        }
        else if (event.target.dataset.label === "type") {
            this.type = event.target.value;
        }
        else if (event.target.dataset.label === "location") {
            this.location = event.target.value;
        }
        else if (event.target.dataset.label === "shipTo") {
            this.shipTo = event.target.value;
        }
        else if (event.target.dataset.label === "startDate") {
            this.startDate = event.target.value;
        }
        else if (event.target.dataset.label === "endDate") {
            this.endDate = event.target.value;
        }
        console.log("Field:" + event.target.value);
    }

    handleKeyDown(event) {
        if (event.keyCode == 13) {
            this.handleApply();
        }
    }

    handleApply(event) {
        const allValid = [
            ...this.template.querySelectorAll("lightning-input")]
            .reduce((validSoFar, currentInput) => {
                currentInput.reportValidity();
                return validSoFar && currentInput.checkValidity();
            }, true);

        if (allValid) {
            this.data = [];
            let isItemNoEmpty = false;//priya
            //for po filter without itemno & location
            if ((this.itemNumber == '') && (this.location == '') && (this.isFilterByItemOnly == false))  {
                let whereClause = ('Id != null' + (this.poNumber != '' ? ' and Name Like \'%' + this.poNumber + '%\'' : '')
                    // +(this.itemNumber != '' ? ' and Item_Number__c Like \'%' + this.itemNumber + '%\'' : '')
                    + (this.accNumber != '' ? ' and Vendor_Number__c Like \'%' + this.accNumber + '%\'' : '')
                    + (this.accName != '' ? ' and Vendor_Name_Text__c Like \'%' + this.accName + '%\'' : '')
                    + (this.status != '' ? ' and Status__c = \'' + this.status + '\'' : '')
                    + (this.type != '' ? ' and Type__c = \'' + this.type + '\'' : '')
                    + (this.location != '' ? ' and Location__c Like \'%' + this.location + '%\'' : '')
                    + (this.shipTo != '' ? ' and ShipTo__c Like \'%' + this.shipTo + '%\'' : '')
                    + (this.isBranchOnly && this.userBranchId != '' ? ' and Branch_Location__c = \'' + this.userBranchId + '\'' : '')
                );

                if (this.startDate && this.endDate) {
                    whereClause = whereClause + ' and Issue_Date__c >= ' + this.startDate + ' and Issue_Date__c <= ' + this.endDate;
                }
                else if (this.startDate) {
                    whereClause = whereClause + ' and Issue_Date__c >= ' + this.startDate;
                }
                else if (this.endDate) {
                    whereClause = whereClause + ' and Issue_Date__c <= ' + this.endDate;
                }



                console.log('1st where clause' + whereClause);
                // console.log('ItemNumber', this.itemNumber);
                isItemNoEmpty = false //priya
                getObjectRecords({
                    recordId: this.recordId,
                    objectName: 'Purchase_Order__c',
                    fieldName: poFields,
                    filterBy: whereClause,
                    recLimit: 9999,
                    orderByField: 'Issue_Date__c DESC'
                })
                    .then(result => {
                        this.partialResult = result;
                        console.log('this.partialResult', this.partialResult);
                        this.data = this.partialResult;
                        console.log('this.data',this.data);
                        const searchEvent = new CustomEvent("getsearchvalue", { detail: this.data, isItemNoEmpty: isItemNoEmpty });

                        // Dispatches the event.
                        this.dispatchEvent(searchEvent);
                    })
                    .catch(error => {
                        this.error = error;
                        console.error(this.error);
                    })



                if (this.isMobileView) {
                    this.mobileFilterOpen = false;
                }
                else {
                    this.openDropDown = false;
                }

            }

           //for po filter with itemno & location or itemno
            if (((this.itemNumber != '') && (this.location != '')) || (this.itemNumber != '') || (this.location != '')) {
                let whereClause = ('Purchase_Order__r.Id != null'

                    + (this.poNumber != '' ? 'and Purchase_Order__r.Name Like \'%' + this.poNumber + '%\'' : '')
                    + (this.itemNumber != '' ? ' and Item_Number__c Like \'%' + this.itemNumber + '%\'' : '')
                    + (this.accNumber != '' ? ' and Purchase_Order__r.Vendor_Number__c Like \'%' + this.accNumber + '%\'' : '')
                    + (this.accName != '' ? ' and Purchase_Order__r.Vendor_Name_Text__c Like \'%' + this.accName + '%\'' : '')
                    + (this.status != '' ? ' and Purchase_Order__r.Status__c = \'' + this.status + '\'' : '')
                    + (this.type != '' ? ' and Purchase_Order__r.Type__c = \'' + this.type + '\'' : '')
                    + (this.location != '' ? ' and Purchase_Order__r.Location__c Like \'%' + this.location + '%\'' : '')
                    + (this.shipTo != '' ? ' and Purchase_Order__r.ShipTo__c Like \'%' + this.shipTo + '%\'' : '')
                );

                if (this.startDate && this.endDate) {
                    whereClause = whereClause + ' and Purchase_Order__r.Issue_Date__c>= ' + this.startDate + ' and Purchase_Order__r.Issue_Date__c <= ' + this.endDate;
                }
                else if (this.startDate) {
                    whereClause = whereClause + ' and Purchase_Order__r.Issue_Date__c >= ' + this.startDate;
                }
                else if (this.endDate) {
                    whereClause = whereClause + ' and Purchase_Order__r.Issue_Date__c <= ' + this.endDate;
                }



                console.log('2nd where clause' + whereClause);

                isItemNoEmpty = true //priya
                getObjectRecordsWithLineItems({
                    recordId: this.recordId,
                    objectName: 'PO_Line_Item__c',
                    fieldName: poFields1,
                    filterBy: whereClause + 'and Purchase_Order__r.Status__c IN (\'Open\', \'Received\', \'Back Order\')',
                    recLimit: 9999,
                    orderByField: 'Purchase_Order__r.Issue_Date__c DESC'
                })
                    .then(result => {
                        this.partialResult = result;
                        console.log('this.partialResult', this.partialResult);
                        //this.data = this.partialResult;
                        this.data = [];
                        this.partialResult.forEach(x => {
                            if(!this.data.some(poLineItem => poLineItem.Id == x.Purchase_Order__r.Id)){
                                let rec = {};
                                rec.Id = x.Purchase_Order__r.Id;
                                rec.Name = x.Purchase_Order__r.Name;
                                rec.Vendor__c = x.Purchase_Order__r.Vendor__c;
                                rec.Vendor_Number__c = x.Purchase_Order__r.Vendor_Number__c;
                                rec.Vendor_Name_Text__c = x.Purchase_Order__r.Vendor_Name_Text__c;
                                //let OrderedBy__r = {Name : x.Purchase_Order__r.OrderedBy_Name__c};
                                //rec.OrderedBy__r = OrderedBy__r;
                                rec.OrderedBy_Name__c = x.Purchase_Order__r.OrderedBy_Name__c;
                                rec.Status__c = x.Purchase_Order__r.Status__c;
                                rec.Type__c = x.Purchase_Order__r.Type__c;
                                rec.Issue_Date__c = x.Purchase_Order__r.Issue_Date__c;
                                rec.Location__c = x.Purchase_Order__r.Location__c;
                                rec.ShipTo__c = x.Purchase_Order__r.ShipTo__c;
                                this.data.push(rec);
                            }
                        })
                        console.log('the data is ',this.data);
                        const searchEvent = new CustomEvent("getsearchvalue", { detail: this.data, isItemNoEmpty: isItemNoEmpty });

                        // Dispatches the event.
                        this.dispatchEvent(searchEvent);
                    })
                    .catch(error => {
                        this.error = error;
                        console.error(this.error);
                    })



                if (this.isMobileView) {
                    this.mobileFilterOpen = false;
                }
                else {
                    this.openDropDown = false;
                }

            }  
        }
    }

    handleReset(event) {
        this.poNumber = '';
        this.itemNumber = '';//priya
        this.accNumber = '';
        this.accName = '';
        this.status = '';
        this.type = '';
        this.location = '';
        this.shipTo = '';
        this.isBranchOnly = true;
        this.isFilterByItemOnly = false;
        //priya 
        this.startDate = '';
        this.endDate = '';
        this.openDropDown = false;
        this.handleApply(event);
        this.dispatchEvent(new CustomEvent('reset'));
    }

    handleCancel() {
        this.mobileFilterOpen = false;
    }

    handleFilterCancel() {
        this.mobileFilterOpen = false;
    }

    openFilters() {
        this.mobileFilterOpen = !this.mobileFilterOpen;
    }

    get filterLabel() {
        let label = "Filters";
        if (this.filters.length > 0) {
            label = `${this.filters.length} Filters Selected`;
        }
        return label;
    }

    computeFilterCSS() {
        const currentUrl = window.location.href;
        if (currentUrl.indexOf(FLOW_IDENTIFIER) !== -1) {
            this.computedFilterCmpCSS = "filter-element-quote";
        } else {
            this.computedFilterCmpCSS = "slds-p-top--small";
        }
    }

    @api closeFilterDropDown() {
        if (this.isMobileView) {
            this.mobileFilterOpen = false;
        }
        else {
            this.openDropDown = false;
        }
    }

    @api
    adjustHeight() {
        const dropdown = this.template.querySelector(".inner-dropdown-element");
        const viewPortHeight = window.innerHeight;
        //FRONT-7753 Updated the if condition to set the height accordingly
        if ((viewPortHeight - dropdown.getBoundingClientRect().top) < dropdown.scrollHeight) {
            const comboboxFinalHeight = viewPortHeight - dropdown.getBoundingClientRect().top;
            dropdown.style.height = comboboxFinalHeight + "px";
        } else {
            dropdown.style.height = "auto";
        }
    }
}