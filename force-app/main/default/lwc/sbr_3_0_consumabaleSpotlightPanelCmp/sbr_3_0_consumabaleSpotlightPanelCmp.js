/* eslint-disable @lwc/lwc/no-api-reassignments */
/* eslint-disable @lwc/lwc/no-leading-uppercase-api-name */
/* eslint-disable no-unused-vars */
import { LightningElement, api, wire, track } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from "lightning/navigation";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import getProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductDetails";
import sbr_3_0_consumabaleSpotlightPanelCmpDesktop from "./sbr_3_0_consumabaleSpotlightPanelCmpDesktop.html";
import sbr_3_0_consumabaleSpotlightPanelCmpMobile from "./sbr_3_0_consumabaleSpotlightPanelCmpMobile.html";
import getProductRates from "@salesforce/apex/SBR_3_0_ConsumablesGetRatesController.getConsumableProductRates";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c"; /*----- End- FRONT-15734 ---- */
import {
  publish,
  MessageContext
} from "lightning/messageService"; /*----- End- FRONT-15734 ---- */
import { createMessageContext } from "lightning/messageService"; /*----- End- FRONT-15734 ---- */
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import COMPANY_CODE_FIELD from "@salesforce/schema/User.CompanyName";
const userFields = [COMPANY_CODE_FIELD];
import { getRecord } from "lightning/uiRecordApi";
import UserId from "@salesforce/user/Id";
export default class Sbr_3_0_consumabaleSpotlightPanelCmp extends NavigationMixin(
  LightningElement
) {
  @api selectedProducts = [];
  @api recordId;
  @api objectApiName;
  @api passedCustomerNumber;
  @api locationInfo;
  @track isMiscProductType = false; //FRONT-14358,14357,14356
  @track isBulkMisc = false;
  @api contractSalesTab; //added for FRONT-15258

  /* FRONT - 1904 : Setting variant for loading view*/
  @api variant = "";
  /* END : FRONT - 1904*/
  isMobile;
  _selectedProducts = [];
  isSelectedState = false;
  panelTitle = "Spotlight Panel";
  panelType = "inactivePanel";
  productId = "";
  bulkProductIds = [];

  //isDetailsPanel;
  @api mobileProductId;
  isNotRecordPage = false;
  selectedProductIds;
  selectedProductDescription = "";
  companyCode;
  userId = UserId;
  selectedClass = "back-button slds-button slds-button_neutral active-state";
  unselectedClass = "back-button slds-button slds-button_neutral selected-btn";
  mobileProps = {
    zIndex: 9004,
    footerClasses: "slds-p-around_none"
  };
  //Added as part of FRONT-8623
  items;
  @track ratesParamObject;
  error = "";
  @track selectedItems = [];
  @track selectedProductWithRates;

  costPrice = 0;
  salesPrice = 0;

  @api productDescription;
  messageContext = createMessageContext(); /*----- End- FRONT-15734 ---- */

  //FRONT-8623 Ends
  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
    if (this.isMobile && this.selectedProducts.length > 0) {
      this.items = this.selectedProducts;
      this.isMiscProductType =
        this.selectedProducts[0].productType === "Misc-Charge" ||
        this.selectedProducts[0].productType === "MISC Charge Items"; //FRONT-14358,14357,14356,14364
      this.selectedItems = this.selectedProducts; //Added to set SelectedItems
      this.setRatesParamObject();
    }
    if (this.isMobile) {
      this.itemSearchBackBtnClass = this.unselectedClass;
      this.selectedProductDescription = this.productDescription;
    }
    this.isNotRecordPage = !this.recordId && !this.objectApiName;
  }

  @api
  toggleSpotlightPanel(selectedProds) {
    const itemsSelected = selectedProds; //Added as part of FRONT-8623
    selectedProds = this.processProducts(selectedProds);
    logger.log("===selectedProds===", JSON.stringify(selectedProds));
    this.selectedItems = selectedProds;
    let selectedProductsCount = selectedProds.length;

    if (selectedProductsCount === 0) {
      this.selectedProductDescription = "";
      this.isSelectedState = false;
      this.panelType = "inactivePanel";
      this.panelTitle = "Spotlight Panel";
      this.items = []; //Added as part of FRONT-8623

      this.setRatesParamObject();
    } else if (selectedProductsCount === 1) {
      this.isSelectedState = true;
      this.panelType = "detailsPanel";
      this.panelTitle = selectedProds[0].name
        ? selectedProds[0].name
        : "Spotlight Panel";
      this.productId = selectedProds[0].Id ? selectedProds[0].Id : "";
      this.selectedProductDescription = selectedProds[0].description
        ? selectedProds[0].description
        : "";
      this.items = this.processItems(itemsSelected); //Added as part of FRONT-8623
      this.setRatesParamObject();

      this.selectedProducts = this.selectedProducts.concat(selectedProds);
      if (
        this._selectedProducts !== undefined &&
        this._selectedProducts.length === 0
      ) {
        this._selectedProducts = selectedProds;
      }
    } else if (selectedProductsCount > 1) {
      this.isSelectedState = true;
      this.panelType = "bulkAddPanel";
      this.panelTitle = this.variant === "Sales" ? "Multi Add" : "Bulk Add";
      this.bulkProductIds = selectedProds.map((p) => p.Id);
      this.items = this.processItems(itemsSelected); //Added as part of FRONT-8623
      this.setRatesParamObject();
    }

    if (this.isMobile) {
      let addToCartCmp = this.template.querySelector(
        "c-sbr_3_0_add-to-cart-cmp"
      );
      if (addToCartCmp) {
        addToCartCmp.resetCount();
      }
    }
    if (
      this.objectApiName === "Order" ||
      this.objectApiName === "SBQQ__Quote__c"
    ) {
      this.setRatesParamObject();
    }
    if (selectedProductsCount > 0) {
      this.getProductDetails();
    }
    this.selectedProductIds = this.selectedProducts.map(
      (selectedProd) => selectedProd.Id || selectedProd.id
    );
  }

  //FRONT-15676
  @api
  checkSelectedvalue(isMiscSelected) {
    this.isMiscProductType = !isMiscSelected;
  }

  handleSelectedItem(event) {
    let selectedItem = event.detail;
    this.toggleSpotlightPanel(selectedItem);
  }

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") === -1) {
      currentsection.className = "slds-section slds-is-open";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }
  }

  processProducts(selectedProducts) {
    let products = [];
    selectedProducts.forEach((item) => {
      let row = {};
      if (item.product) {
        row = {
          Id: item.product.Id,
          name: item.product.Name,
          itemNumber: item.product.Item_Number__c,
          stockClass: item.product.Stock_class__c,
          sellPrice: item.product.Sell_Price__c,
          description: item.product.Product_Description__c,
          availableQty: item.availableQty,
          productType: item.product.Product_Type__c,
          inventoriedItem: item.product.Inventoried_Item__c,
          miscellaneousChargeItem: item.product.Miscellaneous_Charge_Item__c,
          typeOfMiscChargeItem: item.product.Type_of_Misc_Charge_Item__c
        };
      }
      products.push(row);
    });
    return products;
  }

  async getProductDetails() {
    this.isMiscProductType =
      this.selectedProducts[0].productType === "Misc-Charge" ||
      this.selectedProducts[0].productType === "MISC Charge Items"; //FRONT-14358,14357,14356
    let productId =
      this._selectedProducts[0].id || this._selectedProducts[0].Id;
    try {
      let result = await getProductDetails({ productId: productId });
      if (result) {
        this.productDescription = JSON.parse(result);
        this.productDescription =
          this.productDescription.Description != null
            ? this.productDescription.Description
            : false;
      }
    } catch (error) {
      logger.log("error in getProductDetails:" + JSON.stringify(error));
    }
  }

  get unselectedStateClass() {
    return this.isSelectedState
      ? "item-not-selected slds-grid"
      : "item-not-selected slds-grid active";
  }

  get selectedStateClass() {
    return this.isSelectedState ? "item-selected active" : "item-selected";
  }

  get spotlightHeightStyle() {
    //Modified as part of  FRONT-11384
    return this.variant === "Sales"
      ? `height:600px;`
      : `height:${this.spotlightHeight}px;`;
  }

  //getters
  get isInactivePanel() {
    return this.panelType === "inactivePanel";
  }

  get isDetailsPanel() {
    return this.panelType === "detailsPanel";
  }

  get isBulkAddPanel() {
    return this.panelType === "bulkAddPanel";
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = sbr_3_0_consumabaleSpotlightPanelCmpMobile;
    } else {
      renderTemplate = sbr_3_0_consumabaleSpotlightPanelCmpDesktop;
    }
    return renderTemplate;
  }

  renderedCallback() {
    loadStyle(this, FrontLineCSS);
    }

  @api productItemId;
  backToItemSearch(event) {
    this.itemSearchBackBtnClass = this.selectedClass;
    const backToItemSearchEvent = new CustomEvent("backitemsearchevent", {
      detail: this.productItemId
    });
    this.dispatchEvent(backToItemSearchEvent);
    this.itemSearchBackBtnClass = this.unselectedClass;
  }

  toggleAddCustomerMob(event) {
    // this.isAddCustomerSelected = true;
    // this.viewState = "item-spotlight";
    const toggleprodinqmobilestate = new CustomEvent(
      "toggleprodinqmobilestate",
      {
        bubbles: true,
        composed: true,
        detail: {
          viewState: "cust-info",
          showTabsPanel: false
        }
      }
    );
    this.dispatchEvent(toggleprodinqmobilestate);
  }

  //Added as part of FRONT-8623
  processItems(itemsSelected) {
    let itemsList = [];
    itemsSelected.forEach((prod) => {
      let itemObj = {
        itemNumber: prod?.product?.Item_Number__c,
        stockClass: prod?.product?.Stock_class__c,
        quantity: prod?.availableQty,
        cost: prod?.product?.Sell_Price__c ? prod?.product?.Sell_Price__c : 0.0
      };
      itemsList.push(itemObj);
    });
    return itemsList;
  }

  //Added as part of FRONT-8623
  @wire(getProductRates, { prwrapper: "$ratesParamObject" })
  wiredProductRates({ error, data }) {
    let selProd = [];
    let defaultRates = {
      costPrice: 0,
      sellPrice: 0
    };
    if (data) {
      let parsedData = JSON.parse(data);
      if (parsedData?.errors) {
        for (const err of parsedData.errors) {
          this.displayErrorMessage(err.message, "Validation Error");
        }
        this.error = parsedData.errors?.message;
        //this.hasRatesLoaded = false;
        //this.rates = this.ratesUnavailable;

        if (this.selectedItems.length === 1) {
          this._selectedProducts = selProd;
        }
      } else if (parsedData.error) {
        if (this.selectedItems.length > 0) {
          this.displayErrorMessage(
            parsedData.error.message,
            "Validation Error"
          );
        }
      } else {
        let ratesData = parsedData?.data;
        this.rates = ratesData?.salesItems;
        const packages = [this.rates];
        const replacer = {
          sales_price: "sales_price",
          cost_price: "cost_price"
        };

        this.selectedProductWithRates = [];
        if (this.selectedItems.length > 0) {
          this.selectedItems.forEach((item, index) => {
            try {
              selProd[index] = Object.assign({}, defaultRates, item); //merge 2 arrays
              selProd[index].sellPrice = this.rates?.[index]?.price;
              selProd[index].costPrice = this.rates?.[index]?.cost;
              this.selectedProductWithRates.push(selProd[index]);
            } catch (error) {
              logger.log("Error: " + error.message);
            }
          });

          //to show the pricing information in spotlight panel
          if (this.selectedProductWithRates) {
            let tempProd = this.selectedProductWithRates[0];
            this.costPrice = tempProd.costPrice;
            this.salesPrice = tempProd.sellPrice;
          }
        }

        //call bulk add component and pass the data
        if (this.isBulkAddPanel) {
          this.template
            .querySelector(
              "c-sbr_3_0_bulk-add-cmp[data-comp-id='salesBulkAddPanel']"
            )
            .processSalesInvetoryItems(this.selectedProductWithRates);
        }
      }
    } else if (error) {
      logger.log("error-->" + JSON.stringify(error));
    }
  }

  //added a length check to avoid Rates API call if this.items list is empty
  setRatesParamObject() {
    if (this.items && this.items.length > 0) {
      this.ratesParamObject = {
        ...this.ratesParamObject,
        items: this.items
      };
    }
  }

  displayErrorMessage(message, title) {
    const notificationError = new ShowToastEvent({
      title: title,
      message: message,
      variant: "error"
    });
    this.dispatchEvent(notificationError);
  }
  //FRONT-8623 ends

  /*----- Start- FRONT-15734 ---- */
  removeSpotlighData(event) {
    event.preventDefault();
    event.stopPropagation();
    publish(this.messageContext, deselectProductRowChannel, {
      productId: null,
      contextId: this.recordId,
      variant: "consumableSalesAddOn"
    });
    this.panelTitle = "Spotlight Panel";
    this.panelType = "detailsPanel";
  }
  /*----- End- FRONT-15734 ---- */

  @wire(getRecord, { recordId: UserId, fields: userFields })
  wiredUser({ error, data }) {
    if (data) {
      this.companyCode = data.fields.CompanyName.value;
    } else if (error) {
      logger.log("Spotlight wiredUser error:", error);
    }
  }

  //FRONT-15732
  get productName() {
    return this.items && this.items.length > 0 ? this.items[0].name : "";
  }

  //FRONT-15732
  get isNotContractSalesTab() {
    return !this.contractSalesTab;
  }
}