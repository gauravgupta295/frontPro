import { LightningElement, wire, api, track } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from "lightning/navigation";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import getAssetDetails from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getAssetDetails";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c";
import { publish, MessageContext } from "lightning/messageService";
import { createMessageContext } from "lightning/messageService";
import UserId from "@salesforce/user/Id";
import COMPANY_CODE_FIELD from "@salesforce/schema/User.CompanyName";
import { getRecord } from "lightning/uiRecordApi";
const userFields = [COMPANY_CODE_FIELD];
import getProfileBranchChronosDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
export default class Sbr_3_0_assetSpotlightCmp extends NavigationMixin(
  LightningElement
) {
  userId = UserId;
  @api selectedProducts = [];
  @api recordId;
  data;
  count = true;
  companyCode;
  @api objectApiName;
  @api passedCustomerNumber;
  @api locationInfo;
  @api selectedprodvalue;
  isParentAddToCart = true;
  messageContext = createMessageContext();
  showSpinner = false;
  @api originrecordid;
  /* FRONT - 1904 : Setting variant for loading view*/
  @api variant;
  /* END : FRONT - 1904*/
  isMobile;
  _selectedProducts = [];
  panelTitle = "Spotlight Panel"; //FRONT-13129
  panelType = "detailsPanel"; //FRONT-13129
  @api productId = "";
  bulkProductIds = [];
  selectedAssetOnMobile;
  productCatclass = [];
  //isDetailsPanel;
  detailsBtn = "rates-btn-brand slds-button slds-button_brand";
  ratesBtn = "rates-btn-neutral slds-button slds-button_neutral";
  isNotRecordPage = false;
  ratesUnavailable = {
    suggestedRates: { "min.": "N/A", day: "N/A", week: "N/A", month: "N/A" },
    bookRates: { "min.": "N/A", day: "N/A", week: "N/A", month: "N/A" }
  };

  selectedClass = "back-button slds-button slds-button_neutral active-state";
  unselectedClass = "back-button slds-button slds-button_neutral selected-btn";
  mobileProps = {
    zIndex: 9004,
    footerClasses: "slds-p-around_none"
  };
  ratesParamObject = {
    products: [],
    customerNumber: ""
  };

  @wire(getRecord, { recordId: UserId, fields: userFields })
  wiredUser({ error, data }) {
    if (data) {
      this.companyCode = data.fields.CompanyName.value;
    } else if (error) {
    }
  }

  showMobileDetails = true;

  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
    //this.isDetailsPanel = true;
    if (this.isMobile) {
      this.toggleSpotlightPanel(this.selectedProducts);
      //this.panelTitle = this.selectedprodvalue;
      this.itemSearchBackBtnClass = this.unselectedClass;
    }
    this.isNotRecordPage = !this.recordId && !this.objectApiName;
    //this.showDetails = true;
    logger.log('User Location Info' + JSON.stringify(this.locationInfo));
    if(!this.locationInfo)
    {
    getProfileBranchChronosDetails({
      recordId: this.recordId,
      objectAPIName: this.objectAPIName
    })
      .then((result) => {
        logger.log('User Location Info' + JSON.stringify(result));
        if (result.branch) this.locationInfo = result.branch;
        else this.locationInfo = result;
      })
      .catch((error) => {
        logger.log("Error in getProfileBranchChronosDetails", error.stack);
      });
    }
  }

  get isBulkAddPanel() {
    return this.panelType === "bulkAddPanel";
  }
  get isDetailsPanel() {
    return this.panelType === "detailsPanel";
  }

  /* ---- toggle ----*/
  toggleBtn(event) {
    event.preventDefault();
    event.stopPropagation();
    if (event.target.value === "details") {
      this.detailsBtn = "rates-btn-brand slds-button slds-button_brand";
      this.ratesBtn = "rates-btn-neutral slds-button slds-button_neutral";
      this.panelType = "detailsPanel";
      this.showMobileDetails = true;
    } else if (event.target.value === "rates") {
      this.detailsBtn = "rates-btn-neutral slds-button slds-button_neutral";
      this.ratesBtn = "rates-btn-brand slds-button slds-button_brand";
      this.showMobileDetails = false;
      if (this.passedCustomerNumber) {
        this.ratesParamObject = {
          ...this.ratesParamObject,
          customerNumber: this.passedCustomerNumber
        };
      }
      this.getRates();
      // this.panelType = "detailsPanel";
    }
  }

  /*------- Get Rates -----------*/
  async getRates() {
    this.showSpinner = true;
    await getProductRates({ prwrapper: this.ratesParamObject })
      .then((data) => {
        // this.productResults = { error, data };
        this.showSpinner = false;
        let selProd = [];
        let defaultRates = {
          Min_Rate: 0,
          Daily_Rate: 0,
          Weekly_Rate: 0,
          Monthly_Rate: 0
        };
        let parsedData = JSON.parse(data);
        if (parsedData.error) {
          this.error = parsedData.error.message;
          this.hasRatesLoaded = false;
          this.rates = this.ratesUnavailable;
          if (this.selectedProducts.length === 1) {
            selProd[0] = Object.assign(
              {},
              defaultRates,
              this.selectedProducts[0]
            ); //merge 2 arrays
            selProd[0].Min_Rate = this.rates.suggestedRates["min."];
            selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
            selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
            selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
            this._selectedProducts = selProd;
            this._selectedProducts.Id = this.selectedProducts[0].productId;
          }
          if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
            this.template
              .querySelector("c-sbr_3_0_rates-cmp")
              .setRatesError(this.hasRatesLoaded);
        } else {
          let ratesData = parsedData.data;
          this.rates = ratesData.items.map((item) => item.rates)[0];
          //Replace key labels
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
            //Base case, if not an Object literal return value as is
            return obj;
          };
          this.rates = packages.map((o) => transformObj(o))[0];
          if (this.isKit && this.isKitUnPackaged) {
            this.rates = this.ratesUnavailable;
          }
          if (this.selectedProducts.length === 1) {
            try {
              selProd[0] = Object.assign(
                {},
                defaultRates,
                this.selectedProducts[0]
              ); //merge 2 arrays
              selProd[0].Min_Rate = this.rates.suggestedRates["min."];
              selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
              selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
              selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
              this._selectedProducts = selProd; //SADAPUR
            } catch (error) {
              console.log("176 Errorx: " + error.message);
            }
          }
          this.hasRatesLoaded = true;
          if (this.template.querySelector("c-sbr_3_0_rates-cmp")) {
            this.template
              .querySelector("c-sbr_3_0_rates-cmp")
              .setRatesError(this.hasRatesLoaded);
            this.template
              .querySelector("c-sbr_3_0_rates-cmp")
              .createRatesMatrix(this.rates);
            this.template
              .querySelector("c-sbr_3_0_rates-cmp")
              .initRatesMatrix();
            this.template.querySelector("c-sbr_3_0_rates-cmp").setItemQty();
          }
          //this.showCustomerRatesAlert(ratesData);
        }
      })
      .catch((error) => {
        console.log("error-->" + JSON.stringify(error));
        this.showSpinner = false;
        this.hasRatesLoaded = false;
        this.rates = this.ratesUnavailable;
        if (this.selectedProducts.length === 1) {
          selProd[0] = Object.assign(
            {},
            defaultRates,
            this.selectedProducts[0]
          ); //merge 2 arrays
          selProd[0].Min_Rate = this.rates.suggestedRates["min."];
          selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
          selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
          selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
        }
        this._selectedProducts = selProd; //SADAPUR
        if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
          this.template
            .querySelector("c-sbr_3_0_rates-cmp")
            .setRatesError(this.hasRatesLoaded);
      });
  }

  @api
  toggleSpotlightPanel(selectedProds) {
    this.panelTitle = "Spotlight Panel";
    this.hasRatesLoaded = false;
    try {
      this.data = "";
      let selectedProductsCount = selectedProds.length;
      this._selectedProducts = selectedProds;
      if (selectedProductsCount === 1) {
        this.panelType = "detailsPanel";
        this.panelTitle = this._selectedProducts[0].Description
          ? this._selectedProducts[0].Description
          : "Spotlight Panel";
        this.productId = this._selectedProducts[0].id;
        this.productCatclass = this._selectedProducts[0].Product_SKU__c;
        if (!this.isMobile)
          this._selectedProducts[0].Id = this._selectedProducts[0].ProductId;
        else {
          this.selectedAssetOnMobile = Object.assign(
            {},
            this._selectedProducts[0]
          );
          let prodid = this._selectedProducts[0].ProductId;
          //this.selectedAssetOnMobile.Id = this._selectedProducts[0].ProductId;
          this.selectedAssetOnMobile = {
            ...this.selectedAssetOnMobile,
            Id: prodid
          };
        }

        let productBranchObj = [
        {
          pc: this.locationInfo?.Branch_Location_Number__c,
          productId: this.productCatclass
        }];
        this.ratesParamObject = {
          ...this.ratesParamObject,
          products: productBranchObj
        };
        console.log(
          "this.ratesParamObject-->" + JSON.stringify(this.ratesParamObject)
        );
        this.getSelectedAssetDetails();
      } else if (selectedProductsCount > 1) {
        this.panelType = "bulkAddPanel";
        this.panelTitle = "Multi Add";
        this.bulkProductIds = selectedProds.map((p) => p.id);
        this.productCatclass = selectedProds.map((p) => p.Product_SKU__c);
        let productBranchObj = [
          {
            pc: this.locationInfo?.Branch_Location_Number__c,
            productId: this.productCatclass
          }];
        this.ratesParamObject = {
          ...this.ratesParamObject,
          products: productBranchObj
        };
      } else {
        this.panelType = "detailsPanel";
        this.panelTitle = "Spotlight Panel";
      }
    } catch (e) {
      console.log("Err logs", JSON.stringify(e));
      this.showSpinner = false;
    }
  }

  handleActive(event) {
    if (event.target.value === "Rates" && !this.hasRatesLoaded) {
      if (this.passedCustomerNumber) {
        this.ratesParamObject = {
          ...this.ratesParamObject,
          customerNumber: this.passedCustomerNumber
        };
      }
      this.getRates();
    }
  }

  async getSelectedAssetDetails() {
    this.showSpinner = true;
    this.data = await getAssetDetails({ assetId: this.productId });
    this.showSpinner = false;
  }

  handleSelectedItem(event) {
    let selectedItem = event.detail;
    this.toggleSpotlightPanel(selectedItem);
  }

  backToItemSearch(event) {
    const backToItemSearchEvent = new CustomEvent("backitemsearchevent", {
      detail: "false"
    });
    this.dispatchEvent(backToItemSearchEvent);
  }
  removeSpotlighData(event) {
    //FRONT-11329
    event.preventDefault();
    event.stopPropagation();
    //this.template.querySelector('c-sbr_3_0_bulk-add-cmp').inventoryItems=[];
    publish(this.messageContext, deselectProductRowChannel, {
      productId: null,
      contextId: this.recordId
    });
    //var uncheckEvent = new CustomEvent('removeall');
    //this.dispatchEvent(uncheckEvent);
    this.panelTitle = "Spotlight Panel";
    this.panelType = "detailsPanel";
  }
}