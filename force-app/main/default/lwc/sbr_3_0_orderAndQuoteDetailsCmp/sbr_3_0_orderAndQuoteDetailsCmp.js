import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//Current User Fields
import USER_ID from "@salesforce/user/Id";
import ANALYSIS_REGION_KEY_FIELD from "@salesforce/schema/User.Analysis_Region_Key__c";
import REP_TYPE_FIELD from "@salesforce/schema/User.Tech_Rep_Type__c";
import PROFILE_NAME_FIELD from "@salesforce/schema/User.Profile.Name";

//Labels
import systemAdminLabel from "@salesforce/label/c.SBR_3_0_SystemAdminProfil";
import businessAdminLabel from "@salesforce/label/c.SBR_3_0_BusinessAdminProfil";
import PPICC_Label from "@salesforce/label/c.SBR_3_0_PPICC_REP_TYPE";
import RecordAction from "@salesforce/messageChannel/RecordAction__c";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import {
  MessageContext,
  publish,
  subscribe,
  unsubscribe
} from "lightning/messageService";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry"; //FRONT-20091
const userFields = [
  REP_TYPE_FIELD,
  ANALYSIS_REGION_KEY_FIELD,
  PROFILE_NAME_FIELD
];
const SUBMITTED_ACTION = "submitted";
const SAVE_ACTION = "save";
const logger = Logger.create(true);
export default class Sbr_3_0_orderAndQuoteDetailsCmp extends LightningElement {
  //API
  @api recordId;
  @api objectApiName;
  @api isMobileRequestView = false;

  //Track
  @track isEdit = false;
  @track readOnly = true;
  @track showStandbyField = false;
  @track showSeasonalField = false;
  @track showContingencyField = false;
  @track showOrderDetails = false;
  @track showQuoteDetails = false;
  isLoaded = false;
  isLocked = false;
  showEdit = false;
  userFields = {};
  userId = USER_ID;
  repType;
  regionKey;
  profileName;
  orderRecordType;
  isEditMode = false;
  config = "Order_Option_Tab";
  //Labels
  label = {
    systemAdminLabel,
    businessAdminLabel,
    PPICC_Label
  };
  @wire(MessageContext)
  messageContext;
  subscription;
  //Get Order or Quote Record based on recordId
  @wire(getRecord, { recordId: "$recordId", fields: "$fields" })
  wiredRecord({ error, data }) {
    if (data) {
      console.log(" order data :  ", data);
      if (this.objectApiName == "SBQQ__Quote__c") {
        //Quote fields
      } else if (this.objectApiName == "Order") {
        this.orderRecordType = data.fields.Record_Type_Name__c.value;
        this.isLocked = data.fields.Record_Locked__c.value;
        this.isEditMode = data.fields.Is_Edit_In_Progress__c.value;
      }
      this.setEditVisibility();
    } else if (error) {
      console.log(
        "error seen on orderAndQuoteDetailsCmp   " + error.body.message
      );
    }
  }

  //Retrieve current User based on UserId
  @wire(getRecord, { recordId: "$userId", fields: userFields })
  currentUserInfo({ error, data }) {
    if (data) {
      this.regionKey = data.fields.Analysis_Region_Key__c.value;
      this.repType = data.fields.Tech_Rep_Type__c.value;
      this.profileName = getFieldValue(data, PROFILE_NAME_FIELD);

      this.setEditVisibility();
      this.setFieldsVisibility();
    } else if (error) {
      console.log(
        "error seen on orderAndQuoteDetailsCmp   " + error.body.message
      );
    }
  }

  //Set fields related to Order Object
  setOrderRecordFields() {
    this.fields = [
      "Order.Is_Edit_In_Progress__c",
      "Order.RPP__c",
      "Order.Apply_Standby_Rates__c",
      "Order.Contingency_Order__c",
      "Order.Seasonal_Order__c",
      "Order.Record_Locked__c",
      "Order.Record_Type_Name__c"
    ];
  }

  //Set fields related to Quote Object
  setQuoteRecordFields() {
    this.fields = [];
  }

  setEditVisibility() {
    if (this.objectApiName == "Order") {
      if (
        this.isLocked == false &&
        this.orderRecordType == "Reservation Order" &&
        this.isEditMode
      ) {
        //this.showEdit = true;
        this.isEdit = true;
        this.readOnly = false;
      } else {
        // this.showEdit = false;
        this.isEdit = false;
        this.readOnly = true;
      }
    }
  }

  connectedCallback() {
    this.subscribeToMessageChannel();

    if (this.recordId) {
      if (this.objectApiName == "Order") {
        this.setOrderRecordFields();
        this.showOrderDetails = true;
      } else if (this.objectApiName == "SBQQ__Quote__c") {
        this.setQuoteRecordFields();
        this.showQuoteDetails = true;
      }
    }
  }

  handleEdit() {
    this.isEdit = true;
    this.showEdit = false;
    this.readOnly = false;
  }

  handleCancel() {
    this.isEdit = false;
    this.showEdit = true;
    this.readOnly = true;
  }

  handleSubmit(event) {
    try {
      // stop the form from submitting
      event.preventDefault();

      //get all the fields
      const fields = event.detail.fields;
      // let fields = event.detail.fields;
      //FRONT-1635
      publish(
        this.messageContext,
        RecordAction,
        this.buildRecordActionPayload(SUBMITTED_ACTION, {
          fields
        })
      );
    } catch (e) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error updating record",
          message: error?.body?.message,
          variant: "error"
        })
      );
      this.isLoaded = false;
    }
  }

  handleSuccess(event) {
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
    this.isLoaded = false;
  }

  setFieldsVisibility() {
    if (this.objectApiName == "Order") {
      console.log(
        " profiles : " +
          this.label.systemAdminLabel +
          " - " +
          this.label.businessAdminLabel
      );
      // change for SAL-23907
      if (
        this.regionKey == "922" ||
        this.regionKey == "941" ||
        this.profileName == this.label.systemAdminLabel ||
        this.profileName == this.label.businessAdminLabel ||
        this.repType?.includes("Strategic") ||
        this.repType?.includes("Market ")
      ) {
        this.showStandbyField = true;
        this.showContingencyField = true;
      } else {
        this.showStandbyField = false;
        this.showContingencyField = false;
      }

      if (
        this.regionKey == "922" ||
        this.regionKey == "934" ||
        this.profileName == this.label.systemAdminLabel ||
        this.profileName == this.label.businessAdminLabel ||
        this.repType?.includes("Strategic") ||
        this.repType?.includes("Market ") ||
        this.repType == this.label.PPICC_Label
      ) {
        this.showSeasonalField = true;
      } else {
        this.showSeasonalField = false;
      }
    } else if (this.objectApiName == "SBQQ__Quote__c") {
      //Add Criteria to display Quote fields
    }
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        RecordAction,
        (message) => this.handleMessage(message)
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  buildRecordActionPayload(action, _params, origin = this.config) {
    let payload = {
      action,
      params: _params,
      origin
    };

    return payload;
  }
  handleMessage(message) {
    logger.log(
      "#### Subscribe in the Order and Quote detalils",
      message.origin,
      message.action
    );
    let action = message.action;
    switch (action) {
      case SAVE_ACTION:
        this.handleSave();
        break;
      default:
        logger.log("Not a valid action");
    }
  }
  handleSave() {
    this.template.querySelector(".btnclass")?.click();
  }
  //FRONT-20091,20092 Starts
  handleChange(event){
    FORM_STORE.updatedRecords[this.recordId][event.target.fieldName] = event.target.value;
  //FRONT-20091,20092 Ends
  }
}