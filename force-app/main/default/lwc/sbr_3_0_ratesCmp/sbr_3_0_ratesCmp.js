import { LightningElement, api, track, wire } from "lwc";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import { refreshApex } from "@salesforce/apex";
import { appName, FL_APP_NAME, SAL_APP_NAME } from "c/sbr_3_0_frontlineUtils";

import FL_TEMPLATE from "./FL/defaultFL.html";
import SAL_TEMPLATE from "./SAL/defaultSAL.html";
export default class Sbr_3_0_ratesCmp extends LightningElement {
  @api rates;
  @api itemQty;
  @api isMobile; //front-6268
  @api activeTab = ""; //front-6268
  d = JSON.stringify(this.rates);
  suggBtnClass;
  targetBtnClass;
  floorBtnClass;
  selectedClass = "rates-btn-brand slds-button slds-button_brand";
  unselectedClass = "rates-btn-neutral slds-button slds-button_neutral";
  selectedVariantLabel = "Suggested";
  suggestedVariantRows = [];
  targetVariantRows = [];
  floorVariantRows = [];
  /* Variables for checking the Rates data */
  isDataAvailable = true;
  isDataUnavailable = false;
  refreshDataAvailable = false;
  wiredRatesResult;
  isMobile = false;
  ratesParamObject = {
    products: [],
    customerNumber: ""
  };
  @track selectedVariantRows = [];
  @track tableColumns = [
    { label: "", fieldName: "label", hasSeparator: false },
    {
      label: this.selectedVariantLabel,
      fieldName: "variantRate",
      hasSeparator: true,
      style: "isBold"
    },
    { label: "Book", fieldName: "bookRate", hasSeparator: false }
  ];

