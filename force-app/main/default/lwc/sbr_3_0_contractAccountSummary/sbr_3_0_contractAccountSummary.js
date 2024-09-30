import { LightningElement, track, wire, api } from "lwc";
import getColumns from "@salesforce/apex/SBR_3_0_CustomDataTableUtility.getColumns";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { DynamicRecordFormMixin } from "c/sbr_3_0_dynamicRecordFormUtility";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import BILLING_STREET_FIELD from "@salesforce/schema/Account.BillingStreet";
import BILLING_CITY_FIELD from "@salesforce/schema/Account.BillingCity";
import BILLING_STATE_FIELD from "@salesforce/schema/Account.BillingState";
import BILLING_ZIPCODE_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import BILLING_COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountry";

export default class sbr_3_0_ContractAccountSummary extends DynamicRecordFormMixin(
  LightningElement
) {
  columns = [];
  @track recordsToDisplay;
  contract;
  accountId;
  jobSiteAddress;
  accountPhone;
  billingAddress;
  accountRecType;
  config;
  accfields = [NAME_FIELD];

  @wire(getRecord, {
    recordId: "$accountId",
    fields: [
      PHONE_FIELD,
      BILLING_STREET_FIELD,
      BILLING_CITY_FIELD,
      BILLING_STATE_FIELD,
      BILLING_ZIPCODE_FIELD,
      BILLING_COUNTRY_FIELD
    ]
  })
  fetchAcc({ error, data }) {
    if (data) {
      this.accountPhone = data?.fields?.Phone?.value;
      this.billingAddress =
        data?.fields?.BillingStreet?.value +
        "," +
        data?.fields?.BillingCity?.value +
        "," +
        data?.fields?.BillingState?.value +
        "," +
        data?.fields?.BillingPostalCode?.value +
        "," +
        data?.fields?.BillingCountry?.value;
      this.buildRecords();
    } else if (error) {
      console.log("Error is" + JSON.stringify(error));
    }
  }

  connectedCallback() {
    this.contract = FORM_STORE.records[this.recordId];
    this.accountId = this.contract?.fields?.Account?.value?.id;
    this.accountRecType =
      this.contract?.fields?.Account?.value?.recordTypeInfo?.name;
    if (this.accountRecType === "Non-Credit") {
      this.config = "Cont_Acc_Summary_NC";
    } else if (this.accountRecType === "Credit") {
      this.config = "Cont_Acc_Summary_Credit";
    }
    this.jobSiteAddress = this.contract?.fields?.Job_Location__c?.value;
    getColumns({ context: "Contract Account Summary" })
      .then((data) => {
        if (data) {
          let itemSearchCols = [...data];
          itemSearchCols.sort((a, b) => a.Order__c - b.Order__c);
          itemSearchCols.forEach((col) => {
            let colItem = {};
            colItem.hideDefaultActions = true;
            colItem.sortable = col.IsSortable__c;
            colItem.wrapText = true;
            colItem.label = col.Label;
            colItem.fieldName = col.Field_Name__c;
            if (col.fixedWidth__c) {
              colItem.fixedWidth = col.fixedWidth__c;
            }
            if (colItem.fieldName == "accountName") {
              colItem.type = "recordQuickViewTemplate";
              colItem.typeAttributes = {
                recordId: this.accountId,
                variant: "base",
                config: this.config,
                objectApiName: "Account",
                iconName: "standard:account",
                fields: this.accfields
              };
            } else {
              colItem.type = col.Type__c ? col.Type__c : "text";
            }
            this.columns = [...this.columns, colItem];
          });
        }
      })
      .catch((error) => {
        console.log("Error is" + JSON.stringify(error));
      });
  }

  buildRecords() {
    let records = [];
    let row = {};
    row.Id = this.accountId;
    row.accountName = this.contract?.fields?.Account?.displayValue;
    row.startDate = this.contract?.fields?.Start_Date__c?.displayValue;
    row.poNumber = this.contract?.fields?.PoNumber?.value;
    row.phone = this.accountPhone;
    row.jobSiteContact =
      this.contract?.fields?.Jobsite_Contact__r?.displayValue;
    row.jobSitePhone = this.contract?.fields?.Job_Site_Phone_Number__c?.value;
    row.estReturnDate = this.contract?.fields?.Return_Date__c?.displayValue;
    records.push(row);
    this.recordsToDisplay = records;
  }
}