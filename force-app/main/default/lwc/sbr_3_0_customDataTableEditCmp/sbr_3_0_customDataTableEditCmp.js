import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import * as SBRUtils from "c/sbrUtils";
import saveSObjects from "@salesforce/apex/SBR_3_0_CustomDataTableEditCmpController.saveSObjects";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import LABELS from "c/sbr_3_0_customLabelsCmp"; //Added as part of FRONT-2195
import EditCellCss from "@salesforce/resourceUrl/sbr_3_0_LineItemEditCell_css"; //Added as part of FRONT-9276
import { loadStyle } from "lightning/platformResourceLoader"; //Added as part of FRONT-9276

const rentalColumns = [
  { label: "Item Name", fieldName: "Name", type: "text" }, //Modified as part of 8759
  { label: "Cat Class", fieldName: "CatClass", type: "text" }, //Added as part of 2195
  { label: "Quantity", fieldName: "Quantity", type: "number", editable: true }, //Modified as part of 8759
  { label: "Min Rate", fieldName: "Min_Rate", type: "text", editable: true }, //Added as part of 8759
  { label: "Day", fieldName: "Daily_Rate", type: "text", editable: true }, //Modified as part of 8759
  { label: "Week", fieldName: "Weekly_Rate", type: "text", editable: true }, //Modified as part of 8759
  { label: "4 Week ", fieldName: "Monthly_Rate", type: "text", editable: true } //Modified as part of 8759
];

const salesColumns = [
  { label: "Name", fieldName: "Name", type: "text" },
  { label: "Quantity", fieldName: "Quantity", type: "number", editable: true },
  {
    label: "Sales/Misc Price",
    fieldName: "Sale_Price",
    type: "text",
    editable: true
  }
];

const VALID_QUANTITY_ERROR_MSG = "Please enter a valid Quantity.";
const QUANTITY_DIGITS_ERROR_MSG =
  "You may not enter more than a five digit value for Quantity.";
const DAILY_RATE_ERROR_MSG = "Please enter a valid Daily Rate.";
const MIN_RATE_ERROR_MSG = "Please enter a valid Min Rate."; //Added as part of FRONT-8759
const WEEKLY_RATE_ERROR_MSG = "Please enter a valid Weekly Rate.";
const MONTHLY_RATE_ERROR_MSG = "Please enter a valid Monthly Rate.";
const SALES_MISC_PRICE_ERROR_MSG = "Please enter a valid Sales/Misc Price.";
const SUGGESTED_DAILY_RATE_ERROR_MSG =
  "Daily Rate cannot be greater than Suggested Daily Rate";
const SUGGESTED_WEEKLY_RATE_ERROR_MSG =
  "Weekly Rate cannot be greater than Suggested Weekly Rate";
const SUGGESTED_MONTHLY_RATE_ERROR_MSG =
  "Monthly Rate cannot be greater than Suggested Monthly Rate";
