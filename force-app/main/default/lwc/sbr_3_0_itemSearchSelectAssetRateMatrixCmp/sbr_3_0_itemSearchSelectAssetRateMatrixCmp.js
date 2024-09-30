import { LightningElement, api, track } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import FORM_FACTOR from "@salesforce/client/formFactor";
import mobileTemplate from "./sbr_3_0_itemSearchSelectAssetRateMatrixCmpMobile.html";
import desktopTemplate from "./sbr_3_0_itemSearchSelectAssetRateMatrixCmpDesktop.html";
const logger = Logger.create(true);

export default class Sbr_3_0_itemSearchSelectAssetRateMatrixCmp extends LightningElement {
  @api currentActiveTab;
  error;
  hasRatesLoaded;
  @api ratesInfo;
  @track rates;
  @api recordId;
  @api objectApiName;
  _selectedAsset;
  @api orderData;
  isMobile = false;
  @api locationInfo;
  @track productCatclass = [];
  ratesParamObject = {
    products: [],
    customerNumber: ""
  };

  @api
  get selectedAsset() {
    return this._selectedAsset;
  }
  set selectedAsset(value) {
    logger.log(
      this.currentActiveTab,
      "🚀 selectedAsset Data ::: " + JSON.stringify(value)
    );
    this._selectedAsset = value;

    //this.buildAssetData();
  }

  get productName() {
    // return this.selectedAsset.Product2.Name;
    return this._selectedAsset?.ProductName
      ? this._selectedAsset?.ProductName
      : this._selectedAsset?.Product2?.Name ||
          this._selectedAsset?.["Product2.Name"];
  }

  get catClass() {
    //return this.selectedAsset.Product2.Product_SKU__c;
    return this.isMobile
      ? this._selectedAsset?.Product2?.PPA_CatClass__c
      : this._selectedAsset?.["Product2.Product_SKU__c"] ||
          this._selectedAsset?.Product2.Product_SKU__c;
  }

  connectedCallback() {
    loadStyle(this, FrontLineCSS);
    this.isMobile = FORM_FACTOR === "Small";

    this.buildAssetData();
  }

  buildAssetData() {
    if (this.isMobile) {
      this.isLoading = true;
    }
    logger.log(
      this.currentActiveTab,
      "===buildAssetData===",
      JSON.stringify(this._selectedAsset)
    );
    this.getRates();
  }

  getRates() {
    this.rates = this.ratesInfo?.data?.items?.map((item) => item.rates)[0];

    //Replace key labels
    if (this.rates) {
      const packages = [this.rates];
      const replacer = {
        minimum: "min.",
        daily: "day",
        weekly: "week",
        monthly: "month"
      };
      const transformObj = (obj) => {
        if (obj && Object.getPrototypeOf(obj) === Object.prototype) {
          return Object.fromEntries(
            Object.entries(obj).map(([k, v]) => [
              replacer[k] || k,
              transformObj(v)
            ])
          );
        }
        return obj;
      };
      this.rates = packages.map((o) => transformObj(o))[0];

      this.hasRatesLoaded = true;
    }
  }
  render() {
    if (this.isMobile) {
      return mobileTemplate;
    }
    return desktopTemplate;
  }

  renderedCallback() {
    console.log("inside method calling function", JSON.stringify(this.rates));
    this.template
      .querySelector("c-sbr_3_0_rates-cmp")
      .setRatesError(this.hasRatesLoaded);
    this.template
      .querySelector("c-sbr_3_0_rates-cmp")
      .createRatesMatrix(this.rates);
    this.template.querySelector("c-sbr_3_0_rates-cmp").initRatesMatrix();
    this.template.querySelector("c-sbr_3_0_rates-cmp").setItemQty();
  }
}