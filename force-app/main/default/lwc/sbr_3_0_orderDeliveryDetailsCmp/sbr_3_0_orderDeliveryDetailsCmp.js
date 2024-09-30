import { LightningElement, api, track, wire } from "lwc";
import { getRecord, updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import QUOTE_DELIVERY_METHOD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__DeliveryMethod__c";
import ORDER_DELIVERY_METHOD from "@salesforce/schema/Order.Deliverymethod__c";
import QUOTE_PICKUP_CHARGES from "@salesforce/schema/SBQQ__Quote__c.Pickup_Charges__c";
import ORDER_PICKUP_CHARGES from "@salesforce/schema/Order.Pickup_Charges__c";
import QUOTE_DELIVERY_CHARGES from "@salesforce/schema/SBQQ__Quote__c.Delivery_Charges__c";
import ORDER_DELIVERY_CHARGES from "@salesforce/schema/Order.Delivery_Charges__c";
import QUOTE_DELIVERY_CHARGES_OVERRIDE from "@salesforce/schema/SBQQ__Quote__c.Delivery_Charges_Override__c";
import ORDER_DELIVERY_CHARGES_OVERRIDE from "@salesforce/schema/Order.Delivery_Charges_Override__c";
import QUOTE_PICKUP_CHARGES_OVERRIDE from "@salesforce/schema/SBQQ__Quote__c.Pickup_Charges_Override__c";
import ORDER_PICKUP_CHARGES_OVERRIDE from "@salesforce/schema/Order.Pickup_Charges_Override__c";
import QUOTE_THIRD_PARTY from "@salesforce/schema/SBQQ__Quote__c.Using_3rd_Party__c";
import ORDER_THIRD_PARTY from "@salesforce/schema/Order.Using_3rd_Party__c";
import QUOTE_ID_FIELD from "@salesforce/schema/SBQQ__Quote__c.Id";
import ORDER_ID_FIELD from "@salesforce/schema/Order.Id";
import QUOTE_SOURCING_BRANCH from "@salesforce/schema/SBQQ__Quote__c.Sourcing_Branch__c";
import ORDER_SOURCING_BRANCH from "@salesforce/schema/Order.Sourcing_Branch__c";
import ORDER_DISTANCE_TO_JOB_SITE from "@salesforce/schema/Order.Distance_to_Job_Site__c";
import QUOTE_DISTANCE_TO_JOB_SITE from "@salesforce/schema/SBQQ__Quote__c.Distance_to_Job_Site__c";
import QUOTE_OMS_ENABLED from "@salesforce/schema/SBQQ__Quote__c.OMS_Sourcing_Enabled__c";
import QUOTE_LOC_OMS_ENABLED from "@salesforce/schema/SBQQ__Quote__c.Branch__r.OMS_Sourcing_Enabled__c";
import ORDER_OMS_ENABLED from "@salesforce/schema/Order.OMS_Sourcing_Enabled__c";
import QUOTE_COMPANY_CODE from "@salesforce/schema/SBQQ__Quote__c.Company_Code__c";
import ORDER_COMPANY_CODE from "@salesforce/schema/Order.Company_Code__c";
import ORDER_OBJECT from "@salesforce/schema/Order";
import FORM_FACTOR from "@salesforce/client/formFactor";
import FL_TEMPLATE from "./FL/defaultFL.html";
import SAL_TEMPLATE from "./SAL/defaultSAL.html";
import { appName, FL_APP_NAME, SAL_APP_NAME } from "c/sbr_3_0_frontlineUtils";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { refreshApex } from "@salesforce/apex"; //Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj

import getRelatedBranchLocation from "@salesforce/apex/SBR_3_0_JobsiteDA.getRelatedBranchLocation";  //changes for FRONT-22246, FRONT-22247 by Chinmay Bhatkal 

export default class Sbr_3_0_orderDeliveryDetailsCmp extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api isMobileRequestView = false;
  @track quoteRecord;
  @track showOnDelivery = false;
  @track showFields = false;
  @track showOnSalesforceOrigin = false;
  @track recordDetails = {};
  @track isEdit = false;
  parentRecordOwnerId;
  @track readOnly = true;
  @track editOverrideCharge = false;
  deliveryMethodPicklistValues = [];
  showEdit = true;
  showEditBtn = true;
  dataFields = {};
  deliverySectionClass;
  displayChargeSection=false;
  /*Start: Added by Gopal Raj */
  isShowModal = false;
  wiredRecordResult; //Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj
  /*End: Added by Gopal Raj */
  /* ----- Start FRONT-8095 ----- */
  @track showRebalanceScreen = false;
  recordTypeName;
  label = LABELS;
  @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
  objectInfo;

  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  wiredRecord(wiredRecordResult) {    //Story#FRONT-8094: Modified the code for refreshview purpose by Gopal Raj
    this.wiredRecordResult = wiredRecordResult;
    const { data, error } = wiredRecordResult;
    if (data) {
      console.log("data below:");
      console.log(data);
      this.dataFields = data.fields;
      this.recordTypeName = data.recordTypeInfo?.name;
      //fields with same api name ( in quote and order)
      this.recordDetails.suggestedDeliveryCharge =
        this.dataFields.Delivery_Charge__c.value;
      this.recordDetails.suggestedPickupCharge =
        this.dataFields.Pickup_Charge__c.value;
      this.recordDetails.totalSuggestedDeliveryCharge =
        this.dataFields.Total_Suggested_Delivery__c.value;
      this.recordDetails.totalSuggestedPickupCharge =
        this.dataFields.Total_Suggested_Pickup__c.value;
      this.recordDetails.totalWeight = this.dataFields.Total_Weight__c.value;
      this.recordDetails.using3rdParty =
        this.dataFields.Using_3rd_Party__c.value;
      this.recordDetails.numberOfTrucks =
        this.dataFields.Number_of_Trucks__c.value;
      this.recordDetails.deliveryOverride =
        this.dataFields.Delivery_Charges_Override__c.value;
      this.recordDetails.pickupCharges =
        this.dataFields.Pickup_Charges__c.value;
      this.recordDetails.deliveryCharges =
        this.dataFields.Delivery_Charges__c.value;
      this.recordDetails.analysisRegionKey =
        this.dataFields.Analysis_Region_Key__c.value;
      this.recordDetails.sourcingBranch =
        this.dataFields.Sourcing_Branch__c.value;
      this.recordDetails.omsEnabled =
        this.dataFields.OMS_Sourcing_Enabled__c.value;
      this.recordDetails.companyCode = this.dataFields.Company_Code__c.value;
      this.recordDetails.distanceToJobSite =
        this.dataFields.Distance_to_Job_Site__c.value;

      if (this.dataFields.Sourcing_Branch__c.value) {
        this.recordDetails.sourcingBranchName =
          this.dataFields.Sourcing_Branch__r.displayValue;
      }

      if (this.objectApiName == "SBQQ__Quote__c") {
        //SF-6835: Use Quote.Location.OMS_Enabled flag 
        this.recordDetails.omsEnabled = getFieldValue(data, QUOTE_LOC_OMS_ENABLED); 
        this.recordDetails.deliveryMethod =
          this.dataFields.SBQQ__DeliveryMethod__c.value; //SF-6859
        this.recordDetails.deliveryMethodDisplay =
            this.dataFields.SBQQ__DeliveryMethod__c.displayValue; //SF-6884
        this.recordDetails.originSystem =
          this.dataFields.Quote_Initiating_Channel__c.value;
        this.recordDetails.quoteSubmittedToWynne =
          this.dataFields.Submitted_to_Wynne__c.value;
        // SF-6561
        if (this.dataFields.SBQQ__Status__c.value == "In Review") {
          this.showEdit = false;
        }

        //SF-6769 - delivery-pickup fix for converted and won quotes
        if (
          this.dataFields.SBQQ__Status__c.value == "Won" &&
          this.dataFields.SBQQ_Status_Reason__c.value == "Converted"
        ) {
          this.showEditBtn = false;
        }
        this.recordDetails.Status = this.dataFields.SBQQ__Status__c.value; //Added as part of FRONT-22913
        this.recordDetails.recordTypeName =
        this.dataFields.Quote_Record_Type_Text__c.value; //Added as part of FRONT-22913
      } else if (this.objectApiName == "Order") {
        this.recordDetails.omsEnabled =
        this.dataFields.OMS_Sourcing_Enabled__c.value;  //SF-6835
        this.recordDetails.deliveryMethod =
          this.dataFields.Deliverymethod__c.value; //SF-6859
        this.recordDetails.deliveryMethodDisplay =
          this.dataFields.Deliverymethod__c.displayValue; //SF-6884
        this.recordDetails.originSystem =
          this.dataFields.Order_Initiating_Channel__c.value;
        // change for SAL-14196
        this.recordDetails.quoteSubmittedToWynne =
          this.dataFields.Quote_Submitted_to_Wynne__c.value;
        this.recordDetails.reservationOrderNumber =
          this.dataFields.Reservation_Order_Number__c.value;
        this.recordDetails.contractOrderNumber =
          this.dataFields.Contract_Order_Number__c.value;
        console.log("Entered before mapping");
        this.editOverrideCharge =
          this.dataFields.Delivery_Charges_Override__c.value;

          /* changes for FRONT-22246, FRONT-22247 by Chinmay Bhatkal */
        this.recordDetails.isInEditMode = (
          this.dataFields.Is_Edit_In_Progress__c.value && 
          this.dataFields.Is_Edited_By_Current_User__c.value
        );
          /* end FRONT-22246, FRONT-22247 */
        this.recordDetails.Status = this.dataFields.Status.value; //FRONT-8095
        this.recordDetails.recordTypeName =
        this.dataFields.Record_Type_Name__c.value; //FRONT-7977
      }
      if (!this.dataFields.Delivery_Charges_Override__c.value) {
        this.recordDetails.pickupCharges =
          this.recordDetails.totalSuggestedPickupCharge;
        this.recordDetails.deliveryCharges =
          this.recordDetails.totalSuggestedDeliveryCharge;
        console.log("Entered+");
      }
     


    } else if (error) {
      console.log("error seen on orderDeliveryCmp   " + error.body.message);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: ORDER_DELIVERY_METHOD
  })
  wiredDeliveryMethod({ error, data }) {
    if (data) {
      this.deliveryMethodPicklistValues = data.values;
    } else if (error) {
      console.error(JSON.stringify(error));
    }
  }

  setOrderRecordFields() {
    this.fields = [
      "Order.Delivery_Charge__c",
      "Order.Pickup_Charge__c",
      "Order.Total_Suggested_Delivery__c",
      "Order.Deliverymethod__c",
      "Order.Total_Weight__c",
      "Order.Total_Suggested_Pickup__c",
      "Order.Using_3rd_Party__c",
      "Order.Number_of_Trucks__c",
      "Order.Delivery_Charges_Override__c",
      "Order.Delivery_Charges__c",
      "Order.Pickup_Charges__c",
      "Order.Order_Initiating_Channel__c",
      "Order.Analysis_Region_Key__c",
      "Order.Quote_Submitted_to_Wynne__c",
      "Order.Reservation_Order_Number__c",
      "Order.Contract_Order_Number__c",
      "Order.Sourcing_Branch__c",
      "Order.Sourcing_Branch__r.Name",
      "Order.OMS_Sourcing_Enabled__c",
      "Order.Company_Code__c",
      "Order.Distance_to_Job_Site__c",
      "Order.Status", 
      "Order.Record_Type_Name__c",
      "Order.Is_Edit_In_Progress__c",
      "Order.Is_Edited_By_Current_User__c"
    ];
  }

  setQuoteRecordFields() {
    this.fields = [
      "SBQQ__Quote__c.Delivery_Charge__c",
      "SBQQ__Quote__c.Pickup_Charge__c",
      "SBQQ__Quote__c.Total_Suggested_Delivery__c",
      "SBQQ__Quote__c.SBQQ__DeliveryMethod__c",
      "SBQQ__Quote__c.Total_Weight__c",
      "SBQQ__Quote__c.Total_Suggested_Pickup__c",
      "SBQQ__Quote__c.Using_3rd_Party__c",
      "SBQQ__Quote__c.Number_of_Trucks__c",
      "SBQQ__Quote__c.Delivery_Charges_Override__c",
      "SBQQ__Quote__c.Delivery_Charges__c",
      "SBQQ__Quote__c.Pickup_Charges__c",
      "SBQQ__Quote__c.Quote_Initiating_Channel__c",
      "SBQQ__Quote__c.Analysis_Region_Key__c",
      "SBQQ__Quote__c.Submitted_to_Wynne__c",
      "SBQQ__Quote__c.Sourcing_Branch__c",
      "SBQQ__Quote__c.Sourcing_Branch__r.Name",
      "SBQQ__Quote__c.Branch__r.OMS_Sourcing_Enabled__c",
      "SBQQ__Quote__c.OMS_Sourcing_Enabled__c",
      "SBQQ__Quote__c.Company_Code__c",
      "SBQQ__Quote__c.Distance_to_Job_Site__c",
      "SBQQ__Quote__c.SBQQ__Status__c",
      "SBQQ__Quote__c.SBQQ_Status_Reason__c",
      "SBQQ__Quote__c.Quote_Record_Type_Text__c"//Added as part of FRONT-22913
    ];
  }

  connectedCallback() {
    console.log("objectApiName in connectedCallback -->", this.objectApiName);
    this.setAppName();
    this.deliverySectionClass =
      FORM_FACTOR === "Small"
        ? "slds-size--1-of-1 slds-m-vertical--xx-large"
        : "";
    if (this.recordId) {
      if (this.objectApiName == "SBQQ__Quote__c") {
        this.setQuoteRecordFields();
      } else if (this.objectApiName == "Order") {
        this.setOrderRecordFields();
      }
    }
  }

  renderedCallback() {
    if (this.recordDetails) {
      if (this.recordDetails.deliveryMethod == "Delivery") {
        this.showOnDelivery = true;
      } else {
        this.showOnDelivery = false;
      }
      let originSystem = this.recordDetails.originSystem;
      let thirdParty = this.recordDetails.using3rdParty;
      if (
        originSystem &&
        originSystem.toLowerCase() == "salesforce" &&
        thirdParty == false
      ) {
        this.showOnSalesforceOrigin = true;
      } else {
        this.showOnSalesforceOrigin = false;
      }
      let regionKey = this.recordDetails.analysisRegionKey;
      if (
        regionKey == "921" ||
        regionKey == "922" ||
        regionKey == "933" ||
        regionKey == "934" ||
        regionKey == "945"
      ) {
        this.showFields = true;
      } else {
        this.showFields = false;
      }

      if (this.objectApiName == "Order") {
        // change for SAL-14196
        if (
          this.recordDetails.quoteSubmittedToWynne ||
          (this.recordDetails.reservationOrderNumber &&
            this.recordDetails.reservationOrderNumber !== "") ||
          (this.recordDetails.contractOrderNumber &&
            this.recordDetails.contractOrderNumber !== "")
        ) {
          this.showEdit = false;
          this.readOnly = true;
          this.isEdit = false;
        }
      } else if (this.objectApiName == "SBQQ__Quote__c") {
        if (this.recordDetails.quoteSubmittedToWynne) {
          this.showEdit = false;
          this.readOnly = true;
          this.isEdit = false;
        }
      }
    }
  }

  handleSave() {
    const fields = {};
    if (this.objectApiName == "SBQQ__Quote__c") {
      fields[QUOTE_ID_FIELD.fieldApiName] = this.recordId;
      fields[QUOTE_DELIVERY_METHOD.fieldApiName] = this.template.querySelector(
        "[data-field='DeliveryMethod']"
      ).value;
      fields[QUOTE_SOURCING_BRANCH.fieldApiName] =
        this.recordDetails.sourcingBranch;
      if (this.recordDetails.deliveryMethod == "Delivery") {
        fields[QUOTE_THIRD_PARTY.fieldApiName] = this.template.querySelector(
          "[data-field='3rdParty']"
        )?.checked;
        if (this.recordDetails.using3rdParty == false) {
          fields[QUOTE_DELIVERY_CHARGES.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryCharges']"
            )?.value;
          fields[QUOTE_PICKUP_CHARGES.fieldApiName] =
            this.template.querySelector("[data-field='PickupCharges']")?.value;
          fields[QUOTE_DELIVERY_CHARGES_OVERRIDE.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryOverride']"
            )?.checked;
            fields[QUOTE_PICKUP_CHARGES_OVERRIDE.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryOverride']"
            )?.checked;
        }
        if (this.template.querySelector("[data-field='3rdParty']")?.checked) {
          // 3rd party flag = yes/true
          fields[QUOTE_PICKUP_CHARGES.fieldApiName] = 0;
          fields[QUOTE_DELIVERY_CHARGES.fieldApiName] = 0;
        }
      }
    } else if (this.objectApiName == "Order") {
      fields[ORDER_ID_FIELD.fieldApiName] = this.recordId;
      fields[ORDER_DELIVERY_METHOD.fieldApiName] = this.template.querySelector(
        "[data-field='DeliveryMethod']"
      ).value;
      fields[ORDER_SOURCING_BRANCH.fieldApiName] =
        this.recordDetails.sourcingBranch;
      if (this.recordDetails.deliveryMethod == "Delivery") {
        fields[ORDER_THIRD_PARTY.fieldApiName] = this.template.querySelector(
          "[data-field='3rdParty']"
        )?.checked;
        if (this.recordDetails.using3rdParty == false) {
          fields[ORDER_DELIVERY_CHARGES.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryCharges']"
            )?.value;
          fields[ORDER_PICKUP_CHARGES.fieldApiName] =
            this.template.querySelector("[data-field='PickupCharges']")?.value;
          fields[ORDER_DELIVERY_CHARGES_OVERRIDE.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryOverride']"
            )?.checked;
            fields[ORDER_PICKUP_CHARGES_OVERRIDE.fieldApiName] =
            this.template.querySelector(
              "[data-field='DeliveryOverride']"
            )?.checked;
        }
        if (this.template.querySelector("[data-field='3rdParty']")?.checked) {
          // 3rd party flag = yes/true
          fields[ORDER_DELIVERY_CHARGES.fieldApiName] = 0;
          fields[ORDER_PICKUP_CHARGES.fieldApiName] = 0;
        }
      }
    }
    console.log("fields-->" + JSON.stringify(fields));
    const recordInput = {
      fields: fields
    };

    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Record updated",
            variant: "success"
          })
        );
        this.isEdit = false;
        this.readOnly = true;
        this.showEdit = true;
        // Display fresh data in the form
        //return refreshApex(this.contact);
      })
      .catch((error) => {
        
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error updating record",
            message: error?.body?.message,
            variant: "error"
          })
        );
      });
  }

  handleCancel() {
    this.isEdit = false;
    this.showEdit = true;
    this.readOnly = true;
  }

  handleEdit() {
    this.isEdit = true;
    this.showEdit = false;
    this.readOnly = false;
  }

  handleBranchChange(event) {
    this.recordDetails.sourcingBranch = null;
    this.recordDetails.sourcingBranchName = "";
    if (event.detail.selectedRecord) {
      this.recordDetails.sourcingBranch = event.detail.selectedRecord.Id;
      this.recordDetails.sourcingBranchName = event.detail.selectedRecord.Name;
    }
  }

  get isOrder() {
    return this.objectApiName == "Order";
  }
  get isQuote() {
    return this.objectApiName == "SBQQ__Quote__c";
  }
  get showSourcingBranch() {
    console.log(
      "this.recordDetails.deliveryMethod 254" +
        this.recordDetails.deliveryMethod
    );
    console.log(
      "this.recordDetails.omsEnabled  255" + this.recordDetails.omsEnabled
    );
    return (
      this.recordDetails.deliveryMethod == "Customer Pickup" ||
      (this.recordDetails.deliveryMethod == "Delivery" &&
        this.recordDetails.omsEnabled == false)
    );
  }
  get locationWhereBranch() {
    return (
      "RecordType.Name = 'Branch' AND Company_Code__c = '" +
      this.recordDetails.companyCode +
      "'"
    );
  }
  overrideCharge(event) {
    this.editOverrideCharge = event.target.checked;
  }

 
 /*Start:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/
  updatesourcebranch(branchrecId, branchInfo){
    if (this.objectApiName == "Order") {
      /* Start: changes for FRONT-22246, FRONT-22247 by Chinmay Bhatkal */
      const ccAndBranchLocationNumber = branchInfo.locationId.split('-');
      getRelatedBranchLocation({ cc: ccAndBranchLocationNumber[0], branchNumber: ccAndBranchLocationNumber[1] })
        .then((data) => {
          console.log('getBranchData', JSON.stringify(data));
          this.recordDetails.sourcingBranch = data.Id;
          // this.recordDetails.sourcingBranchName = data.Name;
          const fields = {};
          fields[ORDER_ID_FIELD.fieldApiName] = this.recordId;
          fields[ORDER_SOURCING_BRANCH.fieldApiName] = this.recordDetails.sourcingBranch;
          const recordInput = {
            fields: fields
          };

          updateRecord(recordInput)
          .then(() => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "The new sourcing branch has been added to this reservation.",
                variant: "success"
              })
            );
            this.showRebalanceScreen = false;
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error updating record",
                message: "An error occurred while trying to update the source branch value.",
                variant: "error"
              })
            );
          });
        })
        .catch((error) => {
          console.log("Error while retrieving Location", JSON.stringify(error));
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error updating record",
              message: "An error occurred while trying to update the source branch value.",
              variant: "error"
            })
          );
        });

      }

      /* End: changes for FRONT-22246, FRONT-22247 by Chinmay Bhatkal */
  }
