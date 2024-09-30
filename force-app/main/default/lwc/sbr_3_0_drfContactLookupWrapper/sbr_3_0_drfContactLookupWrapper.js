import { LightningElement, wire } from "lwc";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import {
  DynamicRecordFormMixin,
  isMobile
} from "c/sbr_3_0_dynamicRecordFormUtility"; //FRONT-20769
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
const OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP = {
  Order: "Account",
  SBQQ__Quote__c: "SBQQ__Account__r"
};

const OBJECT_API_NAME_TO_CONTACT_RELATIONSHIP = {
  Order: "Order_By__r",
  SBQQ__Quote__c: "Ordered_by__r"
};
const OBJECT_API_NAME_TO_ACCOUNT_FIELD = {
  Order: "AccountId",
  SBQQ__Quote__c: "SBQQ__Account__c"
};
const DEFAULT_BTN_ICON_CLASS = "slds-m-top_medium"; // FRONT-20769

export default class Sbr_3_0_drfContactLookupWrapper extends DynamicRecordFormMixin(
  LightningElement
) {
  orderedByWhere;
  showNewContactButton = false;
  accountId;
  orderedBy;
  appName = FORM_STORE.appName;
  //START : FRONT-20769
  contactId;
  isMobile = isMobile;
  disableEditInfo = false;
  showEditBtnScreen = false;
  subscription = null;
  lookupWrapperSize = 12;
  showEditButtons = false;
  recordTypeName = "";
  get btnIconClass() {
    return this.disableEditInfo
      ? DEFAULT_BTN_ICON_CLASS + " btn-icon-disabled-class"
      : DEFAULT_BTN_ICON_CLASS + " btn-icon-enabled-class";
  }
  //END : FRONT-20769

  connectedCallback() {
    // Get Account Id
    let accountRelationshipName =
      OBJECT_API_NAME_TO_ACCOUNT_RELATIONSHIP[this.objectApiName];
    let account =
      FORM_STORE.records[this.recordId]?.fields?.[accountRelationshipName]
        ?.value;
    this.accountId = account?.fields?.Id.value;

    // Get Contact Id

    let contactRelationshipName =
      OBJECT_API_NAME_TO_CONTACT_RELATIONSHIP[this.objectApiName];
    let contact =
      FORM_STORE.records[this.recordId]?.fields?.[contactRelationshipName]
        ?.value;
    this.contactId = contact?.fields?.Id.value; //FRONT-20769
    if (contact) this.orderedBy = contact?.fields?.Id.value;
    this.registerListeners(this.handleMessage);
    this.orderedByWhere = this.buildDefaultQuery();
    this.recordTypeName = FORM_STORE.records[this.recordId].recordTypeInfo.name; // FRONT-20769
    if (this.appName === "RAE Frontline") {
      this.showNewContactButton = true;
      this.lookupWrapperSize = this.recordTypeName === "Create Contract" ? 10 : 12; // FRONT-20769
      this.showEditButtons = this.recordTypeName === "Create Contract"; // FRONT-20769
    }
  }

  buildDefaultQuery() {
    return "AccountId = '" + this.accountId + "'";
  }

  handleOrderedByChange(event) {
    logger.log("selectedRecord::" + JSON.stringify(event.detail.selectedRecord));
    if (event.detail.selectedRecord === undefined) {
      this.disableEditInfo = true;
    } else {
      this.disableEditInfo = false;
    }
    this.publishEvent(event);
    // FRONT-20769
    this.contactId = event.detail.selectedRecord
      ? event.detail.selectedRecord.Id
      : null;
  }

  publishEvent(event) {
    let selectedValue = [
      {
        apiName: this.field.apiName,
        value: event.detail.selectedRecord
          ? event.detail.selectedRecord.Id || event.detail.selectedRecord.id
          : undefined
      }
    ];
    this.orderedBy =
      event.detail.selectedRecord?.Id || event.detail.selectedRecord?.id;
    this.orderedByWhere = this.buildDefaultQuery();
    this.updateDRFFieldUpdate(selectedValue);
  }

  handleMessage(message) {
    try {
      if (
        message.apiName ===
          OBJECT_API_NAME_TO_ACCOUNT_FIELD[this.objectApiName] &&
        message.value
      ) {
        this.accountId = message.value;
        this.orderedBy = null;
        this.template
          .querySelector("c-s-b-r_3_0_required-custom-lookup-cmp")
          .handleRemove();
      }
      this.orderedByWhere = this.buildDefaultQuery();
    } catch (error) {
      logger.log(
        "Error in Sbr_3_0_drfContactLookupWrapper " + JSON.stringify(error)
      );
    }
  }
  handleEnterKey(event) {
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  }

  //START : FRONT-20769
  handleEdit() {
    if (isMobile && this.disableEditInfo) return;
    this.showEditBtnScreen = true;
    this.orderedBy = null;
  }

  closeModal(event) {
    this.showEditBtnScreen = false;
  }
  //END : FRONT-20769

  handleSubmitChange(event) {
    logger.log('in submit', event.detail.selectedRecord)
    this.orderedBy = event.detail.selectedRecord?.Id || event.detail.selectedRecord?.id;
    this.showEditBtnScreen = false;
  }
}