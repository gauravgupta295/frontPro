import { LightningElement, api, wire, track } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import getContractAncillaryLineItems from "@salesforce/apex/Sbr_3_0_ContractController.getContractAncillaryLineItems";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const iconName = "standard:lead_list";
const ANCILLARY_CHARGES = "Ancillary Charges";
const orderLineActions = [
  { label: "Product Details", name: "view_line_item" },
  { label: "Edit", name: "edit_order_line" }
];
const EXCLUDED_ANCILLARY_COLUMNS_NAMES = [
  "Daily_Rate",
  "Weekly_Rate",
  "Monthly_Rate",
  "Notes",
  "Min_Rate2"
];

const logger = Logger.create(true);
export default class Sbr_3_0_contractLineItemsAncillaryCmp extends LightningElement {
  @api recordId;
  @api objectApiName;
  isMobile = isMobile;
  _lineItemsCols;
  iconName = iconName;
  isReadOnlyRecord;
  @track columns = [];
  @api lineItemsCols = [];
  @track lineItemsRecords = [];
  @track ancillaryItemsDynamicLabel = ANCILLARY_CHARGES;
  hasDataLoaded = false;
  sectionName = ANCILLARY_CHARGES;

  @wire(getContractAncillaryLineItems, { recordId: "$recordId" })
  lineItems({ error, data }) {
    if (data) {
      this.lineItemsRecords = data;
      this.ancillaryItemsDynamicLabel =
        this.sectionName + " (" + this.lineItemsRecords.length + ")";
      this.hasDataLoaded = true;
    } else if (error) {
      logger.log(error);
    }
  }
  get LineItemsColumns() {
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
        if (colItem.fieldName === "Delete_Item") {
          colItem.typeAttributes = {
            iconName: "utility:delete",
            name: "delete"
          };
          colItem.hideLabel = true;
          colItem.label = "";
        }
        if (col.fixedWidth__c) {
          colItem.fixedWidth = col.fixedWidth__c;
        }

        colItem.wrapText = true;
        if (!this.isReadOnlyRecord) {
          colItem.typeAttributes = {
            label: { fieldName: "Name" },
            fieldName: "Name",
            name: "edit_order_line",
            target: "_blank",
            variant: "base",
            disabled: { fieldName: "disableNameColumn" }, //FRONT-1950
            class: { fieldName: "disabledTextColor" } //FRONT-10473
          };
        } else {
          colItem.typeAttributes = {
            label: { fieldName: "Name" },
            fieldName: "Name",
            variant: "base",
            disabled: { fieldName: "disableNameColumn" }, //FRONT-1950
            class: { fieldName: "disabledTextColor" } //FRONT-10473
          };
        }

        colItem.typeAttributes = {
          label: { fieldName: "AssetName" },
          fieldName: "AssetName",
          variant: "base"
        };

        if (colItem.fieldName === "Current_MiHr") {
          colItem.cellAttributes = {
            alignment: "right"
          };
        }
        this.columns.push(colItem);
      });

      this.columns.unshift({
        label: "",
        fieldName: "kitItems",
        hideDefaultActions: true,
        sortable: true,
        type: "kit",
        wrapText: true,
        fixedWidth: 20
      });

      this.columns.push({
        type: "action",
        typeAttributes: {
          rowActions: orderLineActions,
          menuAlignment: "auto"
        }
      });

      let Anciliary_Columns = this.columns.filter(
        (col) => !EXCLUDED_ANCILLARY_COLUMNS_NAMES.includes(col.fieldName)
      );
      this.columns = Anciliary_Columns.filter(
        (column) => column.fieldName !== "Item_Subtotal"
      );
    }
    return this.columns;
  }

  get records() {
    let ancillaryLineItems = [];
    if (this.lineItemsRecords.length > 0) {
      this.lineItemsRecords.forEach((record) => {
        logger.log("ancillary Records" + JSON.stringify(record));
        let row = {};
        row.Id = record.Id;
        row.Name = record.Product2.Name;
        row.Notes = record.Line_Comments__c;
        row.CatClass = record.Product2.Product_SKU__c;
        row.AssetName = record.Product2.Bulk_Item__c
          ? record.Product2.itemNumberUsedByReservationsRentalOut__c
          : record.SBQQ__Asset__r?.Name;
        row.Current_MiHr = record.Meter_Reading_Out__c;
        row.StatusCreated = record.Status_Created_Qty__c
          ? record.Status_Created_Qty__c
          : 0;
        row.StatusFilled = record.Status_Filled_Qty__c
          ? record.Status_Filled_Qty__c
          : 0;
        row.StatusCancel = record.Status_Cancelled_Qty__c
          ? record.Status_Cancelled_Qty__c
          : 0;
        row.allowCancelStatus = record.Allow_Cancel__c;
        row.fullyConvertedItem =
          record.Allow_Cancel__c !== "" && record.Allow_Cancel__c === "Filled"
            ? true
            : false;
        row.partiallyConvertedItem =
          record.Allow_Cancel__c !== "" &&
            record.Allow_Cancel__c === "Partially Filled"
            ? true
            : false;
        row.fullyConvertedNoSubstituteItem =
          record.Allow_Cancel__c !== "" &&
            record.Allow_Cancel__c === "Filled" &&
            (record.Status__c === null || record.Status__c === "AVAILABLE")
            ? true
            : false;
        row.patiallyConvertedNoSubstituteItem =
          record.Allow_Cancel__c !== "" &&
            record.Allow_Cancel__c === "Partially Filled" &&
            (record.Status__c === null || record.Status__c === "AVAILABLE")
            ? true
            : false;
        row.TotalQuantity =
          record.Status_Created_Qty__c +
          record.Status_Filled_Qty__c +
          record.Status_Cancelled_Qty__c;
        row.RemainingQuantity =
          record.Status_Created_Qty__c +
          record.Status_Filled_Qty__c +
          record.Status_Cancelled_Qty__c -
          (record.Status_Filled_Qty__c + record.Status_Cancelled_Qty__c);
        row.Quantity = record.Quantity;
        row.product_Code = record.Product2.Product_SKU__c;
        row.Min_Rate =
          record.Min_Rate__c && String(record.Min_Rate__c).charAt(0) !== "$"
            ? "$" + Number(record.Min_Rate__c).toFixed(2)
            : record.Min_Rate__c;
        row.Min_Rate2 = record.Min_Rate2__c;
        row.Discount_Percentage = record.Discount_Percentage__c;
        row.Daily_Rate =
          record.Daily_Rate2__c &&
            String(record.Daily_Rate2__c).charAt(0) !== "$"
            ? "$" + Number(record.Daily_Rate2__c).toFixed(2)
            : record.Daily_Rate2__c;
        row.Weekly_Rate =
          record.Weekly_Rate2__c &&
            String(record.Weekly_Rate2__c).charAt(0) !== "$"
            ? "$" + Number(record.Weekly_Rate2__c).toFixed(2)
            : record.Weekly_Rate2__c;
        row.Monthly_Rate =
          record.Monthly_Rate2__c &&
            String(record.Monthly_Rate2__c).charAt(0) !== "$"
            ? "$" + Number(record.Monthly_Rate2__c).toFixed(2)
            : record.Monthly_Rate2__c;
        row.Sale_Price = record.Selling_Price__c;
        row.Item_Subtotal = record.Total_Price__c;
        row.Specific_Pricing_Type = record.Specific_Pricing_Type__c;
        row.Suggested_Daily_Rate = record.Suggested_Daily_Rate__c;
        row.Suggested_Weekly_Rate = record.Suggested_Weekly_Rate__c;
        row.Suggested_Monthly_Rate = record.Suggested_Monthly_Rate__c;
        row.productType = record.Product2.Product_Type__c;
        row.miscChargesType = record.Misc_Charges_Type__c;
        row.userSelect = record.Product2.User_Select__c;
        row.isUserAdded = record.is_User_Added__c;
        row.lineItemType =
          record.Line_Item_Type__c != null ? record.Line_Item_Type__c : "";
        row.stockClass = record.Product2.Stock_class__c;

        row.hasNotes = record.Line_Comments__c?.length > 0 ? true : false;
        row.showNoteItem = false;
        row.kitItemsAmount = 0;
        row.showKitItem = false;
        row.hasKitItems = false;
        row.hasKit = record.Product2.Is_Kit__c === "Yes" ? true : false;
        row.product = record.Product2Id;
        row.kitItems = {
          kitItemsValue: [],
          packageName: record.Product2.displayValue,
          isKit: record.Product2.Is_Kit__c,
          productId: record.Product2Id
        };
        row.Status = record.Status__c;
        ancillaryLineItems.push(row); // push(record);
      });
    }
    return ancillaryLineItems;
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }

  get isDataAvailable() {
    return !this.hasDataLoaded;
  }

  _parentRecord;
  @api get parentRecord() {
    return this._parentRecord;
  }
  set parentRecord(value) {
    this._parentRecord = value;
    this.setReadOnly();
  }
  setReadOnly() {
    logger.log("parent Rcord" + JSON.stringify(this.parentRecord));
    if (this.parentRecord) {
      logger.log("parent Rcord" + JSON.stringify(this.parentRecord));
      this.isReadOnlyRecord = !(
        this.parentRecord.fields?.Is_Edit_In_Progress__c.value &&
        this.parentRecord.fields?.Is_Edited_By_Current_User__c.value
      );
    }
  }
}