import { LightningElement, api } from "lwc";
import mobileTemplate from "./sbr_3_0_salesProductFilterCmpMobile.html";
import desktopTemplate from "./sbr_3_0_salesProductFilterCmpDesktop.html";
import Sbr_3_0_lineitemEditorCmp from "@salesforce/resourceUrl/Pros_NonCredit_Css";
import { loadStyle } from "lightning/platformResourceLoader";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_salesProductFilterCmp extends LightningElement {
  @api isMobile;
  @api callFilterCmp;
  @api locationOptions;
  _selectedLocationFilter;
  @api
  get selectedLocationFilter() {
    return this._selectedLocationFilter;
  }
  set selectedLocationFilter(value) {
    this._selectedLocationFilter = value;
  }
  @api preservedAvailableOnly;
  @api preservedStockVendorValue;
  @api preservedManufacturerValue;
  availableOnly = false;
  stockVendorValue = "";
  manufacturerValue = "";
  labels = LABELS;

  @api contractSalesTab; //FRONT-15255
  handleCancelFilter() {
    this.callFilterCmp = false;
    this.handleResetFilter();
    this.handleAppyFilter();
  }
  @api closeProductFilter() {
    //FRONT-15691
    if (this.callFilterCmp) {
      this.handleCancelFilter();
    }
  }

  render() {
    if (this.isMobile) {
      return mobileTemplate;
    } else {
      return desktopTemplate;
    }
  }

  connectedCallback() {
    loadStyle(this, Sbr_3_0_lineitemEditorCmp);
    this.availableOnly = this.preservedAvailableOnly;
    this.stockVendorValue = this.preservedStockVendorValue;
    this.manufacturerValue = this.preservedManufacturerValue;
  }

  handleAppyFilter() {
    const applyFilterEvent = new CustomEvent("applysalesfilters", {
      detail: {
        availableOnly: this.availableOnly,
        stockVendorValue: this.stockVendorValue,
        manufacturerValue: this.manufacturerValue,
        locationValue: this._selectedLocationFilter
      }
    });
    this.dispatchEvent(applyFilterEvent);
  }

  handleResetFilter() {
    this.availableOnly = false;
    this.stockVendorValue = "";
    this.manufacturerValue = "";
    //Added as part of FRONT-13956
    if (this.isMobile) {
      this._selectedLocationFilter = this.locationOptions[0]?.value;
    }
    //FRONT-13956 Ends
  }

  handleChange(event) {
    event.stopPropagation();
    let searchType = event.currentTarget.name;
    if (searchType === "quantity") {
      this.availableOnly = event.currentTarget.checked;
    } else if (searchType === "stockvendor") {
      this.stockVendorValue = event.currentTarget.value;
    } else {
      this.manufacturerValue = event.currentTarget.value;
    }
  }

  handleLocationChange(event) {
    this.locationOptions.forEach((item) => {
      //Modified as part of FRONT-13956
      if (item.value === event.detail.value) {
        this._selectedLocationFilter = item.value;
      }
    });
  }

  @api
  updateSelectedProductFilters(
    availableOnly,
    stockVendorValue,
    manufacturerValue
  ) {
    this.availableOnly = availableOnly;
    this.stockVendorValue = stockVendorValue;
    this.manufacturerValue = manufacturerValue;
  }
  //FRONT-15255
  get availableCheckboxLabel() {
    return this.contractSalesTab && this.isMobile
      ? "Available Only"
      : "Available";
  }
}