import { LightningElement, api, wire, track } from "lwc";
import {
  updateLineItems,
  LineItemMixin
} from "./sbr_3_0_lineItemsCmpFrontlineHelper.js";
import getLineItemsColumns from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns";
import getProductKitComponents from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import getLineItemEstimates from "@salesforce/apex/SBR_3_0_LineItemCartCmpController.getLineItemEstimates";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import deleteLineItems from "@salesforce/apex/SBR_3_0_LineItemCartCmpController.deleteLineItems";
import sbr_3_0_customDataTableCSS from "@salesforce/resourceUrl/sbr_3_0_customDataTable_css";
import getAvailability from "@salesforce/apex/SBR_3_0_API_BranchATP.CheckOrderItemATP"; // FRONT-7422,7423
import { loadStyle } from "lightning/platformResourceLoader";
import {
  getRecord,
  createRecord,
  deleteRecord,
  updateRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { refreshApex } from "@salesforce/apex";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import CART_OBJECT from "@salesforce/schema/Cart__c";
import CART_ITEMS_OBJECT from "@salesforce/schema/Cart_Items__c";
import LOGGEDIN_USER_ID from "@salesforce/user/Id";

import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import pICartLoadedChannel from "@salesforce/messageChannel/PICartLoadedChannel__c";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import updateTotalsChannel from "@salesforce/messageChannel/updateTotalsChannel__c";
import FORM_FACTOR from "@salesforce/client/formFactor";

import {
  registerRefreshHandler,
  unregisterRefreshHandler,
  RefreshEvent
} from "lightning/refresh";
import LABELS from "c/sbr_3_0_customLabelsCmp";

const QUOTE_FIELDS = [
  "SBQQ__Quote__c.OwnerId",
  "SBQQ__Quote__c.RPP_Amount__c",
  "SBQQ__Quote__c.Total_Misc__c",
  "SBQQ__Quote__c.Total_Quoted_Amount__c",
  "SBQQ__Quote__c.Total_Rental_Amount__c",
  "SBQQ__Quote__c.Total_Sales_Amount__c",
  "SBQQ__Quote__c.Total_Sales_Taxes__c",
  "SBQQ__Quote__c.Id",
  "SBQQ__Quote__c.SBQQ__Account__r.RecordType.Name",
  "SBQQ__Quote__c.Is_Edit_In_Progress__c", //FRONT-9237, FRONT-9238
  "SBQQ__Quote__c.Is_Edited_By_Current_User__c" //FRONT-20871
];

const ORDER_FIELDS = [
  "Order.OwnerId",
  "Order.RPP_Amount__c",
  "Order.Total_Misc__c",
  "Order.Total_Rental_Amount__c",
  "Order.Total_Sales_Amount__c",
  "Order.Total_Sales_Taxes__c",
  "Order.Id",
  "Order.Order_Discount__c",
  //Start FRONT-7977
  "Order.Reservation_Order_Number__c",
  "Order.Contract_Order_Number__c",
  "Order.Record_Type_Name__c",
  //End FRONT-7977
  "Order.Status",
  "Order.Account.RecordType.Name",
  //START: FRONT-8736//
  "Order.Branch__r.Analysis_Region2__r.Allow_Header_Discounts__c",
  "Order.Record_Locked__c",
  "Order.Is_Specific_Pricing_Flag__c",
  "Order.Specific_Pricing_Flag__c",
  //END: FRONT-8736//
  //START: FRONT-9235
  "Order.Is_Edit_In_Progress__c",
  //END: FRONT-9235
  "Order.Is_Edited_By_Current_User__c" //FRONT-20871
];

//start FRONT-7977
const USER_FIELDS = [
  "User.Id",
  "User.Name",
  "User.Profile.Name",
  "User.CompanyName"
];
//end FRONT-7977

const CART_FIELDS = ["Cart__c.OwnerId"];
const EXCLUDED_RENTAL_COLUMNS_NAMES = ["Sale_Price", "Quantity", 'Contingency_Cost', 'Seasonal_Multiplier']; //Modified as part of FRONT-2195
//added for 7382
const EXCLUDED_RENTAL_COLUMNS_NAMES_OSR = [
  "Min_Rate2",
  "Sale_Price",
  "Quantity",
  'Contingency_Cost',
  'Seasonal_Multiplier'
]; //Modified as part of FRONT-9233
const EXCLUDED_SALES_COLUMNS_NAMES = [
  "Daily_Rate",
  "Weekly_Rate",
  "Monthly_Rate",
  "Min_Rate2", //added for 7382
  "Total_Qty", //added for 9233
  'Contingency_Cost',
  'Seasonal_Multiplier'
];
const EXCLUDED_DELIVERY_COLUMNS_NAMES = [
  "Daily_Rate",
  "Weekly_Rate",
  "Monthly_Rate",
  "Quantity",
  "Sale_Price",
  "Min_Rate2", //added for 7382
  "Total_Qty", //added for 9233
  'Contingency_Cost',
  'Seasonal_Multiplier'
];
const EXCLUDED_ANCILLARY_COLUMNS_NAMES = [
  "Daily_Rate",
  "Weekly_Rate",
  "Monthly_Rate",
  "Notes",
  "Min_Rate2", //added for 7382
  "Total_Qty", //added for 9233
  'Contingency_Cost',
  'Seasonal_Multiplier'
];

const quoteLineActions = [
  { label: "Product Details", name: "view_line_item" },
  { label: "Edit", name: "edit_quote_line" }
  //{ label: 'Remove', name: 'remove_quote_line' }
];

const orderLineActions = [
  { label: "Product Details", name: "view_line_item" },
  { label: "Substitute Item", name: "substitute_item" }, //FRONT-8772
  { label: "Edit", name: "edit_order_line" }
  //{ label: 'Remove', name: 'remove_order_line' }
];

//start FRONT-7977
const lockedReservationOrderLineActions = [
  { label: "Product Details", name: "view_line_item" } //FRONT-9245
];
//end FRONT-7977

//start FRONT-11421
const readOnlyReservationOrderLineActions = [
  { label: "Product Details", name: "view_line_item" } //FRONT-11421
];
//end FRONT-11421

/* Start  FRONT-1639 */
const orderRentalItemSubstituteLineActions = [
  { label: "Product Details", name: "view_line_item" },
  { label: "Substitute Item", name: "substitute_item" },
  { label: "Cancel Item", name: "Cancel" }
];

/* End  FRONT-1639 */

const editObjectMap = {
  Order: "edit_order_line",
  SBQQ__Quote__c: "edit_quote_line"
};

var userId;
import uId from "@salesforce/user/Id";

import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

export default class Sbr_3_0_lineItemsCmpFrontline extends LineItemMixin(
  NavigationMixin(LightningElement)
) {
  @track selectedRow = {}; //FRONT-6267
  userId = uId;
  @track orderDiscount;
  @track showlineitemComponents = false;
  appName;
  itemsToRemove;
  accName;
  orderStatus; //FRONT-7652,FRONT-7653
  showSubstituteModal = false;
  //START: FRONT-8736
  allowHeader = false;
  isOrderLocked = false;
  isSpecificPricingFlag = false;
  specificPricingFlag = false;
  //END: FRONT-8736
  orderNumber; // Front-9233
  //START FRONT-9235, Modified for FRONT-9237, FRONT-9238
  isRecordEditInProgress = false;
  hideSubtotalonRecordEdit = false;
  //END FRONT-9235, Modified for FRONT-9237, FRONT-9238
  isReadOnlyRecord = false;
  @track cartSalesLineItems = []; //testing purpose for story: FRONT-11378
  callCancel = false;

  @api
  get startDate() {
    return this._startDate;
  }
  set startDate(value) {
    this._startDate = value;
    if (this.columns.length > 0) {
      let subtotalCol = this.columns.find(
        (e) => e.fieldName == "Item_Subtotal"
      );
      subtotalCol.label = `Item Subtotal (${value} to ${this._returnDate})`;
    }
    this.columns = [...this.columns];
    this.getItemEstimates();
  }

  @api
  get startTime() {
    return this._startTime;
  }
  set startTime(value) {
    this._startTime = value;
    this.getItemEstimates();
  }
  //FRONT-6267,FRONT-6266,FRONT-6268 started
  handleToggle() {
    this.template.querySelector(
      "c-sbr_3_0_-line-item-edit-wrapper"
    ).activetabValue = "EditTab";
    this.template.querySelector("c-sbr_3_0_-line-item-edit-wrapper").rates =
      null;
    this.template
      .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
      .callfromparent();
  }
  //FRONT-6267,FRONT-6266,FRONT-6268 ended
  @api
  get returnDate() {
    return this._returnDate;
  }
  set returnDate(value) {
    this._returnDate = value;
    if (this.columns.length > 0) {
      let subtotalCol = this.columns.find(
        (e) => e.fieldName == "Item_Subtotal"
      );
      subtotalCol.label = `Item Subtotal (${this._startDate} to ${value})`;
    }
    this.columns = [...this.columns];
    this.getItemEstimates();
  }
  //FRONT-6266
  get selectedRow() {
    return this.selectedRow;
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
    this.getItemEstimates();
  }

  @api
  get deliveryCpu() {
    return this._deliveryCpu;
  }
  set deliveryCpu(value) {
    this._deliveryCpu = value;
    this.getItemEstimates();
  }

  @api
  get jobsiteZip() {
    return this._jobsiteZip;
  }
  set jobsiteZip(value) {
    this._jobsiteZip = value;
    this.getItemEstimates();
  }

  @api
  get customerInfo() {
    return this._customerInfo;
  }
  set customerInfo(value) {
    if (value) {
      this._customerInfo = value;
      //this._customerInfo = value.selectedRecord;
      let selectedCustomer =
        this._customerInfo && this._customerInfo.RM_Account_Number__c
          ? this._customerInfo.RM_Account_Number__c
          : "";
      let products = this.lineItems.map((item) => item.CatClass);
      //fire only in cart and product inquiry
      if (
        products &&
        products.length > 0 &&
        (this.objectApiName == "Cart__c" || this.objectApiName == undefined)
      ) {
        getProductRates({
          prwrapper: {
            products: products,
            customerNumber: selectedCustomer
          }
        })
          .then((result) => {
            let items = JSON.parse(result).data.items;
            items.forEach((rateItem, index) => {
              this.lineItems[index].Daily_Rate =
                rateItem.rates.suggestedRates.daily;
              this.lineItems[index].Weekly_Rate =
                rateItem.rates.suggestedRates.weekly;
              this.lineItems[index].Monthly_Rate =
                rateItem.rates.suggestedRates.monthly;
            });
            this.updateLineItemsTable();
            let title = "Customer Pricing Adjusted";
            let titleWhenAccountRemoved = "Pricing has been updated";
            if (selectedCustomer == null || selectedCustomer == "") {
              this.showToast(titleWhenAccountRemoved, "", "success");
            } else {
              this.showToast(title, "", "success");
            }
            this.verifyCSP(items);
            this.updateLineItemsTable();
          })
          .catch((error) => {
            console.log(error);
          });
      }
    }
  }

  @api recordId;
  @api objectApiName;
  //Start FRONT-7977
  @track isParentRecordLoaded = false;
  @track parentRecord;
  @track currentUserRecord;
  @track isCurrentUserRecordLoaded = false;
  @track userCompanyCode;
  //End FRONT-7977
  @track updateTotalsRecordId = "";
  @track listInfoRecordId = "";
  @track disableEdit = false;
  isMobile = false;
  isLoading = false;
  _startDate;
  _startTime;
  _returnDate;
  _returnTime;
  _deliveryCpu;
  _jobsiteZip;
  _customerInfo = "";
  _lineItemsCatClassMap = [];
  _disableRemoveItem = true;
  @track lineItems = []; //All Line Items
  @track rentalLineItems = [];
  @track salesLineItems = [];
  @track deliveryLineItems = [];
  @track ancillaryLineItems = [];
  activeSections = [
    "Rental Items",
    "Sales/Misc Items",
    "Delivery Items",
    "Ancillary Items"
  ];
  subscription = null;
  updateTotalsSubscription = null;
  @track columns = [];
  @track rentalColumns = [];
  @track salesColumns = [];
  @track cartSalesColumns = []; //FRONT-11378
  @track deliveryColumns = [];
  @track ancillaryColumns = [];
  recordTypeName = "";
  @track draftValues = [];
  draftErrors;
  @track noItemsMsg = "No items in the cart.";
  showLineItemsTable = false;
  relatedListId = "";
  fields = [];
  lineId = "";
  selectedItemGroup = "";
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
  quoteRecordTypeName = "";
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
  saveButtonLabel = "Confirm";
  lineIdnew;
  groupIdnew;
  recordIdnew;
  isCancel; //FRONt-7653
  showCancelLineItemModal = false; //FRONT-7651
  cancelSelectedRows = [];
  dataForGrid = [];
  disbaleConfirmButton = true; //Added as part of 2195
  availabilityData = new Map(); //FRONT-7422,7423
  @track notes = ''; // Notes Change
  rowId; // Notes Change

  lineItemNotes; //Front-15893
  // test
  estimateRequest = {
    account: 1,
    orderType: "Delivery",
    ratesToBeUsed: "SUGGESTED",
    startDateAndTime: "2023-05-07T09:28:56.321-10:00",
    endDateAndTime: "2023-05-09T09:28:56.321-10:00",
    pc: [
      {
        id: 5105,
        latitude: 47.6044,
        longitude: -122.3345,
        timezone: ""
      }
    ],
    address: [
      {
        type: "jobsite",
        line1: "",
        city: "",
        state: "",
        zip: "20147",
        latitude: -38.9954527,
        longitude: -93.093325
      }
    ],
    delivery: [
      {
        chargesOverride: true,
        charges: "0.00"
      }
    ],
    pickup: [
      {
        chargesOverride: false
      }
    ],
    orderLines: [
      {
        salesItems: [],
        products: []
      }
    ]
  };
  label = LABELS;

  //FRONT-7653
  hasDataLoaded = false;

  @wire(getRecord, { recordId: "$recordId", fields: "$parentFields" })
  wiredRecord({ error, data }) {
    if (data) {
      console.log("Inside wiredRecord");
      this.orderNumber = 2; //Front-9233
      //Start FRONT-7977
      this.parentRecord = data;
      this.isParentRecordLoaded = true;
      //End FRONT-7977
      this.parentRecordOwnerId = data.fields.OwnerId.value;
      this.orderDiscount =
        data.fields.Order_Discount__c != null
          ? data.fields.Order_Discount__c.value
          : 0;
      this.recordTypeName = data?.recordTypeInfo?.name;
      //START: FRONT-7652,FRONT-7653
      if (this.objectApiName === "Order") {
        this.orderStatus = data.fields.Status.value;
        this.accountRecordTypeName =
          data?.fields?.Account?.value?.recordTypeInfo?.name; // FRONT- 7383
        //START: FRONT-8736//
        this.allowHeader =
          data.fields.Branch__r?.value?.fields?.Analysis_Region2__r?.value?.fields?.Allow_Header_Discounts__c?.value;
        this.isOrderLocked = data.fields.Record_Locked__c.value;
        this.isSpecificPricingFlag =
          data.fields.Is_Specific_Pricing_Flag__c.value;
        this.specificPricingFlag = data.fields.Specific_Pricing_Flag__c.value;
        //END: FRONT-8736//
        //START: FRONT-9235 //FRONT-20871
        this.isRecordEditInProgress =
          data.fields.Is_Edit_In_Progress__c.value &&
          data?.fields?.Is_Edited_By_Current_User__c.value;
        //END: FRONT-9235
        this.isReadOnlyRecord = !this.isRecordEditInProgress; //FRONT-11421
        this.handleChevronActionsForLockedReservation(); //FRONT-9245
      }
      //END: FRONT-7652,FRONT-7653
      //START: FRONT- 7383
      else if (this.objectApiName === "SBQQ__Quote__c") {
        this.accountRecordTypeName =
          data?.fields?.SBQQ__Account__r?.value?.recordTypeInfo?.name;
        //FRONT-20871
        this.isRecordEditInProgress =
          data.fields.Is_Edit_In_Progress__c.value &&
          data?.fields?.Is_Edited_By_Current_User__c.value; // FRONT-9237, FRONT-9238
        this.isReadOnlyRecord = !this.isRecordEditInProgress; //FRONT-10503 and FRONT-10504
      }
      //END: FRONT-7383
      getAppName()
        .then((result) => {
          this.appName = result;
          if (this.appName == "RAE Sales") {
            this.showlineitemComponents = true;
          } else {
            this.showlineitemComponents = false;
          }

          console.log("Inside wire method ", this.recordId);
          this.dataForGrid = {
            orderRecordTypeName: this.recordTypeName,
            orderStatus: this.orderStatus,
            appNameFL: this.appName,
            accountRecordTypeName: this.accountRecordTypeName
          };

          //FRONT-7651
          if (this.showCancelChevronBtn()) {
            orderLineActions.push({
              label: "Cancel Item",
              name: "cancel_order_line_item"
            });
          }
        })
        .catch((error) => {
          console.log('catch error-> ', error);
        });

      // SAL-23568
      this.hasDataLoaded = true; //FRONT - 7653
      //refreshApex(this.listInfoResults);
    } else {
      console.log("Error in getRecord:", error);
    }
  }

  //Start FRONT-7977
  @wire(getRecord, { recordId: LOGGEDIN_USER_ID, fields: USER_FIELDS })
  currentUserRecord({ error, data }) {
    if (data) {
      console.log("Inside currentUserRecord");
      this.currentUserRecord = data;
      this.isCurrentUserRecordLoaded = true;
      this.userCompanyCode = data.fields.CompanyName.value;
    } else {
      console.log("Get Current User Record Error:" + JSON.stringify(error));
    }
  }
  //End FRONT-7977

  @wire(getRecord, {
    recordId: "$updateTotalsRecordId",
    fields: "$parentFields"
  })
  updatedTotalsRecord({ error, data }) {
    this.quoteRecordTypeName = data?.recordTypeInfo?.name;
    if (data) {
      console.log("Inside updatedTotalsRecord");
      if (
        this.objectApiName === "SBQQ__Quote__c" ||
        this.objectApiName === "Order"
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
        this.subtotal = (totalRentalAmount + totalSalesAmount).toFixed(2);

        this.charges = (rppAmount + totalMisc).toFixed(2);
        this.tax = totalSalesTax.toFixed(2);
        this.taxAndCharges = (totalSalesTax + rppAmount + totalMisc).toFixed(2);
        if (this.objectApiName === "SBQQ__Quote__c") {
          this.total = (
            data.fields.Total_Quoted_Amount__c.value != null
              ? data.fields.Total_Quoted_Amount__c.value
              : 0
          ).toFixed(2);
          if (this.quoteRecordTypeName == "Rental Quote - Submitted") {
            this.disableEdit = true;
          } else {
            this.disableEdit = false;
          }
        } else
          this.total = (
            totalRentalAmount +
            totalSalesAmount +
            rppAmount +
            totalMisc +
            totalSalesTax
          ).toFixed(2);
      }
    } else {
      console.log("error while updating totals:" + JSON.stringify(error));
    }
  }

  @wire(MessageContext)
  messageContext;
  //method to load columns for the line items datatable

  @wire(getLineItemsColumns, { order: "$orderNumberDetail" }) //Added for FRONT-9233
  lineItemsColumns({ error, data }) {
    if (data) {
      console.log("Inside lineItemsColumns");
      let lineItemsCols;

      var userId = LOGGEDIN_USER_ID;
      if (this.objectApiName === "Cart__c" || this.objectApiName == undefined) {
        lineItemsCols = data.filter((col) => col.Context__c == "Line Item");
        this.cartSalesColumns = data.filter(
          (col) => col.Context__c === "Sales Line Item"
        ); //FRONT-11378

        this.createSalesItemsColumns(this.cartSalesColumns); //FRONT-11378
      } else if (
        this.objectApiName === "SBQQ__Quote__c" ||
        (this.objectApiName === "Order")
      ) {
        lineItemsCols = data.filter(
          (col) => col.Context__c === "Quote Line Item"
        );
      }
      //Front-9233 started
      if (
        this.objectApiName === "Order" &&
        this.orderStatus === "Partially Filled"
      ) {
        let remainingQty = data.filter(
          (col) => col.Context__c === "Order Line Item"
        );
        // Array.prototype.push.apply(remainingQty,[ { cellAttributes: { alignment: 'left' }}]);

        Array.prototype.push.apply(lineItemsCols, remainingQty);
      }
      //Front-9233 ended
      lineItemsCols.sort((a, b) => a.Order__c - b.Order__c);
      lineItemsCols.forEach((col) => {
        let colItem = {};
        colItem.label =
          col.Label === "Item Subtotal"
            ? `${col.Label} (${this._startDate} to ${this._returnDate})`
            : col.Label;
        colItem.fieldName = col.Field_Name__c;
        colItem.hideDefaultActions = true;
        colItem.sortable = col.IsSortable__c;
        if (
          this.objectApiName === "SBQQ__Quote__c" ||
          this.objectApiName === "Order"
        ) {
          colItem.editable =
            userId == this.parentRecordOwnerId && col.IsEditable__c
              ? true
              : false;
        } else {
          colItem.editable = col.IsEditable__c;
        }
        colItem.type = col.Type__c ? col.Type__c : "text";
        /* Start ----  FRONT-1639 */
        colItem.cellAttributes = {
          class: { fieldName: "noAvailability" }
        };
        /* End -----   FRONT-1639 */
        if (colItem.fieldName === "Delete_Item") {
          colItem.typeAttributes = {
            iconName: "utility:delete",
            name: "delete"
          };
          colItem.hideLabel = true;
          colItem.label = "";
        }
        if (col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;
        this.columns.push(colItem);
        //11909
        //Notes Change
        if (colItem.fieldName === "Notes") {
          colItem.type = "buttonIcon";
          //FRONT-15893
          colItem.typeAttributes = {
            iconName: "utility:note",
            class: "notes-icon-color",
            name: !this.isReadOnlyRecord
              ? editObjectMap[this.objectApiName]
              : "view_line_item_notes",
            rowId: { fieldName: "Id" }
          };
          colItem.fieldName = "Notes"
          //FRONT-15893
        }
        if (
          this.objectApiName === "SBQQ__Quote__c" &&
          colItem.fieldName === "Name"
        ) {
          colItem.wrapText = true;
          if (!this.isReadOnlyRecord) {
            //FRONT-10503
            colItem.typeAttributes = {
              label: { fieldName: "Name" },
              fieldName: "Name",
              name: "edit_quote_line",
              target: "_blank",
              variant: "base"
            };
          } else {
            //Start: FRONT-10503
            colItem.typeAttributes = {
              label: { fieldName: "Name" },
              fieldName: "Name",
              variant: "base",
              disabled: { fieldName: "disableNameColumn" },
              class: { fieldName: "disabledTextColor" }
            };
          } //End: FRONT-10503
        }
        //11909
        if (this.objectApiName === "Order" && colItem.fieldName === "Name") {
          colItem.wrapText = true;
          if (!this.isReadOnlyRecord) {
            colItem.typeAttributes = {
              label: { fieldName: "Name" },
              fieldName: "Name",
              name: "edit_order_line",
              target: "_blank",
              variant: "base",
              disabled: { fieldName: "disableNameColumn" }, //FRONT-1950
              class: { fieldName: "disabledTextColor" } //FRONT-10473
            };
          } else {
            colItem.typeAttributes = {
              label: { fieldName: "Name" },
              fieldName: "Name",
              variant: "base",
              disabled: { fieldName: "disableNameColumn" }, //FRONT-1950
              class: { fieldName: "disabledTextColor" } //FRONT-10473
            };
          }
        }
      });

      if (
        this.objectApiName == undefined ||
        this.objectApiName == "Cart__c" ||
        this.objectApiName == "SBQQ__Quote__c" ||
        this.objectApiName == "Order"
      ) {
        this.columns.unshift({
          label: "",
          fieldName: "kitItems",
          hideDefaultActions: true,
          sortable: true,
          type: "kit",
          wrapText: true,
          fixedWidth: 20,
          /* Start ----  FRONT-1639 */
          cellAttributes: {
            class: { fieldName: "noAvailability" }
          }
          /* End -----   FRONT-1639 */
        });
      }
      //FRONT-6268
      if (this.objectApiName === "SBQQ__Quote__c") {
        if (!this.isReadOnlyRecord) {
          //FRONT-10503 and FRONT-10504
          this.columns.push({
            type: "action",
            typeAttributes: {
              rowActions: quoteLineActions,
              menuAlignment: "auto"
            }
          });
        } else {
          //Start FRONT-10503 and 10504
          this.columns.push({
            type: "action",
            typeAttributes: {
              rowActions: readOnlyReservationOrderLineActions,
              menuAlignment: "auto"
            }
          });
        } //End FRONT-10503 and 10504
      } else if (this.objectApiName === "Order") {
        this.columns.push({
          type: "action",
          typeAttributes: {
            rowActions: orderLineActions,
            menuAlignment: "auto"
          },
          /* Start ----  FRONT-1639 */
          cellAttributes: {
            class: { fieldName: "noAvailability" }
          }
          /* End -----   FRONT-1639 */
        });
      }
      // parsing columns

      //added for 7382

      if (this.showlineitemComponents == true || this.isMobile == true) {
        //start for 9233
        if (
          this.objectApiName === "Order" &&
          this.orderStatus !== "Partially Filled"
        ) {
          let z = [...EXCLUDED_RENTAL_COLUMNS_NAMES_OSR];
          z.splice(z.indexOf("Quantity"), 1);
          this.rentalColumns = this.columns.filter(
            (col) => !z.includes(col.fieldName)
          );
        } else {
          let r = [...EXCLUDED_RENTAL_COLUMNS_NAMES_OSR];
          this.rentalColumns = this.columns.filter(
            (col) => !r.includes(col.fieldName)
          );
        }
        //end for 9233
        //FRONT-1674
        if (this.objectApiName === "Order" && this.isMobile) {
          // Modified for FRONT-9233
          const column = {
            label: "",
            fieldName: "noAvailabilityIcon",
            hideDefaultActions: true,
            sortable: true,
            type: "iconTooltip",
            fixedWidth: 20,
            typeAttributes: {
              iconName: { fieldName: "noAvailabilityIcon" }, //  FRONT-1639
              iconVariant: "error",
              iconSize: "x-small",
              tooltip:
                "This Cat-Class Item is no longer available. Update item by selecting a substitute or cancel item" //FRONT-8793
            },
            cellAttributes: {
              class: { fieldName: "noAvailability" }
            }
          };
          const column2 = {
            fieldName: "tooltipClicked"
          };
          const newNumbers = [
            ...this.rentalColumns.slice(0, 1),
            column,
            column2,
            ...this.rentalColumns.slice(1)
          ];
          this.rentalColumns = newNumbers;
          this.rentalColumns.pop(); // remove the default actions added
          this.rentalColumns.push({
            type: "action",
            typeAttributes: {
              rowActions: this.getRowActions.bind(this), //add the actions dynamically
              menuAlignment: "auto"
            },
            cellAttributes: {
              class: { fieldName: "noAvailability" }
            }
          });
        } else if (
          this.objectApiName === "Order" ||
          this.objectApiName === "SBQQ__Quote__c"
        ) {
          //FRONT-11845
          const column = {
            label: "",
            fieldName: "noAvailabilityIcon",
            hideDefaultActions: true,
            sortable: true,
            type: "iconTooltip",
            fixedWidth: 20,
            typeAttributes: {
              iconName: { fieldName: "noAvailabilityIcon" },
              iconVariant: "error",
              iconSize: "x-small",
              tooltip:
                "This Cat-Class Item is no longer available. Update item by selecting a substitute or cancel item" //FRONT-8793
            },
            cellAttributes: {
              class: { fieldName: "noAvailability" }
            }
          };
          const column2 = {
            fieldName: "tooltipClicked"
          };
          const newNumbers = [
            ...this.rentalColumns.slice(0, 1),
            column,
            column2,
            ...this.rentalColumns.slice(1)
          ];
          //FRONT-12021 Added this section to set rowActions for RAE Sales app on desktop.FRONT-10503
          this.rentalColumns.pop();
          this.rentalColumns.push({
            type: "action",
            typeAttributes: {
              rowActions: this.getRowActions.bind(this),
              menuAlignment: "auto"
            }
          });
          this.salesColumns.pop(); //Start: FRONT-10503 and 10504
          this.salesColumns.push({
            type: "action",
            typeAttributes: {
              rowActions: this.getRowActions.bind(this),
              menuAlignment: "auto"
            }
          }); //END: FRONT-10503 and 10504
        }
      }
      //added for 7382
      else {
        //Front- 9233 started
        let y = [...EXCLUDED_RENTAL_COLUMNS_NAMES];
        if (this.objectApiName === "SBQQ__Quote__c" ||
          (this.objectApiName === "Order" &&
            this.orderStatus != "Partially Filled")
        ) {
          y.splice(y.indexOf("Quantity"), 1);
          this.rentalColumns = this.columns.filter(
            (col) => !y.includes(col.fieldName)
          );
        } else {
          let x = [...EXCLUDED_RENTAL_COLUMNS_NAMES];

          this.rentalColumns = this.columns.filter(
            (col) => !x.includes(col.fieldName)
          );
        }
        //Front- 9233 ended
        /* Start ----  FRONT-1639 */
        if (this.objectApiName === "Order") {
          const column = {
            label: "",
            fieldName: "noAvailabilityIcon",
            hideDefaultActions: true,
            sortable: true,
            type: "iconTooltip",
            fixedWidth: 30, // FRONT-10473
            typeAttributes: {
              iconName: { fieldName: "noAvailabilityIcon" },
              iconVariant: { fieldName: "errorClickedIconVariant" }, //ADDED FOR FRONT-11845
              iconSize: "x-small",
              tooltip:
                "This Cat-Class Item is no longer available. Update item by selecting a substitute or cancel item" //FRONT-8793
            },
            cellAttributes: {
              class: { fieldName: "noAvailability" }
            }
          };
          const newNumbers = [
            ...this.rentalColumns.slice(0, 1),
            column,
            ...this.rentalColumns.slice(1)
          ];
          //START FRONT-1950
          const column1 = {
            label: "",
            fieldName: "tooltipClickedIcon",
            hideDefaultActions: true,
            sortable: true,
            type: "iconTooltip",
            fixedWidth: 30, // FRONT-10473
            typeAttributes: {
              iconName: { fieldName: "tooltipClickedIcon" },
              iconVariant: { fieldName: "tooltipClickedIconVariant" },
              iconSize: "x-small",
              tooltip: { fieldName: "tooltipClickedText" }
            }
          };
          const newNumbersPartiallyFilled = [
            column1,
            column,
            ...this.rentalColumns.slice(1)
          ];
          if (this.orderStatus !== "Partially Filled") {
            this.rentalColumns = newNumbers;
          } else {
            this.rentalColumns = newNumbersPartiallyFilled;
          }
          //END FRONT-1950
          this.rentalColumns.pop(); // remove the default actions added
          this.rentalColumns.push({
            type: "action",
            typeAttributes: {
              rowActions: this.getRowActions.bind(this), //add the actions dynamically
              menuAlignment: "auto"
            },
            cellAttributes: {
              class: { fieldName: "noAvailability" }
            }
          });
        }

        /* End ----  FRONT-1639 */
      }

      this.salesColumns = this.columns.filter(
        (col) => !EXCLUDED_SALES_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.deliveryColumns = this.columns.filter(
        (col) => !EXCLUDED_DELIVERY_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.ancillaryColumns = this.columns.filter(
        (col) => !EXCLUDED_ANCILLARY_COLUMNS_NAMES.includes(col.fieldName)
      );

      //START: FRONT-11136 For Reservation Order, hiding the action options for locked reservation. The assigments above this section reset all the action items, so need this section.
      if (this.objectApiName === "Order") {
        this.handleChevronActionsForLockedReservation();
      }
      //END: FRONT-11136

      //START: FRONT-11421 Removing checkbox column when record is readonly
      if (
        (this.objectApiName === "Order" ||
          this.objectApiName === "SBQQ__Quote__c") && //FRONT-10503 and FRONT-10504
        this.isReadOnlyRecord &&
        this.recordTypeName === "Reservation Order"
      ) {
        this.rentalColumns = this.rentalColumns.slice(1);
        this.salesColumns = this.salesColumns.slice(1);
        this.deliveryColumns = this.deliveryColumns.slice(1);
        this.ancillaryColumns = this.ancillaryColumns.slice(1);
      }
      //END: FRONT-11421

      //START: FRONT-9235 - hiding subtotal columns when order is is edit mode
      if (
        (this.objectApiName === "Order" ||
          this.objectApiName === "SBQQ__Quote__c") &&
        this.isRecordEditInProgress &&
        this.appName === "RAE Frontline"
      ) {
        //FRONT-9237, FRONT-9238
        this.hideSubtotalonRecordEdit = true;
        this.rentalColumns = this.rentalColumns.filter(
          (column) => column.fieldName !== "Item_Subtotal"
        );
        this.salesColumns = this.salesColumns.filter(
          (column) => column.fieldName !== "Item_Subtotal"
        );
      }
      //END: FRONT-9235
      /* FRONT-24214 : Removing substitute lineItems from Sales/Misc actions */
      this.salesColumns = this.formatSalesColumns(this.salesColumns);
      this.updateLineItemsTable();
    } else if (error) {
      console.log(error);
    }
  }

  get parentFields() {
    switch (this.objectApiName) {
      case "SBQQ__Quote__c":
        return QUOTE_FIELDS;
      case "Order":
        return ORDER_FIELDS;
      case "Cart__c":
        return CART_FIELDS;
    }
  }

  //method to load child line item records when component is loaded in record context
  @wire(getRelatedListRecords, {
    parentRecordId: "$listInfoRecordId",
    relatedListId: "$relatedListId",
    fields: "$fields"
  })
  listInfo(result) {
    console.log("Inside listInfo --- ", JSON.stringify(result.data));
    this.showSpinner = false;
    this.listInfoResults = result;
    let data = result.data,
      error = result.error;
    if (data) {
      this.lineItems = [];
      let tempLineItems = [];

      // eslint-disable-next-line default-case
      switch (this.objectApiName) {
        case "Cart__c":
          data.records.forEach((record) => {
            this.lineItems.push({
              Id: record?.fields?.Id.value,
              Name: record?.fields?.Name.value,
              CatClass: record?.fields?.Cat_Class__c.value,
              Quantity: record?.fields?.Quantity__c.value,
              Min_Rate: record?.fields?.Minimum_Price__c.value,
              Daily_Rate: record?.fields?.Daily_Price__c.value,
              Weekly_Rate: record?.fields?.Weekly_Price__c.value,
              Monthly_Rate: record?.fields?.Monthly_Price__c.value,
              Sale_Price: record?.fields?.Misc_Sales_Price__c.value,
              Item_Subtotal: record?.fields?.Item_Subtotal__c.value,
              productType:
                record?.fields?.Product__r?.value.fields.Product_Type__c.value,
              // SAL-25639 (1 fields below)
              miscChargesType:
                record?.fields?.Product__r?.value.fields
                  ?.Type_of_Misc_Charge_Item__c.value,
              itemNumber:
                record?.fields?.Product__r?.value.fields.Item_Number__c.value,
              stockClass:
                record?.fields?.Product__r?.value.fields.Stock_class__c.value,
              _isChecked: false,
              kitItemsAmount: 0,
              showKitItem: false,
              hasKitItems: false,
              product: record?.fields?.Product__r?.value.id,
              isUserAdded: record?.fields?.is_User_Added__c.value, //25998
              hasKit:
                record?.fields?.Product__r?.value.fields.Is_Kit__c.value ==
                  "Yes"
                  ? true
                  : false,
              kitItems: {
                kitItemsValue: [],
                packageName: record?.fields?.Product__r?.displayValue,
                isKit: record?.fields?.Product__r?.value.fields.Is_Kit__c.value,
                productId: record?.fields?.Product__c.value
              } // changed for SAL-13913
              // kitItems: {kitItemsValue:[], packageName:record?.fields?.Product__r?.displayValue,isKit: record?.fields?.Product__r?.value.fields.Is_Kit__c.value,productId :record?.fields?.Product__c.value}
            });
          });

          break;
        case "SBQQ__Quote__c":
          data.records.forEach((record) => {
            this.lineItems.push({
              Id: record?.fields?.Id.value,
              Name: record?.fields?.SBQQ__ProductName__c.value,
              Notes: record?.fields?.Line_Comments__c.value, //11909
              CatClass: record?.fields?.Product_SKU__c.value,
              Quantity: record?.fields?.SBQQ__Quantity__c.value,
              //Modified for FRONT-8740
              Min_Rate:
                record?.fields?.Min_Rate__c.value !== null
                  ? record?.fields?.Min_Rate__c.value
                  : 0,
              Min_Rate2: record?.fields?.Min_Rate2__c.value,
              Daily_Rate: record?.fields?.Daily_Rate2__c.value,
              Weekly_Rate: record?.fields?.Weekly_Rate2__c.value,
              Monthly_Rate: record?.fields?.Monthly_Rate2__c.value,
              Sale_Price: record?.fields?.Selling_Price__c.value,
              Item_Subtotal: record?.fields?.Total_Price__c.value,
              Specific_Pricing_Type:
                record?.fields?.Specific_Pricing_Type__c.value,
              Suggested_Daily_Rate:
                record?.fields?.Suggested_Daily_Rate__c.value,
              Suggested_Weekly_Rate:
                record?.fields?.Suggested_Weekly_Rate__c.value,
              Suggested_Monthly_Rate:
                record?.fields?.Suggested_Monthly_Rate__c.value,
              // SAL-25639 (1 fields below)
              //miscChargesType: record?.fields?.SBQQ__Product__r?.value.fields?.Type_of_Misc_Charge_Item__c.value,
              miscChargesType: record?.fields?.Misc_Charges_Type__c.value,
              productType:
                record?.fields?.SBQQ__Product__r?.value.fields?.Product_Type__c
                  .value,
              userSelect:
                record?.fields?.SBQQ__Product__r?.value.fields?.User_Select__c
                  .value,
              isUserAdded: record?.fields?.is_User_Added__c.value, //25998
              lineItemType:
                record?.fields?.Line_Item_Type__c.value != null
                  ? record?.fields?.Line_Item_Type__c.value
                  : "", //25998
              stockClass:
                record?.fields?.SBQQ__Product__r?.value.fields?.Stock_class__c
                  .value,
              _isChecked: false,
              hasNotes:
                record?.fields?.Line_Comments__c.value?.length > 0
                  ? true
                  : false,
              showNoteItem: false,
              // DS changes
              kitItemsAmount: 0,
              showKitItem: false,
              hasKitItems: false,
              hasKit:
                record?.fields?.SBQQ__Product__r?.value.fields.Is_Kit__c
                  .value == "Yes"
                  ? true
                  : false,

              // DS changes

              product: record?.fields?.SBQQ__Product__c.value,
              AddedByCrewExpense:
                record?.fields?.Added_by_Crew_Expense__c.value, //25936
              kitItems: {
                kitItemsValue: [],
                packageName: record.fields?.SBQQ__Product__r?.displayValue,
                isKit:
                  record.fields?.SBQQ__Product__r?.value?.fields?.Is_Kit__c
                    ?.value,
                productId: record?.fields?.SBQQ__Product__c?.value
              }
            });
          });
          break;
        case "Order":
          data.records.forEach((record) => {
            let itemExists = false;
            let isItemHidden = false;

            if (
              record?.fields?.is_Line_Item_Hidden__c != null &&
              record?.fields?.is_Line_Item_Hidden__c.value === true
            ) {
              isItemHidden = true;
            }

            this.lineItems.forEach((obj) => {
              if (
                obj._groupId &&
                obj._groupId === record?.fields?.groupID__c.value
              ) {
                this.orderItemGrouping.map((grouping) => {
                  if (grouping.groupId === record?.fields?.groupID__c.value) {
                    grouping.recordIds.push(record?.fields?.Id.value);
                  }
                });
                obj.Quantity += 1;
                obj.Item_Subtotal += record?.fields?.Total_Price__c.value; // SAL-14399
                itemExists = true;
              }
            });
            if (!itemExists && !isItemHidden) {
              this.lineItems.push({
                Id: record?.fields?.Id.value,
                Name: record?.fields?.Product2.value.fields.Name.value,
                Notes: record?.fields?.Line_Comments__c.value, //11909
                //  CatClass: record?.fields?.Cat_Class__c.value,
                //Started for front-6266,6267,6288
                CatClass: record?.fields?.Cat_Class__c.value
                  ? record?.fields?.Cat_Class__c.value
                  : record?.fields?.Product2.value.fields.Product_SKU__c.value,
                //Ended for Front-6266,6267,6268
                //FRONT-9233, 1950 Start
                StatusCreated: record?.fields?.Status_Created_Qty__c.value
                  ? record?.fields?.Status_Created_Qty__c.value
                  : 0,
                StatusFilled: record?.fields?.Status_Filled_Qty__c.value
                  ? record?.fields?.Status_Filled_Qty__c.value
                  : 0,
                StatusCancel: record?.fields?.Status_Cancelled_Qty__c.value
                  ? record?.fields?.Status_Cancelled_Qty__c.value
                  : 0,
                allowCancelStatus: record?.fields?.Allow_Cancel__c.value,
                fullyConvertedItem:
                  record?.fields?.Allow_Cancel__c.value !== "" &&
                    record?.fields?.Allow_Cancel__c.value === "Filled"
                    ? true
                    : false,
                partiallyConvertedItem:
                  record?.fields?.Allow_Cancel__c.value !== "" &&
                    record?.fields?.Allow_Cancel__c.value === "Partially Filled"
                    ? true
                    : false,
                fullyConvertedNoSubstituteItem:
                  record?.fields?.Allow_Cancel__c.value !== "" &&
                    record?.fields?.Allow_Cancel__c.value === "Filled" &&
                    (record?.fields?.Status__c?.value === null ||
                      record?.fields?.Status__c?.value === "AVAILABLE")
                    ? true
                    : false,
                patiallyConvertedNoSubstituteItem:
                  record?.fields?.Allow_Cancel__c.value !== "" &&
                    record?.fields?.Allow_Cancel__c.value ===
                    "Partially Filled" &&
                    (record?.fields?.Status__c?.value === null ||
                      record?.fields?.Status__c?.value === "AVAILABLE")
                    ? true
                    : false,
                //FRONT-9233 End
                //FRONT-9234 Start
                TotalQuantity:
                  record?.fields?.Status_Created_Qty__c.value +
                  record?.fields?.Status_Filled_Qty__c.value +
                  record?.fields?.Status_Cancelled_Qty__c.value,
                RemainingQuantity:
                  record?.fields?.Status_Created_Qty__c.value +
                  record?.fields?.Status_Filled_Qty__c.value +
                  record?.fields?.Status_Cancelled_Qty__c.value -
                  (record?.fields?.Status_Filled_Qty__c.value +
                    record?.fields?.Status_Cancelled_Qty__c.value),
                //FRONT-9234 End
                Quantity: record?.fields?.Quantity.value,
                //Modified for FRONT-8740
                //FRONT-7422,7423 START
                product_Code:
                  record?.fields?.Product2.value.fields.Product_SKU__c.value,
                //FRONT-7422,7423 END
                Min_Rate:
                  record?.fields?.Min_Rate__c.value !== null
                    ? record?.fields?.Min_Rate__c.value
                    : 0,
                Min_Rate2: record?.fields?.Min_Rate2__c.value,
                Discount_Percentage: record?.fields?.Discount_Percentage__c.value, //20309
                Daily_Rate: record?.fields?.Daily_Rate2__c.value,
                Weekly_Rate: record?.fields?.Weekly_Rate2__c.value,
                Monthly_Rate: record?.fields?.Monthly_Rate2__c.value,
                Sale_Price: record?.fields?.Selling_Price__c.value,
                Item_Subtotal: record?.fields?.Total_Price__c.value,
                Specific_Pricing_Type:
                  record?.fields?.Specific_Pricing_Type__c.value,
                Suggested_Daily_Rate:
                  record?.fields?.Suggested_Daily_Rate__c.value,
                Suggested_Weekly_Rate:
                  record?.fields?.Suggested_Weekly_Rate__c.value,
                Suggested_Monthly_Rate:
                  record?.fields?.Suggested_Monthly_Rate__c.value,
                productType:
                  record?.fields?.Product2?.value.fields?.Product_Type__c.value,
                // SAL-25639 (1 fields below)
                //miscChargesType: record?.fields?.Product2?.value.fields?.Type_of_Misc_Charge_Item__c.value,
                miscChargesType: record?.fields?.Misc_Charges_Type__c.value,
                userSelect:
                  record?.fields?.Product2?.value.fields?.User_Select__c.value,
                isUserAdded: record?.fields?.is_User_Added__c.value, //25998
                lineItemType:
                  record?.fields?.Line_Item_Type__c.value != null
                    ? record?.fields?.Line_Item_Type__c.value
                    : "", //25998
                stockClass:
                  record?.fields?.Product2?.value.fields?.Stock_class__c.value,
                _groupId: record?.fields?.groupID__c.value,
                _isChecked: false,
                hasNotes:
                  record?.fields?.Line_Comments__c.value?.length > 0
                    ? true
                    : false,
                showNoteItem: false,
                // DS changes
                kitItemsAmount: 0,
                showKitItem: false,
                hasKitItems: false,
                hasKit:
                  record?.fields?.Product2?.value.fields.Is_Kit__c.value ==
                    "Yes"
                    ? true
                    : false,

                // DS changes
                product: record?.fields?.Product2Id.value,
                kitItems: {
                  kitItemsValue: [],
                  packageName: record?.fields?.Product2.displayValue,
                  isKit: record?.fields?.Product2.value.fields.Is_Kit__c.value,
                  productId: record?.fields?.Product2Id.value
                },
                Status: record?.fields?.Status__c?.value //FRONT-1639
              });
              this.orderItemGrouping.push({
                groupId: record?.fields?.groupID__c.value,
                recordIds: [record?.fields?.Id.value]
              });
            }
          });
          break;
      }
      this.isLoading = false;
      this.updateLineItemsTable();
    } else if (error) {
      console.log(error);
    }
  }

  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
    console.log("This.recordId in lineItemsCmpFrontline --- ", this.recordId);
    console.log("this.fields --- ", JSON.stringify(this.fields));
    console.log("objectApiName ---- ", this.objectApiName);
    //this.isMobile = true;
    this.subscribeToMessageChannel();
    if (this.recordId) {
      refreshApex(this.listInfoResults);
      this.initRecordContextVariables();
      console.log("this.fields after assign --- ", JSON.stringify(this.fields));
      //SAL-26056, SADAPUR
      this.refreshHandlerID = registerRefreshHandler(this, this.refreshHandler);
      //this.beginRefresh();
    } else {
      const payload = {
        recordId: null
      };
      publish(this.messageContext, pICartLoadedChannel, payload);
      this.orderNumber = 2; //make lineitemsColumns wire reactive
    }

    this.updateTotalsRecordId = this.recordId ? this.recordId.valueOf() : "";
    this.listInfoRecordId = this.recordId ? this.recordId.valueOf() : "";
    console.log("listInfoRecordId ---- ", this.listInfoRecordId);
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
        case "Cart__c":
          this.noItemsMsg = "No items in the cart.";
          this.relatedListId = "Cart_Items__r";
          this.fields = [
            "Cart_Items__c.Id",
            "Cart_Items__c.Name",
            "Cart_Items__c.Cat_Class__c",
            "Cart_Items__c.Quantity__c",
            "Cart_Items__c.Minimum_Price__c",
            "Cart_Items__c.Daily_Price__c",
            "Cart_Items__c.Weekly_Price__c",
            "Cart_Items__c.Monthly_Price__c",
            "Cart_Items__c.Misc_Sales_Price__c",
            "Cart_Items__c.Item_Subtotal__c",
            "Cart_Items__c.Product__c",
            "Cart_Items__c.Product__r.Is_Kit__c",
            "Cart_Items__c.Product__r.Changeable__c",
            "Cart_Items__c.Product__r.Product_Type__c",
            "Cart_Items__c.Product__r.Type_of_Misc_Charge_Item__c",
            "Cart_Items__c.Product__r.Item_Number__c",
            "Cart_Items__c.Product__r.Stock_class__c",
            "Cart_Items__c.is_User_Added__c"
          ];
          break;
        case "SBQQ__Quote__c":
          this.noItemsMsg =
            "There are no Line Items in this Quote. Use Item Search to add items.";
          this.relatedListId = "SBQQ__LineItems__r";
          //this.fields = ['SBQQ__QuoteLine__c.Id','SBQQ__QuoteLine__c.SBQQ__ProductName__c'];
          this.fields = [
            "SBQQ__QuoteLine__c.Id",
            "SBQQ__QuoteLine__c.SBQQ__ProductName__c",
            "SBQQ__QuoteLine__c.Product_SKU__c",
            "SBQQ__QuoteLine__c.SBQQ__Quantity__c",
            "SBQQ__QuoteLine__c.Min_Rate__c",
            "SBQQ__QuoteLine__c.Min_Rate2__c",
            "SBQQ__QuoteLine__c.Daily_Rate2__c",
            "SBQQ__QuoteLine__c.Weekly_Rate2__c",
            "SBQQ__QuoteLine__c.Monthly_Rate2__c",
            "SBQQ__QuoteLine__c.Selling_Price__c",
            "SBQQ__QuoteLine__c.SBQQ__UnitCost__c",
            "SBQQ__QuoteLine__c.Total_Price__c",
            "SBQQ__QuoteLine__c.Specific_Pricing_Type__c",
            "SBQQ__QuoteLine__c.Suggested_Daily_Rate__c",
            "SBQQ__QuoteLine__c.Suggested_Weekly_Rate__c",
            "SBQQ__QuoteLine__c.Suggested_Monthly_Rate__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__c",
            "SBQQ__QuoteLine__c.Line_Comments__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__r.Is_Kit__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__r.Product_Type__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__r.Type_of_Misc_Charge_Item__c",
            "SBQQ__QuoteLine__c.Misc_Charges_Type__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__r.User_Select__c",
            "SBQQ__QuoteLine__c.SBQQ__Product__r.Stock_class__c",
            "SBQQ__QuoteLine__c.Line_Item_Type__c",
            "SBQQ__QuoteLine__c.is_User_Added__c",
            "SBQQ__QuoteLine__c.Added_by_Crew_Expense__c"
          ];
          break;
        case "Order":
          this.noItemsMsg =
            "There are no Line Items in this Order. Use Item Search to add items.";
          this.relatedListId = "OrderItems";
          this.fields = [
            "OrderItem.Id",
            "OrderItem.Product2.Name",
            "OrderItem.Product2.Product_SKU__c",
            "OrderItem.Quantity",
            "OrderItem.Min_Rate__c",
            "OrderItem.Min_Rate2__c",
            "OrderItem.Daily_Rate2__c",
            "OrderItem.Weekly_Rate2__c",
            "OrderItem.Monthly_Rate2__c",
            "OrderItem.Selling_Price__c",
            "OrderItem.UnitPrice",
            "OrderItem.Total_Price__c",
            "OrderItem.groupID__c",
            "OrderItem.Cat_Class__c",
            "OrderItem.Product2Id",
            "OrderItem.Line_Comments__c",
            "OrderItem.Specific_Pricing_Type__c",
            "OrderItem.Suggested_Daily_Rate__c",
            "OrderItem.Suggested_Weekly_Rate__c",
            "OrderItem.Suggested_Monthly_Rate__c",
            "OrderItem.Product2.Product_Type__c",
            "OrderItem.Product2.Type_of_Misc_Charge_Item__c",
            "OrderItem.Misc_Charges_Type__c",
            "OrderItem.Product2.User_Select__c",
            "OrderItem.Product2.Stock_class__c",
            "OrderItem.Product2.Is_Kit__c",
            "OrderItem.is_Line_Item_Hidden__c",
            "OrderItem.Line_Item_Type__c",
            "OrderItem.is_User_Added__c",
            "OrderItem.Status__c", //FRONT-1639
            "Status__c", //FRONT-1639
            "OrderItem.Status_Created_Qty__c", //FRONT-9233, 1950
            "OrderItem.Status_Filled_Qty__c", //FRONT-9233
            "OrderItem.Status_Cancelled_Qty__c", //FRONT-9233
            "OrderItem.Allow_Cancel__c", //FRONT-1950, 1958
            "OrderItem.Discount_Percentage__c" //20309
          ];
          break;
      }
    }
    console.log("this.fields after assign in method--- ", JSON.stringify(this.fields));
  }
  //handler method for update totals event
  updateTotalsHandler(data) {
    if (data.recordId == this.recordId) {
      this.updateTotalsRecordId = "";
      this.updateTotalsRecordId = data.recordId;
    }
  }

  //method to split line items to various grid data
  updateLineItemGridData(data) {
    if (data && data.detail) {
      data = data.detail;
      data = JSON.parse(JSON.stringify(data));
      this.lineItems = JSON.parse(JSON.stringify(data));
    }
    this.rentalLineItems = [];
    this.salesLineItems = [];
    this.deliveryLineItems = [];
    this.ancillaryLineItems = [];
    let currentRecord = 0; //FRONT-1950
    let currentCATRecord = 0; //FRONT-11845
    data.forEach((record) => {
      //START FRONT-1950
      var disableNameColumn = false;
      let toolTipPosition = "topToolTip";
      //let toolTipPositionError = "topToolTipError"; //ADDED FOR FRONT-11845
      console.log("RECORD##", JSON.stringify(record));
      if (currentRecord == 0 || currentRecord == 1) {
        toolTipPosition = "rightToolTip";
        //toolTipPositionError = "rightToolTipError"; //ADDED FOR FRONT-11845
      }
      currentRecord++;
      //END FRONT-1950

      //START FRONT-11421
      if (
        this.isReadOnlyRecord &&
        (this.recordTypeName === "Reservation Order" ||
          this.objectApiName === "SBQQ__Quote__c") //FRONT-10503 Added check for quotes to make read-only
      ) {
        disableNameColumn = true;
        record = {
          ...record,
          disableNameColumn: disableNameColumn,
          disabledTextColor: "disabled-text"
        };
      }
      //END FRONT-11421

      // SAL-25677 __ 14/07/2023 __ Salma
      //FRONT-9233 start
      if (this.orderStatus == "Partially Filled") {
        let TotalQty =
          record.StatusCreated + record.StatusFilled + record.StatusCancel;
        let Remaining_Quantity =
          TotalQty - (record.StatusFilled + record.StatusCancel);
        record.Total_Qty = Remaining_Quantity + " of " + TotalQty;

        //START FRONT-1950
        if (record.allowCancelStatus === "Filled") {
          disableNameColumn = true;
          record = {
            ...record,
            disableNameColumn: disableNameColumn,
            disabledTextColor: "disabled-text", //FRONT-10473
            tooltipClickedIconVariant: toolTipPosition,
            tooltipClickedIcon: "utility:info_alt",
            tooltipClickedText: ""
          };
        } else if (record.allowCancelStatus === "Partially Filled") {
          record = {
            ...record,
            tooltipClickedIconVariant: toolTipPosition,
            tooltipClickedIcon: "utility:info",
            tooltipClickedText: this.label.INFO_TOOLTIP
          };
        }
        //END FRONT-1950
      }
      //FRONT-9233 ended
      record.Min_Rate =
        record.Min_Rate && String(record.Min_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Min_Rate).toFixed(2)
          : record.Min_Rate;
      record.Daily_Rate =
        record.Daily_Rate && String(record.Daily_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Daily_Rate).toFixed(2)
          : record.Daily_Rate;
      record.Weekly_Rate =
        record.Weekly_Rate && String(record.Weekly_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Weekly_Rate).toFixed(2)
          : record.Weekly_Rate;
      record.Monthly_Rate =
        record.Monthly_Rate && String(record.Monthly_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Monthly_Rate).toFixed(2)
          : record.Monthly_Rate;
      record.Sale_Price =
        record.Sale_Price && String(record.Sale_Price).charAt(0) !== "$"
          ? "$" + Number(record.Sale_Price).toFixed(2)
          : record.Sale_Price;
      record.Item_Subtotal =
        record.Item_Subtotal && String(record.Item_Subtotal).charAt(0) !== "$"
          ? "$" + Number(record.Item_Subtotal).toFixed(2)
          : record.Item_Subtotal;
      record.Suggested_Daily_Rate =
        record.Suggested_Daily_Rate &&
          String(record.Suggested_Daily_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Suggested_Daily_Rate).toFixed(2)
          : record.Suggested_Daily_Rate;
      record.Suggested_Weekly_Rate =
        record.Suggested_Weekly_Rate &&
          String(record.Suggested_Weekly_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Suggested_Weekly_Rate).toFixed(2)
          : record.Suggested_Weekly_Rate;
      record.Suggested_Monthly_Rate =
        record.Suggested_Monthly_Rate &&
          String(record.Suggested_Monthly_Rate).charAt(0) !== "$"
          ? "$" + Number(record.Suggested_Monthly_Rate).toFixed(2)
          : record.Suggested_Monthly_Rate;

      // SAL-25639
      // New logic from SAL-23417 / SAL-23418
      if (record.productType === "Cat-Class") {
        /* --- Start: FRONT-11845 ---*/
        let toolTipPositionError = "topToolTipError";
        if (currentCATRecord === 0 || currentCATRecord === 1) {
          toolTipPositionError = "rightToolTipError";
        }
        /* --- End: FRONT-11845 ---*/
        /* --- Start: FRONT-7422, FRONT-7423 ---*/
        let noAvailability = "";
        let noAvailabilityIcon = "";
        console.log('availabilityData==', JSON.stringify(this.availabilityData));
        if (this.availabilityData.has(record.product_Code)) {
          if (this.availabilityData.get(record.product_Code) > 0) {
            noAvailability = "";
            noAvailabilityIcon = "";
          } else {
            noAvailability = "no-availability";
            noAvailabilityIcon = "utility:warning";
          }
        }
        record = {
          ...record,
          errorClickedIconVariant: toolTipPositionError, //ADDED FOR FRONT-11845
          noAvailability: noAvailability,
          noAvailabilityIcon: noAvailabilityIcon
        };
        currentCATRecord++; //FRONT-11845
        /* --- End FFRONT-7422, FRONT-7423 ---*/

        this.rentalLineItems = [...this.rentalLineItems, record]; // push(record);
      } else if (
        record.productType === "Merchandise" ||
        record.productType === "Parts" ||
        record.productType === "Misc-Charge" ||
        record.productType === "MISC Charge Items" // Added for Story - 14358
      ) {
        this.salesLineItems.push(record);
      } else {
        if (
          record.productType == "MISC Charge Items" &&
          record.stockClass == "DEL"
        ) {
          this.deliveryLineItems.push(record);
        } else if (
          record.productType == "MISC Charge Items" &&
          record.stockClass != "DEL"
        ) {
          //SAL-25998
          if (record.isUserAdded) {
            record.isSales = true;
            this.salesLineItems.push(record);
          } else if (
            record.lineItemType != undefined &&
            record.lineItemType != null &&
            record.lineItemType === "YC"
          ) {
            this.ancillaryLineItems.push(record);
          } else {
            this.ancillaryLineItems.push(record);
          }
        } else {
          this.ancillaryLineItems.push(record);
        }
      }
    });
    /*START: FRONT: 11570 */
    if (
      this.rentalLineItems != null &&
      this.objectApiName === "Order" &&
      !this.isReadOnlyRecord &&
      this.recordTypeName === "Reservation Order"
    ) {
      const itemStatus = "Filled";
      const newRentalItems = [];
      this.rentalLineItems.forEach((e) => {
        if (e.allowCancelStatus !== itemStatus) {
          newRentalItems.push(e);
        }
      });
      this.rentalLineItems.forEach((e) => {
        if (e.allowCancelStatus === itemStatus) {
          newRentalItems.push(e);
        }
      });
      if (newRentalItems != null) {
        this.rentalLineItems = [];
        this.rentalLineItems.push(...newRentalItems);
      }
    }
    /*END: FRONT: 11570 */
  }

  //method to add line items based on input from item search tab
  addLineItem(item) {
    //handle validation to check addition of intended line item based on recordId
    if (item.type === "add") {
      if (this.recordId) {
        if (item.recordId == this.recordId) {
          try {
            refreshApex(this.listInfoResults); // Hashem Abdul - SAL-26119
          } catch (error) {
            console.log("addLineItem error->" + error.message);
          }
          this.updateLineItemsTable();
        }
      } else {
        let selectedCustomer =
          this._customerInfo && this._customerInfo.RM_Account_Number__c
            ? this._customerInfo.RM_Account_Number__c
            : "";
        if (!item.isBulk) {
          let branch;
          let products = [];
          if (
            item.lineItem.itemType == "rental" ||
            item.lineItem.itemType == "base"
          ) {
            branch = item.lineItem?.rateBranch
              ? item.lineItem.rateBranch
              : item?.lineItem.Rate_Branch
                ? item.lineItem.Rate_Branch
                : "";
            products.push({ productId: item.lineItem.catClass, pc: branch });
            getProductRates({
              prwrapper: {
                products: products,
                customerNumber: selectedCustomer
              }
            })
              .then((result) => {
                let suggestedRates = {
                  minimum: 0,
                  daily: 0,
                  weekly: 0,
                  monthly: 0
                };
                let rates = { suggestedRates: suggestedRates };
                if (
                  JSON.parse(result).data &&
                  JSON.parse(result).data.items &&
                  JSON.parse(result).data.items.length > 0
                ) {
                  rates = JSON.parse(result).data.items[0].rates;
                  let rateFlag = JSON.parse(result).data.items[0].rateFlag;
                  let notToExceed =
                    JSON.parse(result).data.items[0].notToExceed;
                  if (rateFlag == "Y") {
                    switch (notToExceed) {
                      case "S":
                        this.showSetRatesBanner = true;
                        break;
                      case "X":
                        this.showDNEBanner = true;
                        break;
                      case "P":
                        this.showPercentBanner = true;
                        break;
                      case "":
                        this.showSpecialRateBanner = true;
                        break;
                      default:
                        break;
                    }
                    this.invokeCSP();
                  }
                }
                //refactor to remove usage of math.random and replace with sequence for id
                let id = Math.random().toString(16).slice(2);

                this.lineItems.push({
                  Id: id,
                  Product: item.lineItem.id, //SAL-12552
                  CatClass: item.lineItem.catClass,
                  Name: item.lineItem.name,
                  Quantity: item.lineItem.quantity,
                  Min_Rate: rates.suggestedRates.minimum,
                  Daily_Rate: rates.suggestedRates.daily,
                  Weekly_Rate: rates.suggestedRates.weekly,
                  Monthly_Rate: rates.suggestedRates.monthly,
                  SpecificPricingType: item.lineItem.specificPricingType,
                  Sale_Price: null,
                  Item_Subtotal: null,
                  _isChecked: false,
                  kitItemsAmount:
                    item.lineItem.isKit == "Yes"
                      ? item.lineItem.kitItems.length
                      : 0,
                  showKitItem: false,
                  hasKit: item.lineItem.isKit == "Yes" ? true : false,
                  productType: item.lineItem.productType,
                  //     kitItems: {kitItemsValue: ('kitItems' in item.lineItem) ? item.lineItem.kitItems : [], packageName:item.lineItem.name}, //changed for SAL-13913
                  kitItems: {
                    kitItemsValue:
                      "kitItems" in item.lineItem ? item.lineItem.kitItems : [],
                    packageName: item.lineItem.name,
                    isKit: item.lineItem.isKit,
                    productId: item.lineItem.id
                  }
                });

                this.updateLineItemsTable();
                this.sendIsCartEmpty();
                this.beginRefresh();
              })
              .catch((error) => {
                console.log(error);
              });
            //FRONT-11309 adding items to the cart from sales tab
          } else if (item.lineItem.itemType === "consumableSalesAddOn") {
            this.addConsumableItem(item);
            //to remove the items after saving the cart
            this.clearItemType = item.lineItem.itemType;
          } else {
            let id = Math.random().toString(16).slice(2);

            this.lineItems.push({
              Id: id,
              Product: item.lineItem.id,
              //CatClass: item.lineItem.catClass,
              CatClass: item.lineItem.fields
                ? item.lineItem.fields.Cat_Class__c.value
                : item.lineItem.catClass, //SAL-12552
              Name: item.lineItem.name,
              Quantity: item.lineItem.quantity,
              Min_Rate: null,
              Daily_Rate: null,
              Weekly_Rate: null,
              Monthly_Rate: null,
              Sale_Price: item.lineItem.sellPrice,
              Item_Subtotal: null,
              Item_Type: item.lineItem.itemType,
              _isChecked: false,
              kitItemsAmount:
                item.lineItem.isKit == "Yes"
                  ? item.lineItem.kitItems.length
                  : 0,
              hasKit: item.lineItem.isKit == "Yes" ? true : false,
              showKitItem: false,
              productType: item.lineItem.productType,
              SpecificPricingType: item.lineItem.specificPricingType,
              stockClass: item.lineItem.stockClass, //25958
              itemNumber: item.lineItem.itemNumber, //25958
              //  kitItems: {kitItemsValue: ('kitItems' in item.lineItem) ? item.lineItem.kitItems : [], packageName:item.lineItem.name}, //changed for SAL-13913
              kitItems: {
                kitItemsValue:
                  "kitItems" in item.lineItem ? item.lineItem.kitItems : [],
                packageName: item.lineItem.name,
                isKit: item.lineItem.isKit,
                productId: item.lineItem.id
              }
            });

            logger.log("### this.lineItems >> " + this.lineItems);
            this.updateLineItemsTable();
            this.sendIsCartEmpty();
            this.beginRefresh();
          }
        } else {
          let products = [];
          let salesItems = [];
          let bulkLineItems = [...item.lineItem];

          bulkLineItems.forEach((item) => {
            if (item.itemType === "rental" || item.itemType === "base") {
              products.push(item.catClass);
            }
          });
          if (products[0] != null) {
            getProductRates({
              prwrapper: {
                products: products,
                customerNumber: selectedCustomer
              }
            })
              .then((result) => {
                let bulkRates = JSON.parse(result).data.items;
                let bulkLineItems = item.lineItem.map((item) => item.lineItem);
                bulkRates.forEach((rateItem, index) => {
                  let id = Math.random().toString(16).slice(2);
                  this.lineItems.push({
                    Id: id,
                    CatClass: bulkLineItems[index].catClass,
                    Name: bulkLineItems[index].name,
                    Quantity: bulkLineItems[index].quantity,
                    Min_Rate: rateItem.rates.suggestedRates.minimum,
                    Daily_Rate: rateItem.rates.suggestedRates.daily,
                    Weekly_Rate: rateItem.rates.suggestedRates.weekly,
                    Monthly_Rate: rateItem.rates.suggestedRates.monthly,
                    Sale_Price: "--",
                    Item_Subtotal: "--",
                    _isChecked: false
                  });
                });
                bulkLineItems.forEach((item) => {
                  if (item.itemType === "sales") {
                    let id = Math.random().toString(16).slice(2);
                    this.lineItems.push({
                      Id: id,
                      CatClass: item.catClass,
                      Name: item.name,
                      Quantity: item.quantity,
                      Min_Rate: "--",
                      Daily_Rate: "--",
                      Weekly_Rate: "--",
                      Monthly_Rate: "--",
                      Sale_Price: item.sellPrice,
                      Item_Subtotal: "--",
                      Item_Type: item.itemType,
                      _isChecked: false
                    });
                    salesItems.push(item.catClass);
                  }
                });

                this.updateLineItemsTable();
                this.sendIsCartEmpty();
                this.beginRefresh();
              })
              .catch((error) => {
                console.log(error);
              });
          }
        }
      }
    }
  }
  @api clearLineItems() {
    this.lineItems = [];
    this.cartSalesLineItems = []; //FRONT-11309 remove items from the table when save cart clicked
    const payload = {
      recordId: null,
      type: "remove",
      lineItemsCount: this.lineItems.length,
      lineItem: { itemType: this.clearItemType } //FRONT-11309 passing this to identify on which tab cart count need to be updated
    };
    publish(this.messageContext, updateLineItemsChannel, payload);

    if (!this.isMobile) {
      publish(this.messageContext, deselectProductRowChannel, {
        productId: null,
        contextId: null,
        variant: this.clearItemType //FRONT-11309 passing variant to identify on which tab items need to be deselect from the tabl
      });
    }
    const isCartEmpty = new CustomEvent("sendisemptycart", {
      detail: {
        isEmptyCart: true
      }
    });
    this.dispatchEvent(isCartEmpty);
    this.beginRefresh();
    this.updateLineItemsTable();
  }
  @api saveLineItems(context, information) {
    let lineItemsToSave = [...this.lineItems];
    console.log("===this.lineItems====", JSON.stringify(this.lineItems));
    if (this.cartSalesLineItems) {
      lineItemsToSave = [...lineItemsToSave, ...this.cartSalesLineItems];
    }
    console.log("===this.lineItems= after===", JSON.stringify(lineItemsToSave));
    information["Total__c"] = this.total;
    switch (context) {
      case "Product Inquiry":
        const fields = information;
        const cartRecordInput = { apiName: CART_OBJECT.objectApiName, fields };
        createRecord(cartRecordInput)
          .then((cart) => {
            this.savedCartId = cart.id;
            this.savedCartName = cart.fields.Name.value;
            let cartItems = lineItemsToSave.map((item) => {
              let fields = {
                Cart__c: cart.id,
                Cat_Class__c: item.CatClass,
                Name: item.Name,
                Minimum_Price__c:
                  String(item.Min_Rate).charAt(0) === "$"
                    ? String(item.Min_Rate).slice(1)
                    : item.Min_Rate,
                Daily_Price__c:
                  String(item.Daily_Rate).charAt(0) === "$"
                    ? String(item.Daily_Rate).slice(1)
                    : item.Daily_Rate,
                Weekly_Price__c:
                  String(item.Weekly_Rate).charAt(0) === "$"
                    ? String(item.Weekly_Rate).slice(1)
                    : item.Weekly_Rate,
                Monthly_Price__c:
                  String(item.Monthly_Rate).charAt(0) === "$"
                    ? String(item.Monthly_Rate).slice(1)
                    : item.Monthly_Rate,
                Misc_Sales_Price__c:
                  String(item.Sale_Price).charAt(0) === "$"
                    ? String(item.Sale_Price).slice(1)
                    : item.Sale_Price,
                Item_Subtotal__c:
                  String(item.Item_Subtotal).charAt(0) === "$"
                    ? String(item.Item_Subtotal).slice(1)
                    : item.Item_Subtotal,
                Suggested_Minimum_Price__c:
                  String(item.Min_Rate).charAt(0) === "$"
                    ? String(item.Min_Rate).slice(1)
                    : item.Min_Rate,
                Suggested_Daily_Price__c:
                  String(item.Daily_Rate).charAt(0) === "$"
                    ? String(item.Daily_Rate).slice(1)
                    : item.Daily_Rate,
                Suggested_Weekly_Price__c:
                  String(item.Weekly_Rate).charAt(0) === "$"
                    ? String(item.Weekly_Rate).slice(1)
                    : item.Weekly_Rate,
                Suggested_Monthly_Price__c:
                  String(item.Monthly_Rate).charAt(0) === "$"
                    ? String(item.Monthly_Rate).slice(1)
                    : item.Monthly_Rate,
                Specific_Pricing_Type__c: item.SpecificPricingType,
                Quantity__c: item.Quantity,
                Product__c: item.Product, //SAL-12552
                is_User_Added__c: true //22570
              };
              return { apiName: CART_ITEMS_OBJECT.objectApiName, fields };
            });
            console.log("=====cartItem===save==", JSON.stringify(cartItems));
            let cartItemsPromises = cartItems.map((cartItem) =>
              createRecord(cartItem)
            );
            Promise.all(cartItemsPromises)
              .then((createdCartItems) => {
                if (createdCartItems.length > 0) {
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Success",
                      message: this.savedCartName + " was created",
                      variant: "success"
                    })
                  );
                } else {
                  this.dispatchEvent(
                    new ShowToastEvent({
                      title: "Success",
                      message: this.savedCartName + " was created",
                      variant: "success"
                    })
                  );
                }
                this.clearLineItems();
                this[NavigationMixin.Navigate]({
                  type: "standard__recordPage",
                  attributes: {
                    recordId: this.savedCartId,
                    actionName: "view"
                  }
                });
              })
              .catch((cartItemsError) => {
                this.dispatchEvent(
                  new ShowToastEvent({
                    title: "Error creating Cart Items",
                    message: cartItemsError.body.message,
                    variant: "error"
                  })
                );
              });
          })
          .catch((error) => {
            console.log("Error log->" + JSON.stringify(error));
            this.dispatchEvent(
              new ShowToastEvent({
                // SAL-11600 undefined is not an object (evaluating 'cartItemsError.body.message')
                title: "Error creating Cart record",
                message: error.body.message,
                variant: "error"
              })
            );
          });
        break;
      default:
        break;
    }
  }

  sendIsCartEmpty() {
    const isCartEmpty = new CustomEvent("sendisemptycart", {
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
    let ev = new CustomEvent("updatecsp", { detail: paramData });
    this.dispatchEvent(ev);
  }

  updateLineItemsTable() {
    this.columns = [...this.columns];
    this.lineItems = [...this.lineItems];

    if (
      this.lineItems?.length > 0 &&
      (this.objectApiName == undefined || this.objectApiName == "Cart__c")
    ) {
      this.getItemEstimates();
    }
    this.showLineItemsTable =
      this.lineItems?.length != 0 && this.columns?.length != 0 ? true : false;
    console.log(' from   updateLineItemsTable')


    this.updateLineItemGridData(this.lineItems);


  }

  getItemEstimates() {
    this.estimateRequest.orderLines[0].products = [];
    this.estimateRequest.orderLines[0].salesItems = [];
    this.lineItems.forEach((item) => {
      let product = {};
      let salesItems = {};
      if (!this.recordId) {
        if (item.CatClass != undefined) {
          if (item.productType !== "Cat-Class") {
            salesItems = {
              itemNumber: item.itemNumber,
              stockClass: item.stockClass,
              unitPrice: item.Sale_Price
                ? Number(String(item.Sale_Price).replace(/[$,]+/g, ""))
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
                hourly: "0.00",
                minimum: item.Min_Rate
                  ? String(item.Min_Rate).replace(/[$,]+/g, "")
                  : null,
                daily: item.Daily_Rate
                  ? String(item.Daily_Rate).replace(/[$,]+/g, "")
                  : null,
                weekly: item.Weekly_Rate
                  ? String(item.Weekly_Rate).replace(/[$,]+/g, "")
                  : null,
                monthly: item.Monthly_Rate
                  ? String(item.Monthly_Rate).replace(/[$,]+/g, "")
                  : null
              }
            };
            this.estimateRequest.orderLines[0].products.push(product);
          }
        }
      } else {
        if (item.CatClass != undefined) {
          if (item.productType !== "Cat-Class") {
            salesItems = {
              itemNumber: item.itemNumber,
              stockClass: item.stockClass,
              unitPrice: item.Sale_Price
                ? Number(String(item.Sale_Price).replace(/[$,]+/g, ""))
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
                hourly: "0.00",
                minimum: item.Min_Rate
                  ? String(item.Min_Rate).replace(/[$,]+/g, "")
                  : null,
                daily: item.Daily_Rate
                  ? String(item.Daily_Rate).replace(/[$,]+/g, "")
                  : null,
                weekly: item.Weekly_Rate
                  ? String(item.Weekly_Rate).replace(/[$,]+/g, "")
                  : null,
                monthly: item.Monthly_Rate
                  ? String(item.Monthly_Rate).replace(/[$,]+/g, "")
                  : null
              }
            };
            this.estimateRequest.orderLines[0].products.push(product);
          }
        }
      }
    });
    this.estimateRequest.orderType =
      this._deliveryCpu == "delivery" ? "Delivery" : "Pickup";
    if (this._jobsiteZip) {
      this.estimateRequest.address[0].zip = this._jobsiteZip;
    }
    this.estimateRequest.startDateAndTime =
      this._startDate + "T" + this._startTime;
    if (!this.estimateRequest.startDateAndTime.endsWith("Z")) {
      this.estimateRequest.startDateAndTime =
        this.estimateRequest.startDateAndTime + "Z";
    }
    this.estimateRequest.endDateAndTime =
      this._returnDate + "T" + this._returnTime;
    if (!this.estimateRequest.endDateAndTime.endsWith("Z")) {
      this.estimateRequest.endDateAndTime =
        this.estimateRequest.endDateAndTime + "Z";
    }
    if (
      this.lineItems.length > 0 &&
      this._customerInfo.Company_Code__c != undefined
    ) {
      let companyId = this._customerInfo.Company_Code__c.replace("0", "");
      getLineItemEstimates({
        estimatesRequestJson: JSON.stringify(this.estimateRequest),
        companyId: companyId
      })
        .then((result) => {
          let retVal = JSON.parse(result);
          if (!retVal.hasOwnProperty("error")) {
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
            this.subtotal = (
              parseFloat(retVal.data.estimate.totals.rentalAmount) +
              parseInt(retVal.data.estimate.totals.salesAmount)
            ).toFixed(2);
            this.tax = retVal.data.estimate.totals.salesTax.toFixed(2);
            this.total = retVal.data.estimate.totals.finalTotal.toFixed(2);

            this.charges = (
              retVal.data.estimate.totals.rppCharges +
              retVal.data.estimate.totals.miscCharges
            ).toFixed(2);
            this.taxAndCharges = (
              retVal.data.estimate.totals.salesTax +
              retVal.data.estimate.totals.rppCharges +
              retVal.data.estimate.totals.miscCharges
            ).toFixed(2);

            this.lineItems = [...this.lineItems];
            // add dollar sign to rates
            this.lineItems.forEach((lineItem) => {
              lineItem.Min_Rate = lineItem.Min_Rate;
              lineItem.Daily_Rate = lineItem.Daily_Rate;
              lineItem.Weekly_Rate = lineItem.Weekly_Rate;
              lineItem.Monthly_Rate = lineItem.Monthly_Rate;
              lineItem.Item_Subtotal = lineItem.Item_Subtotal;
            });
            this.showLineItemsTable =
              this.lineItems.length != 0 && this.columns.length != 0
                ? true
                : false;
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title:
                  "Failed to retrieve Estimates (Expect blank totals/subtotals)",
                message: "",
                variant: "error"
              })
            );
          }
        })
        .catch((error) => {
          console.log("Estimate error:");
          console.log(error);
          this.dispatchEvent(
            new ShowToastEvent({
              title:
                "Failed to retrieve Estimates (Expect blank totals/subtotals)",
              message: "",
              variant: "error"
            })
          );
        });
    } else {
      this.subtotal = 0;
      this.charges = 0;
      this.tax = 0;
      this.taxAndCharges = 0;
      this.total = 0;
    }
  }

  handleRowAction(event) {
    this.showItemEditor = true;
    const action = event.detail.action;
    const row = event.detail.row;

    let lineItemEditWrapper = this.template.querySelector(
      "c-sbr_3_0_-line-item-edit-wrapper"
    );
    if (lineItemEditWrapper) {
      lineItemEditWrapper.selectedRow = event.detail.row;
    }
    switch (action.name) {
      case "delete":
        if (this.recordId) {
          deleteRecord(row.Id)
            .then(() => {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: "Record deleted",
                  variant: "success"
                })
              );
            })
            .catch((error) => {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error deleting record",
                  message: error.body.message,
                  variant: "error"
                })
              );
            });
        }
        const rows = this.lineItems;
        const rowIndex = rows.findIndex((r) => r.Id == row.Id);
        rows.splice(rowIndex, 1);
        this.lineItems = rows;
        const payload = {
          recordId: this.recordId,
          type: "remove",
          lineItemsCount: this.lineItems.length,
          lineItem: { itemType: this.clearItemType } //FRONT-11309 passing this to identify on which tab cart count need to be updated
        };
        publish(this.messageContext, updateLineItemsChannel, payload);
        //remove the selected item from table
        if (!this.isMobile) {
          publish(this.messageContext, deselectProductRowChannel, {
            productId: row.Product,
            contextId: null,
            variant: this.clearItemType //FRONT-11309 passing variant to identify on which tab items need to be deselect from the tabl
          });
        }
        this.updateLineItemsTable();
        break;
      case "edit_quote_line":
        this.selectedRow = row; //FRONT-6266

        this.lineId = row.Id;
        this.selectedItemGroup = "";
        this.template.querySelector(".editModal").header = row.Name;
        this.template.querySelector(".editModal").toggleModal();
        this.template
          .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
          .populateLineData(row.Id, row._groupId, this.recordId);
        break;
      case "remove_quote_line":
        console.log("lets not do this");
        break;
      case "view_line_item":
        this[NavigationMixin.Navigate]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.product,
            actionName: "view"
          }
        });
        break;
      case "edit_order_line":
        this.lineId = row.Id;
        this.selectedItemGroup = row._groupId;
        this.template.querySelector(".editModal").header = row.Name;
        this.template.querySelector(".editModal").toggleModal();
        this.template
          .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
          .populateLineData(row.Id, row._groupId, this.recordId, row);
        break;
      case "remove_order_line":
        console.log("lets not do this");
        break;
      case "cancel_order_line_item":
        this.cancelSelectedRows.push(row);
        this.showCancelLineItemModal = true;
        break;
      /* Start ----  FRONT-1639 */
      case "substitute_item":
        this.substituteItem = row;
        this.showSubstituteModal = true;
        /* End ----  FRONT-1639 */
        break;
      default:
        break;
      /* End ----- Front-15893 */
    }
  }
  /* Notes Change Start*/
  handleNotesChange(event) {
    this.notes = event.detail.value;
  }
  updateOrderItemNotes = () => {
    let fields = { Id: this.rowId };
    fields.Line_Comments__c = this.notes;
    let recordInput = { fields };

    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Notes updated successfully",
            variant: "success"
          })
        );
        this.refs.notesModal.toggleModal();
      })
      .catch(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Error",
            variant: "error"
          })
        );
      });
  }
  handleRowNotesAction(event) {
    let detail = event.detail.detail;
    const actionName = detail.name;
    this.lineItemNotes = detail.value;
    this.rowId = detail.rowid;
    switch (actionName) {
      case "view_line_item_notes":
        this.template.querySelector(".viewlineitemNotes").toggleModal();
        this.template.querySelector(".viewlineitemNotes").showFooter = false;
        break;
      case "edit_order_line":
        this.template.querySelector(".editlineitemNotes").toggleModal();
        this.template.querySelector(".editlineitemNotes").showFooter = true;
        break;
      case "edit_quote_line":
        this.template.querySelector(".editlineitemNotes").toggleModal();
        this.template.querySelector(".editlineitemNotes").showFooter = true;
        break;
      default:
        break;
    }
  }
  /*Notes Change End*/

  //Modified as part of FRONT-2195-->
  handleSaveEdit = () => {
    let bulkEditConfirmModal = this.template.querySelector(
      ".bulkEditConfirmModal"
    ); //moved to single variable for referencing
    this.template.querySelector(".bulkEditModal").toggleModal();
    bulkEditConfirmModal.toggleModal();
    /*FRONT-9276 : Removing the Neutral variant classes from cancel and back buttons*/
    bulkEditConfirmModal.addGreyColourBoundaryToCancelButton();
    bulkEditConfirmModal.addGreyColourBoundaryToBackButton();
    /*END :  FRONT-9276*/
  };
  //Added as part of FRONT-2195
  saveData = (event) => {
    event.stopPropagation();
    this.showSpinner = true;
    this.template.querySelector(".bulkEditConfirmModal").toggleModal();
    //FRONT-2185, 9280
    this.template.querySelector(".bulkEditModal").toggleModal();
    //FRONT-2185, 9280
    this.template
      .querySelector("c-sbr_3_0_custom-data-table-edit-cmp")
      .saveRows(this.rentalLineItems)
      .then(() => {
        // this.showSpinner = false;
        //commenting as this is part of rate validation stories, will uncomment when we implement FRONT-2185
        // if (result === "success") {
        this.template.querySelector(".bulkEditModal").toggleModal();
        // }
      })
      .catch((error) => {
        this.showSpinner = false;
        console.log("===Error in saveData===", JSON.stringify(error));
      });
    refreshApex(this.listInfoResults);
  };
  //FRONT-2195 Ends
  handleCancelEdit = (event) => {
    event.stopPropagation();
  };
  //method to handle inline edits
  handleSave(event) {
    this.showSpinner = true;
    let draftValues = event.detail.draftValues;
    let isValid = this.validateChanges(draftValues);
    if (isValid) {
      if (this.recordId) {
        let editLineItems = draftValues.map((value) => {
          let fields = { Id: value.Id };
          switch (this.objectApiName) {
            case "Cart__c":
              fields["Quantity__c"] = value.Quantity;
              break;
            case "SBQQ__Quote__c":
              fields["SBQQ__Quantity__c"] = value.Quantity;
              fields["Daily_Rate__c"] = value.Daily_Rate;
              fields["Weekly_Rate__c"] = value.Weekly_Rate;
              fields["Monthly_Rate__c"] = value.Monthly_Rate;
              fields["SBQQ__UnitCost__c"] = value.Sale_Price;
              break;
            case "Order":
              fields["Quantity"] = value.Quantity;
              fields["Daily_Rate__c"] = value.Daily_Rate;
              fields["Weekly_Rate__c"] = value.Weekly_Rate;
              fields["Monthly_Rate__c"] = value.Monthly_Rate;
              fields["UnitPrice"] = value.Sale_Price;
              break;
          }
          let recordIput = { fields };
          return updateRecord(recordIput);
        });
        Promise.all(editLineItems)
          .then(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items edited.",
                variant: "success"
              })
            );
            this.showSpinner = false;
          })
          .catch(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error editing Line Items",
                message: "Error editing Line Items",
                variant: "error"
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
        this.updateLineItemsTable();
        this.showSpinner = false;
      }
      this.draftValues = [];
    }
  }
  handleLineItemSelection(event) {
    let selectedRows = event.target.getSelectedRows();
    this._disableRemoveItem = selectedRows.length > 0 ? false : true;
  }

  @api refreshDataGrid() {
    this.template
      .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
      .saveLineItem()
      .then((data) => {
        if (
          (data && data?.errorCode && data?.errorCode !== undefined) ||
          (data.error &&
            data?.error?.errorCode &&
            data?.error?.errorCode !==
            undefined) /*!logger.isEmpty(data?.errorCode)*/
        ) {
          this.showSpinner = false;
          this.isLoading = false;
          return;
        }
        this.template.querySelector(".editModal").toggleModal();
        var updatedRecordId =
          this.objectApiName == "SBQQ__Quote__c" ? data.Id : data[0].Id;
        let timeoutDuration =
          this.objectApiName == "SBQQ__Quote__c" ? 500 : 15000;
        setTimeout(() => {
          notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
            .then((rec) => {
              this.listInfoRecordId = "";
              this.listInfoRecordId = this.recordId.valueOf();
              refreshApex(this.listInfoResults);
            })
            .catch((error) => {
              console.log("error:" + error);
            });
        }, timeoutDuration);
        setTimeout(() => {
          notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
            .then((rec) => {
              this.listInfoRecordId = "";
              this.listInfoRecordId = this.recordId.valueOf();
              this.isLoading = false;
            })
            .catch((error) => {
              console.log("error:" + error);
            });
        }, 15000);
        // if(data) this.template.querySelector('.editModal').toggleModal();
      })
      .catch((error) => {
        console.log("error: " + error);
        this.isLoading = false;
      });
  }
  showItemEditor = true;
  saveQuoteLine = (event) => {
    console.log("inside refreshDataGrid ");
    if (this.saveButtonLabel === "Back") {
      this.template
        .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
        .setTabValue("EditTab");
      this.template
        .querySelector("c-sbr_3_0_-line-item-edit-wrapper")
        .populateLineData(this.lineIdnew, this.groupIdnew, this.recordIdnew);
      this.handleToggle(); //6267
    } else {
      event.stopPropagation();
      this.isLoading = true;
      this.refreshDataGrid();
    }
    // this.showItemEditor = false;
  };
  //method to validate inline edit inputs
  validateChanges(draftValues) {
    let isValid = true;
    let errors = { rows: {}, table: {} };
    draftValues.forEach((value) => {
      if (parseInt(value.Quantity) < 1) {
        errors.rows[value.Id] = {
          title: "We found 1 error.",
          messages: ["Enter a Quantity greater than 1."],
          fieldNames: ["Quantity"]
        };
        isValid = false;
      }
    });
    errors.table.title =
      "Your entry cannot be saved. Fix the errors and try again.";
    errors.table.messages = ["Enter valid Quantity values."];
    this.draftErrors = errors;
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
      if (rateFlag == "Y") {
        switch (notToExceed) {
          case "S":
            this.showSetRatesBanner = true;
            break;
          case "X":
            this.showDNEBanner = true;
            break;
          case "P":
            this.showPercentBanner = true;
            break;
          case "":
            this.showSpecialRateBanner = true;
            break;
          default:
            break;
        }
      }
    });
    this.invokeCSP();
  }

  showToast(t, m, v) {
    let variant = v == "" ? "info" : v;
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
    if (buttonName === "remove") {
      this.toggleRemoveModal();
    } else if (buttonName === "bulkEdit") {
      if (event.detail.isRental === "true") {
        this.bulkEditRows = this.rentalLineItems;
        this.isSales = false;
      } else if (event.detail.isSales === "true") {
        this.bulkEditRows = this.salesLineItems;
        this.isSales = true;
      }
      this.toggleBulkEdit();
    }
    //FRONT 7653
    else if (buttonName === "cancelItems") {
      this.cancelLineItems();
    }
  }

  //FRONT 7653
  cancelLineItems() {
    let lineIdstoCancel = [];
    let selectedRows = [];
    let orderItemsToUpdateCancelFlag = []; //FRONT-8693
    for (let i = 0; i < this.itemsToRemove.length; i++) {
      lineIdstoCancel.push(this.itemsToRemove[i].Id);
      /* START FRONT-8693*/
      let newItem = {
        Id: this.itemsToRemove[i].Id,
        Item_Marked_For_Cancellation__c: true,
        is_Line_Item_Hidden__c: true
      };
      orderItemsToUpdateCancelFlag.push(newItem);
      /* END FRONT-8693*/
    }
    /* START FRONT-8693*/
    this.isLoading = true;
    if (this.objectApiName == "Order" && this.orderStatus == "Created") {
      updateLineItems(null, orderItemsToUpdateCancelFlag, "OrderItem");
      this.lineItems = this.lineItems.filter(
        (row) => !lineIdstoCancel.includes(row.Id)
      );
      console.log(' from   updateLineItems')
      this.updateLineItemGridData(this.lineItems);
      this.dispatchEvent(
        new ShowToastEvent({
          message: this.label.LINE_ITEMS_CANCEL_SUCCESS,
          variant: "success"
        })
      );
      this.isLoading = false;
      /* END FRONT-8693*/
    } else {
      deleteLineItems({ lineIds: lineIdstoCancel })
        .then((data) => {
          refreshApex(this.listInfoResults);
          this.beginRefresh();
          this.lineItems = this.lineItems.filter(
            (row) => !selectedRows.includes(row.Id)
          );
          console.log(' from  else deleteLineItems')
          this.updateLineItemGridData(this.lineItems);
          this.dispatchEvent(
            new ShowToastEvent({
              message: this.label.LINE_ITEMS_CANCEL_SUCCESS,
              variant: "success"
            })
          );
          this.isLoading = false;
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: this.labels.SINGLE_ITEM_CANCEL,
              variant: "error"
            })
          );
          this.isLoading = false;
        });
    }
  }

  handleRowActionMethod(event) {
    this.handleRowAction(event.detail.newEvent);
  }

  handleRowSaveMethod(event) {
    this.handleSave(event.detail.newEvent);
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
          this.objectApiName === "Order" ||
          this.objectApiName === "SBQQ__Quote__c"
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
                  title: "Success",
                  message: "Line Items deleted.",
                  variant: "success"
                })
              );
            })
            .catch((error) => {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error deleting Line Items",
                  message: error,
                  variant: "error"
                })
              );
            });
        } else {

        }
      }
      this.template.querySelector(".removeModal").toggleModal();
    } else {
      this.isLoading = true;
      //let selectedRows = this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').selectedRows;
      let selectedRows = this.itemsToRemove;

      let removeItemRows;

      //26002
      if (
        this.objectApiName === "Order" ||
        this.objectApiName === "SBQQ__Quote__c"
      ) {
        deleteLineItems({ lineIds: selectedRows })
          .then((data) => {
            refreshApex(this.listInfoResults);
            this.beginRefresh();
            this.lineItems = this.lineItems.filter(
              (row) => !selectedRows.includes(row.Id)
            );
            console.log(' from deleteLineItems')
            this.updateLineItemGridData(this.lineItems);
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items deleted.",
                variant: "success"
              })
            );
            this.isLoading = false;
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error deleting Line Items",
                message: error,
                variant: "error"
              })
            );
            this.isLoading = false;
          });
      }
      this.template.querySelector(".removeModal").toggleModal();
    }
  };
  //method to toggle line item editor on mobile
  editLineItemHandler(event) {
    this.lineId = event.target.getAttribute("id").slice(0, 18);
    this.itemListDisplay = false;
    this.lineItemEditorDisplay = true;
    this.selectedItemGroup = event.target.getAttribute("data-groupid");
    this.template
      .querySelector("c-sbr_3_0_line-item-editor-cmp-frontline")
      .populateLineData(this.lineId, this.selectedItemGroup, this.recordId);
  }
  closeLineItemEditor() {
    this.lineItemEditorDisplay = false;
    this.itemListDisplay = true;
  }
  mobileSaveQuoteLine() {
    this.isLoading = true;
    this.template
      .querySelector("c-sbr_3_0_line-item-editor-cmp-frontline")
      .saveData()
      .then((data) => {
        var updatedRecordId =
          this.objectApiName == "SBQQ__Quote__c" ? data.Id : data[0].Id;
        let timeoutDuration =
          this.objectApiName == "SBQQ__Quote__c" ? 500 : 5000;
        setTimeout(() => {
          notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
            .then((rec) => {
              this.listInfoRecordId = "";
              this.listInfoRecordId = this.recordId.valueOf();
              refreshApex(this.listInfoResults);
              this.isLoading = false;
            })
            .catch((error) => {
              console.log("error:" + error);
            });
        }, timeoutDuration);
        setTimeout(() => {
          notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
            .then((rec) => {
              this.listInfoRecordId = "";
              this.listInfoRecordId = this.recordId.valueOf();
            })
            .catch((error) => {
              console.log("error:" + error);
            });
        }, 8000);
        // if(data) this.template.querySelector('.editModal').toggleModal();
      })
      .catch((error) => {
        console.log("error: " + error);
        this.isLoading = false;
      });
    this.closeLineItemEditor();
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
      case "selectAll":
        this.lineItems.forEach((item) => (item._isChecked = true));
        break;
      case "remove":
        this.removeItems();
        break;
    }
  }
  toggleRemoveModal() {
    this.template.querySelector(".removeModal").toggleModal();
  }
  toggleBulkEdit() {
    this.disbaleConfirmButton = true; //Added as part of FRONT-8759
    let cspSet = new Set();
    this.CSP = null;
    this.CSP_msg = null;
    this.template
      .querySelector("c-sbr_3_0_custom-data-table-edit-cmp")
      .clearDrafts();
    this.lineItems.forEach((item) => {
      if (this.isSales && item.AddedByCrewExpense) {
        this.showSalesMiscError = true;
        this.CSP_msg =
          "Crew & Expense Calculator was used to add Sales/Misc line items. Please return to that section to make edits";
      } else {
        if (item.Specific_Pricing_Type == "Set Rates") {
          this.CSP = "Set Rates";
          this.CSP_msg = "Customer has Set Rates. Bulk Edit not available.";
        } else if (
          this.CSP != "Set Rates" &&
          item.Specific_Pricing_Type == "Do Not Exceed"
        ) {
          this.CSP = "Do Not Exceed";
          this.CSP_msg =
            "Customer has Do Not Exceed Rates. Rates increases not allowed, but can be lowered.";
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        } else if (
          this.CSP != "Set Rates" &&
          item.Specific_Pricing_Type == "Percent Off Local Book"
        ) {
          this.CSP = "Percent Off Local Book";
          this.CSP_msg =
            "Customer has Percent off Local Book Rates. Rates increases not allowed, but can be lowered.";
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        } else if (
          this.CSP != "Set Rates" &&
          item.Specific_Pricing_Type == "Customer Loaded"
        ) {
          this.CSP = "Customer Loaded";
          this.CSP_msg = "Customer has special rates.";
          cspSet.add(this.CSP);
          //this.template.querySelector('.bulkEditModalWarning').toggleModal(); // opens warning
        }
      }
    });

    if (this.showSalesMiscError) {
      this.template.querySelector(".bulkEditModalError").toggleModal();
    }

    if (cspSet.size > 1 && this.CSP != "Set Rates") {
      this.CSP = "Multiple Customer Specific Pricing Detected";
      this.CSP_msg =
        "Customer specific pricing has been applied. Please review line item details for more information.";
      this.template.querySelector(".bulkEditModalWarning").toggleModal(); // opens warning
    } else if (cspSet.size == 1 && this.CSP != "Set Rates") {
      this.template.querySelector(".bulkEditModalWarning").toggleModal(); // opens warning
    }

    if (this.CSP == "Set Rates") {
      this.template.querySelector(".bulkEditModalError").toggleModal(); // opens error
    }

    if (!this.CSP && !this.showSalesMiscError) {
      this.template.querySelector(".bulkEditModal").toggleModal();
    }

    //FRONT-9276
    this.template
      .querySelector(".bulkEditModal")
      .addGreyColourBoundaryToCancelButton();
  }
  showBulkEdit = (event) => {
    event.stopPropagation();
    this.template.querySelector(".bulkEditModalWarning").toggleModal(); // closes warning
    this.template.querySelector(".bulkEditModal").toggleModal(); // open bulk edit
  };
  //Modified as part of FRONT-2195
  hideBulkEdit = (event) => {
    event.stopPropagation();
    this.showSpinner = false;
    this.disbaleConfirmButton = true;
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
        "Invalid Quantity",
        "Please enter a quantity greater than or equal to 1",
        "error"
      );
    }
  }
  mobileQuantity(event) {
    let updatedLineId = event.detail.lineid;
    let updatedQuantity = event.detail.quantity;

    if (updatedQuantity >= 1) {
      this.lineItems.forEach((line) => {
        if (line.Id === updatedLineId) {
          line.Quantity = parseInt(updatedQuantity);
        }
      });
      if (this.objectApiName == undefined) {
        this.updateLineItemsTable();
      } else {
        let fields = { Id: updatedLineId };
        fields["Quantity__c"] = updatedQuantity;
        let recordInput = { fields };
        // return updateRecord(recordIput);

        updateRecord(recordInput)
          .then(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items edited.",
                variant: "success"
              })
            );
            this.updateLineItemsTable();
          })
          .catch(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error editing Line Items",
                message: "Error editing Line Items",
                variant: "error"
              })
            );
          });
      }
    } else {
      this.showToast(
        "Invalid Quantity",
        "Please enter a quantity greater than or equal to 1",
        "error"
      );
    }
  }
  get isQuoteOrOrder() {
    return this.isQuote || this.isOrder;
  }

  get isQuote() {
    if (this.objectApiName == "SBQQ__Quote__c") {
      return true;
    } else {
      return false;
    }
  }

  get isOrder() {
    if (this.objectApiName == "Order") {
      return true;
    } else {
      return false;
    }
  }

  get isCart() {
    return this.objectApiName == "Cart__c";
  }

  get isPI() {
    return !this.objectApiName;
  }

  get isRateQuote() {
    return (
      this.objectApiName == "SBQQ__Quote__c" &&
      this.recordTypeName == "Rate Quote"
    );
  }

  get isQuote() {
    return this.objectApiName == "SBQQ__Quote__c";
  }
  get hasAddOns() {
    return this.hasAddOns;
  }
  get disableRemoveItem() {
    return this._disableRemoveItem;
  }
  get disableBulkEdit() {
    if (this.objectApiName === "Order") {
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
      ? "hidden-mob-container show"
      : "hidden-mob-container";
  }
  get lineItemEditorDisplayClass() {
    return this.lineItemEditorDisplay
      ? "hidden-mob-container show"
      : "hidden-mob-container";
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
      console.log("error in getKitComponents:");
      console.log(error);
    }
  }

  get itemsDynamicLabel() {
    return "Items (" + this.lineItems.length + ")";
  }
  //FRONT-7654 : Modified
  get rentalItemsDynamicLabel() {
    return "Rental Items (" + this.rentalLineItems.length + ")";
  }
  get salesMiscItemsDynamicLabel() {
    return "Sales/Misc Items (" + this.salesLineItems.length + ")";
  }
  //FRONT-7654 : Modified
  get deliveryItemsDynamicLabel() {
    return this.isMobile
      ? "Delivery (" + this.deliveryLineItems.length + ")"
      : "Delivery Items (" + this.deliveryLineItems.length + ")";
  }
  get ancillaryItemsDynamicLabel() {
    return this.isMobile
      ? "Ancillary (" + this.ancillaryLineItems.length + ")"
      : "Ancillary Charges (" + this.ancillaryLineItems.length + ")";
  }

  beginRefresh() {
    this.dispatchEvent(new RefreshEvent());
  }
  refreshHandler() {
    return new Promise((resolve) => {
      console.log(' from refreshHandler')
      this.updateLineItemGridData(this.lineItems);
      resolve(true);
    });
  }

  handleTabSwitch(event) {
    if (event.detail.tabName === "EditTab") {
      this.saveButtonLabel = "Confirm";
    }
    //Added for FRONT-6266
    else if (
      event.detail.tabName === "AvailabilityTab" ||
      event.detail.tabName === "RatesTab"
    ) {
      this.saveButtonLabel = "Back";
    }
    this.lineIdnew = event.detail.lineId;
    this.groupIdnew = event.detail.groupId;
    this.recordIdnew = event.detail.recordId;
  }

  renderedCallback() {
    if (!this.isMobile) {
      Promise.all([loadStyle(this, sbr_3_0_customDataTableCSS)])
        .then(() => {
          logger.log("sbr_3_0_customDataTableCSS file loaded");
        })
        .catch((error) => {
          logger.log(
            "Error in loading sbr_3_0_customDataTableCSS file",
            error.body.message
          );
        });
    }
  }

  /* Start  FRONT-1639 */
  getRowActions(record, doneCallback) {
    let actions;
    if (
      record.Status &&
      record.Status !== "AVAILABLE" &&
      this.recordTypeName !== "Locked Reservation Order"
    ) {
      //FRONT-9245
      actions = orderRentalItemSubstituteLineActions;
    }
    //End of FRONT-7977
    else if (this.recordTypeName === "Locked Reservation Order") {
      actions = lockedReservationOrderLineActions;
    } else if (
      this.isReadOnlyRecord &&
      (this.recordTypeName === "Reservation Order" ||
        this.objectApiName === "SBQQ__Quote__c") //FRONT-10503 Added check to make read only for quote
    ) {
      //FRONT-11421 start
      actions = readOnlyReservationOrderLineActions;
    } //FRONT-11421 end
    else if (
      this.objectApiName === "SBQQ__Quote__c" &&
      !this.isReadOnlyRecord
    ) {
      actions = quoteLineActions; //FRONT - 13054 start
    }
    //End of FRONT-7977
    else {
      actions = orderLineActions;
    }
    //START FRONT-1950
    if (
      this.orderStatus == "Partially Filled" &&
      record.allowCancelStatus === "Filled"
    ) {
      actions = lockedReservationOrderLineActions;
    }
    //END FRONT-1950
    doneCallback(actions);
  }
  /* End  FRONT-1639 */
  closeModal() {
    this.template.querySelector(".editModal").toggleModal();
  }
  //START: FRONT-7652
  refreshRecordsForMobile(event) {
    if (event.detail.isRental) {
      this.rentalLineItems = event.detail.updatedRecords;
    }
    if (event.detail.isSales) {
      this.salesLineItems = event.detail.updatedRecords;
    }
  } //END: FRONT-7652

  //FRONT-7651
  handleCancelItemAction() {
    this.cancelSelectedRows = [];
    this.showCancelLineItemModal = false;
  }
  //FRONT-7651
  handleCancelAction(event) {
    this.itemsToRemove = event.detail.itemsToRemove;
    if (this.itemsToRemove.length === 1) {
      this.cancelLineItems();
    }
  }
  //FRONT-7651
  showCancelChevronBtn() {
    let isCancelCheronAvailable = false;
    for (let orderChevBtn of orderLineActions) {
      if (orderChevBtn.name === "cancel_order_line_item") {
        isCancelCheronAvailable = true;
      }
    }

    if (
      !isCancelCheronAvailable &&
      (this.dataForGrid.appNameFL === "RAE Frontline" ||
        this.dataForGrid.appNameFL === "RAE Sales") && //FRONT-12021 Added RAE Sales as condition to show Cancel button.
      this.objectApiName === "Order" &&
      (this.dataForGrid.orderStatus === "Draft" ||
        this.dataForGrid.orderStatus === "Submitted" ||
        this.dataForGrid.orderStatus === "Created" || //FRONT-9269
        this.dataForGrid.orderStatus === "Partially Filled") && //FRONT-9269
      this.dataForGrid.orderRecordTypeName === "Reservation Order"
    ) {
      return true;
    } else {
      //FRONT-13054 Removed a check for quote since no cancel option for quote.
      return false;
    }
  }

  /* Start  FRONT-1639 */
  notificationFromSubstituteScreen(event) {
    let message = event.detail.message;
    this.showSubstituteModal = false;
    let newEvent;
    if (message !== "close") {
      if (message === "success") {
        let selectedRows = [];
        if (this.isMobile) {
          newEvent = new ShowToastEvent({
            title: "Success",
            message: `${event.detail.data2} has been substituted for ${event.detail.data}`,
            variant: "success"
          });
        } else {
          newEvent = new ShowToastEvent({
            title: "Success",
            message: `${this.substituteItem.Name} has been substituted for ${event.detail.data}`,
            variant: "success"
          });
        }
        refreshApex(this.listInfoResults);
        this.beginRefresh();
        this.lineItems = this.lineItems.filter(
          (row) => !selectedRows.includes(row.Id)
        );
        console.log(' from notificationFromSubstituteScreen')
        this.updateLineItemGridData(this.lineItems);

      } else if (message === "error") {
        newEvent = new ShowToastEvent({
          title: "Error",
          message:
            "Some error has been occurred. Please contact to the administrator",
          variant: "error"
        });
        refreshApex(this.listInfoResults);
      }
      this.dispatchEvent(newEvent);
    }
  }
  /* End  FRONT-1639 */
  //Added as part of FRONT-2195
  handleBack = (event) => {
    this.template.querySelector(".bulkEditConfirmModal").toggleModal();
    this.template.querySelector(".bulkEditModal").toggleModal();
  };

  handleFieldEdits = (event) => {
    if (this.disbaleConfirmButton) this.disbaleConfirmButton = false;
  };
  //FRONT-2195 Ends
  //START: FRONT-8736
  get dynamicFooter() {
    let classes = "";
    if (!this.callCancel) {
      if (
        (this.orderStatus === "Draft" &&
          this.allowHeader !== undefined &&
          this.allowHeader &&
          (this.isSpecificPricingFlag || !this.specificPricingFlag)) ||
        this.isOrderLocked
      ) {
        classes = "dynamicHeightForSection";
      } else {
        classes = "dynamicHeight";
      }
    }
    return classes;
  }
  //END: FRONT-8736

  //START FRONT-9245
  handleChevronActionsForLockedReservation() {
    if (this.recordTypeName === "Locked Reservation Order") {
      this.salesColumns.pop();
      this.salesColumns.push({
        type: "action",
        typeAttributes: {
          rowActions: lockedReservationOrderLineActions,
          menuAlignment: "auto"
        }
      });

      this.deliveryColumns.pop();
      this.deliveryColumns.push({
        type: "action",
        typeAttributes: {
          rowActions: lockedReservationOrderLineActions,
          menuAlignment: "auto"
        }
      });

      this.ancillaryColumns.pop();
      this.ancillaryColumns.push({
        type: "action",
        typeAttributes: {
          rowActions: lockedReservationOrderLineActions,
          menuAlignment: "auto"
        }
      });
    }
  }
  //END FRONT-9245

  //START: FRONT-9235 - appname was coming as null because due to multiple wire method so made wire method reactive using this variable
  get orderNumberDetail() {
    if (this.appName || !this.recordId) {
      //FRONT-11378
      return this.orderNumber;
    } else {
      return undefined;
    }
  }
  //END: FRONT-9235

  //FRONT-7422,7423 START
  @wire(getAvailability, { orderId: "$recordId" })
  ATPgetAvailability({ error, data }) {
    console.log("Inside listInfo", JSON.stringify(data));
    if (data) {
      if (this.objectApiName === "Order") {
        for (const [key, value] of Object.entries(data)) {
          this.availabilityData.set(key, value);
        }
        console.log('availabilityData==1', this.availabilityData.get('0070025'));
        this.updateLineItemsTable();
      }
    } else if (error) {
      console.log("Error for availability:" + JSON.stringify(error));
    }
  }
  //FRONT-7422,7423 END


  //FRONT-11378 start
  toggleSalesItemsPanel(e) {
    let container = this.template.querySelector(".slds-section");
    let isExpanded = e.target.getAttribute("aria-expanded");
    let content = this.template.querySelector(".slds-section__content");
    if (isExpanded == "true") {
      e.target.setAttribute("aria-expanded", false);
      content.setAttribute("aria-hidden", true);
      container.classList.remove("slds-is-open");
    } else {
      e.target.setAttribute("aria-expanded", true);
      content.setAttribute("aria-hidden", false);
      container.classList.add("slds-is-open");
    }
  }

  createSalesItemsColumns() {
    this.cartSalesColumns.sort((a, b) => a.Order__c - b.Order__c);
    this.cartSalesColumns.forEach((col, index) => {
      let colItem = {};
      colItem.label = col.Label;
      colItem.fieldName = col.Field_Name__c;
      colItem.hideDefaultActions = true;
      colItem.sortable = col.IsSortable__c;
      colItem.editable = col.IsEditable__c;
      colItem.type = col.Type__c ? col.Type__c : "text";
      colItem.cellAttributes = {
        class: { fieldName: "noAvailability" }
      };
      if (colItem.fieldName === "Delete_Item") {
        colItem.typeAttributes = {
          iconName: "utility:delete",
          name: "delete"
        };
        colItem.hideLabel = true;
        colItem.label = "";
      }
      if (colItem.fieldName === 'Quantity') { //FRONT-22125
        colItem.cellAttributes = {
          alignment: 'left'
        };
      }
      if (col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;

      this.cartSalesColumns[index] = colItem;
    });
  }
  //FRONT-11378 end

  handleCancelComponentLoad() {
    this.callCancel = true;
  }

  handleCloseCancelModel() {
    this.callCancel = false;
  }

  showLoading() {
    this.isLoading = true;
  }

}