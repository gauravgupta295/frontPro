import { LightningElement, api, wire, track } from 'lwc';
import flowTemplate from './templates/flow.html';
import pageTemplate from './templates/page.html';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAcctShippingDetails from '@salesforce/apex/SBR_3_0_FetchShippingDetails.getAcctShippingDetails';
import getBranchShippingDetails from '@salesforce/apex/SBR_3_0_FetchShippingDetails.getBranchShippingDetails';
import getVendorContacts from '@salesforce/apex/SBR_3_0_FetchShippingDetails.getVendorContacts';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LOCATION_OBJECT from '@salesforce/schema/Location';
import STATE_CODES from '@salesforce/schema/Location.State__c';
import SHIP_TYPES from '@salesforce/schema/Purchase_Order__c.ShipTo_Type__c';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { loadStyle } from 'lightning/platformResourceLoader';
import FORM_FACTOR from "@salesforce/client/formFactor";

const FIELDS = ['Purchase_Order__c.Type__c', 'Purchase_Order__c.Third_Party_Carrier__c', 'Purchase_Order__c.Carrier_Num__c' ]

const objectFields = {
    recordTypeId: { apiName: 'RecordTypeId' },
    shipToType: { apiName: 'ShipTo_Type__c' },
    addressLine1: { apiName: 'ShipTo_Addr1__c', length: 40, checkValidity: true },
    addressLine2: { apiName: 'ShipTo_Addr2__c', length: 40, checkValidity: true },
    shipToCity: { apiName: 'ShipTo_City__c', length: 20, checkValidity: true },
    shipToState: { apiName: 'ShipTo_State__c' },
    shipToZip: { apiName: 'ShipTo_Zip__c', length: 20, checkValidity: true },
    orderedFrom: { apiName: 'Ordered_From__c', length: 15, checkValidity: true },
    requestedDate: { apiName: 'Requested_Date__c' },
    phoneNumber: { apiName: 'Phone_Number__c', length: 40 },
    orderedFor: { apiName: 'Ordered_For__c', length: 15, checkValidity: true },
    shipDate: { apiName: 'Ship_Date__c' },
    vendorAccountId: { apiName: 'Vendor__c' },
    shipToLocation: { apiName: 'ShipTo_Location__c' },
    shipToCustomer: { apiName: 'ShipTo_Customer__c' },
    branchLocationNumber: { apiName: 'ShipTo__c' },
    customer: { apiName: 'Customer__c' },
    shipToName: { apiName: 'ShipTo_Name__c', length: 40 },
    carrierNumber: { apiName: 'Third_Party_Carrier__c', checkValidity: true },
    carrierNum: { apiName: 'Carrier_Num__c' },
    customerContractNum: { apiName: 'Customer_or_Contract_Number__c'}
}

