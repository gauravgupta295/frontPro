import { LightningElement, api, wire, track } from "lwc";
import LABELS from "c/sbr_3_0_customLabelsCmp";

import PRODUCT_2_LOOKUP from "@salesforce/schema/ProductItem.Product2Id";
import RSV_ITEM_NUM_FIELD from "@salesforce/schema/ProductItem.Product2.itemNumberUsedByReservationsRentalOut__c";
import LOCATION_LOOKUP_FIELD from "@salesforce/schema/ProductItem.LocationId";
import LOCATION_NAME_FIELD from "@salesforce/schema/ProductItem.Location.Name";
import TOTAL_OWNED_FIELD from "@salesforce/schema/ProductItem.SM_PS_Number_of_Rental_Units__c";
import AVAILABLE_QUANTITY_FIELD from "@salesforce/schema/ProductItem.SM_PS_Quantity_Available__c";
import RETURNED_QUANTITY_FIELD from "@salesforce/schema/ProductItem.SM_PS_Quantity_Returned__c";
import INSIDE_SHOP_QUANTITY_FIELD from "@salesforce/schema/ProductItem.SM_PS_Quantity_in_Inside_Shop__c";
import OUTSIDE_SHOP_QUANTITY_FIELD from "@salesforce/schema/ProductItem.SM_PS_Quantity_in_Outside_Shop__c";
import MISSING_QUANTITY_FIELD from "@salesforce/schema/ProductItem.SM_PS_Quantity_Missing__c";
import FORM_FACTOR from "@salesforce/client/formFactor";

import DESKTOPTEMPLATE from "./sbr_3_0_bulkQuantityMaintenanceDesktop/sbr_3_0_bulkQuantityMaintenanceDesktop.html";
import MOBILETEMPLATE from "./sbr_3_0_bulkQuantityMaintenanceMobile/sbr_3_0_bulkQuantityMaintenanceMobile.html";

import { CloseActionScreenEvent } from "lightning/actions";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Sbr_3_0_bulkQuantityMaintenance extends LightningElement {
  @api recordId;
  productItemRecordTypeId;
  moveTo;
  moveFrom;
  newQuantity;
  productItem;
  locationRecordID;
  @track statuses;

  locationId;
  locationName;
  totalOwned;
  rsvItemNum;
  @track statusDropdownItems;
  @track moveToDropdown;
  @track moveFromDropdown;

  isNextDisabled = true;
  showEditLayout = true;
  showSpinner = true;
  showError = false;
  label = LABELS;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      PRODUCT_2_LOOKUP,
      RSV_ITEM_NUM_FIELD,
      LOCATION_LOOKUP_FIELD,
      LOCATION_NAME_FIELD,
      TOTAL_OWNED_FIELD,
      AVAILABLE_QUANTITY_FIELD,
      RETURNED_QUANTITY_FIELD,
      INSIDE_SHOP_QUANTITY_FIELD,
      OUTSIDE_SHOP_QUANTITY_FIELD,
      MISSING_QUANTITY_FIELD
    ]
  })
  getProductItem({ error, data }) {
    if (data) {
      this.productItem = { data };

      this.statuses = this.generateStatusArray();
      this.locationId = getFieldValue(
        this.productItem.data,
        LOCATION_LOOKUP_FIELD
      );
      this.locationName = getFieldValue(
        this.productItem.data,
        LOCATION_NAME_FIELD
      );
      this.rsvItemNum = getFieldValue(
        this.productItem.data,
        RSV_ITEM_NUM_FIELD
      );
      this.totalOwned = getFieldValue(this.productItem.data, TOTAL_OWNED_FIELD);

      if (this.statuses) {
        this.statusDropdownItems = this.statuses.map(({ Label }) => ({
          label: Label,
          value: Label
        }));
        this.moveFromDropdown = this.moveToDropdown = Array.from(
          this.statusDropdownItems
        );
      }
    }

    if (error) {
      console.log("Error Fetching Product Item", error);
    }

    this.showSpinner = false;
  }

  generateStatusArray() {
    return [
      {
        id: this.recordId + "-available",
        Label: "Available",
        Quantity: getFieldValue(
          this.productItem.data,
          AVAILABLE_QUANTITY_FIELD
        ),
        NewQuantity: null
      },
      {
        id: this.recordId + "-returned",
        Label: "Returned",
        Quantity: getFieldValue(this.productItem.data, RETURNED_QUANTITY_FIELD),
        NewQuantity: null
      },
      {
        id: this.recordId + "-inside-shop",
        Label: "Inside Shop",
        Quantity: getFieldValue(
          this.productItem.data,
          INSIDE_SHOP_QUANTITY_FIELD
        ),
        NewQuantity: null
      },
      {
        id: this.recordId + "-outside-shop",
        Label: "Outside Shop",
        Quantity: getFieldValue(
          this.productItem.data,
          OUTSIDE_SHOP_QUANTITY_FIELD
        ),
        NewQuantity: null
      },
      {
        id: this.recordId + "-missing",
        Label: "Missing",
        Quantity: getFieldValue(this.productItem.data, MISSING_QUANTITY_FIELD),
        NewQuantity: null
      },
      {
        id: this.recordId + "-junked",
        Label: "Junked",
        Quantity: 0,
        NewQuantity: null
      }
    ];
  }

  handleMoveTo(event) {
    this.moveTo = event.detail.value;
    this.enableNext();
  }

  handleMoveFrom(event) {
    this.moveFrom = event.detail.value;
    if (this.moveTo === this.moveFrom) {
      this.moveTo = null;
    }
    this.moveToDropdown = this.statusDropdownItems.filter(
      (status) => status.label !== this.moveFrom
    );
    this.enableNext();
  }

  handleUpdateQuantity(event) {
    this.newQuantity = event.detail.value;
    this.enableNext();
  }

  enableNext() {
    this.isNextDisabled =
      this.moveFrom && this.moveTo && this.newQuantity == Math.trunc(this.newQuantity) && parseInt(this.newQuantity) > 0 ? false : true;
    
    if(!this.isNextDisabled) {
      this.newQuantity = parseInt(this.newQuantity);
    }
  }

  handleNext() {
    if (this.moveTo !== this.moveFrom) {
      const moveToStatus = this.statuses.filter(
        (status) => status.Label === this.moveTo
      )[0];
      const moveFromStatus = this.statuses.filter(
        (status) => status.Label === this.moveFrom
      )[0];

      //validation to ensure that quantity being moved, does not exceed the original quantity associated with that status
      if (this.newQuantity <= moveFromStatus.Quantity) {
        moveToStatus.NewQuantity = this.newQuantity;
        moveFromStatus.NewQuantity = moveFromStatus.Quantity - this.newQuantity;
        this.statuses = [...this.statuses];
        this.showEditLayout = false;
        this.showError = false;
      } else {
        this.showError = true;
      }
    }
  }

  handlePrevious() {
    //clear new quantities
    this.statuses.forEach((status) => {
      status.NewQuantity = null;
    });
    this.showEditLayout = true;
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  // if opened through Aura
  closeAuraAction() {
    this.dispatchEvent(new CustomEvent("closeauraaction"));
  }

  handleSubmit() {
    this.closeModal();
    this.closeAuraAction();
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Your changes to bulk quantity has been saved.",
        variant: "success"
      })
    );
  }

  render() {
    return FORM_FACTOR === "Small" ? MOBILETEMPLATE : DESKTOPTEMPLATE;
  }
}