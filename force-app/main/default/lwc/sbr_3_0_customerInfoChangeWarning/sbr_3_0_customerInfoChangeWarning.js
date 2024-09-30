import { LightningElement, api } from "lwc";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import MobileTemplate from "./sbr_3_0_customerInfoChangeWarningMobile.html";
import DesktopTemplate from "./sbr_3_0_customerInfoChangeWarning.html";
import FORM_FACTOR from "@salesforce/client/formFactor";
export default class Sbr_3_0_customerInfoChangeWarning extends LightningElement {
  label = LABELS;
  @api objectLabel;
  isMobile = false;
  //props = { footerClasses: "slds-grid slds-grid_align-spread" };
  get WarningMessageHeading() {
    return this.label.MSG_FOR_CUST_INFO_CHANGE_WARNING.replaceAll(
      "{ObjectLabel}",
      this.objectLabel
    );
  }
  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
  }
  closeModal() {
    const closeWarning = new CustomEvent("handlewarningclose", {
      detail: "close"
    });
    this.dispatchEvent(closeWarning);
  }
  confirmModal() {
    const closeWarning = new CustomEvent("handlewarningclose", {
      detail: "confirm"
    });
    this.dispatchEvent(closeWarning);
  }
  render() {
    let templateToRender;
    if (this.isMobile) {
      templateToRender = MobileTemplate;
    } else {
      templateToRender = DesktopTemplate;
    }
    return templateToRender;
  }

  renderedCallback() {
    if (!this.isMobile && this.isContract) {
      let headerCmp = this.template.querySelector(".slds-modal__header");
      let footerCmp = this.template.querySelector(".slds-modal__footer");
      let contentCmp = this.template.querySelector(".slds-modal__content");
      let containerDiv = this.template.querySelector(".slds-modal__container");
      headerCmp.classList.add("footerHeader");
      footerCmp.classList.add("footerHeader");
      contentCmp.classList.add("content");
      containerDiv.classList.add("container");
    }
  }

  get isContract() {
    return this.objectLabel == "Contract" ? true : false;
  }
}