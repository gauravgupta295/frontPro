import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import SHIPTO_TYPE from '@salesforce/schema/Purchase_Order__c.ShipTo_Type__c';
import SHIPTO from '@salesforce/schema/Purchase_Order__c.ShipTo__c';
import COMPLETE_SHIPPING_ADDRESS from '@salesforce/schema/Purchase_Order__c.Complete_Shipping_Address__c';
import SHIPTO_ADDR1 from '@salesforce/schema/Purchase_Order__c.ShipTo_Addr1__c';
import SHIPTO_ADDR2 from '@salesforce/schema/Purchase_Order__c.ShipTo_Addr2__c';
import SHIPTO_CITY from '@salesforce/schema/Purchase_Order__c.ShipTo_City__c';
import SHIPTO_STATE from '@salesforce/schema/Purchase_Order__c.ShipTo_State__c';
import SHIPTO_ZIP from '@salesforce/schema/Purchase_Order__c.ShipTo_Zip__c';
import ORDERED_FROM from '@salesforce/schema/Purchase_Order__c.Ordered_From__c';
import REQUESTED_DATE from '@salesforce/schema/Purchase_Order__c.Requested_Date__c';
import PHONE_NUMBER from '@salesforce/schema/Purchase_Order__c.Phone_Number__c';
import ORDERED_FOR from '@salesforce/schema/Purchase_Order__c.Ordered_For__c';
import SHIP_DATE from '@salesforce/schema/Purchase_Order__c.Ship_Date__c';
import SHIPTO_LOCATION from '@salesforce/schema/Purchase_Order__c.ShipTo_Location__c';
import SHIPTO_CUSTOMER from '@salesforce/schema/Purchase_Order__c.ShipTo_Customer__c';
import BRANCH_LOCATION from '@salesforce/schema/Purchase_Order__c.Branch_Location__c';
import LOCATION from '@salesforce/schema/Purchase_Order__c.Location__c';
import VENDOR from '@salesforce/schema/Purchase_Order__c.Vendor__c';
import CUSTOMER from '@salesforce/schema/Purchase_Order__c.Customer__c';
import SHIPTO_NAME from '@salesforce/schema/Purchase_Order__c.ShipTo_Name__c';
import RECORD_TYPE from '@salesforce/schema/Purchase_Order__c.RecordTypeId';
import THIRD_PARTY_CARRIER from '@salesforce/schema/Purchase_Order__c.Third_Party_Carrier__r.Name';
import TYPE from '@salesforce/schema/Purchase_Order__c.Type__c';
import CUSTOMERNO from '@salesforce/schema/Purchase_Order__c.Customer_or_Contract_Number__c';
import PO_STATUS from '@salesforce/schema/Purchase_Order__c.Status__c';
import REOPENED_STATUS from '@salesforce/schema/Purchase_Order__c.Reopened__c';
import FORM_FACTOR from "@salesforce/client/formFactor";

const SMALL_FORM_FACTOR = "Small";

const poFields = [SHIPTO_TYPE, SHIPTO_LOCATION, SHIPTO_ADDR1, SHIPTO_ADDR2, SHIPTO_CITY,
    SHIPTO_STATE, SHIPTO_ZIP, COMPLETE_SHIPPING_ADDRESS, ORDERED_FROM,
    REQUESTED_DATE, PHONE_NUMBER, ORDERED_FOR, SHIP_DATE, VENDOR, SHIPTO,
    SHIPTO_CUSTOMER, BRANCH_LOCATION, LOCATION, CUSTOMER, SHIPTO_NAME, RECORD_TYPE, THIRD_PARTY_CARRIER, TYPE, CUSTOMERNO, PO_STATUS, REOPENED_STATUS];

export default class Sbr_3_0_POShippingDetails extends LightningElement {

    @api recordId;
    record;
    fromTheFlow = false;
    isReadOnlyMode = true;
    dataToRefresh;

    showEditIcon = true;