const SMALL_FORM_FACTOR = "Small";
export default class Sbr_3_0_POShippingDetailsEdit extends LightningElement {
    @api source;
    @api vendorId;
    @api availableActions = [];
    @api recordId;
    @api fromTheFlow = false;
    errorMessage = '';
    showErrorMessage = false;
    @api recordIdName;
    //@api selectedCarrierId;
    @api carrierId = '';
    @api carrierNum = '';
    @api carrierName = '';
    _shipRecord;
    @api shipToType
    error;
    @api recordTypeId;
    showSpinner = false;
    displaycarrierfield = false;
    displaycarrierfieldonpage = false;
    showcarriersearch = false;
    isRerent = false;
    //For Edit mode 
    @api addressLine1 = '';
    @api addressLine2 = '';
    @api shipToCity = '';
    @api shipToState = '';
    @api shipToZip = '';
    @api orderedFrom = '';
    @api requestedDate = '';
    @api phoneNumber = '';
    @api orderedFor = '';
    @api shipDate = '';
    @api shipTo;
    @api shipToLoc;
    vendorAccountId;
    shipToLocation;
    shipToCustomer;
    branchLocationNumber;
    customer;
    customerNo = '';
    custAccNum = '';
    @api customerNumber;
    @api shipToName;
    isShipTypeCustomer = false;
    @api branchAdd1;
    @api branchAdd2;
    @api branchCity;
    @api branchPhone;
    @api branchState;
    @api branchZip;
    @api branchLocId;
    @api branchShipToName;
    @api branchLocNum;
    //For Acct search component
    @track parentComp = "orderrequireCustomLookup";
    locationRecordTypeId;
    stateCodes = [];
    shipTypes = [];
    defaultContactId;
    contactWhereClause;
    selectedContact;
    showLookup = false;
    showShipToName = false;
    vendorContacts = [];
    objectFields = objectFields;
    isOrderedFromReq = true;
    hasRequired = true;
    shipTypeValues;
    isCssLoaded = false;
    alignClass = 'slds-grid slds-wrap';
    shipTypeWidth = 'slds-size_4-of-12 slds-p-horizontal_medium';
    shipToWidth = 'slds-size_8-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    mainDiv = 'slds-size_1-of-2 slds-p-horizontal_medium';

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
    render() {
        return this.fromTheFlow ? flowTemplate : pageTemplate;
    }
    connectedCallback() {
        this.fromTheFlow = (this.source == 'Flow') ? true : false;
        if (this.fromTheFlow) {
            this.vendorAccountId = this.vendorId;
            this.fetchVendorContacts();
            this.orderedFrom = '';
            this.addressLine1 = this.branchAdd1;
            this.addressLine2 = this.branchAdd2;
            this.shipToCity = this.branchCity;
            this.shipToState = this.branchState;
            this.phoneNumber = this.branchPhone;
            this.shipToZip = this.branchZip;
            this.shipToLocation = this.branchLocId;
            this.shipToName = this.branchShipToName;
            this.showShipToName = (this.shipToName !== undefined);
            this.dispatchEvent(new FlowAttributeChangeEvent('shipToLoc', this.shipToLocation));
            this.branchLocationNumber = this.branchLocNum;
            this.dispatchEvent(new FlowAttributeChangeEvent('shipTo', this.branchLocationNumber));
            this.shipToType = 'Branch';
            this.displayCarrierNum();

            let currentDate = new Date();
            console.log('currentDate >> ' , currentDate);
            console.log(currentDate.toLocaleDateString("en-US"));

            // this.requestedDate = currentDate.toLocaleDateString("en-US");

            currentDate.setDate(currentDate.getDate() + 14);
            // let text = d.toISOString();
            let formattedDate = currentDate.toISOString();
            console.log('formattedDate >> ' , formattedDate);
            this.requestedDate = formattedDate;
            
            console.log('this.requestedDate >> ' , this.requestedDate);
        }
        if (this.isMobileView) {
            this.alignClass = this.alignClass + ' slds-grid_vertical';
            this.shipTypeWidth = 'slds-size_12-of-12 slds-p-horizontal_medium';
            this.shipToWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
            this.mainDiv = 'slds-size_1-of-1 slds-p-horizontal_medium';
        }
    }
    renderedCallback() {
        if (this.showErrorMessage && this.errorMessage != '') {
            //Scroll to error message
            const errorDiv = this.template.querySelector('[class*="slds-theme_error"]');
            if (errorDiv != undefined) {
                errorDiv.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
            }
        }
        if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }
    @api
    set shipRecord(value) {
        if (this._shipRecord !== value) {
            this._shipRecord = value;
            this.setScreenValues(value);
            this.fetchVendorContacts();
        }
    }
    get shipRecord() {
        return this._shipRecord;
    }

