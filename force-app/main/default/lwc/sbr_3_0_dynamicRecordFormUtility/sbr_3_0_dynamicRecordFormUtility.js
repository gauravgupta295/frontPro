import FORM_FACTOR from "@salesforce/client/formFactor";
import { api, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import {
  fireEvent,
  registerListener,
  unregisterAllListeners
} from "c/sbr_3_0_pubsub";
import { isArray } from "c/sbr_3_0_frontlineUtils";

const DynamicRecordFormMixin = (Base) => {
  return class extends Base {
    @wire(CurrentPageReference) pageRef;

    @api field;
    @api recordId;
    @api objectApiName;
    registerListener(listenTo, listener) {
      registerListener(listenTo, listener, this);
    }

    registerListeners(listener) {
      if (this.field?.listenTo) {
        for (let listenTo of this.field.listenTo) {
          this.registerListener(listenTo, listener);
        }
      }
    }

    publishChange(
      channel = this.field.externalId,
      payload = `Fired by ${this.field.externalId}`,
      forcePush = false
    ) {
      if (this.field?.allowedToDispatch || forcePush) {
        fireEvent(this.pageRef, channel, payload);
      }
    }

    unregisterAllListeners() {
      unregisterAllListeners(this);
    }

    updateDRFFieldUpdate(payload) {
      this.dispatchEvent(
        new CustomEvent("drf_fieldchange", {
          detail: payload,
          bubbles: true,
          composed: true
        })
      );
    }

    getMessagePayload(message) {
      let payload = message.detail || message;
      let field = isArray(payload)
        ? payload.filter(
            (payloadField) => payloadField.apiName === this.field.apiName
          )?.[0]
        : payload;

      return field;
    }
  };
};
const SMALL_FORM_FACTOR = "Small";
const isMobile = FORM_FACTOR === SMALL_FORM_FACTOR;
const ACCORDION_VIEW = "Accordion";

export { isMobile, DynamicRecordFormMixin, ACCORDION_VIEW };