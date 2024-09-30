import { LightningElement, api, track, wire } from "lwc";
import Sbr_3_0_lineitemEditorCmp from "@salesforce/resourceUrl/Pros_NonCredit_Css";
import Sbr_3_0_customModalCmpDesktop_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmpDesktop_Css";
import { loadStyle } from "lightning/platformResourceLoader";
import mobileTemplate from "./sbr_3_0_LineItemEditWrapperMobile.html";
import desktopTemplate from "./sbr_3_0_LineItemEditWrapperDesktop.html";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import getChronosStatus from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";

import {
  getRecord,
  createRecord,
  deleteRecord,
  updateRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_LineItemEditWrapper extends NavigationMixin(
  LightningElement
) {
  @api isMobile;
  @api lineId;
  @api recordId;
  @api groupId;
  @api row; //FRONT-1950 - for sending the line item object.
  @api objectApiName;
  @api isLoading;
  selectedProducts = {};
  @api selectedRow = {};

  @api lineItemName;
  cancelLabel = "Cancel";
  saveLabel = "Confirm";
  activeTab = "Editor";
  listInfoRecordId;
  @api catClass = ["0010001"];
  //@api productCat = ["0070025"];
  @api productCat = [];
  locationInfo;
  @api activetabValue = "EditTab";
  @api rates = {};
  @api selectedRecord = [];
  isRateVal = false;
  isMiscItem = false; //FRONT-14360
  //started for FRONT-6266
  ratesParamObject = {
    products: [],
    customerNumber: ""
  };
  parentItemQty = 1;
  hasRatesLoaded = true;
  rates;
  _selectedProducts = [];
  sectionContentDivClass = "slds-section__content slds-p-top_none rateSection";
  sectionH3Class = "slds-section__title slds-has-dividers_bottom-space";
  sectionButtonClass =
    "tab-section slds-button slds-section__title-action slds-p-around_none";
  sectionIconClass = "slds-section__title-action-icon slds-button__icon_left";
  openSections = [];

  mobileProps = { zIndex: 9004 };

  //ended for FRONT-6266
  //started for Front-9206
  @api totalRequestedQuantity = 0;
  @api filledQuantity = 0;
  @api remainingQuantity = 0;
  @api isRental;
  //ended for Front-9206
  @api setTabValue(val) {
    this.activetabValue = val;
  }

  get activeTabVal() {
    return this.activetabValue;
  }

  //******************************************************************** */
  selectedClass = "slds-button slds-button_neutral active-state";
  unselectedClass = "slds-button slds-button_neutral selected-btn";
  editBtnClass = "slds-button slds-button_neutral active-state";
  rateMatrixBtnClass = "slds-button slds-button_neutral selected-btn";
  availabilityBtnClass = "slds-button slds-button_neutral selected-btn";
  //******************************************************************** */

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      loadStyle(this, Sbr_3_0_lineitemEditorCmp);
      setTimeout(() => {
        this.populateLineData(this.lineId, this.groupId, this.recordId);
      }, 100);
      this.productCat = [this.selectedRecord.CatClass];
    } else {
      loadStyle(this, Sbr_3_0_customModalCmpDesktop_Css);
    }
    getChronosStatus().then((result) => {
      this.locationInfo = result;
    });
  }

  @api callfromparent() {
    this.template.querySelector("c-sbr_3_0_rates-cmp").updateproperty();
  }

  //Started for FRONT-6267
  @wire(getProductRates, { prwrapper: "$ratesParamObject" })
  wiredProductRates({ error, data }) {
    let selProd = [];
    if (!this.isMobile) {
      this.selectedProducts = this.selectedRow;
    } else if (this.isMobile) {
      this.selectedProducts = this.selectedRecord;
    }

    if (data) {
      let parsedData = JSON.parse(data);
      if (parsedData.error) {
        this.error = parsedData.error.message;
        this.hasRatesLoaded = false;
        this.rates = this.ratesUnavailable;
        if (Object.keys(this.selectedProducts).length) {
          selProd = selProd.concat(this.selectedProducts);
          if (this.rates) {
            selProd[0].Min_Rate = this.rates.suggestedRates["min."];
            selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
            selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
            selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
          }
          this._selectedProducts = selProd; //SADAPUR
        }

        if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
          this.template
            .querySelector("c-sbr_3_0_rates-cmp")
            .setRatesError(this.hasRatesLoaded);
      } else {
        let ratesData = parsedData.data;

        this.rates = ratesData.items.map((item) => item.rates)[0];
        // Replace key labels
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

        if (Object.keys(this.selectedProducts).length) {
          try {
            if (this.rates) {
              selProd = selProd.concat(this.selectedProducts);
              selProd[0].Min_Rate = this.rates.suggestedRates["min."];
              selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
              selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
              selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
            }
            this._selectedProducts = selProd;
          } catch (error) {
            console.log("176 Error: " + error.message);
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
          this.template.querySelector("c-sbr_3_0_rates-cmp").initRatesMatrix();
        }
        this.showCustomerRatesAlert(ratesData);
      }
    } else if (error) {
      let selProd = [];

      this.hasRatesLoaded = false;
      this.rates = this.ratesUnavailable;

      if (this.selectedProducts.length === 1) {
        selProd = selProd.concat(this.selectedProducts);
        if (this.rates) {
          selProd[0].Min_Rate = this.rates.suggestedRates["min."];
          selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
          selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
          selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
        }
      }
      this._selectedProducts = selProd;
      if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
        this.template
          .querySelector("c-sbr_3_0_rates-cmp")
          .setRatesError(this.hasRatesLoaded);
    }
  }

  showCustomerRatesAlert(rates) {
    let rateFlag = rates.items[0].rateFlag;
    let notToExceed = rates.items[0].notToExceed;
    try {
      if (rateFlag == "Y") {
        switch (notToExceed) {
          case "S":
            this._selectedProducts[0].Specific_Pricing_Type__c = "Set Rates";
            this.customerPricingAlert =
              "Customer has Set Rates. Rates cannot be changed.";
            break;
          case "X":
            this._selectedProducts[0].Specific_Pricing_Type__c =
              "Do Not Exceed";
            this.customerPricingAlert =
              "Customer has Do Not Exceed Rates. Rates increases not allowed.";
            break;
          case "P":
            this._selectedProducts[0].Specific_Pricing_Type__c =
              "Percent Off Local Book";
            this.customerPricingAlert =
              "Customer has % off Local Book Rates. Rates increases not allowed.";
            break;
          case "":
            this._selectedProducts[0].Specific_Pricing_Type__c =
              "Customer Loaded";
            this.customerPricingAlert = "Customer has special rates.";
            break;
          default:
            this.customerPricingAlert = "Rates Updated";
            break;
        }
        this.hasCustomerPricing = true;
        this.showCustomerPricingAlert = true;
      }
    } catch (error) {
      console.log("showCustomerRatesAlert Error->" + error.message);
    }
  }
  //Ended for FRONT-6267

  render() {
    if (this.isMobile) {
      return mobileTemplate;
    } else {
      return desktopTemplate;
    }
  }

  @api populateLineData(lineId, groupId, recordId, row) {
    console.log("🚀 populateLineData Called!!");
    if (
      this.selectedRow.productType === "Misc-Charge" ||
      this.selectedRecord.productType === "Misc-Charge" ||
      this.selectedRow.productType === "MISC Charge Items" ||
      this.selectedRecord.productType === "MISC Charge Items"
    ) {
      //FRONT-14360 starts
      this.isMiscItem = true;
    } else {
      this.isMiscItem = false;
    } //FRONT-14360 ends
    this.lineId = lineId;
    this.groupId = groupId;
    this.recordId = recordId;
    this.row = row; //FRONT-1950
    this.template
      .querySelector("c-sbr_3_0_line-item-editor-cmp-frontline")
      .populateLineData(this.lineId, this.groupId, this.recordId, this.row);
  }

  tabChangeHandler(e) {
    let currentState = e.target.value;
    this.editBtnClass = this.unselectedClass;
    this.rateMatrixBtnClass = this.unselectedClass;
    this.availabilityBtnClass = this.unselectedClass;
    let productBranchObj = [
      {
        pc: this.locationInfo?.branch?.Branch_Location_Number__c,
        productId: this.selectedRecord.CatClass
      }
    ]; //FRONT-20785, FRONT-20654

    switch (currentState) {
      case "Editor":
        this.editBtnClass = this.selectedClass;
        this.activeTab = "Editor";
        this.saveLabel = "Confirm";
        break;
      case "Availability":
        //FRONT-1910, 1667
        setTimeout(() => {
          this.template
            .querySelector("c-sbr_3_0_line-item-edit-availability-component")
            .initializePropFromLineEditorWrapperCmp();
        }, 1000);
        this.rateMatrixBtnClass = this.selectedClass;
        this.activeTab = "Availability";
        this.saveLabel = "Back";
        this.productCat = [this.selectedRecord.CatClass];
        break;
      case "Rate Matrix":
        this.callfromparent();
        this.availabilityBtnClass = this.selectedClass;
        this.activeTab = "Rate Matrix";
        this.saveLabel = "Back"; //FRONT-6267
        this.ratesParamObject = {
          ...this.ratesParamObject,
          products: productBranchObj //FRONT-20785, FRONT-20654
        };

        break;
      default:
        break;
    }
  }
  get editorDisplay() {
    return this.activeTab == "Editor" ? "editor show" : "editor-hide";
  }
  get rateMatrixDisplay() {
    return this.activeTab == "Availability"
      ? "availability show"
      : "ratematrix-hide";
  }
  get availabilityDisplay() {
    return this.activeTab == "Rate Matrix"
      ? "ratematrix show"
      : "availability-hide";
  }
  get rateMatrixShow() {
    return this.activeTab == "RatesTab" && this.rates
      ? "ratematrix-show"
      : "availability-hide";
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
    this.callfromparent(); //6268
  }

  handleSubmit() {
    if (this.activeTab == "Editor" && this.isMobile == true) {
      this.isLoading = true;

      this.template
        .querySelector("c-sbr_3_0_line-item-editor-cmp-frontline")
        .saveData()
        .then((data) => {
          var updatedRecordId =
            this.objectApiName == "SBQQ__Quote__c" ? data.Id : data[0].Id;

          let timeoutDuration =
            this.objectApiName == "SBQQ__Quote__c" ? 500 : 15000;
          setTimeout(() => {
            notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
              .then((rec) => {
                this.listInfoRecordId = "";
                this.listInfoRecordId = this.recordId.valueOf();
                this.isLoading = false;
              })
              .catch((error) => {
                console.log("error:" + error);
                this.isLoading = false;
              });
          }, timeoutDuration);

          setTimeout(() => {
            notifyRecordUpdateAvailable([{ recordId: updatedRecordId }])
              .then((rec) => {
                this.listInfoRecordId = "";
                this.listInfoRecordId = this.recordId.valueOf();
              })
              .catch((error) => {
                console.log("error:" + error);
              });
          }, 15000);

          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Line Item updated.",
              variant: "success"
            })
          );
          this.isLoading = true;

          // Start FRONT-7383
          let updatedData = data;
          this.dispatchEvent(
            new CustomEvent("save", {
              detail: {
                data: updatedData
              }
            })
          );
          // END FRONT-7383
        })
        .catch((error) => {
          console.log("error: " + error);
          this.isLoading = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: "Error updating Line Item",
              variant: "error"
            })
          );
        });
      //FRONT-6268
    } else if (this.activeTab == "Availability" && this.isMobile == true) {
      this.rateMatrixBtnClass = this.unselectedClass;
      this.editBtnClass = this.selectedClass;
      this.activeTab = "Editor";
      this.saveLabel = "Confirm";
    } else if (this.activeTab == "Rate Matrix" && this.isMobile == true) {
      this.availabilityBtnClass = this.unselectedClass;
      this.editBtnClass = this.selectedClass;
      this.activeTab = "Editor";
      this.saveLabel = "Confirm";
      this.callfromparent();
    }
  }

  @api saveLineItem() {
    return this.template
      .querySelector("c-sbr_3_0_line-item-editor-cmp-frontline")
      .saveData();
  }

  handleActive(event) {
    this.hideAvailability();
    if (event.target.value == "RatesTab") {
      this.callfromparent();
      let productBranchObj = [
        {
          pc: this.locationInfo?.branch?.Branch_Location_Number__c,
          productId: this.selectedRow.CatClass
        }
      ]; //FRONT - 20785, FRONT - 20654
      this.ratesParamObject = {
        ...this.ratesParamObject,
        products: productBranchObj //FRONT-20785, FRONT-20654
      };
    } else if (event.target.value == "AvailabilityTab") {
      this.productCat = [this.selectedRow.CatClass];
      if (
        this.template.querySelector(
          "c-sbr_3_0_line-item-edit-availability-component"
        )
      ) {
        this.template
          .querySelector("c-sbr_3_0_line-item-edit-availability-component")
          .setDefaultBranch();
      }
      //FRONT-1668 and 1937
      setTimeout(() => {
        this.template
          .querySelector("c-sbr_3_0_line-item-edit-availability-component")
          .initializePropFromLineEditorWrapperCmp();
      }, 100);
    }
    this.activeTab = event.target.value;
    this.activetabValue = event.target.value;
    this.dispatchEvent(
      new CustomEvent("tabswitch", {
        detail: {
          tabName: event.target.value,
          lineId: this.lineId,
          groupId: this.groupId,
          recordId: this.recordId
        }
      })
    );
  }

  //Added as part of 8721 to hide availability component when another tab is clicked
  hideAvailability() {
    if (
      this.template.querySelector(
        "c-sbr_3_0_line-item-edit-availability-component"
      )
    ) {
      this.template
        .querySelector("c-sbr_3_0_line-item-edit-availability-component")
        .hideAvailability();
    }
  }
}