export default class sbr_3_0_customDataTableEditCmp extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api draftValues = [];
  @api isQuote;
  @api isOrder;
  @api isSales;
  @api csp = "";

  showSpinner = false;
  hasValidationError = false;
  errorMsgs = [];
  label = LABELS; //Added as part of FRONT-2195
  _tableData;

  @api
  get cmpdata() {
    return this._tableData;
  }

  renderedCallback() {
    let styles = document.createElement("style");
    styles.innerText = ".slds-grid_align-end {justify-content: space-between;}";
    this.template.querySelector(".custom-datatable-style").appendChild(styles);
  }

  set cmpdata(value) {
    let updatedData = JSON.parse(JSON.stringify(value));

    updatedData.forEach((obj) => {
      //This is for Forced Rental Addon
      if (obj?.forcedItem) {
        obj.isEditable = obj?.quantityEditable;
      } else if (obj.Kit_Number_this_Item_Belongs_to) {
        // Check if any other object has the same CatClass as Kit_Number_this_Item_Belongs_to
        const matchingObject = updatedData.find(
          (item) => item.CatClass === obj.Kit_Number_this_Item_Belongs_to
        );

        // If a matching object is found, set isEditable to false, else set it to true
        obj.isEditable = !!matchingObject ? false : true;
      } else {
        obj.isEditable = true; // Set isEditable to true for objects without Kit_Number_this_Item_Belongs_to
      }
    });
    this._tableData = updatedData;
  }

  get columns() {
    if ((this.isQuote || this.isOrder) && this.isSales) {
      return salesColumns;
    }

    return rentalColumns;
  }

  @api
  clearDrafts() {
    this.draftValues = [];
  }

  @api
  async saveRows(existingLines) {
    this.resetErrorMsg();
    this.showSpinner = true;
    this.draftValues = this.template.querySelector(
      "lightning-datatable"
    ).draftValues;
    this.draftValues.forEach((recordEdited) => {
      let lineItemsData = JSON.parse(JSON.stringify(this.cmpdata));
      let lineItemData = lineItemsData.find(
        (lineItemRecord) => lineItemRecord.Id === recordEdited.Id
      );

      //Execute validations for the field data updates
      if (recordEdited.Quantity) {
        if (
          SBRUtils.isEmpty(recordEdited.Quantity) ||
          recordEdited.Quantity < 0
        ) {
          this.setErrorMsg(true, VALID_QUANTITY_ERROR_MSG);
        } else if (recordEdited.Quantity.toString().length > 5) {
          this.setErrorMsg(true, QUANTITY_DIGITS_ERROR_MSG);
        }
        recordEdited.SBQQ__Quantity__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Quantity
        );
      }
      //Added as part of FRONT-8759
      if (recordEdited.Min_Rate) {
        if (
          SBRUtils.isEmpty(recordEdited.Min_Rate) ||
          recordEdited.Min_Rate < 0
        ) {
          this.setErrorMsg(true, MIN_RATE_ERROR_MSG);
        }
        recordEdited.Min_Rate__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Min_Rate
        );
      }
      //FRONT-8759 ends
      if (recordEdited.Daily_Rate) {
        if (
          SBRUtils.isEmpty(recordEdited.Daily_Rate) ||
          recordEdited.Daily_Rate < 0
        ) {
          this.setErrorMsg(true, DAILY_RATE_ERROR_MSG);
        }
        recordEdited.Daily_Rate__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Daily_Rate
        );
      }
      if (recordEdited.Weekly_Rate) {
        if (
          SBRUtils.isEmpty(recordEdited.Weekly_Rate) ||
          recordEdited.Weekly_Rate < 0
        ) {
          this.setErrorMsg(true, WEEKLY_RATE_ERROR_MSG);
        }
        recordEdited.Weekly_Rate__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Weekly_Rate
        );
      }
      if (recordEdited.Monthly_Rate) {
        if (
          SBRUtils.isEmpty(recordEdited.Monthly_Rate) ||
          recordEdited.Monthly_Rate < 0
        ) {
          this.setErrorMsg(true, MONTHLY_RATE_ERROR_MSG);
        }
        recordEdited.Monthly_Rate__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Monthly_Rate
        );
      }
      if (recordEdited.Sale_Price) {
        if (
          SBRUtils.isEmpty(recordEdited.Sale_Price) == null ||
          recordEdited.Sale_Price < 0
        ) {
          this.setErrorMsg(true, SALES_MISC_PRICE_ERROR_MSG);
        }
        recordEdited.Selling_Price__c = SBRUtils.formatRemoveDollarSign(
          recordEdited.Sale_Price
        );
      }

      //Execute validations for the limit increases
      if (
        this.csp === "Do Not Exceed" ||
        this.csp === "Percent Off Local Book"
      ) {
        if (recordEdited.Daily_Rate > lineItemData.Suggested_Daily_Rate) {
          this.setErrorMsg(true, SUGGESTED_DAILY_RATE_ERROR_MSG);
        } else if (
          recordEdited.Weekly_Rate > lineItemData.Suggested_Weekly_Rate
        ) {
          this.setErrorMsg(true, SUGGESTED_WEEKLY_RATE_ERROR_MSG);
        } else if (
          recordEdited.Monthly_Rate > lineItemData.Suggested_Monthly_Rate
        ) {
          this.setErrorMsg(true, SUGGESTED_MONTHLY_RATE_ERROR_MSG);
        }
      }
      // Show error on quantity for sales required addons when quantity is less than parent quantity
      let currentEditedLine = existingLines?.find(
        (item) => item?.Id == recordEdited?.Id
      );
      let parentLine = existingLines?.find(
        (item) =>
          item?.CatClass == currentEditedLine?.Kit_Number_this_Item_Belongs_to
      );

      if (parentLine?.Quantity > recordEdited.Quantity) {
        let isRentalOrSales =
          lineItemData?.Sale_Price != undefined &&
          lineItemData?.Sale_Price != null
            ? "Sales"
            : "Rental";
        this.setErrorMsg(
          true,
          "Sales Add On Quantity must be greater than or equal to the quantity of the " +
            isRentalOrSales +
            " Item this Add On is associated to."
        );
      }
    });

    if (!this.hasValidationError) {
      if (this.isQuote) {
        saveSObjects({
          quoteLines: this.draftValues,
          orderLines: [],
          objectType: "SBQQ__QuoteLine__c"
        })
          .then((result) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: this.label.EDIT_LINEITEMS_SUCCESS_MESSAGE, //this.draftValues.length + ' line items have been successfully updated.',

                variant: "success"
              })
            );
            this.showSpinner = false;
            this.dispatchEvent(new CustomEvent("success"));
            getRecordNotifyChange([{ recordId: this.recordId }]);
            // Clear all draft values in the datatable
            this.draftValues = [];
          })
          .catch((error) => {
            //SF-6561 Adding user friendly error message
            let message = error.body?.message || error.message;
            if (message.includes("Quotes may only be edited if Status =")) {
              message =
                "Quotes may only be edited if Status is Draft or by Sales Managers if Status is In Review ";
            }
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error updating or reloading records",
                message: message,
                variant: "error"
              })
            );
            this.showSpinner = false;
          });
      } else {
        saveSObjects({
          quoteLines: [],
          orderLines: this.draftValues,
          objectType: "OrderItem"
        })
          .then((result) => {
            setTimeout(() => {
              getRecordNotifyChange([{ recordId: this.recordId }]);
              //Added message label as part of 8759
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success",
                  message: this.label.EDIT_LINEITEMS_SUCCESS_MESSAGE, //this.draftValues.length + ' line items have been successfully updated.',

                  variant: "success"
                })
              );
              this.dispatchEvent(new CustomEvent("success"));
              
               this.showSpinner = false;
            }, 15000);
            
            // Clear all draft values in the datatable
            this.draftValues = [];
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error updating or reloading records",
                message: error.body.message,
                variant: "error"
              })
            );
            this.showSpinner = false;
          });
      }
    } else {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.errorMsgs.join("\n"),
          variant: "error"
        })
      );
      this.showSpinner = false;
    }
  }

  get disableSave() {
    return !this.draftValues && this.draftValues.length === 0;
  }
  //Populates array with validation errors
  setErrorMsg(hasValidationError, errorMsg) {
    this.hasValidationError = hasValidationError;
    if (!this.errorMsgs.includes(errorMsg)) {
      this.errorMsgs.push(errorMsg);
    }
  }
  //Clears array value if user is hitting Save consequently
  resetErrorMsg() {
    this.hasValidationError = false;
    this.errorMsgs = [];
  }
  //Added as part of FRONT-2195
  handleChange() {
    this.dispatchEvent(new CustomEvent("fieldedited"));
  }
  //FRONT-2195 Ends
  /* FRONT- 9276 : Rendering custom css*/
  renderedCallback() {
    loadStyle(this, EditCellCss);
  }
  /* END : FRONT - 9276 */
}