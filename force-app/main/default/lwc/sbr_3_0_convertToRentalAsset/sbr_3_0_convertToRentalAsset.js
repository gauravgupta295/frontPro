import { LightningElement, wire, api, track } from "lwc";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import RECORD_TYPE_ID from "@salesforce/schema/Asset.RecordTypeId";
import RECORD_TYPE_NAME from "@salesforce/schema/Asset.RecordType.DeveloperName";
import ASSET_CURRENT_LOCATION from "@salesforce/schema/Asset.SM_PS_Current_Location__c";
import ASSET_CURRENT_LOCATION_NAME from "@salesforce/schema/Asset.SM_PS_Current_Location__r.Name";
import CURRENT_LOCATION_NAME from "@salesforce/schema/Asset.SM_PS_Current_Location__r.Branch_Location_Name__c";
import EQUIPMENT_TYPE from "@salesforce/schema/Asset.SM_PS_Equipment_Type__c";
import EQUIPMENT_STATUS from "@salesforce/schema/Asset.SM_PS_Equipment_Status__c";
import COST_FIELD from "@salesforce/schema/Asset.SM_PS_Original_Cost__c";
import REPLACEMENT_FIELD from "@salesforce/schema/Asset.SM_PS_Replacement_Value__c";
import USERID from "@salesforce/user/Id";
import RSV_NUMBER from "@salesforce/schema/Asset.Product2.itemNumberUsedByReservationsRentalOut__c";
import getLoggedInUserLocation from "@salesforce/apex/SBR_3_0_Create_Inventory_Transfer_Cntr.getLoggedInUserLocation";
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class Sbr_3_0_convertToRentalAsset extends LightningElement {
  @api recordId;
  @api objectApiName;
  userCurrentLocation;
  recordTypeName;
  currLocation;
  currLocationName;
  equiType;
  equiStatus;
  rsvNumber;
  cost;
  replacementCost;
  isError = true;
  @track errors = [];
  label = LABELS;

  //constants
  VALID_EQUIPMENT_TYPES = ["RENTAL", "OWNED", "NEW FOR SALE"];
  VALID_EQUIPMENT_STATUSES = ["AVAILABLE", "RETURNED - NEED CHECK OUT"];

  //showErrorMessage = false;
  showComponent;
  isMobileDevice = false;
  asset;
  showSpinner = true;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      ASSET_CURRENT_LOCATION,
      CURRENT_LOCATION_NAME,
      EQUIPMENT_TYPE,
      EQUIPMENT_STATUS,
      RECORD_TYPE_ID,
      RECORD_TYPE_NAME,
      ASSET_CURRENT_LOCATION_NAME,
      RSV_NUMBER,
      COST_FIELD,
      REPLACEMENT_FIELD
    ]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.asset = { data };
      this.recordTypeName = getFieldValue(this.asset.data, RECORD_TYPE_NAME);
      this.currLocation = getFieldValue(
        this.asset.data,
        ASSET_CURRENT_LOCATION
      );
      this.equiType = getFieldValue(this.asset.data, EQUIPMENT_TYPE);
      this.equiStatus = getFieldValue(this.asset.data, EQUIPMENT_STATUS);
      this.currLocationName = getFieldValue(
        this.asset.data,
        ASSET_CURRENT_LOCATION_NAME
      );
      this.rsvNumber = getFieldValue(this.asset.data, RSV_NUMBER);

      getLoggedInUserLocation({ userId: USERID })
        .then((data) => {
          this.userCurrentLocation = data.ProfileBranch;

          if (this.recordTypeName !== "Rental_Asset") {
            this.errors.push({
              id: "assetRecordTypeError" + this.recordId,
              field: "Record Type",
              currentValue: this.recordTypeName,
              errorMessage: this.label.ASSET_RECORDTYPE_ERROR_MESSAGE
            });
          }

          if (this.currLocation !== this.userCurrentLocation) {
            this.errors.push({
              id: "userCurrentLocationError" + this.recordId,
              field: "Asset Current Location",
              currentValue: this.currLocationName,
              errorMessage: this.label.ASSET_CURRENT_LOCATION_ERROR_MESSAGE
            });
          }

          if (!this.VALID_EQUIPMENT_TYPES.includes(this.equiType)) {
            this.errors.push({
              id: "userEquipmentTypeError" + this.recordId,
              field: "Equipment Type",
              currentValue: this.equiType,
              errorMessage: this.label.ASSET_EQUIPMENT_TYPE_ERROR_MESSAGE
            });
          }

          if (!this.VALID_EQUIPMENT_STATUSES.includes(this.equiStatus)) {
            this.errors.push({
              id: "userEquipmentStatusError" + this.recordId,
              field: "Equipment Status",
              currentValue: this.equiStatus,
              errorMessage: this.label.ASSET_EQUIPMENT_STATUS_ERROR_MESSAGE
            });
          }

          if (this.errors.length > 0) {
            this.showSpinner = false;
            this.isError = true;
            this.showComponent = true;
          } else {
            this.showSpinner = false;
            this.isError = false;
            this.showComponent = true;
          }
        })
        .catch((error) => {
          console.log("user location Error —> " + JSON.stringify(error));
        });
    } else if (error) {
      console.error("Convert To Rental Asset Wire Error: " + error);
    }
  }

  connectedCallback() {
    this.validateTypeOfDevice();
  }

  handleSave() {
    if (
      //temporary logic, until API information is available, and actual update is made via API and to Salesforce
      this.errors.length === 0
    ) {
      this.showToast(
        "Success",
        "Successfully transferred from Sales to Rental",
        "success"
      );
      this.handleCancel();
      this.closeAuraAction();
    } else {
      //this.showErrorMessage = true;
    }
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.closeAuraAction();
  }

  // if opened through Aura
  closeAuraAction() {
    this.dispatchEvent(new CustomEvent("closeauraaction"));
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  validateTypeOfDevice() {
    if (FORM_FACTOR === "Small") {
      this.isMobileDevice = true;
      this.modalSize = "slds-modal slds-fade-in-open slds-modal_full";
      console.log("Mobile device");
    } else {
      this.modalSize = "slds-modal slds-fade-in-open slds-modal_small";
    }
  }
}