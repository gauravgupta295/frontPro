import { LightningElement, api } from "lwc";

export default class Sbr_3_0_customQuantityForDataTable extends LightningElement {
  @api quantity;
  @api isEditable;
  @api createdQuantity;
  @api pickupQuantity;
  @api itemRecord;

  connectedCallback() {
    console.log("=========== Quantity -> connected callback, ");
  }
  handleQuantityChange(event) {
    console.log("event:", event.target.value);
    console.log('thiseventrecord',this.itemRecord);
      this.dispatchEvent(
        new CustomEvent("quantitychange", {
          composed: true,
          bubbles: true,
          cancelable: true,
          detail: { recordId: this.itemRecord, value: event.target.value }
        })
      );
  }
}