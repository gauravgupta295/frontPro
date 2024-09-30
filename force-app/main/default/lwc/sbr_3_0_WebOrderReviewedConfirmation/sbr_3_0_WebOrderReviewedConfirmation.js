import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import EMAIL_FIELD from "@salesforce/schema/Order.Email__c";
import CUSTOMER_NAME_FIELD from "@salesforce/schema/Order.Account.Name";
import PHONE_FIELD from "@salesforce/schema/Order.Phone__c";
import REVIEWED_FIELD from "@salesforce/schema/Order.Reviewed__c";
import { getFieldValue, getRecord, updateRecord } from "lightning/uiRecordApi";
import { CloseActionScreenEvent } from "lightning/actions";
export default class Sbr_3_0_WebOrderReviewedConfirmation extends LightningElement {
  @api recordId;
  @api objectApiName;
  label = LABELS;
  REVIEWED_YES = "Yes";
  showSpinner = false;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [EMAIL_FIELD, PHONE_FIELD, CUSTOMER_NAME_FIELD]
  })
  order;

  get email() {
    return getFieldValue(this.order.data, EMAIL_FIELD);
  }

  get customerName() {
    return getFieldValue(this.order.data, CUSTOMER_NAME_FIELD);
  }

  get phone() {
    return getFieldValue(this.order.data, PHONE_FIELD);
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  confirmReservation() {
    this.showSpinner = true;
    const fields = {};

    fields[REVIEWED_FIELD.fieldApiName] = this.REVIEWED_YES;

    const recordInput = {
      fields: fields,
      recordId: this.recordId,
      Object: this.order
    };

    updateRecord(recordInput)
      .then(() => {
        this.showSpinner = false;
        this.closeModal();
        this.dispatchEvent(
          new ShowToastEvent({
            title:
              "The Reservation has been successfully marked as reviewed. Please verify customer’s ID prior to submitting a contract.",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        console.error(error);
        this.closeModal();
        this.dispatchEvent(
          new ShowToastEvent({
            title: "An error occurred. Please contact System Administrator. ",
            variant: "error"
          })
        );
      });
  }
}