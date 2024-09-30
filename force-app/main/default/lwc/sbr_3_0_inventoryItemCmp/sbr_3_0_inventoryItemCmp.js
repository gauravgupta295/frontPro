import { LightningElement, api, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";
import { createMessageContext } from "lightning/messageService";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import ORDER_ITEM_OBJECT from "@salesforce/schema/OrderItem";
import CART_ITEMS_OBJECT from "@salesforce/schema/Cart_Items__c";
import QUOTE_LINE_OBJECT from "@salesforce/schema/SBQQ__QuoteLine__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getProductKitComponents from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents";
import getBulkProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBulkProductDetails";
import * as SBRUtils from "c/sbrUtils";
import createLineItems from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.createLineItems";
import getProductAddOns from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductAddOns";
import hasFuelPlan from "@salesforce/apex/SBR_3_0_ProductDA.getProductOptionsWithFuelCharge"; //SF-5291,SF-5292
import { updateRecord } from "lightning/uiRecordApi";

export default class Sbr_3_0_inventoryItemCmp extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api itemData = {};
  @api itemType = "altInventory";
  @api branchId;
  @api productType;
  @api branchPhone;
  @api itemAvailability;
  @api locationInfo;
  @api chronosEnabled;
  @api itemQty;
  @api isLastBulkItem = false;
  @api customerNumber;
  @api companyCode;
  @api tabname = ""; //Added as part of FRONT-11384
  @api variant;
  @api showSpinner = false;
  parentBranch;
  branchAvailability;
  hrefBranchPhone = "";
  count = 1;
  isMobile;
  type = "summary";
  hasFuelPlan = false; //SF-5291,SF-5292
  isSalesTab = false; //Added as part of FRONT-11384
  isAssetTab = false; //Added as part of FRONT-11320
  messageContext = createMessageContext();
  kitComponentRates = [];
  kitComponents = [];
  lineItemRecsToInsert = [];
  productAddOns = {};
  rentalAddOns = [];
  salesAddOns = [];
  updateRecordArr = [];
  @api existing = [];

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.parentBranch = this.itemData.value.rateBranch;
    /*Added as part of FRONT-11384*/
    if (this.tabname === "Sales") {
      this.isSalesTab = true;
    }
    /*FRONT-11320 */
    if (this.tabname === "itemSearchAsset") {
      this.isAssetTab = true;
    }
    /*FRONT-11384 Ends*/
  }
  get isAltInventory() {
    return this.itemType == "altInventory" ? true : false;
  }
  get isAltInventoryChronos() {
    return this.itemType == "altInventoryChronos" ? true : false;
  }
  get isBulkInventory() {
    return this.itemType == "bulkInventory" ? true : false;
  }
  get hasBranchAvailability() {
    if (
      this.chronosEnabled &&
      this.itemData.value.locationItemInfo != undefined
    ) {
      return (
        this.itemQty <= this.itemData.value.locationItemInfo.fulfillQuantity
      );
    }
    return false;
  }
  get hasBranchPhone() {
    return this.itemData.value.locationItemInfo &&
      this.itemData.value.locationItemInfo.branchPhone
      ? true
      : false;
  }

  get branchDisplay() {
    if (this.itemData.value.locationItemInfo.pc == "n/a") {
      return "";
    } else {
      return this.itemData.value.locationItemInfo.pc;
    }
  }
  addItem() {
    this.count++;
  }
  subtractItem() {
    if (this.count > 0) {
      this.count -= 1;
    }
  }
  handleCountChange(event) {
    var numerics = /^[0-9]+$/;
    var countInput = event.target.value;
    if (countInput.match(numerics)) {
      this.count = parseInt(countInput);
    } else {
      event.target.value = this.count;
    }
  }
  changeItem(event) {
    let selectedItem = [
      {
        BranchNumberSelected: this.itemData.value.locationItemInfo.pc,
        AtpSelected: this.itemData.value.locationItemInfo.atp,
        AtpLabel: this.itemData.value.locationItemInfo.atpLabel,
        LocationInfo: this.itemData.value.locationItemInfo,
        ItemUtil: this.itemData.value.availabilityInfo.utilization,
        Product_SKU__c: event.currentTarget.dataset.catClass,
        Id: event.currentTarget.dataset.id,
        Name: event.currentTarget.dataset.name,
        ItemType: this.itemType,
        Is_Kit__c: this.itemData.value.isKit,
        Changeable__c: this.itemData.value.isChangeable
      }
    ];

    const selectedItemEvent = new CustomEvent("itemselected", {
      detail: selectedItem,
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(selectedItemEvent);
  }

  // SAL-26036
  /**
   * Method to determine lineitemtype field value
   * @param {object} obj Product Info details
   * @returns
   */
  getLineItemType(obj) {
    let result = "";
    if (
      obj?.productType === "Cat-Class" ||
      obj.productType.includes("altInventory")
    ) {
      result = "VR";
    } else if (
      obj?.inventoriedItem &&
      (obj?.productType === "Parts" || obj?.productType === "Merchandise")
    ) {
      result = "VS";
    } else if (
      obj?.miscellaneousChargeItem &&
      !(
        obj?.productType === "Parts" ||
        obj?.productType === "Merchandise" ||
        obj?.productType === "DEL"
      )
    ) {
      result = "YC";
    } else if (
      obj?.miscellaneousChargeItem &&
      obj?.typeOfMiscChargeItem === "MS" &&
      obj?.stockClass === "DEL"
    ) {
      result = "YD";
    }

    return result;
  }

  @api
  async addToCart() {
    let areLineItemsCreated = false;
    this.updateRecordArr = [];
    if (
      this.itemData.value.isKit === "Yes" &&
      this.itemData.value.isChangeable
    ) {
      //Process Unmanaged kit component product
      await this.handleUnmanagedKitCmpProduct();
      areLineItemsCreated = true;
    } else if (
      this.itemData.value.isKit === "Yes" &&
      !this.itemData.value.isChangeable
    ) {
      //Process Managed kit component product
      await this.handleManagedKitCmpProduct();
      areLineItemsCreated = true;
    } else {
      const fuelFlag = await hasFuelPlan({
        productSkus: this.itemData.value.id || this.itemData.value.Id,
        companyCode: this.companyCode
      }); //SF-5291,SF-5292
      this.hasFuelPlan = fuelFlag?.hasFuelCharge; //SF-5291,SF-5292, FRONT-19009-Added safe navigation operator for null check
      if (!(await this.handleExistingLineItems())) {
        //Process Regular Cat-Class product
        await this.handleRegularCatClassProduct();
        //Get product addons if regular cat class product
        await this.getProductAddOns();
        //Add rental forced addons if regular cat class product
        await this.addRentalForcedAddOns();
        //Add sales forced addons if regular cat class product
        await this.addSalesForcedAddOns();
      } else {
        if (
          Array.isArray(this.updateRecordArr) &&
          this.updateRecordArr.length > 0
        ) {
          areLineItemsCreated = this.updateRecordArr.map(async (cartItem) => {
            areLineItemsCreated = await this.updateLineItem(cartItem);
          });
          publish(this.messageContext, updateLineItemsChannel, {});
          //Showing toast message only when last line item has been created
          this.dispatchEvent(
            new ShowToastEvent({
              message: "Line items were successfully added",
              variant: "success"
            })
          );
        }
      }
    }
    //Create LineItem records
    if (!SBRUtils.isEmpty(this.lineItemRecsToInsert)) {
      areLineItemsCreated = await this.createLineItemRecords();
    }
    return areLineItemsCreated;
  }

  async updateLineItem(cartItem) {
    let recordupdated = false;
    updateRecord(cartItem)
      .then(() => {
        recordupdated = true;
      })
      .catch((error) => {
        console.log("updateLineItem error" + JSON.stringify(error));
      });
    return recordupdated;
  }

  deleteProduct() {
    let productId = this.itemData.value.id || this.itemData.value.Id;
    if (this.tabname === "itemSearchAsset") {
      //FRONT-13129
      productId = this.itemData.value.assetid;
    }
    const payload = {
      productId,
      contextId: this.recordId,
      variant: this.variant
    };
    publish(this.messageContext, deselectProductRowChannel, payload);
  }

  handleBranchPhone() {
    this.hrefBranchPhone = "tel:".concat(
      this.itemData.value.locationItemInfo.branchPhone
    );
  }

  //To process unmanaged kit product selected by user
  async handleUnmanagedKitCmpProduct() {
    this.kitComponents = await this.getKitComponents();
    if (!SBRUtils.isEmpty(this.kitComponents)) {
      //Only get the rates if the kit components are found
      this.kitComponentRates = await this.getKitComponentRates();
    } else {
      //if no kit components found show warning msg
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Warning",
          message:
            "No kit components found for one or all of the products to add to the cart.",
          variant: "warning"
        })
      );
    }
    //Add kit components as line items if found
    if (!SBRUtils.isEmpty(this.kitComponents)) {
      if (!(await this.updateExistingKITS())) {
        this.addKitComponentsToCart();
      }
    }
  }

  //To process managed kit product selected by user
  async handleManagedKitCmpProduct() {
    this.kitComponents = await this.getKitComponents();
    if (!SBRUtils.isEmpty(this.kitComponents)) {
      //Only get the rates if there kit components are found
      this.kitComponentRates = await this.getKitComponentRates();
    } else {
      //if no kit components found add the parent product and show warning msg
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Warning",
          message:
            "No kit components found for one or all of the products to add to the cart.",
          variant: "warning"
        })
      );
    }
    //Add parent product as line item
    await this.handleRegularCatClassProduct();
    //Add kit components as line item if they are found
    if (!SBRUtils.isEmpty(this.kitComponents)) {
      if (!(await this.updateExistingKITS())) {
        //Add parent product as line item
        await this.handleRegularCatClassProduct();
        await this.addKitComponentsToCart();
      }
    }
  }
  async handleExistingLineItems() {
    let isUpdated = false;
    isUpdated = await this.handleExistingLineItemsForObject();
    return isUpdated;
  }

  async handleExistingLineItemsForObject() {
    let isCartUpdated = false;
    let isChildUpdated = false;
    if (Array.isArray(this.existing) && this.existing.length > 0) {
      this.existing.forEach((lineItem) => {
        if (
          this.itemData.value.catClass == lineItem.catClass &&
          !lineItem.kitNumberBelongsTo
        ) {
          this.updateRecordArr.push(this.updateInstance(lineItem, null));
          isCartUpdated = true;
        }
      });
      if (this.objectApiName === "Cart__c" || this.objectApiName === "Order") {
        this.handleExistingChildLineItems().then((updated) => {
          isChildUpdated = updated;
        });
      }
    }
    return isCartUpdated || isChildUpdated;
  }
  updateInstance(lineItem, kitComponent) {
    let lineItemRecordInputForUpdate = {};
    let fields = {};
    //Order Logic as it will have multiple line for same catclass
    const quantityCount = {};
    this.existing.forEach((lineItem) => {
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
    let key = lineItem?.kitNumberBelongsTo
      ? `${lineItem.catClass}_${lineItem.kitNumberBelongsTo}`
      : `${lineItem.catClass}`;

    switch (this.objectApiName) {
      case "Cart__c":
        fields.Id = lineItem.Id;
        fields.Quantity__c =
          kitComponent != undefined
            ? this.count * kitComponent.SBQQ__Quantity__c
            : lineItem.quantity + this.count;
        break;
      case "SBQQ__Quote__c":
        fields.Id = lineItem.Id;
        fields.SBQQ__Quantity__c =
          kitComponent != undefined
            ? this.count * kitComponent.SBQQ__Quantity__c
            : lineItem.quantity + this.count;
        break;
      case "Order":
        fields.Id = lineItem.Id;
        fields.Quantity =
          kitComponent != undefined
            ? this.count * kitComponent.SBQQ__Quantity__c
            : quantityCount[key] + this.count;
        break;
    }
    lineItemRecordInputForUpdate = { fields };
    return lineItemRecordInputForUpdate;
  }
  //SF-5303
  handleExistingChildLineItems() {
    return new Promise((resolve, reject) => {
      //Get product addons if regular cat class product
      let isChildUpdated = false;
      //await this.getProductAddOns();
      let requiredAddOns = [];
      this.rentalAddOns = this.itemData?.value?.rentalAddOns;
      if (!SBRUtils.isEmpty(this.rentalAddOns)) {
        //Filtering rental forced addons
        this.rentalAddOns.forEach((rentalAddon) => {
          let addOn = { ...rentalAddon };
          let rentalAddOnName = rentalAddon?.name;
          let hasFuelProductsRental =
            rentalAddOnName &&
            (rentalAddOnName.indexOf("Refill") !== -1 ||
              rentalAddOnName.indexOf("Fuel Convenience Charge") !== -1)
              ? true
              : false;
          if (rentalAddon.isRequired || hasFuelProductsRental) {
            addOn.addonType = "rental";
            requiredAddOns.push(addOn);
          }
        });
      }
      this.salesAddOns = this.itemData?.value?.salesAddOns;

      if (!SBRUtils.isEmpty(this.salesAddOns)) {
        //Filtering rental forced addons
        this.salesAddOns.forEach((salesAddOn) => {
          let addOn = { ...salesAddOn };
          let salesAddOnName = salesAddOn?.name;
          let hasFuelProductsSales =
            salesAddOnName &&
            (salesAddOnName.indexOf("Refill") !== -1 ||
              salesAddOnName.indexOf("Fuel Convenience Charge") !== -1)
              ? true
              : false;
          if (salesAddOn.isRequired || hasFuelProductsSales) {
            addOn.addonType = "sales";
            requiredAddOns.push(addOn);
          }
        });
      }

      if (!SBRUtils.isEmpty(requiredAddOns)) {
        const quantityCount = {};
        this.existing.forEach((lineItem) => {
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
        console.log("requiredAddons " + JSON.stringify(requiredAddOns));
        requiredAddOns.forEach((requiredAddOn) => {
          const lineItem = this.existing.find(
            (item) =>
              item.catClass === requiredAddOn.catClass &&
              item.kitNumberBelongsTo === this.itemData.value.catClass
          );
          if (lineItem) {
            console.log("child lineItem " + JSON.stringify(lineItem));
            this.updateRecordArr.push(
              this.updateChildInstance(lineItem, requiredAddOn, quantityCount)
            );
            isChildUpdated = true;
          }
        });
      }
      return resolve(isChildUpdated);
    });
  }
  //SF-5303
  updateChildInstance(lineItem, requiredAddOn, quantityCount) {
    let lineItemRecordInputForUpdate = {};
    let fields = {};
    let key = lineItem.kitNumberBelongsTo
      ? `${lineItem.catClass}_${lineItem.kitNumberBelongsTo}`
      : `${lineItem.catClass}`;
    switch (this.objectApiName) {
      case "Cart__c":
        fields.Id = lineItem.Id;
        fields.Quantity__c =
          requiredAddOn.addonType === "rental"
            ? this.count *
                this.parseQuantityValue(requiredAddOn.availQuantity) +
              quantityCount[key]
            : this.count * this.parseQuantityValue(requiredAddOn.minQuantity) +
              quantityCount[key];
        break;
      case "Order":
        fields.Id = lineItem.Id;
        fields.Quantity =
          requiredAddOn.addonType === "rental"
            ? this.count *
                this.parseQuantityValue(requiredAddOn.availQuantity) +
              quantityCount[key]
            : this.count * this.parseQuantityValue(requiredAddOn.minQuantity) +
              quantityCount[key];
        break;
    }
    lineItemRecordInputForUpdate = { fields };
    return lineItemRecordInputForUpdate;
  }
  async updateExistingKITS() {
    let isUpdated = false;
    let lineItemRecordInputForUpdate = {};
    await this.handleExistingLineItemsForObject();
    if (Array.isArray(this.existing) && this.existing.length > 0) {
      for (let kitComponent of this.kitComponents) {
        // Check if Product_SKU__c exists in existingLineItems
        let existingItemIndex = this.existing.findIndex(
          (item) =>
            item.catClass === kitComponent.SBQQ__OptionalSKU__r.Product_SKU__c
        );
        if (existingItemIndex !== -1) {
          // Update quantity in existingLineItems
          const lineItem = this.existing[existingItemIndex];
          this.updateRecordArr.push(
            this.updateInstance(lineItem, kitComponent)
          );
          isUpdated = true;
        }
      }
    }
    if (isUpdated) {
      if (
        Array.isArray(this.updateRecordArr) &&
        this.updateRecordArr.length > 0
      ) {
        this.updateRecordArr.map((cartItem) =>
          updateRecord(cartItem).then((updtResult) => {})
        );
        publish(this.messageContext, updateLineItemsChannel, {});
      }
    }
    return isUpdated;
  }
  //To process regular cat class product selected by user
  async handleRegularCatClassProduct() {
    let kitItem = {};
    if (!this.recordId) {
      //Item searched and added from Product Inquiry page
      this.addProductToCartPI(false, kitItem);
    } else {
      if (this.objectApiName === "Cart__c") {
        //Item searched and added from Cart record
        this.createCartItem(false, kitItem);
      } else if (this.objectApiName === "SBQQ__Quote__c") {
        //Item searched and added from Quote record
        this.createQuoteLine(false, kitItem);
      } else if (this.objectApiName === "Order") {
        //Item searched and added from Order record
        this.createOrderItem(false, kitItem);
      }
    }
  }

  //Publish a message for products selected from product inquiry tab
  addProductToCartPI(isKitItem, kitItemData) {
    //get the payload for msg channel
    let payload = this.getProductInquiryPayload(isKitItem, kitItemData);
    //Send a message to line items cmp and it will fire a rates api call and populate data in the line item grid
    publish(this.messageContext, updateLineItemsChannel, payload);
    if (!this.isMobile) {
      //FRONT-11309 added variant in the payload to indentify current tab
      publish(this.messageContext, deselectProductRowChannel, {
        productId: null,
        contextId: this.recordId,
        variant: this.variant
      });
    }

    var successEvent = new CustomEvent("additemsuccess"); //FRONT-13129
    this.dispatchEvent(successEvent);
    const toastEvent = new ShowToastEvent({
      title: "Success",
      message: "The items(s) were added to Cart",
      variant: "success"
    });
    this.dispatchEvent(toastEvent);
    return true;
  }

  /**
   * Method to push Cart Item record to the line items array
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   */
  createCartItem(isKitItem, kitItemData) {
    let fields = this.getCartItemFields(isKitItem, kitItemData);
    let lineItemRecordInput = {
      apiName: CART_ITEMS_OBJECT.objectApiName,
      fields
    };
    this.lineItemRecsToInsert.push(lineItemRecordInput);
  }

  /**
   * Method to push Quote Line record to the line items array
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   */
  createQuoteLine(isKitItem, kitItemData) {
    let fields = this.getQuoteLineFields(isKitItem, kitItemData);
    let lineItemRecordInput = {
      apiName: QUOTE_LINE_OBJECT.objectApiName,
      fields
    };
    this.lineItemRecsToInsert.push(lineItemRecordInput);
  }

  /**
   * Method to push Order Item record to the line items array
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   */
  createOrderItem(isKitItem, kitItemData) {
    let fields = this.getOrderItemFields(isKitItem, kitItemData);
    let lineItemRecordInput = {
      apiName: ORDER_ITEM_OBJECT.objectApiName,
      fields
    };
    this.lineItemRecsToInsert.push(lineItemRecordInput);
  }

  //Check rate field values and return 0 if unparseable or n/a string
  parseRateValue(rateValue) {
    if (!SBRUtils.isEmpty(rateValue)) {
      return rateValue === "n/a" ? 0 : rateValue;
    }
    return 0;
  }
  //Check quantity field values and return 1 if unparseable or n/a or null string
  parseQuantityValue(quantityValue) {
    if (!SBRUtils.isEmpty(quantityValue)) {
      return quantityValue === "n/a" || quantityValue === 0 || null
        ? 1
        : quantityValue;
    }
    return 1;
  }

  //To get kit components for the selected product
  getKitComponents() {
    return getProductKitComponents({
      productId: this.itemData.value.id || this.itemData.value.Id
    })
      .then((data) => {
        return JSON.parse(data);
      })
      .catch((error) => {
        console.error("Error fetching kit components " + error.message);
      });
  }

  //To get rates for kit components of selected product
  getKitComponentRates() {
    let productIds = this.kitComponents?.map(
      (kitItem) => kitItem.SBQQ__OptionalSKU__c
    );
    return getBulkProductDetails({
      productIds: productIds,
      customerNumberParam: this.customerNumber
    })
      .then((data) => {
        return data;
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Failed to fetch rates for the kit components",
            variant: "error"
          })
        );
        console.error(
          "Error fetching rates for kit components " + error.message
        );
      });
  }

  /**
   * Method to build object for Cart Item record
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   * @returns
   */
  getCartItemFields(isKitItem, kitItemData) {
    let kitComponentRates = {};
    let productInfo = {};

    if (isKitItem) {
      //Find rates for the kit component in the rate api response
      kitComponentRates = this.kitComponentRates.find(
        (item) => item.id == kitItemData.SBQQ__OptionalSKU__c
      );
      //Get product info to determine the line type field value
      productInfo = this.getProductInfoKitItem(kitItemData);
    }
    let fields = {
      Cart__c: this.recordId,
      Cat_Class__c: isKitItem
        ? kitItemData?.SBQQ__OptionalSKU__r.Product_SKU__c
        : this.itemData?.value?.catClass,
      Name: isKitItem
        ? kitItemData?.SBQQ__ProductName__c
        : this.itemData?.value?.name,
      Quantity__c: isKitItem
        ? kitItemData.SBQQ__Quantity__c * this.count
        : this.count,
      Product__c: isKitItem
        ? kitItemData?.SBQQ__OptionalSKU__c
        : this.itemData.value.id || this.itemData.value.Id,
      Minimum_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Hourly_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Daily_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Weekly_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Monthly_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Misc_Sales_Price__c: this.isSalesConsumables
        ? this.parseRateValue(this.itemData?.value?.sellPrice)
        : 0,
      Item_Subtotal__c: 0,
      Suggested_Daily_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Suggested_Weekly_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Suggested_Monthly_Price__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Specific_Pricing_Type__c: this.itemData?.value?.Specific_Pricing_Type__c,
      Line_Item_Type__c: isKitItem
        ? this.getLineItemType(productInfo)
        : this.getLineItemType(this.itemData?.value), // SAL-26036
      is_User_Added__c: true, // SAL-27192
      Kit_Number_This_Item_Belongs_To__c: isKitItem
        ? this.itemData?.value?.catClass
        : "",
      Fuel_Plan__c: this.hasFuelPlan ? true : false,
      Rates_Branch__c: this.parentBranch //SF-5291,SF-5292
    };
    return fields;
  }

  /**
   * Method to build object for Quote Line record
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   * @returns
   */
  getQuoteLineFields(isKitItem, kitItemData) {
    let kitComponentRates = {};
    let productInfo = {};
    if (isKitItem) {
      //Find rates for the kit component in the rate api response
      kitComponentRates = this.kitComponentRates.find(
        (item) => item.id == kitItemData.SBQQ__OptionalSKU__c
      );
      //Get product info to determine the line type field value
      productInfo = this.getProductInfoKitItem(kitItemData);
    }
    let fields = {
      SBQQ__Quote__c: this.recordId,
      SBQQ__Quantity__c: isKitItem
        ? kitItemData.SBQQ__Quantity__c * this.count
        : this.count,
      SBQQ__Product__c: isKitItem
        ? kitItemData?.SBQQ__OptionalSKU__c
        : this.itemData.value.id || this.itemData.value.Id,
      Min_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Hourly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Daily_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Weekly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Monthly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Selling_Price__c: this.isSalesConsumables
        ? this.parseRateValue(this.itemData?.value?.sellPrice)
        : 0,
      Total_Price__c: 0,
      Suggested_Minimum_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Suggested_Hourly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Suggested_Daily_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Suggested_Weekly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Suggested_Monthly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Specific_Pricing_Type__c: this.itemData.value.Specific_Pricing_Type__c,
      Line_Item_Type__c: isKitItem
        ? this.getLineItemType(productInfo)
        : this.getLineItemType(this.itemData?.value), // SAL-26036
      is_User_Added__c: true, // SAL-27192
      Kit_Number_this_Item_Belongs_to__c: isKitItem
        ? this.itemData?.value?.catClass
        : "",
      Fuel_Plan__c: this.hasFuelPlan ? true : false, //SF-5291,SF-5292
      Rates_Branch__c: this.parentBranch
    };

    return fields;
  }

  /**
   * Method to build object for Order Item record
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   * @returns
   */
  getOrderItemFields(isKitItem, kitItemData) {
    let kitComponentRates = {};
    let productInfo = {};
    if (isKitItem) {
      //Find rates for the kit component in the rate api response
      kitComponentRates = this.kitComponentRates.find(
        (item) => item.id == kitItemData.SBQQ__OptionalSKU__c
      );
      //Get product info to determine the line type field value
      productInfo = this.getProductInfoKitItem(kitItemData);
    }
    let fields = {
      OrderId: this.recordId,
      Product2Id: isKitItem
        ? kitItemData?.SBQQ__OptionalSKU__c
        : this.itemData?.value?.id || this.itemData?.value?.Id,
      groupID__c: Math.floor(100000 + Math.random() * 900000).toString(),
      Cat_Class__c: isKitItem
        ? kitItemData?.SBQQ__OptionalSKU__r.Product_SKU__c
        : this.itemData.value.catClass,
      Quantity: isKitItem
        ? kitItemData.SBQQ__Quantity__c * this.count
        : this.count,
      UnitPrice: 1.0,
      Min_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Hourly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Daily_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Weekly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Monthly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Selling_Price__c: this.isSalesConsumables
        ? this.parseRateValue(this.itemData?.value?.sellPrice)
        : 0,
      Total_Price__c: 0,
      Suggested_Minimum_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Suggested_Hourly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.minRate)
        : this.parseRateValue(this.itemData?.value?.minRate),
      Suggested_Daily_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesDaily)
        : this.parseRateValue(this.itemData?.value?.ratesDaily),
      Suggested_Weekly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesWeekly)
        : this.parseRateValue(this.itemData?.value?.ratesWeekly),
      Suggested_Monthly_Rate__c: isKitItem
        ? this.parseRateValue(kitComponentRates?.ratesMonthly)
        : this.parseRateValue(this.itemData?.value?.ratesMonthly),
      Specific_Pricing_Type__c: this.itemData?.value?.Specific_Pricing_Type__c,
      Line_Item_Type__c: isKitItem
        ? this.getLineItemType(productInfo)
        : this.getLineItemType(this.itemData?.value), // SAL-26036
      is_User_Added__c: true, // SAL-27192
      Kit_Number_This_Item_Belongs_To__c: isKitItem
        ? this.itemData?.value?.catClass
        : "",
      Fuel_Plan__c: this.hasFuelPlan ? true : false, //SF-5291,SF-5292
      Rates_Branch__c: this.parentBranch
    };

    return fields;
  }
  /**
   * Method to build payload for the products selected from product inquiry tab
   * @param {Boolean} isKitItem If true then kititem else regular cat class product
   * @param {Object} kitItemData Data for kititem else empty
   * @returns
   */
  getProductInquiryPayload(isKitItem, kitItemData) {
    const payload = {
      recordId: null,
      lineItem: {
        id: isKitItem
          ? kitItemData?.SBQQ__OptionalSKU__c
          : this.itemData?.value?.id || this.itemData?.value?.Id,
        name: isKitItem
          ? kitItemData?.SBQQ__ProductName__c
          : this.itemData?.value?.name,
        catClass: isKitItem
          ? kitItemData?.SBQQ__OptionalSKU__r?.Product_SKU__c
          : this.itemData?.value?.catClass,
        quantity: isKitItem
          ? kitItemData.SBQQ__Quantity__c * this.count
          : this.count,
        itemType: "base",
        productType: isKitItem
          ? kitItemData?.SBQQ__OptionalSKU__r?.Product_Type__c
          : this.itemData?.value?.productType,
        hasFuelPlan: this.hasFuelPlan ? true : false, //SF-5291,SF-5292
        lineItemType: this.getLineItemType(this.itemData?.value), //SF-5291,SF-5292
        rateBranch: this.parentBranch
      },
      type: "add"
    };
    //FRONT-11309 bulk add to cart from sales tab
    if (this.isSalesConsumables) {
      payload.lineItem.itemType = this.variant;
      payload.lineItem.itemNumber = this.itemData?.value?.itemNumber;
      payload.lineItem.stockClass = this.itemData?.value?.stockClass;
      payload.lineItem.productType = this.itemData?.value?.productType;
      payload.lineItem.sellPrice = this.itemData?.value?.sellPrice;
    }
    return payload;
  }

  /**
   * Method to build productinfo object for kititem
   * to determine lineItemType field on CartItem/QuoteLine/OrderItem
   * @param {Object} kitItemData Data for kititem
   * @returns productinfo object
   */
  getProductInfoKitItem(kitItemData) {
    let productInfo = {
      productType: kitItemData?.SBQQ__OptionalSKU__r?.Product_Type__c,
      inventoriedItem: kitItemData?.SBQQ__OptionalSKU__r?.Inventoried_Item__c,
      miscellaneousChargeItem:
        kitItemData?.SBQQ__OptionalSKU__r?.Miscellaneous_Charge_Item__c,
      stockClass: kitItemData?.SBQQ__OptionalSKU__r?.Stock_class__c
    };
    return productInfo;
  }

  //Method to process kit components of selected product
  addKitComponentsToCart() {
    this.kitComponents.forEach((kitItem) => {
      if (!SBRUtils.isEmpty(kitItem)) {
        if (!this.recordId) {
          //Item searched and added from Product Inquiry page
          this.addProductToCartPI(true, kitItem);
        } else {
          if (this.objectApiName === "Cart__c") {
            //Item searched and added from Cart record
            this.createCartItem(true, kitItem);
          } else if (this.objectApiName === "SBQQ__Quote__c") {
            //Item searched and added from Quote record
            this.createQuoteLine(true, kitItem);
          } else if (this.objectApiName === "Order") {
            //Item searched and added from Order record
            this.createOrderItem(true, kitItem);
          }
        }
      }
    });
  }

  //Method to insert line item records for Cart/Quote/Order dynamically
  async createLineItemRecords() {
    await createLineItems({
      apiName: this.objectApiName,
      lineItems: JSON.stringify(this.lineItemRecsToInsert)
    })
      .then((createdLineItemRecords) => {
        createdLineItemRecords.forEach((createdLineItem) => {
          const payload = {
            recordId: this.recordId,
            lineItem: createdLineItem,
            type: "add"
          };
          //Add productType property for line estimates call only applicable for Cart/PI
          if (
            this.objectApiName === "Cart__c" &&
            !SBRUtils.isEmpty(createdLineItem)
          ) {
            payload.productType =
              this.getProductTypeForCartItem(createdLineItem);
          }
          //send a message to lineitemscmp
          publish(this.messageContext, updateLineItemsChannel, payload);
          //Showing toast message only when last line item has been created
          if (this.isLastBulkItem) {
            this.dispatchEvent(
              new ShowToastEvent({
                message: "Line items were successfully added",
                variant: "success"
              })
            );
          }
          //send a message to uncheck the products from item search cmp
          if (!this.isMobile && this.isLastBulkItem) {
            publish(this.messageContext, deselectProductRowChannel, {
              productId: null,
              contextId: this.recordId,
              variant: this.variant
            });
          }
        });
        var successEvent = new CustomEvent("additemsuccess"); //FRONT-13129
        this.dispatchEvent(successEvent);
        return true;
      })
      .catch((error) => {
        let errorMsg = JSON.stringify(error);
        console.log("error on inventory",errorMsg)
        if (errorMsg.includes("INSUFFICIENT_ACCESS")) {
          errorMsg = "You do not have sufficient rights to add the item(s)";
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error adding line items",
            message: errorMsg,
            variant: "error"
          })
        );
        return false;
      });
  }

  /**
   * Method to find product type for the Cart record
   * @param {Object} createdCartItemRec Object holding data for created cart item rec
   * @returns productType String value
   */
  getProductTypeForCartItem(createdCartItemRec) {
    let productType = "";
    if (this.itemData.value.isKit === "Yes") {
      this.kitComponents.forEach((kitItem) => {
        if (
          kitItem?.SBQQ__OptionalSKU__r.Product_SKU__c ===
          createdCartItemRec?.Cat_Class__c
        ) {
          productType = kitItem?.SBQQ__OptionalSKU__r.Product_Type__c;
        }
      });
    } else {
      productType = this.itemData?.value?.productType;
    }
    return productType;
  }

  //Method to fetch addons for a selected product
  async getProductAddOns() {
    let results;
    try {
      results = await getProductAddOns({
        productId: this.itemData.value.id || this.itemData.value.Id,
        companyCode: this.companyCode,
        recordId: this.recordId,
        branch: this.parentBranch
      });
    } catch (error) {
      console.error("Error fetching product addons " + error.message);
    }
    this.productAddOns = JSON.parse(results);
  }

  /**
   * Method to add forced addon to the line item array for record insertion
   * @param {Object} forcedAddOnData Data for forced addon
   * @param {Boolean} isRentalAddOn rental forced addon flag
   * @param {Boolean} isSalesAddOn sales forced addon flag
   */
  addForcedAddOn(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
    if (!this.recordId) {
      //Item searched and added from Product Inquiry page.
      //Get payload for the msg channel
      let payload = this.getForcedAddOnPayloadPI(
        forcedAddOnData,
        isRentalAddOn,
        isSalesAddOn
      );
      //Send a message to line items cmp and it will fire a rates api call and populate data in the line item grid
      publish(this.messageContext, updateLineItemsChannel, payload);
    } else if (this.objectApiName === "Cart__c") {
      //Item searched and added from Cart record
      let fields = this.getForcedAddOnFieldsCartItem(
        forcedAddOnData,
        isRentalAddOn,
        isSalesAddOn
      );
      let lineItemRecordInput = {
        apiName: CART_ITEMS_OBJECT.objectApiName,
        fields
      };
      //Add forced addon as line item
      this.lineItemRecsToInsert.push(lineItemRecordInput);
    } else if (this.objectApiName === "SBQQ__Quote__c") {
      //Item searched and added from Quote record
      let fields = this.getForcedAddOnFieldsQuoteLine(
        forcedAddOnData,
        isRentalAddOn,
        isSalesAddOn
      );
      let lineItemRecordInput = {
        apiName: QUOTE_LINE_OBJECT.objectApiName,
        fields
      };
      //Add forced addon as line item
      this.lineItemRecsToInsert.push(lineItemRecordInput);
    } else if (this.objectApiName === "Order") {
      //Item searched and added from Order record
      let fields = this.getForcedAddOnFieldsOrderItem(
        forcedAddOnData,
        isRentalAddOn,
        isSalesAddOn
      );
      let lineItemRecordInput = {
        apiName: ORDER_ITEM_OBJECT.objectApiName,
        fields
      };
      //Add forced addon as line item
      this.lineItemRecsToInsert.push(lineItemRecordInput);
    }
  }
  /**
   * Method to create payload for a product selected from PI
   * @param {Object} forcedAddOnData  Data for forced add on
   * @param {Boolean} isRentalAddOn rental forced addon flag
   * @param {Boolean} isSalesAddOn sales forced addon flag
   * @returns {Object} payload Data for the msg channel
   */
  getForcedAddOnPayloadPI(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
    let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
    let addOnPIProdname = forcedAddOnData?.name; //SF-5291,SF-5292
    let hasPIFuelProducts =
      addOnPIProdname &&
      (addOnPIProdname.indexOf("Refill") !== -1 ||
        addOnPIProdname.indexOf("Fuel Convenience Charge") !== -1)
        ? true
        : false; //SF-5291,SF-5292
    const payload = {
      recordId: null,
      lineItem: {
        id: forcedAddOnData?.id,
        name: forcedAddOnData?.name,
        catClass: forcedAddOnData?.catClass,
        quantity: isRentalAddOn
          ? this.count * this.parseQuantityValue(forcedAddOnData?.availQuantity)
          : this.count * this.parseQuantityValue(forcedAddOnData?.minQuantity),
        itemType: this.getItemTypeForAddOn(isRentalAddOn, isSalesAddOn),
        productType: forcedAddOnData?.productType,
        stockClass: forcedAddOnData?.stockClass,
        itemNumber: forcedAddOnData?.itemNumber,
        sellPrice: forcedAddOnData?.sellPrice,
        is_Forced_Item__c: true,
        lineItemType: this.getLineItemType(productInfo), //SF-5291,SF-5292
        kitNumberBelongsTo:
          hasPIFuelProducts &&
          forcedAddOnData.stockClass === "FUEL" &&
          (this.itemData?.value?.catClass != "" ||
            this.itemData?.value?.catClass != NULL)
            ? this.itemData?.value?.catClass
            : "", //SF-5291,SF-5292
        notes:
          hasPIFuelProducts && this.itemData?.value?.name
            ? "Fuel Plan for " + this.itemData?.value?.name
            : "", //SF-5997
        rateBranch: this.parentBranch
      },
      type: "add"
    };

    return payload;
  }

  /**
   * Method to get fields of forced add on for cart item
   * @param {Object} forcedAddOnData Data for forced add on
   * @returns
   */
  getForcedAddOnFieldsCartItem(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
    let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
    let addOnCartProdname = forcedAddOnData?.name; //SF-5291,SF-5292
    let hasCartFuelProducts =
      addOnCartProdname &&
      (addOnCartProdname.indexOf("Refill") !== -1 ||
        addOnCartProdname.indexOf("Fuel Convenience Charge") !== -1)
        ? true
        : false; //SF-5291,SF-5292
    let fields = {
      Cart__c: this.recordId,
      Cat_Class__c: forcedAddOnData?.catClass,
      Name: forcedAddOnData?.name,
      Quantity__c: isRentalAddOn
        ? this.count * this.parseQuantityValue(forcedAddOnData?.availQuantity)
        : this.count * this.parseQuantityValue(forcedAddOnData?.minQuantity),
      Product__c: forcedAddOnData?.id,
      Minimum_Price__c: this.parseRateValue(forcedAddOnData?.minRate),
      Hourly_Price__c: this.parseRateValue(forcedAddOnData?.minRate),
      Daily_Price__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
      Weekly_Price__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
      Monthly_Price__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
      Item_Subtotal__c: 0,
      Suggested_Daily_Price__c: this.parseRateValue(
        forcedAddOnData?.ratesDaily
      ),
      Suggested_Weekly_Price__c: this.parseRateValue(
        forcedAddOnData?.ratesWeekly
      ),
      Suggested_Monthly_Price__c: this.parseRateValue(
        forcedAddOnData?.ratesMonthly
      ),
      Line_Item_Type__c: this.getLineItemType(productInfo),
      is_User_Added__c: true,
      is_Forced_Item__c: true,
      Kit_Number_This_Item_Belongs_to__c:
        (hasCartFuelProducts || isRentalAddOn || isSalesAddOn) &&
        (this.itemData?.value?.catClass != "" ||
          this.itemData?.value?.catClass != NULL)
          ? this.itemData?.value?.catClass
          : "", //SF-5291,SF-5292
      Line_Comments__c:
        hasCartFuelProducts && this.itemData?.value?.name
          ? "Fuel Plan for " + this.itemData?.value?.name
          : "", //SF-5997
      Misc_Sales_Price__c: this.parseRateValue(forcedAddOnData?.sellPrice),
      Rates_Branch__c: this.parentBranch
    };
    return fields;
  }

  /**
   * Method to get fields of forced add on for quote line
   * @param {Object} forcedAddOnData Data for forced add on
   * @returns
   */
  getForcedAddOnFieldsQuoteLine(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
    let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
    let addOnQuoteProdname = forcedAddOnData?.name; //SF-5291,SF-5292
    let hasQuoteFuelProduct =
      addOnQuoteProdname &&
      (addOnQuoteProdname.indexOf("Refill") !== -1 ||
        addOnQuoteProdname.indexOf("Fuel Convenience Charge") !== -1)
        ? true
        : false; //SF-5291,SF-5292
    let fields = {
      SBQQ__Quote__c: this.recordId,
      SBQQ__Quantity__c: isRentalAddOn
        ? this.count * this.parseQuantityValue(forcedAddOnData?.availQuantity)
        : this.count * this.parseQuantityValue(forcedAddOnData?.minQuantity),
      SBQQ__Product__c: forcedAddOnData?.id,
      Min_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
      Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
      Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
      Total_Price__c: 0,
      Suggested_Minimum_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Suggested_Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Suggested_Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
      Suggested_Weekly_Rate__c: this.parseRateValue(
        forcedAddOnData?.ratesWeekly
      ),
      Suggested_Monthly_Rate__c: this.parseRateValue(
        forcedAddOnData?.ratesMonthly
      ),
      Specific_Pricing_Type__c: this.itemData?.value?.Specific_Pricing_Type__c,
      Line_Item_Type__c: this.getLineItemType(productInfo),
      is_User_Added__c: true,
      is_Forced_Item__c: true,
      SBQQ__UnitCost__c: this.parseRateValue(forcedAddOnData?.sellPrice),
      Selling_Price__c: this.parseRateValue(forcedAddOnData?.sellPrice),
      Kit_Number_this_Item_Belongs_to__c:
        (hasQuoteFuelProduct || isRentalAddOn || isSalesAddOn) &&
        (this.itemData?.value?.catClass != "" ||
          this.itemData?.value?.catClass != NULL)
          ? this.itemData?.value?.catClass
          : "", //SF-5291,SF-5292
      Line_Comments__c:
        hasQuoteFuelProduct && this.itemData?.value?.name
          ? "Fuel Plan for " + this.itemData?.value?.name
          : "", //SF-5997
      Misc_Charge__c:
        forcedAddOnData?.productType === "MISC"
          ? this.parseRateValue(forcedAddOnData?.sellPrice)
          : 0,
      Rates_Branch__c: this.parentBranch
    };
    return fields;
  }

  /**
   * Method to get fields of forced add on for order item
   * @param {Object} forcedAddOnData Data for forced add on
   * @returns
   */
  getForcedAddOnFieldsOrderItem(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
    let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
    let addOnOrderProdname = forcedAddOnData?.name;
    let hasOrderFuelProduct =
      addOnOrderProdname &&
      (addOnOrderProdname.indexOf("Refill") !== -1 ||
        addOnOrderProdname.indexOf("Fuel Convenience Charge") !== -1)
        ? true
        : false; //SF-5291,SF-5292
    let fields = {
      OrderId: this.recordId,
      Product2Id: forcedAddOnData?.id,
      Cat_Class__c: forcedAddOnData?.catClass,
      groupID__c: Math.floor(100000 + Math.random() * 900000).toString(),
      Quantity: isRentalAddOn
        ? this.count * this.parseQuantityValue(forcedAddOnData?.availQuantity)
        : this.count * this.parseQuantityValue(forcedAddOnData?.minQuantity),
      Min_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
      Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
      Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
      Total_Price__c: 0,
      Suggested_Minimum_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Suggested_Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
      Suggested_Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
      Suggested_Weekly_Rate__c: this.parseRateValue(
        forcedAddOnData?.ratesWeekly
      ),
      Suggested_Monthly_Rate__c: this.parseRateValue(
        forcedAddOnData?.ratesMonthly
      ),
      Line_Item_Type__c: this.getLineItemType(productInfo),
      is_User_Added__c: true,
      is_Forced_Item__c: true,
      Selling_Price__c: this.parseRateValue(forcedAddOnData?.sellPrice),
      UnitPrice: this.parseRateValue(forcedAddOnData?.sellPrice),
      Kit_Number_This_Item_Belongs_to__c:
        (hasOrderFuelProduct || isRentalAddOn || isSalesAddOn) &&
        (this.itemData?.value?.catClass != "" ||
          this.itemData?.value?.catClass != NULL)
          ? this.itemData?.value?.catClass
          : "", //SF-5291,SF-5292
      Line_Comments__c:
        hasOrderFuelProduct && this.itemData?.value?.name
          ? "Fuel Plan for " + this.itemData?.value?.name
          : "", //SF-5997
      Misc_Charge__c:
        forcedAddOnData?.productType === "MISC"
          ? this.parseRateValue(forcedAddOnData?.sellPrice)
          : 0,
      Rates_Branch__c: this.parentBranch
    };
    return fields;
  }

  /**
   * Method to get product info of forced add on
   * @param {*} forcedAddOnData Data for forced add on
   * @returns
   */
  getForcedAddOnProductInfo(forcedAddOnData) {
    let productInfo = {
      productType: forcedAddOnData?.productType,
      inventoriedItem: forcedAddOnData?.inventoriedItem,
      miscellaneousChargeItem: forcedAddOnData?.miscellaneousChargeItem,
      stockClass: forcedAddOnData?.stockClass
    };
    return productInfo;
  }

  /**
   * Method to filter and add rental forced addon
   */
  async addRentalForcedAddOns() {
    this.rentalAddOns = this.itemData?.value?.rentalAddOns;
    if (!SBRUtils.isEmpty(this.rentalAddOns)) {
      //Filtering rental forced addons OR //SF-5291,SF-5292
      this.rentalAddOns.forEach((rentalAddon) => {
        let addOnRentalProdname = rentalAddon?.name;
        let hasFuelProductRental =
          addOnRentalProdname.indexOf("Refill") !== -1 ||
          addOnRentalProdname.indexOf("Fuel Convenience Charge") !== -1
            ? true
            : false;
        if (rentalAddon.isRequired || hasFuelProductRental) {
          this.addForcedAddOn(rentalAddon, true, false);
        }
      });
    } else {
      console.warn("No rental addons found for the selected product");
    }
  }

  /**
   * Method to filter and add sales forced addon //SF-5291,SF-5292
   */
  async addSalesForcedAddOns() {
    this.salesAddOns = this.itemData?.value?.salesAddOns;
    if (!SBRUtils.isEmpty(this.salesAddOns)) {
      //Filtering sales forced addons
      this.salesAddOns.forEach((salesAddOn) => {
        let addOnSalesProdname = JSON.stringify(salesAddOn?.name);
        let hasFuelProductSales =
          addOnSalesProdname.indexOf("Refill") !== -1 ||
          addOnSalesProdname.indexOf("Fuel Convenience Charge") !== -1
            ? true
            : false;
        if (salesAddOn.isRequired || hasFuelProductSales) {
          this.addForcedAddOn(salesAddOn, false, true);
        }
      });
    } else {
      console.warn("No sales addons found for the selected product");
    }
  }

  /**
   * Method to determine ItemType prop value for message channel
   * @param {Boolean} isRentalAddOn rental addon flag
   * @param {Boolean} isSalesAddOn  sales addon flag
   * @returns
   */
  getItemTypeForAddOn(isRentalAddOn, isSalesAddOn) {
    if (isRentalAddOn) {
      return "rental";
    } else if (isSalesAddOn) {
      return "sales";
    } else {
      return "base";
    }
  }

  get isSalesConsumables() {
    return this.variant === "consumableSalesAddOn";
  }
}