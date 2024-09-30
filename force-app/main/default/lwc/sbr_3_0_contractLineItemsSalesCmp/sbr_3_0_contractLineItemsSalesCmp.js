import { LightningElement, api, wire, track } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { refreshApex } from "@salesforce/apex";
import getContractSalesLineItems from "@salesforce/apex/Sbr_3_0_ContractController.getContractSalesLineItems";
import noSalesItemSvg from "@salesforce/resourceUrl/Sbr_3_0_NoRentalItemSVG";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { deleteRecord } from "lightning/uiRecordApi"; //Front-15728
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
import borderStyle from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import deleteOrderItems from "@salesforce/apex/Sbr_3_0_ContractController.deleteContractLineItems"; //Front-29022
const logger = Logger.create(true);
const iconName = "standard:lead_list";
const SALES_ITEM = "Sales/Misc Items";
const orderLineActions = [
  /*{ label: "Product Details", name: "view_line_item" },*/
  { label: "Edit", name: "edit_line_item" },
  { label: "Remove Item", name: "remove_line_item" }
];
//START: FRONT-29004
const OPTIONS = [
  { label: "Sales", value: "SALES" },
  { label: "Misc", value: "MISC" }
];
//END: FRONT-29004
const EXCLUDED_SALES_COLUMNS_NAMES = [
  "Daily_Rate",
  "Weekly_Rate",
  "Monthly_Rate",
  "Min_Rate2", //added for 7382
  "Total_Qty", //added for 9233
  "Contingency_Cost",
  "Seasonal_Multiplier"
];
export default class Sbr_3_0_contractLineItemsSalesCmp extends LightningElement {
  @api recordId;
  @api objectApiName;
  isMobile = isMobile;
  iconName = iconName;
  sectionName = SALES_ITEM;
  salesMiscItemsDynamicLabel = SALES_ITEM;
  @track isReadOnlyRecord;
  @api lineItemsCols = [];
  hasDataLoaded = false;
  @track lineItemsRecords = [];
  @track lineItemNotes;
  @track selectedItem;
  @track notes = "";
  rowId;
  noItemUrl = noSalesItemSvg;
  assetSearchPlaceholder = "Add Part/Item #";
  LABELS = LABELS;
  salesLineItems = [];
  //Front-15728 start
  isShowRemove = false;
  lineItemId = "";
  isLoading = false;
  //Front-15728 end
  selectedItemName; //FRONT-15261
  showEditor = false; // FRONT-15261

  //START: FRONT-29004
  @track options = OPTIONS;
  selectedValue = "SALES";
  isEditAllDisabled = true;
  isRemoveItemsDisabled = true;
  //END: FRONT-29004
  //start for 29022
  @track selectedRows;
  isConfirm = false;
  disableConfirm = false;
  //end for 29022
  @track props = { isDisable: false }; //FRONT-29019
  selectedRecordstoRemove = []; //FRONT-29023
  _showRemoveScreenSales; //FRONT-29023
  @track lineItemsListToRemove = []; //FRONT-29023
  @track finalrecordstoremove = []; //FRONT-29023

  wiredLineItemsResult;
  @wire(getContractSalesLineItems, { recordId: "$recordId" })
  lineItems(result) {
    this.wiredLineItemsResult = result;
    if (result.data) {
      this.lineItemsRecords = result.data;
      this.buildRecords();
      this.salesMiscItemsDynamicLabel =
        this.sectionName + " (" + this.lineItemsRecords.length + ")";
      this.hasDataLoaded = true;
    } else if (result.error) {
      logger.log(result.error);
    }
  }

