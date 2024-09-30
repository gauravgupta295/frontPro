import { LightningElement, api, track } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import DESKTOPTEMPLATE from "./sbr_3_0_contractLineItemsBulkRemoveDesktop.html";
import MOBILETEMPLATE from "./sbr_3_0_contractLineItemsBulkRemoveMobile.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
const EXCLUDED_RENTAL_COLUMNS_NAMES = [
  "Sale_Price",
  "Contingency_Cost",
  "Seasonal_Multiplier",
  "Notes",
  "Current_MiHr"
];
export default class Sbr_3_0_contractLineItemsBulkRemove extends LightningElement {
  _selectedRows;
  isMobile = isMobile;
  selectedRemovedRows;
  preSelectedRemovedRows;
  LABELS = LABELS;

  @api isConfirm;
  @api lineItemsCols = [];
  @api
  get selectedRows() {
    return this._selectedRows;
  }
  set selectedRows(value) {
    this._selectedRows = value;
    this.selectedRemovedRows = this._selectedRows;
    this.preSelectedRemovedRows = this.getpreSelectedRows();
    logger.log("_selectedRows 2", JSON.stringify(this._selectedRows));
  }

  @api getSelectedRemovedRows() {
    return this.selectedRemovedRows;
  }

  @track _lineItemsToRemove;

  //added for FRONT-31384 - Mobile Change
  @api
  get lineItemsToRemove() {
    return this._lineItemsToRemove;
  }

  set lineItemsToRemove(value) {
    this._lineItemsToRemove = value;
  }

  @api isSales; //FRONT-29023
  @api isRentals; //FRONT-29023

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  get rentalColumns() {
    let columns = [];
    if (this.lineItemsCols) {
      let lineItemsColumns = [...this.lineItemsCols];
      lineItemsColumns.sort((a, b) => a.Order__c - b.Order__c);
      lineItemsColumns.forEach((col) => {
        let colItem = {};
        colItem.label = col.Label;
        colItem.fieldName = col.Field_Name__c;
        colItem.hideDefaultActions = true;
        colItem.sortable = col.IsSortable__c;
        colItem.type = col.Type__c ? col.Type__c : "text";
        if (col.Type__c === "currency") {
          colItem.typeAttributes = {
            currencyCode: "USD"
          };
          colItem.cellAttributes = {
            alignment: "left"
          };
        }
        //FRONT-29022 Start
        if (col.fixedWidth__c) {
          if (colItem.fieldName === "unitOfMeasure") {
            colItem.fixedWidth = 200;
          } else {
            colItem.fixedWidth = col.fixedWidth__c;
          }
          //FRONT-29022 End
        }

        if (colItem.fieldName === "AssetName") {
          colItem.typeAttributes = {
            label: { fieldName: "AssetName" },
            fieldName: "AssetName",
            variant: "base"
          };
        }
        //FRONT-29022 start
        if (colItem.fieldName === "Name") {
          colItem.type = "text";
          colItem.typeAttributes = {
            label: { fieldName: "Name" },
            fieldName: "Name"
          };
        }

        //Front-29022 end

        if (
          colItem.fieldName === "Daily_Rate" ||
          colItem.fieldName === "Min_Rate" ||
          colItem.fieldName === "Weekly_Rate" ||
          colItem.fieldName === "Monthly_Rate" ||
          colItem.fieldName === "Quantity"
        ) {
          colItem.cellAttributes = {
            alignment: "right"
          };
        }
        columns.push(colItem);
      });

      let Rental_Columns = columns.filter(
        (col) => !EXCLUDED_RENTAL_COLUMNS_NAMES.includes(col.fieldName)
      );
      columns = Rental_Columns.filter(
        (column) => column.fieldName !== "Item_Subtotal"
      );
    }

    return columns;
  }

  getpreSelectedRows() {
    let preSelectedRows = [];
    if (this._selectedRows) {
      let selectedRows = [...this._selectedRows];
      selectedRows.forEach((row) => {
        preSelectedRows.push(row.Id);
      });
    }
    return preSelectedRows;
  }

  handleLineItemSelection(event) {
    this.selectedRemovedRows = event.target.getSelectedRows();
    logger.log(
      "selectedRemovedRows" + JSON.stringify(this.selectedRemovedRows)
    );
  }
  //added for FRONT-31384 - Mobile Change
  handleRemoveAction() {
    let checkBoxes = this.template.querySelectorAll(".isChecked");
    let selectedRecordstoRemove = [];
    for (let i = 0; i < checkBoxes.length; i++) {
      if (checkBoxes[i].checked) {
        selectedRecordstoRemove.push(checkBoxes[i].dataset.id);
      }
    }
    logger.log(
      "Final Records to remove:",
      JSON.stringify(selectedRecordstoRemove)
    );
    const selectedEvent = new CustomEvent("finalselected", {
      detail: selectedRecordstoRemove
    });
    this.dispatchEvent(selectedEvent);
  }

  //added for FRONT-31384 - Mobile Change
  toggleViewContent(event) {
    let currentItemId = event.target.dataset.lineItemId;
    let data = this.lineItemsToRemove;
    this._lineItemsToRemove = data.map((item) => {
      if (item.Id === currentItemId) {
        return {
          ...item,
          ViewMore: !item.ViewMore
        };
      }
      return item;
    });
  }
}