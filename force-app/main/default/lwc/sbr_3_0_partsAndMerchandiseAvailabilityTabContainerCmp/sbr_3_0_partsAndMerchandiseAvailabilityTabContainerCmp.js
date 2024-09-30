import { LightningElement, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

export default class Sbr_3_0_partsAndMerchandiseAvailabilityTabContainerCmp extends LightningElement {
  _variant = "";
  _hideSearch = false;
  computedClass;
  itemComputedClass;
  containerComputedClass;

  @api
  get variant() {
    return this._variant;
  }
  set variant(value) {
    this._variant = value;
  }

  @api searchPlaceholderLabel;
  @api containerSubtitle;

  @api
  get hidesearch() {
    return this._hideSearch;
  }
  set hidesearch(value) {
    this._hideSearch = value === "true" ? true : false;
  }

  connectedCallback() {
    //code
    this.computedClass = FORM_FACTOR === "Small" ? "slds-p-top_small" : "";
    this.itemComputedClass =
      FORM_FACTOR !== "Small"
        ? "slds-p-left_small slds-p-top_small"
        : "slds-p-left_small";
    this.containerComputedClass =
      FORM_FACTOR === "Small"
        ? "slds-var-p-top_small slds-m-left_small slds-m-right_small"
        : "slds-var-p-top_small";
  }

  handleValueChange(event) {
    let sBoxInp = event.target.value;
    const searchBoxChangeEvent = new CustomEvent("searchboxchangeevt", {
      detail: {
        variant: this._variant,
        searchQuery: sBoxInp
      }
    });
    this.dispatchEvent(searchBoxChangeEvent);
  }

  handleKeyPress(event) {
    if (event.keyCode === 13) {
      const searchBoxField = this.template.querySelector(
        ".searchBoxFieldClass"
      );
      searchBoxField.blur();
    }
  }

  @api
  resetSearchBox() {
    const searchBoxField = this.template.querySelector(".searchBoxFieldClass");
    if (searchBoxField) {
      searchBoxField.value = null;
    }
  }
}