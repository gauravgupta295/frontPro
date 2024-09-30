import { LightningElement, api } from "lwc";
import {
  FlowNavigationFinishEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";

export default class Sbr_3_0_customFlowFooterCmp extends LightningElement {
  @api availableActions = [];
  hasCancel = true;
  hasSave = true;

  saveHandler(event) {
    event.preventDefault();
    if (this.availableActions.find((action) => action === "NEXT")) {
      console.log("Inside Next Btm Method");
      const navigationNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigationNextEvent);
    }
  }

  cancelClickHandler(event) {
    event.preventDefault();
    const cancelEvent = new CustomEvent("cancelbutton", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(cancelEvent);
  }
}