  get salesColumns() {
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
        if (col.Type__c === "currency") {
          colItem.typeAttributes = {
            currencyCode: "USD"
          };
          colItem.cellAttributes = {
            alignment: "left"
          };
        }
        if (colItem.fieldName === "Notes") {
          colItem.type = "buttonIcon";
          colItem.typeAttributes = {
            iconName: "utility:note",
            CssClass: "notes-icon-color",
            iconVariant: "bare",
            name: !this.isReadOnlyRecord
              ? "edit_contract_line"
              : "view_line_item_notes",
            rowId: { fieldName: "Id" }
          };
          colItem.fieldName = "Notes";
          colItem.cellAttributes = {
            alignment: "left"
          };
        }

        if (colItem.fieldName === "Name") {
          colItem.wrapText = true;
          if (!this.isReadOnlyRecord) {
            colItem.typeAttributes = {
              label: { fieldName: "Name" },
              fieldName: "Name",
              name: "edit_line_item",
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
        }
        if (colItem.fieldName === "AssetName") {
          colItem.typeAttributes = {
            label: { fieldName: "AssetName" },
            fieldName: "AssetName",
            variant: "base"
          };
        }

        if (colItem.fieldName === "Current_MiHr") {
          colItem.cellAttributes = {
            alignment: "right"
          };
        }
        if (colItem.fieldName === "salesMiscPrice") {
          //FRONT-31788
          colItem.cellAttributes = {
            alignment: "right"
          };
        }
        columns.push(colItem);
      });
      /*Commented by Komal. This is not being used and as such was causing spacing issues.
      columns.unshift({
        label: "",
        fieldName: "kitItems",
        hideDefaultActions: true,
        sortable: true,
        type: "kit",
        wrapText: true,
        fixedWidth: 20
      });
      */
      columns.push({
        type: "action",
        typeAttributes: {
          rowActions: orderLineActions,
          menuAlignment: "auto"
        }
      });

      let Sales_Columns = columns.filter(
        (col) => !EXCLUDED_SALES_COLUMNS_NAMES.includes(col.fieldName)
      );
      columns = Sales_Columns.filter(
        (column) => column.fieldName !== "Item_Subtotal"
      );
    }

