import { LightningElement, wire } from "lwc";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import {
  DynamicRecordFormMixin,
  isMobile
} from "c/sbr_3_0_dynamicRecordFormUtility"; //FRONT-20769
import { Logger, isArray } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

const OBJECT_API_NAME_TO_CONTACT_RELATIONSHIP = {
  Order: "Jobsite_Contact__r",
  SBQQ__Quote__c: "SBR_Job_Site_Contact__r"
};
const DEFAULT_BTN_ICON_CLASS = "slds-m-top_medium";

export default class Sbr_3_0_drfJobSiteContactLookupWrapper extends DynamicRecordFormMixin(
  LightningElement
) {
  orderedByWhere;
  showNewContactButton = false;
  appName = FORM_STORE.appName;
  contactId;
  isMobile = isMobile;
  disableEditInfo = false;
  showEditBtnScreen = false;
  subscription = null;
  classesToAdd = "";
  labelPaddingJobsite = "";
  get btnIconClass() {
    return this.disableEditInfo
      ? DEFAULT_BTN_ICON_CLASS + " btn-icon-disabled-class"
      : DEFAULT_BTN_ICON_CLASS + " btn-icon-enabled-class";
  }
  //END : FRONT-20769

  connectedCallback() {
    let contactRelationshipName =
      OBJECT_API_NAME_TO_CONTACT_RELATIONSHIP[this.objectApiName];
    logger.log(
      this.recordId,
      "====formstore===",
      JSON.stringify(FORM_STORE.records),
      "===",
      contactRelationshipName
    );
    let contact =
      FORM_STORE.records[this.recordId]?.fields?.[contactRelationshipName]
        ?.value;
    this.contactId = contact?.id;
    this.classesToAdd = "greyBorderCon";
    this.labelPaddingJobsite = "labelPaddingJobsite";
    this.registerListeners(this.handleMessage);
  }

  handleMessage(message) {
    try {
      let payload = message.detail || message;
      console.log("Payload", payload);
      let field = isArray(payload)
        ? payload.filter(
            (payloadField) => payloadField.apiName === this.field.apiName
          )?.[0]
        : payload;
      if (field && field.apiName === this.field.apiName) {
        this.contactId = field.value;
      }
    } catch (error) {
      logger.log(
        "Error in Sbr_3_0_drfContactLookupWrapper " + JSON.stringify(error)
      );
    }
  }
}