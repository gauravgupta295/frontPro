import { LightningElement, api, wire, track } from 'lwc';
import * as SBRUtils from 'c/sbrUtils';
import getLineItemsColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
import getProductKitComponents from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents';
import getProductRates from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates';
import getLineItemEstimates from '@salesforce/apex/SBR_3_0_LineItemCartCmpController.getLineItemEstimates';
import deleteLineItems from '@salesforce/apex/SBR_3_0_LineItemCartCmpController.deleteLineItems';
import checkBulkFlag from '@salesforce/apex/SBR_3_0_LineItemCartCmpController.getLineItemBulkFlag';
import getProductOptionForLineItems from '@salesforce/apex/SBR_3_0_ProductDA.getProductOptionForLineItems';
import {
  getRecord,
  createRecord,
  deleteRecord,
  updateRecord,
  notifyRecordUpdateAvailable
} from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import CART_OBJECT from '@salesforce/schema/Cart__c';
import CART_ITEMS_OBJECT from '@salesforce/schema/Cart_Items__c';
import LOGGEDIN_USER_ID from '@salesforce/user/Id';
import NOTES_ICON from "@salesforce/resourceUrl/notes_icon";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from 'lightning/messageService';
import updateLineItemsChannel from '@salesforce/messageChannel/UpdateLineItemsChannel__c';
import pICartLoadedChannel from '@salesforce/messageChannel/PICartLoadedChannel__c';
import deselectProductRowChannel from '@salesforce/messageChannel/deselectProductRowChannel__c';
import updateTotalsChannel from '@salesforce/messageChannel/updateTotalsChannel__c';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { registerRefreshHandler, unregisterRefreshHandler, RefreshEvent } from 'lightning/refresh';
import Submitted_Quote_Error_Message from "@salesforce/label/c.Submitted_Quote_Error_Message";
import Submitted_Order_Error_Message from "@salesforce/label/c.Submitted_Order_Error_Message";
import { loadStyle } from 'lightning/platformResourceLoader';
import kitCustomStyleSheet from '@salesforce/resourceUrl/kitCustomStyleSheet';

import { cartItemFields, quoteLineFields, orderItemFields, quoteFields, orderFields, userFields,
  cartFields, rentalColumnNames, salesColumnNames, deliveryColumnNames, ancillaryColumnNames
 } from "c/sbr_3_0_utilities";

const DELAY = 10000;

const QUOTE_FIELDS = quoteFields;
const ORDER_FIELDS = orderFields;
const USER_FIELDS = userFields;
const CART_FIELDS = cartFields;
const EXCLUDED_RENTAL_COLUMNS_NAMES = rentalColumnNames;
const EXCLUDED_SALES_COLUMNS_NAMES = salesColumnNames;
const EXCLUDED_DELIVERY_COLUMNS_NAMES = deliveryColumnNames;
const EXCLUDED_ANCILLARY_COLUMNS_NAMES = ancillaryColumnNames;

const quoteLineActions = [
  { label: 'Product Details', name: 'view_line_item' }
];