    @wire(getObjectInfo, { objectApiName: LOCATION_OBJECT })
    locationResults({ error, data }) {
        if (data) {
            this.locationRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.locationRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$locationRecordTypeId', fieldApiName: STATE_CODES })
    stateCodeValues({ error, data }) {
        if (data) {
            this.stateCodes = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
        } else if (error) {
            this.error = error;
            this.stateCodes = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: SHIP_TYPES })
    shipTypeRecords({ error, data }) {
        if (data) {
            this.shipTypeValues = data;
            console.log('recordIdName: ', this.recordIdName);
            if (this.recordIdName == 'Rerent') {
                this.shipTypes = [{ label: 'Customer', value: 'Customer' }];
                this.shipToType = 'Customer';
                this.isRerent = true;
                this.isShipTypeCustomer = (this.shipToType === 'Customer');
            }
            else {
                this.isRerent = false;
                this.shipTypes = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
            }
        } else if (error) {
            this.error = error;
            this.shipTypes = undefined;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.poRecordType = data.fields.Type__c.value;
            console.log('poRecordType code of PO >>', this.poRecordType);
            if (this.poRecordType === '3rd Party Hauler') {
                this.displaycarrierfieldonpage = true;
                this.carrierNumber = data.fields.Third_Party_Carrier__c.value;
                this.carrierNum = data.fields.Carrier_Num__c.value;
                this.isOrderedFromReq = true;
            }
            else if (this.poRecordType === 'Rerent') {
                this.recordIdName = this.poRecordType;
                this.recordTypeId = this.recordTypeId;
                refreshApex(this.shipTypeValues);
            }
            else {
                this.displaycarrierfieldonpage = false;
            }

        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }
    fetchAccountShippingDetails() {
        getAcctShippingDetails({ accountId: this.shipToCustomer })
            .then(result => {
                console.log('Shipping details:', result);
                // Check for errors
                if (result.error) {
                    console.error('Error fetching shipping details', result.error);
                    return;
                }
                this.addressLine1 = result.addressLine1;
                this.addressLine2 = '';
                this.shipToCity = result.shipToCity;
                this.shipToState = result.shipToState;
                this.shipToZip = result.shipToZip;
                this.customerNo = result.customerNo;
                this.phoneNumber = result.phoneNumber === undefined ? '' : result.phoneNumber;
                this.dispatchEvent(new FlowAttributeChangeEvent('customerNumber', this.customerNo));
            })
            .catch(error => {
                console.error('Error fetching shipping details', error);
            });
    }
    fetchBranchShippingDetails() {
        getBranchShippingDetails({ branchId: this.shipToLocation })
            .then(result => {
                console.log('Shipping details:', result);

                // Check for errors
                if (result.error) {
                    console.error('Error fetching shipping details', result.error);
                    return;
                }

                this.addressLine1 = result.addressLine1;
                this.shipToCity = result.shipToCity;
                this.shipToState = result.shipToState;
                this.shipToZip = result.shipToZip;
                this.branchLocationNumber = result.branchNumber;
                this.phoneNumber = result.phoneNumber === undefined ? '' : result.phoneNumber;
                this.dispatchEvent(new FlowAttributeChangeEvent('shipTo', this.branchLocationNumber));
                this.dispatchEvent(new FlowAttributeChangeEvent('shipToLoc', this.shipToLocation));
            })
            .catch(error => {
                console.error('Error fetching shipping details', error);
            });
    }
    fetchVendorContacts() {
        getVendorContacts({ accountId: this.vendorAccountId })
            .then((data) => {
                if (data != null) {
                    this.vendorContacts = data.map(x => {
                        return {
                            id: x.Id,
                            value: x.Name,
                            label: x.Name
                        }
                    });
                }
            })
            .catch((error) => {
                this.error = error;
                this.vendorContacts = [];

            });
    }
    setScreenValues(shipRecordVar) {
        this.recordTypeId = shipRecordVar.RecordTypeId;
        this.shipToType = shipRecordVar.ShipTo_Type__c;
        this.addressLine1 = shipRecordVar.ShipTo_Addr1__c;
        this.addressLine2 = shipRecordVar.ShipTo_Addr2__c;
        this.shipToCity = shipRecordVar.ShipTo_City__c;
        this.shipToState = shipRecordVar.ShipTo_State__c;
        this.shipToZip = shipRecordVar.ShipTo_Zip__c;
        this.orderedFrom = shipRecordVar.Ordered_From__c;
        this.requestedDate = shipRecordVar.Requested_Date__c;
        this.phoneNumber = shipRecordVar.Phone_Number__c;
        this.orderedFor = shipRecordVar.Ordered_For__c;
        this.shipDate = shipRecordVar.Ship_Date__c;
        this.vendorAccountId = shipRecordVar.Vendor__c;
        this.branchLocationNumber = shipRecordVar.ShipTo__c;
        this.customer = shipRecordVar.Customer__c;
        this.shipToName = shipRecordVar.ShipTo_Name__c;
        this.customerNo = shipRecordVar.customerNo;
        if (this.shipToType === 'Customer') {
            this.isShipTypeCustomer = true;
            this.shipToCustomer = shipRecordVar.ShipTo_Customer__c;
            this.showShipToName = true;
        }
        else {
            this.isShipTypeCustomer = false;
            this.shipToLocation = shipRecordVar.ShipTo_Location__c;
            this.showShipToName = false;
        }
        if (shipRecordVar.Third_Party_Carrier__c) {
            this.carrierName = shipRecordVar.Third_Party_Carrier__c;
        }
    }


    handlePicklistChange(event) {
        this.shipToType = event.detail.value;
        this.isShipTypeCustomer = (this.shipToType === 'Customer');
        this.showShipToName = (this.isShipTypeCustomer && this.shipToName !== undefined);
    }

    navigateToComponent() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentname: 'c-s-b-r_3_0_custom-lookup-cmp-frontline'
            }
        })
    }

    handleSearchClick(event) {
        this.showLookup = true;
    }

    handleAccountChange(event) {
        if (event.detail.selectedRecord !== undefined) {
            this.shipToName = event.detail.selectedRecord.Name;
            this.shipToCustomer = event.detail.selectedRecord.Id;
            this.showShipToName = (this.shipToName !== undefined);
            this.phoneNumber = event.detail.selectedRecord.Phone === undefined ? '' : event.detail.selectedRecord.Phone;
            console.log("@@selected Acc " + JSON.stringify(event.detail.selectedRecord));
            if (this.fromTheFlow) {
                this.dispatchEvent(new FlowAttributeChangeEvent('shipTo', ''));
                this.dispatchEvent(new FlowAttributeChangeEvent('shipToLoc', ''));
            }
            this.fetchAccountShippingDetails();
        }
        else {
            this.shipToName = event.detail.selectedRecord;
            this.shipToCustomer = event.detail.selectedRecord;
            this.phoneNumber = '';
        }
    }

    selectedBranchHandler(event) {
        if (event.detail.selectedRecord !== undefined) {
            this.shipToLocation = event.detail.selectedRecord.Id;
            this.shipToName = event.detail.selectedRecord.Name;
            this.shipTo = event.detail.selectedRecord.Branch_Location_Number__c;
            this.phoneNumber = event.detail.selectedRecord.Phone__c === undefined ? '' : event.detail.selectedRecord.Phone__c;
            console.log("@@selected Branch " + JSON.stringify(event.detail.selectedRecord));
            if (this.fromTheFlow && this.errorMessage != '') {
                this.showErrorMessage = false;
                this.errorMessage = '';
                this.dispatchEvent(new FlowAttributeChangeEvent('shipTo', this.shipTo));
                this.dispatchEvent(new FlowAttributeChangeEvent('shipToLoc', this.shipToLocation));
            }
            this.fetchBranchShippingDetails();
        }
        else {
            this.shipToName = event.detail.selectedRecord;
            this.shipToLocation = event.detail.selectedRecord;
            this.phoneNumber = '';
        }
    }

    displayCarrierNum() {
        if (this.recordIdName === '3rd Party Hauler') {
            this.displaycarrierfield = true;
            this.isOrderedFromReq = true;
            console.log('recordIdName', this.recordIdName);
        }
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        if (field === 'AddressLine1') {
            this.addressLine1 = event.target.value;
        }
        else if (field === 'AddressLine2') {
            this.addressLine2 = event.target.value;
        }
        else if (field === 'ShipToCity') {
            this.shipToCity = event.target.value;
        }
        else if (field === 'ShipToState') {
            this.shipToState = event.target.value;
        }
        else if (field === 'ShipToZip') {
            this.shipToZip = event.target.value;
        }
        else if (field === 'OrderedFrom') {
            this.orderedFrom = event.detail.value;
            if (this.fromTheFlow) {
                if (this.isOrderedFromReq && this.orderedFrom != '') {
                    this.errorMessage = '';
                    this.showErrorMessage = false;
                }
                this.dispatchEvent(new FlowAttributeChangeEvent('orderedFrom', this.orderedFrom));
            }
        }
        else if (field === 'OrderedFor') {
            this.orderedFor = event.target.value;
        }
        else if (field === 'ReqDate') {
            this.requestedDate = event.target.value;
        }
        else if (field === 'ShipDate') {
            this.shipDate = event.target.value;
        }
        else if (field === 'ShipToName') {
            this.shipToName = event.target.value;
        }
        else if (field === 'CustomerNumber') {
            this.customerNo = event.target.value;
            if (this.fromTheFlow) {
                if (this.isRerent && this.customerNo == '') {
                    this.errorMessage = 'Unable to create PO. Ship To and Customer Account # is required.';
                    this.showErrorMessage = true;
                }
                else {
                    this.errorMessage = '';
                    this.showErrorMessage = false;
                }
                this.dispatchEvent(new FlowAttributeChangeEvent('customerNumber', this.customerNo));
            }
        }
    }

    async handleSave() {

        if (this.checkValidity()) {
            // to update the Purchase Order record
            const fields = {};
            fields['Id'] = this.recordId;
            fields[objectFields.recordTypeId.apiName] = this.recordTypeId;
            fields[objectFields.shipToType.apiName] = this.shipToType;

            if (this.shipToType === 'Branch') {
                fields[objectFields.branchLocationNumber.apiName] = this.branchLocationNumber;
                fields[objectFields.shipToLocation.apiName] = this.shipToLocation;
            }
            else {
                fields[objectFields.shipToCustomer.apiName] = this.shipToCustomer;
            }
            fields[objectFields.addressLine1.apiName] = this.addressLine1.trim();
            fields[objectFields.addressLine2.apiName] = this.addressLine2;
            fields[objectFields.shipToCity.apiName] = this.shipToCity.trim();
            fields[objectFields.shipToState.apiName] = this.shipToState.trim();
            fields[objectFields.shipToZip.apiName] = this.shipToZip.trim();
            fields[objectFields.orderedFrom.apiName] = this.orderedFrom;
            fields[objectFields.requestedDate.apiName] = this.requestedDate;
            fields[objectFields.phoneNumber.apiName] = this.phoneNumber;
            fields[objectFields.orderedFor.apiName] = this.orderedFor;
            fields[objectFields.shipDate.apiName] = this.shipDate;
            fields[objectFields.shipToName.apiName] = this.shipToName;
            fields[objectFields.carrierNumber.apiName] = this.carrierNumber;
            fields[objectFields.carrierNum.apiName] = this.carrierNum;
            fields[objectFields.customerContractNum.apiName] = this.customerNo;

            const recordInput = { fields };
            try {
                this.showSpinner = true;
                await updateRecord(recordInput)
                console.log('Record updated successfully');
                this.showSpinner = false;
                this.dispatchEvent(new CustomEvent('save'));
            }
            catch (error) {
                this.showSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'An error occurred while trying to update the record.',
                        variant: 'error'
                    })
                );
            }
            console.log('After updateRecord');
        }
    }

    checkValidity() {
        let isValid = false;
        let fieldName = '';
        let length = 0;

        const allValid = [
            ...this.template.querySelectorAll("lightning-input")]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            let addressLine1 = this.template.querySelector('[data-field="AddressLine1"]');
            let addressLine2 = this.template.querySelector('[data-field="AddressLine2"]');
            let shipToCity = this.template.querySelector('[data-field="ShipToCity"]');
            let shipToState = this.template.querySelector('[data-field="ShipToState"]');
            let shipToZip = this.template.querySelector('[data-field="ShipToZip"]');
            let orderedFrom = this.template.querySelector('[data-field="OrderedFrom"]');
            let orderedFor = this.template.querySelector('[data-field="OrderedFor"]');
            let requestedDate = this.template.querySelector('[data-field="ReqDate"]');
            let shipDate = this.template.querySelector('[data-field="ShipDate"]');

            if (this.shipToType == 'Branch' && !this.shipToLocation) {
                fieldName = 'Branch';
            }
            else if (this.shipToType == 'Customer' && !this.shipToCustomer) {
                fieldName = 'Customer';
            }
            else if (addressLine1.value.trim().length < 1 || addressLine1.value.trim().length > objectFields.addressLine1.length) {
                fieldName = 'Address 1';
                length = (addressLine1.value.trim().length > 0) ? objectFields.addressLine1.length : 0;
            }
            else if (addressLine2.value && addressLine2.value.trim().length > objectFields.addressLine2.length) {
                fieldName = 'Address 2';
                length = objectFields.addressLine2.length;
            }
            else if ((shipToCity.value == undefined) || (shipToCity.value.trim().length < 1 || shipToCity.value.trim().length > objectFields.shipToCity.length)) {
                fieldName = 'City';
                length = (shipToCity.value.trim().length > 0) ? objectFields.shipToCity.length : 0;
            }
            else if ((shipToState.value == undefined) || (shipToState.value.trim().length !== 2)) {
                fieldName = 'State';
            }
            else if ((shipToZip.value == undefined) ||(shipToZip.value.trim().length < 1 || shipToZip.value.trim().length > objectFields.shipToZip.length)) {
                fieldName = 'Popstal Code';
                length = (shipToZip.value.trim().length > 0) ? objectFields.shipToZip.length : 0;
            }
            else if (orderedFrom.value && orderedFrom.value.trim().length > objectFields.orderedFrom.length) {
                fieldName = 'Ordered From';
                length = objectFields.orderedFrom.length;
            }
            else if (orderedFor.value && orderedFor.value.trim().length > objectFields.orderedFor.length) {
                fieldName = 'Ordered For';
                length = objectFields.orderedFor.length;
            }
            else if (requestedDate.value && isNaN(Date.parse(requestedDate.value))) {
                fieldName = 'Requested Date';
            }
            else if (shipDate.value && isNaN(Date.parse(shipDate.value))) {
                fieldName = 'Ship Date';
            }


            if (fieldName.length > 0) {
                let errorMessage = (length > 0) ? `${fieldName} must not be more than ${length} characters.`
                    : `${fieldName} must have a valid value.`
                if (this.fromTheFlow) {
                    this.showErrorMessage = true;
                    this.errorMessage = errorMessage;
                }
                else {
                    const event = new ShowToastEvent({
                        title: 'Invalid values',
                        message: errorMessage,
                        variant: 'error'
                        //message: result
                    });
                    this.dispatchEvent(event);
                }
            }
            else if (this.isRerent && (this.customerNo == '' || this.customerNo == undefined)) {
                let errorMessage = 'Ship To and Customer Account # is required.';
                if (this.fromTheFlow) {
                    this.showErrorMessage = true;
                    this.errorMessage = 'Unable to create PO. ' + errorMessage;
                }
                else {
                    const event = new ShowToastEvent({
                        title: 'Required',
                        message: errorMessage,
                        variant: 'error'
                        //message: result
                    });
                    this.dispatchEvent(event);
                }
            }
            else if (this.isOrderedFromReq && (orderedFrom.value == undefined || orderedFrom.value == '')) {
                let errorMessage = "Ordered From is required.";
                if (this.fromTheFlow) {
                    this.showErrorMessage = true;
                    this.errorMessage = errorMessage;
                }
                else {
                    const event = new ShowToastEvent({
                        title: 'Required',
                        message: errorMessage,
                        variant: 'error'
                        //message: result
                    });
                    this.dispatchEvent(event);
                }
            }
            else if ((this.displaycarrierfield || this.displaycarrierfieldonpage) && (this.carrierNumber == undefined || this.carrierNumber == '')) {
                let errorMessage = "Carrier number is required.";
                if (this.fromTheFlow) {
                    this.showErrorMessage = true;
                    this.errorMessage = errorMessage;
                }
                else {
                    const event = new ShowToastEvent({
                        title: 'Required',
                        message: errorMessage,
                        variant: 'error'
                        //message: result
                    });
                    this.dispatchEvent(event);
                }
            }
            else {
                isValid = true;
            }

        }
        else {
            if (this.fromTheFlow) {
                this.errorMessage = 'The value(s) provided are not valid.';
            }
            else {
                const event = new ShowToastEvent({
                    title: 'Invalid values',
                    message: 'The value(s) provided are not valid.',
                    variant: 'error'
                    //message: result
                });
                this.dispatchEvent(event);
            }
        }
        return isValid;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    // To handle previous click
    handlePrevious() {
        if (this.availableActions.find((action) => action === "BACK")) {
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }

    // To handle next click
    handleNext() {
        if (this.checkValidity() && this.availableActions.find((action) => action === "NEXT")) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        else {
            if (this.showErrorMessage && this.errorMessage != '') {
                //Scroll to error message
                const errorDiv = this.template.querySelector('[class*="slds-theme_error"]');
                if (errorDiv != undefined) {
                    errorDiv.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
                }
            }
        }
    }

    handleClick() {
        this.showcarriersearch = true;
        console.log(this.showcarriersearch);
    }

    handleCarrierSelect(event) {
        if (event.detail.selectedRecord !== undefined) {
            this.carrierNumber = event.detail.selectedRecord;
            this.carrierNum = event.detail.carrierNum;
            console.log("@@selected Carrier " + JSON.stringify(event.detail.selectedRecord));
            if (this.fromTheFlow && this.errorMessage != '') {
                this.showErrorMessage = false;
                this.errorMessage = '';
            }
        }
    }

    handleCarrierClear(event) {
        if (event.detail.selectedRecord == undefined || event.detail.selectedRecord == '') {
            this.carrierNumber = event.detail.selectedRecord;
            //this.carrierNum = event.detail.selectedRecord;
        }
    }
}