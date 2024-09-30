import { LightningElement, api } from "lwc";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_createQuoteFromAccountCompanyInfo extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api parentId;
  @api accountName;
  label = LABELS;

  accountId;
  isChangeAccount = false;
  isAccountSelected = true;
  isOrderedByButtonDisabled = true;
  officeAccountId;
  orderedBy;
  contactId;
  officeId;

  accountWhere =
    "Show_Create_Quote__c = true AND Allowed_to_Create_Quote__c = true AND IsCompanyCodeEqualsUserCompanyCode__c = true";
  accountWhereClause =
    "Show_Create_Quote__c = true AND Allowed_to_Create_Quote__c = true AND IsCompanyCodeEqualsUserCompanyCode__c = true AND RecordType.Name != 'Office'";
  officeWhereClause;
  orderedByWhere;

  connectedCallback() {
    this.orderedByWhere = "Account.Id = '" + this.recordId + "'";
    this.officeWhereClause =
      "Account.ParentId ='" + this.recordId + "' AND " + this.accountWhere;
  }

  handleAccountChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.isChangeAccount = true;
      this.accountId = event.detail.selectedRecord.Id;
      this.isAccountSelected = true;
      this.orderedByWhere = "Account.Id = '" + this.accountId + "'";
      this.officeWhereClause =
        "ParentId ='" + this.accountId + "' AND " + this.accountWhere;
    } else {
      this.isAccountSelected = false;
      this.isChangeAccount = false;
      this.isOrderedByButtonDisabled = true;
      this.accountId = "";
      this.officeAccountId = "";
      this.orderedBy = "";
      this.contactId = this.orderedBy;
    }

    const selectedAccount = new CustomEvent("accountchange", {
      detail: this.accountId
    });
    this.dispatchEvent(selectedAccount);
  }

  handleOrderedByChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.orderedBy = event.detail.selectedRecord.Id;
      this.isOrderedByButtonDisabled = false;
      this.contactId = this.orderedBy;
      console.log("Selected Contact: ", this.orderedBy);
    } else {
      this.orderedBy = "";
      this.contactId = this.orderedBy;
      this.isOrderedByButtonDisabled = true;
    }

    const selectedOrderedBy = new CustomEvent("orderedbychange", {
      detail: this.orderedBy
    });
    this.dispatchEvent(selectedOrderedBy);
  }

  handleOfficeAccountChange(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.officeAccountId = event.detail.selectedRecord.Id;
      this.officeId = this.officeAccountId;
      console.log("Selected Office Account: ", this.officeAccountId);
    } else {
      this.officeAccountId = "";
      this.officeId = this.officeAccountId;
    }
  }
}