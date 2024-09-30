import { LightningElement, wire } from "lwc";
import { DynamicRecordFormMixin } from "c/sbr_3_0_dynamicRecordFormUtility";
import RecordAction from "@salesforce/messageChannel/RecordAction__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  MessageContext,
  publish,
  subscribe,
  unsubscribe
} from "lightning/messageService";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import LABELS from "c/sbr_3_0_customLabelsCmp";
const SUBMITTED_ACTION = "submitted";
const SAVE_ACTION = "save";
const logger = Logger.create(true);

export default class Sbr_3_0_updateDeliveryChargeOnCreateContractCmp extends DynamicRecordFormMixin(
  LightningElement
) {
  disableChargeFields = true;

  @wire(MessageContext)
  messageContext;
  subscription;

  config = "Contract_Order_Delivery_Tab";
  helpTextLabelDeliveryOverride =
    LABELS.DELIVERY_CHARGE_OVERRIDE_FIELD_LEVEL_HELP;

  connectedCallback() {
    this.subscribeToMessageChannel();
  }
  handleCheckBoxChange(event) {
    console.log("@@@@@@@ >> " + JSON.stringify(event.target.value));
    this.disableChargeFields = !event.target.value;
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

  handleSubmit(event) {
    try {
      // stop the form from submitting
      event.preventDefault();

      //get all the fields
      const fields = event.detail.fields;
      publish(
        this.messageContext,
        RecordAction,
        this.buildRecordActionPayload(SUBMITTED_ACTION, {
          fields
        })
      );
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error updating record",
          message: error?.body?.message,
          variant: "error"
        })
      );
    }
  }
  buildRecordActionPayload(action, _params, origin = this.config) {
    let payload = {
      action,
      params: _params,
      origin
    };

    return payload;
  }

  handleSave() {
    this.template.querySelector(".btnclass")?.click();
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
}