import { LightningElement, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import LABELS from "c/sbr_3_0_customLabelsCmp";

import ACCOUNT_PARENTID_FIELD from "@salesforce/schema/Account.ParentId";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";

import { CloseActionScreenEvent } from "lightning/actions";

import FORM_FACTOR from "@salesforce/client/formFactor";
const SMALL_FORM_FACTOR = "Small";
import DESKTOP_TEMPLATE from "./sbr_3_0_createSalesQuoteFromAccount_Dekstop/sbr_3_0_createSalesQuoteFromAccountDesktop.html";
import MOBILE_TEMPLATE from "./sbr_3_0_createSalesQuoteFromAccount_Mobile/sbr_3_0_createSalesQuoteFromAccountMobile.html";

export default class Sbr_3_0_createSalesQuoteFromAccount extends LightningElement {
  @api recordId;
  @api objectApiName;
  label = LABELS;
  recordType = "Sales_Quote";

  recordTypePage = true;
  customerInfoPage = false;

  accountId;
  orderedby;
  accountIdMissing;
  orderedByMissing;
  accountParentId;
  accountName;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [ACCOUNT_PARENTID_FIELD, ACCOUNT_NAME_FIELD]
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.accountParentId = data.fields.ParentId.value;
      this.accountName = data.fields.Name.value;
      this.accountId = this.recordId;
    } else if (error) {
      console.log("Error loading record", error);
    }
  }

  closeRecordTypePage() {
    this.recordTypePage = false;
    this.openCustomerInfoPage();
  }
  openCustomerInfoPage() {
    this.customerInfoPage = true;
  }

  handleRecordTypeChange(event) {
    this.recordType = event.detail;
  }

  handleAccountChange(event) {
    this.accountId = event.detail;
  }

  handleOrderedByChange(event) {
    this.orderedby = event.detail;
  }

  goBackToRecordType(){

    this.recordTypePage = true;
    this.customerInfoPage = false;
  }

  closeCustomerInfoPage() {
    if (!this.accountId) {
      this.accountIdMissing = true;
    }
    if (!this.orderedby) {
      this.orderedByMissing = true;
    }
    if (this.accountId) {
      this.accountIdMissing = false;
    }
    if (this.orderedby) {
      this.orderedByMissing = false;
    }
    if (this.accountId && this.orderedby) {
      this.customerInfoPage = false;
    }
  }

  get isMobile() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  } 

  render() {
    let renderTemplate;
    if (this.isMobile) {
        renderTemplate = MOBILE_TEMPLATE;
    }
    else{
        renderTemplate = DESKTOP_TEMPLATE;          
    }
    return renderTemplate;
}

closeModal() {
  this.dispatchEvent(new CloseActionScreenEvent());
  this.closeAuraAction(); //Added as part of the story#FRONT - 17780 by Gopal Raj
}

/*Start: Added as part of the story#FRONT - 17780 by Gopal Raj*/
closeAuraAction() {
    this.dispatchEvent(new CustomEvent("closeauraaction"));
  } 

}