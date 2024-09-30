import { LightningElement, api } from "lwc";
import NO_CONTENT_TEMPLATE from "./noContent.html";
import NO_EVENT_TEMPLATE from "./noEvent.html";
const NO_CONTENT_VARIANT = "nocontent";
const NO_EVENT_VARIANT = "noevent";
export default class Sbr_3_0_illustrationCmp extends LightningElement {
  @api message = "Select a row to see relevant item information here.";
  @api variant = NO_CONTENT_VARIANT;

  isAvailability = false;
  isRates = true;
  isMobile = false;

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
  }

  render() {
    return this.variant === NO_EVENT_VARIANT
      ? NO_EVENT_TEMPLATE
      : NO_CONTENT_TEMPLATE;
  }
}