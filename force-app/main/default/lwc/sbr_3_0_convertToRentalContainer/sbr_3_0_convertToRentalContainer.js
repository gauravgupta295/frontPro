import { LightningElement, api, track, wire } from "lwc";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import retrieveRentalProduct from "@salesforce/apex/ConvertToRentalController.retrieveRentalProduct";
import { CloseActionScreenEvent } from "lightning/actions";

import PRODUCT_2_LOOKUP from "@salesforce/schema/ProductItem.Product2Id";
import PRODUCT_2_RENTAL_CLASS from "@salesforce/schema/ProductItem.Product2.Rental_Class__c";
import PRODUCT_2_RENTAL_CATEGORY from "@salesforce/schema/ProductItem.Product2.Rental_Category__c";
import PRODUCT_2_TYPE from "@salesforce/schema/ProductItem.Product2.Product_Type__c";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_convertToRentalContainer extends LightningElement {
  @api recordId;
  @api objectApiName;
  product2Lookup;
  productType;
  productRentalClass;
  productRentalCategory;
  @track rentalProduct = {};
  showError = false;
  labels = LABELS;
  showSpinner = true;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      PRODUCT_2_LOOKUP,
      PRODUCT_2_TYPE,
      PRODUCT_2_RENTAL_CLASS,
      PRODUCT_2_RENTAL_CATEGORY
    ]
  })
  getProductItem({ error, data }) {
    if (data) {
      this.productItem = { data };
      this.product2Lookup = getFieldValue(
        this.productItem.data,
        PRODUCT_2_LOOKUP
      );
      this.productType = getFieldValue(this.productItem.data, PRODUCT_2_TYPE);
      this.productRentalClass = getFieldValue(
        this.productItem.data,
        PRODUCT_2_RENTAL_CLASS
      );
      this.productRentalCategory = getFieldValue(
        this.productItem.data,
        PRODUCT_2_RENTAL_CATEGORY
      );
      this.getRelatedRentalProduct();
      this.showError = !(
        this.productRentalCategory &&
        this.productRentalClass &&
        this.productType === "Merchandise"
      );
      this.showSpinner = false;
    }
    if (error) {
      console.error("Error Fetching Product Item", error);
    }
  }
  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  getRelatedRentalProduct() {
    retrieveRentalProduct({
      rentalClass: this.productRentalClass,
      rentalCategory: this.productRentalCategory
    })
      .then((data) => {
        let relatedProduct = data[0];
        this.rentalProduct.description = relatedProduct.Product_Description__c;
        this.rentalProduct.itemNumber =
          relatedProduct.itemNumberUsedByReservationsRentalOut__c;
        this.rentalProduct.isBulk = relatedProduct.Bulk_Item__c;
      })
      .catch((error) => {
        console.error("Error Retrieving rental product", error);
      });
  }

  handleSubmit() {
    if(this.template.querySelector('c-sbr_3_0_convert-to-rental-merch').handleSubmit()) {
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }
}