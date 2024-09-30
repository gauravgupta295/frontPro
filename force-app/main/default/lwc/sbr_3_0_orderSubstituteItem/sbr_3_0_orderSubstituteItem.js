import { LightningElement, api, track } from "lwc";
import desktopTemplate from "./sbr_3_0_orderSubstituteItemDesktopTemplate.html";
import mobileTemplate from "./sbr_3_0_orderSubstituteItemMobileTemplate.html";
import createLineItems from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.createLineItems";
import getProductRates from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductRates";
import FORM_FACTOR from "@salesforce/client/formFactor";
import deleteLineItems from "@salesforce/apex/SBR_3_0_LineItemCartCmpController.deleteLineItems";

export default class Sbr_3_0_orderSubstituteItem extends LightningElement {
  @api recordId;
  @api lineItem;
  @api selectedRecord;
  @api itemName;
  objectApiName = "Order";
  selectedProducts;
  @api substituteItem;
  @api id;
  isMobile;
  maxRowSelection = 1;
  showRadioButtons = true;//FRONT-8793
  ratesParamObject = {
    products: [],
    customerNumber: ""
  };
  @api customerInfo;
  @track isLoading = false;
  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
    //this.isMobile = true;
  }

  render() {
    let template;
    if (this.isMobile) {
      template = mobileTemplate;
    } else {
      template = desktopTemplate;
    }
    return template;
  }

  get substituteItemName() {
    console.log("-----substituteItem---" + JSON.stringify(this.substituteItem));
    return this.substituteItem.Name;
    //return "item";
  }
  handleViewCart(event) {
    const viewCartEvent = new CustomEvent("viewcart");
    this.dispatchEvent(viewCartEvent);
  }

  @api handleSelectedRows(event) {
    try {
      console.log("------ event: " + JSON.stringify(event.detail));
      if(this.isMobile) {
        this.selectedProducts = [event.detail];//FRONT-8793 The call to substitueRows has been removed and now handled by cancel button.
      } else {
        this.selectedProducts = event.detail;
      }
    } catch (error) {
      console.log("error in handleselected " + JSON.stringify(error));
    }
  }

  closeModal() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }

  substituteRows() {
    this.getProductRates();
  }

  /*---- Get Rates----- */
  getProductRates() {
    this.isLoading = true;
    let productCatclass = [this.selectedProducts[0].Product_SKU__c];
    this.ratesParamObject = {
      ...this.ratesParamObject,
      products: productCatclass,
      customerNumber: this.customerInfo.RM_Account_Number__c
    };

    console.log("----ratesParamObject" + JSON.stringify(this.ratesParamObject));
    getProductRates({ prwrapper: this.ratesParamObject })
      .then((data, error) => {
        let selProd = [];
        console.log("----getProductRates" + JSON.stringify(data));
        console.log("----getProductRates" + JSON.stringify(error));
        if (data) {
          let parsedData = JSON.parse(data);
          console.log("rates: ", parsedData);
          console.log("rates stringified: ", JSON.stringify(parsedData));
          if (parsedData.error) {
            this.error = parsedData.error.message;
            this.hasRatesLoaded = false;
            this.rates = this.ratesUnavailable;

            console.log("--> Line 134");
            selProd = selProd.concat(this.selectedProducts);
            selProd[0].Min_Rate = this.rates.suggestedRates["min."];
            selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
            selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
            selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];

            this.selectedProducts = selProd;
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
            try {
              selProd = selProd.concat(this.selectedProducts);
              selProd[0].Min_Rate = this.rates.suggestedRates["min."];
              selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
              selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
              selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];

              this.selectedProducts = selProd;
            } catch (error) {
              console.log("176 Error: " + error.message);
            }
          }
        } else if (error) {
          console.log("error-->" + JSON.stringify(error));
          this.hasRatesLoaded = false;
          this.rates = this.ratesUnavailable;
          selProd = selProd.concat(this.selectedProducts);
          selProd[0].Min_Rate = this.rates.suggestedRates["min."];
          selProd[0].Daily_Rate = this.rates.suggestedRates["day"];
          selProd[0].Weekly_Rate = this.rates.suggestedRates["week"];
          selProd[0].Monthly_Rate = this.rates.suggestedRates["month"];
          this.selectedProducts = selProd;
        }
      })
      .catch((err) => {
        console.log("error-->" + JSON.stringify(err));
      })
      .finally(() => {
        this.createLineItemRecord();
      });
  }
  /*--- */

  /* ---------- */
  // create new records by setting field information
  createLineItemRecord() {
    this.isLoading = true;
    // this.getProductRates();
    let item = this.selectedProducts[0];
    console.log("createLineItemRecord: " + JSON.stringify(item));
    let fields = {};
    let lineItemRecordInput = {};
    fields = {
      OrderId: this.recordId,
      Product2Id: item.Id,
      groupID__c: Math.floor(100000 + Math.random() * 900000).toString(),
      is_User_Added__c: true,
      UnitPrice: 0.1,
      Quantity: 1
    };
    console.log("createLineItemRecord: " + JSON.stringify(fields));
    lineItemRecordInput = {
      apiName: "Order",
      fields
    };
    this.substituteOrderLineItem(lineItemRecordInput);
  }
  /*------*/

  substituteOrderLineItem(item) {
    console.log("----atcRecordArr");
    let atcRecordArr = [];
    atcRecordArr.push(item);
    createLineItems({
      apiName: "Order",
      lineItems: JSON.stringify(atcRecordArr)
    })
      .then((result) => {
        result.forEach((createdLineItem) => {
          console.log("createdLineItem -> " + JSON.stringify(createdLineItem));
          this.deleteLineItems();
        });
      })
      .catch((err) => {
        this.isLoading = false;
        console.log(err);
        const selectedEvent = new CustomEvent("eventnotification", {
          detail: { message: "error", data: "" }
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
      });
  }

  closeModal() {
    const selectedEvent = new CustomEvent("eventnotification", {
      detail: { message: "close", data: "" }
    });
    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }

  deleteLineItems() {
    let returnMessage;
    let lineIdstoCancel = [];
    if(this.isMobile) {
      lineIdstoCancel.push(this.selectedRecord.Id);
    } else {
      lineIdstoCancel.push(this.substituteItem.Id);
    }
    deleteLineItems({ lineIds: lineIdstoCancel })
      .then((data) => {
        returnMessage = "success";
        setTimeout(() => {
          this.isLoading = false;
          const selectedEvent = new CustomEvent("eventnotification", {
            detail: { message: "success", data: this.selectedProducts[0].Name, data2: this.itemName }
          });
          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
        }, 3000);
      })
      .catch((error) => {
        returnMessage = "error";
        console.log("--- Substitute Error" + JSON.stringify(error));
      });
    return returnMessage;
  }
}