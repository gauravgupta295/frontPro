import { LightningElement, api } from "lwc";
import { FlowNavigationBackEvent } from "lightning/flowSupport";
import { NavigationMixin } from "lightning/navigation";
import { Logger, isUndefinedOrNull } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
export default class LwcInFlow extends NavigationMixin(LightningElement) {
  @api
  availableActions = [];
  @api
  recordId;
  @api
  objectApiName;
  _currentPageReference;
  fieldsToQuery = [
    `Order.Is_Edit_In_Progress__c`,
    `Order.Id`,
    `Order.Is_Edited_By_Current_User__c`
  ];
  isEditMode = false;
  isEditedByCurrentUser = false;

  // @wire(getRecord, {
  //   recordId: "$recordId",
  //   fields: [
  //     `Order.Is_Edit_In_Progress__c`,
  //     `Order.Id`,
  //     `Order.Is_Edited_By_Current_User__c`
  //   ]
  // })
  // wiredRecord({ error, data }) {
  //   if (data) {
  //     debugger;
  //     this.isEditMode = data.fields.Is_Edit_In_Progress__c.value;
  //     this.isEditedByCurrentUser =
  //       data.fields.Is_Edited_By_Current_User__c.value;

  //     if (this.isEditMode && this.isEditedByCurrentUser && this.availableActions.length === 0) {
  //       this.NavigateToRecord();
  //       logger.log("inside wire");
  //     }
  //     if (error) {
  //     }
  //   }
  // }

  handleBack(event) {
    if (this.availableActions.find((action) => action === "BACK")) {
      const navigateBackEvent = new FlowNavigationBackEvent();
      this.dispatchEvent(navigateBackEvent);
    }
  }

  connectedCallback() {
    this.NavigateToRecord();
  }

  NavigateToRecord() {
    if (this.recordId && this.objectApiName) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          //componentName: "c__sbr_3_0_navigateEditModeComponent"
          recordId: this.recordId,
          actionName: "edit"
        }
        /*state: {
          c__id: this.recordId,
          c__objectName: this.objectApiName
        }*/
      });
      this.recordId = null;
    }
  }
}