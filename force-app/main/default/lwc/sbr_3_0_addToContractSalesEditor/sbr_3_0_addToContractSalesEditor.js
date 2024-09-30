import { LightningElement, api, track } from "lwc";
import { Logger } from "c/sbr_3_0_frontlineUtils";

const logger = Logger.create(true);
export default class Sbr_3_0_addToContractSalesEditor extends LightningElement {
  isLoading = true;
  @track itemData = {
    partOrItemNumber: "",
    stockOrVendor: "",
    quantity: 1,
    availabileQty: 0,
    unitOfMeasure: "",
    salesOrMiscPrice: 0,
    noChargeFlag: false,
    lineItemNotes: ""
  };

  @api costPrice;
  @api variant;
  @api
  get selectedSalesItem() {
    return this._selectedSalesItem;
  }
  set selectedSalesItem(value) {
    logger.log("🚀 selectedAsset Data :: " + JSON.stringify(value));
    this._selectedSalesItem = value;
    this.buildModalData();
  }

  get salesOrMiscPriceFieldLevelHelp() {
    return this.costPrice ? `Cost: $${this.costPrice}` : "Cost: $0.00";
  }

  buildModalData() {
    this.isLoading = true;
    if (this._selectedSalesItem) {
      this.itemData.partOrItemNumber = this._selectedSalesItem.itemNumber;
      this.itemData.stockOrVendor = this._selectedSalesItem.stockClass;
      this.itemData.quantity = 1;
      this.itemData.availabileQty = this._selectedSalesItem.availableQty;
      this.itemData.unitOfMeasure = "each";
      this.itemData.salesOrMiscPrice = this._selectedSalesItem.sellPrice;
      this.itemData.noChargeFlag = false;
      this.itemData.lineItemNotes = "";
      this.isLoading = false;
    }
  }

  get isMiscVariant() {
    return this.variant && this.variant.toLowerCase() === "misc";
  }

  get isSalesVariant() {
    return this.variant && this.variant.toLowerCase() === "sales";
  }

  handleFieldChange(event) {
    let fieldKey = event.currentTarget.dataset.fieldKey;
    this.itemData[fieldKey] =
      fieldKey === "noChargeFlag" ? event.target.checked : event.target.value;
  }

  @api getSalesMiscItemData() {
    return this.itemData;
  }
}