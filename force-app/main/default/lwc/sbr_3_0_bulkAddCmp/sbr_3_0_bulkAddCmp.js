import { LightningElement, api, wire, track } from "lwc";
import getBulkProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBulkProductDetails";
import getBulkAssetProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBulkAssetsProductDetails"; //FRONT-11329
import getProductAvailabilities from "@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import createLineItems from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.createLineItems";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import { createMessageContext } from "lightning/messageService";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_bulkAddCmp extends LightningElement {
  @api variant = "base";
  @api itemType = "bulkInventory";
  @api productId = "";
  @api bulkProductIds = [];
  @api recordId;
  @api objectApiName;
  @api customerNumber;
  @api companyCode;
  @api productType;
  @api existingLineItems = [];
  errorAddItem = false;
  @track inventoryItems = [];
  @api productList = [];
  atcRecordArr = [];
  @api tabname = ""; //Added as part of FRONT-11384
  @api locationInfo;
  @api assetBulkProductIds; //FRONT-11329
  @api selectedSalesItems;
  isSalesTab = false;
  delayTimeout;
  showBulkMsg = true;
  showSpinner = true;
  dprSubscription = null;
  messageContext = createMessageContext();
  showCustomerSpecificRatesMsg = false;
  relatedListId = "";
  fields = [];
  _bulkProductData;
  @api contractSalesTab; //added for FRONT-15258
  @api
  get bulkProductData() {
    return this._bulkProductData;
  }

  set bulkProductData(value) {
    this.showSpinner = true;
    this._bulkProductData = JSON.parse(JSON.stringify(value));
    if (this._bulkProductData) {
      // Separate response into products and rental addons
      const products = this._bulkProductData.filter(
        (item) => item.featureName === null
      );

      const addOns = this._bulkProductData.filter(
        (item) => item.featureName !== null
      );

      // Find and add addons to products array
      addOns.forEach((addon) => {
        const matchingProduct = products.find(
          (product) => product.catClass === addon.parentSKU
        );
        if (matchingProduct) {
          if (!matchingProduct.rentalAddOns) {
            matchingProduct.rentalAddOns = [];
          }
          if (!matchingProduct.salesAddOns) {
            matchingProduct.salesAddOns = [];
          }
          if (!matchingProduct.kitComponents) {
            matchingProduct.kitComponents = [];
          }
          if (addon.featureName === "Sales Addons") {
            matchingProduct.salesAddOns.push(addon);
          }
          if (addon.featureName === "Rental Addons") {
            matchingProduct.rentalAddOns.push(addon);
          }
          if (addon.featureName === "Kit Component") {
            matchingProduct.kitComponents.push(addon);
          }
        }
      });

      this.getCustomerSpecificPricingMsg(products);
      this.inventoryItems = products;
      console.log("### added" + JSON.stringify(this.inventoryItems));
      this.showSpinner = false;
    } else {
      this.showSpinner = false;
      console.log(error);
    }
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
    if (this.tabname === "Sales") {
      this.isSalesTab = true;
    }
    this.initRecordContextVariables();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
    if (!this.dprSubscription) {
      this.dprSubscription = subscribe(
        this.messageContext,
        deselectProductRowChannel,
        (item) => this.removeInventoryItem(item),
        { scope: APPLICATION_SCOPE }
      );
    }
  }
  unsubscribeToMessageChannel() {
    unsubscribe(this.dprSubscription);
    this.dprSubscription = null;
  }

  removeInventoryItem(item) {
    if (this.tabname === "itemSearchAsset") {
      //FRONT-13129
      if (item.productId) {
        this.inventoryItems = this.inventoryItems.filter(
          (invItem) => invItem.assetid !== item.productId
        );
      } else {
        this.inventoryItems = [];
      }
    } else {
      if (item.productId) {
        this.inventoryItems = this.inventoryItems.filter(
          (invItem) => invItem.id !== item.productId
        );
      } else {
        this.inventoryItems = [];
      }
    }
  }

  initRecordContextVariables() {
    if (this.recordId) {
      switch (this.objectApiName) {
        case "Cart__c":
          this.relatedListId = "Cart_Items__r";
          this.fields = [
            "Cart_Items__c.Id",
            "Cart_Items__c.Product__r.Product_SKU__c",
            "Cart_Items__c.Quantity__c"
          ];
          break;
        case "SBQQ__Quote__c":
          this.relatedListId = "SBQQ__LineItems__r";
          this.fields = [
            "SBQQ__QuoteLine__c.Id",
            "SBQQ__QuoteLine__c.Product_SKU__c",
            "SBQQ__QuoteLine__c.SBQQ__Quantity__c"
          ];
          break;
        case "Order":
          this.relatedListId = "OrderItems";
          this.fields = [
            "OrderItem.Id",
            "OrderItem.Product2.Product_SKU__c",
            "OrderItem.Quantity"
          ];
          break;
      }
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: "$recordId",
    relatedListId: "$relatedListId",
    fields: "$fields"
  })
  listInfo(result) {
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
      catClass: record.fields.Product__r.value.fields.Product_SKU__c.value
    }));
  }

  mapQuoteRecords(records) {
    return records.map((record) => ({
      Id: record.fields.Id.value,
      quantity: record.fields.SBQQ__Quantity__c.value,
      catClass: record.fields.Product_SKU__c.value
    }));
  }

  mapOrderRecords(records) {
    return records.map((record) => ({
      Id: record.fields.Id.value,
      quantity: record.fields.Quantity.value,
      catClass: record.fields.Product2.value.fields.Product_SKU__c.value
    }));
  }

  /*@wire(getBulkProductDetails, { productIds: "$bulkProductIds" })
  wiredAlternateProducts({ error, data }) {
    if (data) {
      this.inventoryItems = data;
      this.getCustomerSpecificPricingMsg(this.inventoryItems);
      this.showSpinner = false;
    } else if (error) {
      this.showSpinner = false;
      console.log(error);
    }
  } */

  get isBase() {
    return this.variant == "base";
  }

  get isCompact() {
    return this.variant == "compact";
  }

  get addItemBtnLabel() {
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

  getCustomerSpecificPricingMsg(items) {
    let specialRateProductCount = 0;
    for (let i = 0; i < items.length; i++) {
      let rateFlag = items[i].rateFlag;
      console.log("rate flag kah" + rateFlag);
      let notToExceed = items[i].notToExceed;
      if (rateFlag == "Y") {
        specialRateProductCount++;

        switch (notToExceed) {
          case "S":
            this.inventoryItems[i].Specific_Pricing_Type__c = "Set Rates";
            break;
          case "X":
            this.inventoryItems[i].Specific_Pricing_Type__c = "Do Not Exceed";
            break;
          case "P":
            this.inventoryItems[i].Specific_Pricing_Type__c =
              "Percent Off Local Book";
            break;
          case "":
            this.inventoryItems[i].Specific_Pricing_Type__c = "Customer Loaded";
            break;
          default:
            break;
        }
      }
      if (specialRateProductCount > 0) {
        this.customerSpecificRatesAlertMsg =
          "Customer Special pricing has been applied. Please review line item details for more information.";
        this.showCustomerSpecificRatesMsg = true;
      }
    }
  }

  closeMsg() {
    this.showBulkMsg = false;
  }

  async addToCart() {
    try {
      this.showSpinner = true;
      const inventories = this.template.querySelectorAll(
        "c-sbr_3_0_inventory-item-cmp"
      );
      // Added for SAL-26730
      for (let i = 0; i < inventories.length; i++) {
        if (i == inventories.length - 1) {
          inventories[i].isLastBulkItem = true;
        }
        const isSuccess = await inventories[i].addToCart();

        if (!isSuccess) {
          this.errorAddItem = true;
        }
      }
      this.showSpinner = false;
      // publish(this.messageContext, deselectProductRowChannel, {
      //   productId: null
      // });
    } catch (err) {
      console.error("error in bulk" + JSON.stringify(err.message));
    }
  }

  async asyncForEach(array, callback) {
    for (let index = 0; index < array.length; index++) {
      await callback(array[index], index, array);
    }
  }

  async getProductAvailabilities(products) {
    console.log("Product Bulk Data :- " + JSON.stringify(products));
    let catClasses = products.map((product) => product.catClass);
    const productAvailabilities = await getProductAvailabilities({
      products: catClasses,
      type: "summary",
      locationInfo: JSON.stringify(this.locationInfo)
    });
    const catClassToAvailability = new Map();
    for (let productAvailability of productAvailabilities) {
      catClassToAvailability.set(
        productAvailability.catClass,
        productAvailability
      );
    }
    this.inventoryItems = products.map((product) => {
      let availabilityInfo = catClassToAvailability.get(
        product.catClass
      )?.availabilityInfo;
      let branchObject = {
        available: "n/a",
        pickUp: "n/a",
        reserve: "n/a"
      };
      if (availabilityInfo) {
        branchObject =
          availabilityInfo.find((item) => item.label === "Branch") ??
          branchObject;
      }

      return {
        ...product,
        availabilityA: branchObject.available,
        availabilityU: branchObject.pickUp,
        availabilityR: branchObject.reserve
      };
    });
    this.getCustomerSpecificPricingMsg(this.inventoryItems);
  }
  disableSpinner(event) {
    this.showSpinner = false; //FRONT-13129
  }

  @api
  processSalesInvetoryItems(selectedSalesItems) {
    this.showSpinner = true;
    this.inventoryItems = [];
    console.log(
      "Bulk Add Component for Sales Tab - -processSalesInvetoryItems -- " +
        selectedSalesItems
    );
    window.clearTimeout(this.delayTimeout);
    this.delayTimeout = setTimeout(() => {
      selectedSalesItems.forEach((item) => {
        let row = {
          Id: item.Id,
          name: item.name,
          stockClass: item.stockClass,
          sellPrice: item.sellPrice,
          itemNumber: item.itemNumber,
          availQuantity: item.availableQty,
          productType: item.productType,
          inventoriedItem: item.inventoriedItem,
          miscellaneousChargeItem: item.miscellaneousChargeItem,
          typeOfMiscChargeItem: item.typeOfMiscChargeItem
        };
        this.inventoryItems.push(row);
        this.showSpinner = false;
      });
      console.log(
        "=====inventoryItems====",
        JSON.stringify(this.inventoryItems)
      );
    }, 500);
  }
  @wire(getBulkAssetProductDetails, { productIds: "$assetBulkProductIds" }) //FRONT-13129
  wiredAlternateProductsAsset({ error, data }) {
    if (data) {
      console.log("Product Data Bulk : " + JSON.stringify(data));
      this.getProductAvailabilities(JSON.parse(data));
      this.showSpinner = false;
    } else if (error) {
      this.showSpinner = false;
      console.log(error);
    }
  }
  get multiAddBannerMessage() {
    console.log("contractSalesTab::" + this.contractSalesTab);
    if (this.contractSalesTab && this.productType) {
      return LABELS.MULTI_ADD_MISC_BANNER_MSG;
    }
    return LABELS.MULTI_ADD_COMMON_BANNER_MSG;
  }
}