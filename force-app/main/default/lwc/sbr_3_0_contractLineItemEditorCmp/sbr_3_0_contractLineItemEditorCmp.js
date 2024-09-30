import { LightningElement, track, api } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import saveSObjects from "@salesforce/apex/SBR_3_0_LineItemEditorCmpController.saveSObjects";
import getAllProductItemsForSales from "@salesforce/apex/SBR_3_0_ConsumablesItemSearchCtrl.getAllProductItemsForSales";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LABELS from "c/sbr_3_0_customLabelsCmp";
const logger = Logger.create(true);

export default class Sbr_3_0_contractLineItemEditorCmp extends LightningElement {
  isLoading = false;
  salesOrMiscPriceFieldLevelHelp;
  isMobile = isMobile;
  disableConfirm = false;
  price=LABELS.PRICE_LABEL;


  @track itemData = {
    partOrItemNumber: "",
    stockOrVendor: "",
    quantity: 1,
    availabileQty: 0,
    unitOfMeasure: "",
    salesOrMiscPrice: 0,
    noChargeFlag: false,
    lineItemNotes: "",
    productType: ""
  };

  @api
  get selectedItem() {
    return this._selectedItem;
  }
  set selectedItem(value) {
    logger.log("===selectedItem====", JSON.stringify(value));
    this._selectedItem = value;
    this.buildModalData();
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  async buildModalData() {
    if (this._selectedItem) {
      this.isLoading = true;
      let whereClause = ` Product2Id = '${this._selectedItem.product}' AND LocationId = '${this._selectedItem.sourcingBranch}' `;

      //get the available quantity from the corresponding productitems
      let productItemsResponse = await getAllProductItemsForSales({
        offset: 0,
        batchSize: 500,
        whereClause: whereClause,
        productType: this.getIsSalesOrMISC(this._selectedItem.productType)
      });

      this.salesOrMiscPriceFieldLevelHelp = this._selectedItem.cost
        ? "$" + this._selectedItem.cost.toFixed(2)
        : "$0.00";
      this.salesOrMiscPriceFieldLevelHelp="Cost: "+this.salesOrMiscPriceFieldLevelHelp;  //FRONT-31902
      this.itemData.Id = this._selectedItem.Id;
      this.itemData.partOrItemNumber = this._selectedItem.itemNumber;
      this.itemData.stockOrVendor = this._selectedItem.stockClass;
      this.itemData.quantity = this._selectedItem.Quantity;
      this.itemData.availabileQty =
        productItemsResponse && productItemsResponse.length > 0
          ? productItemsResponse[0].availableQty
          : 0;
      this.itemData.unitOfMeasure = "Each";
      this.itemData.salesOrMiscPrice = this._selectedItem.Sale_Price
        ? this._selectedItem.Sale_Price
        : "0.00";
      this.itemData.noChargeFlag = this._selectedItem.noChargeFlag;
      this.itemData.lineItemNotes = this._selectedItem.lineItemNotes;
      this.itemData.productType = this._selectedItem.productType;
      this.enableOrDisableSalesMiscPrice();
      this.isLoading = false;
    }
    this.isLoading = false;
  }

  get isMiscProduct() {
    return (
      this.itemData.productType === "Misc-Charge" ||
      this.itemData.productType === "MISC Charge Items"
    );
  }

  handleFieldChange(event) {
    let fieldKey = event.target.dataset.fieldKey;
    if (fieldKey === "noChargeFlag") {
      let salesPriceField = this.template.querySelector(
        'lightning-input[data-field-key="salesOrMiscPrice"]'
      );
      if (event.target.checked) {
        salesPriceField.disabled = true;
        this.itemData["salesOrMiscPrice"] = "0.00";
      } else {
        salesPriceField.disabled = false;
      }
      this.itemData[fieldKey] = event.target.checked;
    } else {
      this.itemData[fieldKey] = event.target.value;
    }
    this.itemData[fieldKey] =
      fieldKey === "noChargeFlag" ? event.target.checked : event.target.value;
    if (fieldKey === "quantity" && !this.isMiscProduct) {
        if (
          parseFloat(event.target.value) >
          this.itemData.availabileQty
        ) {
        event.target.setCustomValidity(
            "Cannot go above available quantity of " +
            this.itemData.availabileQty
        );
        this.disableConfirm = true;
      } else {
        event.target.setCustomValidity("");
        this.disableConfirm = false;
      }
      let disableConfirmEvent = new CustomEvent("disableconfirm", {
        detail: {
          disableConfirm: this.disableConfirm
        }
      });
      this.dispatchEvent(disableConfirmEvent);
    }
  }

  @api async saveLineItemData() {
    this.isLoading = true;
    const itemtoUpdate = {
      Id: this.itemData.Id,
      Quantity: parseInt(this.itemData.quantity),
      Line_Comments__c: this.itemData.lineItemNotes,
      Selling_Price__c: this.itemData.salesOrMiscPrice,
      Free_Flag__c: this.itemData.noChargeFlag
    };

    const result = await saveSObjects({
      quoteLines: [],
      orderLines: [itemtoUpdate],
      objectType: "OrderItem"
    })
      .then((result) => {
        const message = `${this._selectedItem?.Name} has been successfully updated.`;
        setTimeout(() => {
          this.isLoading = false;
          this.dispatchEvent(
            new ShowToastEvent({
              message,
              variant: "success"
            })
          );
          this.dispatchEvent(new CustomEvent("closemodal"));
        }, 500);
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Error updating Line Item",
            variant: "error"
          })
        );
        this.isLoading = false;
      });
  }

  getIsSalesOrMISC(productType) {
    let salesOrMisc = "";
    if (productType === "Parts" || productType === "Merchandise") {
      salesOrMisc = "SALES";
    } else if (
      productType === "Misc-Charge" ||
      productType === "MISC Charge Items"
    ) {
      salesOrMisc = "MISC";
    }
    return salesOrMisc;
  }

  enableOrDisableSalesMiscPrice() {
    let salesPriceField = this.template.querySelector(
      'lightning-input[data-field-key="salesOrMiscPrice"]'
    );
    if (this._selectedItem.noChargeFlag) {
      salesPriceField.disabled = true;
      this.itemData.salesOrMiscPrice = "0.00";
    } else {
      salesPriceField.disabled = false;
    }
  }
}