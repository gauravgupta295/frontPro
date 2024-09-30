import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, createRecord, updateRecord } from 'lightning/uiRecordApi';
import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from "@salesforce/i18n/timeZone";
import ID_FIELD from "@salesforce/schema/Cart__c.Id";
import RENTALPERIOD_FIELD from '@salesforce/schema/Cart__c.Rental_Period__c';
import STARTDATE_FIELD from '@salesforce/schema/Cart__c.Rental_Start_Date__c';
import RETURDATE_FIELD from '@salesforce/schema/Cart__c.Rental_End_Date__c';
import ZIPCODE_FIELD from '@salesforce/schema/Cart__c.Zip_Code__c';
import NOTES_FIELD from '@salesforce/schema/Cart__c.Notes__c';
import START_TIME_FIELD from '@salesforce/schema/Cart__c.Rental_Start_Time__c';
import END_TIME_FIELD from '@salesforce/schema/Cart__c.Rental_End_Time__c';
import CUSTOMERPICKUP_FIELD from '@salesforce/schema/Cart__c.Customer_Pick_Up__c';
import ACCOUNT_FIELD from '@salesforce/schema/Cart__c.Account__c';
import updateOrderItemTaxes from '@salesforce/apex/SBR_3_0_API_Contract_OpenOrderTaxUpdate.updateOrderItemTaxes';//10062, SADAPUR
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import updateQuoteItemTaxes from '@salesforce/apex/SBR_3_0_API_Contract_OpenQuoteTaxUpdate.updateQuoteTaxes';//19714, 21257, SADAPUR


import { NavigationMixin } from 'lightning/navigation';



export default class Sbr_3_0_editCartInfoCmp extends NavigationMixin(LightningElement) {

    cancelBtnClass = 'slds-button cancel-btn-class';
    saveBtnClass = 'slds-button save-btn-class';
    showCartInformation = false;
    userTimeZone = TIME_ZONE;
    userTimeZoneStartDate;
    userTimeZoneStartDate1;
    pstTimeZone = 'America/Los_Angeles';
    mobileIsLoading = false;
    @api _selectedCustomer;
    @api recordId;
    @api objectApiName;
    @api cartRecordTypeIdString; 
    @api _tempCustomer;
    savedRentalPeriod;
    savedStartDate;
    savedReturnDate;
    savedStartTime;
    savedReturnTime;
    savedDeliveryCpu;
    savedZipCode;
    savedNotes;
    savedCustomer;
    @api rentalPeriod = '';
    @api startDate;
    @api startTime = '12:00:00.000';
    @api returnDate;
    @api returnTime = '12:00:00.000';
    @api deliveryCpu = '';
    @api jobsiteZip;

    minStartDate;
    minReturnDate;
    disableDuration = true;
    notes;
    isFirstRender = true;
    isInvalidStartDate = false;
    isInvalidEndDate = false;
    messageTest = 'empty';
    isJobsiteRequired = false;
    jobsiteErrorMsg = 'Job Site Zip Code is required for Delivery';
    whereClause = "RecordType.DeveloperName in ('ERP_Link', 'Credit')";
    acctFields = "RM_Account_Number__c, ShippingCity, ShippingState, ShippingPostalCode, RM_Account_Number_Display__c, Status__c, Phone,Company_Code__c, E_mail_Address__c";//25958, Company_Code__c
    _context = 'Cart';
    customerName = '';
    showSaveBtn = false;
    showDNEBanner = false;
    showSetRatesBanner = false;
    showPricingUpdatedBanner = false;
    showCSPBanner = false;
    showPercentBanner = false;
    showSpecialRateBanner = false;
    showPricingBanner = false;
    //showCPUDeliveryField = false;
    dneBannerMessage = 'Customer has Do No Exceed Rates. Rates increases not allowed';
    setRatesBannerMessage = 'Customer has Set Rates. Rates cannot be changed.';
    pricingUpdatedBannerMessage = 'Pricing has been updated.';
    customerPricingAdjustingBannerMessage = 'Customer Pricing Adjusted.'
    cSPBannerMessage = 'Customer Special pricing has been applied. Please review line item details for more information.';
    percentBannerMessage = 'Customer has % off Local Book Rates. Rates increases not allowed.';
    specialRateBannerMessage = 'Customer has special rates';
    pricingMessage;
    customerOrPricingBannerMessage;
    showCloseBannerIcon = false;

    fields = [];
    
    wiredRecordResult;
    accountRecordId = '';
    accountRecordName = '';
    oilGasRecordTypeIdString = '';


    connectedCallback() {
        if (this.recordId) {
            this.setContext();
            this.setRecordFields();
            this.wiredRecord();
            
        }
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        this.initializeFields();
        //this.displayCartInfo();
    }
    renderedCallback() {

        if (this.isFirstRender && !this.recordId) {
            this.isFirstRender = false;
            if(this._tempCustomer)
            {
                this._selectedCustomer = this._tempCustomer;
            } 
        }

    }

