import { LightningElement, api, track } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

export default class Sbr_3_0_partsAndMerchandiseAvailabilityTable extends LightningElement {
  @track columnData;
  @track rowData;

  @api callingFrom;
  isInModal;
  isMobile;

  @api
  get columns() {
    return this.columnData;
  }
  set columns(value) {
    this.columnData = value;
  }

  @api
  get rows() {
    return this.rowData;
  }
  set rows(value) {
    this.rowData = value;
  }

  connectedCallback() {
    this.isInModal = this.callingFrom === "modal";
    this.isMobile = FORM_FACTOR === "Small";
  }

  handleRowClicked(evt) {
    if (!this.isInModal) {
      this.dispatchEvent(
        new CustomEvent("openavailabilitymodal", {
          detail: evt.currentTarget.dataset.id
        })
      );
    }
  }

  get headerClass() {
    if (this.isMobile || !this.isInModal) {
      return "header-row";
    }
    return "header-row2";
  }

  get columnStyle() {
    return this.isInModal ? "columnsModal slds-text-color_weak" : "columns";
  }
}