const orderLineActions = [
  { label: 'Product Details', name: 'view_line_item' }
];
//CustomLabel approach not working since it is passed in Wired call
const PAGESIZE_ORDERITEM_RELATEDLIST = 1000;
var userId;
import uId from '@salesforce/user/Id';
export default class Sbr_3_0_lineItemsCmp extends NavigationMixin(
  LightningElement
) {
  // SAL-26606
  notesIcon = NOTES_ICON;
  // SAL-26337
  @track gridName = 'rental';
  @track isExpanded = false;
  userId = uId;
  @track orderDiscount;
  itemsToRemove;
  @track headerText = 'Line Editor';
  @track itemToRemove;
  accName;
  isAccountRemoved = false;
  isAccountAdded = false;
  showRentalGrid = true;
  showSalesGrid = true;
  showDeliveryGrid = true;
  showAncillaryGrid = true;
  hideFooterForEdit = false;
  delayTimeout;
  showCartInfo = false;
  savedRentalPeriod = '';
  savedStartDate;
  savedReturnDate;
  savedStartTime = '12:00:00.000';
  savedReturnTime = '12:00:00.000';
  savedDeliveryCpu = '';
  savedZipCode;
  savedNotes = '';
  savedCustomer;
  clearCartAction = false;
  requiredOptions=[];
  @api tempCustomer;
  @api
  get startDate() {
    return this._startDate;
  }
  set startDate(value) {
    this._startDate = value;
    if (this.columns.length > 0) {
      let subtotalCol = this.columns.find(
        (e) => e.fieldName == 'Item_Subtotal'
      );
      subtotalCol.label = `Item Subtotal (${value} to ${this._returnDate})`;
    }
    this.columns = [...this.columns];
  }
  @api
  get rentalPeriod() {
    return this._rentalPeriod;
  }
  set rentalPeriod(value) {
    this._rentalPeriod = value;
  }
  @api
  get startTime() {
    return this._startTime;
  }
  set startTime(value) {
    this._startTime = value;
  }
  @api
  get returnDate() {
    return this._returnDate;
  }
  set returnDate(value) {
    this._returnDate = value;
    if (this.columns.length > 0) {
      let subtotalCol = this.columns.find(
        (e) => e.fieldName == 'Item_Subtotal'
      );
      subtotalCol.label = `Item Subtotal (${this._startDate} to ${value})`;
    }
    this.columns = [...this.columns];
  }
  get isPI() {
    return !this.objectApiName;
  }
  @api
  get returnTime() {
    return this._returnTime;
  }
  set returnTime(value) {
    this._returnTime = value;
  }

  @api
  get deliveryCpu() {
    return this._deliveryCpu;
  }
  set deliveryCpu(value) {
    this._deliveryCpu = value;
  }

  @api
  get jobsiteZip() {
    return this._jobsiteZip;
  }
  set jobsiteZip(value) {
    this._jobsiteZip = value;
  }

  @api
  get customerInfo() {
    return this._customerInfo;
  }
  set customerInfo(value) {
    if (value) {
      this._customerInfo = value;
      this.checkForCSP();
    }
  }

  checkForCSP() {
    let selectedCustomer =
      this._customerInfo && this._customerInfo.RM_Account_Number__c
        ? this._customerInfo.RM_Account_Number__c
        : '';
    let products = [];
    let branch;
    this.lineItems.forEach((item) => {
      if (item.itemType === 'rental' || item.itemType === 'base' || item.Item_Type === 'rental' || item.Item_Type === 'base') {
        branch = item?.rateBranch ? item.rateBranch : (item?.Rate_Branch ? item.Rate_Branch : '');
        products.push({ productId: item.CatClass, pc: branch });
      }
    });
    if (products && products.length > 0 && (this.objectApiName == 'Cart__c' || !this.objectApiName)) {
      getProductRates({
        prwrapper: {
          products: products,
          customerNumber: selectedCustomer
        }
      })
        .then((result) => {
          let items = JSON.parse(result).data.items;
          items.forEach((rateItem, index) => {
            let foundIndex = this.lineItems.findIndex(item => item?.catClass == rateItem?.productId);
            if (foundIndex != -1) {
              this.lineItems[foundIndex].Daily_Rate =
                rateItem.rates.suggestedRates.daily;
              this.lineItems[foundIndex].Weekly_Rate =
                rateItem.rates.suggestedRates.weekly;
              this.lineItems[foundIndex].Monthly_Rate =
                rateItem.rates.suggestedRates.monthly;
              this.lineItems[foundIndex].Rate_Branch = rateItem.pc;
            }
          });
          this.updateLineItemsTable();
          let title = 'Customer Pricing Adjusted';
          let titleWhenAccountRemoved = 'Pricing has been updated';
          if (selectedCustomer == null || selectedCustomer == '') {
            this.isAccountRemoved = true;
          } else {
            this.isAccountAdded = true;
          }
          this.verifyCSP(items);
          this.updateLineItemsTable();
        })
        .catch((error) => {
          console.log('Error getting product rates' + error.message);
        });
    }
  }

  @api recordId;
  @api objectApiName;
  @api cartRecordTypeId;
  @track makeCallout = true;
  @track intialLineLength;
  @track userCompanyCode;
  @track isParentRecordLoaded = false;
  @track parentRecord;
  @track currentUserRecord;
  @track isCurrentUserRecordLoaded = false;
  @track updateTotalsRecordId = '';
  @track listInfoRecordId = '';
  @track disableEdit = false;
  isMobile = false;
  isLoading = false;
  _rentalPeriod;
  _startDate;
  _startTime;
  _returnDate;
  _returnTime;
  _deliveryCpu;
  _jobsiteZip;
  _customerInfo = '';
  _lineItemsCatClassMap = [];
  _disableRemoveItem = true;
  @track lineItems = []; //All Line Items
  @track displayedLineItems = [];
  @track rentalLineItems = [];
  @track salesLineItems = [];
  @track deliveryLineItems = [];
  @track ancillaryLineItems = [];
  activeSections = [
    'Rental Items',
    'Sales/Misc Items',
    'Delivery Items',
    'Ancillary Items'
  ];
  activeSectionsMobile = [];
  subscription = null;
  updateTotalsSubscription = null;
  @track columns = [];
  @track rentalColumns = [];
  @track salesColumns = [];
  @track deliveryColumns = [];
  @track ancillaryColumns = [];
  recordTypeName = '';
  @track draftValues = [];
  @api draftErrors;
  @track noItemsMsg = 'No items in the cart.';
  showLineItemsTable = false;
  loadingItems = true;
  relatedListId = '';
  fields = [];
  lineId = '';
  selectedItemGroup = '';
  removeNotChecked = true;
  subtotal = 0;
  charges = 0;
  tax = 0;
  total = 0;
  showDNEBanner = false;
  showSetRatesBanner = false;
  showPricingUpdatedBanner = false;
  showPercentBanner = false;
  showSpecialRateBanner = false;
  taxAndCharges;
  itemListDisplay = true;
  lineItemEditorDisplay = false;
  showSpinner = false;
  parentRecordOwnerId;
  parentId;
  quoteRecordTypeName = '';
  listInfoResults;
  hasColumnsLoaded = false;
  hasAddOns = false;
  orderItemGrouping = [];
  kitItems = [];
  @track bulkEditRows = [];
  isSales = false;
  CSP;
  CSP_msg;
  showSalesMiscError;
  refreshHandlerID;

  // test
  estimateRequest = {
    account: 1,
    orderType: 'Pickup',
    ratesToBeUsed: 'SUGGESTED',
    startDateAndTime: '',
    endDateAndTime: '',
    pc: [
      {
        id: 0,
        latitude: 0.0,
        longitude: 0.0,
        timezone: ''
      }
    ],
    address: [
      {
        type: 'jobsite',
        line1: '',
        city: '',
        state: '',
        zip: '',
        latitude: 0.0,
        longitude: 0.0
      }
    ],
    delivery: [
      {
        chargesOverride: false,
        charges: '0.00'
      }
    ],
    pickup: [
      {
        chargesOverride: false,
        charges: '0.00'
      }
    ],
    orderLines: [
      {
        salesItems: [],
        products: []
      }
    ]
  };
  @api setMakeCallout() {
    this.makeCallout = true;
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$parentFields' })
  wiredRecord({ error, data }) {
    if (data) {
      let USDollar = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      });
      if (this.objectApiName == 'Cart__c') {
        this.total = (USDollar.format((data?.fields?.Total__c?.value) ? data.fields.Total__c.value : '0'));
        this.subtotal = ((USDollar.format((data?.fields?.Sub_Total__c?.value) ? data.fields.Sub_Total__c.value : '0')));
        this.tax = ((USDollar.format((data?.fields?.Tax__c?.value) ? data.fields.Tax__c.value : '0')));
        this.charges = (USDollar.format((data?.fields?.Total_Delivery_Pickup__c?.value) ? data.fields.Total_Delivery_Pickup__c.value : '0'));
      }
      this.parentRecord = data;
      this.isParentRecordLoaded = true;
      this.parentRecordOwnerId = data.fields.OwnerId.value;
      this.orderDiscount =
        data.fields.Order_Discount__c != null
          ? data.fields.Order_Discount__c.value
          : 0;
      this.recordTypeName = data?.recordTypeInfo?.name;
      // SAL-23568
      refreshApex(this.listInfoResults);
    } else {
      console.log('Error fetching record data' + JSON.stringify(error));
    }
  }

  @wire(getRecord, { recordId: LOGGEDIN_USER_ID, fields: USER_FIELDS })
  currentUserRecord({ error, data }) {
    if (data) {
      this.currentUserRecord = data;
      this.isCurrentUserRecordLoaded = true;
      this.userCompanyCode = data.fields.CompanyName.value;
    } else {
      console.log('Error getting current user record ' + JSON.stringify(error));
    }
  }

  @wire(getRecord, {
    recordId: '$updateTotalsRecordId',
    fields: '$parentFields'
  })
  updatedTotalsRecord({ error, data }) {
    this.quoteRecordTypeName = data?.recordTypeInfo?.name;
    if (data) {
      if (
        this.objectApiName === 'SBQQ__Quote__c' ||
        this.objectApiName === 'Order'
      ) {
        let totalRentalAmount =
          data.fields.Total_Rental_Amount__c.value != null
            ? data.fields.Total_Rental_Amount__c.value
            : 0,
          totalSalesAmount =
            data.fields.Total_Sales_Amount__c.value != null
              ? data.fields.Total_Sales_Amount__c.value
              : 0,
          rppAmount =
            data.fields.RPP_Amount__c.value != null
              ? data.fields.RPP_Amount__c.value
              : 0,
          totalMisc =
            data.fields.Total_Misc__c.value != null
              ? data.fields.Total_Misc__c.value
              : 0,
          totalSalesTax = data.fields.Total_Sales_Taxes__c.value
            ? data.fields.Total_Sales_Taxes__c.value
            : 0;

        this.subtotal = this.formatNumber(totalRentalAmount + totalSalesAmount);

        this.charges = this.formatNumber(rppAmount + totalMisc);
        this.tax = this.formatNumber(totalSalesTax);
        this.taxAndCharges = this.formatNumber(totalSalesTax + rppAmount + totalMisc);
        if (this.objectApiName === 'SBQQ__Quote__c') {
          this.total = this.formatNumber(
            data.fields.Total_Quoted_Amount__c.value != null
              ? data.fields.Total_Quoted_Amount__c.value
              : 0
          );
          if (this.quoteRecordTypeName == 'Rental Quote - Submitted') {
            this.disableEdit = true;
          } else {
            this.disableEdit = false;
          }
        } else
          this.total = this.formatNumber(
            totalRentalAmount +
            totalSalesAmount +
            rppAmount +
            totalMisc +
            totalSalesTax
          );
      }
    } else {
      console.log('Error updating totals ');
    }
  }

  @wire(MessageContext)
  messageContext;
  //method to load columns for the line items datatable
  @wire(getLineItemsColumns)
  lineItemsColumns({ error, data }) {
    if (data) {
      let lineItemsCols;
      var userId = LOGGEDIN_USER_ID;
      if (this.objectApiName === 'Cart__c' || this.objectApiName == undefined) {
        lineItemsCols = data.filter((col) => col.Context__c == 'Line Item');
      } else if (
        this.objectApiName === 'SBQQ__Quote__c' ||
        this.objectApiName === 'Order'
      ) {
        lineItemsCols = data.filter(
          (col) => col.Context__c == 'Quote Line Item'
        );
      }
      lineItemsCols.sort((a, b) => a.Order__c - b.Order__c);
      this.columns.unshift({
        "label": "",
        "fieldName": "iconColumn",
        "hideDefaultActions": true,
        "sortable": false,
        "editable": false,
        "type": "button-icon",
        "wrapText": true,
        "fixedWidth": 40,
        "typeAttributes": {
          "label": {
            "fieldName": "iconColumn"
          },
          "fieldName": "iconColumn",
          "name": "Kit",
          "target": "_blank",
          "variant": "bare",
          "iconName": {
            "fieldName": "displayIconName"
          },
          "cellAttributes": {
            "class": {
              "fieldName": "displayCssClass"
            }
          }
        }
      });
      lineItemsCols.forEach((col) => {
        let colItem = {};
        colItem.label = col.Label;
        colItem.fieldName = col.Field_Name__c;
        colItem.hideDefaultActions = true;
        colItem.sortable = col.IsSortable__c;
        if (
          this.objectApiName === 'SBQQ__Quote__c' ||
          this.objectApiName === 'Order'
        ) {
          colItem.editable =
            userId == this.parentRecordOwnerId && col.IsEditable__c
              ? true
              : false;
        } else {
          colItem.editable = col.IsEditable__c;
        }

        if (col.Type__c === undefined) {
          if (
            col.Field_Name__c == 'Daily_Rate' ||
            col.Field_Name__c == 'Weekly_Rate' ||
            col.Field_Name__c == 'Monthly_Rate' ||
            col.Field_Name__c == 'Sale_Price' ||
            col.Field_Name__c == 'Item_Subtotal' ||
            col.Field_Name__c == 'Suggested_Daily_Rate' ||
            col.Field_Name__c == 'Suggested_Weekly_Rate' ||
            col.Field_Name__c == 'Suggested_Monthly_Rate'
          ) {
            colItem.type = 'currency';
            colItem.cellAttributes = { alignment: 'left' };
            if (col.Field_Name__c == 'Sale_Price') {
              colItem.typeAttributes = { maximumFractionDigits: 3, minimumFractionDigits: 3 };
            }
          } else {
            colItem.type = 'text';
          }
        } else {
          colItem.type = col.Type__c;
        }
        if (colItem.fieldName == 'Delete_Item') {
          colItem.typeAttributes = {
            iconName: 'utility:delete',
            name: 'delete',
            disabled: { fieldName: 'forcedItem' } // SF-5303
          };
          colItem.hideLabel = true;
          colItem.label = '';
        }
        if (col.fixedWidth__c) { colItem.fixedWidth = col.fixedWidth__c; }
        this.columns.push(colItem);
        //11909
        if (colItem.fieldName === 'Notes') {
          colItem.type = 'image';
        }
        if (colItem.fieldName === 'Quantity') {
          colItem.cellAttributes = { alignment: 'left' };
          // SF-5303
          if (this.objectApiName === 'Cart__c' || this.objectApiName == undefined) {
            colItem.editable = { fieldName: 'quantityEditable' };
          }
        }
        if (
          (this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Order' || this.objectApiName == undefined) &&
          colItem.fieldName === 'Name'
        ) {
          colItem.wrapText = true;
          colItem.typeAttributes = {
            label: { fieldName: 'Name' },
            fieldName: 'Name',
            name: 'edit_quote_line',
            target: '_blank',
            variant: 'base'
          };
          colItem.cellAttributes = {
            "class": {
              "fieldName": "titleStyleClass"
            }
          }
        }

        // Display Shade Background Color for Child Kit Components
        if (this.objectApiName === 'SBQQ__Quote__c' || this.objectApiName === 'Order' || this.objectApiName === 'Cart__c') {
          if(!(colItem.cellAttributes && colItem.cellAttributes['class'] && colItem.cellAttributes['class']['fieldName'])) {
            colItem.cellAttributes = { ... colItem.cellAttributes, 
              "class": {
                "fieldName": "shadeBackground"
              }
            }
          }
        }

        //11909
        if (this.objectApiName === 'Order' && colItem.fieldName === 'Name') {
          colItem.wrapText = true;
          colItem.typeAttributes = {
            label: { fieldName: 'Name' },
            fieldName: 'Name',
            name: 'edit_order_line',
            target: '_blank',
            variant: 'base'
          };
        }
      });

      if (this.objectApiName === 'SBQQ__Quote__c') {
        this.columns.push({
          type: 'action',
          typeAttributes: {
            rowActions: quoteLineActions,
            menuAlignment: 'right'
          }
        });
      } else if (this.objectApiName === 'Order') {
        this.columns.push({
          type: 'action',
          typeAttributes: {
            rowActions: orderLineActions,
            menuAlignment: 'right'
          }
        });
      }

      // parsing columns

      this.rentalColumns = this.columns.filter(
        (col) => !EXCLUDED_RENTAL_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.salesColumns = this.columns.filter(
        (col) => !EXCLUDED_SALES_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.deliveryColumns = this.columns.filter(
        (col) => !EXCLUDED_DELIVERY_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.ancillaryColumns = this.columns.filter(
        (col) => !EXCLUDED_ANCILLARY_COLUMNS_NAMES.includes(col.fieldName)
      );

      this.updateLineItemsTable();
    } else if (error) {
      console.log('Error in fetching line item column data ' + JSON.stringify(error));
    }
  }

  clearCartBtnStyle = 'slds-button slds-button_outline-brand';
  get disableClearCart() {
    if (this.lineItems?.length > 0) {
      this.clearCartBtnStyle = 'slds-button slds-button_outline-brand';
      return false;
    }
    this.clearCartBtnStyle = 'disableBtnStyle';
    return true;
  }
  get parentFields() {
    switch (this.objectApiName) {
      case 'SBQQ__Quote__c':
        return QUOTE_FIELDS;
      case 'Order':
        return ORDER_FIELDS;
      case 'Cart__c':
        return CART_FIELDS;
    }
  }

  //method to load child line item records when component is loaded in record context
  @wire(getRelatedListRecords, {
    parentRecordId: '$listInfoRecordId',
    relatedListId: '$relatedListId',
    fields: '$fields',
    pageSize: PAGESIZE_ORDERITEM_RELATEDLIST
  })
  listInfo(result) {
    this.showSpinner = false;
    this.listInfoResults = result;
    let data = result.data,
      error = result.error;
    try {
      if (data) {
        this.lineItems = [];
        let tempLineItems = [];
        switch (this.objectApiName) {
          case 'Cart__c':
            data.records.forEach((record) => {
              let catclassStr = this.generateCatClass(record);
              this.lineItems.push({
                Changeable: record.fields.Product__r?.value.fields.Changeable__c.value, // SF-7666
                SalesforceManagedKit: record.fields.Product__r?.value.fields.Salesforce_Managed_Kit__c.value, // SF-7666
                // SAL-26036
                lineItemType: record.fields.Line_Item_Type__c.value,
                UserSelectableForQuote: record.fields.Product__r?.value.fields?.User_Selectable_for_Quote__c.value,
                Id: record.fields.Id.value,
                Name: record.fields.Name.value,
                CatClass: record.fields.Cat_Class__c.value,
                Cat_Class: catclassStr,
                Quantity: record.fields.Quantity__c.value,
                Min_Rate: record.fields.Minimum_Price__c.value,
                Daily_Rate: record.fields.Daily_Price__c.value,
                Weekly_Rate: record.fields.Weekly_Price__c.value,
                Monthly_Rate: record.fields.Monthly_Price__c.value,
                Sale_Price: record.fields.Misc_Sales_Price__c.value,
                Item_Subtotal: record.fields.Item_Subtotal__c.value,
                Rate_Branch: record.fields.Rates_Branch__c.value,
                productType:
                  record.fields.Product__r.value.fields.Product_Type__c.value,
                // SAL-25639 (1 fields below)
                miscChargesType:
                  record.fields.Product__r?.value.fields
                    ?.Type_of_Misc_Charge_Item__c.value,
                itemNumber:
                  record.fields.Product__r.value.fields.Item_Number__c.value,
                stockClass:
                  record.fields.Product__r.value.fields.Stock_class__c.value,
                _isChecked: false,
                kitItemsAmount: 0,
                showKitItem: false,
                hasKitItems: false,
                product: record.fields.Product__r.value.id,
                isUserAdded: record.fields.is_User_Added__c.value, //25998
                hasKit:
                  record.fields.Product__r.value.fields.Is_Kit__c.value == 'Yes'
                    ? true
                    : false,
                Kit_Number_this_Item_Belongs_to: record.fields.Kit_Number_This_Item_Belongs_To__c.value,
                hasFuelPlan: record.fields.Fuel_Plan__c.value,//SF-5291,SF-5292
                kitItems: {
                  kitItemsValue: [],
                  packageName: record.fields.Product__r.displayValue,
                  isKit: record.fields.Product__r.value.fields.Is_Kit__c.value,
                  productId: record.fields.Product__c.value
                }, // changed for SAL-13913,
                forcedItem: record.fields.is_Forced_Item__c.value,// SF-5303
                disableMobileRemoveItem: record.fields.is_Forced_Item__c.value, // SF-5303
                miscellaneousChargeItem : record.fields.Product__r.value.fields.Miscellaneous_Charge_Item__c.value
              });
            });
            break;
          case 'SBQQ__Quote__c':
            data.records.forEach((record) => {
              let catclassStr = this.generateCatClass(record);
              this.lineItems.push({
                // SAL-26036
                UserSelectableForQuote: record.fields.SBQQ__Product__r?.value.fields?.User_Selectable_for_Quote__c.value,
                Id: record.fields.Id.value,
                Name: record.fields.SBQQ__ProductName__c.value,
                Notes: (this.isMobile ? record.fields.Line_Comments__c.value : (record.fields.Line_Comments__c.value ? this.notesIcon + '/notes_icon/notes.svg' : '')), //11909
                CatClass: record.fields.Product_SKU__c.value,
                Cat_Class: catclassStr,
                Quantity: record.fields.SBQQ__Quantity__c.value,
                Min_Rate: record.fields.Min_Rate__c.value,
                Daily_Rate: record.fields.Daily_Rate2__c.value,
                Weekly_Rate: record.fields.Weekly_Rate2__c.value,
                Monthly_Rate: record.fields.Monthly_Rate2__c.value,
                Rate_Branch: record.fields.Rates_Branch__c.value,
                Sale_Price: record.fields.Selling_Price__c.value,
                Item_Subtotal: record.fields.Total_Price__c.value,
                Specific_Pricing_Type:
                  record.fields.Specific_Pricing_Type__c.value,
                Suggested_Daily_Rate: record.fields.Suggested_Daily_Rate__c.value,
                Suggested_Weekly_Rate:
                  record.fields.Suggested_Weekly_Rate__c.value,
                Suggested_Monthly_Rate:
                  record.fields.Suggested_Monthly_Rate__c.value,
                // SAL-25639 (1 fields below)
                //miscChargesType: record.fields.SBQQ__Product__r?.value.fields?.Type_of_Misc_Charge_Item__c.value,
                miscChargesType: record.fields.Misc_Charges_Type__c.value,
                productCategory: record.fields.SBQQ__Product__r?.value.fields?.Category__c.value,
                productClass: record.fields.SBQQ__Product__r?.value.fields?.Class__c.value,
                productType:
                  record.fields.SBQQ__Product__r?.value.fields?.Product_Type__c
                    .value,
                userSelect:
                  record.fields.SBQQ__Product__r?.value.fields?.User_Select__c
                    .value,
                isUserAdded: record.fields.is_User_Added__c.value, //25998
                lineItemType:
                  record.fields.Line_Item_Type__c.value != null
                    ? record.fields.Line_Item_Type__c.value
                    : '', //25998
                stockClass:
                  record.fields.SBQQ__Product__r?.value.fields?.Stock_class__c
                    .value,
                _isChecked: false,
                hasNotes:
                  record.fields.Line_Comments__c.value?.length > 0 ? true : false,
                showNoteItem: false,
                // DS changes
                kitItemsAmount: 0,
                showKitItem: false,
                hasKitItems: false,
                hasKit:
                  record.fields.SBQQ__Product__r?.value.fields.Is_Kit__c.value ==
                    'Yes'
                    ? true
                    : false,
                Kit_Number_this_Item_Belongs_to: record.fields.Kit_Number_this_Item_Belongs_to__c.value,
                hasFuelPlan: record.fields.Fuel_Plan__c.value,//SF-5291,SF-5292
                Changeable: record.fields.SBQQ__Product__r?.value.fields.Changeable__c.value,
                SalesforceManagedKit: record.fields.SBQQ__Product__r?.value.fields.Salesforce_Managed_Kit__c.value, // SAL-27182
                product: record.fields.SBQQ__Product__c.value,
                AddedByCrewExpense: record.fields.Added_by_Crew_Expense__c.value, //25936
                kitItems: {
                  kitItemsValue: [],
                  packageName: record.fields?.SBQQ__Product__r?.displayValue,
                  isKit:
                    record.fields?.SBQQ__Product__r?.value?.fields?.Is_Kit__c
                      ?.value,
                  productId: record?.fields?.SBQQ__Product__c?.value
                },
                forcedItem: record.fields.is_Forced_Item__c.value, // SF-5303
                disableMobileRemoveItem: record.fields.is_Forced_Item__c.value,
                miscellaneousChargeItem : record.fields.SBQQ__Product__r.value.fields.Miscellaneous_Charge_Item__c.value // SF-5303
              });
            });

            break;
          case 'Order':
            data.records.forEach((record) => {

              let itemExists = false;
              let isItemHidden = false;

              let catclassStr = this.generateCatClass(record);

              if (
                record.fields.is_Line_Item_Hidden__c != null &&
                record.fields.is_Line_Item_Hidden__c.value === true
              ) {
                isItemHidden = true;
              }

              this.lineItems.forEach((obj) => {
                if (
                  obj._groupId &&
                  obj._groupId === record.fields.groupID__c.value
                ) {
                  this.orderItemGrouping.map((grouping) => {
                    if (grouping.groupId === record.fields.groupID__c.value) {
                      grouping.recordIds.push(record.fields.Id.value);
                    }
                  });
                  obj.Quantity += 1;
                  obj.Item_Subtotal += record.fields.Total_Price__c.value; // SAL-14399
                  itemExists = true;
                }
              });
              if (!itemExists && !isItemHidden) {
                this.lineItems.push({
                  // SAL-26036
                  UserSelectableForQuote: record.fields.Product2?.value.fields?.User_Selectable_for_Quote__c.value,
                  Id: record.fields.Id.value,
                  Name: record.fields.Product2.value.fields.Name.value,
                  Notes: (this.isMobile ? record.fields.Line_Comments__c.value : (record.fields.Line_Comments__c.value ? this.notesIcon + '/notes_icon/notes.svg' : '')), //11909
                  CatClass: record.fields.Product_SKU__c.value,
                  Cat_Class: catclassStr,
                  Quantity: record.fields.Quantity.value,
                  Min_Rate: record.fields.Min_Rate__c.value,
                  Daily_Rate: record.fields.Daily_Rate2__c.value,
                  Weekly_Rate: record.fields.Weekly_Rate2__c.value,
                  Monthly_Rate: record.fields.Monthly_Rate2__c.value,
                  Rate_Branch: record.fields.Rates_Branch__c.value,
                  Sale_Price: record.fields.Selling_Price__c.value,
                  Item_Subtotal: record.fields.Total_Price__c.value,
                  Specific_Pricing_Type:
                    record.fields.Specific_Pricing_Type__c.value,
                  Suggested_Daily_Rate:
                    record.fields.Suggested_Daily_Rate__c.value,
                  Suggested_Weekly_Rate:
                    record.fields.Suggested_Weekly_Rate__c.value,
                  Suggested_Monthly_Rate:
                    record.fields.Suggested_Monthly_Rate__c.value,
                  productType:
                    record.fields.Product2?.value.fields?.Product_Type__c.value,
                  // SAL-25639 (1 fields below)
                  miscChargesType: record.fields.Misc_Charges_Type__c.value,
                  productCategory: record.fields.Product2?.value.fields?.Category__c.value,
                  productClass: record.fields.Product2?.value.fields?.Class__c.value,
                  userSelect:
                    record.fields.Product2?.value.fields?.User_Select__c.value,
                  isUserAdded: record.fields.is_User_Added__c.value, //25998
                  lineItemType:
                    record.fields.Line_Item_Type__c.value != null
                      ? record.fields.Line_Item_Type__c.value
                      : '', //25998
                  stockClass:
                    record.fields.Product2?.value.fields?.Stock_class__c.value,
                  _groupId: record.fields.groupID__c.value,
                  _isChecked: false,
                  hasNotes:
                    record.fields.Line_Comments__c.value?.length > 0
                      ? true
                      : false,
                  showNoteItem: false,
                  // DS changes
                  kitItemsAmount: 0,
                  showKitItem: false,
                  hasKitItems: false,
                  hasKit:
                    record.fields.Product2?.value.fields.Is_Kit__c.value == 'Yes'
                      ? true
                      : false,
                  Kit_Number_this_Item_Belongs_to: record.fields.Kit_Number_This_Item_Belongs_To__c.value,
                  hasFuelPlan: record.fields.Fuel_Plan__c.value,//SF-5291,SF-5292
                  Changeable: record.fields.Product2?.value.fields.Changeable__c.value,
                  SalesforceManagedKit: record.fields.Product2?.value.fields.Salesforce_Managed_Kit__c.value, // SAL-27182
                  // DS changes
                  product: record.fields.Product2Id.value,
                  kitItems: {
                    kitItemsValue: [],
                    packageName: record.fields.Product2.displayValue,
                    isKit: record.fields.Product2.value.fields.Is_Kit__c.value,
                    productId: record.fields.Product2Id.value
                  },
                  forcedItem: record.fields.is_Forced_Item__c.value, // SF-5303
                  disableMobileRemoveItem: record.fields.is_Forced_Item__c.value,
                  miscellaneousChargeItem : record.fields.Product2.value.fields.Miscellaneous_Charge_Item__c.value // SF-5303 // SF-5303
                });
                this.orderItemGrouping.push({
                  groupId: record.fields.groupID__c.value,
                  recordIds: [record.fields.Id.value]
                });
              }
            });

            break;
        }
        this.updateLineItemsTable();
      } else if (error) {
        console.log('Error in fetching related list records ' + JSON.stringify(error));
      }
    }
    catch (error) {
      console.log('Printing catch block error from wire method to fetch related list records' + JSON.stringify(error));
    }
  }

  generateCatClass(record) {
    switch (this.objectApiName) {
      case 'Cart__c':
        const cartCategory = record.fields.Product__r?.value.fields?.Category__c.value;
        const cartProductClass = record.fields.Product__r?.value.fields?.Class__c.value;
        return cartCategory && cartProductClass ? `${cartCategory}-${cartProductClass}` : 'N/A';
        break;
      case 'Order':
        const orderCategory = record.fields.Product2?.value.fields?.Category__c.value;
        const orderProductClass = record.fields.Product2?.value.fields?.Class__c.value;
        return orderCategory && orderProductClass ? `${orderCategory}-${orderProductClass}` : 'N/A';
        break;
      case 'SBQQ__Quote__c':
        const quoteCategory = record.fields.SBQQ__Product__r?.value.fields?.Category__c.value;
        const quoteProductClass = record.fields.SBQQ__Product__r?.value.fields?.Class__c.value;
        return quoteCategory && quoteProductClass ? `${quoteCategory}-${quoteProductClass}` : 'N/A';
        break;
      default:
        const defaultCategory = record.fields.Product2?.value.fields?.Category__c.value;
        const defaultProductClass = record.fields.Product2?.value.fields?.Class__c.value;
        return defaultCategory && defaultProductClass ? `${defaultCategory}-${defaultProductClass}` : 'N/A';
        break;
    }
  }

  connectedCallback() {
    Promise.all([
      loadStyle(this, kitCustomStyleSheet)
    ]);
    //this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    if (FORM_FACTOR === 'Small') {
      this.isMobile = true;
    }
    this.subscribeToMessageChannel();
    if (this.recordId) {
      refreshApex(this.listInfoResults);
      this.initRecordContextVariables();
      //SAL-26056, SADAPUR
      this.refreshHandlerID = registerRefreshHandler(this, this.refreshHandler);
    } else {
      const payload = {
        recordId: null
      };
      publish(this.messageContext, pICartLoadedChannel, payload);
    }
    this.updateTotalsRecordId = this.recordId ? this.recordId.valueOf() : '';
    this.listInfoRecordId = this.recordId ? this.recordId.valueOf() : '';
  }
  disconnectedCallback() {
    unregisterRefreshHandler(this.refreshHandlerID);
    this.unsubscribeToMessageChannel();
  }
  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        updateLineItemsChannel,
        (item) => this.addLineItem(item),
        { scope: APPLICATION_SCOPE }
      );
    }
    if (!this.updateTotalsSubscription) {
      this.updateTotalsSubscription = subscribe(
        this.messageContext,
        updateTotalsChannel,
        (item) => this.updateTotalsHandler(item),
        { scope: APPLICATION_SCOPE }
      );
    }
  }
  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
    unsubscribe(this.updateTotalsSubscription);
    this.updateTotalsSubscription = null;
  }
  initRecordContextVariables() {
    if (this.recordId) {
      switch (this.objectApiName) {
        case 'Cart__c':
          this.noItemsMsg = 'No items in the cart.';
          this.relatedListId = 'Cart_Items__r';
          this.fields = cartItemFields;
          break;
        case 'SBQQ__Quote__c':
          this.noItemsMsg =
            'There are no Line Items in this Quote. Use Item Search to add items.';
          this.relatedListId = 'SBQQ__LineItems__r';
          this.fields = quoteLineFields;
          break;
        case 'Order':
          this.noItemsMsg =
            'There are no Line Items in this Order. Use Item Search to add items.';
          this.relatedListId = 'OrderItems';
          this.fields = orderItemFields;
          break;
      }
    }
  }
  updateTotalsHandler(data) {
    if (data.recordId == this.recordId) {
      this.updateTotalsRecordId = '';
      this.updateTotalsRecordId = data.recordId;
    }
  }
  @track selRowForKit;
  @track IdToExpandedMap = {};
  isParentPresent(record) {
    let isCatClassPresent = this.lineItems.some((item) =>
      item.hasKit === true && item.CatClass === record.Kit_Number_this_Item_Belongs_to
    );
    return isCatClassPresent;
  }
  updateLineItemGridData(data) {
    if (data && data.detail) {
      data = data.detail;
      data = JSON.parse(JSON.stringify(data));
      this.lineItems = JSON.parse(JSON.stringify(data));
    }
      this.displayedLineItems = [];
      this.rentalLineItems = [];
      this.salesLineItems = [];
      this.deliveryLineItems = [];
      this.ancillaryLineItems = [];
    let catClassId = this.selRowForKit != undefined ? this.selRowForKit.CatClass : '';
    let isExpanded = this.IdToExpandedMap.hasOwnProperty(this.selRowForKit?.Id) ? this.IdToExpandedMap[this.selRowForKit?.Id] : false;

    if (this.objectApiName == undefined) {
       //for PI
       this.lineItems = this.getUniqueProducts();
       let kitChildren = [];
       this.lineItems.forEach((item) => {
        item.quantityEditable = (item.hasKit || item.SalesforceManagedKit) ? true : false; // SF-7540
        if(item.hasKit === true 
           && !item.SalesforceManagedKit
           ) { //&& !item.changeable
          let itemKitChildren = this.lineItems.filter((iter) => {
            return iter.kitNumberBelongsTo === item.CatClass;
          }) 
          kitChildren = [...kitChildren, ...itemKitChildren ];
        }
      });
      let idsToRemove = kitChildren.map(obj => obj.Id);
      this.displayedLineItems = this.lineItems.filter(obj => !idsToRemove.includes(obj.Id));
    } else {
        data.forEach((record) => {
          //SF-5303  & SF-5850 
          let matchedOption = this.requiredOptions.find(option => option?.SBQQ__OptionalSKU__c === record?.product && option?.SBQQ__ConfiguredSKU__r?.Product_SKU__c === record?.Kit_Number_this_Item_Belongs_to);
          record.quantityEditable = (matchedOption && matchedOption?.SBQQ__Feature__r?.Name === 'Rental Addons') ? false : (record.Kit_Number_this_Item_Belongs_to != undefined && this.isParentPresent(record)) ? false : true;
          // SAL-26036, SF-5035
          if (record.lineItemType == 'VR' ||
            record.lineItemType == 'RI') {
            record.displayCssClass = 'linkClass';
            if (record.lineItemType == 'VR' && record.hasKit && !record.SalesforceManagedKit) { // SAL-27182
              record.displayIconName = (!record.Changeable) ? (isExpanded && (this.selRowForKit?.Id == record.Id) ? 'utility:chevrondown' : 'utility:chevronright') : '';
              record.displayCssClass = '';
              record.expandKit = isExpanded;
            }
            // for all non kits
            if ((record.Kit_Number_this_Item_Belongs_to == undefined || record.Kit_Number_this_Item_Belongs_to == null)) {
              this.rentalLineItems.push(record);
            }
            //for managed
            else if (record.Kit_Number_this_Item_Belongs_to === catClassId &&
              isExpanded) { // SAL-27182, SF-5877
              if (record.Name && !record.Name.includes('KIT - ')) {
                // Add 'KIT - ' prefix
                //record.Name = 'KIT - ' + record.Name; // SF-5877
                record.forcedItem = true;
                record.disableMobileRemoveItem = true;
                record.titleStyleClass = 'kitTextColour slds-theme_shade';
                record.shadeBackground = 'slds-theme_shade';
                record.Daily_Rate = null;
                record.Weekly_Rate = null;
                record.Monthly_Rate = null;
                record.Item_Subtotal = null
              }
              this.rentalLineItems.push(record);
            }
            else if (record.Kit_Number_this_Item_Belongs_to != undefined && !this.isParentPresent(record)) {
              this.rentalLineItems.push(record);
            }
          } else if ((record.lineItemType == 'VS' || record.lineItemType == 'SI' || record.lineItemType == 'YC' || record.lineItemType == 'XC') && record.UserSelectableForQuote) {
            this.salesLineItems.push(record);
            this.isExpanded=true;
          } else if (record.lineItemType == 'YD' || record.lineItemType == 'XD') {
            this.deliveryLineItems.push(record);
          } else if (record.lineItemType == 'YC' && record.miscellaneousChargeItem) {
            this.salesLineItems.push(record);
          } else if ((record.lineItemType == 'YC' || record.lineItemType == 'XC') && !record.UserSelectableForQuote && !(record.Name == 'Fuel Convenience Charge')) {
            this.ancillaryLineItems.push(record);
          } else if (((record?.Name) ? (record.Name == 'Fuel Convenience Charge') : false)) {
            this.salesLineItems.push(record);
          } else {
            // Not supposed to go in this section, however keeping it for safety 
            this.salesLineItems.push(record);
          }
        });
        this.rentalLineItems = this.reorderItems(this.rentalLineItems);
    }
      this.dispatchEvent(new RefreshEvent());
  }
  //method to add line items based on input from item search tab
  addLineItem(item) {
    //handle validation to check addition of intended line item based on recordId
    this.makeCallout = true;
    if (item.type === 'update') {
      refreshApex(this.listInfoResults); // Hashem Abdul - SAL-26119
      this.updateLineItemsTable();
    }
    else if (item.type === 'add') {
      if (this.recordId) {
        if (item.recordId == this.recordId) {
          if (item.lineItem?.Quantity > 1) {
            window.clearTimeout(this.delayTimeout);
            this.isLoading = true;
            this.delayTimeout = setTimeout(() => {
              //Hashem Abdul Commented out this code - SAL - 26119
              refreshApex(this.listInfoResults); // Hashem Abdul - SAL-26119
              this.updateLineItemsTable();
              this.isLoading = false;
            }, 8000);
            this.updateLineItemsTable();
          }
          else {
            refreshApex(this.listInfoResults); // Hashem Abdul - SAL-26119
            this.updateLineItemsTable();
          }

        }
      } else {
        let selectedCustomer = this._customerInfo && this._customerInfo.RM_Account_Number__c ? this._customerInfo.RM_Account_Number__c : '';
        if (!item.isBulk) {

          if (
            !item.lineItem.isKit && (
              item.lineItem.itemType == 'rental' ||
              item.lineItem.itemType == 'base')
          ) {
            let rateBranch = item.lineItem?.rateBranch ? item.lineItem.rateBranch : (item.lineItem?.Rate_Branch ? item.lineItem.Rate_Branch : '');
            getProductRates({
              prwrapper: {
                products: [{ productId: item.lineItem.catClass, pc: rateBranch }],
                customerNumber: selectedCustomer
              }
            }).then((result) => {
              let branch = JSON.parse(result).data.items[0].pc;
              let rates = JSON.parse(result).data.items[0].rates;
              let rateFlag = JSON.parse(result).data.items[0].rateFlag;
              let notToExceed = JSON.parse(result).data.items[0].notToExceed;
              if (rateFlag == 'Y') {
                switch (notToExceed) {
                  case 'S':
                    this.showSetRatesBanner = true;
                    break;
                  case 'X':
                    this.showDNEBanner = true;
                    break;
                  case 'P':
                    this.showPercentBanner = true;
                    break;
                  case '':
                    this.showSpecialRateBanner = true;
                    break;
                  default:
                    break;
                }
                this.invokeCSP();
              }
              //refactor to remove usage of math.random and replace with sequence for id
              let id = Math.random().toString(16).slice(2);
              this.lineItems.push({
                //SAL-26036
                lineItemType: item.lineItem.lineItemType,
                Id: id,
                Product: item.lineItem.id, //SAL-12552
                CatClass: item.lineItem.catClass,
                Cat_Class: item.lineItem.catClass,
                Name: item.lineItem.name,
                Quantity: item.lineItem.quantity,
                Min_Rate: rates.suggestedRates.minimum,
                Daily_Rate: rates.suggestedRates.daily,
                Weekly_Rate: rates.suggestedRates.weekly,
                Monthly_Rate: rates.suggestedRates.monthly,
                Rate_Branch: branch,
                SpecificPricingType: item.lineItem.specificPricingType,
                Sale_Price: null,
                Item_Subtotal: null,
                _isChecked: false,
                hasFuelPlan: item.lineItem?.hasFuelPlan ? item.lineItem.hasFuelPlan : false,//SF-5291,SF-5292
                kitItemsAmount:
                  item.lineItem.isKit == 'Yes'
                    ? item.lineItem.kitItems.length
                    : 0,
                showKitItem: false,
                hasKit: item.lineItem.isKit == 'Yes' ? true : false,
                productType: item.lineItem.productType,
                //     kitItems: {kitItemsValue: ('kitItems' in item.lineItem) ? item.lineItem.kitItems : [], packageName:item.lineItem.name}, //changed for SAL-13913
                kitItems: {
                  kitItemsValue:
                    'kitItems' in item.lineItem ? item.lineItem.kitItems : [],
                  packageName: item.lineItem.name,
                  isKit: item.lineItem.isKit,
                  productId: item.lineItem.id,
                },
                forcedItem: item?.lineItem?.forcedItem ? item?.lineItem?.forcedItem : false,// SF-5303
                Kit_Number_This_Item_Belongs_to__c: item?.lineItem?.Kit_Number_This_Item_Belongs_to__c ? item?.lineItem?.Kit_Number_This_Item_Belongs_to__c : '',//SF-5291,SF-5292
                kitNumberBelongsTo: item?.lineItem.kitNumberBelongsTo ? item.lineItem.kitNumberBelongsTo : '',
                notes: item?.lineItem?.notes ? item.lineItem.notes : '',//SF-5997
                is_Forced_Item__c: item?.lineItem?.forcedItem ? item?.lineItem?.forcedItem : false,
                SalesforceManagedKit: item?.lineItem?.SalesforceManagedKit,
                changeable: item?.lineItem?.changeable
              });
              this.updateLineItemsTable();
              this.sendIsCartEmpty();
              this.beginRefresh();
            }).catch((error) => {
              console.log('Error getting product rates ' + error.message);
            });
          } else {
            let id = Math.random().toString(16).slice(2);
            this.lineItems.push({
              Id: id,
              Product: item.lineItem.id,
              //CatClass: item.lineItem.catClass,
              CatClass: item.lineItem.fields
                ? item.lineItem.fields.Cat_Class__c.value
                : item.lineItem.catClass, //SAL-12552
              Cat_Class:item.lineItem.fields
                ? item.lineItem.fields.Cat_Class__c.value
                : item.lineItem.catClass,
              Name: item.lineItem.name,
              Quantity: item.lineItem.quantity,
              Min_Rate: item.lineItem?.Min_Rate,
              Daily_Rate: item.lineItem?.Daily_Rate,
              Weekly_Rate: item.lineItem?.Weekly_Rate,
              Monthly_Rate: item.lineItem?.Monthly_Rate,
              Sale_Price: item.lineItem.sellPrice,
              Rate_Branch: item.lineItem.Rate_Branch,
              Item_Subtotal: null,
              Item_Type: item.lineItem.itemType,
              _isChecked: false,
              kitItemsAmount:
                item.lineItem.isKit == 'Yes'
                  ? item.lineItem.kitItems.length
                  : 0,
              hasKit: item.lineItem.isKit == 'Yes' ? true : false,
              showKitItem: false,
              productType: item.lineItem.productType,
              SpecificPricingType: item.lineItem.specificPricingType,
              stockClass: item.lineItem.stockClass, //25958
              itemNumber: item.lineItem.itemNumber, //25958
              lineItemType: item.lineItem.lineItemType, // SAL-27018
              //  kitItems: {kitItemsValue: ('kitItems' in item.lineItem) ? item.lineItem.kitItems : [], packageName:item.lineItem.name}, //changed for SAL-13913
              kitNumberBelongsTo: item.lineItem.kitNumberBelongsTo ? item.lineItem.kitNumberBelongsTo : '',//SF-5291,SF-5292
              hasFuelPlan: item.lineItem?.hasFuelPlan ? item.lineItem.hasFuelPlan : false,//SF-5291,SF-5292
              notes: item?.lineItem?.notes ? item.lineItem.notes : '',//SF-5997
              kitItems: {
                kitItemsValue:
                  'kitItems' in item.lineItem ? item.lineItem.kitItems : [],
                packageName: item.lineItem.name,
                isKit: item.lineItem.isKit,
                lineItemType: item.lineItem.lineItemType, // SAL-27018
                productId: item.lineItem.id
              },
              SalesforceManagedKit: item?.lineItem?.SalesforceManagedKit,
              changeable: item?.lineItem?.changeable
            });
            this.updateLineItemsTable();
            this.sendIsCartEmpty();
            this.beginRefresh();
          }
        } else {
          let products = [];
          let salesItems = [];
          let bulkLineItems = [...item.lineItem];
          bulkLineItems.forEach((item) => {
            if (item.itemType === 'rental' || item.itemType === 'base') {
              products.push({ productId: item.catClass, pc: item.rateBranch });
            }
          });
          if (products[0] != null) {
            getProductRates({
              prwrapper: {
                products: products,
                customerNumber: selectedCustomer
              }
            }).then((result) => {
              let bulkRates = JSON.parse(result).data.items;
              let bulkLineItems = item.lineItem.map((item) => item.lineItem);
              bulkRates.forEach((rateItem, index) => {
                let id = Math.random().toString(16).slice(2);
                this.lineItems.push({
                  Id: id,
                  CatClass: bulkLineItems[index].catClass,
                  Cat_Class: bulkLineItems[index].catClass,
                  Name: bulkLineItems[index].name,
                  Quantity: bulkLineItems[index].quantity,
                  Min_Rate: rateItem.rates.suggestedRates.minimum,
                  Daily_Rate: rateItem.rates.suggestedRates.daily,
                  Weekly_Rate: rateItem.rates.suggestedRates.weekly,
                  Monthly_Rate: rateItem.rates.suggestedRates.monthly,
                  Rate_Branch: rateItem.pc,
                  Sale_Price: '--',
                  Item_Subtotal: '--',
                  _isChecked: false
                });
              });
              bulkLineItems.forEach((item) => {
                if (item.itemType === 'sales') {
                  let id = Math.random().toString(16).slice(2);
                  this.lineItems.push({
                    Id: id,
                    CatClass: item.catClass,
                    Cat_Class: item.catClass,
                    Name: item.name,
                    Quantity: item.quantity,
                    Min_Rate: '--',
                    Daily_Rate: '--',
                    Weekly_Rate: '--',
                    Monthly_Rate: '--',
                    Sale_Price: item.sellPrice,
                    Item_Subtotal: '--',
                    Item_Type: item.itemType,
                    _isChecked: false
                  });
                  salesItems.push(item.catClass);
                }
              });
              this.updateLineItemsTable();
              this.sendIsCartEmpty();
              this.beginRefresh();
            }).catch((error) => {
              console.log('Error getting product rates ' + error.message);
            });
          }
        }
      }
    }
  }
  @api clearLineItems() {
    this.lineItems = [];
    const payload = {
      recordId: null,
      type: 'remove',
      lineItemsCount: this.lineItems.length
    };
    publish(this.messageContext, updateLineItemsChannel, payload);

    if (!this.isMobile) {
      publish(this.messageContext, deselectProductRowChannel, {
        productId: null,
        contextId: null
      });
    }
    const isCartEmpty = new CustomEvent('sendisemptycart', {
      detail: {
        isEmptyCart: true
      }
    });
    this.dispatchEvent(isCartEmpty);
    this.beginRefresh();
    this.updateLineItemsTable();
  }
  updateUniqueProductsMap(item, uniqueProductsMap) {
    let key = item.kitNumberBelongsTo
      ? `${item.CatClass}_${item.kitNumberBelongsTo}`
      : `${item.CatClass}`;
    if (uniqueProductsMap[key]) {
      uniqueProductsMap[key].Quantity += item.Quantity;
    } else {
      uniqueProductsMap[key] = { ...item };
    }
    if (item.kitNumberBelongsTo && this.hasKitParent(item)) {
      this.updateChildItemProperties(item);
    } else {
      item.quantityEditable = true;
    }
  }
  updateUniqueLineItemsArray(item, lineItemsUnique) {
    let indexItem = lineItemsUnique.findIndex((element) => element.CatClass === item.CatClass);
    if (indexItem >= 0) {
      let existingItem = lineItemsUnique[indexItem];
      existingItem.Quantity += item.Quantity;
      lineItemsUnique.splice(indexItem, 1, existingItem);
    } else {
      lineItemsUnique.push(item);
    }
  }

  // SAL-27018
  getUniqueProducts() {
    let lineItemsUnique = [];
    let uniqueProductsMap = {};
    this.lineItems.forEach((item) => {
      if (this.objectApiName === undefined) {
        this.updateUniqueProductsMap(item, uniqueProductsMap);
      } else {
        this.updateUniqueLineItemsArray(item, lineItemsUnique);
      }
    });
    if (this.objectApiName == undefined) {
      // Convert the map values back to an array
      lineItemsUnique = Object.values(uniqueProductsMap);
    }

    lineItemsUnique = this.reorderItems(lineItemsUnique);
    return lineItemsUnique;
  }

  hasKitParent(item) {
    return this.lineItems.some(
      (parent) => parent.CatClass === item.kitNumberBelongsTo && parent.hasKit
    );
  }

  updateChildItemProperties(item) {
    item.quantityEditable = false;
    item.forcedItem = true;
    item.disableMobileRemoveItem = true;
  }


  handleSaveCartInfos(event) {
    let context = event.detail.context;
    let informations = event.detail.information;
    this.saveLineItems(context, informations);
  }

  reorderItems = (array) => {
    let newArray = [];
    let processedItems = new Set();

    array.forEach((item) => {
      const catClass = item?.fields?.Cat_Class__c || item.CatClass;
      const kitNumber = item?.fields?.Kit_Number_This_Item_Belongs_To__c || item?.Kit_Number_this_Item_Belongs_to || item?.kitNumberBelongsTo;

      if (catClass && !kitNumber) {
        // Push parent item
        newArray.push(item);
        processedItems.add(catClass);

        // Push child items where Kit_Number_This_Item_Belongs_To__c matches parent Cat_Class__c
        const children = array.filter(
          (child) => (child.Kit_Number_this_Item_Belongs_to || child?.fields?.Kit_Number_This_Item_Belongs_To__c || child?.kitNumberBelongsTo) === catClass
        );

        children.forEach((child) => {
          let childCatClass = child.CatClass || child?.fields?.Cat_Class__c;
          newArray.push(child);
          processedItems.add(childCatClass);
        });
      }
    });
    // Push remaining items
    array.forEach((item) => {
      if (!processedItems.has(item.CatClass || item?.fields?.Cat_Class__c)) {
        newArray.push(item);
      }
    });

    return newArray;
  };



  @api saveLineItems(context, information) {
    this.lineItems = this.getUniqueProducts(); // SAL-27018
    information['Total__c'] = String(this.total).charAt(0) === '$' ? String(this.total).slice(1) : this.total;
    switch (context) {
      case 'Product Inquiry':
        const fields = information;
        const cartRecordInput = { apiName: CART_OBJECT.objectApiName, fields };
        createRecord(cartRecordInput)
          .then((cart) => {
            this.savedCartId = cart.id;
            this.savedCartName = cart.fields.Name.value;
            let processedKitItemIds = new Set();  // changes done for SF-5287
            // Create an array to store the final result
            let flattenedCartItems = [];
            let cartItems = this.lineItems.map((item) => {
              //use CatClass+KitNumberBelongsto field as unique for ForcedAddons - SF-6457
              let key = item.kitNumberBelongsTo? `${item.CatClass}_${item.kitNumberBelongsTo}`: `${item.CatClass}`;
              // If the CatClass is already processed, skip creating the cart item record
              if (processedKitItemIds.has(key)) {
                return [];
              }
              let fields = {
                Cart__c: cart.id,
                Cat_Class__c: item.CatClass,
                Name: item.Name,
                Minimum_Price__c:
                  String(item.Min_Rate).charAt(0) === '$'
                    ? String(item.Min_Rate).slice(1)
                    : item.Min_Rate,
                Daily_Price__c:
                  String(item.Daily_Rate).charAt(0) === '$'
                    ? String(item.Daily_Rate).slice(1)
                    : item.Daily_Rate,
                Weekly_Price__c:
                  String(item.Weekly_Rate).charAt(0) === '$'
                    ? String(item.Weekly_Rate).slice(1)
                    : item.Weekly_Rate,
                Monthly_Price__c:
                  String(item.Monthly_Rate).charAt(0) === '$'
                    ? String(item.Monthly_Rate).slice(1)
                    : item.Monthly_Rate,
                Misc_Sales_Price__c:
                  String(item.Sale_Price).charAt(0) === '$'
                    ? String(item.Sale_Price).slice(1)
                    : item.Sale_Price,
                Item_Subtotal__c:
                  String(item.Item_Subtotal).charAt(0) === '$'
                    ? String(item.Item_Subtotal).slice(1)
                    : item.Item_Subtotal,
                Suggested_Minimum_Price__c:
                  String(item.Min_Rate).charAt(0) === '$'
                    ? String(item.Min_Rate).slice(1)
                    : item.Min_Rate,
                Suggested_Daily_Price__c:
                  String(item.Daily_Rate).charAt(0) === '$'
                    ? String(item.Daily_Rate).slice(1)
                    : item.Daily_Rate,
                Suggested_Weekly_Price__c:
                  String(item.Weekly_Rate).charAt(0) === '$'
                    ? String(item.Weekly_Rate).slice(1)
                    : item.Weekly_Rate,
                Suggested_Monthly_Price__c:
                  String(item.Monthly_Rate).charAt(0) === '$'
                    ? String(item.Monthly_Rate).slice(1)
                    : item.Monthly_Rate,
                Specific_Pricing_Type__c: item.SpecificPricingType,
                Quantity__c: item.Quantity,
                Product__c: item.Product, //SAL-12552
                is_User_Added__c: true, //22570
                Line_Item_Type__c: item.lineItemType != undefined ? item.lineItemType : 'VR',
                Fuel_Plan__c: item?.hasFuelPlan ? item.hasFuelPlan : false,//SF-5291,SF-5292
                Kit_Number_This_Item_Belongs_To__c: item?.kitNumberBelongsTo ? item.kitNumberBelongsTo : '',//SF-5291,SF-5292
                Line_Comments__c: item?.notes ? item.notes : '',//SF-5997
                Rates_Branch__c: item?.rateBranch ? item.rateBranch : (item?.Rate_Branch ? item.Rate_Branch : '')
              };
              let cartItemRecord = { apiName: CART_ITEMS_OBJECT.objectApiName, fields };
              flattenedCartItems.push(cartItemRecord);
              // Mark the CatClass as processed
              processedKitItemIds.add(key);
            });

            // Sorting the array
            flattenedCartItems = this.reorderItems(flattenedCartItems);

            let cartItemsPromises = flattenedCartItems.map((cartItem) =>
              createRecord(cartItem)
            );
            Promise.all(cartItemsPromises)
              .then((createdCartItems) => {
                if (createdCartItems.length > 0) {
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: 'Success',
                      message: this.savedCartName + ' was created',
                      variant: 'success'
                    })
                  );
                } else {
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: 'Success',
                      message: this.savedCartName + ' was created',
                      variant: 'success'
                    })
                  );
                }
                this.clearLineItems();
                this[NavigationMixin.Navigate]({
                  type: 'standard__recordPage',
                  attributes: {
                    recordId: this.savedCartId,
                    actionName: 'view'
                  }
                });
              })
              .catch((cartItemsError) => {
                this.dispatchEvent(
                  new ShowToastEvent({
                    title: 'Error creating Cart Items',
                    message: cartItemsError.body.message,
                    variant: 'error'
                  })
                );
              });
          })
          .catch((error) => {
            console.log('Error saving line items' + error.message);
            this.dispatchEvent(
              new ShowToastEvent({
                // SAL-11600 undefined is not an object (evaluating 'cartItemsError.body.message')
                title: 'Error creating Cart record',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
        break;
    }
  }

  toggleClearCart(event) {
    this.clearCartAction = true;
    this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
  }
  resetFooterData() {
    this.subtotal = 0;
    this.tax = 0;
    this.total = 0;
    this.charges = 0;
  }

  displayCartInfo() {
    this.showCartInfo = true;
    const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
      bubbles: true,
      composed: true,
      detail: {
        viewState: 'cart-info',
        showTabsPanel: false
      }
    });
    this.dispatchEvent(toggleprodinqmobilestate);
  }
  get cartInfoDisplay() {
    return this.showCartInfo ? 'cart-info-show' : 'cart-info';
  }

  get displayFooterButtons() {
    if (this.objectApiName == 'SBQQ__Quote__c' || this.objectApiName == 'Order' || this.objectApiName == 'Cart__c') {
      return false;
    }
    return true;
  }

  cancelCartInfos(event) {
    this.showCartInfo = false;
  }
  hideSpinner() {
    this.showSpinner = false;
  }
  sendIsCartEmpty() {
    const isCartEmpty = new CustomEvent('sendisemptycart', {
      detail: {
        isEmptyCart: this.lineItems.length <= 0
      }
    });
    this.dispatchEvent(isCartEmpty);
  }
  invokeCSP() {
    let paramData = {};
    if (this.showSetRatesBanner) {
      paramData = {
        showDNEBanner: false,
        showSetRatesBanner: true,
        showPricingUpdatedBanner: false,
        showPercentBanner: false,
        showSpecialRateBanner: false
      };
    } else {
      paramData = {
        showDNEBanner: this.showDNEBanner,
        showSetRatesBanner: this.showSetRatesBanner,
        showPricingUpdatedBanner: this.showPricingUpdatedBanner,
        showPercentBanner: this.showPercentBanner,
        showSpecialRateBanner: this.showSpecialRateBanner
      };
    }
    if (this.isAccountRemoved || this.isAccountAdded) {
      paramData = { ...paramData, isAccountRemoved: this.isAccountRemoved, isAccountAdded: this.isAccountAdded };
      this.isAccountRemoved = false;
      this.isAccountAdded = false;
    }
    let ev = new CustomEvent('updatecsp', { detail: paramData });
    this.dispatchEvent(ev);
  }
  @api updateLineItemsTable() {
    this.columns = [...this.columns];
    this.lineItems = [...this.lineItems];
    this.getRequiredAddOns().then((options) => {
        this.requiredOptions = options;
        if (this.lineItems.length > 0 && (this.objectApiName == undefined || this.objectApiName == 'Cart__c')) {
          return this.getItemEstimates(); // Only call getItemEstimates if the conditions are met
        }
        else {
          this.dispatchEvent(new CustomEvent('stopspinner'));
        }
      }).then(() => {
        this.showLineItemsTable = this.lineItems.length !== 0 && this.columns.length !== 0;
        this.loadingItems = false;
        this.updateLineItemGridData(this.lineItems);
      });
  }
  formatNumber(num) {
    const formattingOptions = {
      style: "decimal",  // or "currency" for currency formatting
      currency: "USD",   // If using currency formatting
      maximumFractionDigits: 2,
      minimumFractionDigits: 2,
    };
    return '$' + new Intl.NumberFormat("en-US", formattingOptions).format(Number(num));
  }

  getItemEstimates() {
    this.estimateRequest.orderLines[0].products = [];
    this.estimateRequest.orderLines[0].salesItems = [];
    let accountNumber;
    let rmAccountNumber;
    if (this._customerInfo != undefined && this._customerInfo.RM_Account_Number__c != undefined && (this._customerInfo.RM_Account_Number__c).includes("-")) {
      rmAccountNumber = this._customerInfo?.RM_Account_Number__c.split('-');
      if (rmAccountNumber[1]) {
        accountNumber = Number(rmAccountNumber[1]);
      }
      else {
        accountNumber = 0;
      }
    }
    else if (this._customerInfo != undefined && this._customerInfo.RM_Account_Number__c != undefined && !((this._customerInfo.RM_Account_Number__c).includes("-"))) {
      accountNumber = this._customerInfo.RM_Account_Number__c;
    }
    else {
      accountNumber = 0;
    }
    this.estimateRequest.account = accountNumber;
    this.lineItems.forEach((item) => {
      let product = {};
      let salesItems = {};
      if (!this.recordId) {
        if (item.CatClass != undefined) {
          if (item.productType !== 'Cat-Class') {
            salesItems = {
              itemNumber: item.itemNumber,
              stockClass: item.stockClass,
              unitPrice: item.Sale_Price
                ? Number(String(item.Sale_Price).replace(/[$,]+/g, ''))
                : 0,
              quantity: item.Quantity
            };
            this.estimateRequest.orderLines[0].salesItems.push(salesItems);
          } else {
            product = {
              catId: item.CatClass.slice(0, 3),
              classId: item.CatClass.slice(3, 7),
              quantity: item.Quantity,
              rates: {
                override: true,
                hourly: '0.00',
                minimum: item.Min_Rate
                  ? String(item.Min_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                daily: item.Daily_Rate
                  ? String(item.Daily_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                weekly: item.Weekly_Rate
                  ? String(item.Weekly_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                monthly: item.Monthly_Rate
                  ? String(item.Monthly_Rate).replace(/[$,]+/g, '')
                  : '0.00'
              }
            };
            this.estimateRequest.orderLines[0].products.push(product);
          }
        }
      } else {
        if (item.CatClass != undefined) {
          if (item.productType !== 'Cat-Class') {
            salesItems = {
              itemNumber: item.itemNumber,
              stockClass: item.stockClass,
              unitPrice: item.Sale_Price
                ? Number(String(item.Sale_Price).replace(/[$,]+/g, ''))
                : 0, //25958
              quantity: item.Quantity
            };
            this.estimateRequest.orderLines[0].salesItems.push(salesItems);
          } else {
            product = {
              catId: item.CatClass.slice(0, 3),
              classId: item.CatClass.slice(3, 7),
              quantity: item.Quantity,
              rates: {
                override: true,
                hourly: '0.00',
                minimum: item.Min_Rate
                  ? String(item.Min_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                daily: item.Daily_Rate
                  ? String(item.Daily_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                weekly: item.Weekly_Rate
                  ? String(item.Weekly_Rate).replace(/[$,]+/g, '')
                  : '0.00',
                monthly: item.Monthly_Rate
                  ? String(item.Monthly_Rate).replace(/[$,]+/g, '')
                  : '0.00'
              }
            };
            this.estimateRequest.orderLines[0].products.push(product);
          }
        }
      }
    });
    this.estimateRequest.orderType =
      this._deliveryCpu == 'delivery' ? 'Delivery' : 'Pickup';
    if (this._jobsiteZip) {
      this.estimateRequest.address[0].zip = this._jobsiteZip;
    }
    this.estimateRequest.startDateAndTime =
      this._startDate + 'T' + this._startTime;
    if (!this.estimateRequest.startDateAndTime.endsWith('Z')) {
      this.estimateRequest.startDateAndTime =
        this.estimateRequest.startDateAndTime + 'Z';
    }
    this.estimateRequest.endDateAndTime =
      this._returnDate + 'T' + this._returnTime;
    if (!this.estimateRequest.endDateAndTime.endsWith('Z')) {
      this.estimateRequest.endDateAndTime =
        this.estimateRequest.endDateAndTime + 'Z';
    }
    let today = new Date();
    let cartDate = new Date(this._startDate);
    let cmpCode = (this.__customerInfo) && (this._customerInfo?.Company_Code__c) ? this._customerInfo.Company_Code__c : this.userCompanyCode;
    if (
      this.lineItems.length > 0 && this.estimateRequest.orderLines[0].products?.length > 0 &&
      cmpCode != undefined && !(today > cartDate) && this.makeCallout
    ) {
      let companyId = cmpCode.replace('0', '');
      this.isLoading = true;
      getLineItemEstimates({
        estimatesRequestJson: JSON.stringify(this.estimateRequest),
        companyId: companyId
      })
        .then((result) => {
          this.isLoading = false;
          let retVal = JSON.parse(result);
          if (!retVal.hasOwnProperty('error')) {
            let salesEstimates =
              retVal.data.estimate.itemizedCharges.orderLines[0].salesItems;
            let productEstimates =
              retVal.data.estimate.itemizedCharges.orderLines[1].products;
            this.lineItems.forEach((item) => {
              productEstimates.forEach((estimate) => {
                if (
                  estimate.catId === item.CatClass.slice(0, 3) &&
                  estimate.classId === item.CatClass.slice(3, 7) &&
                  estimate.quantity === item.Quantity
                ) {
                  item.Item_Subtotal = estimate.rentalCost;
                }
              });
              salesEstimates.forEach((estimate) => {
                if (
                  estimate.itemNumber === item.itemNumber &&
                  estimate.stockClass === item.stockClass &&
                  estimate.quantity === item.Quantity
                ) {
                  item.Item_Subtotal = estimate.totalPrice;
                }
              });
            });
            this.subtotal = this.formatNumber(parseFloat(retVal.data.estimate.totals.rentalAmount) + parseInt(retVal.data.estimate.totals.salesAmount));
            this.tax = this.formatNumber(retVal.data.estimate.totals.salesTax);
            this.total = this.formatNumber(retVal.data.estimate.totals.finalTotal);
            this.charges = this.formatNumber(retVal.data.estimate.totals.rppCharges + retVal.data.estimate.totals.miscCharges);
            this.taxAndCharges = this.formatNumber(retVal.data.estimate.totals.salesTax + retVal.data.estimate.totals.rppCharges + retVal.data.estimate.totals.miscCharges);
            this.lineItems = [...this.lineItems];
            // add dollar sign to rates
            this.lineItems.forEach((lineItem) => {
              lineItem.Min_Rate = lineItem.Min_Rate;
              lineItem.Daily_Rate = lineItem.Daily_Rate;
              lineItem.Weekly_Rate = lineItem.Weekly_Rate;
              lineItem.Monthly_Rate = lineItem.Monthly_Rate;
              lineItem.Item_Subtotal = lineItem.Item_Subtotal;
            });
            this.updateLineItemGridData(this.lineItems);
            this.showLineItemsTable =
              this.lineItems.length != 0 && this.columns.length != 0
                ? true
                : false;
            this.loadingItems = false;
            if (this.objectApiName === 'Cart__c' && this.recordId) {
              let fields = {};
              //26732 BD 
              //SF-6237
              let updateFields = {};
              updateFields['cartTotal'] = String(this.total).charAt(0) === '$' ? String(this.total).slice(1) : this.total;
              updateFields['cartTax'] = String(this.tax).charAt(0) === '$' ? String(this.tax).slice(1) : this.tax;
              updateFields['cartSubTotal'] = String(this.subtotal).charAt(0) === '$' ? String(this.subtotal).slice(1) : this.subtotal;
              updateFields['cartDeliveryCharges'] = String(this.charges).charAt(0) === '$' ? String(this.charges).slice(1) : this.charges;
              this.dispatchEvent(
                new CustomEvent("savecart", {
                  detail: updateFields
                })
              );

              let cartItems = this.lineItems.map((item) => {
                let fields = {
                  Id: item.Id,
                  Item_Subtotal__c:
                    String(item.Item_Subtotal).charAt(0) === '$'
                      ? String(item.Item_Subtotal).slice(1)
                      : item.Item_Subtotal
                };
                return { fields };
              });
              let cartItemsPromises = cartItems.map((cartItem) => {
                updateRecord(cartItem)
              }
              );
              this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Success',
                  message: 'Totals Updated',
                  variant: 'success'
                })
              );
              this.makeCallout = false;
            }
            this.dispatchEvent(new CustomEvent('stopspinner'));
          } else {
            this.isLoading = false;
            if (retVal.hasOwnProperty('error')) {
              this.isLoading = false;
              this.dispatchEvent(
                new ShowToastEvent({
                  title:
                    'Failed to retrieve Estimates (Expect blank totals/subtotals)',
                  message: '',
                  variant: 'error'
                })
              );
            }
            this.dispatchEvent(new CustomEvent('stopspinner'));
          }
        })
        .catch((error) => {
          this.isLoading = false;
          this.dispatchEvent(new CustomEvent('stopspinner'));
          this.dispatchEvent(
            new ShowToastEvent({
              title:
                'Failed to retrieve Estimates (Expect blank totals/subtotals)',
              message: '',
              variant: 'error'
            })
          );
        });
    } else {
    }
  }

  // SAL-26337
  getGridName(record) {
    let result = 'rental';
    if (record.productType == 'Cat-Class') {
      result = 'rental';
    } else if (record.productType == 'Merchandise' || record.productType == 'Parts') {
      result = 'sales';
    } else if (record.productType == 'MISC Charge Items') {
      if (record.stockClass == 'DEL') {
        result = 'delivery';
      } else if (record.stockClass != 'DEL') {
        if (record.lineItemType != undefined && record.lineItemType != null && record.lineItemType === 'YC') {
          result = 'ancillary';
        } else if (record.isUserAdded) {
          result = 'sales';
        } else {
          result = 'ancillary';
        }
      }
    } else {
      result = 'sales';
    }
    return result;
  }

  handleRowAction(event) {
    this.makeCallout = true;
    const action = event.detail.action;
    const row = event.detail.row;
    // SAL-26337
    this.gridName = this.getGridName(row);
    this.headerText = 'Line Editor';
    this.selRowForKit = event.detail.row;

    switch (action.name) {
      case 'Kit':
        if (row.hasKit && row.displayIconName != undefined && row.displayIconName != null) {
          //first time click for ID
          let isExpanded = this.IdToExpandedMap[this.selRowForKit.Id];
          if (isExpanded !== undefined) {
            // Toggle the state
            isExpanded = !isExpanded;
            // Update the object
            this.IdToExpandedMap[this.selRowForKit.Id] = isExpanded;
          } else {
            this.IdToExpandedMap[this.selRowForKit.Id] = true;
          }
          this.isExpanded = !this.isExpanded;
          if (!this.isMobile)
            this.dispatchEvent(new RefreshEvent());
        }
        break;
      case 'delete':

        const rows = this.lineItems;

        let selectedRows = [];
        if (this.recordId) {
          let matchingItem;
          let lineItem = this.lineItems.find(item => item.Id === row.Id);
          //change for KITS
          if (lineItem) {
            if (this.objectApiName === 'Cart__c') {
              // Check if lineItem.CatClass matches any Kit_Number_this_Item_Belongs_to //SF-5291,SF-5292
              matchingItem = rows.filter(item => item.Kit_Number_this_Item_Belongs_to === lineItem.CatClass);
              if (lineItem.hasKit || matchingItem) { //  Added check for matching Item for SF-6147
                // Remove child items
                matchingItem.forEach((childItem) => {
                  const childIndex = rows.findIndex((r) => r.Id === childItem.Id);
                  if (childIndex !== -1) {
                    selectedRows.push(childItem.Id)
                    rows.splice(childIndex, 1);
                  }
                });
              }
            }
            if (matchingItem && matchingItem[0]?.hasFuelPlan) {
              let fields = { Id: matchingItem[0]?.Id };
              fields['Fuel_Plan__c'] = false;
              let recordInput = { fields };
              updateRecord(recordInput);
            }
          }
        }
        if (row && this.objectApiName == undefined) {
          // Check if lineItem.CatClass matches any Kit_Number_this_Item_Belongs_to for PI //SF-5291,SF-5292
          const matchingItem = this.lineItems.filter(item => item.CatClass === row.kitNumberBelongsTo);
          if (matchingItem && matchingItem[0]?.hasFuelPlan) {
            const targetItemId = matchingItem[0].Id;
            this.lineItems.forEach(item => {
              if (item.Id === targetItemId) {
                item.hasFuelPlan = false;
              }
            });
          }
        }

        selectedRows.push(row.Id);

        const rowIndex = rows.findIndex((r) => r.Id == row.Id);
        rows.splice(rowIndex, 1);
        this.lineItems = rows;

        // Remove row from Displayed Line Items in PI
        if(this.objectApiName == undefined) {
          let displayedLineItemsRows = this.displayedLineItems;
          const rowIndexDisplayed = displayedLineItemsRows.findIndex((r) => r.Id == row.Id);
          displayedLineItemsRows.splice(rowIndexDisplayed, 1);
          this.displayedLineItems = displayedLineItemsRows;
        }

        if (this.recordId) {
          for (const idToRemove of selectedRows) {
            deleteRecord(idToRemove)
              .then(() => {
                refreshApex(this.listInfoResults);
                this.beginRefresh();
              })
              .catch((error) => {
                this.dispatchEvent(
                  new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body.message,
                    variant: 'error'
                  })
                );
              });
          }
          const payload = {
            recordId: this.recordId,
            type: 'remove',
            lineItemsCount: this.lineItems.length
          };
          publish(this.messageContext, updateLineItemsChannel, payload);
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Line Items deleted.',
            variant: 'success'
          })
        );
        this.updateLineItemsTable();
        break;
      case 'edit_quote_line':
        if (this.isQuote && this.isQuoteSubmitted()) {
          this.showToastMessage('Error', Submitted_Quote_Error_Message, 'error');
          break;
        }
        this.lineId = row.Id;
        this.headerText = row.Name;
        if (this.gridName == 'rental') {
          this.headerText = row.Name + ' (' + row.productCategory + '-' + row.productClass + ')';
        }
        this.selectedItemGroup = '';
        if (!this.isParentPresent(this.selRowForKit)) {
          this.template.querySelector('.editModal').toggleModal();
          this.template
            .querySelector('c-sbr_3_0_line-item-editor-cmp')
            .populateLineData(row.Id, row._groupId, this.recordId, this.lineItems);
        }
        break;
      case 'remove_quote_line':
        break;
      case 'view_line_item':
        this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
            recordId: row.product,
            actionName: 'view'
          }
        });
        break;
      case 'edit_order_line':
        if (this.isOrder && this.isOrderSubmitted()) {
          this.showToastMessage('Error', Submitted_Order_Error_Message, 'error');
          break;
        }
        this.lineId = row.Id;
        this.headerText = row.Name;
        if (this.gridName == 'rental') {
          this.headerText = row.Name + ' (' + row.productCategory + '-' + row.productClass + ')';
        }
        this.selectedItemGroup = row._groupId;
        if (!this.isParentPresent(this.selRowForKit)) {
          this.template.querySelector('.editModal').toggleModal();
          this.template
            .querySelector('c-sbr_3_0_line-item-editor-cmp')
            .populateLineData(row.Id, row._groupId, this.recordId, this.lineItems);
        }
        break;
      case 'remove_order_line':
        break;
    }
  }
  handleSaveEdit = (event) => {

    event.stopPropagation();
    this.template
      .querySelector('c-sbr_3_0_custom-data-table-edit-cmp')
      .saveRows(this.lineItems);

    setTimeout(() =>
      refreshApex(this.listInfoResults)
      , DELAY);

  };
  handleCancelEdit = (event) => {
    event.stopPropagation();
  };
  //method to handle inline edits
  async handleSave(event) {
    this.showSpinner = true;
    let draftValues = event.detail.draftValues;
        let isValid = await this.validateChanges(draftValues);
    if (isValid) {
      if (this.recordId) {
        let editLineItems = draftValues.map((value) => {
          let fields = { Id: value.Id };
          switch (this.objectApiName) {
            case 'Cart__c':
              fields['Quantity__c'] = value.Quantity;
              this.makeCallout = true;
              break;
            case 'SBQQ__Quote__c':
              fields['SBQQ__Quantity__c'] = value.Quantity;
              fields['Daily_Rate__c'] = value.Daily_Rate;
              fields['Weekly_Rate__c'] = value.Weekly_Rate;
              fields['Monthly_Rate__c'] = value.Monthly_Rate;
              fields['SBQQ__UnitCost__c'] = value.Sale_Price;
              break;
            case 'Order':
              fields['Quantity'] = value.Quantity;
              fields['Daily_Rate__c'] = value.Daily_Rate;
              fields['Weekly_Rate__c'] = value.Weekly_Rate;
              fields['Monthly_Rate__c'] = value.Monthly_Rate;
              fields['UnitPrice'] = value.Sale_Price;
              break;
          }
          let recordIput = { fields };
          return updateRecord(recordIput);
        });
        Promise.all(editLineItems)
          .then(async (editedItems) => {
            // query product options for addons - SF-5330
            this.getRequiredAddOns().then((productOptions) => {
              productOptions = productOptions || [];
              for (let eItem of editedItems) {//modified existing for SF-5291,SF-5292
                let lineItem = this.lineItems.find(item => item.Id === eItem.id);

                if (lineItem) {
                  // Check if lineItem.CatClass matches any Kit_Number_this_Item_Belongs_to
                  const matchingItems = this.lineItems.filter(item => item.Kit_Number_this_Item_Belongs_to === lineItem.CatClass);
                  // Update Quantity field for matching items
                  matchingItems.forEach(item => {
                    let matchedOption = productOptions.find(option => { return option.SBQQ__OptionalSKU__c === item.product });
                    // For Sales Addons update child quantity only if new quantity is greater
                    if (matchedOption && matchedOption?.SBQQ__Feature__r?.Name == 'Sales Addons' && eItem.fields.Quantity__c.value > item.Quantity) {
                      item.Quantity = eItem.fields.Quantity__c.value;
                    } else if (matchedOption && (matchedOption?.SBQQ__Feature__r?.Name == 'Rental Addons' || matchedOption?.SBQQ__Feature__r?.Name == 'Kit Component')) {
                      item.Quantity = matchedOption.SBQQ__Quantity__c * eItem.fields.Quantity__c.value;
                    }
                  });
                  let secondEditLineItems = matchingItems.map(item => {
                    const quantityFieldName = this.getQuantityFieldName(this.objectApiName);
                    let fields = { Id: item.Id };
                    fields[quantityFieldName] = item.Quantity;
                    let recordInput = { fields };
                    return updateRecord(recordInput);
                  });
                  Promise.all(secondEditLineItems)
                    .then((secondEditedItems) => {
                      console.log('Second update successful:', secondEditedItems);

                    })
                    .catch((secondEditError) => {
                      console.error('Error during second update:', secondEditError);
                      this.dispatchEvent(
                        new ShowToastEvent({
                          title: 'Error editing Line Items',
                          message: 'Error editing Line Items',
                          variant: 'error'
                        })
                      )
                      this.showSpinner = false;
                    });
                }
              }//SF-5291,SF-5292
            });

            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Success',
                message: 'Line Items edited.',
                variant: 'success'
              })
            );
            this.showSpinner = false;
          })
          .catch((editedLineItemsError) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error editing Line Items',
                message: 'Error editing Line Items',
                variant: 'error'
              })
            );
            this.showSpinner = false;
          });
      } else {
        const rows = this.lineItems;
        draftValues.forEach((value) => {
          rows.find((e) => e.Id == value.Id).Quantity = parseInt(
            value.Quantity
          );
        });
        this.lineItems = rows;
        
        for (let lineItem of rows) {
          const matchingItems = this.lineItems.filter(item => item.kitNumberBelongsTo === lineItem.CatClass);
          matchingItems.forEach(childItem => {
            childItem.Quantity = lineItem.Quantity * childItem.Quantity;
          });
        }
        this.updateLineItemsTable();
        this.showSpinner = false;
      }
      this.draftValues = [];
      this.draftErrors = {};
    } else {
      this.showSpinner = false;
    }
  }

  handleLineItemSelection(event) {
    let selectedRows = event.target.getSelectedRows();
    this._disableRemoveItem = selectedRows.length > 0 ? false : true;
  }
  getQuantityFieldName(objectApiName) {
    // Add logic to determine the correct quantity field name based on the object type
    switch (objectApiName) {
      case 'Cart__c':
        return 'Quantity__c';
      case 'SBQQ__Quote__c':
        return 'SBQQ__Quantity__c';
      case 'Order':
        return 'Quantity';

      default:

        throw new Error('Unsupported object type: ' + objectApiName);
    }
  }

  @api refreshDataGrid() {
    this.template.querySelector('c-sbr_3_0_line-item-editor-cmp').saveData().then((data) => {
      if (data != null) {
        let updatedRecordId = this.objectApiName == 'SBQQ__Quote__c' ? data.Id : data[0].Id;
        if (this.objectApiName == 'SBQQ__Quote__c') {
          this.repopulateLineItems(updatedRecordId);
        }
        else {  // SAL-27195
          checkBulkFlag({ lineItemId: updatedRecordId })
            .then(result => {
              if (result) {
                this.repopulateLineItems(updatedRecordId);
              }
              else {
                window.clearTimeout(this.delayTimeout);
                this.delayTimeout = setTimeout(() => {
                  this.repopulateLineItems(updatedRecordId);
                }, 8000);
              }
            })
            .catch(error => {
              console.log('Error in getting a response from get line item bulk flag ' + error.message);
            })
        }
      }
    }).catch((error) => {
      this.dispatchEvent(new ShowToastEvent(
        {
          name: 'Submit Success',
          message: error.message,
          variant: 'error',
          mode: 'dismissible'
        }));
    });
    this.isLoading = false;
  }

  repopulateLineItems(updatedRecordId) {
    this.isLoading = false;
    notifyRecordUpdateAvailable([{ recordId: updatedRecordId }]);
    refreshApex(this.listInfoResults);
    this.template.querySelector('.editModal').toggleModal();
    this.dispatchEvent(new ShowToastEvent(
      {
        name: 'Submit Success',
        message: 'Record was successfully saved',
        variant: 'success',
        mode: 'dismissible'
      }
    ));
  }

  saveQuoteLine = (event) => {
    event.stopPropagation();
    this.isLoading = true;
    this.refreshDataGrid();

  };
  //method to validate inline edit inputs
  async validateChanges(draftValues) {
    let isValid = true;
    let errors = { rows: {}, table: {} };
    draftValues.forEach((value) => {
      if (parseInt(value.Quantity) < 1) {
        errors.rows[value.Id] = {
          title: 'We found 1 error.',
          messages: ['Enter a Quantity greater than 1.'],
          fieldNames: ['Quantity']
        };
        isValid = false;
      }
    });
    if (!isValid) {
      errors.table.title =
        'Your entry cannot be saved. Fix the errors and try again.';
      errors.table.messages = ['Enter valid Quantity values.'];
      this.draftErrors = errors;
    }
    if (this.objectApiName == 'Cart__c' && isValid) {
     
      this.getRequiredAddOns().then((requiredProductOptions) => {
        requiredProductOptions = requiredProductOptions || []; 
        for (let inputItem of draftValues) {
          // Find the corresponding item in lineItemsJSON based on Id
          let lineItem = this.lineItems.find(item => item.Id === inputItem.Id);
          // Check if the item exists and has a Kit_Number_this_Item_Belongs_to value
          if (lineItem && lineItem.Kit_Number_this_Item_Belongs_to !== null) {
            let matchedOption = requiredProductOptions.find(option => { return option.SBQQ__OptionalSKU__c === lineItem.product });
            if (matchedOption && matchedOption.SBQQ__Required__c && matchedOption.SBQQ__Feature__r.Name === 'Sales Addons') {
              let parentLine = this.lineItems.find(item => item.CatClass === lineItem.Kit_Number_this_Item_Belongs_to);
              if (parentLine.Quantity > inputItem.Quantity) {
                let isRentalOrSales = lineItem?.Sale_Price != undefined && lineItem?.Sale_Price != null ? 'Sales' : 'Rental';
                isValid = false;
                errors.rows[lineItem.Id] = {
                  title: 'We found 1 error.',
                  messages: ['Quantity must be greater than or equal to the quantity of the Rental Item this Add On is associated to.'],//SF-6258 error message for lineitem view on Cart
                  fieldNames: ['Quantity']
                };
              }
            }// Check if the Kit_Number_this_Item_Belongs_to value is present in lineItemsJSON
            else if (this.lineItems.some(item => item.CatClass === lineItem.Kit_Number_this_Item_Belongs_to)) {
              isValid = false;
              errors.rows[lineItem.Id] = {
                title: 'We found 1 error.',
                messages: ['Quantity cannot be edited for Cart for KITS'],
                fieldNames: ['Quantity']
              };
            }
          }
        }

      if (!isValid) {
        errors.table.title = 'Your entry cannot be saved. Fix the errors and try again.';
        errors.table.messages = ['Your entry cannot be saved. Fix the errors and try again.'];
        this.draftErrors = errors;
      }
    });

    }
    return isValid;
  }

  //method for CSP - this is called when account is added/removed from line items page on PI/Cart
  verifyCSP(rateItems) {
    this.showSetRatesBanner = false;
    this.showDNEBanner = false;
    this.showPricingUpdatedBanner = false;
    this.showPercentBanner = false;
    this.showSpecialRateBanner = false;
    rateItems.forEach((rateItem, index) => {
      let rateFlag = rateItem.rateFlag;
      let notToExceed = rateItem.notToExceed;
      if (rateFlag == 'Y') {
        switch (notToExceed) {
          case 'S':
            this.showSetRatesBanner = true;
            break;
          case 'X':
            this.showDNEBanner = true;
            break;
          case 'P':
            this.showPercentBanner = true;
            break;
          case '':
            this.showSpecialRateBanner = true;
            break;
          default:
            break;
        }
        this.invokeCSP();
      }
    });

  }

  showToast(t, m, v) {
    let variant = v == '' ? 'info' : v;
    const event = new ShowToastEvent({
      title: t,
      message: m,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  handleItemActionMethod(event) {
    let buttonName = event.detail.buttonName;
    this.itemsToRemove = event.detail.selectedRows;

    if (buttonName === 'remove') {
      this.toggleRemoveModal();
    } else if (buttonName === 'removeOneItem') {
      this.itemToRemove = event.detail.selectedRows;
      this.toggleMobileRemoveModal();
    } else if (buttonName === 'bulkEdit') {
      if (event.detail.isRental === 'true') {
        this.bulkEditRows = this.rentalLineItems;
        this.isSales = false;
      } else if (event.detail.isSales === 'true') {
        this.bulkEditRows = this.salesLineItems;
        this.isSales = true;
      }
      this.toggleBulkEdit();
    }
  }

  handleRowActionMethod(event) {
    this.handleRowAction(event.detail.newEvent);
  }

  handleRowSaveMethod(event) {
    this.handleSave(event.detail.newEvent);
  }

  removeOneItem = (event) => {
    let item = String(this.itemToRemove)
    if (!this.recordId) {
      if (this.clearCartAction) {
        this.clearLineItems();
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Line Items deleted.',
            variant: 'success'
          })
        );
        this.resetFooterData();
        this.clearCartAction = false;
      } else {
        const rows = this.lineItems;
        const rowIndex = rows.findIndex((r) => r.Id == item);
        // Check if the item is a parent with child items
        if (this.lineItems[rowIndex]?.hasKit) { //SF-8154
          // Find child items with matching kitNumberBelongsTo
          const childItems = this.lineItems.filter((item) => item.kitNumberBelongsTo === this.lineItems[rowIndex].CatClass);
          // Remove child items
          childItems.forEach((childItem) => {
            const childIndex = this.lineItems.findIndex((r) => r.Id === childItem.Id);
            if (childIndex !== -1) {
              this.lineItems.splice(childIndex, 1);
            }
          });
        }

        rows.splice(rowIndex, 1);
        this.lineItems = rows;
        //SF-8154
        this.updateLineItemsTable();
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Line Items deleted.',
            variant: 'success'
          })
        );
      }
    }

    if (this.recordId) {
      if (
        this.objectApiName === 'Order' ||
        this.objectApiName === 'SBQQ__Quote__c'
      ) {
        deleteLineItems({ lineIds: [item] })
          .then((data) => {
            refreshApex(this.listInfoResults);
            this.beginRefresh();
            this.lineItems = this.lineItems.filter(item => item.Id !== this.itemToRemove.Id);
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Success',
                message: 'Line Items deleted.',
                variant: 'success'
              })
            );
          })
          .catch((error) => {
						
						let message = error.message;
            if (message.includes('Quotes may only be edited if Status =') ) {
                message = 'Quotes may only be edited if Status is Draft or by Sales Managers if Status is In Review ';
            } 						
						
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error deleting Line Items',
                message: message,
                variant: 'error'
              })
            );
          });
      }
      else {
        // cart item
        deleteRecord(item)
          .then(() => {
            refreshApex(this.listInfoResults);
            this.beginRefresh();
            this.lineItems = this.lineItems.filter(item => item.Id !== this.itemToRemove.Id);
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Success',
                message: 'Line Items deleted.',
                variant: 'success'
              })
            );
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error deleting record',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
      }
    }
    this.template.querySelector('.removeOneItemModal').toggleModal();
  }

  removeItems = (event) => {
    event.stopPropagation();

    if (this.isMobile) {
      let removeItemsIndexArray = [];
      let recordIdsToDelete = [];
      let selectedRows = [];
      this.lineItems.forEach((item, index) => {
        if (item._isChecked) {
          removeItemsIndexArray.push(index);
          selectedRows.push(item.Id);
        }
      });
      for (let i = removeItemsIndexArray.length - 1; i >= 0; i--) {
        let currIndex = removeItemsIndexArray[i];
        recordIdsToDelete.push(this.lineItems[currIndex].Id);
        // this.lineItems.splice(currIndex, 1);
      }
      if (!this.recordId) {
        // change  for bug SAL-13446
        this.lineItems = this.lineItems.filter(
          (row) => !selectedRows.includes(row.Id)
        );
        //change end for bug SAL-13446
        this.updateLineItemsTable();
        this.sendIsCartEmpty();
      }

      if (this.recordId) {
        let removeItemRows;
        //SAL-26002
        if (
          this.objectApiName === 'Order' ||
          this.objectApiName === 'SBQQ__Quote__c'
        ) {
          deleteLineItems({ lineIds: selectedRows })
            .then((data) => {
              refreshApex(this.listInfoResults);
              this.beginRefresh();
              this.lineItems = this.lineItems.filter(
                (row) => !selectedRows.includes(row.Id)
              );
              this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Success',
                  message: 'Line Items deleted.',
                  variant: 'success'
                })
              );
            })
            .catch((error) => {

              let message = error.message;
              if (message.includes('Quotes may only be edited if Status =') ) {
                  message = 'Quotes may only be edited if Status is Draft or by Sales Managers if Status is In Review ';
              } 	

              this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Error deleting Line Items',
                  message: message,
                  variant: 'error'
                })
              );
            });
        } else {
        }
      }
      this.template.querySelector('.removeModal').toggleModal();
    } else {
      this.isLoading = true;
      let selectedRows = this.itemsToRemove;
      for (const item of this.lineItems) {
        if (selectedRows.includes(item.Id)) {
          const matchingRecords = this.lineItems.find(record => record.Kit_Number_this_Item_Belongs_to === item.CatClass);
          //if parent is selected (as item) add all forcedItems to delete
          if (item?.hasKit && matchingRecords.length > 0) {
            // If item.hasKit is true and there are matching records, push their Id values into selectedRows
            for (const matchingRecord of matchingRecords) {
              selectedRows.push(matchingRecord.Id);
            }
          }
          else if (item?.forcedItem) {
            // If the item is a child with forcedItem true and its parent hasKit false, remove it from selectedRows
            const parentRecord = this.lineItems.filter(record => record.CatClass === item.Kit_Number_this_Item_Belongs_to);
            if (parentRecord && !parentRecord?.hasKit && !(item?.Name == 'Fuel Convenience Charge')) { //SF-5879
              const indexToRemove = selectedRows.indexOf(item.Id);
              if (indexToRemove !== -1) {
                selectedRows.splice(indexToRemove, 1);
              }
              this.dispatchEvent(
                new ShowToastEvent({
                  title: 'Error deleting Line Items',
                  //message: error.body.message,
                  message: 'Cannot be removed  ' + item?.Name,
                  variant: 'error'
                })
              );
              this.isLoading = false;
            }
          }
        }
      }
      let removeItemRows;

      //26002
      if (
        (this.objectApiName === 'Order' ||
          this.objectApiName === 'SBQQ__Quote__c') && selectedRows.length > 0
      ) {
        deleteLineItems({ lineIds: selectedRows })
          .then((data) => {
            refreshApex(this.listInfoResults);
            this.beginRefresh();
            this.lineItems = this.lineItems.filter(
              (row) => !selectedRows.includes(row.Id)
            );
            this.updateLineItemGridData(this.lineItems);
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Success',
                message: 'Line Items deleted.',
                variant: 'success'
              })
            );
            this.isLoading = false;
          })
          .catch((error) => {
            let errMsg = JSON.stringify(error);
            if (errMsg.includes('INSUFFICIENT_ACCESS_OR_READONLY')) {
              errMsg = 'You do not have sufficient rights to delete the item(s)';
            }
             if (errMsg.includes('Quotes may only be edited if Status =') ) {
                errMsg = 'Quotes may only be edited if Status is Draft or by Sales Managers if Status is In Review ';
            } 	

            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error deleting Line Items',
                //message: error.body.message,
                message: errMsg,
                variant: 'error'
              })
            );
            this.isLoading = false;
          });
      } else {
      }
      this.template.querySelector('.removeModal').toggleModal();
    }
  };
  //method to toggle line item editor on mobile
  editLineItemHandler(event) {
    this.lineId = event.target.getAttribute('id').slice(0, 18);
    this.itemListDisplay = false;
    this.lineItemEditorDisplay = true;
    this.selectedItemGroup = event.target.getAttribute('data-groupid');
    this.template
      .querySelector('c-sbr_3_0_line-item-editor-cmp')
      .populateLineData(this.lineId, this.selectedItemGroup, this.recordId, this.lineItems);
  }

  //method to toggle item selected sticky footer when line items are selected/deselected
  handleRowSelection(event) {
    let r = event.target;
    let i = this.lineItems.findIndex((e) => e.Id === r.value);
    this.lineItems[i]._isChecked = r.checked;
    this.removeNotChecked = false;
  }
  //method to handle actions in the selection panel on mobile
  selectionPanelActions(event) {
    switch (event.target.value) {
      case 'selectAll':
        this.lineItems.forEach((item) => (item._isChecked = true));
        break;
      case 'remove':
        this.removeItems();
        break;
    }
  }
  toggleRemoveModal() {
    this.template.querySelector('.removeModal').toggleModal();
  }
  toggleMobileRemoveModal() {
    this.template.querySelector('.removeOneItemModal').toggleModal();
  }
  toggleBulkEdit() {
    let cspSet = new Set();
    this.CSP = null;
    this.CSP_msg = null;
    this.template
      .querySelector('c-sbr_3_0_custom-data-table-edit-cmp')
      .clearDrafts();
    this.lineItems.forEach((item) => {
      if (this.isSales && item.AddedByCrewExpense) {
        this.showSalesMiscError = true;
        this.CSP_msg =
          'Crew & Expense Calculator was used to add Sales/Misc line items. Please return to that section to make edits';
      } else {
        if (item.Specific_Pricing_Type == 'Set Rates') {
          this.CSP = 'Set Rates';
          this.CSP_msg = 'Customer has Set Rates. Bulk Edit not available.';
        } else if (
          this.CSP != 'Set Rates' &&
          item.Specific_Pricing_Type == 'Do Not Exceed'
        ) {
          this.CSP = 'Do Not Exceed';
          this.CSP_msg =
            'Customer has Do Not Exceed Rates. Rates increases not allowed, but can be lowered.';
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        } else if (
          this.CSP != 'Set Rates' &&
          item.Specific_Pricing_Type == 'Percent Off Local Book'
        ) {
          this.CSP = 'Percent Off Local Book';
          this.CSP_msg =
            'Customer has Percent off Local Book Rates. Rates increases not allowed, but can be lowered.';
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        } else if (
          this.CSP != 'Set Rates' &&
          item.Specific_Pricing_Type == 'Customer Loaded'
        ) {
          this.CSP = 'Customer Loaded';
          this.CSP_msg = 'Customer has special rates.';
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        }
      }
    });

    if (this.showSalesMiscError) {
      this.template.querySelector('.bulkEditModalError').toggleModal();
    }

    if (cspSet.size > 1 && this.CSP != 'Set Rates') {
      this.CSP = 'Multiple Customer Special Pricing Detected';
      this.CSP_msg =
        'Customer Special pricing has been applied. Please review line item details for more information.';
      this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
    } else if (cspSet.size == 1 && this.CSP != 'Set Rates') {
      this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
    }

    if (this.CSP == 'Set Rates') {
      this.template.querySelector('.bulkEditModalError').toggleModal(); // opens error
    }

    if (!this.CSP && !this.showSalesMiscError) {
      this.template.querySelector('.bulkEditModal').toggleModal();
    }
  }
  showBulkEdit = (event) => {
    event.stopPropagation();
    this.template.querySelector('.bulkEditModalWarning').toggleModal(); // closes warning
    this.template.querySelector('.bulkEditModal').toggleModal(); // open bulk edit
  };
  hideBulkEdit = (event) => {
    event.stopPropagation();
    this.template.querySelector('.bulkEditModal').toggleModal(); // open bulk edit
    refreshApex(this.listInfoResults); //SAL-26168 Refresh Change
  };
  mobileEditQuantity(event) {
    let updatedLineId = event.target.dataset.lineid;
    let updatedQuantity = event.target.value;

    if (updatedQuantity >= 1) {
      this.lineItems.forEach((line) => {
        if (line.Id === updatedLineId) {
          line.Quantity = parseInt(updatedQuantity);
        }
      });
      this.updateLineItemsTable();
    } else {
      this.showToast(
        'Invalid Quantity',
        'Please enter a quantity greater than or equal to 1',
        'error'
      );
    }
  }
  async mobileQuantity(event) { //modified existing for SF-5291,SF-5292
    let updatedLineId = event.detail.lineid;
    let updatedQuantity = event.detail.quantity;
    let updatedCatClass = event.detail.catclass;
    let secondItemId; // To store the Id when Kit_Number_this_Item_Belongs_to matches
    // query product options for addons - SF-5330
    this.getRequiredAddOns().then((productOptions) => {
      productOptions = productOptions || []; 
      if (updatedQuantity >= 1) {
        try {
          // check if updated line is Required sales addon and quantiy is greater than parent otherwise throw error
          const currentLine = this.lineItems.find(item => item.Id === updatedLineId);
          const parentLine = this.lineItems.find(item => item.CatClass === currentLine.Kit_Number_this_Item_Belongs_to);
          let matchedOption = productOptions.find(option => { return option.SBQQ__OptionalSKU__c === currentLine.product });
          if (matchedOption && matchedOption?.SBQQ__Feature__r?.Name === 'Sales Addons' && parentLine?.Quantity > updatedQuantity) {
            throw new Error('Quantity must be greater than or equal to the quantity of the Rental Item this Add On is associated to.');//SF-6258
          }
          this.lineItems.forEach((line) => {
            if (line.Id === updatedLineId) {
              line.Quantity = parseInt(updatedQuantity);
            }
            if (line.Kit_Number_this_Item_Belongs_to === updatedCatClass) {
              secondItemId = line.Id; // Store the Id for the second condition
            }
          });
          if (this.objectApiName == undefined) {
            this.updateLineItemsTable();
          }
          else if (this.objectApiName !== undefined) {
            // If objectApiName is defined, update the record with updatedLineId
            let fields = { Id: updatedLineId };
            fields['Quantity__c'] = updatedQuantity;
            let recordInput = { fields };

            updateRecord(recordInput)
              .then(() => {
                this.dispatchEvent(
                  new ShowToastEvent({
                    title: 'Success',
                    message: 'Line Items edited.',
                    variant: 'success'
                  })
                );
                this.updateLineItemsTable();
              })
              .catch((error) => {
                this.dispatchEvent(
                  new ShowToastEvent({
                    title: 'Error editing Line Items',
                    message: 'Error editing Line Items',
                    variant: 'error'
                  })
                );
              });

            // If secondItemId is defined, update the record with the secondItemId
            if (secondItemId) {
              const matchingItems = this.lineItems.filter(item => item.Kit_Number_this_Item_Belongs_to === updatedCatClass);

              // Update Quantity field for matching items
              matchingItems.forEach(item => {
                let matchedOption = productOptions.find(option => { return option.SBQQ__OptionalSKU__c === item.product });
                // For Sales Addons update child quantity only if new quantity is greater
                if (matchedOption && matchedOption?.SBQQ__Feature__r?.Name == 'Sales Addons' && updatedQuantity > item.Quantity) {
                  item.Quantity = updatedQuantity;
                } else if (matchedOption && matchedOption?.SBQQ__Feature__r?.Name == 'Rental Addons') {
                  item.Quantity = matchedOption.SBQQ__Quantity__c * updatedQuantity;
                }
              });
              let secondEditLineItems = matchingItems.map(item => {
                const quantityFieldName = this.getQuantityFieldName(this.objectApiName);
                let fields = { Id: item.Id };
                fields[quantityFieldName] = item.Quantity;
                let recordInput = { fields };
                return updateRecord(recordInput);
              });
              Promise.all(secondEditLineItems)
                .then((secondEditedItems) => {

                })
                .catch((secondEditError) => {
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: 'Error editing Line Items',
                      message: 'Error editing Line Items',
                      variant: 'error'
                    })
                  );
                });

            }

          }
        } catch (error) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error editing Line Items',
              message: error.message,
              variant: 'error'
            })
          );
        }
      } else {
        this.showToast(
          'Invalid Quantity',
          'Please enter a quantity greater than or equal to 1',
          'error'
        );
      }
    });
  }
  get isQuoteOrOrder() {
    return this.isQuote || this.isOrder;
  }

  get isQuote() {
    if (this.objectApiName == 'SBQQ__Quote__c') {
      return true;
    } else {
      return false;
    }
  }

  get isOrder() {
    if (this.objectApiName == 'Order') {
      return true;
    } else {
      return false;
    }
  }

  get isCart() {
    return this.objectApiName == 'Cart__c';
  }

  get isPI() {
    return !this.objectApiName;
  }

  get isRateQuote() {
    return (
      this.objectApiName == 'SBQQ__Quote__c' &&
      this.recordTypeName == 'Rate Quote'
    );
  }

  get isQuote() {
    return this.objectApiName == 'SBQQ__Quote__c';
  }
  get hasAddOns() {
    return this.hasAddOns;
  }
  get disableRemoveItem() {
    return this._disableRemoveItem;
  }
  get disableBulkEdit() {
    if (this.objectApiName === 'Order') {
      if (this.orderDiscount > 0) {
        return true;
      } else {
        return this.lineItems.length <= 0;
      }
    } else {
      return this.lineItems.length <= 0;
    }
  }
  get selectedRowsCount() {
    return this.lineItems.reduce(
      (accumulator, currentValue) =>
        currentValue._isChecked ? accumulator + 1 : accumulator,
      0
    );
  }
  get itemSelected() {
    let notSelected = false;
    this.lineItems.forEach((item) => {
      if (item._isChecked) {
        notSelected = true;
      }
    });
    return notSelected;
  }
  get itemListDisplayClass() {
    return this.itemListDisplay
      ? 'hidden-mob-container show'
      : 'hidden-mob-container';
  }
  get lineItemEditorDisplayClass() {
    return this.lineItemEditorDisplay
      ? 'hidden-mob-container show'
      : 'hidden-mob-container';
  }
  showKitComponents(event) {
    let index = Number(event.currentTarget.dataset.id);
    this.getKitItems(this.lineItems[index], index);
  }

  showNotes(event) {
    let index = Number(event.currentTarget.dataset.id);
    this.lineItems[index].showNoteItem = !this.lineItems[index].showNoteItem;
  }

  async getKitItems(lineItem, index) {
    let data = [];
    try {
      let productId = lineItem.product ? lineItem.product : lineItem.Product;
      data = await getProductKitComponents({
        productId: JSON.parse(JSON.stringify(productId))
      });
      data = JSON.parse(data);

      this.lineItems[index].showKitItem = !this.lineItems[index].showKitItem;
      if (this.lineItems[index].kitItems.kitItemsValue.length == 0) {
        this.lineItems[index].kitItems.kitItemsValue = data;
      }
    } catch (error) {
      console.log('Error fetching kit items ' + JSON.stringify(error));
    }
  }

  get itemsDynamicLabel() {
    return 'Items (' + this.displayedLineItems.length + ')';
  }

  get rentalItemsDynamicLabel() {
    return this.isMobile
      ? 'Rental (' + this.rentalLineItems.length + ')'
      : 'Rental Items (' + this.rentalLineItems.length + ')';
  }
  get salesMiscItemsDynamicLabel() {
    return this.isMobile
      ? 'Sales/Misc (' + this.salesLineItems.length + ')'
      : 'Sales/Misc Items (' + this.salesLineItems.length + ')';
  }
  get deliveryItemsDynamicLabel() {
    return this.isMobile
      ? 'Delivery (' + this.deliveryLineItems.length + ')'
      : 'Delivery Items (' + this.deliveryLineItems.length + ')';
  }
  get ancillaryItemsDynamicLabel() {
    return this.isMobile
      ? 'Ancillary (' + this.ancillaryLineItems.length + ')'
      : 'Ancillary Charges (' + this.ancillaryLineItems.length + ')';
  }

  beginRefresh() {
    this.makeCallout = true;
    this.dispatchEvent(new RefreshEvent());
  }
  refreshHandler() {
    return new Promise((resolve) => {
      this.updateLineItemGridData(this.lineItems)
      resolve(true);
    });
  }
  disableSaveBtnHandler() {
    this.template.querySelector('.editModal').disableSaveBtn();
  }

  enableSaveBtnHandler() {
    this.template.querySelector('.editModal').enableSaveBtn();
  }

  addKits(event) {
    let index = event.detail.index;
    let kits = event.detail.kits;
    // Loop through all rentalLineItems
    for (let i = 0; i < this.rentalLineItems.length; i++) {
      if (i === index) {
        // For the specified index, set showKits to true and kitItemsValue to kits
        this.rentalLineItems[i].kitItems.showKits = this.rentalLineItems[i].kitItems?.showKits == true ? false : true;
        this.rentalLineItems[i].kitItems.kitItemsValue = this.rentalLineItems[i].kitItems?.showKits == true ? kits : [];
        // Check if the index matches and update SBQQ__Quantity__c for all elements in kitItemsValue
        for (let j = 0; j < this.rentalLineItems[i].kitItems.kitItemsValue.length; j++) {
          this.rentalLineItems[i].kitItems.kitItemsValue[j].SBQQ__Quantity__c *= this.rentalLineItems[i].Quantity;
        }
      } else {
        // For all other indices, set showKits to false and kitItemsValue to an empty array
        this.rentalLineItems[i].kitItems.kitItemsValue = [];
        this.rentalLineItems[i].kitItems.showKits = false;
      }
    }
  }

  hideExtraGridSections(event) {
    switch (event.detail.grid) {
      case 'rental':
        this.showSalesGrid = false;
        this.showRentalGrid = true;
        this.showDeliveryGrid = false;
        this.showAncillaryGrid = false;
        break;
      case 'sales':
        this.showRentalGrid = false;
        this.showSalesGrid = true;
        this.showDeliveryGrid = false;
        this.showAncillaryGrid = false;
        break;
      case 'delivery':
        this.showRentalGrid = false;
        this.showSalesGrid = false;
        this.showDeliveryGrid = true;
        this.showAncillaryGrid = false;
        break;
      case 'ancillary':
        this.showRentalGrid = false;
        this.showSalesGrid = false;
        this.showDeliveryGrid = false;
        this.showAncillaryGrid = true;
        break;
    }
    this.hideFooterForEdit = true;
  }
  showGridSections() {
    this.showRentalGrid = true;
    this.showSalesGrid = true;
    this.showDeliveryGrid = true;
    this.showAncillaryGrid = true;
    this.hideFooterForEdit = false;
  }
  closeLineItemEditor() {
    this.template.querySelector('c-sbr_3_0_line-items-grid-section-cmp').closeLineItemEditor();
  }
  mobileSaveQuoteLine() {
    this.showSpinner = true;
    this.template.querySelector('c-sbr_3_0_line-items-grid-section-cmp').mobileSaveQuoteLine();
    this.showSpinner = false;
  }

  showToastMessage(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }
  isQuoteSubmitted() {
    return (this.parentRecord?.fields?.Rentalman_Quote_Id__c?.value && this.parentRecord?.fields?.Submitted_to_Wynne__c?.value);
  }
  isOrderSubmitted() {
    return (this.parentRecord?.fields?.Reservation_Order_Number__c?.value && this.parentRecord?.fields?.Submitted_to_Wynne__c?.value)
  }
  getRequiredAddOns() {
    return new Promise((resolve, reject) => {
      let parentSkus = [];
      let optionalSkuIds = [];
      this.lineItems.forEach(item => {
        if (!SBRUtils.isEmpty(item.Kit_Number_this_Item_Belongs_to)) {
          parentSkus.push(item.Kit_Number_this_Item_Belongs_to);
          optionalSkuIds.push(item.product);
        }
      });
      if (parentSkus.length === 0 || optionalSkuIds.length === 0) {
        resolve([]);
      } else {
        getProductOptionForLineItems({
            optionalSKU: optionalSkuIds,
            kitNumber: parentSkus
        }).then((result) => {
              const productOptions = JSON.parse(result);
              if (Array.isArray(productOptions) && productOptions.length === 0) {
                resolve([]);
              } else {
                resolve(productOptions);
              }
          }).catch(error => {
              reject(error);
          });
      }
    });
  }
}