    initializeFields() {
       
        let today = new Date();
        today.setDate(today.getDate() + 1);
        //this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
        let startMonthPad;
        let startDayPad;
        if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
            today.getDate() > 0 && today.getDate() < 10) {
            startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            startDayPad = today.getDate().toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${startMonthPad}-${startDayPad}`;
        }
        // if only date is between 1-9
        else if (today.getDate() > 0 && today.getDate() < 10) {
            startDayPad = today.getDate().toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${startDayPad}`;
        }
        // if only month is between 1-9
        else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
            startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            this.startDate = `${today.getFullYear()}-${startMonthPad}-${today.getDate()}`;
        } else {
            this.startDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`
        }
        this.minStartDate = this.startDate;
        today.setDate(today.getDate() + 7);
        let returnMonthPad;
        let returnDayPad;
        if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
            today.getDate() > 0 && today.getDate() < 10) {
            returnMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            returnDayPad = today.getDate().toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${returnMonthPad}-${returnDayPad}`;
        }
        else if (today.getDate() > 0 && today.getDate() < 10) {
            returnDayPad = today.getDate().toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${today.getMonth() + 1}-${returnDayPad}`;
        }

        else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
            returnMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
            this.returnDate = `${today.getFullYear()}-${returnMonthPad}-${today.getDate()}`;
        } else {
            this.returnDate = `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}`;
        }

        this.savedStartDate = this.startDate;
        this.savedReturnDate = this.returnDate;
        this.savedDeliveryCpu = this.deliveryCpu;
        this.savedStartTime = this.startTime;
        this.savedReturnTime = this.returnTime;
        this.updateCartInfo();

    }

     // display cart info
    displayCartInfo() {
        
        // Handle "rerendering" the edit cart info, to assist in "rerendering" it to it's previous saved state
        if (!this.recordId) {
            if (this.template.querySelector('[data-name=jobsite-zip]').value != undefined && this.savedZipCode != undefined) {
                this.jobsiteZip = this.savedZipCode;
                this.template.querySelector('[data-name=jobsite-zip]').value = this.savedZipCode;
            }
            this.validateStartDate();
            this.updateReturnDates();
        }
        console.log("toggles this end ...");
    }

    updateCartInfo() {
        let cartInfo = this.getInfoObject();
        if (!this.recordId) {
            console.log('send cartInfo: ', JSON.stringify(cartInfo));
            const cartSyncEvent = new CustomEvent('cartsync', {
                detail: {
                    cartInfo: cartInfo
                }
            });
            this.dispatchEvent(cartSyncEvent);
        }
    }
    setContext() {
        switch (this.objectApiName) {
            case 'Cart__c':
                this._context = 'Cart';
                break;
            case 'SBQQ__Quote__c':
                this._context = 'Quote';
                break;
            case 'Order':
                this._context = 'Order';
                break;
            default:
                this._context = 'Cart';
                break;
        }
    }

    
     //wire method to set customer information based on record page context
     @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
     wiredRecord(result) {
         this.wiredRecordResult = result;//14147, SADAPUR             
         if (result) {
             let data = result.data;
             let error = result.error;
             if (data) {
                 try {
                     let fieldsData;
                     let cartEditFlag = false;
                     console.log('object api name : ' + this.objectApiName);
                     switch (this.objectApiName) {
                         case 'Cart__c':
                             if(data.fields.RecordType && data.fields.RecordType.displayValue == "Oil & Gas") {
                                 this.showCartInformation = false;
                             }
                             if (data.fields.Account__r) {
                                 fieldsData = data.fields.Account__r.value;
                                 cartEditFlag = true;
                             }
                             break;
                         case 'SBQQ__Quote__c':
                             fieldsData = data.fields.SBQQ__Account__r.value;
                             break;
                         case 'Order':
                             console.log('get record in lineitemcontainer! Order data->' + JSON.stringify(data)); //10062
                             fieldsData = data.fields.Account.value;
                             //SAL-26747
                             if (data.fields.Deliverymethod__c) {
                                 switch (data.fields.Deliverymethod__c.value) {
                                     case 'Delivery':
                                         this.deliveryCpu = 'delivery';
                                         break;
                                     case 'Pickup':
                                         this.deliveryCpu = 'cpu';
                                         break;
                                 }
                             }
                             break;
                     }
                     if (fieldsData) {
                         let acctInfo = {
                             Id: fieldsData.fields.Id.value,
                             Name: fieldsData.fields.Name.value,
                             RM_Account_Number__c: fieldsData.fields.RM_Account_Number__c.value,
                             Company_Code__c: fieldsData.fields.Company_Code__c.value,
                             RecordTypeId: fieldsData.recordTypeId,
                             DisplayName: fieldsData.fields.Name.value
                         };
                         this.accountRecordName = fieldsData.fields.Name.value;
 
                         this.accountRecordId = fieldsData.fields.Id.value;
                         this._selectedCustomer = acctInfo;
                         console.log('lineItemsContainer this._selectedCustomer->' + JSON.stringify(this._selectedCustomer));
 
                     }
                     if (this.isQuoteOrOrderContext) {
                         if (data.fields.Specific_Pricing_Flag__c) {
                             this.showCSPBanner = data.fields.Specific_Pricing_Flag__c.value;
                         }
                     }
                     if (cartEditFlag) {
                         console.log('data.fields-->' + JSON.stringify(data.fields));
                         if (data.fields.Rental_Period__c) {
                             switch (data.fields.Rental_Period__c.value) {
                                 case '1 Day':
                                     this.rentalPeriod = '1day';
                                     break;
                                 case '7 Days':
                                     this.rentalPeriod = '7days';
                                     break;
                                 case '14 Days':
                                     this.rentalPeriod = '14days';
                                     break;
                                 case '28 Days':
                                     this.rentalPeriod = '28days';
                                     break;
                                 case 'Custom':
                                     this.rentalPeriod = 'custom';
                                     break;
                             }
                         }
                         if (data.fields.Zip_Code__c) {
                             this.jobsiteZip = data.fields.Zip_Code__c.value;
                             this.template.querySelector('[data-name=jobsite-zip]').value = data.fields.Zip_Code__c.value;
                         }
                         if (data.fields.Customer_Pick_Up__c) {
 
                             switch (data.fields.Customer_Pick_Up__c.value) {
                                 case 'Delivery':
                                     this.deliveryCpu = 'delivery';
                                     break;
                                 case 'Pickup':
                                     this.deliveryCpu = 'cpu';
                                     break;
                             }
                         }
                         //Fix update for SAL-14015  "Added Cart__c object condition for making customer information field on edit card record page editable "
                         if (data.fields.Account__c && this.objectApiName != 'Cart__c') {
                             this._selectedCustomer = data.fields.Account__c.value;
                         }
 
                         var timezone = TIME_ZONE;
                         console.log('Time Zone Preference in Salesforce ORG :' + timezone);
 
                         if (data.fields.Start_Date__c) {
                             console.log('in getRecord data.fields.Start_Date__c ' + JSON.stringify(data.fields.Start_Date__c));
                             let startCartDate = data.fields.Start_Date__c.value;
                             console.log('startCartDate:' + startCartDate);
                             this.startDate = startCartDate;
                         }
                         if (data.fields.Rental_Start_Time__c) {
                             console.log('in getRecord data.fields.Rental_Start_Time__c ' + JSON.stringify(data.fields.Rental_Start_Time__c));
                             //let startTimeCart = data.fields.Rental_Start_Time__c.value;
                             this.startTime = data.fields.Rental_Start_Time__c.value;
                             console.log('this.startDate:' + this.startTime);
                         }
                        
                         if (data.fields.Return_Date__c) {
                             let endDT = data.fields.Return_Date__c.value;
                             this.returnDate = endDT;
                             console.log('this.returnDate:' + this.returnDate);
                         }
                         if (data.fields.Rental_End_Time__c) {
                             this.returnTime = data.fields.Rental_End_Time__c.value;
                             console.log('this.returnTime:' + this.returnTime);
                         }
                         if (data.fields.Notes__c) {
                             this.notes = data.fields.Notes__c.value;
                         }
                         if (data.fields.RecordType.displayValue == 'Standard') {
                             this.showSaveBtn = true;
                         }
 
                     }
                 } catch (e) {
                     console.log('\n @@vp error caught in wiredRecord lineitemsContainerCmp' + JSON.stringify(e));
                 }
             } else if (error) {
                 if (Array.isArray(error.body)) {
                     // If the error body is an array of errors
                     error.body.forEach(err => {
                         console.error('Error message:', err.message);
                         console.error('Error status code:', err.statusCode);
                         console.error('Error stack:', err.stack);
                     });
                 } else if (typeof error.body === 'object') {
                     // If the error body is a single error object
                     console.error('Error message:', error.body.message);
                     console.error('Error status code:', error.body.statusCode);
                     console.error('Error stack:', error.body.stack);
                 }
 
                 console.log('error seen on wiredRecord on LIC  ' + error);
             }
         }
     }
     //set fields to fetch for account information based on record page context
     setRecordFields() {
         console.log('this.objectApiName 300' + this.objectApiName);
 
         switch (this.objectApiName) {
 
             case 'Cart__c':
                 this.fields = ['Cart__c.Account__r.Name', 'Cart__c.Account__r.Company_Code__c', 'Cart__c.Account__r.Id', 'Cart__c.Account__r.RM_Account_Number__c', 'Cart__c.Rental_Period__c', 'Cart__c.Rental_Start_Date__c',
                     'Cart__c.Rental_End_Date__c', 'Cart__c.Customer_Pick_Up__c', 'Cart__c.Account__c', 'Cart__c.Zip_Code__c', 'Cart__c.RecordType.Name','Cart__c.RecordTypeId','Cart__c.Notes__c', 'Cart__c.Rental_Start_Time__c', 'Cart__c.Rental_End_Time__c', 'Cart__c.Start_Date__c', 'Cart__c.Return_Date__c'];
                 break;
             case 'SBQQ__Quote__c':
                 this.fields = ['SBQQ__Quote__c.SBQQ__Account__r.Name', 'SBQQ__Quote__c.SBQQ__Account__r.Company_Code__c', 'SBQQ__Quote__c.SBQQ__Account__r.Id', 'SBQQ__Quote__c.SBQQ__Account__r.RM_Account_Number__c', 'SBQQ__Quote__c.Specific_Pricing_Flag__c'];
                 updateQuoteItemTaxes({ recordId: this.recordId }).then(
                     result => {
                         console.log('isValidQuoteRecord->' + result.isValidQuoteRecord);
                         this.refreshData(this.wiredRecordResult);
                     }
                 )
                 break;
             case 'Order':
                 this.fields = ['Order.Account.Name', 'Order.Account.Company_Code__c', 'Order.Account.Id', 'Order.Account.RM_Account_Number__c', 'Order.RecordType.Name', 'Order.Specific_Pricing_Flag__c', 'Order.Deliverymethod__c'];//10062 | SAL-26747: Added Deliverymethod__c
                 updateOrderItemTaxes({ recordId: this.recordId }).then(
                     result => {
                         console.log('isValidOrderRecord->' + result.isValidOrderRecord);
                         this.refreshData(this.wiredRecordResult);
                     }
                 )
                 break;
         }
     }
     
    get isQuoteOrOrderContext() {
        return (this._context == 'Quote' || this._context == 'Order');
    }
  
    get rpOptions() {
        return [
            { label: 'Day', value: '1day' },
            { label: 'Week', value: '7days' },
            { label: '4 Week', value: '28days' },
            { label: 'Custom', value: 'custom' }
        ];
    }
    get dcOptions() {
        return [
            { label: 'Delivery', value: 'delivery' },
            { label: 'CPU', value: 'cpu' }
        ];
    }

    updateField(e) {
        let targetField = e.target;
        console.log('TargetField.Name: ' + targetField.name);
        console.log('TargetField.Value: ' + targetField.value);
        switch (targetField.name) {
            case 'rental-period':
                this.rentalPeriod = targetField.value;
                if (targetField.value == 'custom') {
                    this.disableDuration = false;
                } else {
                    this.disableDuration = true;
                }
                this.updateReturnDates();
                break;
            case 'start-date':
                if (targetField.value == null || targetField.value == '') {
                    targetField.value = this.startDate;
                } else {
                    let date = new Date(targetField.value.replaceAll('-', '/'));
                    //date.setDate(date.getDate() + 1);
                    let monthPad;
                    let dayPad;
                    // if both month and date are between 1-9, pad with 0
                    if (((date.getMonth() + 1) > 0) && (date.getMonth() + 1) < 10 &&
                        date.getDate() > 0 && date.getDate() < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${monthPad}-${dayPad}`;
                    }
                    // if only date is between 1-9
                    else if (date.getDate() > 0 && date.getDate() < 10) {
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${dayPad}`;
                    }
                    // if only month is between 1-9
                    else if ((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        this.startDate = `${date.getFullYear()}-${monthPad}-${date.getDate()}`;
                    } else {
                        this.startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
                    }
                }
                this.validateStartDate();
                this.updateReturnDates();
                break;
            case 'start-time':
                if (targetField.value == null || targetField.value == '') targetField.value = this.startTime;
                console.log('start time->' + targetField.value);
                this.startTime = targetField.value;
                this.returnTime = targetField.value;
                break;
            case 'return-date':
                if (targetField.value == null || targetField.value == '') {
                    targetField.value = this.returnDate;
                } else {
                    console.log('return date target value->' + targetField.value);
                    let date = new Date(targetField.value.replaceAll('-', '/'));
                    let monthPad;
                    let dayPad;
                    // if both month and date are between 1-9, pad with 0
                    if (((date.getMonth() + 1) > 0) && (date.getMonth() + 1) < 10 &&
                        date.getDate() > 0 && date.getDate() < 10) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${monthPad}-${dayPad}`;
                    }
                    // if only date is between 1-9
                    else if ((date.getDate() > 0 && date.getDate() < 10) &&
                        !((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10)) {
                        dayPad = date.getDate().toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${date.getMonth() + 1}-${dayPad}`;
                    }
                    // if only month is between 1-9
                    else if (((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10)
                        && !(date.getDate() > 0 && date.getDate() < 10)) {
                        monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
                        this.returnDate = `${date.getFullYear()}-${monthPad}-${date.getDate()}`;
                    } else {
                        this.returnDate = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
                    }

                }
                this.validateReturnDate();
                break;
            case 'return-time':
                if (targetField.value == null || targetField.value == '') targetField.value = this.returnTime;
                this.returnTime = targetField.value;
                break;
            case 'delivery-cpu':
                this.deliveryCpu = targetField.value;
                this.isJobsiteRequired = targetField.value == 'delivery' ? true : false;
                if (this.deliveryCpu == 'cpu') {
                    this.deliveryCpu.toUpperCase();
                }
                break;
            case 'jobsite-zip':
                this.jobsiteZip = targetField.value;
                if (this.deliveryCpu == 'delivery' && targetField.value == '') {
                    const inputElement = this.template.querySelector('[data-name="jobsite-zip"]');
                    inputElement.reportValidity();
                }
                break;
            case 'notes':
                this.notes = targetField.value;
        }
    }

    cancelCartInfo(event) {
       
        this.isInvalidStartDate = false;
        this.isInvalidEndDate = false;
        if (this.savedRentalPeriod) {
            this.rentalPeriod = this.savedRentalPeriod;
            this.disableDuration = this.rentalPeriod == 'custom' ? false : true;
            this.updateReturnDates();
        } else {
            this.rentalPeriod = '7days';
            this.disableDuration = true;
            this.updateReturnDates();
        }
        if (this.savedStartDate) this.startDate = this.savedStartDate;
        if (this.savedReturnDate) this.returnDate = this.savedReturnDate;
        if (this.savedDeliveryCpu) {
            this.deliveryCpu = this.savedDeliveryCpu;
            this.isJobsiteRequired = this.deliveryCpu == 'delivery' ? true : false;
        }
        if (this.template.querySelector('[data-name=jobsite-zip]').value == null || this.template.querySelector('[data-name=jobsite-zip]').value == '') {
            this.jobsiteZip = this.savedZipCode;
            this.template.querySelector('[data-name=jobsite-zip]').value = this.savedZipCode;
        }
        else {
            this.jobsiteZip = this.savedZipCode;
            this.template.querySelector('[data-name=jobsite-zip]').value = this.savedZipCode;
        }
        if (this.savedStartTime) this.startTime = this.savedStartTime;
        if (this.savedReturnTime) this.returnTime = this.savedReturnTime;

        this.template.querySelector('[data-name=notes]').value = this.savedNotes;
        this.notes = this.savedNotes;

        if (this.savedCustomer != null) {
            if (this._selectedCustomer != null) {
                if (this._selectedCustomer.Name != null && this.savedCustomer == null) {
                    this.customerName = '';
                    this._selectedCustomer = null;
                    if (this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp')) {
                        this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').handleRemove();
                    }
                    if (this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp-frontline')) {
                        this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp-frontline').handleRemove();
                    }
                } else {
                    this.customerName = this.savedCustomer.Name + ', ';
                    this._selectedCustomer = this.savedCustomer;
                    console.log('Customer should be changed here');
                }
            } else {
                this.customerName = '';
                this._selectedCustomer = null;
            }
        } else {
            console.log('fell here in else 720');
          /* this.customerName = '';
            this._selectedCustomer = null;
            if (this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp')) {
                this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').handleRemove();
            }
            if (this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp-frontline')) {
                this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp-frontline').handleRemove();
            }*/
        }
        console.log('Send toggleprodinqmobilestate');

        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            detail: {
                viewState: 'base',
                showTabsPanel: true
            }
        });
        this.dispatchEvent(toggleprodinqmobilestate);
        this.dispatchEvent(new CustomEvent('cancelcartinfo'));
    }

    saveCartInfo(event) {
        let today = new Date();
        try {
            today.setDate(today.getDate() + 1);
            let startMonthPad;
            let startDayPad;
            let validDate;
            if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10 &&
                today.getDate() > 0 && today.getDate() < 10) {
                startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
                startDayPad = today.getDate().toString().padStart(2, '0');
                validDate = `${startMonthPad}/${startDayPad}/${today.getFullYear()}`;
            }
            // if only date is between 1-9
            else if (today.getDate() > 0 && today.getDate() < 10) {
                startDayPad = today.getDate().toString().padStart(2, '0');
                validDate = `${today.getMonth() + 1}/${startDayPad}/${today.getFullYear()}`;
            }
            // if only month is between 1-9
            else if ((today.getMonth() + 1) > 0 && (today.getMonth() + 1) < 10) {
                startMonthPad = (today.getMonth() + 1).toString().padStart(2, '0');
                validDate = `${startMonthPad}/${today.getDate()}/${today.getFullYear()}/`;
            } else {
                validDate = `${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}`
            }

            this.savedRentalPeriod = this.rentalPeriod;
            if (this.validateStartDate() && this.validateReturnDate()) {
                this.savedStartDate = this.startDate;
                this.savedReturnDate = this.returnDate;
            }
            this.savedStartTime = this.startTime;
            this.savedReturnTime = this.returnTime;
            console.log('this.savedReturnTime: ', this.savedReturnTime);
            console.log('this.returnTime: ', this.returnTime);

            this.savedDeliveryCpu = this.deliveryCpu;

            if (this.template.querySelector('[data-name=jobsite-zip]').value == null || this.template.querySelector('[data-name=jobsite-zip]').value == '') {
                this.jobsiteZip = this.template.querySelector('[data-name=jobsite-zip]').value;
            }
            if (this.validateZipCode()) {
                this.jobsiteZip = this.template.querySelector('[data-name=jobsite-zip]').value;
                this.savedZipCode = this.jobsiteZip;
            }

            this.savedNotes = this.notes;

            if (this._selectedCustomer != null) {
                if (this._selectedCustomer.Name == null) {
                    this.customerName = '';
                    this.savedCustomer = null
                } else {
                    this.customerName = this._selectedCustomer.Name + ', ';
                    this.savedCustomer = this._selectedCustomer;
                }
            } else {
                this.customerName = '';
                this.savedCustomer = null
            }

            if (this.validateCartInfo()) {
                this.dispatchEvent(new CustomEvent('cancelcartinfo'));

                this.dispatchEvent (new CustomEvent('savecartinfos',{
                            detail : {
                                context : 'Product Inquiry',
                                information : this.getInfoObject()
                            }
                }));
                            
            } else {
                event.preventDefault();
                this.jobsiteZip = this.savedZipCode;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `Please resolve errors in information section to proceed with Save Cart.`,
                        variant: 'error'
                    }),
                );
            }
        } catch (exc) {
            console.log(exc.message);
        }
        
    }

    getLastDayOfMonth(year, month) {
        return new Date(year, month + 1, 0);
    }

    getFirstDayOfNextMonth(startDate) {
        const date = new Date(startDate);
        return new Date(date.getFullYear(), date.getMonth() + 1, 1);
    }

    validateCartInfo() {
        try {
            let isStartDateValid = this.template.querySelector('[data-name=start-date]').validity.valid && this.validateStartDate();
            let isStartTimeValid = this.template.querySelector('[data-name=start-time]').validity.valid;
            let isReturnDateValid = this.template.querySelector('[data-name=return-date]').validity.valid && this.validateReturnDate();
            let isReturnTimeValid = this.template.querySelector('[data-name=return-time]').validity.valid;
            let isJobsiteZipValid = this.template.querySelector('[data-name=jobsite-zip]').validity.valid && this.validateZipCode();
            let isRentalPeriodValid = this.template.querySelector('[data-name=rental-period]').validity.valid;// && !string.IsNullOrEmpty(this.template.querySelector('[data-name=rental-period]').Text) && !string.IsNullOrEmpty(this.template.querySelector('[data-name=rental-period]').SelectedIndex == -1);
            this.template.querySelector('[data-name=rental-period]').reportValidity();
            console.log('isStartTimeValid: ' + isStartTimeValid);
            console.log('isReturnTimeValid: ' + isReturnTimeValid);
            console.log('isJobsiteZipValid: ' + isJobsiteZipValid);
            console.log('isRentalPeriodValid: ' + isRentalPeriodValid);
            console.log('isStartDateValid: ' + isStartDateValid);
            console.log('isReturnDateValid: ' + isReturnDateValid);
            this.template.querySelector('[data-name=start-date]').reportValidity();
            this.template.querySelector('[data-name=start-time]').reportValidity();
            this.template.querySelector('[data-name=return-date]').reportValidity();
            this.template.querySelector('[data-name=return-time]').reportValidity();
            this.template.querySelector('[data-name=jobsite-zip]').reportValidity();
            //let areDatesValid = this.validateDates();
            return isStartDateValid && isReturnDateValid && isJobsiteZipValid && isRentalPeriodValid;
        } catch (error) {
            console.log('Error in validating: ' + JSON.stringify(error) + ' message: ' + error.message + ' name: ' + error.name + ' stack: ' + error.stack);
        }

    }

    updateReturnDates() {
        console.log("validating update return ...")
        if (this.startDate) {
            console.log("this.startDate exist ...");
            let startDate = new Date(this.startDate);
            //startDate.setDate(startDate.getDate() + 1);
            let monthPad;
            let dayPad;

            const lastDayCurrentMonth = this.getLastDayOfMonth(startDate.getFullYear(), startDate.getMonth());
            let datemin = new Date(this.minReturnDate);

            //format and pass return date in right when you reach the end of the month
            let lastDateCurrentMonth = (lastDayCurrentMonth.getMonth() + 1) + '/' + lastDayCurrentMonth.getDate() + '/' + lastDayCurrentMonth.getFullYear();
            let minDate = (startDate.getMonth() + 1) + '/' + startDate.getDate() + '/' + startDate.getFullYear();

            if (lastDateCurrentMonth === minDate) {
                let newDate = this.getFirstDayOfNextMonth(startDate);
                if ((newDate.getMonth() + 1) > 0 && (newDate.getMonth() + 1) < 10 &&
                    newDate.getDate() > 0 && newDate.getDate() < 10) {
                    monthPad = (newDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = newDate.getDate().toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                // if only date is between 1-9
                else if (newDate.getDate() > 0 && newDate.getDate() < 10) {
                    dayPad = newDate.getDate().toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${newDate.getMonth() + 1}-${dayPad}`;
                }
                // if only month is between 1-9
                else if ((newDate.getMonth() + 1) > 0 && (newDate.getMonth() + 1) < 10) {
                    monthPad = (newDate.getMonth() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${newDate.getFullYear()}-${monthPad}-${newDate.getDate()}`;
                } else {
                    this.minReturnDate = `${newDate.getFullYear()}-${newDate.getMonth() + 1}-${newDate.getDate()}`;
                }
            } else {
                if ((startDate.getMonth() + 1) > 0 && (startDate.getMonth() + 1) < 10 &&
                    startDate.getDate() > 0 && startDate.getDate() < 10) {
                    monthPad = (startDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = (startDate.getDate() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                // if only date is between 1-9
                else if (startDate.getDate() > 0 && startDate.getDate() < 10) {
                    dayPad = (startDate.getDate() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${startDate.getMonth() + 1}-${dayPad}`;
                }
                // if only month is between 1-9
                else if ((startDate.getMonth() + 1) > 0 && (startDate.getMonth() + 1) < 10) {
                    monthPad = (startDate.getMonth() + 1).toString().padStart(2, '0');
                    this.minReturnDate = `${startDate.getFullYear()}-${monthPad}-${startDate.getDate() + 1}`;
                } else {
                    this.minReturnDate = `${startDate.getFullYear()}-${startDate.getMonth() + 1}-${startDate.getDate() + 1}`;
                }
            }
            let returnDate = new Date(this.startDate.replaceAll('-', '/'));
            console.log('returnDate->' + returnDate);
            //returnDate.setDate(returnDate.getDate() + 1);
            switch (this.rentalPeriod) {
                case '1day':
                    returnDate.setDate(returnDate.getDate() + 1);
                    break;
                case '7days':
                    returnDate.setDate(returnDate.getDate() + 7);
                    break;
                case '14days':
                    returnDate.setDate(returnDate.getDate() + 14);
                    break;
                case '28days':
                    returnDate.setDate(returnDate.getDate() + 28);
                    break;
            }
            if (this.rentalPeriod != 'custom') {
                let monthPad;
                let dayPad;
                if (((returnDate.getMonth() + 1) > 0) && (returnDate.getMonth() + 1) < 10 &&
                    returnDate.getDate() > 0 && returnDate.getDate() < 10) {
                    monthPad = (returnDate.getMonth() + 1).toString().padStart(2, '0');
                    dayPad = returnDate.getDate().toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${monthPad}-${dayPad}`;
                }
                else if ((returnDate.getDate() > 0 && returnDate.getDate() < 10) &&
                    !((returnDate.getMonth() + 1) > 0 && (returnDate.getMonth() + 1) < 10)) {
                    dayPad = returnDate.getDate().toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${returnDate.getMonth() + 1}-${dayPad}`;
                }
                else if (((returnDate.getMonth() + 1) > 0 && (returnDate.getMonth() + 1) < 10)
                    && !(returnDate.getDate() > 0 && returnDate.getDate() < 10)) {
                    monthPad = (returnDate.getMonth() + 1).toString().padStart(2, '0');
                    this.returnDate = `${returnDate.getFullYear()}-${monthPad}-${returnDate.getDate()}`;
                } else {
                    this.returnDate = `${returnDate.getFullYear()}-${returnDate.getMonth() + 1}-${returnDate.getDate()}`;
                }
            }
            this.returnTime = this.startTime; //22497
            console.log('Final startDate->' + this.startDate);
            console.log('Final returnDate->' + this.returnDate);
            console.log('this.isFirstRender->' + this.isFirstRender);
            this.validateReturnDate();
        }
    }

    validateStartDate() {
        let startDate = new Date(this.startDate);
        startDate.setDate(startDate.getDate() + 1);
        let minStart = new Date(this.minStartDate);
        let today = new Date();
        today.setDate(today.getDate() + 1);
        if (!startDate || startDate <= today) {
            console.log('start date should error');
            this.isInvalidStartDate = true;
            return false;
        } else {
            this.isInvalidStartDate = false;
            return true;
        }

    }
    validateReturnDate() {
        let startDate = new Date(this.startDate);
        let returnDate = new Date(this.returnDate);

        startDate.setDate(startDate.getDate() + 1);
        returnDate.setDate(returnDate.getDate() + 1);

        let today = new Date();
        today.setDate(today.getDate() + 1);

        if (!returnDate || startDate >= returnDate) {
            this.isInvalidEndDate = true;
            return false;
        } else {
            this.isInvalidEndDate = false;
            return true;
        }
    }
    validateZipCode() {
        // for Canadian zip code validation
        const canadianZip = new RegExp(/^[ABCEGHJKLMNPRSTVXY]\d[ABCEGHJKLMNPRSTVXY][ -]?\d[ABCEGHJKLMNPRSTVXY]\d$/i);
        if (this.isJobsiteRequired) {
            if ((/(^\d{5}$)|(^\d{5}-\d{4}$)/.test(this.jobsiteZip) || canadianZip.test(this.jobsiteZip))) {
                this.zipValid = true;
            } else {
                this.zipValid = false;
            }
        } else { //CPU with no zip
            if ((/(^\d{5}$)|(^\d{5}-\d{4}$)/.test(this.jobsiteZip) || canadianZip.test(this.jobsiteZip) || this.jobsiteZip == null || this.jobsiteZip == '')) {
                this.zipValid = true;
            } else {
                this.zipValid = false;
            }
        }

        if (!this.zipValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: `Please enter a valid US or CA zip code.`,
                    variant: 'error'
                }),
            );
            return false;
        } else {
            return true;
        }
    }

    get hasRecordId() {
        return this.recordId ? true : false;
    }

    updateCustomerPricing(event) {
        //Fix update for SAL-14015 
        this._selectedCustomer = event.detail.selectedRecord ? event.detail.selectedRecord : null;
        if (!this.recordId) {
            console.log('## event fired to parent');
            this.showPricingBanner = true;
            if (JSON.stringify(this._selectedCustomer) == '{}') {
                this.pricingMessage = 'Pricing has been updated.';
            } else {
                this.pricingMessage = 'Customer Pricing Adjusted.';
            }
            let selectedCustomer = event.detail;
            const selectedCustomerEvent = new CustomEvent('customerselection', {
                detail: {
                    selectedRecord: { ...this._selectedCustomer }
                },
                bubbles: true,
                composed: true
            });
            console.log('lineitemsContainer updateCustomerPricing->' + JSON.stringify(selectedCustomerEvent.detail));
            this.dispatchEvent(selectedCustomerEvent);

        }
    }

    handleSave() {
        let cartInfo = this.getInfoObject();
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;

        fields[STARTDATE_FIELD.fieldApiName] = cartInfo.Rental_Start_Date__c;
        fields[RETURDATE_FIELD.fieldApiName] = cartInfo.Rental_End_Date__c;
        fields[ACCOUNT_FIELD.fieldApiName] = cartInfo.Account__c;
        fields[RENTALPERIOD_FIELD.fieldApiName] = cartInfo.Rental_Period__c;
        fields[CUSTOMERPICKUP_FIELD.fieldApiName] = cartInfo.Customer_Pick_Up__c;
        fields[ZIPCODE_FIELD.fieldApiName] = cartInfo.Zip_Code__c;
        fields[NOTES_FIELD.fieldApiName] = cartInfo.Notes__c;
        //22497
        fields[START_TIME_FIELD.fieldApiName] = cartInfo.Rental_Start_Time__c;
        fields[END_TIME_FIELD.fieldApiName] = cartInfo.Rental_End_Time__c;

        const recordInput = {
            fields: fields
        };

        updateRecord(recordInput).then((record) => {
            this.template.querySelector("c-sbr_3_0_line-items-cmp").setMakeCallout();
            console.log('record updated!!!' + record);
        }).catch((err) => { console.log('updateRecord issue : ', err.message); });
    }

    getInfoObject() {

        console.log('this.startdate->' + this.startDate + ' ' + this.startTime);
        console.log('this.returnDate->' + this.returnDate + ' ' + this.returnTime);
        let startDateNew = new Date(this.startDate + " " + this.startTime);
        let formatedStartDateNew = this.formatDateTimeUserTimZone(startDateNew);
        console.log('this.formatedStartDateNew->' + formatedStartDateNew);
        console.log('startDate in JSON->' + startDateNew.toJSON());
        console.log('###', JSON.stringify(this._selectedCustomer));
        let infoObject = {
            Rental_Period__c: '',
            Rental_Start_Date__c: new Date(this.startDate + " " + this.startTime).toISOString(),
            Rental_End_Date__c: new Date(this.returnDate + " " + this.returnTime).toISOString(),
            Account__c: this._selectedCustomer ? this._selectedCustomer.Id : null,
            Customer_Pick_Up__c: this.deliveryCpu,
            Zip_Code__c: this.jobsiteZip,
            Notes__c: this.notes,
            Is_Active__c: true,
            RecordTypeId: this.cartRecordTypeIdString,
            Rental_End_Time__c: this.returnTime,
            Rental_Start_Time__c: this.startTime
        };

        if (this.startTime != undefined && (!this.startTime.includes('Z') || !this.startTime.includes('z'))) {
            infoObject.Rental_Start_Time__c = this.startTime + 'Z';
            console.log('Rental_Start_Time__c->' + JSON.stringify(infoObject));
        }
        if (this.returnTime != undefined && (!this.returnTime.includes('Z') || !this.returnTime.includes('z'))) {
            infoObject.Rental_End_Time__c = this.returnTime + 'Z';
            console.log('Rental_End_Time__c->' + JSON.stringify(infoObject));
        }

        switch (this.rentalPeriod) {
            case '1day':
                infoObject.Rental_Period__c = '1 Day';
                break;
            case '7days':
                infoObject.Rental_Period__c = '7 Days';
                break;
            case '14days':
                infoObject.Rental_Period__c = '14 Days';
                break;
            case '28days':
                infoObject.Rental_Period__c = '28 Days';
                break;
            case 'custom':
                infoObject.Rental_Period__c = 'Custom';
                break;
        }
        switch (this.deliveryCpu) {
            case 'delivery':
                infoObject.Customer_Pick_Up__c = 'Delivery';
                break;
            case 'cpu':
                infoObject.Customer_Pick_Up__c = 'Pickup';
                break;
        }
        console.log('infoObject->' + JSON.stringify(infoObject));
        return infoObject;
    }

    formatDateTimeUserTimZone(newDateTime) {
        console.log('instance of newDateTime-> ' + newDateTime);
        console.log('instance of newDateTime-> ' + newDateTime instanceof Date);
        let options = {
            year: "numeric",
            month: "numeric",
            day: "numeric",
            hour: "numeric",
            minute: "numeric",
            second: "numeric",
            hour12: true,
            timeZone: this.userTimeZone
        };
        let formatedTimeZoneDate = new Intl.DateTimeFormat('en-US', options).format(newDateTime);
        console.log('instance of formatedTimeZoneDate-> ' + formatedTimeZoneDate instanceof Date);

        console.log(formatedTimeZoneDate);
        return formatedTimeZoneDate;
    }
}