    shipToType
    shipToName;
    completeShippingAddress;
    shipToLocation;
    shipToCustomer;
    branchLocation;
    location;
    customer;
    selectedValue;
    addressLine1;
    addressLine2;
    shipToCity;
    shipToState;
    shipToZip;
    branchLocationNumber;
    orderedFrom;
    phoneNumber;
    orderedFor;
    requestedDate;
    shipDate;
    vendorAccountId;
    selectedVendorContactId;
    vendorContacts = [];
    error;
    thirdPartyCarrier;
    type;
    thirdpartyCarrierflag = false;
    isRerent = false;
    customerNo = '';
    custAccNum = '';

    shipEditObj = {};

    // alignClass = 'slds-grid slds-wrap';
    // shipTypeWidth = 'slds-size_4-of-12 slds-p-horizontal_medium';
    // shipToWidth = 'slds-size_8-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // completeShippingAddressWidth = 'slds-size_12-of-12 slds-p-horizontal_medium';
    // phoneNumberWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // orderedFromWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // orderedForWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // requestedDateWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // shipDateWidth = 'slds-size_12-of-12 slds-p-horizontal_medium slds-m-top_xx-small';
    // isMobile = false;


    @wire(getRecord, { recordId: '$recordId', fields: poFields })
    wiredRecord(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.record = result.data;
            console.log('Record Id:', this.recordId);

            this.shipEditObj.RecordTypeId = getFieldValue(this.record, RECORD_TYPE);
            this.shipEditObj.ShipTo_Type__c = getFieldValue(this.record, SHIPTO_TYPE);
            this.shipEditObj.ShipTo_Location__c = getFieldValue(this.record, SHIPTO_LOCATION);
            this.shipEditObj.Complete_Shipping_Address__c = getFieldValue(this.record, COMPLETE_SHIPPING_ADDRESS);
            this.shipEditObj.ShipTo_Addr1__c = getFieldValue(this.record, SHIPTO_ADDR1);
            this.shipEditObj.ShipTo_Addr2__c = getFieldValue(this.record, SHIPTO_ADDR2);
            this.shipEditObj.ShipTo_City__c = getFieldValue(this.record, SHIPTO_CITY);
            this.shipEditObj.ShipTo_State__c = getFieldValue(this.record, SHIPTO_STATE);
            this.shipEditObj.ShipTo_Zip__c = getFieldValue(this.record, SHIPTO_ZIP);
            this.shipEditObj.Ordered_From__c = getFieldValue(this.record, ORDERED_FROM);
            this.shipEditObj.Requested_Date__c = getFieldValue(this.record, REQUESTED_DATE);
            this.shipEditObj.Phone_Number__c = getFieldValue(this.record, PHONE_NUMBER);
            this.shipEditObj.Ordered_For__c = getFieldValue(this.record, ORDERED_FOR);
            this.shipEditObj.ShipTo__c = getFieldValue(this.record, SHIPTO);
            this.shipEditObj.Ship_Date__c = getFieldValue(this.record, SHIP_DATE);
            this.shipEditObj.Vendor__c = getFieldValue(this.record, VENDOR);
            this.shipEditObj.ShipTo_Customer__c = getFieldValue(this.record, SHIPTO_CUSTOMER);
            this.shipEditObj.Branch_Location__c = getFieldValue(this.record, BRANCH_LOCATION);
            this.shipEditObj.Location__c = getFieldValue(this.record, LOCATION);
            this.shipEditObj.Customer__c = getFieldValue(this.record, CUSTOMER);
            this.shipEditObj.ShipTo_Name__c = getFieldValue(this.record, SHIPTO_NAME);
            this.shipEditObj.Third_Party_Carrier__c = getFieldValue(this.record, THIRD_PARTY_CARRIER);
            this.shipEditObj.Type__c = getFieldValue(this.record, TYPE);

            this.shipEditObj.Status__c = getFieldValue(this.record, PO_STATUS);
            console.log('PO_STATUS : ', this.shipEditObj.Status__c);
            this.shipEditObj.Reopened__c = getFieldValue(this.record, REOPENED_STATUS);
            console.log('REOPENED_STATUS : ', this.shipEditObj.Reopened__c);
            this.shipToName = this.shipEditObj.ShipTo_Name__c;
            this.completeShippingAddress = this.shipEditObj.Complete_Shipping_Address__c;
            this.phoneNumber = this.shipEditObj.Phone_Number__c;
            this.orderedFrom = this.shipEditObj.Ordered_From__c;
            this.orderedFor = this.shipEditObj.Ordered_For__c;
            this.requestedDate = this.shipEditObj.Requested_Date__c;


            if (this.requestedDate) {
                let formattedReqDate = new Date(this.requestedDate).toLocaleDateString('en-US', { timeZone: 'UTC' });
                this.requestedDate = formattedReqDate;
            }
            this.shipDate = this.shipEditObj.Ship_Date__c;
            if (this.shipDate) {
                let formattedShipDate = new Date(this.shipDate).toLocaleDateString('en-US', { timeZone: 'UTC' });
                this.shipDate = formattedShipDate;
            }
            this.type = this.shipEditObj.Type__c;

            if (this.type === '3rd Party Hauler') {
                this.thirdpartyCarrierflag = true;
                this.thirdPartyCarrier = this.shipEditObj.Third_Party_Carrier__c;

                if (this.shipEditObj.Status__c === 'Open' || this.shipEditObj.Status__c === 'Back Order' || this.shipEditObj.Status__c === 'Partially Received' || this.shipEditObj.Status__c === 'Received'  || this.shipEditObj.Status__c === 'Cancelled') {
                    this.showEditIcon = false;
                }
                else {                 
                    this.showEditIcon = true;

                }
            }
            console.log(this.type);

            if (this.type === 'Standard Purchase Order') {
                if (this.shipEditObj.Status__c === 'Received' || this.shipEditObj.Status__c === 'Cancelled') {
                    this.showEditIcon = false;
                }
                else if(this.shipEditObj.Status__c === 'Open' && this.shipEditObj.Reopened__c===true)
                {
                    this.showEditIcon = false;
                } 
                else {
                    this.showEditIcon = true;
                }
            }

            if (this.type === 'Standard Purchase Order - One Step') {
                if (this.shipEditObj.Status__c === 'Received') {
                    this.showEditIcon = false;
                }
                else {
                    this.showEditIcon = true;
                }
            }

            if (this.type === 'Rerent') {
                this.isRerent = true;
                this.customerNo = getFieldValue(this.record, CUSTOMERNO);
                if (this.customerNo != null) {
                    this.customerNo = this.customerNo.toString();
                }
                this.shipEditObj.customerNo = getFieldValue(this.record, CUSTOMERNO);

                if (this.shipEditObj.Status__c === 'Open' || this.shipEditObj.Status__c === 'Back Order' || this.shipEditObj.Status__c === 'Partially Received'  || this.shipEditObj.Status__c === 'Received'  || this.shipEditObj.Status__c === 'Cancelled') {
                    this.showEditIcon = false;
                }
                else {
                    this.showEditIcon = true;
                }
            }
            console.log('shipToLocation: ' + this.shipToLocation);
        }
        else if (result.error) {
            this.error = result.error;
            console.error(this.error);
        }
    }

    handleSectionClick(event) {
        event.detail.ariaExpanded = true;
    }

    handleEditClick(event) {
        this.isReadOnlyMode = false;
    }

    handleCancel(event) {
        this.isReadOnlyMode = true;
    }

    handleSave(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Record updated successfully',
                variant: 'success'
            })
        );
        refreshApex(this.dataToRefresh);
        this.isReadOnlyMode = true;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    // connectedCallback() {

    //     if (FORM_FACTOR === 'Small') {
    //         this.isMobile = true;
    //         this.alignClass = this.alignClass + ' slds-grid_vertical';
    //         this.shipTypeWidth = 'slds-size_1-of-1 slds-p-horizontal_medium';
    //         this.shipToWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';
    //         this.completeShippingAddressWidth = 'slds-size_1-of-2 slds-p-horizontal_medium';
    //         this.phoneNumberWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';
    //         this.orderedFromWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';
    //         this.orderedForWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';
    //         this.requestedDateWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';
    //         this.shipDateWidth = 'slds-size_1-of-2 slds-p-horizontal_medium slds-m-top_xx-small';

    //     }
    // }
}