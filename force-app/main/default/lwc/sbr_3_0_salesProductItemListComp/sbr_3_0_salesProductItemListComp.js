import { LightningElement, api, track } from "lwc";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import DESKTOPTEMPLATE from "./sbr_3_0_salesProductItemListCompDesktop.html";
import MOBILE_TEMPLATE from "./sbr_3_0_salesProductItemListCompMobile.html";
import FORM_FACTOR from "@salesforce/client/formFactor";

const logger = Logger.create(true);
const SMALL_FORM_FACTOR = "Small";
export default class Sbr_3_0_salesProductItemListComp extends LightningElement {
  _productItems;
  mobileIsLoading = false;
  productId = "";
  productCatclass = [];
  productItemId = "";
  isDetailPage = false; //11395
  @api locationInfo;
  @api recordId;
  @api objectApiName;
  @api selectedProductIds;
  @track selectedItems = [];
  productDescription = "";
  @api isContractSalesTab; //FRONT-15259,28872
  @api showAvailability;

  @api
  get productItemDetails() {
    return this._productItems;
  }
  set productItemDetails(value) {
    this.mobileIsLoading = false;
    this._productItems = value;
  }

  render() {
    let renderTemplate;
    if (!this.isMobileView) {
      renderTemplate = DESKTOPTEMPLATE;
    } else {
      renderTemplate = MOBILE_TEMPLATE;
    }
    return renderTemplate;
  }

  connectedCallback() {
    logger.log("Sbr_3_0_salesProductItemListComp Initiated !");
  }

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  loadMoreDataMobile(event) {
    if (
      event.target.scrollTop >
        event.target.scrollHeight - event.target.offsetHeight &&
      !this.mobileIsLoading
    ) {
      this.mobileIsLoading = true;

      const selectEvent = new CustomEvent("loadmore", {
        detail: { isLoadMoreMobile: true }
      });
      this.dispatchEvent(selectEvent);
    }
  }

  //11395
  handleCheckboxChange(event) {
    if (event.target.checked) {
      this.productId = event.target.dataset.productId;
      this.productItemId = event.target.id;
      this.isDetailPage = true;
      /*below condition added for FRONT-19392*/
      if (this.isMobileView) {
        const selectEvent = new CustomEvent("detailview", {
          detail: { chosendetailedview: true }
        });
        this.dispatchEvent(selectEvent);
      }
      let checkedProduct = this.getProductDescriptionFromSelectedProduct(
        this.productId
      );
      this.selectedItems = this.processProducts(checkedProduct);
      this.productDescription = checkedProduct[0]?.description;
    }
  }

  getProductDescriptionFromSelectedProduct(prodId) {
    return this._productItems.filter((e) => {
      return e.product.Id === prodId;
    });
  }

  //11395
  handleBackToItemSearchButton(event) {
    this.template.querySelector('[id="' + event.detail + '"]').checked = false;
    this.isDetailPage = false;
    /*below condition added for FRONT-19392*/
    if (this.isMobileView) {
      const selectEvent = new CustomEvent("detailview", {
        detail: { chosendetailedview: false }
      });
      this.dispatchEvent(selectEvent);
    }
  }

  processProducts(selectedProducts) {
    let products = [];
    selectedProducts?.forEach((item) => {
      let row = {
        id: item.product.Id,
        name: item.product.Name,
        itemNumber: item.product.Item_Number__c,
        stockClass: item.product.Stock_class__c,
        sellPrice: item.product.Sell_Price__c,
        quantity: item.availableQty,
        productType: item.product.Product_Type__c //FRONT-14364
      };
      products.push(row);
    });
    return products;
  }
}