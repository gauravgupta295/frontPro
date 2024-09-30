import { LightningElement, api } from "lwc";

export default class Sbr_3_0_inlineErrorCard extends LightningElement {
  @api title;
  @api message;
  @api variant;

  isError;
  isInfo;

  connectedCallback() {
    if (this.variant === "Info") {
      this.isInfo = true;
    } else if (this.variant === "Error") {
      this.isError = true;
    }
  }

  get styleClass() {
    let color = "";
    if (this.isError) {
      color = "slds-theme_error";
    } else if (this.isInfo) {
      color = "slds-theme_info";
    }
    return `slds-notify slds-notify_toast sbr_inline-error ${color}`;
  }
}