/*End:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/


  async setAppName() {
    this.appName = await appName;
  }

  render() {
    return this.isFrontlineApp ? FL_TEMPLATE : SAL_TEMPLATE;
  }

  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }

  get checkVisibility() {
    const validStatus = ["Draft", "Partially Filled", "Created"];
    console.log(
      "checkVisibility from orderDeliveryDetailsCmp",
      JSON.stringify(this.recordDetails),
      "this.recordDetails.Status: " +
        this.recordDetails.Status +
        "-" +
        this.objectApiName +
        "-" +
        this.appName +
        "-" +
        this.recordTypeName
    );

    /*   changes for FRONT-22246, FRONT-22247 by Chinmay Bhatkal 
      changing 'change source branch' button visibility criteria
       1. Order is in edit mode
       2. Order is being edited by the current user
       3. Sourcing Branch of the Order has omsEnabled set to False
       4. Order is in draft or partially filled or created status
    */

    if (
      this.objectApiName === "Order" &&
      this.appName === FL_APP_NAME &&
      this.recordTypeName === "Reservation Order" &&
      validStatus.includes(this.recordDetails.Status) && 
      this.recordDetails.isInEditMode
    ) {
      this.hasVisibility = true;
    } else {
      this.hasVisibility = false;
    }

    return this.hasVisibility;
  }

  closeModals() {
    this.showRebalanceScreen = false;
  }
  /* ----------  Start FRONT-8095 ----------- */
  openSourcingBranchModal() {
    this.showRebalanceScreen = true;
  }

  handleNotifyEvent(event) {
    console.log('Entered notifyevent execution'+ JSON.stringify(event.detail));
    /*Start:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/
    if (event.detail.eventType === "confirmsuccess") {
      let selectedSourceBranceId = event.detail.selectrowid;
      this.updatesourcebranch(selectedSourceBranceId, event.detail.selectedRow);      
    }
    else if(event.detail.eventType === "confirmpopup"){
      try{
        refreshApex(this.wiredRecordResult);
        this.closeModals();
      }catch(error){
        console.error('Error at isOrderItemNotBulk method:', error.message);
      }
      
    }
    /*End:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/
    else if (event.detail.eventType === "Close") {
        this.closeModals();
    }
  }
}