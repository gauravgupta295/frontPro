import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
//import storeData from "@salesforce/apex/sbr_3_0_DataStoreControllerClass.storeData";
import updateRecords from "@salesforce/apex/sbr_3_0_drfDMLServiceDelegator.updateRecord"; //FRONT-4352
import Id from "@salesforce/user/Id";
import FORM_FACTOR from "@salesforce/client/formFactor";
import {
  /*updateRecord,*/ //FRONT-4352
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
let FIELDS = [
  "Order.Is_Edited_By_Current_User__c",
  "Order.Last_Edit_By__c",
  "Order.Is_Edit_In_Progress__c"
]; //added for Front-4587

const ID_FIELD = "Id"; //FRONT-4352
const IS_EDIT_IN_PROGRESS_FIELD = "Is_Edit_In_Progress__c"; //FRONT-4352
const INSUFFICIENT_ACCESS = "INSUFFICIENT_ACCESS_OR_READONLY";
import { getRecord } from "lightning/uiRecordApi"; //Front-4587
//started for FRONT-4587
import Warning_Template from "./sbr_3_0_dynamicFormEditActionWarningMsg.html";
import Default_template from "./sbr_3_0_dynamicFormEditAction.html";
//ended for Front-4587
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";

export default class Sbr_3_0_dynamicFormEditAction extends LightningElement {
  @api recordId;

  @api objectApiName;

  //Front-4587 start
  @api editInProgress;
  @api editBycurrentUser;
  displayError = false;
  //Front-4587 end

  connectedCallback() {
    //started for Front-4587
    if (FORM_FACTOR == "Large" || this.objectApiName == "SBQQ__Quote__c") {
      this.updateEditInProgress();
    }

    //ended for Front-4587
  }
  //started for Front-4587
  render() {
    if (
      FORM_FACTOR === "Small" &&
      this.displayError === true &&
      this.objectApiName !== "SBQQ__Quote__c"
    ) {
      return Warning_Template;
    } else {
      return Default_template;
    }
  }

  //Ended for Front-4587

  isCurrentUser = false; //4587
  UserId = Id; //4587
  //start for Front-4587

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (error) {
    } else if (data) {
      if (FORM_FACTOR === "Small" && this.objectApiName !== "SBQQ__Quote__c") {
        if (data.fields.Is_Edit_In_Progress__c.value === false) {
          this.updateEditInProgress();
          this.displayError = false;
        } else if (
          data.fields.Is_Edit_In_Progress__c.value &&
          !data.fields.Is_Edit_In_Progress__c.value
        ) {
          this.displayError = true;
        }
        else {
          this.displayError = false;
          this.closeAuraAction();
        }
      }
    }
  }

  //end for Front-4587

  async updateEditInProgress() {
    //FRONT-4352 Start
    let fields = {};
    fields[ID_FIELD] = this.recordId;
    fields[IS_EDIT_IN_PROGRESS_FIELD] = true;
    const recordInput = {
      objectApiName: this.objectApiName,
      fields: fields,
      actionType: "Edit"
    }; //FRONT-4352 Start END */
    try {
      await updateRecords(recordInput); //FRONT-4352

      //await dmlServiceProvider({ ObjectApiName:this.objectApiName, ID:this.recordId, ActionType:'Edit', UserID:this.userId });    //FRONT-4352
      // await storeData({ recordId: this.recordId, EditInProgress: true });

      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

      this.closeAuraAction();
    } catch (e) {
      //FRONT-4353 START
      if (
        (e.body.output &&
          e.body.output.errors &&
          e.body.output.errors.length > 0) ||
        (e.body.pageErrors[0].statusCode !== "" &&
          e.body.pageErrors[0].statusCode !== null &&
          e.body.pageErrors[0].statusCode !== undefined)
      ) {
        let error = "";
        if (
          e.body.pageErrors[0].statusCode !== "" &&
          e.body.pageErrors[0].statusCode !== null &&
          e.body.pageErrors[0].statusCode !== undefined
        ) {
          error = e.body.pageErrors[0].statusCode;
        } else {
          error = e.body.output.errors[0];
        }
        //FRONT-4353 END
        if (
          error.errorCode === INSUFFICIENT_ACCESS ||
          error === INSUFFICIENT_ACCESS
        ) {
          //FRONT-4352
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: `You do not have permission to edit this record. Please contact the administrator`,
              variant: "error"
            })
          );
          this.dispatchEvent(
            new CustomEvent("closeauraaction", {
              detail: "error"
            })
          );
        }
      }
    }
  }

  closeAuraAction() {
    this.dispatchEvent(new CustomEvent("closeauraaction"));
  }
  //start for FRONT-4587
  closeErrorScreen() {
    this.dispatchEvent(
      new CustomEvent("closeauraaction", {
        detail: {
          action: this.actionName
        }
      })
    );
  }
  //End for FRONT-4587
}