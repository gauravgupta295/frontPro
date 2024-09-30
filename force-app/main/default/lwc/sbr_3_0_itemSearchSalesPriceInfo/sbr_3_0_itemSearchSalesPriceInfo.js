import { LightningElement, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";

export default class Sbr_3_0_itemSearchSalesPriceInfo extends LightningElement {
  @api costPrice;
  @api salesPrice;
  @api productType;////FRONT-14358,14357,14356

  isMobile;

  connectedCallback() {
    console.log('productType from itemSearch: '+this.productType);
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
  }

  toggleSection(event) {
    let buttonid = event.currentTarget.dataset.buttonid;
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    );
    if (currentsection.className.search("slds-is-open") == -1) {
      currentsection.className = "slds-section slds-is-open";
    } else {
      currentsection.className = "slds-section slds-is-close";
    }

    let pricingDetailSection = this.template.querySelector(".pricingDetails");
    pricingDetailSection.classList.toggle("slds-hide");
  }
  get priceTextClass() {
    return this.isMobile
      ? "slds-col slds-size_3-of-5 slds-p-around_x-small priceFont"
      : "slds-col slds-size_3-of-5 slds-p-top_x-small slds-p-left_small";
  }
  get priceValueClass() {
    return this.isMobile
      ? "slds-col slds-size_2-of-5 slds-p-top_small slds-p-around_x-small"
      : "slds-col slds-size_2-of-5 slds-p-around_x-small slds-p-left_small pricingValue";
  }
}