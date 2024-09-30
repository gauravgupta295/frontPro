import { LightningElement, api } from "lwc";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_selectSalesQuoteRecordType extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api defaultRecordType;
  label = LABELS;

  get options() {
    return [
      { label: "Equipment and Parts/Merch", value: "Sales_Quote" },
      { label: "Parts/Merch", value: "Parts_Merchandise" }
    ];
  }

  handleChange(event) {
    const selectedRecordType = new CustomEvent("recordtypechange", {
      detail: event.target.value
    });
    this.dispatchEvent(selectedRecordType);
  }
}