import { LightningElement, api, wire } from "lwc";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import CURRENT_LOCATION from "@salesforce/schema/ProductItem.Location.Name";
import RSV_NUMBER from "@salesforce/schema/ProductItem.Product2.itemNumberUsedByReservationsRentalOut__c";
import CAT_CLASS_DESCRIPTION from "@salesforce/schema/ProductItem.Product2.Name";
import AVERAGE_COST from "@salesforce/schema/ProductItem.SM_PS_Average_Cost__c";
import AVAILABLE_QUANTITY from "@salesforce/schema/ProductItem.SM_PS_Quantity_Available__c";
export default class Sbr_3_0_convertToRentalBulkAsset extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api rentalProduct;
  currLocation;
  rsvNumber;
  catClassDescription;
  avgCost;
  itemQuantity;
  calculatedExtendedCost;
  extendedCost;
  availableQty;
  productItem;
  showSpinner=false;
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      RSV_NUMBER,
      CAT_CLASS_DESCRIPTION,
      CURRENT_LOCATION,
      AVERAGE_COST,
      AVAILABLE_QUANTITY
    ]
  })
  productItemDetails({ data, error }) {
    if (data) {
      this.productItem = { data };
      this.rsvNumber = getFieldValue(this.productItem.data, RSV_NUMBER);

      this.catClassDescription = getFieldValue(
        this.productItem.data,
        CAT_CLASS_DESCRIPTION
      );

      this.currLocation = getFieldValue(
        this.productItem.data,
        CURRENT_LOCATION
      );

      this.avgCost = getFieldValue(this.productItem.data, AVERAGE_COST);

      this.availableQty = getFieldValue(
        this.productItem.data,
        AVAILABLE_QUANTITY
      );
    }
    this.showSpinner=true;
    setTimeout(() => {
      this.showSpinner=false;
    }, 1000);
  }

  handleItemQtyChange(event) {
    //Added for FRONT-29079
    if(typeof(event.detail.value) === 'boolean'){
      //for invalid Input
      this.extendedCost = '';
    }else{
      //for valid input
      this.itemQuantity = event.detail.value;
      this.calculateExtendedCost();
    }   
    //End of FRONT-29079
  }

  calculateExtendedCost() {
    this.calculatedExtendedCost = this.itemQuantity * this.avgCost;
    this.extendedCost = "USD" + " " + this.calculatedExtendedCost.toString();
  }

  @api
  handleSubmit() {
    if (this.rentalProduct.isBulk) {
      return this.template
        .querySelector("c-sbr_3_0_convert-to-rent-quantity-field")
        .handleSubmit();
    } else {
      return this.template
        .querySelector("c-sbr_3_0_convert-to-rent-serial-num-field")
        .handleSubmit();
    }
  }
}