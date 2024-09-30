import { LightningElement, api, track, wire } from "lwc";
import MOBILE_TEMPLATE from "./sbr_3_0_itemSearchSelectAssetContainerCmpMobile.html";
import DESKTOP_TEMPLATE from "./sbr_3_0_itemSearchSelectAssetContainerCmpDesktop.html";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import getProductRates from "@salesforce/apex/SBR_3_0_ConsumablesGetRatesController.getContractProductRates";
const logger = Logger.create(true);

export default class Sbr_3_0_itemSearchSelectAssetContainerCmp extends LightningElement {
  @api orderData;
  isMobile = false;
  _selectedAsset;
  _currentActiveTab;
  @api recordId;
  @api objectApiName;
  activeClass;
  ratesParamObject = {};
  @track rates;
  @api isConfirm; //Front-16656
  // started for Front-18999
  mobileProps = { zIndex: 9004 };
  activeTab = "Editor";
  editBtnClass = "slds-button slds-button_neutral active-state";
  rateMatrixBtnClass = "slds-button slds-button_neutral selected-btn";
  unselectedClass = "slds-button slds-button_neutral selected-btn";
  selectedClass = "slds-button slds-button_neutral active-state";
  // ended for Front-18999
  @api origin = ""; //Front-16656
  @api
  get selectedAsset() {
    return this._selectedAsset;
  }
  set selectedAsset(value) {
    this._selectedAsset = value;
    this.setRatesParams();
  }

  @api
  get currentActiveTab() {
    return this._currentActiveTab;
  }
  set currentActiveTab(value) {
    this._currentActiveTab = value;
  }

  render() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    return this.isMobile ? MOBILE_TEMPLATE : DESKTOP_TEMPLATE;
  }

  handleTabToggle(event) {
    logger.log("🚀 tabchangetoggle : " + event.detail);
  }

  @api getUpdatedOrderItem() {
    let orderItmData = this.refs.assetOrderItemEditorComp;
    return orderItmData.getAssetData();
  }
  //Started for Front-18999
  tabChangeHandler(e) {
    let currentState = e.target.value;
    this.editBtnClass = this.unselectedClass;
    this.rateMatrixBtnClass = this.unselectedClass;
    switch (currentState) {
      case "Editor":
        this.editBtnClass = this.selectedClass;
        this.activeTab = "Editor";
        //FRONT-24414
        const tabeventeditor = new CustomEvent("ratematrixclicked", {
          detail: { ratematrix: false },
          bubbles: true,
          composed: true
        });
        this.dispatchEvent(tabeventeditor);
        break;
      case "Rate Matrix":
        this.rateMatrixBtnClass = this.selectedClass;
        this.activeTab = "Rate Matrix";
        //FRONT-24414
        const tabevent = new CustomEvent("ratematrixclicked", {
          detail: { ratematrix: true },
          bubbles: true,
          composed: true
        });
        console.log("event called");
        this.dispatchEvent(tabevent);

        break;
      default:
        break;
    }
  }
  @api
  get editorDisplay() {
    console.log("called");
    this.activeClass =
      this.activeTab === "Editor" ? "editor show" : "editor-hide";
    return this.activeClass;
  }
  //FRONT-24414
  set editorDisplay(value) {
    this.activeTab = "Editor";
    this.rateMatrixBtnClass = this.unselectedClass;
    this.editBtnClass = this.selectedClass;
    this.activeClass = "editor show";
  }
  get rateMatrixDisplay() {
    return this.activeTab === "Rate Matrix"
      ? "ratematrix show"
      : "ratematrix-hide";
  }

  setRatesParams() {
    this.ratesParamObject = {
      customerNumber:
        this.orderData?.fields?.Account?.value?.fields?.RM_Account_Number__c
          ?.value,
      products:
        this._currentActiveTab === "Cat Class Description"
          ? [this.selectedAsset?.["Product2.Product_SKU__c"]]
          : [this.selectedAsset?.Product2?.Product_SKU__c]
    };
    logger.log("---- selected Assets--- " + JSON.stringify(this.selectedAsset));
    if (this.selectedAsset) this.getRate();
  }

  @api
  handleBack() {
    this.editorDisplay = "editor show";
  }

  //Ended for Front-18999
  // @wire(getProductRates, { prwrapper: "$ratesParamObject" })
  // wiredProductRates({ error, data }) {
  //   if (data) {
  //     this.rates = JSON.parse(data);
  //     logger.log("Rates Data-->" + JSON.stringify(this.rates));
  //   } else if (error) {
  //     logger.log("error-->" + JSON.stringify(error));
  //   }
  // }
  hasRatesLoaded = false;

  async getRate() {
    this.hasRatesLoaded = false; //Front-16656
    await getProductRates({ prwrapper: this.ratesParamObject })
      .then((data) => {
        this.rates = JSON.parse(data);
        if (this.rates) {
          this.hasRatesLoaded = true;
        } else {
          this.hasRatesLoaded = false;
        }
        logger.log("Rates Data-->" + JSON.stringify(this.rates));
      })
      .catch((error) => {
        this.hasRatesLoaded = true;
        console.log("### rates Error" + JSON.stringify(error));
      });
  }
}