import { LightningElement, api, wire, track } from "lwc";
import {
  publish,
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getProductKitComponents from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents";
import getAddOns from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductAddOns";
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { createMessageContext } from "lightning/messageService";
import CART_OBJECT from "@salesforce/schema/Cart__c";
import CART_ITEMS_OBJECT from "@salesforce/schema/Cart_Items__c";
import QUOTE_OBJECT from "@salesforce/schema/SBQQ__Quote__c";
import QUOTE_LINE_OBJECT from "@salesforce/schema/SBQQ__QuoteLine__c";
import ORDER_OBJECT from "@salesforce/schema/Order";
import ORDER_PRODUCT_OBJECT from "@salesforce/schema/OrderItem";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import createLineItems from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.createLineItems";
import hasAddLinesAccess from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.hasAddLinesAccess";
import getBulkProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBulkProductDetails";
import hasFuelPlan from "@salesforce/apex/SBR_3_0_ProductDA.getProductOptionsWithFuelCharge"; //SF-5291,SF-5292
import * as SBRUtils from "c/sbrUtils";
import { RefreshEvent } from "lightning/refresh";
import updateLineItems from "@salesforce/apex/SBR_3_0_LineItemCartCmpController.updateLineItems";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

export default class Sbr_3_0_addToCartCmp extends LightningElement {
  @api variant = "base";
  @api selectedItemPanel;
  selectedItem;
  get selectedItemPanel() {
    return this.selectedItem;
  }
  set selectedItemPanel(value) {
    this.selectedItem = value;
  }
  @api recordId;
  @api objectApiName;
  @api disableAddToCart = false;
  @api isParentAddToCart;
  @api companyCode;
  @api customerNumber;
  @api contractSalesTab; //added for FRONT-15258
  _hasRatesLoaded = true;
  @api
  get hasRatesLoaded() {
    return this._hasRatesLoaded;
  }

  set hasRatesLoaded(value) {
    this._hasRatesLoaded = value;
  }

  @api
  get parentQtyFromChild() {
    return this.count;
  }

  set parentQtyFromChild(value) {
    this.count =
      value == null
        ? 1
        : this.variant == "addon" &&
            this.selectedItem?.value?.isRequired &&
            this.selectedItem?.value?.itemType == "rental" &&
            this.selectedItem?.value?.availQuantity
          ? value * this.selectedItem?.value?.availQuantity
          : value;
  }
  count = 1;
  @api maxCount;
  @api originrecordid;
  btnLabel = "Add to Cart";

  isMobile = false;
  kitItems = [];
  allAddOns = [];
  atcRecordArr = []; // array to perform promise.all
  groupId = Math.random().toString(16).slice(2); // UID for required add-ons
  groupSize;
  subscription = null;
  cartHasRental = false;

  toastMessage;
  @track isLoading = false;

  itemProductTypeArr = []; //23583

  recordIdConst = "";

  relatedListId = "";
  fields = [];
  existingLineItems = [];
  listInfoResults;
  updateRecordArr = [];
  messageContext = createMessageContext();
  kitComponentRates = [];
  disableBtn = false;
  hideBtn = false;
  dataFuelPlan = false; //SF-5291,SF-5292

  salesContractEditorModalHeader;
  @api costPrice;
  @api isMiscProductType;

  get itemTypeVariant() {
    return this.isMiscProductType ? "Misc" : "Sales";
  }

  async connectedCallback() {
    if (this.selectedItem && this.selectedItem.length > 0) {
      //SF-5291,SF-5292
      const fuelFlag = await hasFuelPlan({
        productIds: [this.selectedItem[0].Id],
        companyCode: [this.companyCode]
      });
      //this.dataFuelPlan = fuelFlag.hasFuelCharge;
      this.dataFuelPlan = fuelFlag !== null && fuelFlag !== undefined; // new change
      console.log("this.dataFuelPlan" + this.dataFuelPlan);
    }
    // Check if selectedItem is present and it is a kit
    if (
      this.selectedItem?.length > 0 &&
      this.selectedItem[0].Is_Kit__c === "Yes"
    ) {
      this.disableBtn = true;
      await this.getKitComponents();
      await this.getKitComponentRates();
    }

    // Check FORM_FACTOR for mobile
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }

    // Initialize recordId related variables if available
    if (this.recordId) {
      this.recordIdConst = this.recordId;
      this.handleAccess();
      this.initRecordContextVariables();
    }
  }

  // SAL-24302 START
  initRecordContextVariables() {
    if (this.recordId) {
      switch (this.objectApiName) {
        case "Cart__c":
          this.relatedListId = "Cart_Items__r";
          this.fields = [
            "Cart_Items__c.Id",
            "Cart_Items__c.Product__r.Product_SKU__c",
            "Cart_Items__c.Quantity__c",
            "Cart_Items__c.Kit_Number_This_Item_Belongs_To__c"
          ];
          break;
        case "SBQQ__Quote__c":
          this.relatedListId = "SBQQ__LineItems__r";
          this.fields = [
            "SBQQ__QuoteLine__c.Id",
            "SBQQ__QuoteLine__c.Product_SKU__c",
            "SBQQ__QuoteLine__c.SBQQ__Quantity__c",
            "SBQQ__QuoteLine__c.Kit_Number_this_Item_Belongs_to__c"
          ];
          break;
        case "Order":
          this.relatedListId = "OrderItems";
          this.fields = [
            "OrderItem.Id",
            "OrderItem.Product2.Product_SKU__c",
            "OrderItem.Quantity",
            "OrderItem.Kit_Number_This_Item_Belongs_To__c"
          ];
          break;
      }
    }
  }

  handleAccess() {
    hasAddLinesAccess({ recordId: this.recordId })
      .then((result) => {
        this.disableAddToCart = !result;
      })
      .catch((error) => {
        console.log("Error getting record access " + error.message);
      });
  }
  /*changes by Aman - to be tested */
  @wire(getRelatedListRecords, {
    parentRecordId: "$recordIdConst",
    relatedListId: "$relatedListId",
    fields: "$fields"
  })
  listInfo(result) {
    this.listInfoResults = result;
    let data = result.data,
      error = result.error;
    if (data) {
      this.existingLineItems = this.mapExistingLineItems(data.records);
    } else if (error) {
      console.error("Error getting related list records " + error);
    }
  }
  mapExistingLineItems(records) {
    switch (this.objectApiName) {
      case "Cart__c":
        return this.mapCartRecords(records);
      case "SBQQ__Quote__c":
        return this.mapQuoteRecords(records);
      case "Order":
        return this.mapOrderRecords(records);
      default:
        return [];
    }
  }

  mapCartRecords(records) {
    return records.map((record) => ({
      Id: record.fields.Id.value,
      quantity: record.fields.Quantity__c.value,
      catClass: record.fields.Product__r.value.fields.Product_SKU__c.value,
      kitNumberBelongsTo: record.fields.Kit_Number_This_Item_Belongs_To__c.value //SF-6457
    }));
  }

  mapQuoteRecords(records) {
    return records.map((record) => ({
      Id: record.fields.Id.value,
      quantity: record.fields.SBQQ__Quantity__c.value,
      catClass: record.fields.Product_SKU__c.value,
      kitNumberBelongsTo: record.fields.Kit_Number_this_Item_Belongs_to__c.value //SF-6457
    }));
  }

  mapOrderRecords(records) {
    return records.map((record) => ({
      Id: record.fields.Id.value,
      quantity: record.fields.Quantity.value,
      catClass: record.fields.Product2.value.fields.Product_SKU__c.value,
      kitNumberBelongsTo: record.fields.Kit_Number_This_Item_Belongs_To__c.value //SF-6457
    }));
  }
  //SAL-24032 END
  //24085
  requiredAddOns = {
    parentId: null,
    rentalAddOns: [],
    salesAddOns: [],
    forcedItemAddOns: []
  };

  @api resetCount() {
    this.count = 1;
  }

  addItem() {
    if (this.maxCount && this.maxCount > 0) {
      this.count =
        this.count == this.maxCount ? this.maxCount : (this.count += 1);
    } else {
      this.count += 1;
    }
    this.parentItemQtyChange();
  }
  subtractItem() {
    this.count = this.count == 1 ? this.count : (this.count -= 1);
    this.parentItemQtyChange();
  }
  handleCountChange(event) {
    var numerics = /^\+?[1-9]\d*$/;
    var countInput = event.target.value;
    if (countInput.match(numerics)) {
      this.count = parseInt(countInput);
    } else if (countInput == 0) {
      this.count = 1;
      event.target.value = 1;
    } else {
      event.target.value = this.count;
    }
    this.parentItemQtyChange();
  }

  parentItemQtyChange() {
    // Creates the event with the data.
    if (this.isParentAddToCart) {
      const selectedEvent = new CustomEvent("parentitemqtychange", {
        detail: this.count
      });
      // Dispatches the event.
      this.dispatchEvent(selectedEvent);
    }
  }

  get isBase() {
    return this.variant === "base";
  }

  get variantClass() {
    if (this.isMobile) {
      switch (this.variant) {
        case "base":
          return "mobile-atc-footer slds-p-around_small";
        case "addon":
          return "";
        default:
          return "mobile-atc-footer slds-p-around_small";
      }
    } else {
      switch (this.variant) {
        case "base":
          return "atc-footer slds-p-around_small";
        case "addon":
          return "atc-addon";
        default:
          return "atc-footer slds-p-around_small";
      }
    }
  }
  get atcButtonClass() {
    if (this.isMobile) {
      if (this.disableAddToCart) {
        switch (this.variant) {
          case "base":
            return "mobile-atc-disabled slds-button slds-button_brand";
          case "addon":
            return "mobile-atc-outline-disabled slds-button slds-button_outline-brand";
          default:
            return "mobile-atc-disabled slds-button slds-button_brand";
        }
      } else {
        switch (this.variant) {
          case "base":
            return "mobile-atc slds-button slds-button_brand";
          case "addon":
            return "mobile-atc-outline slds-button slds-button_outline-brand";
          default:
            return "mobile-atc slds-button slds-button_brand";
        }
      }
    } else {
      switch (this.variant) {
        case "base":
          return "slds-button slds-button_brand";
        case "addon":
          return "slds-button slds-button_outline-brand";
        default:
          return "slds-button slds-button_brand";
      }
    }
  }
  get addItemBtnLabel() {
    if (!this.hasRatesLoaded) {
      return "Fetching Rates..";
    }
    switch (this.objectApiName) {
      case "Cart__c":
        return "Add to Cart";
      case "SBQQ__Quote__c":
        return "Add to Quote";
      case "Order":
        //below condition added for FRONT-15258
        if (this.contractSalesTab == true) {
          return "Add to Contract";
        } else {
          return "Add to Order";
        }
      default:
        return "Add to Cart";
    }
  }

  addKitComponents() {
    return new Promise((resolve, reject) => {
      if (
        Array.isArray(this.selectedItem) &&
        this.selectedItem[0].Is_Kit__c === "Yes" &&
        this.variant === "base"
      ) {
        let lineItem = {};
        let payload;
        lineItem.name = this.selectedItem[0].Name;
        lineItem.id = this.selectedItem[0].Id;
        lineItem.catClass = this.selectedItem[0].Product_SKU__c;
        lineItem.itemType = "base";
        lineItem.isKit = this.selectedItem[0].Is_Kit__c;
        lineItem.changeable = this.selectedItem[0].Changeable__c;
        lineItem.SalesforceManagedKit =
          this.selectedItem[0].Salesforce_Managed_Kit__c; // SAL-27182
        lineItem.productType = this.selectedItem[0].Product_Type__c;
        lineItem.kitItems = [];
        lineItem.quantity = this.count;
        this.getKitComponents()
          .then(() => {
            lineItem.kitItems = this.kitItems;
            if (this.isParentAddToCart) {
              lineItem.groupId = this.groupId;
            }
            this.kitItems.forEach((kItem) => {
              payload = {
                recordId: this.recordId,
                lineItem: {
                  name: kItem.SBQQ__ProductName__c,
                  id: kItem.SBQQ__OptionalSKU__c,
                  catClass:
                    kItem.SBQQ__OptionalSKU__r.Category__c.padStart(3, "0") +
                    kItem.SBQQ__OptionalSKU__r.Class__c.padStart(4, "0"),
                  itemType: "base",
                  quantity: kItem.SBQQ__Quantity__c * this.count,
                  isKit: true
                },
                isBulk: false,
                type: "add"
              };
              publish(this.messageContext, updateLineItemsChannel, payload);
            });
            this.createLineItemRecord(lineItem, "Kit");
            resolve(); // Resolve the Promise
          })
          .catch((error) => {
            reject(error); // Reject the Promise in case of an error
          });
      } else {
        resolve(); // Resolve the Promise
      }
    });
  }

  async addToCart() {
    refreshApex(this.listInfoResults);
    //FRONT-22235/22237 to open add to contract modal
    if (this.contractSalesTab) {
      this.showContractSalesModal(this.selectedItem);
      return;
    }
    //End

    this.isLoading = true;
    const selectEvent = new CustomEvent("showspinner", {
      detail: this.isLoading
    });
    this.dispatchEvent(selectEvent);
    let payload;
    let isUpdate = false;
    // reset variables
    this.atcRecordArr = [];

    // SAL-26342 - SAL-26352
    if (this.variant === "base") {
      if (
        this.selectedItem[0].Is_Kit__c !== "Yes" &&
        (this.selectedItem[0].Min_Rate == "N/A" ||
          this.selectedItem[0].Min_Rate == "n/a") &&
        (this.selectedItem[0].Daily_Rate == "N/A" ||
          this.selectedItem[0].Daily_Rate == "n/a") &&
        (this.selectedItem[0].Weekly_Rate == "N/A" ||
          this.selectedItem[0].Weekly_Rate == "n/a") &&
        (this.selectedItem[0].Monthly_Rate == "N/A" ||
          this.selectedItem[0].Monthly_Rate == "n/a")
      ) {
        const toastEvent = new ShowToastEvent({
          title: "Error adding line items",
          message:
            "Line Items could not be added. If issue persists, please contact your System Administrator.",
          variant: "error"
        });
        this.dispatchEvent(toastEvent);
        return;
      }
    }
    if (!this.recordId) {
      console.log("inside product inq if");
      // Product Inquiry
      let lineItem = {};
      if (this.variant === "base") {
        console.log("inside bse variant");
        lineItem.name = this.selectedItem[0].Name;
        lineItem.id = this.selectedItem[0].Id || this.selectedItem[0].id;
        lineItem.catClass = this.selectedItem[0].Product_SKU__c;
        lineItem.itemType = "base";
        lineItem.isKit = this.selectedItem[0].Is_Kit__c;
        lineItem.changeable = this.selectedItem[0].Changeable__c;
        lineItem.productType =
          this.selectedItem[0]?.Product_Type__c ||
          this.selectedItem[0]?.ItemType;
        lineItem.hasFuelPlan = this.dataFuelPlan; //SF-5291,SF-5292
        lineItem.SalesforceManagedKit =
          this.selectedItem[0].Salesforce_Managed_Kit__c; // SAL-27182
        //id of the product record associated with selected product
        lineItem.kitItems = [];
        lineItem.quantity = this.count;
        if (this.selectedItem[0].Is_Kit__c === "Yes") {
          //await this.getKitComponents();
          lineItem.kitItems = [];
          if (!SBRUtils.isEmpty(this.kitItems)) {
            this.kitItems.forEach((kitItem) => {
              //find kit cmp rates
              let kitComponent = this.kitComponentRates.find(
                (item) => item.id == kitItem.SBQQ__OptionalSKU__c
              );
              if (!SBRUtils.isEmpty(kitComponent)) {
                // SAL-27182
                kitItem.Min_Rate = 0; //kitComponent?.minRate ? kitComponent.minRate : 0;
                //SF-7417
                kitItem.Daily_Rate = this.selectedItem[0]
                  .Salesforce_Managed_Kit__c
                  ? kitComponent.ratesDaily
                  : 0; //kitComponent?.ratesDaily ? kitComponent.ratesDaily : 0;
                kitItem.Weekly_Rate = this.selectedItem[0]
                  .Salesforce_Managed_Kit__c
                  ? kitComponent.ratesWeekly
                  : 0; //kitComponent?.ratesWeekly ? kitComponent?.ratesWeekly : 0;
                kitItem.Monthly_Rate = this.selectedItem[0]
                  .Salesforce_Managed_Kit__c
                  ? kitComponent.ratesMonthly
                  : 0; //kitComponent?.ratesMonthly ? kitComponent?.ratesMonthly : 0;
                kitItem.Kit_Number_This_Item_Belongs_To__c =
                  this.selectedItem[0].Product_SKU__c;
                kitItem.Rate_Branch = this.selectedItem[0]?.Rate_Branch
                  ? this.selectedItem[0].Rate_Branch
                  : "";
              }
              lineItem.kitItems.push(kitItem);
            });
          }
        }
        if (this.isParentAddToCart) {
          lineItem.groupId = this.groupId; // UID for required add-ons
        }
        // SAL-26036
        lineItem.inventoriedFlag = this.selectedItem[0].Inventoried_Item__c
          ? this.selectedItem[0].Inventoried_Item__c
          : false;
        lineItem.miscChargeItemFlag = this.selectedItem[0]
          .Miscellaneous_Charge_Item__c
          ? this.selectedItem[0].Miscellaneous_Charge_Item__c
          : false;
        lineItem.typeMiscChargeItem = this.selectedItem[0]
          .Type_of_Misc_Charge_Item__c
          ? this.selectedItem[0].Type_of_Misc_Charge_Item__c
          : "";
        lineItem.Min_Rate = this.selectedItem[0]?.Min_Rate
          ? this.selectedItem[0].Min_Rate
          : 0;
        lineItem.Daily_Rate = this.selectedItem[0]?.Daily_Rate
          ? this.selectedItem[0].Daily_Rate
          : 0;
        lineItem.Weekly_Rate = this.selectedItem[0]?.Weekly_Rate
          ? this.selectedItem[0].Weekly_Rate
          : 0;
        lineItem.Monthly_Rate = this.selectedItem[0]?.Monthly_Rate
          ? this.selectedItem[0].Monthly_Rate
          : 0;
        lineItem.Rate_Branch = this.selectedItem[0]?.Rate_Branch
          ? this.selectedItem[0].Rate_Branch
          : "";
      } else if (this.variant === "addon") {
        console.log("inside addon");
        lineItem.name = this.selectedItem.value.name;
        lineItem.id = this.selectedItem.value.id;
        lineItem.catClass = this.selectedItem.value.catClass;
        lineItem.itemType = this.selectedItem.value.itemType;
        lineItem.sellPrice = this.selectedItem.value.sellPrice;
        lineItem.productType = this.selectedItem.value.productType;
        lineItem.itemNumber = this.selectedItem.value.itemNumber;
        lineItem.stockClass = this.selectedItem.value.stockClass;
        lineItem.quantity = this.count;
        lineItem.Rate_Branch = this.selectedItem.value.rateBranch
          ? this.selectedItem.value.rateBranch
          : ""; // SF-27670
        //FRONT-11309 add to cart from sales tab
      } else if (this.variant === "consumableSalesAddOn") {
        console.log("inside consumableSalesAddOn");
        lineItem.name = this.selectedItem[0].name;
        lineItem.id = this.selectedItem[0].Id || this.selectedItem[0].id;
        lineItem.sellPrice = this.selectedItem[0].sellPrice;
        lineItem.productType = "Parts";
        lineItem.itemNumber = this.selectedItem[0].itemNumber;
        lineItem.stockClass = this.selectedItem[0].stockClass;
        lineItem.quantity = this.count;
        lineItem.itemType = this.variant;
      }
      // need to refactor/fix bulk add so this can be simplified
      if (this.variant === "base" && this.selectedItem[0].Is_Kit__c === "Yes") {
        let lineItemProdInfo = {};
        this.kitItems.forEach((kItem) => {
          // SAL-27018
          lineItemProdInfo = {
            productType: kItem.SBQQ__OptionalSKU__r.Product_Type__c,
            catClass:
              kItem.SBQQ__OptionalSKU__r.Category__c.padStart(3, "0") +
              kItem.SBQQ__OptionalSKU__r.Class__c.padStart(4, "0"),
            stockClass: this.selectedItem[0].Stock_class__c,
            inventoriedFlag: kItem.SBQQ__OptionalSKU__r.Inventoried_Item__c,
            miscChargeItemFlag:
              kItem.SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c,
            typeMiscChargeItem:
              kItem.SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c
          };
          payload = {
            recordId: this.recordId,
            lineItem: {
              name: kItem.SBQQ__ProductName__c, // SAL-27182
              id: kItem.SBQQ__OptionalSKU__c,
              productType: kItem.SBQQ__OptionalSKU__r.Product_Type__c,
              catClass:
                kItem.SBQQ__OptionalSKU__r.Category__c.padStart(3, "0") +
                kItem.SBQQ__OptionalSKU__r.Class__c.padStart(4, "0"),
              itemType: "base",
              quantity: kItem.SBQQ__Quantity__c * this.count,
              isKit: true,
              lineItemType: this.getLineItemType(lineItemProdInfo), // SAL-27018
              Kit_Number_This_Item_Belongs_To__c:
                this.selectedItem[0].Product_SKU__c,
              kitNumberBelongsTo: this.selectedItem[0].Product_SKU__c,
              //quantityEditable: this.selectedItem[0].Changeable__c ? true : false  // SAL-27182
              quantityEditable: this.selectedItem[0].Salesforce_Managed_Kit__c
                ? true
                : false, // SAL-27182
              SalesforceManagedKit:
                this.selectedItem[0].Salesforce_Managed_Kit__c, // SAL-27182
              changeable: this.selectedItem[0].Changeable__c, // SAL-27182
              Rate_Branch: this.selectedItem[0]?.Rate_Branch
                ? this.selectedItem[0].Rate_Branch
                : ""
            },
            isBulk: false,
            type: "add"
          };
          //SF-7417
          let kitComponent = this.kitComponentRates.find(
            (item) => item.id == kItem.SBQQ__OptionalSKU__c
          );
          if (!SBRUtils.isEmpty(kitComponent)) {
            payload.lineItem.Daily_Rate = this.selectedItem[0]
              .Salesforce_Managed_Kit__c
              ? kitComponent.ratesDaily
              : 0;
            payload.lineItem.Weekly_Rate = this.selectedItem[0]
              .Salesforce_Managed_Kit__c
              ? kitComponent.ratesWeekly
              : 0;
            payload.lineItem.Monthly_Rate = this.selectedItem[0]
              .Salesforce_Managed_Kit__c
              ? kitComponent.ratesMonthly
              : 0;
          }
          publish(this.messageContext, updateLineItemsChannel, payload);
        });
        if (this.selectedItem[0].Salesforce_Managed_Kit__c === false) {
          // SAL-27182 : Changeable__c
          payload = {
            recordId: this.recordId,
            // SAL-26036
            lineItem: lineItem,
            isBulk: false,
            type: "add"
          };
          publish(this.messageContext, updateLineItemsChannel, payload);
        }
      } else {
        // add a subtype variable for 'sales' or 'rental' to determine which API to use
        // SAL-26036
        console.log("inside else");
        let lineItemProdInfo1 = {
          productType: lineItem.productType,
          catClass: lineItem.catClass,
          //stockClass: lineItem.stockClass,
          inventoriedFlag: lineItem.inventoriedFlag,
          miscChargeItemFlag: lineItem.miscChargeItemFlag,
          typeMiscChargeItem: lineItem.typeMiscChargeItem
        };
        // SAL-26036
        lineItem.lineItemType = this.getLineItemType(lineItemProdInfo1);
        payload = {
          recordId: this.recordId,
          // SAL-26036
          lineItem: lineItem,
          isBulk: false,
          type: "add"
        };
        publish(this.messageContext, updateLineItemsChannel, payload);
        await this.getRequiredAddOns();
        console.log("after getRequiredAddOns");
        if (
          this.requiredAddOns.rentalAddOns.length > 0 ||
          this.requiredAddOns.salesAddOns.length > 0 ||
          this.requiredAddOns.forcedItemAddOns.length > 0
        ) {
          this.atcRequiredAddOns();
        }
        //24085
        if (this.requiredAddOns.forcedItemAddOns.length > 0) {
          this.requiredAddOns.forcedItemAddOns.forEach((forcedItemAddOn) => {
            this.createLineItemRecord(forcedItemAddOn, "forcedItem");
          });
        }
      }

      this.toastMessage = "The items(s) were added to Cart";
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.toastMessage,
          variant: "success"
        })
      );

      if (
        !this.isMobile &&
        (this.recordId == "undefined" || this.recordId == undefined)
      ) {
        // SAL-27238 => addOns deselect
        if (this.variant !== "addon") {
          publish(this.messageContext, deselectProductRowChannel, {
            productId: null,
            variant: this.variant
          });
        }
      }
    } else {
      // Have record Id ( Cart/Quote/Order )

      await this.getRequiredAddOns();

      if (!this.isMobile) {
        // SAL-27238 => addOns deselect
        if (this.variant !== "addon") {
          publish(this.messageContext, deselectProductRowChannel, {
            productId: null
          });
        }
      }
      // SF-7556
      if (this.isMobile) {
        setTimeout(() => {
          this.createOrUpdateLI(isUpdate);
        }, 2000);
      } else {
        this.createOrUpdateLI(isUpdate);
      }
    }

    // for PI and Cart , as we call estimate API as well
    if (this.objectApiName !== "Order") {
      setTimeout(() => {
        this.handleLoadingState(false);
      }, 8000);
    } else {
      // in case of Order queueable jobs to finish increasing delay
      setTimeout(() => {
        this.handleLoadingState(false);
      }, 10000);
    }
    if (this.objectApiName == undefined && this.isMobile) {
      this.dispatchEvent(new RefreshEvent());
    }
  }
  //SF-7556
  createOrUpdateLI(isUpdate) {
      let productType;
      let stockClass;
      let itemNumber;
      // add parent item to list of records being created
      if (this.isParentAddToCart && this.variant == "base") {
        productType =
          this.selectedItem[0].Product_Type__c != undefined ||
          this.selectedItem[0].Product_Type__c != null
            ? this.selectedItem[0].Product_Type__c
            : this.selectedItem[0]?.ItemType || ""; //23583
        itemNumber =
          this.selectedItem[0].Item_Number__c != undefined ||
          this.selectedItem[0].Item_Number__c != null
            ? this.selectedItem[0].Item_Number__c
            : ""; //23583
        stockClass =
          this.selectedItem[0].Stock_class__c != undefined ||
          this.selectedItem[0].Stock_class__c != null
            ? this.selectedItem[0].Stock_class__c
            : ""; //23583
        this.createLineItemRecord(this.selectedItem[0], this.variant);
      } else if (this.variant == "addon") {
        productType =
          this.selectedItem.value.productType != undefined ||
          this.selectedItem.value.productType != null
            ? this.selectedItem.value.productType
            : ""; //23583
        itemNumber =
          this.selectedItem.value.itemNumber != undefined ||
          this.selectedItem.value.itemNumber != null
            ? this.selectedItem.value.itemNumber
            : ""; //23583
        stockClass =
          this.selectedItem.value.stockClass != undefined ||
          this.selectedItem.value.stockClass != null
            ? this.selectedItem.value.stockClass
            : ""; //23583

        this.createLineItemRecord(
          this.selectedItem.value,
          this.selectedItem.value.itemType
        );
      } else if (this.variant === "consumableSalesAddOn") {
        this.createLineItemRecord(this.selectedItem[0], "consumableSalesAddOn");
      }
      // then add required addOns
      if (
        this.requiredAddOns.rentalAddOns.length > 0 ||
        this.requiredAddOns.salesAddOns.length > 0
      ) {
        this.requiredAddOns.rentalAddOns.forEach((rentalAddOn) => {
          this.createLineItemRecord(rentalAddOn, "rental");
        });
        this.requiredAddOns.salesAddOns.forEach((salesAddOn) => {
          this.createLineItemRecord(salesAddOn, "sales");
        });
      }
      // then add forced item addOns. 24085
      if (this.requiredAddOns.forcedItemAddOns.length > 0) {
        this.requiredAddOns.forcedItemAddOns.forEach((forcedItemAddOn) => {
          this.createLineItemRecord(forcedItemAddOn, "forcedItem");
        });
      }
      this.addKitComponents()
        .then(() => {
          let cartItemsPromises = [];
        if (Array.isArray(this.atcRecordArr) && this.atcRecordArr.length > 0) {
            createLineItems({
              apiName: this.objectApiName,
              lineItems: JSON.stringify(this.atcRecordArr)
            })
              .then((result) => {
                result.forEach((createdLineItem) => {
                  const payload = {
                    recordId: this.recordId,
                    lineItem: createdLineItem,
                    quantity:
                      this.objectApiName === "Order"
                        ? createdLineItem.Quantity
                        : this.count,
                    type: "add",
                    isKit:
                      this.variant === "addon"
                        ? "No"
                        : this.selectedItem[0].Is_Kit__c
                  };
                  payload.lineItem.CatClass = createdLineItem?.Cat_Class__c; //has been refered in other cmps so need to populate
                  this.itemProductTypeArr.forEach((itemProdinfo) => {
                  if (payload.lineItem.Cat_Class__c == itemProdinfo.catClass) {
                      payload.productType = itemProdinfo.productType;
                      payload.lineItem.Name = itemProdinfo.name;
                      if (
                        itemProdinfo.stockClass != undefined ||
                        itemProdinfo.stockClass != null
                      ) {
                        payload.stockClass = itemProdinfo.stockClass;
                      }
                      if (
                        itemProdinfo.itemNumber != undefined ||
                        itemProdinfo.itemNumber != null
                      ) {
                        payload.itemNumber = itemProdinfo.itemNumber;
                      }
                    } else if (
                      this.objectApiName == "SBQQ__Quote__c" &&
                      payload.lineItem.SBQQ__Product__c == itemProdinfo.itemId
                    ) {
                      payload.lineItem.Name = itemProdinfo.name;
                    } else if (
                      this.objectApiName == "Order" &&
                      payload.lineItem.Product2Id == itemProdinfo.itemId
                    ) {
                      payload.lineItem.Name = itemProdinfo.name;
                    }
                  });

                  publish(this.messageContext, updateLineItemsChannel, payload);
                });
              })
              .catch((error) => {
                console.log("Error adding kit components " + error.message);
              //SF-8225
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error",
                  message: error.message,
                  variant: "error"
                })
              );
              });
            let isShowToast = 0;

            if (isShowToast == this.atcRecordArr.length - 1) {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: this.toastMessage,
                  variant: "success"
                })
              );
            }
            if (!this.isMobile) {
              // SAL-27238 => addOns deselect
              if (this.variant !== "addon") {
                publish(this.messageContext, deselectProductRowChannel, {
                  productId: null,
                  variant: this.variant
                });
              }
            }
          }

          //SAL-26467
          if (
            Array.isArray(this.updateRecordArr) &&
            this.updateRecordArr.length > 0
          ) {
            updateLineItems({
              apiName: this.objectApiName,
              lineItems: JSON.stringify(this.updateRecordArr)
            })
              .then((result) => {
                result.forEach((updatedLineItem) => {
                  const payload = {
                    recordId: updatedLineItem.id,
                    lineItem: updatedLineItem,
                    quantity:
                      this.objectApiName === "Order"
                        ? updatedLineItem.Quantity
                        : this.objectApiName == "SBQQ__Quote__c"
                          ? updatedLineItem.SBQQ__Quantity__c
                          : this.count,
                    type: "update",
                    isKit:
                      this.variant === "addon"
                        ? "No"
                        : this.selectedItem[0].Is_Kit__c
                  };

                  publish(this.messageContext, updateLineItemsChannel, payload);
                });
              })
              .catch((error) => {
                console.log("Error adding kit components " + error.message);
              });

            /* cartItemsPromises = this.updateRecordArr.map(cartItem => updateRecord(cartItem).then(updtResult => {
                    
                    const payload = {
                        recordId: updtResult.id,
                        lineItem: updtResult,
                        quantity: (this.objectApiName === 'Order') ? updtResult.fields.Quantity : (this.objectApiName == 'SBQQ__Quote__c') ? updtResult.fields.SBQQ__Quantity__c : this.count,
                        type: 'update',
                        isKit: this.variant==='addon'? 'No' : this.selectedItem[0].Is_Kit__c
                    };

                    publish(this.messageContext, updateLineItemsChannel, payload);
                    })); */
            isUpdate = true;
            if (!this.isMobile) {
              // SAL-27238 => addOns deselect
              if (this.variant !== "addon") {
                publish(this.messageContext, deselectProductRowChannel, {
                  productId: null
                });
              }
            }
          }
        })
        .catch((error) => {
          console.log("Error resolving kit cmp promise " + error.message);
          if (!this.isMobile) {
            this.isLoading = false;
            const selectEvent = new CustomEvent("showspinner", {
              detail: this.isLoading
            });
            this.dispatchEvent(selectEvent);
          }
        });

    if (isUpdate) {
      this.toastMessage = "Quantity Updated";
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.toastMessage,
          variant: "success"
        })
      );
      refreshApex(this.listInfoResults);
    } else {
      /*conditon added as a part of FRONT-14366 and FRONT-14365*/
      if (this.isMobile) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: this.toastMessage,
            variant: "success"
          })
        );
      } else {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: this.toastMessage,
            variant: "success"
          })
        );
      }
    }
    }
  handleLoadingState(isLoading) {
    this.isLoading = isLoading;
    const selectEvent = new CustomEvent("showspinner", {
      detail: this.isLoading
    });
    this.dispatchEvent(selectEvent);
  }

  async getKitComponents() {
    let data;
    try {
      data = await getProductKitComponents({
        productId: this.selectedItem[0].Id
      });
      this.kitItems = JSON.parse(data);
    } catch (error) {
      console.log("Error fetching kit components " + error.message);
    }
  }

  // get requiredAddOns for an item
  async getRequiredAddOns() {
    this.requiredAddOns = {
      parentId: null,
      rentalAddOns: [],
      salesAddOns: [],
      forcedItemAddOns: []
    };
    let data;
    try {
      data = await getAddOns({
        productId: this.selectedItem[0].id || this.selectedItem[0].Id,
        companyCode: this.companyCode,
        recordId: this.recordIdConst,
        branch: this.selectedItem[0].Rate_Branch
      });
      let addOns = JSON.parse(data);

      if (addOns) {
        if (addOns.rentalAddOns) {
          addOns.rentalAddOns.forEach((ao) => {
            //SF-5291,SF-5292
            let rentalAddOnName = ao.name;
            if (
              ao.isRequired === true ||
              rentalAddOnName.includes("Fuel Convenience Charge")
            )
              this.requiredAddOns.rentalAddOns.push(ao); //SF-5879
          });
        }
        if (addOns.salesAddOns) {
          addOns.salesAddOns.forEach((ao) => {
            //SF-5291,SF-5292
            let salesAddOnName = ao.name;
            if (
              ao.isRequired === true ||
              salesAddOnName.includes("Fuel Convenience Charge")
            )
              this.requiredAddOns.salesAddOns.push(ao); //SF-5879
          });
        }
        this.requiredAddOns.parentId = this.selectedItem[0].Id;
        this.groupSize =
          this.requiredAddOns.rentalAddOns.length +
          this.requiredAddOns.salesAddOns.length;
      }
    } catch (error) {
      console.log("Error fetching addons " + error.message);
    }
  }

  // publish event to create required add-ons for Product Inquiry
  atcRequiredAddOns() {
    try {
      if (this.isParentAddToCart && this.variant === "base") {
        this.requiredAddOns.rentalAddOns.forEach((rentalAddOn) => {
          let addOnRentalProdname = rentalAddOn?.name;
          let hasFuelProductRental =
            addOnRentalProdname.indexOf("Fuel Convenience Charge") !== -1
              ? true
              : false; //SF-5879
          let rentalPayload = {};
          // SF-5303
          let lineItemProdInfo1 = {
            productType: rentalAddOn.productType,
            catClass: rentalAddOn.catClass,
            //stockClass: lineItem.stockClass,
            inventoriedFlag: rentalAddOn.inventoriedItem,
            miscChargeItemFlag: rentalAddOn.miscellaneousChargeItem,
            typeMiscChargeItem: rentalAddOn.typeOfMiscChargeItem,
            stockClass: rentalAddOn.stockClass,
            name: rentalAddOn.name
          };

          rentalPayload = {
            recordId: this.recordId,
            lineItem: {
              name: rentalAddOn.name,
              id: rentalAddOn.id,
              productType: rentalAddOn.productType,
              catClass: rentalAddOn.catClass,
              itemType: "rental",
              sellPrice: rentalAddOn.sellPrice,
              quantity: rentalAddOn.availQuantity * this.count,
              groupId: this.groupId,
              stockClass: rentalAddOn.stockClass, //25958
              itemNumber: rentalAddOn.itemNumber, //25958
              forcedItem: true, // SF-5303
              kitNumberBelongsTo:
                ((hasFuelProductRental && rentalAddOn.stockClass === "FUEL") ||
                  (rentalAddOn?.isRequired
                    ? rentalAddOn?.isRequired
                    : false)) &&
                (this.selectedItem[0].Product_SKU__c != "" ||
                  this.selectedItem[0].Product_SKU__c != NULL)
                  ? this.selectedItem[0].Product_SKU__c
                  : "", //SF-5291,SF-5292
              Kit_Number_This_Item_Belongs_to__c:
                ((hasFuelProductRental && rentalAddOn.stockClass === "FUEL") ||
                  (rentalAddOn?.isRequired
                    ? rentalAddOn?.isRequired
                    : false)) &&
                (this.selectedItem[0].Product_SKU__c != "" ||
                  this.selectedItem[0].Product_SKU__c != NULL)
                  ? this.selectedItem[0].Product_SKU__c
                  : "", //SF-5291,SF-5292
              quantityEditable: false, // SF-5303
              lineItemType: this.getLineItemType(lineItemProdInfo1), // SF-5303
              Line_Item_Type__c: this.getLineItemType(lineItemProdInfo1), // SF-5303
              rateBranch: rentalAddOn.rateBranch
            },
            isBulk: false,
            type: "add"
          };
          publish(this.messageContext, updateLineItemsChannel, rentalPayload);
        });
        this.requiredAddOns.salesAddOns.forEach((salesAddOn) => {
          let addOnSalesProdname = salesAddOn?.name;
          let hasFuelProductSales =
            addOnSalesProdname.indexOf("Fuel Convenience Charge") !== -1
              ? true
              : false; //SF-5879
          let salesPayload = {};
          //SF-5291,SF-5292
          let lineItemProdInfoSales = {
            productType: salesAddOn.productType,
            catClass: salesAddOn.catClass,
            //stockClass: lineItem.stockClass,
            inventoriedFlag: salesAddOn.inventoriedItem,
            miscChargeItemFlag: salesAddOn.miscellaneousChargeItem,
            typeMiscChargeItem: salesAddOn.typeOfMiscChargeItem,
            stockClass: salesAddOn.stockClass,
            name: salesAddOn.name
          };
          salesPayload = {
            recordId: this.recordId,
            lineItem: {
              name: salesAddOn.name,
              id: salesAddOn.id,
              productType: salesAddOn.productType,
              catClass: salesAddOn.catClass,
              itemType: "sales",
              sellPrice: salesAddOn.sellPrice,
              quantity: this.count,
              groupId: this.groupId,
              stockClass: salesAddOn.stockClass, //25958
              itemNumber: salesAddOn.itemNumber, //25958
              lineItemType: this.getLineItemType(lineItemProdInfoSales), //SF-5291,SF-5292
              kitNumberBelongsTo:
                ((hasFuelProductSales && salesAddOn.stockClass === "FUEL") ||
                  (salesAddOn?.isRequired ? salesAddOn?.isRequired : false)) &&
                (this.selectedItem[0].Product_SKU__c != "" ||
                  this.selectedItem[0].Product_SKU__c != NULL)
                  ? this.selectedItem[0].Product_SKU__c
                  : "", //SF-5291,SF-5292
              notes:
                hasFuelProductSales &&
                salesAddOn.stockClass === "FUEL" &&
                this.selectedItem[0]?.Name
                  ? "Fuel Plan for " + this.selectedItem[0]?.Name
                  : "" //SF-5997
            },
            isBulk: false,
            type: "add"
          };
          publish(this.messageContext, updateLineItemsChannel, salesPayload);
        });
        this.requiredAddOns.forcedItemAddOns.forEach((fcdItem) => {
          // SAL-27487
          let lineItemProdInfo = {
            productType: fcdItem.productType,
            inventoriedFlag: fcdItem.inventoriedItem,
            miscChargeItemFlag: fcdItem.miscellaneousChargeItem,
            typeMiscChargeItem: fcdItem.typeOfMiscChargeItem,
            stockClass: fcdItem.stockClass,
            name: fcdItem.name
          };
          let fcdItemsPayload = {};
          fcdItemsPayload = {
            recordId: this.recordId,
            lineItem: {
              name: fcdItem.name,
              id: fcdItem.id,
              catClass: fcdItem.catClass,
              itemType: "forcedItem",
              sellPrice: fcdItem.sellPrice,
              quantity: this.count,
              // requiredAddOns : this.requiredAddOns,
              groupId: this.groupId,
              stockClass: fcdItem.stockClass, //25958
              itemNumber: fcdItem.itemNumber, //25958
              // groupSize : this.groupSize,
              lineItemType: this.getLineItemType(lineItemProdInfo), // SAL-27487
              rateBranch: fcdItem?.rateBranch ? fcdItem.rateBranch : ""
            },
            isBulk: false,
            type: "add"
          };
          publish(this.messageContext, updateLineItemsChannel, fcdItemsPayload);
        });
      }
    } catch (error) {
      console.log("Error fetching ATC addons " + error.message);
    }
  }

  // SAL-26036
  getLineItemType(obj) {
    let result = "";
    if (
      obj.productType === "Cat-Class" ||
      obj.productType.includes("altInventory")
    ) {
      result = "VR";
    } else if (
      obj.inventoriedFlag &&
      (obj.productType === "Parts" || obj.productType === "Merchandise")
    ) {
      result = "VS";
    } else if (
      obj.miscChargeItemFlag &&
      !(
        obj.productType === "Parts" ||
        obj.productType === "Merchandise" ||
        obj.productType === "DEL"
      )
    ) {
      result = "YC";
    } else if (
      obj.miscChargeItemFlag &&
      obj.typeMiscChargeItem === "MS" &&
      obj.stockClass === "DEL"
    ) {
      result = "YD";
    } else if (
      obj?.name != undefined &&
      obj?.name == "Fuel Convenience Charge"
    ) {
      //SF-5879
      result = "VS";
    }
    return result;
  }

  // create new records by setting field information
  createLineItemRecord(item, itemType) {
    refreshApex(this.existingLineItems);
    let fields = {};
    let lineItemRecordInput = {};
    let Min_Rate;
    let Daily_Rate;
    let Weekly_Rate;
    let Monthly_Rate;
    let Misc_Sales_Price;
    let isUpdateLineItem = false;
    let lineItemRecordInputForUpdate = {};
    let lineItemProdInfo = {};
    //SAL-27182
    let showRates = item.SalesforceManagedKit;

    if (
      itemType === "rental" ||
      itemType === "sales" ||
      itemType === "forcedItem" ||
      itemType === "consumableSalesAddOn"
    ) {
      //SAL-27237
      if (itemType === "rental") {
        // SF-5105
        Min_Rate = item.minRate.toLowerCase() === "n/a" ? null : item.minRate;
        Daily_Rate =
          item.ratesDaily.toLowerCase() === "n/a" ? null : item.ratesDaily;
        Weekly_Rate =
          item.ratesWeekly.toLowerCase() === "n/a" ? null : item.ratesWeekly;
        Monthly_Rate =
          item.ratesMonthly.toLowerCase() === "n/a" ? null : item.ratesMonthly;
      }
      itemType == "sales" || "forcedItem" || "consumableSalesAddOn"
        ? (Misc_Sales_Price = item.sellPrice)
        : (Misc_Sales_Price = "");
      lineItemProdInfo = {
        productType: item.productType,
        catClass: item.catClass,
        stockClass: item.stockClass,
        itemNumber: item.itemNumber,
        name: item.name,
        itemId: item.id || item.Id,
        //SAL-26036
        inventoriedFlag: item.Inventoried_Item__c,
        miscChargeItemFlag: item.Miscellaneous_Charge_Item__c,
        typeMiscChargeItem: item.Type_of_Misc_Charge_Item__c
      };
    } else if (itemType === "base") {
      Min_Rate = item.Min_Rate?.toLowerCase() === "n/a" ? null : item.Min_Rate; // SAL-27182
      Daily_Rate =
        item.Daily_Rate?.toLowerCase() === "n/a" ? null : item.Daily_Rate; // SAL-27182
      Weekly_Rate =
        item.Weekly_Rate?.toLowerCase() === "n/a" ? null : item.Weekly_Rate; // SAL-27182
      Monthly_Rate =
        item.Monthly_Rate?.toLowerCase() === "n/a" ? null : item.Monthly_Rate; // SAL-27182
      Misc_Sales_Price = "";
      lineItemProdInfo = {
        productType: item?.Product_Type__c || item?.ItemType,
        catClass: item.Product_SKU__c,
        name: item.Name,
        itemId: item.Id,
        //SAL-26036
        stockClass: item.stockClass,
        inventoriedFlag: item.Inventoried_Item__c,
        miscChargeItemFlag: item.Miscellaneous_Charge_Item__c,
        typeMiscChargeItem: item.Type_of_Misc_Charge_Item__c
      };
    } else if (itemType === "Kit") {
      //SAL-26036
      lineItemProdInfo = {
        productType: item.productType,
        catClass: item.catClass,
        stockClass: item.stockClass,
        inventoriedFlag: item.Inventoried_Item__c,
        miscChargeItemFlag: item.Miscellaneous_Charge_Item__c,
        typeMiscChargeItem: item.Type_of_Misc_Charge_Item__c
      };
    }
    switch (this.objectApiName) {
      case "Cart__c":
        let addOnCartProdname = item?.name; //SF-5291,SF-5292
        let hasCartFuelProducts =
          addOnCartProdname &&
          addOnCartProdname.indexOf("Fuel Convenience Charge") !== -1
            ? true
            : false; //SF-5291,SF-5292 //SF-5879
        fields = {
          Cat_Class: item.Product_SKU__c, // SAL-27392
          Cart__c: this.recordId,
          Cat_Class__c:
            itemType == "base" ? item.Product_SKU__c : item.catClass,
          Name: itemType == "base" ? item.Name : item.name,
          Quantity__c:
            itemType === "rental"
              ? item.availQuantity * this.count == 0
                ? this.count
                : item.availQuantity * this.count
              : this.count, //SF-5330, SAL-27669
          Product__c: itemType === "base" ? item.Id : item.id,
          Minimum_Price__c: Min_Rate,
          Hourly_Price__c: Min_Rate,
          Daily_Price__c: Daily_Rate,
          Weekly_Price__c: Weekly_Rate,
          Monthly_Price__c: Monthly_Rate,
          Misc_Sales_Price__c: Misc_Sales_Price,
          Item_Subtotal__c: null,
          Suggested_Minimum_Price__c: Min_Rate,
          Suggested_Daily_Price__c: Daily_Rate,
          Suggested_Weekly_Price__c: Weekly_Rate,
          Suggested_Monthly_Price__c: Monthly_Rate,
          is_User_Added__c: true,
          Specific_Pricing_Type__c: item.Specific_Pricing_Type__c,
          Fuel_Plan__c:
            item?.Name == this.selectedItem[0]?.Name &&
            this.dataFuelPlan &&
            itemType === "base"
              ? true
              : false, //SF-5291,SF-5292,SF-5996
          Kit_Number_This_Item_Belongs_To__c:
            (hasCartFuelProducts ||
              (item?.isRequired ? item?.isRequired : false)) &&
            this.selectedItem[0]?.Product_SKU__c
              ? this.selectedItem[0].Product_SKU__c
              : "", //SF-5291,SF-5292,SF-5996
          Line_Comments__c:
            hasCartFuelProducts && this.selectedItem[0]?.Name
              ? "Fuel Plan for " + this.selectedItem[0].Name
              : "", //SF-5997
          Rates_Branch__c: this.selectedItem[0]?.Rate_Branch,
          // SAL-26036
          Line_Item_Type__c: this.getLineItemType(lineItemProdInfo),
          is_Forced_Item__c: item?.isRequired ? item?.isRequired : false
        };
        //24085
        if (itemType === "forcedItem") {
          fields.Quantity__c = item.minQuantity;
          fields.is_Forced_Item__c = true;

          if (
            (item.stockClass != undefined ||
              (item.stockClass != null && item.stockClass == "MISC")) &&
            (item.name != undefined || item.name != null)
          ) {
            let prodName = item.name;
          }
        }
        lineItemRecordInput = {
          apiName: CART_ITEMS_OBJECT.objectApiName,
          fields
        };
        //24302
        this.existingLineItems.forEach((lineItem) => {
          // use CatClass+KitNumberBelongsto field as unique for ForcedAddons - SF-6457
          let parentMatched =
            lineItem?.kitNumberBelongsTo &&
            lineItem.kitNumberBelongsTo == this.selectedItem[0]?.Product_SKU__c
              ? true
              : false;
          if (
            (item.catClass == lineItem.catClass ||
              (item.hasOwnProperty("Product_SKU__c") &&
                item["Product_SKU__c"] == lineItem.catClass)) &&
            ((!lineItem.kitNumberBelongsTo &&
              item.hasOwnProperty("Product_SKU__c")) ||
              parentMatched)
          ) {
            const fields = {};
            fields.Id = lineItem.Id;
            fields.Fuel_Plan__c =
              this.dataFuelPlan && itemType === "base" ? true : false; //SF-5291,SF-5292
            fields.Kit_Number_This_Item_Belongs_To__c =
              hasCartFuelProducts ||
              (item?.isRequired ? item.isRequired : false)
                ? this.selectedItem[0]?.Product_SKU__c
                : ""; //SF-5996
            fields.Line_Comments__c =
              hasCartFuelProducts && this.selectedItem[0]?.Name
                ? "Fuel Plan for " + this.selectedItem[0].Name
                : ""; //SF-5997
            let addedCount =
              itemType === "rental"
                ? this.count * item.availQuantity
                : this.count; // SF-5330
            fields.Quantity__c = addedCount + lineItem.quantity;
            lineItemRecordInputForUpdate = { fields };
            this.updateRecordArr.push(lineItemRecordInputForUpdate);
            isUpdateLineItem = true;
          }
          if (item.kitItems && item.kitItems.length > 0) {
            item.kitItems.forEach((kitItem) => {
              if (
                kitItem.SBQQ__OptionalSKU__r.Product_SKU__c == lineItem.catClass
              ) {
                const fields = {};
                fields.Id = lineItem.Id;
                fields.Quantity__c =
                  this.count * kitItem.SBQQ__Quantity__c + lineItem.quantity;
                const lineItemRecordInputForUpdate = { fields };
                this.updateRecordArr.push(lineItemRecordInputForUpdate);
                isUpdateLineItem = true;
              }
            });
          }
        });

        // Create additional quote lines for each kitItem - DS - Start
        if (item.kitItems && item.kitItems.length > 0 && !isUpdateLineItem) {
          for (const kitItem of item.kitItems) {
            let kitComponent = this.kitComponentRates.find(
              (item) => item.id == kitItem.SBQQ__OptionalSKU__c
            );
            fields = {
              Cat_Class: kitItem?.SBQQ__OptionalSKU__r?.Product_SKU__c, // SAL-27392
              Cat_Class__c: kitItem?.SBQQ__OptionalSKU__r?.Product_SKU__c,
              Cart__c: this.recordId,
              Name: kitItem.SBQQ__ProductName__c,
              Quantity__c: this.count * kitItem.SBQQ__Quantity__c,
              Kit_Number_This_Item_Belongs_To__c: item.catClass,
              Product__c: kitItem.SBQQ__OptionalSKU__c,
              is_User_Added__c: true,
              // SAL-27182
              Daily_Price__c: !showRates
                ? 0
                : kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent.ratesDaily, //kitComponent?.ratesDaily === 'n/a' ? 0 : kitComponent.ratesDaily,
              Weekly_Price__c: !showRates
                ? 0
                : kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent.ratesWeekly, //kitComponent?.ratesWeekly === 'n/a' ? 0 : kitComponent.ratesWeekly,
              Monthly_Price__c: !showRates
                ? 0
                : kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent.ratesMonthly, //kitComponent?.ratesMonthly === 'n/a' ? 0 : kitComponent.ratesMonthly,
              Minimum_Price__c: !showRates
                ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent.minRate,
              Hourly_Price__c: !showRates
                  ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent.minRate,
              Suggested_Minimum_Price__c:
                kitComponent?.minRate === "n/a" ? 0 : kitComponent.minRate,
              Suggested_Daily_Price__c:
                kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent.ratesDaily,
              Suggested_Weekly_Price__c:
                kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent.ratesWeekly,
              Suggested_Monthly_Price__c:
                kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent.ratesMonthly,
              Rates_Branch__c:this.selectedItem[0]?.Rate_Branch,
              Line_Item_Type__c: this.getLineItemType(lineItemProdInfo)
            };

            let kitLineItemRecordInput = {
              apiName: CART_ITEMS_OBJECT.objectApiName,
              fields
            };
            // SAL-27392 start
            let result = this.isUniqueItem(kitLineItemRecordInput, "");
            if (result) {
              delete kitLineItemRecordInput.fields.Cat_Class;
              this.atcRecordArr.push(kitLineItemRecordInput);
            }
            // SAL-27392 end
          }
        }
        // Create additional quote lines for each kitItem - DS - End
        this.itemProductTypeArr.push(lineItemProdInfo);
        this.toastMessage = "Cart Item Added";
        break;
      case "SBQQ__Quote__c":
        let addOnQuoteProdname = item?.name; //SF-5291,SF-5292
        let hasQuoteFuelProduct =
          addOnQuoteProdname &&
          addOnQuoteProdname.indexOf("Fuel Convenience Charge") !== -1
            ? true
            : false; //SF-5291,SF-5292 //SF-5879
        fields = {
          Cat_Class: item.Product_SKU__c, // SAL-27392
          SBQQ__Quote__c: this.recordId,
          SBQQ__Quantity__c:
            itemType === "rental"
              ? item.availQuantity * this.count == 0
                ? this.count
                : item.availQuantity * this.count
              : this.count, //SF-5330,  SAL-27669
          SBQQ__Product__c: itemType === "base" ? item.Id : item.id,
          Min_Rate__c: Min_Rate,
          Hourly_Rate__c: Min_Rate,
          Daily_Rate__c: Daily_Rate,
          Weekly_Rate__c: Weekly_Rate,
          Monthly_Rate__c: Monthly_Rate,
          SBQQ__UnitCost__c: Misc_Sales_Price,
          Selling_Price__c: Misc_Sales_Price == "" ? null : Misc_Sales_Price,
          Total_Price__c: "",
          Suggested_Minimum_Rate__c: Min_Rate,
          Suggested_Hourly_Rate__c: Min_Rate,
          Suggested_Daily_Rate__c: Daily_Rate,
          Suggested_Weekly_Rate__c: Weekly_Rate,
          Suggested_Monthly_Rate__c: Monthly_Rate,
          is_User_Added__c: true,
          Specific_Pricing_Type__c: item.Specific_Pricing_Type__c,
          // SAL-26036
          Line_Item_Type__c: this.getLineItemType(lineItemProdInfo),
          Fuel_Plan__c:
            item?.Name == this.selectedItem[0]?.Name &&
            this.dataFuelPlan &&
            itemType === "base"
              ? true
              : false, //SF-5291,SF-5292,SF-5996
          Kit_Number_this_Item_Belongs_to__c:
            (hasQuoteFuelProduct ||
              (item?.isRequired ? item.isRequired : false)) &&
            this.selectedItem[0]?.Product_SKU__c
              ? this.selectedItem[0].Product_SKU__c
              : "", //SF-5291,SF-5292,SF-5996
          is_Forced_Item__c: item?.isRequired ? item?.isRequired : false,
          Rates_Branch__c:
            this.selectedItem[0]?.Rate_Branch != undefined
              ? this.selectedItem[0]?.Rate_Branch
              : item?.rateBranch,
          Line_Comments__c:
            hasQuoteFuelProduct && this.selectedItem[0]?.Name
              ? "Fuel Plan for " + this.selectedItem[0].Name
              : "" //SF-5997
        };

        //24085
        if (itemType === "forcedItem") {
          fields.SBQQ__Quantity__c = item.minQuantity;
          fields.is_Forced_Item__c = true;

          if (
            (item.stockClass != undefined ||
              (item.stockClass != null && item.stockClass == "MISC")) &&
            (item.name != undefined || item.name != null)
          ) {
            let prodName = item.name;
            fields.Misc_Charges_Type__c = prodName.toUpperCase();
          }
        }
        lineItemRecordInput = {
          apiName: QUOTE_LINE_OBJECT.objectApiName,
          fields
        };
        this.existingLineItems.forEach((lineItem) => {
          // use CatClass+KitNumberBelongsto field as unique for ForcedAddons - SF-6457
          let parentMatched =
            lineItem?.kitNumberBelongsTo &&
            lineItem.kitNumberBelongsTo == this.selectedItem[0]?.Product_SKU__c
              ? true
              : false;
          if (
            (item.catClass == lineItem.catClass ||
              (item.hasOwnProperty("Product_SKU__c") &&
                item["Product_SKU__c"] == lineItem.catClass)) &&
            ((!lineItem.kitNumberBelongsTo &&
              item.hasOwnProperty("Product_SKU__c")) ||
              parentMatched)
          ) {
            const fields = {};
            fields.Id = lineItem.Id;
            let addedCount =
              itemType === "rental"
                ? this.count * item.availQuantity
                : this.count; // SF-5330
            fields.SBQQ__Quantity__c = addedCount + lineItem.quantity;
            fields.Fuel_Plan__c =
              this.dataFuelPlan && itemType === "base" ? true : false; //SF-5291,SF-5292
            fields.Kit_Number_this_Item_Belongs_to__c =
              hasQuoteFuelProduct ||
              (item?.isRequired ? item.isRequired : false)
                ? this.selectedItem[0]?.Product_SKU__c
                : ""; //SF-5996
            fields.Line_Comments__c =
              hasQuoteFuelProduct && this.selectedItem[0]?.Name
                ? "Fuel Plan for " + this.selectedItem[0].Name
                : ""; //SF-5997
            lineItemRecordInputForUpdate = { fields };
            this.updateRecordArr.push(lineItemRecordInputForUpdate);
            isUpdateLineItem = true;
          }
          if (item.kitItems && item.kitItems.length > 0) {
            item.kitItems.forEach((kitItem) => {
              if (
                kitItem.SBQQ__OptionalSKU__r.Product_SKU__c == lineItem.catClass
              ) {
                const fields = {};
                fields.Id = lineItem.Id;
                fields.SBQQ__Quantity__c =
                  this.count * kitItem.SBQQ__Quantity__c + lineItem.quantity;
                const lineItemRecordInputForUpdate = { fields };
                this.updateRecordArr.push(lineItemRecordInputForUpdate);
                isUpdateLineItem = true;
              }
            });
          }
        });
        // Create additional quote lines for each kitItem
        if (item.kitItems && item.kitItems.length > 0 && !isUpdateLineItem) {
          for (const kitItem of item.kitItems) {
            let kitComponent = this.kitComponentRates.find(
              (item) => item.id == kitItem.SBQQ__OptionalSKU__c
            );
            fields = {
              Cat_Class: kitItem?.SBQQ__OptionalSKU__r?.Product_SKU__c, // SAL-27392
              SBQQ__Quote__c: this.recordId,
              SBQQ__Quantity__c: this.count * kitItem.SBQQ__Quantity__c,
              Kit_Number_this_Item_Belongs_to__c: item.catClass,
              SBQQ__Product__c: kitItem.SBQQ__OptionalSKU__c,
              is_User_Added__c: true,
              // SAL-27182
              Daily_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent.ratesDaily, //kitComponent?.ratesDaily === 'n/a' ? 0 : kitComponent.ratesDaily,
              Weekly_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent.ratesWeekly, //kitComponent?.ratesWeekly === 'n/a' ? 0 : kitComponent.ratesWeekly,
              Monthly_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent.ratesMonthly, //kitComponent?.ratesMonthly === 'n/a' ? 0 : kitComponent.ratesMonthly,
              Min_Rate__c: !showRates
                ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent.minRate,
              Hourly_Rate__c: !showRates
                  ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent.minRate,
              Suggested_Minimum_Rate__c:
                kitComponent?.minRate === "n/a" ? 0 : kitComponent.minRate,
              Suggested_Hourly_Rate__c:
                kitComponent?.minRate === "n/a" ? 0 : kitComponent.minRate,
              Suggested_Daily_Rate__c:
                kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent.ratesDaily,
              Suggested_Weekly_Rate__c:
                kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent.ratesWeekly,
              Suggested_Monthly_Rate__c:
                kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent.ratesMonthly,
              Rates_Branch__c:
                this.selectedItem[0]?.Rate_Branch != undefined
                  ? this.selectedItem[0]?.Rate_Branch
                  : item?.rateBranch,
              Line_Item_Type__c: this.getLineItemType(lineItemProdInfo)
            };
            let kitLineItemRecordInput = {
              apiName: QUOTE_LINE_OBJECT.objectApiName,
              fields
            };
            // SAL-27392 start
            let result = this.isUniqueItem(kitLineItemRecordInput, "");
            if (result) {
              delete kitLineItemRecordInput.fields.Cat_Class;
              this.atcRecordArr.push(kitLineItemRecordInput);
            }
            // SAL-27392 end
          }
        }

        //24302
        this.itemProductTypeArr.push(lineItemProdInfo);
        /*conditon added as a part of FRONT-14366 and FRONT-14365*/
        if (this.isMobile) {
          this.toastMessage = "The Item has been successfully added";
        } else {
          this.toastMessage = "Quote Line Item added";
        }
        break;
      case "Order":
        let addOnOrderProdname = item?.name; //SF-5291,SF-5292
        let hasOrderFuelProduct =
          addOnOrderProdname &&
          addOnOrderProdname.indexOf("Fuel Convenience Charge") !== -1
            ? true
            : false; //SF-5291,SF-5292 //SF-5879

        fields = {
          Cat_Class: item.Product_SKU__c, // SAL-27392
          OrderId: this.recordId,
          //Product2Id: itemType === "base" ? item.Id : item.id,
          Product2Id: item.Id || item.id, //FRONT-32188 - getting undefined productId for itemType consumableSalesAddOn
          groupID__c: Math.floor(100000 + Math.random() * 900000).toString(),
          Quantity:
            itemType === "rental"
              ? item.availQuantity * this.count == 0
                ? this.count
                : item.availQuantity * this.count
              : this.count, //SF-5330,  SAL-27669
          UnitPrice: !Misc_Sales_Price ? 0.1 : Misc_Sales_Price,
          Min_Rate__c: Min_Rate,
          Hourly_Rate__c: Min_Rate,
          Daily_Rate__c: Daily_Rate,
          Weekly_Rate__c: Weekly_Rate,
          Monthly_Rate__c: Monthly_Rate,
          Selling_Price__c: Misc_Sales_Price == "" ? null : Misc_Sales_Price,
          Total_Price__c: "",
          Suggested_Minimum_Rate__c: Min_Rate,
          Suggested_Hourly_Rate__c: Min_Rate,
          Suggested_Daily_Rate__c: Daily_Rate,
          Suggested_Weekly_Rate__c: Weekly_Rate,
          Suggested_Monthly_Rate__c: Monthly_Rate,
          is_User_Added__c: true,
          Specific_Pricing_Type__c: item.Specific_Pricing_Type__c,
          Rates_Branch__c:
            this.selectedItem[0]?.Rate_Branch != undefined
              ? this.selectedItem[0]?.Rate_Branch
              : item?.rateBranch,
          // SAL-26036
          Line_Item_Type__c: this.getLineItemType(lineItemProdInfo),
          Fuel_Plan__c:
            item?.Name == this.selectedItem[0]?.Name &&
            this.dataFuelPlan &&
            itemType === "base"
              ? true
              : false, //SF-5291,SF-5292,SF-5996
          Kit_Number_This_Item_Belongs_To__c:
            (hasOrderFuelProduct ||
              (item?.isRequired ? item.isRequired : false)) &&
            this.selectedItem[0]?.Product_SKU__c
              ? this.selectedItem[0].Product_SKU__c
              : "", //SF-5291,SF-5292,SF-5996
          is_Forced_Item__c: item?.isRequired ? item?.isRequired : false,
          Line_Comments__c:
            hasOrderFuelProduct && this.selectedItem[0]?.Name
              ? "Fuel Plan for " + this.selectedItem[0].Name
              : "" //SF-5997
        };
        if (this.isDisableCounter && this.isMobile) {
          fields.Product2Id = item.ProductId;
        }
        if (itemType === "forcedItem") {
          fields.Quantity = item.minQuantity;
          fields.is_Forced_Item__c = true;

          if (
            (item.stockClass != undefined ||
              (item.stockClass != null && item.stockClass == "MISC")) &&
            (item.name != undefined || item.name != null)
          ) {
            let prodName = item.name;
            fields.Misc_Charges_Type__c = prodName.toUpperCase();
          }
        }
        lineItemRecordInput = {
          apiName: ORDER_PRODUCT_OBJECT.objectApiName,
          fields
        };
        const quantityCount = {};
        //SF-5330
        this.existingLineItems.forEach((lineItem) => {
          const quantity = lineItem.quantity;
          let key = lineItem.kitNumberBelongsTo
            ? `${lineItem.catClass}_${lineItem.kitNumberBelongsTo}`
            : `${lineItem.catClass}`;
          if (quantityCount[key]) {
            quantityCount[key] += quantity;
          } else {
            quantityCount[key] = quantity;
          }
        });
        let alreadyAddedToUpdate = [];
        //24302
        this.existingLineItems.forEach((lineItem) => {
          // use CatClass+KitNumberBelongsto field as unique for ForcedAddons - SF-6457
          let parentMatched =
            lineItem?.kitNumberBelongsTo &&
            lineItem.kitNumberBelongsTo == this.selectedItem[0]?.Product_SKU__c
              ? true
              : false;
          let key = lineItem.kitNumberBelongsTo
            ? `${lineItem.catClass}_${lineItem.kitNumberBelongsTo}`
            : `${lineItem.catClass}`;
          if (
            (item.catClass == lineItem.catClass ||
              (item.hasOwnProperty("Product_SKU__c") &&
                item["Product_SKU__c"] == lineItem.catClass)) &&
            ((!lineItem.kitNumberBelongsTo &&
              item.hasOwnProperty("Product_SKU__c")) ||
              parentMatched) &&
            !alreadyAddedToUpdate.includes(key)
          ) {
            const fields = {};
            fields.Id = lineItem.Id;
            let addedCount =
              itemType === "rental"
                ? this.count * item.availQuantity
                : this.count; //SF-5330

            fields.Quantity = addedCount + quantityCount[key];
            fields.Fuel_Plan__c =
              this.dataFuelPlan && itemType === "base" ? true : false; //SF-5291,SF-5292
            fields.Kit_Number_This_Item_Belongs_To__c =
              hasOrderFuelProduct ||
              (item?.isRequired ? item.isRequired : false)
                ? this.selectedItem[0]?.Product_SKU__c
                : ""; //SF-5996
            fields.Line_Comments__c =
              hasOrderFuelProduct && this.selectedItem[0]?.Name
                ? "Fuel Plan for " + this.selectedItem[0].Name
                : ""; //SF-5997
            lineItemRecordInputForUpdate = { fields };
            this.updateRecordArr.push(lineItemRecordInputForUpdate);
            alreadyAddedToUpdate.push(key);
            isUpdateLineItem = true;
          }
          if (item.kitItems && item.kitItems.length > 0) {
            item.kitItems.forEach((kitItem) => {
              if (
                kitItem.SBQQ__OptionalSKU__r.Product_SKU__c == lineItem.catClass
              ) {
                const fields = {};
                fields.Id = lineItem.Id;
                fields.Quantity =
                  this.count * kitItem.SBQQ__Quantity__c + lineItem.quantity;
                const lineItemRecordInputForUpdate = { fields };
                this.updateRecordArr.push(lineItemRecordInputForUpdate);
                isUpdateLineItem = true;
              }
            });
          }
        });
        // Create additional quote lines for each kitItem
        if (item.kitItems && item.kitItems.length > 0 && !isUpdateLineItem) {
          for (const kitItem of item.kitItems) {
            let kitComponent = this.kitComponentRates.find(
              (item) => item.id == kitItem.SBQQ__OptionalSKU__c
            );
            fields = {
              Cat_Class: kitItem?.SBQQ__OptionalSKU__r?.Product_SKU__c, // SAL-27392
              OrderId: this.recordId,
              Quantity: this.count * kitItem.SBQQ__Quantity__c,
              Kit_Number_This_Item_Belongs_To__c: item.catClass,
              Product2Id: kitItem.SBQQ__OptionalSKU__c,
              is_User_Added__c: true,
              UnitPrice: !Misc_Sales_Price ? 0.1 : Misc_Sales_Price,
              // SAL-27182
              Daily_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent.ratesDaily, //kitComponent?.ratesDaily === 'n/a' ? 0 : kitComponent?.ratesDaily,
              Weekly_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent.ratesWeekly, //kitComponent?.ratesWeekly === 'n/a' ? 0 : kitComponent?.ratesWeekly,
              Monthly_Rate__c: !showRates
                ? 0
                : kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent.ratesMonthly, //kitComponent?.ratesMonthly === 'n/a' ? 0 : kitComponent?.ratesMonthly,
              Min_Rate__c: !showRates
                ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent?.minRate,
              Hourly_Rate__c: !showRates
                  ? 0
                : kitComponent?.minRate === "n/a"
                  ? 0
                  : kitComponent.minRate, //kitComponent?.minRate === 'n/a' ? 0 : kitComponent?.minRate,
              Suggested_Minimum_Rate__c:
                kitComponent?.minRate === "n/a" ? 0 : kitComponent?.minRate,
              Suggested_Hourly_Rate__c:
                kitComponent?.minRate === "n/a" ? 0 : kitComponent?.minRate,
              Suggested_Daily_Rate__c:
                kitComponent?.ratesDaily === "n/a"
                  ? 0
                  : kitComponent?.ratesDaily,
              Suggested_Weekly_Rate__c:
                kitComponent?.ratesWeekly === "n/a"
                  ? 0
                  : kitComponent?.ratesWeekly,
              Suggested_Monthly_Rate__c:
                kitComponent?.ratesMonthly === "n/a"
                  ? 0
                  : kitComponent?.ratesMonthly,
              Rates_Branch__c:
                this.selectedItem[0]?.Rate_Branch != undefined
                  ? this.selectedItem[0]?.Rate_Branch
                  : item?.rateBranch,
              Line_Item_Type__c: this.getLineItemType(lineItemProdInfo)
            };
            let kitLineItemRecordInput = {
              apiName: ORDER_PRODUCT_OBJECT.objectApiName,
              fields
            };
            // SAL-27392 start
            let result = this.isUniqueItem(kitLineItemRecordInput, "");
            if (result) {
              delete kitLineItemRecordInput.fields.Cat_Class;
              this.atcRecordArr.push(kitLineItemRecordInput);
            }
            // SAL-27392 end
          }
        }
        this.itemProductTypeArr.push(lineItemProdInfo);
        /*conditon added as a part of FRONT-14366 and FRONT-14365*/
        if (this.isMobile) {
          this.toastMessage = "The Item has been successfully added";
        } else {
          this.toastMessage = "Order Product Item added";
        }
        break;
      default: {
      }
    }

    //24302
    if (!isUpdateLineItem) {
      if (
        this.isUniqueItem(lineItemRecordInput, item.catClass) &&
        itemType != "Kit"
      ) {
        delete lineItemRecordInput.fields.Cat_Class;
        if (item.Is_Kit__c !== undefined) {
          if (
            item.Is_Kit__c !== "Yes" ||
            (item.Is_Kit__c === "Yes" &&
              item.Salesforce_Managed_Kit__c === false)
          ) {
            //SAL-27182
            this.atcRecordArr.push(lineItemRecordInput);
          }
        }
        // SAL-27182 : commented next IF section to not publish HEADER kit comp when SMK=TRUE
        // if (item.isKit !== undefined && item.changeable !== undefined) {
        //   if (
        //    item.isKit !== "Yes" ||
        //    (item.isKit === "Yes" && item.changeable === false)
        //  ) {
        //    this.atcRecordArr.push(lineItemRecordInput);
        //  }
        // } else
          if (
          itemType === "rental" ||
          itemType === "sales" ||
          itemType === "consumableSalesAddOn"
        ) {
          this.atcRecordArr.push(lineItemRecordInput);
        }
      } else if (itemType === "consumableSalesAddOn") {
        this.atcRecordArr.push(lineItemRecordInput);
      }
    }
  }

  get isDisableAddToCart() {
    if (this.selectedItem && this.selectedItem.length > 0) {
      //SAL-27182
      return this.disableAddToCart ||
        (this.selectedItem[0].Is_Kit__c === "Yes" &&
          this.selectedItem[0].Salesforce_Managed_Kit__c === true)
        ? this.disableAddToCart
        : !this.hasRatesLoaded;
    }
    // Required Add On Logic - To hide the button - SF-5303, SF-5850
    if (this.selectedItem && this.selectedItem?.value?.isRequired) {
      this.hideBtn = true;
      return true;
    }
  }
  // Define a JavaScript method to check if kitLineItemRecordInput is unique
  isUniqueItem(ItemRecordInput, catClass) {
    let uniqueIdentifier = "";
    // SAL-27392 start
    if (this.existingLineItems.length == 0) {
      return true;
    } else {
      uniqueIdentifier =
        ItemRecordInput.fields.Cat_Class != undefined
          ? ItemRecordInput.fields.Cat_Class
          : catClass;
      // use CatClass+KitNumberBelongsto field as unique for ForcedAddons - SF-6457
      if (
        ItemRecordInput?.fields?.is_Forced_Item__c &&
        this.objectApiName == "SBQQ__Quote__c"
      ) {
        uniqueIdentifier = `${uniqueIdentifier}_${ItemRecordInput?.fields?.Kit_Number_this_Item_Belongs_to__c}`;
      } else if (
        ItemRecordInput?.fields?.is_Forced_Item__c &&
        this.objectApiName != "SBQQ__Quote__c"
      ) {
        uniqueIdentifier = `${uniqueIdentifier}_${ItemRecordInput?.fields?.Kit_Number_this_Item_Belongs_to__c}`;
      }
      if (uniqueIdentifier) {
        return !this.existingLineItems.some((record) => {
          let key = record.kitNumberBelongsTo
            ? `${record.catClass}_${record.kitNumberBelongsTo}`
            : record.catClass;
          return key === uniqueIdentifier;
        });
      }
    }
    // SAL-27392 end
  }

  async getKitComponentRates() {
    //Fire rates api call only if there are kit components and they valid product ids
    if (!SBRUtils.isEmpty(this.kitItems)) {
      let productIds = this.kitItems?.map(
        (kitItem) => kitItem.SBQQ__OptionalSKU__c
      );
      if (!SBRUtils.isEmpty(productIds)) {
        //Rates API call
        this.kitComponentRates = await getBulkProductDetails({
          productIds: productIds,
          customerNumberParam: this.customerNumber
        });
      }
      if (!SBRUtils.isEmpty(this.kitComponentRates)) {
        //Enable Add to Cart button and dynamically change the label
        this.disableBtn = false;
        this.hasRatesLoaded = true;
      } else {
        this.hasRatesLoaded = true; //to change the btn label
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Failed to fetch rates for the kit components.",
            variant: "error"
          })
        );
      }
    } else {
      this.hasRatesLoaded = true; //to change the btn label
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Warning",
          message: "No kit components found to add to cart.",
          variant: "warning"
        })
      );
    }
  }

  //FRONT-22235/22237 to open add to contract modal
  showContractSalesModal(selectedItemsToDisplay) {
    this.selectedItem = selectedItemsToDisplay[0]
      ? selectedItemsToDisplay[0]
      : selectedItemsToDisplay;
    this.salesContractEditorModalHeader = this.selectedItem?.name;
    this.refs.salesContractEditorModal.toggleModal();
  }

  //FRONT-22235/22237 create Order Item Record on Confirm Click
  handleConfirm = () => {
    let itemData = this.refs.salesContractEditor.getSalesMiscItemData();
    let orderItemObjectFields = {
      OrderId: this.recordId,
      Product2Id: this.selectedItem?.Id,
      Quantity: itemData?.quantity,
      UnitPrice: 0,
      Line_Comments__c: itemData?.lineItemNotes,
      Selling_Price__c: itemData?.salesOrMiscPrice,
      Free_Flag__c: itemData?.noChargeFlag,
      Cost__c: this.costPrice //saving cost price to Order Item which will be used in edit Order Line Item
    };
    let orderItemObject = {
      apiName: "OrderItem",
      fields: orderItemObjectFields
    };
    createRecord(orderItemObject)
      .then((response) => {
        logger.log("OrderItem created with Id: " + response.id);
        logger.log("OrderItem : " + JSON.stringify(orderItemObject));
        this.refs.salesContractEditorModal.toggleModal();
        const toastEvent = new ShowToastEvent({
          message: this.selectedItem?.name + " has been successfully added.",
          variant: "success"
        });
        this.dispatchEvent(toastEvent);
      })
      .catch((error) => {
        logger.log(
          "error in create Order Item:",
          JSON.stringify(error.body),
          error.status,
          error.statustext
        );
        const toastEvent = new ShowToastEvent({
          title: "ERROR!!",
          message: JSON.stringify(error.body),
          variant: "error"
        });
        this.dispatchEvent(toastEvent);
      });
  };
}