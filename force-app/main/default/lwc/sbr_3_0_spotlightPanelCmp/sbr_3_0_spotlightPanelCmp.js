import { LightningElement, api, wire, track } from "lwc";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import getProductKitComponents from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents";
import getProductDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductDetails";
import getATPForBranch from "@salesforce/apex/SBR_3_0_AvailabilityBadgeCmpController.getATP";
// import getProductAvailabilities from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductAvailabilities';
import getChronosStatus from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import { getRecord } from "lightning/uiRecordApi";
import UserId from "@salesforce/user/Id";
import COMPANY_CODE_FIELD from "@salesforce/schema/User.CompanyName";
import FORM_FACTOR from "@salesforce/client/formFactor";
import deselectProductRowChannel from "@salesforce/messageChannel/deselectProductRowChannel__c"; /*----- End- FRONT-15734 ---- */
import findRatesForProductbyAvailabilityLocation from "@salesforce/apex/SBR_3_0_RatesController.findRatesForProductbyAvailabilityLocation";
import findRatesForProducts from "@salesforce/apex/SBR_3_0_RatesController.findRatesForProducts";
const userFields = [COMPANY_CODE_FIELD];
import { RefreshEvent } from "lightning/refresh";

import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";
import filterProductListChannel from "@salesforce/messageChannel/filterProductListChannel__c";
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_spotlightPanelCmp extends NavigationMixin(
  LightningElement
) {
  @api selectedProducts = [];
  @api isMobile = false;
  @api spotlightHeight = "410";
  @api rows = [];
  @api recordId;
  @api objectApiName;
  @api isCustomerAdded;
  @api previousCustomer;
  @api syncCartInfo;
  @api passedCustomerNumber;
  atpSelected;
  atpLabel;
  badges = { badge1: false, badge2: false, badge3: false, badge4: false };
  branchNumberSelected;
  itemType;
  userId = UserId;
  companyCode;
  parentItemQty = 1;
  @track _selectedProducts = [];
  selectedCustomerNumber = "";
  selectedCustomerName = "";
  customerPricingAlert;
  showCustomerPricingAlert = false;
  hasCustomerPricing = false;
  isSelectedState = false;
  panelTitle = "Spotlight Panel";
  panelType = "inactivePanel";
  productId = "";
  bulkProductIds = [];
  productCatclass = [];
  spotlightContext;
  rates;
  ratesUnavailable = {
    suggestedRates: { "min.": "N/A", day: "N/A", week: "N/A", month: "N/A" },
    bookRates: { "min.": "N/A", day: "N/A", week: "N/A", month: "N/A" }
  };
  hasRatesLoaded = false;
  hasAvailabilityLoaded = true;
  availabilities;
  addOns;
  error = "";
  chronosEnabled = false;
  branchNumber;
  branchId = "Branch: ";
  companyId;
  branchName;
  branchPhone = "";
  locationInfo;
  openSections = [];
  isParentAddToCart = true;
  isProductKit = "No";
  isKitUnPackaged = true;

  itemSearchBackBtnClass =
    "back-button slds-button slds-button_neutral active-state";
  selectedClass = "back-button slds-button slds-button_neutral active-state";
  unselectedClass = "back-button slds-button slds-button_neutral selected-btn";
  sectionButtonClass =
    "tab-section slds-button slds-section__title-action slds-p-around_none";
  sectionH3Class = "slds-section__title slds-has-dividers_bottom-space";
  sectionContentDivClass = "slds-section__content slds-p-top_none";
  sectionIconClass = "slds-section__title-action-icon slds-button__icon_left";
  alertClass = "slds-notify slds-notify_alert align-left";

  isNotRecordPage = false;
  branchDisplayFromChild;
  profileBranch;

  @api viewState;

  isAddCustomerSelected = false;
  @wire(MessageContext)
  messageContext;

  productResults;

  @track kitComponents = [];
  @track productDescription = "";

  @track showSpinner = false;
  @track transactionType = "SBR";
  @track productRateMap = new Map();

  ratesParamObject = {
    products: [],
    customerNumber: ""
  };

  selectedProductMap = {};
  finalProductMap = {};
  productsPendingRatesQueue = [];

  _bulkProductData = [];
  productCount;
  isShowBranchWarning = false;

  @api showBranchWarningAlert(showMessage) {
    if (this.chronosEnabled) {
      this.isShowBranchWarning = showMessage;
    } else {
      this.isShowBranchWarning = false;
    }
  }
  get bulkProductData() {
    return this._bulkProductData;
  }

  set bulkProductData(value) {
    this._bulkProductData = value;
  }
  clearAlert() {
    this.isShowBranchWarning = false;
  }
  @api updateCustomerInfo(selectedCustomer) {
    //check if customer is same
    if (
      this.selectedCustomerNumber !== "" &&
      this.selectedCustomerNumber === selectedCustomer?.RM_Account_Number__c
    ) {
      return;
    }
    if (selectedCustomer) {
      this.selectedCustomerNumber = selectedCustomer.RM_Account_Number__c
        ? selectedCustomer.RM_Account_Number__c
        : "";
      this.selectedCustomerName = selectedCustomer.Name;
    } else {
      console.log("updateCustomerInfo  else");
      this.selectedCustomerNumber = "";
      this.selectedCustomerName = "";
    }
    this.ratesParamObject = {
      ...this.ratesParamObject,
      customerNumber: this.selectedCustomerNumber
    };
    if (this.productCount === 1) {
      this.getRates();
    } else if (this.productCount > 1) {
      if (this.chronosEnabled) {
        this.processATPRates(true);
      } else {
        this.processRates(true);
      }
    }
  }

  @wire(getRecord, { recordId: UserId, fields: userFields })
  wiredUser({ error, data }) {
    if (data) {
      this.companyCode = data.fields.CompanyName.value;
    } else if (error) {
      console.log("Spotlight wiredUser error:", error);
    }
  }

  get parentBranch() {
    if (this.chronosEnabled && this.branchDisplayFromChild) {
      return this.branchDisplayFromChild;
    } else {
      return this.branchNumber;
    }
  }
  get productRateList() {
    let productIds = [];
    Object.values(this.selectedProducts).forEach((val) => {
      productIds.push(this.productRateMap.get(val.Product_SKU__c));
    });
    console.log("###PRODUCTIDS" + productIds);
    return productIds;
  }
  getRates() {
    console.log("###inside rates");
    console.log("###Rates Request " + JSON.stringify(this.ratesParamObject));
    /* Sales Retrofit Change, if its not working in FT2, please uncomment this and comment the next line
    this.ratesParamObject.products[0].pc = this.branchNumber;
    */
    let selProd = [];
    let defaultRates =
      '{"Min_Rate":0,"Daily_Rate":0,"Weekly_Rate":0,"Monthly_Rate":0}';
    this.hasRatesLoaded = false;
    getProductRates({ prwrapper: this.ratesParamObject })
      .then((data) => {
        let cartSelectedProducts = this.selectedProducts.reduce((map, item) => {
          map[item.Product_SKU__c] = item;
          return map;
        }, {});
        let newCartArray = Object.entries(cartSelectedProducts);
        let mapCartProducts = new Map(newCartArray);
        console.log("###data" + JSON.stringify(data));
        if (data) {
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
              // as rates failing for managed kits, SF-7546, we are assigning ATP branch for kits products
              if (
                this.ratesParamObject &&
                this.ratesParamObject.products.length > 0
              ) {
                selProd[0].Rate_Branch = this.ratesParamObject.products[0].pc;
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
            let ratesMap = ratesData.items.reduce((map, item) => {
              map[item.productId] = item;
              return map;
            }, {});
            //     const rateNew = new Map(Object.entries(ratesMap));
            let newArray = Object.entries(ratesMap);
            console.log("##type" + newArray);
            let mapRates = new Map(newArray);
            console.log("##newMap" + mapRates);
            console.log("###newrates" + typeof mapRates);
            console.log("###new" + JSON.stringify(ratesMap));

            console.log(
              "### selectedProductMap" + JSON.stringify(cartSelectedProducts)
            );

            mapRates.forEach((productRates, productId) => {
              console.log("##1 inside for each");
              let productObj = Object.assign(
                {},
                defaultRates,
                mapCartProducts.get(productId)
              );
              productObj.Min_Rate = productRates.rates.suggestedRates.minimum;
              productObj.Daily_Rate = productRates.rates.suggestedRates.daily;
              productObj.Weekly_Rate = productRates.rates.suggestedRates.weekly;
              productObj.Monthly_Rate =
                productRates.rates.suggestedRates.monthly;
              productObj.Rate_Branch = productRates.pc;
              selProd.push(productObj);
              this.productRateMap.set(productId, productObj);
            });
            this._selectedProducts = selProd;
            console.log("IDSFORWARD" + JSON.stringify(this.productRateList));
            //let mergedArray = this.productRateMap;
            //  this.productRateMap = mergedArray.concat(selProd);
            console.log(
              "### selectedProd" + [...this.productRateMap.entries()]
            );

            if (this.isKit && this.isKitUnPackaged) {
              this.rates = this.ratesUnavailable;
            }
            if (
              this._selectedProducts.filter(
                (product) => product?.Rate_Branch == null
              ).length === 0
            ) {
              this.hasRatesLoaded = true;
            }
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
            this.showCustomerRatesAlert(ratesData);
          }
        } else if (error) {
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
            // as rates failing for managed kits, SF-7546, we are assigning ATP branch for kits products
            if (
              this.ratesParamObject &&
              this.ratesParamObject.products.length > 0
            ) {
              selProd[0].Rate_Branch = this.ratesParamObject.products[0].pc;
            }
          }
          this._selectedProducts = selProd; //SADAPUR
          if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
            this.template
              .querySelector("c-sbr_3_0_rates-cmp")
              .setRatesError(this.hasRatesLoaded);
        }
        this.showSpinner = false;
      })
      .catch((error) => {
        console.log("### rates Error" + JSON.stringify(error));
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
          // as rates failing for managed kits, SF-7546, we are assigning ATP branch for kits products
          if (
            this.ratesParamObject &&
            this.ratesParamObject.products.length > 0
          ) {
            selProd[0].Rate_Branch = this.ratesParamObject.products[0].pc;
          }
        }
        this._selectedProducts = selProd; //SADAPUR
        if (this.template.querySelector("c-sbr_3_0_rates-cmp"))
          this.template
            .querySelector("c-sbr_3_0_rates-cmp")
            .setRatesError(this.hasRatesLoaded);

        this.showSpinner = false;
      });
  }

  connectedCallback() {
    //this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }

    if (this.isMobile) {
      this.itemSearchBackBtnClass = this.unselectedClass;
    }

    this.isNotRecordPage = !this.recordId && !this.objectApiName;

    getChronosStatus({
      objectId: this.recordId,
      objectApiName: this.objectApiName
    }).then((result) => {
      this.chronosEnabled = result?.isChronosEnabled;
      this.branchNumber = result?.branch?.Branch_Location_Number__c;
      this.branchId = "Branch: ".concat(
        result?.branch?.Branch_Location_Number__c
      );
      this.companyId = result?.branch?.Company_ID__c;
      this.branchPhone = result?.branch?.Phone__c;
      this.locationInfo = result?.branch;
      this.profileBranch = result?.profileBranch?.Branch_Location_Number__c;
    });

    // refreshApex(this.productResults);
  }

  @api
  toggleSpotlightPanel(selectedProds) {
    console.log("\n hasProductsLoaded = " + this.hasProductsLoaded);
    this.hasRatesLoaded = false;
    let selectedProductsCount = selectedProds.length;
    this.productCount = selectedProds.length;
    console.log("###Prod JSON" + JSON.stringify(selectedProds));
    this.hideCustomerPricingAlert();

    if (selectedProductsCount > 0) {
      this.selectedProductMap = {}; // clear after every selection
      selectedProds.forEach((item) => {
        const productSku = item["Product_SKU__c"];

        if (!this.selectedProductMap[productSku]) {
          this.selectedProductMap[productSku] = item; // Directly assigning the item
        }
      });
      // remove unselected products from finalProductMap
      const tempProductMap = {};
      for (let key of Object.keys(this.finalProductMap)) {
        if (this.selectedProductMap.hasOwnProperty(key)) {
          tempProductMap[key] = this.finalProductMap[key];
        }
      }
      this.finalProductMap = tempProductMap;
      //add new products to finalProductMap
      for (let key of Object.keys(this.selectedProductMap)) {
        if (!this.finalProductMap.hasOwnProperty(key)) {
          this.finalProductMap[key] = this.convertToBulk(
            this.selectedProductMap[key]
          );
        }
      }
      this.bulkProductData = Object.values(this.finalProductMap);
    }

    if (selectedProductsCount === 0) {
      this.isSelectedState = false;
      this.panelType = "inactivePanel";
      this.panelTitle = "Spotlight Panel";
      this.productCatclass = [];
      this.ratesParamObject = {
        ...this.ratesParamObject,
        products: this.productCatclass
      };
    } else if (selectedProductsCount === 1) {
      this.isSelectedState = true;
      this.atpSelected = selectedProds[0].AtpSelected;
      this.atpLabel = selectedProds[0].AtpLabel;
      this.itemType = selectedProds[0].ItemType;
      if (selectedProds[0].LocationInfo) {
        this.badges = {
          // SAL-25827 __ SAL-26130
          badge1: selectedProds[0].LocationInfo.badge1
            ? selectedProds[0].LocationInfo.badge1
            : false,
          badge2: selectedProds[0].LocationInfo.badge2
            ? selectedProds[0].LocationInfo.badge2
            : false,
          badge3: selectedProds[0].LocationInfo.badge3
            ? selectedProds[0].LocationInfo.badge3
            : false,
          badge4: selectedProds[0].LocationInfo.badge4
            ? selectedProds[0].LocationInfo.badge4
            : false
        };
      }
      this.branchNumberSelected = selectedProds[0].BranchNumberSelected;
      this.panelType = "detailsPanel";
      this.panelTitle = selectedProds[0].Name
        ? selectedProds[0].Name
        : "Spotlight Panel";
      this.productId = selectedProds[0].Id ? selectedProds[0].Id : "";
      this.productCatclass = [selectedProds[0].Product_SKU__c];
      
      /* Sales Retrofit Change, if its not working in FT2, please uncomment this and comment the next line
      let productBranchObj = {
        pc: this.branchNumberSelected,
        productId: this.productCatclass,
      };
      this.ratesParamObject = {
        ...this.ratesParamObject,
        products: productBranchObj,
      };*/

      this.ratesParamObject = {
        ...this.ratesParamObject,
        products: this.productCatclass
      };

      //this.selectedProducts = this.selectedProducts.concat(selectedProds);//SF-7987
      this.selectedProducts = selectedProds; //SF-7987
      if (
        this._selectedProducts != undefined &&
        this._selectedProducts.length == 0
      ) {
        this._selectedProducts = this.selectedProducts;
      } else {
        this._selectedProducts = selectedProds;
      }

      this.isProductKit = selectedProds[0].Is_Kit__c;
      this.isKitUnPackaged = selectedProds[0].Salesforce_Managed_Kit__c; // SF-5287 (old condition : selectedProds[0].Changeable__c)
      // setting to resolve ATP issue - SAL-24259
      if (!this.isProductKit) {
        this.isProductKit = false;
      }
      if (!this.isKitUnPackaged) {
        this.isKitUnPackaged = false;
      }

      if (!this.isMobile) {
        try {
          if (this.isDetailsPanel && !this.isKit) {
            //SADAPUR

            let tabSet = this.template.querySelector("lightning-tabset");
            if (tabSet != undefined && tabSet != null) {
              tabSet.activeTabValue = "AvailabilityRates";
            }

            let availabilityCmp = this.template.querySelector(
              "c-sbr_3_0_availability-cmp"
            );
            if (availabilityCmp != undefined && availabilityCmp != null) {
              availabilityCmp.updateAvailabilityData(this.productCatclass);

              availabilityCmp.updateSelectedATPData(this.atpSelected);
              availabilityCmp.updateSelectedATPLabelData(this.atpLabel);
              availabilityCmp.updateSelectedBranchData(
                this.branchNumberSelected
              );
              if (this.badges) {
                availabilityCmp.updateLocationData(this.badges);
              }
            }
          }
          // SAL-27182
          if (this.isKit) {
            let productBranchObj = [
              {
                pc: this.branchNumber,
                productId: this.selectedProducts[0].Product_SKU__c
              }
            ];
            this.ratesParamObject = {
              ...this.ratesParamObject,
              products: productBranchObj
            };
            this.getRates();
          }
        } catch (error) {
          console.log("Error 295: " + JSON.stringify(error));
          console.log("Error 295 Message: " + error.message);
          console.log("Error 295 stack: " + error.stack);
        }
      } else {
        // if(!this.productCatclass) {
        //     this.template.querySelector('c-sbr_3_0_availability-cmp').updateAvailabilityData(this.productCatclass);
        // }
        // SF-8154 start
        if (this.isKit) {
          let productBranchObj = [
            {
              pc: this.branchNumber,
              productId: this.selectedProducts[0].Product_SKU__c
            }
          ];
          this.ratesParamObject = {
            ...this.ratesParamObject,
            products: productBranchObj
          };
          this.getRates();
        }
        // SF-8154 end

        let availabilityCmp = this.template.querySelector(
          "c-sbr_3_0_availability-cmp"
        );
        if (availabilityCmp != undefined && availabilityCmp != null) {
          availabilityCmp.updateAvailabilityData(this.productCatclass);
        }
        this.template
          .querySelector("c-sbr_3_0_availability-badge-cmp")
          .updateSelectedATPData(this.atpSelected);
        this.template
          .querySelector("c-sbr_3_0_availability-badge-cmp")
          .updateSelectedATPLabelData(this.atpLabel);
        this.template
          .querySelector("c-sbr_3_0_availability-badge-cmp")
          .updateSelectedBranchNumberData(this.branchDisplayFromChild);
        if (this.badges) {
          this.template
            .querySelector("c-sbr_3_0_availability-badge-cmp")
            .updateLocationData(this.badges);
        }
        this.template
          .querySelector("c-sbr_3_0_availability-badge-cmp")
          .updateItemType(this.itemType);

        this.closeSections();
      }
      // to get rates in bulk add structure for single product
      if (this.chronosEnabled) {
        this.processATPRates(false);
      } else {
        this.processRates(false);
      }
    } else if (selectedProductsCount > 1) {
      this.isSelectedState = true;
      this.panelType = "bulkAddPanel";
      this.panelTitle = "Multi Add"; // FRONT-11315

      this.bulkProductIds = selectedProds.map((p) => p.Id);
      this.productCatclass = selectedProds.map((p) => p.Product_SKU__c);
      //this.ratesParamObject = { ...this.ratesParamObject, products: this.productCatclass }

      if (this.passedCustomerNumber) {
        this.ratesParamObject = {
          ...this.ratesParamObject,
          customerNumber: this.passedCustomerNumber
        };
      }
      console.log("##handle multiple callout" + this.chronosEnabled);
      if (this.chronosEnabled) {
        console.log("### inside to make ATP");
        //   this.getATPDetails(selectedProds[(selectedProductsCount-1)].Product_SKU__c);
        this.processATPRates(false);
      } else {
        this.processRates(false);
      }
      // add atp call and also get the rates
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
      this.objectApiName == "Order" ||
      this.objectApiName == "SBQQ__Quote__c"
    ) {
      if (this.passedCustomerNumber) {
        this.ratesParamObject = {
          ...this.ratesParamObject,
          customerNumber: this.passedCustomerNumber
        };
      }
    }
    if (selectedProductsCount > 0) {
      this.getKitItems();
      this.getProductDetails();
    }
  }

  handleSelectedItem(event) {
    let selectedItem = event.detail;
    this.hasRatesLoaded = false;
    console.log("selectedItem-->" + JSON.stringify(selectedItem));
    //this.showSpinner = true;
    this.toggleSpotlightPanel(selectedItem);

    // if (!this.isMobile) {
    //     this.template.querySelector('lightning-tabset').activeTabValue = 'Availability & Rates';
    //     this.template.querySelector('c-sbr_3_0_availability-cmp').updateAvailabilityData(this.productCatclass);
    //     this.template.querySelector('c-sbr_3_0_availability-cmp').updateSelectedATPData(this.atpSelected);
    //     this.template.querySelector('c-sbr_3_0_availability-cmp').updateSelectedATPLabelData(this.atpLabel);
    //     this.template.querySelector('c-sbr_3_0_availability-cmp').updateSelectedBranchData(this.branchNumberSelected);
    //     if(this.badges) {
    //         this.template.querySelector('c-sbr_3_0_availability-cmp').updateLocationData(this.badges);
    //     }
    // } else {
    //     this.closeSections();
    // }
  }
  getATPDetails(productSku) {
    console.log("##bulk cat " + productSku);
    getATPForBranch({
      objectId: this.recordId,
      catClass: productSku,
      companyCode: this.companyId,
      transactionType: this.transactionType
    })
      .then((data) => {
        if (data) {
          let closestLocation = undefined;
          let lastResortBranch = undefined;
          let closestATP = undefined;
          let closestLocationDistance = undefined;
          let atpBranch;
          // adding this for testing purpose need to show error if we don't have a atp branch for chronos enabled
          atpBranch = this.branchNumber;
          JSON.stringify(data, (key, val) => {
            if (key === "lastResortBranch" && val !== undefined && val !== "") {
              lastResortBranch = val.split("-")[1];
            }

            if (key == "availabilityByLocations" && val && val.length > 0) {
              for (const key2 in val) {
                if (
                  val[key2].hasOwnProperty("locationId") &&
                  val[key2].hasOwnProperty("atp") &&
                  val[key2].hasOwnProperty("geoDistanceFromJobSite")
                ) {
                  if (
                    closestLocation === undefined &&
                    closestATP === undefined &&
                    closestLocationDistance === undefined
                  ) {
                    closestLocation = val[key2]["locationId"].split("-")[1];
                    closestATP = val[key2]["atp"];
                    closestLocationDistance =
                      val[key2]["geoDistanceFromJobSite"];
                  } else if (
                    closestLocationDistance !== undefined &&
                    val[key2]["geoDistanceFromJobSite"] <
                      closestLocationDistance
                  ) {
                    closestLocation = val[key2]["locationId"].split("-")[1];
                    closestATP = val[key2]["atp"];
                    closestLocationDistance =
                      val[key2]["geoDistanceFromJobSite"];
                  }
                }
              }
            }

            if (key === "pcId") {
              closestLocation = val;
            }

            return val;
          });

          if (closestLocation !== undefined && closestATP !== undefined) {
            atpBranch = closestLocation;
          } else if (lastResortBranch !== undefined) {
            // this.atpBranch = lastResortBranch;
            atpBranch = lastResortBranch;
          }
        } else {
          atpBranch = this.branchNumber;
          console.log("####ATP success " + "calling rates");
        }

        let productBranchObj = [{ pc: atpBranch, productId: productSku }];
        productBranchObj =
          this.ratesParamObject.products.push(productBranchObj);
        this.ratesParamObject = {
          ...this.ratesParamObject,
          products: productBranchObj
        };
        this.getRates();
      })
      .catch((error) => {
        console.log("error in getATPForBranch " + JSON.stringify(error));
        console.log("##Calling Parent");
        //this.updateParent();
        // adding this for testing purpose need to show error if we don't have a atp branch for chronos enabled
        let atpBranch = this.branchNumber;
        console.log("###inside catch" + productSku);
        let productBranchObj = [{ pc: atpBranch, productId: productSku }];
        this.ratesParamObject = {
          ...this.ratesParamObject,
          products: productBranchObj
        };
        this.getRates();

        //console.log('error stack -> ' + error.stack.toString());
      });
  }

  handleParentItemQtyChange(event) {
    this.parentItemQty = event.detail.valueOf();
  }

  //method to check if customer special rates are available and alert accordingly
  //will be modified to show the specific type of CSP that is applied to that product for the selected customer khaight
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
  hideCustomerPricingAlert() {
    this.showCustomerPricingAlert = false;
  }
  backToItemSearch() {
    this.itemSearchBackBtnClass = this.selectedClass;
    this.isSelectedState = false;
    this.closeSections();
    this.template
      .querySelector(
        'c-sbr_3_0_product-details-cmp[class="image-carousel-container"'
      )
      .resetImageCarousel();
    this.panelType == "inactivePanel";
    const toggleprodinqmobilestate = new CustomEvent(
      "toggleprodinqmobilestate",
      {
        bubbles: true,
        composed: true,
        detail: {
          viewState: "base",
          showTabsPanel: true
        }
      }
    );
    this.dispatchEvent(toggleprodinqmobilestate);
    this.itemSearchBackBtnClass = this.unselectedClass;
  }
  toggleAddCustomerMob(event) {
    this.isAddCustomerSelected = true;
    this.viewState = "item-spotlight";
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

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );

    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className =
        "slds-section slds-is-open slds-border_top slds-m-around_none";
      this.openSections.push(buttonid);
    } else {
      currentsection.className =
        "slds-section slds-is-close slds-border_top slds-m-around_none";
      this.openSections = this.openSections.filter((e) => e !== buttonid);
    }
  }

  closeSections() {
    for (let index in this.openSections) {
      let currentsection = this.template.querySelector(
        '[data-id="' + this.openSections[index] + '"]'
      );
      if (currentsection.className.search("slds-is-open") == -1) {
        currentsection.className =
          "slds-section slds-is-open slds-border_top slds-m-around_none";
      } else {
        currentsection.className =
          "slds-section slds-is-close slds-border_top slds-m-around_none";
      }
    }
    this.openSections = [];
  }

  handleBranchId(event) {
    event.stopPropagation();
    this.recordNavigateRef = {
      type: "standard__recordPage",
      attributes: {
        recordId: this.locationInfo.Id,
        actionName: "view"
      }
    };
    this[NavigationMixin.Navigate](this.recordNavigateRef);
  }

  updateSpotlightUtil(event) {
    let data = event.detail;
    this.template
      .querySelector("c-sbr_3_0_availability-badge-cmp")
      .updateUtil(data.util);
  }

  //getters
  get isInactivePanel() {
    return this.panelType == "inactivePanel";
  }
  get isDetailsPanel() {
    return this.panelType == "detailsPanel";
  }
  get isBulkAddPanel() {
    return this.panelType == "bulkAddPanel";
  }
  get isKit() {
    return this.isProductKit == "Yes" ? true : false;
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
    return `height:${this.spotlightHeight}px;`;
  }
  get hasProductsLoaded() {
    return (
      this.productId != "" &&
      this.productId != null &&
      this.productId != undefined
    );
  }

  async getKitItems(event) {
    let data = [];
    try {
      let productId = this._selectedProducts[0].Id;
      data = await getProductKitComponents({ productId: productId });
      data = JSON.parse(data);
      console.log("getKitItems->" + JSON.stringify(data));
      //this._selectedProducts[0].kitItems = data;
      //this.selectedProducts[0].kitItems = data;
      this._selectedProducts = this.selectedProducts; //SADAPUR
      this.kitComponents = data;
    } catch (error) {
      console.log(
        "error in getKitComponents:" +
          error.message +
          " | " +
          JSON.stringify(error) +
          " | " +
          error.stack
      );
    }
  }

  async getProductDetails() {
    let productId = this._selectedProducts[0].Id;
    console.log("--> Line 509 productId: " + productId);

    try {
      let result = await getProductDetails({ productId: productId });
      this.productDescription = JSON.parse(result);
      this.productDescription =
        this.productDescription.Description != null
          ? this.productDescription.Description
          : false;
    } catch (error) {
      console.log("error in getProductDetails:" + error.message);
    }
  }
  handleBranchDisplayUpdate(event) {
    let branch = event.detail.pc;
    let catClassId = event.detail.productId;
    let chronosEnabledAvail = event.detail?.chronosEnabled;
    let productBranchObj = [{ pc: branch, productId: this.productCatclass[0] }];
    this.branchDisplayFromChild = event.detail.pc;
    this.showBranchWarningAlert(!event.detail.branchAvailable);
    if (chronosEnabledAvail != undefined && chronosEnabledAvail == false) {
      // SF - 6828
      this.isShowBranchWarning = false;
    }

    this.ratesParamObject = {
      ...this.ratesParamObject,
      products: productBranchObj
    };
    this.getRates();
  }

  // Process rates when ATP call is not required for bulk add
  processRates(customerChanged) {
    if (customerChanged) {
      this.finalProductMap = {};
    }
    // Logic to store products and its rates responses
    let productSkusWithoutRates = {};
    const customerNumber = this.passedCustomerNumber
      ? this.passedCustomerNumber
      : this.selectedCustomerNumber;

    for (let key of Object.keys(this.selectedProductMap)) {
      if (
        !this.finalProductMap.hasOwnProperty(key) ||
        (this.finalProductMap[key].ratesAPI === "pending" &&
          !this.productsPendingRatesQueue.includes(key))
      ) {
        productSkusWithoutRates[key] = this.selectedProductMap[key];
        this.productsPendingRatesQueue.push(key);
        break;
      }
    }
    if (Object.keys(productSkusWithoutRates).length > 0) {
      this.hasRatesLoaded = false;
      findRatesForProducts({
        productSkus: Object.keys(productSkusWithoutRates),
        productLocationMap: null,
        accountNumber: customerNumber,
        branchNumber: this.branchNumber,
        formatForBulk: true
      })
        .then((data) => {
          console.log("productRatesMap", data);
          if (data) {
            let parsedData = JSON.parse(data);
            this.finalProductMap = this.addValuesToFinalMap(
              this.finalProductMap,
              parsedData
            );
            this.bulkProductData = Object.values(this.finalProductMap);
            if (
              this.productCount > 1 &&
              this.productCount ===
                this.bulkProductData.filter(
                  (product) =>
                    product.ratesAPI === "complete" &&
                    product.featureName === null
                ).length
            ) {
              this.hasRatesLoaded = true;
            }
          }
          this.showSpinner = false;
          console.log("this.finalProductMap", this.finalProductMap);
        })
        .then(() => {
          this.processRates(false);
        })
        .catch((error) => {
          console.log("productRatesMap error", error);
          this.showSpinner = false;
        });
    }
  }

  // Process rates when ATP call is required for bulk add
  processATPRates(customerChanged) {
    if (customerChanged) {
      this.finalProductMap = {};
    }

    const customerNumber = this.passedCustomerNumber
      ? this.passedCustomerNumber
      : this.selectedCustomerNumber;

    let productSkusWithoutRates = {};
    for (let key of Object.keys(this.selectedProductMap)) {
      if (
        !this.finalProductMap.hasOwnProperty(key) ||
        (this.finalProductMap[key].ratesAPI === "pending" &&
          !this.productsPendingRatesQueue.includes(key))
      ) {
        productSkusWithoutRates[key] = this.selectedProductMap[key];
        this.productsPendingRatesQueue.push(key);
        break;
      }
    }
    //SF-7849, using profileBranch.
    if (Object.keys(productSkusWithoutRates).length > 0) {
      this.hasRatesLoaded = false;
      findRatesForProductbyAvailabilityLocation({
        recordId: this.recordId,
        productSkus: Object.keys(productSkusWithoutRates),
        customerNumberParam: customerNumber,
        branchNumber: this.profileBranch,
        formatForBulk: true
      })
        .then((data) => {
          console.log("productRatesMap", data);
          if (data) {
            let parsedData = JSON.parse(data);
            this.finalProductMap = this.addValuesToFinalMap(
              this.finalProductMap,
              parsedData
            );
            this.bulkProductData = Object.values(this.finalProductMap);
            if (
              this.productCount > 1 &&
              this.productCount ===
                this.bulkProductData.filter(
                  (product) =>
                    product.ratesAPI === "complete" &&
                    product.featureName === null
                ).length
            ) {
              this.hasRatesLoaded = true;
            }
          }
        })
        .then(() => {
          this.processATPRates(false);
        })
        .catch((error) => {
          console.log("productRatesMap error", error);
        });
    }
  }

  // store product Rates ib finalProductMap to send to bulk add component
  addValuesToFinalMap(finalProductMap, productRates) {
    console.log("productRate", JSON.stringify(productRates));
    productRates.forEach((item) => {
      console.log("Inside", item);
      finalProductMap[item.catClass] = item;
      finalProductMap[item.catClass].ratesAPI = "complete";
      this.productsPendingRatesQueue = this.productsPendingRatesQueue.filter(
        (sku) => sku !== item.catClass
      );
    });
    console.log("finalMap", JSON.stringify(finalProductMap));
    return finalProductMap;
  }
  //convert selected product to bulk format
  convertToBulk(selectedProduct) {
    return {
      id: selectedProduct?.Id,
      catClass: selectedProduct?.Product_SKU__c,
      name: selectedProduct?.Name,
      productType: selectedProduct?.Product_Type__c,
      isKit: selectedProduct?.Is_Kit__c,
      isChangeable: selectedProduct?.Changeable__c,
      inventoriedItem: selectedProduct?.Inventoried_Item__c,
      miscellaneousChargeItem: selectedProduct?.Miscellaneous_Charge_Item__c,
      userSelectableForQuote: selectedProduct?.User_Selectable_for_Quote__c,
      ratesAPI: "pending"
    };
  }

  handleSpinner(event) {
    this.showSpinner = event.detail;
  }
  //SF-7082
  handleAltInvTabActive(event) {
    let activetabContent = event.target.value;
    if (this.chronosEnabled) {
      this.dispatchEvent(new RefreshEvent());
    }
  }

  /*----- Start- FRONT-15734 ---- */
  removeSpotlighData(event) {
    event.preventDefault();
    event.stopPropagation();
    publish(this.messageContext, deselectProductRowChannel, {
      productId: null,
      contextId: this.recordId
    });
    this.panelTitle = "Spotlight Panel";
    this.panelType = "detailsPanel";
  }
  /*----- End- FRONT-15734 ---- */
}