    return columns;
  }

  buildRecords() {
    this.salesLineItems = [];
    if (this.lineItemsRecords.length > 0) {
      this.lineItemsRecords.forEach((record) => {
        logger.log("SalesItems" + JSON.stringify(record));

        let row = {};
        row.Id = record.Id;
        row.Name = record.Product2?.Name;
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
        row.Min_Rate = record.Min_Rate__c;
        row.Min_Rate2 = record.Min_Rate2__c;
        row.Discount_Percentage = record.Discount_Percentage__c;
        row.Daily_Rate = record.Daily_Rate2__c;
        row.Weekly_Rate = record.Weekly_Rate2__c;
        row.Monthly_Rate = record.Monthly_Rate2__c;
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
          packageName: record.Product2.Name,
          isKit: record.Product2.Is_Kit__c,
          productId: record.Product2Id
        };
        row.Status = record.Status__c;
        //FRONT-15260: START
        row.cost = record.Cost__c;
        row.itemNumber = record.Product2?.Item_Number__c;
        row.lineItemNotes = record.Line_Comments__c;
        row.sourcingBranch = record.Order?.Sourcing_Branch__c;
        row.noChargeFlag = record.Free_Flag__c;
        //FRONT-15260: END
        // START FRONT-27948
        row.isSalesItem =
          record.Product2.Product_Type__c === "Merchandise" ||
          record.Product2.Product_Type__c === "Parts"
            ? true
            : false;
        row.salesMiscPrice = row.isSalesItem
          ? record.Selling_Price__c
          : record.Misc_Charge__c;
        // row.salesMiscPrice = this.isMobile ?row.salesMiscPrice ? "$" + row.salesMiscPrice : "":row.salesMiscPrice;  //FRONT-31730
        row.unitOfMeasure = record.Order_Item_Unit_Of_Measure__c;
        // END FRONT-27948
        this.salesLineItems.push(row); // push(record);
      });
      logger.log("salesLineItems" + JSON.stringify(this.salesLineItems));
    }
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

  get isRecordListNotEmpty() {
    return this.salesLineItems?.length > 0;
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
    if (this.parentRecord) {
      this.isReadOnlyRecord = !(
        this.parentRecord.fields?.Is_Edit_In_Progress__c.value &&
        this.parentRecord.fields?.Is_Edited_By_Current_User__c.value
      );
    }
  }

  handleRowNotesAction(event) {
    let detail = event.detail;
    const actionName = detail.name;
    this.lineItemNotes = detail.value;
    switch (actionName) {
      case "view_line_item_notes":
        this.template.querySelector(".viewlineitemNotes").toggleModal();
        this.template.querySelector(".viewlineitemNotes").showFooter = false;
        break;
      case "edit_contract_line":
        this.rowId = detail.rowid;
        this.template.querySelector(".editlineitemNotes").toggleModal();
        this.template.querySelector(".editlineitemNotes").showFooter = true;
        break;
      default:
        break;
    }
  }

  handleNotesChange(event) {
    this.notes = event.detail.value;
  }

  updateOrderItemNotes = () => {
    let fields = { Id: this.rowId };
    fields.Line_Comments__c = this.notes;
    let recordInput = { fields };

    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Notes updated successfully",
            variant: "success"
          })
        );
        this.refs.notesModal.toggleModal();
      })
      .catch(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Error",
            variant: "error"
          })
        );
      });
  };

  //FRONT-15260
  handleRowAction(event) {
    const action = event.detail.action;
    //const selectedRow = event.detail.row;
    this.selectedItem = event.detail.row; //FRONT-29019

    switch (action.name) {
      case "edit_line_item":
        this.handleEditLineItem(this.selectedItem);
        break;
      case "remove_line_item": //FRONT-20111 Testing code
        console.log("Inside remove line item");
        this.refs.selectedItemRemoveModal.toggleModal();
        break;

      default:
        break;
    }
  }

  handleEditLineItem(selectedRow) {
    this.modalHeader = selectedRow.Name;
    //this.selectedItem = selectedRow;
    this.refs.contractItemEditorModal.toggleModal();
  }

  handleConfirm = (event) => {
    event.stopPropagation();
    this.template
      .querySelector("c-sbr_3_0_contract-line-item-editor-cmp")
      .saveLineItemData();
  };

  closeEditor = () => {
    this.refs.contractItemEditorModal.toggleModal();
    this.handleCancelModal();
  };

  handleCancelModal() {
    this.selectedItem = null;
    refreshApex(this.wiredLineItemsResult);
  }

  handleCloseModal() {
    this.refs.contractItemEditorModal.toggleModal();
    refreshApex(this.wiredLineItemsResult);
  }

  toggleViewContent(event) {
    let currentItemId = event.target.dataset.lineItemId;
    let toggleType = event.target.dataset.toggleType;
    this.salesLineItems = this.salesLineItems.map((item) => {
      if (item.Id === currentItemId) {
        if (toggleType === "ViewMore") {
          return {
            ...item,
            ViewMore: !item.ViewMore
          };
        } else if (toggleType === "Notes") {
          return {
            ...item,
            hideNotes: !item.hideNotes
          };
        }
      }
      return item;
    });
  }

  //Front-15728 start
  handleRemoveAction(event) {
    this.isShowRemove = true;
    this.lineItemId = event.currentTarget.dataset.id;
  }
  handleNo() {
    this.isShowRemove = false;
    this.lineItemId = "";
  }
  async removeItem() {
    this.isLoading = true;
    await deleteRecord(this.lineItemId)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            message: "Your item has been removed.",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error deleting record",
            message: error,
            variant: "error"
          })
        );
        logger.log("error in deleting Order Item:", JSON.stringify(error.body));
      });

    refreshApex(this.wiredLineItemsResult);
    this.isLoading = false;
    this.isShowRemove = false;
    this.lineItemId = "";
  }
  //Front-15728 end

  renderedCallback() {
    if (!this.hasCSSLoaded) {
      Promise.all([loadStyle(this, borderStyle), loadStyle(this, FrontLineCSS)])
        .then(() => {
          logger.log("Files loaded");
          this.hasCSSLoaded = true;
        })
        .catch((error) => {
          logger.log("error in" + JSON.stringify(error));
        });
    }
  }
  //START: FRONT-29004
  handleLineItemSelection(event) {
    //Modified for 29022
    this.selectedRows = event.detail.selectedRows;
    logger.log("====selectedRows====", JSON.stringify(this.selectedRows));
    if (this.selectedRows) {
      if (this.selectedRows.length > 0) {
        this.isRemoveItemsDisabled = false;
      } else {
        this.isRemoveItemsDisabled = true;
      }
      if (this.selectedRows.length > 1) {
        this.isEditAllDisabled = false;
      } else {
        this.isEditAllDisabled = true;
      }
    }
  }

  // FRONT-15261 START
  handleEditClick(event) {
    this.selectedItemName =
      this.salesLineItems[event.target.dataset.index].Name;
    this.selectedItem = this.salesLineItems[event.target.dataset.index];
    this.showEditor = true;
  }
  handleCancel() {
    this.showEditor = false;
    this.lineItemId = "";
  }

  handleCloseEditor() {
    this.showEditor = false;
    refreshApex(this.wiredLineItemsResult);
  }
  // FRONT-15261 END
  //Front-29022 start
  handleRemoveItemsToggle() {
    const toggleRemoveItems =
      this.refs.selectedAllItemRemoveModal.toggleModal();
  }
  handleRemoveSelectedLineItems = () => {
    const selectedRemovedItems =
      this.refs.itemBulkRemove.getSelectedRemovedRows();
    if (selectedRemovedItems.length > 0) {
      this.isConfirm = true;
      this.deleteOrderItemList(selectedRemovedItems);
    }
  };
  handleRemoveItemsCloseButtonClick = () => {
    this.handleRemoveItemsToggle();
  };
  async deleteOrderItemList(selectedRemovedItems) {
    let orderItemList = [];
    selectedRemovedItems.forEach((row) => {
      let orderItemObj = {};
      orderItemObj.Id = row.hasOwnProperty("Id") ? row.Id : row;
      orderItemList.push(orderItemObj);
    });
    await this.handleDelete(orderItemList);
    this.isConfirm = false;
    if (!this.isMobile) {
      this.handleRemoveItemsToggle();
    } else {
      this.handleRemoveCancel();
    }
  }
  //end for FRONT-29022

  //FRONT-29019
  async handleDelete(orderItemList) {
    await deleteOrderItems({ orderItemList: orderItemList })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "",
            message: "Your item(s) has been removed.",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        logger.log("Error is" + JSON.stringify(error));
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: JSON.stringify(error),
            variant: "Error"
          })
        );
      });
    refreshApex(this.wiredLineItemsResult);
  }

  disableConfirmButton(event) {
    this.disableConfirm = event.detail.disableConfirm;
  }

  //FRONT-29019
  removeLineItem = () => {
    this.handleRemoveLineItem();
  };

  //FRONT-29019
  async handleRemoveLineItem() {
    this.props = {
      isDisable: true
    };
    let orderItemList = [];
    const row = this.selectedItem;

    let orderItemObj = {};
    orderItemObj.Id = row.hasOwnProperty("Id") ? row.Id : row;
    orderItemList.push(orderItemObj);

    await this.handleDelete(orderItemList);
    this.refs.selectedItemRemoveModal.toggleModal();
    this.props = {
      isDisable: false
    };
  }

  //FRONT-29023
  handleCheckboxChange(event) {
    let id = event.target.dataset.id;
    if (event.detail.checked) {
      this.selectedRecordstoRemove.push(id);
    } else {
      const index = this.selectedRecordstoRemove.indexOf(id);
      console.log("index: ", index);
      if (index > -1) {
        this.selectedRecordstoRemove.splice(index, 1);
      }
    }
    const selectedEvent = new CustomEvent("multiselected", {
      bubbles: true,
      composed: true,
      detail: {
        selectedRecordstoRemove: this.selectedRecordstoRemove,
        lineItemType: "Consumables"
      }
    });
    this.dispatchEvent(selectedEvent);
  }

  //FRONT-29023
  @api
  selectAllCheckbox() {
    let i;
    let checkBoxes = this.template.querySelectorAll(".isChecked");
    console.log("checkBoxes", checkBoxes[0].checked);
    this.selectedRecordstoRemove = [];

    for (i = 0; i < checkBoxes.length; i++) {
      logger.log("target", JSON.stringify(checkBoxes[i].dataset.id));
      this.selectedRecordstoRemove.push(checkBoxes[i].dataset.id);
      checkBoxes[i].checked = true;
      const selectedEvent = new CustomEvent("multiselected", {
        bubbles: true,
        composed: true,
        detail: {
          selectedRecordstoRemove: this.selectedRecordstoRemove,
          lineItemType: "Consumables"
        }
      });
      this.dispatchEvent(selectedEvent);
    }
  }

  //FRONT-29023
  @api
  set showRemoveScreenSales(value) {
    logger.log("ShowRemove Screen Called Sales" + value);
    this._showRemoveScreenSales = value;
    if (value) {
      this.handleRemoveScreen(this.selectedRecordstoRemove);
    }
  }

  get showRemoveScreenSales() {
    logger.log("showRemoveCall from UI Sales");
    return this._showRemoveScreenSales;
  }

  //FRONT-29023
  handleRemoveScreen(lineItemsToRemoveMobile) {
    logger.log("under handleAttributeChange Sales");
    let recordstoshow = [];
    recordstoshow = this.salesLineItems.filter((item1) => {
      return lineItemsToRemoveMobile.some((item2) => item2 === item1.Id);
    });
    this.lineItemsListToRemove = [];
    this.lineItemsListToRemove = recordstoshow;
    const addingattribute = this.lineItemsListToRemove;
    for (let x of addingattribute) {
      x.isSelected = true;
    }
    this.finalrecordstoremove = this.lineItemsListToRemove;
  }

  //FRONT-29023
  handleRemove() {
    logger.log("under handle remove");
    this.selectedRecordstoRemove = [];
    if (this.finalrecordstoremove.length > 0) {
    this.deleteOrderItemList(this.finalrecordstoremove);
    }
  }

  //FRONT-29023
  handleRemoveCancel() {
    this.selectedRecordstoRemove = [];
    const selectedEvent = new CustomEvent("cancelsalesclick", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(selectedEvent);
  }

  //FRONT-29023
  finalRecordstoRemove(event) {
    logger.log("under finalselectedSales");
    this.finalrecordstoremove = [];
    this.selectedRecordstoRemove = [];
    this.finalrecordstoremove = event.detail;
  }
}