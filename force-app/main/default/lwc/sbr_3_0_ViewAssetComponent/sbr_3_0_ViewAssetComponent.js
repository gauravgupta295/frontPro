import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import DESKTOPTEMPLATE from "./sbr_3_0_ViewAssetComponentDesktop.html";
import MOBILE_TEMPLATE from "./sbr_3_0_ViewAssetComponentMobile.html";
import FORM_FACTOR from "@salesforce/client/formFactor";
import NAME_FIELD from "@salesforce/schema/Asset.Name";
import ASSET_ID_FIELD from "@salesforce/schema/Asset.SM_PS_Asset_Id__c";
import PRODUCT_NAME_FIELD from "@salesforce/schema/Asset.Product2.Name";
import MARKET_NAME_FIELD from "@salesforce/schema/Asset.SM_PS_Market_Name__c";
import MAKE_FIELD from "@salesforce/schema/Asset.SM_PS_Make__c";
import MODEL_FIELD from "@salesforce/schema/Asset.SM_PS_Model__c";
import SERIAL_NUMBER_FIELD from "@salesforce/schema/Asset.SM_PS_Serial_Number__c";
import MODEL_YEAR_FIELD from "@salesforce/schema/Asset.SM_PS_Model_Year__c";
import YEARS_TO_HOURS_FIELD from "@salesforce/schema/Asset.SM_PS_Year_to_Hours_Rent__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Asset.Description";
import QUANTITY_FIELD from "@salesforce/schema/Asset.Quantity";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
const logger = Logger.create(true);
const FIELDS = [
  NAME_FIELD,
  MARKET_NAME_FIELD,
  MAKE_FIELD,
  MODEL_FIELD,
  SERIAL_NUMBER_FIELD,
  MODEL_YEAR_FIELD,
  YEARS_TO_HOURS_FIELD,
  DESCRIPTION_FIELD,
  QUANTITY_FIELD,
  PRODUCT_NAME_FIELD,
  ASSET_ID_FIELD
];
const SMALL_FORM_FACTOR = "Small";
export default class Sbr_3_0_ViewAssetComponent extends LightningElement {
  @api assetId;
  @api orderItem;

  itemSize;
  isLoading = false;
  asset;
  _isRendered = false;

  activeSections = ["details", "description"];
  computeScrollableClass = "slds-modal__content";
  previousPortHeight;

  @wire(getRecord, {
    recordId: "$assetId",
    fields: FIELDS
  })
  wiredAsset({ error, data }) {
    if (data) {
      this.buildAsset(data);
    } else if (error) {
      logger.error(error);
      this.isLoading = false;
    }
  }

  closeModal() {
    const goBackEvent = new CustomEvent("returnpage", {});
    this.dispatchEvent(goBackEvent);
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

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  buildAsset(data) {
    this.isLoading = true;
    let _asset = {};
    for (let field of FIELDS) {
      let fieldApiName = field.fieldApiName;
      let fieldValue = getFieldValue(data, field);
      if (field.fieldApiName.includes(".")) {
        let fieldApiNameSplit = fieldApiName.split(".");
        let relatedObj = {};
        relatedObj[fieldApiNameSplit[1]] = fieldValue;
        _asset[fieldApiNameSplit[0]] = relatedObj;
      } else {
        _asset[fieldApiName] = fieldValue;
      }
    }
    this.asset = _asset;
    this.isLoading = false;
    logger.log(JSON.stringify(this.asset));
  }

  handleSectionToggle() {}

  get header() {
    this.previousPortHeight = window.innerHeight;
    let header = "Asset";
    if (this.asset) {
      header = `${header} #${this.asset.SM_PS_Asset_Id__c}`;
      // this.computeScrollableClass = (!this.asset.Description || this.asset.Description === undefined) ? "slds-modal__content" : "slds-modal__content modalContentClass";
      this.computeScrollableClass = (!this.asset.Description || this.asset.Description === undefined) ? "slds-modal__content" : "slds-modal__content modalContentClass";
      
    }
    return header;
  }

  renderedCallback() {
    if (!this._isRendered) {
      this._isRendered = true;
      loadStyle(this, FrontLineCSS);
    }
  }

  handleGoBack(event) {
    event.stopPropagation();
    this.dispatchEvent(new CustomEvent("returnpage"));
  }
}