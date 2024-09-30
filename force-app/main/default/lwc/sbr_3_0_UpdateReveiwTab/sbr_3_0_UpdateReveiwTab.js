import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import Order_StaleTotals from "@salesforce/schema/Order.Pending_Tax_Calculation__c"; //FRONT-20239, FRONT-18373
import Quote_StaleTotals from "@salesforce/schema/SBQQ__Quote__c.Pending_Tax_Calculation__c"; //FRONT-20239, FRONT-18373
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry"; //FRONT-21763
import { Logger } from "c/sbr_3_0_frontlineUtils";

const logger = Logger.create(true);
export default class Sbr_3_0_UpdateReveiwTab extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;
  showUpdateTotals = false;
  staleTotals = true;
  FIELDS = [];
  appName = "";
  isActive = false;
  observer;
  //START: FRONT-21763
  existingRecord = {};
  isChanged;
  //END: FRONT-21763

  @wire(getRecord, { recordId: "$recordId", fields: "$FIELDS" })
  wiredRecord({ data }) {
    if (data) {
      if (this.objectApiName === "SBQQ__Quote__c") {
        this.staleTotals = getFieldValue(data, Quote_StaleTotals);
      } else if (this.objectApiName === "Order") {
        this.staleTotals = getFieldValue(data, Order_StaleTotals);
      }

      

      if(FORM_STORE.updatedRecords && FORM_STORE.updatedRecords[this.recordId]) {
        this.isRecordChanged(FORM_STORE.updatedRecords[this.recordId]);
      }
      console.log('isChanged : '+this.isChanged);
      //FRONT-21763: Added OR condition to run the updatetotals if we are updating quote/order details without updating the lineitems 
      if (this.staleTotals || (FORM_STORE.updatedRecords && FORM_STORE.updatedRecords[this.recordId] && this.isChanged)) {
        this.showUpdateTotals = true;
      }
    }
  }

  connectedCallback() {
    getAppName().then((results) => {
      this.appName = results;
      if (this.appName === "RAE Frontline") {
        this.observerIsTabActiveMutationObserver();
        if (this.objectApiName === "SBQQ__Quote__c") {
          this.FIELDS = [Quote_StaleTotals];
        } else if (this.objectApiName === "Order") {
          this.FIELDS = [Order_StaleTotals];
        }
      }
    });
  }

  observerIsTabActiveMutationObserver() {
    let parentNode = this.template.host.parentNode?.parentNode;
    if (parentNode && parentNode.tagName === "FLEXIPAGE-TAB2") {
      let id = parentNode.id;
      let tabName = parentNode.ownerDocument.documentElement.querySelector(
        `a[aria-controls="${id}"]`
      );
      if (
        tabName &&
        tabName.dataset &&
        ((this.objectApiName === "Order" &&
          tabName.dataset.label === "Order Review") ||
          (this.objectApiName === "SBQQ__Quote__c" &&
            tabName.dataset.label === "Quote Review"))
      ) {
        const config = { attributeFilter: ["tabindex"], attributes: true };
        const callback = (mutationList, observer) => {
          for (const mutation of mutationList) {
            if (
              mutation.type === "attributes" &&
              mutation.target.tabIndex !== -1 &&
              !this.isActive
            ) {
              if (this.objectApiName === "SBQQ__Quote__c") {
                this.FIELDS = [Quote_StaleTotals];
              } else if (this.objectApiName === "Order") {
                this.FIELDS = [Order_StaleTotals];
              }
              this.isActive = true;
            } else {
              this.isActive = false;
              this.showUpdateTotals = false;
            }
          }
        };
        this.observer = new MutationObserver(callback);
        this.observer.observe(tabName, config);
      }
    }
  }

  disconnectedCallback() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  handleCloseOnError() {
    this.showUpdateTotals = false;
    this.staleTotals = true;
  }

  handleCloseOnSuccess() {
    this.showUpdateTotals = false;
    this.staleTotals = false;
  }
  
  //FRONT-21763: to avoid the dml is record is not updated and user is navigating to Review Tab
  isRecordChanged(newRecord) {
    this.isChanged = false;
    const newRecordKeys = Object.keys(newRecord);
    const existingRecordKeys = Object.keys(this.existingRecord);
    
    if (newRecordKeys.length !== existingRecordKeys.length) {
      this.isChanged = true;
    }

    for (let key of newRecordKeys) {
      if (newRecord[key] !== this.existingRecord[key]) {
        this.isChanged = true;
      }
    }
    logger.log(JSON.stringify(this.existingRecord), "===ischanged===", this.isChanged, "===newRecord===", JSON.stringify(newRecord));
    this.existingRecord = Object.assign({}, newRecord);    
    return this.isChanged;
  }
}