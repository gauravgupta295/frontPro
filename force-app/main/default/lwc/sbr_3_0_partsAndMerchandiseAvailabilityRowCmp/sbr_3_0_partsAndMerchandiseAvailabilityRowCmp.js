import { LightningElement, api } from "lwc";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
export default class Sbr_3_0_partsAndMerchandiseAvailabilityRowCmp extends LightningElement {
  @api rowData;
  @api rowKey;
  @api callingFrom;
  isInModal;
  branchLocation;
  labelDesc;

  get rowItem() {
    let item = this.rowData[this.rowKey];
    if (
      this.rowKey === "label" &&
      this.rowData[this.rowKey]?.includes("Branch") &&
      this.isInModal === false
    ) {
      item = this.rowData[this.rowKey];
      this.branchLocation = true;
      this.labelDesc = this.rowData?.labelDesc;
    } else {
      item = this.rowKey !== "label" && item !== "N/A" ? item : item;
      this.branchLocation = false;
    }
    return item;
  }

  connectedCallback() {
    this.isInModal = this.callingFrom === "modal";
  }
}