  @api hideSectionTitle = false;
  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.initRatesMatrix();
    this.setAppName();
  }
  /* Set the appropriate data available variables depending on if the data loads in the Spotlight Panel */
  @api setRatesError(hasRatesLoaded) {
    this.isDataAvailable = hasRatesLoaded;
    this.isDataUnavailable = !hasRatesLoaded;
  }
  @api setItemQty() {
    console.log("setItemQty");
    this.itemQty = 1;
  }
  @api initRatesMatrix() {
    this.suggBtnClass = this.selectedClass;
    this.targetBtnClass = this.unselectedClass;
    this.floorBtnClass = this.unselectedClass;
    this.selectedVariantRows = this.suggestedVariantRows;
  }
  @api updateproperty() {
    this.selectedVariantLabel = "Suggested";
    this.tableColumns[1].label = this.selectedVariantLabel;
  }
  @api createRatesMatrix(rates) {
    this.rates = rates;
    let suggestedRatesKeys = Object.keys(this.rates.suggestedRates);
    let bookRatesKeys = Object.keys(this.rates.bookRates);
    let isTargetAvailable =
      this.rates.segmentedRates && this.rates.segmentedRates.target
        ? true
        : false;
    let isFloorAvailable =
      this.rates.segmentedRates && this.rates.segmentedRates.floor
        ? true
        : false;
    let targetRatesKeys = isTargetAvailable
      ? Object.keys(this.rates.segmentedRates.target)
      : [];
    let floorRatesKeys = isFloorAvailable
      ? Object.keys(this.rates.segmentedRates.floor)
      : [];
    let skeyList =
      suggestedRatesKeys.length > bookRatesKeys.length
        ? suggestedRatesKeys
        : bookRatesKeys;
    let tkeyList =
      targetRatesKeys.length > bookRatesKeys.length
        ? targetRatesKeys
        : bookRatesKeys;
    let fkeyList =
      floorRatesKeys.length > bookRatesKeys.length
        ? floorRatesKeys
        : bookRatesKeys;
    this.suggestedVariantRows = skeyList.map((key) => {
      return {
        id: key,
        label: this.changeKey(key),
        variantRate: this.formatNumber(this.rates.suggestedRates[key]),
        bookRate: this.formatNumber(this.rates.bookRates[key])
      };
    });
    this.targetVariantRows = tkeyList.map((key) => {
      return {
        id: key,
        label: this.changeKey(key),
        variantRate:
          isTargetAvailable && this.rates.segmentedRates.target[key]
            ? this.rates.segmentedRates.target[key]
            : "N/A",
        bookRate: this.formatNumber(this.rates.bookRates[key])
      };
    });
    this.floorVariantRows = fkeyList.map((key) => {
      return {
        id: key,
        label: this.changeKey(key),
        variantRate:
          isFloorAvailable && this.rates.segmentedRates.floor[key]
            ? this.rates.segmentedRates.floor[key]
            : "N/A",
        bookRate: this.formatNumber(this.rates.bookRates[key])
      };
    });
  }
  changeKey(key) {
    return key === "month" ? "month" : key;
  }
  formatNumber(num) {
    const formattingOptions = {
      style: "decimal", // or "currency" for currency formatting
      currency: "USD", // If using currency formatting
      maximumFractionDigits: 2,
      minimumFractionDigits: 2
    };
    return new Intl.NumberFormat("en-US", formattingOptions).format(
      Number(num)
    );
  }
  toggleSection(event) {
    console.log("inside toggleSection  ");
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    console.log("currentsection " + currentsection);
    console.log("buttonid " + buttonid);
    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className = "slds-section slds-is-open";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }
  }
  // User shall see rates and prices formatted with commas when > 3 digits ($X,XXX.XX)
  // SAL-26334
  toggleRates(e) {
    e.preventDefault();
    e.stopPropagation();
    let currentRates = e.target.value;
    this.suggBtnClass = this.unselectedClass;
    this.targetBtnClass = this.unselectedClass;
    this.floorBtnClass = this.unselectedClass;
    switch (currentRates) {
      case "Suggested":
        this.suggBtnClass = this.selectedClass;
        this.selectedVariantLabel = "Suggested";
        this.selectedVariantRows = this.suggestedVariantRows;
        break;
      case "Target":
        this.targetBtnClass = this.selectedClass;
        this.selectedVariantLabel = "Target";
        this.selectedVariantRows = this.targetVariantRows;
        break;
      case "Floor":
        this.floorBtnClass = this.selectedClass;
        this.selectedVariantLabel = "Floor";
        this.selectedVariantRows = this.floorVariantRows;
        break;
      default:
        break;
    }
    this.tableColumns[1].label = this.selectedVariantLabel;
  }
  /* Method to reload the data when you click the Refresh button on the Rates error component. */
  @wire(getProductRates, { prwrapper: "$ratesParamObject" })
  imperativeRefresh(result) {
    const { data, error } = result;
    this.wiredRatesResult = result;
    if (data) {
      this.refreshDataAvailable = true;
    } else {
      this.refreshDataAvailable = false;
    }
  }
  /* Method for clicking the Refresh button on the Rates error component. */
  handleRefresh() {
    if (this.refreshDataAvailable) {
      this.isDataAvailable = true;
      this.isDataUnavailable = false;
      return refreshApex(this.imperativeRefresh);
    } else {
      this.isDataAvailable = false;
      this.isDataUnavailable = true;
      return;
    }
  }
  /* Display the error illustration if the data is not available. */
  get illustrationDisplayClass() {
    return this.isDataUnavailable
      ? "illustration-error show"
      : "illustration-error";
  }
  /* Display data if it is available. */
  get ratesDisplayClass() {
    return this.isDataAvailable ? "rates-grid show" : "rates-grid";
  }

  get sectionClass() {
    //started for FRONT-6268
    if (this.activeTab == "Rate Matrix" && this.isMobile) {
      return "slds-section slds-is-open";
    }
    //ended for FRONT-6268
    return this.isMobile ? "" : "slds-section slds-is-open";
  }

  get showSectionTitle() {
    return (
      (this.appName === FL_APP_NAME &&
        !this.isMobile &&
        !this.hideSectionTitle) ||
      this.appName !== FL_APP_NAME
    ); //FRONT-25234
  }

  async setAppName() {
    this.appName = await appName;
  }

  render() {
    return this.appName === FL_APP_NAME ? FL_TEMPLATE : SAL_TEMPLATE;
  }
}