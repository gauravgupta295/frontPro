import { LightningElement, api, track, wire } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import getContractRentalLineItems from "@salesforce/apex/Sbr_3_0_ContractController.getContractRentalLineItems";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import noRentalItemSvg from "@salesforce/resourceUrl/Sbr_3_0_NoRentalItemSVG";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { refreshApex } from "@salesforce/apex"; //Front-16656
import getProductItem from "@salesforce/apex/SBR_3_0_AssetController.getProductItem";
import getLoggedInUserBranchLocation from "@salesforce/apex/SBR_3_0_AssetController.getLoggedInUserBranchLocation"; // FRONT-20221
import getAssetList from "@salesforce/apex/SBR_3_0_AssetController.getAssetList"; // FRONT-20221
import deleteOrderItems from "@salesforce/apex/Sbr_3_0_ContractController.deleteContractLineItems"; //FRONT-28588
import { NavigationMixin } from "lightning/navigation";
//start for 31380
import { createRecord } from "lightning/uiRecordApi";
import borderStyle from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import { loadStyle } from "lightning/platformResourceLoader";
import {
  publish,
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext
} from "lightning/messageService";
import lineItemUpdate from "@salesforce/messageChannel/sbr_3_0_contractLineItemsUpdate__c";
//end for 31380
const logger = Logger.create(true);
const iconName = "standard:lead_list";
const serializedLineActions = [
  { label: "Asset Details", name: "view_line_item_asset" },
  { label: "Edit", name: "edit_order_line" },
  { label: "Remove Item", name: "remove_order_line" }
];
const bulkLineActions = [
  { label: "Product Details", name: "view_line_item" },
  { label: "Edit", name: "edit_order_line" },
  { label: "Remove Item", name: "remove_order_line" }
];
const EXCLUDED_RENTAL_COLUMNS_NAMES = [
  "Sale_Price",
  "Contingency_Cost",
  "Seasonal_Multiplier"
];
const RENTAL_ITEMS = "Rental Items";
export default class Sbr_3_0_contractLineItemsRentalsCmp extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;
  activeTab;
  assetSearchPlaceholder = "Add Valid Asset #";
  assetSearchPlaceholderMobile = "Add Valid Asset #";
  isMobile = isMobile;
  iconName = iconName;
  sectionName = RENTAL_ITEMS;
  @track rentalItemsDynamicLabel = RENTAL_ITEMS;
  @track isReadOnlyRecord;
  @api lineItemsCols = [];
  searchKey;
  hideEditorFooter;
  hasDataLoaded = false;
  @track lineItemsRecords = [];
  @track lineItemNotes;
  @track notes = "";
  rowId;
  LABELS = LABELS;
  location; // FRONT-20221
  @track selectedAssetRow;
  @track selectedRows; // FRONT-28588
  rentalLineItems = [];
  noItemUrl = noRentalItemSvg;
  isConfirm = false; //Front-16656
  showRemoveItemModal = false; //Front 20111 Analysis
  wiredLineItemsResult; //Front-16656  and Front-20676
  _disableRemoveItem = true;
  actionName = "";
  isEditorRateShow = false;
  showEditScreen = false; //FRONT-31374
  assetNotFound = false; //FRONT-31380,31385
  @track lineItemsListToRemove = []; //added for FRONT-31384 - Mobile Change
  @track finalrecordstoremove = []; //added for FRONT-31384 - Mobile Change
  //isSelected = false; //added for FRONT-31384 - Mobile Change
  @track props = { isDisable: false };
  @track selectedRecordstoRemove = []; //added for FRONT-31384 - Mobile Change
  isEditAllDisabled = true; //FRONT-20115


  @wire(getContractRentalLineItems, { recordId: "$recordId" })
  lineItems(result) {
    this.wiredLineItemsResult = result; //Front-16656  and Front-20676
    if (result.data) {
      this.lineItemsRecords = result.data;

      this.rentalItemsDynamicLabel =
        this.sectionName + " (" + this.lineItemsRecords.length + ")";
      this.hasDataLoaded = true;
      this.buildRecords();
    } else if (result.error) {
      logger.log(result.error);
    }
  }
  //start for Front-16656
  // FRONT-20221
  @wire(getLoggedInUserBranchLocation) getLoggedInUserBranchLocation({
    error,
    data
  }) {
    if (data) {
      console.log("location loaded");
      this.location = data;
    } else if (error) {
      console.log("error on location:", error);
      this.error = error;
    }
  }
  @wire(MessageContext)
  messageContext;

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
          //colItem.type = "text";
          colItem.typeAttributes = {
            //FRONT-30483
            currencyCode: "USD"
          };
          colItem.cellAttributes = {
            alignment: "left"
          };
        }
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
        }

        if (colItem.fieldName === "AssetName") {
          colItem.typeAttributes = {
            label: { fieldName: "AssetName" },
            fieldName: "AssetName",
            variant: "base"
          };
        }

        if (
          colItem.fieldName === "Current_MiHr" ||
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
      columns.push({
        type: "action",
        typeAttributes: {
          rowActions: this.getRowActions.bind(this),
          menuAlignment: "Auto"
        }
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

  buildRecords() {
    //Front-16656 and Front-20676
    this.rentalLineItems = [];
    if (this.lineItemsRecords.length > 0) {
      this.lineItemsRecords.forEach((record) => {
        logger.log("RentalItems" + JSON.stringify(record));

        let row = {};
        row.Id = record.Id;
        row.Name = record.Product2?.Name;
        row.Notes = record.Line_Comments__c;
        row.CatClass = record.Product2.PPA_CatClass__c; //FRONT-30483
        row.AssetId = record.SBQQ__Asset__c; //FRONT-16654
        row.AssetName = record.Product2.Bulk_Item__c
          ? record.Product2.itemNumberUsedByReservationsRentalOut__c
          : record.SBQQ__Asset__r?.Name;

        row.AssetHeader = "Asset # " + row.AssetName;
        row.isBulkAsset = record.Product2.Bulk_Item__c ? true : false;
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
        row.Product2 = {};
        row.Product2.Product_SKU__c = record.Product2.Product_SKU__c;
        row.ProductName = record.Product2?.Name;
        row.Product2.PPA_CatClass__c = record.Product2.PPA_CatClass__c;
        logger.log("record.Min_Rate__c;" + record.Min_Rate__c);
        row.Min_Rate =
          record.Min_Rate2__c; /* && String(record.Min_Rate2__c).charAt(0) !== "$"? "$" + Number(record.Min_Rate2__c).toFixed(2)*/
        // : record.Min_Rate2__c;   //FRONT-30483
        //row.Min_Rate2 = record.Min_Rate2__c;
        row.Discount_Percentage = record.Discount_Percentage__c;
        row.Daily_Rate =
          record.Daily_Rate2__c; /*&& String(record.Daily_Rate2__c).charAt(0) !== "$"? "$" + Number(record.Daily_Rate2__c).toFixed(2)*/
        // : record.Daily_Rate2__c;  //FRONT-30483
        row.Weekly_Rate =
          record.Weekly_Rate2__c; /*&& String(record.Weekly_Rate2__c).charAt(0) !== "$"? "$" + Number(record.Weekly_Rate2__c).toFixed(2)*/
        //: record.Weekly_Rate2__c;   //FRONT-30483
        row.Monthly_Rate =
          record.Monthly_Rate2__c; /*&& String(record.Monthly_Rate2__c).charAt(0) !== "$" ? "$" + Number(record.Monthly_Rate2__c).toFixed(2)*/
        //  : record.Monthly_Rate2__c; //FRONT-30483
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
        //16656-start
        row.oldMeter = record.SBQQ__Asset__r?.SM_PS_MiHr_Old_meter__c;
        row.mihrMeter = record.SBQQ__Asset__r?.SM_PS_Meter_Code_MIHR__c;
        row.meterCode = record.SBQQ__Asset__r?.SM_PS_Meter_2_Code__c;
        //16656 end
        //start FRONT-31374
        row.noCharge = record.Free_Flag__c;
        row.dateOutVarMobile = record.Date_Time_Out__c;
        row.dateVar = record.Date_Time_Out__c;
        //end FRONT-31374
        this.rentalLineItems.push(row); // push(record);
      });
      logger.log("rentalItems" + this.rentalLineItems.length);
    }

    //return this.rentalLineItems;
  }

  handleTabClicked(event) {
    console.log("event called in parent");
    this.hideEditorFooter = event.detail.ratematrix;
  }

  handleBack() {
    if (!this.assetNotFound) {
      this.hideEditorFooter = false;
      const childComponent = this.template.querySelector(
        "c-sbr_3_0_item-search-select-asset-container-cmp"
      );
      childComponent.editorDisplay = "editor show";
    }
    this.assetNotFound = false; //31380,31385
  }

  handleCloseModal() {
    if (this.isMobile) {
      this.isConfirm = false;
      this.isEditorRateShow = false;
      this.showEditScreen = false;
    } else {
      this.selectedAssetRow = null;
    }
  }

  // FRONT-20221 Starts
  handleQuickAddDesktop(event) {
    console.log("event", event.key);
    if (event.keyCode === 13) {
      this.searchKey = event.target.value;

      let assetListParamObject = {
        actvTab: "Asset",
        searchKey: this.searchKey
      };

      getAssetList({ params: assetListParamObject })
        .then((data) => {
          logger.log("result of apex :- " + JSON.stringify(data));
          logger.log("User location :- " + JSON.stringify(this.location));
          let isAssetAlreadyAdded = false;
          if (data.length > 0) {
            logger.log(
              "Asset location :- " +
              JSON.stringify(data[0].SM_PS_Current_Branch_Location_Number__c)
            );
            if (
              data[0].Status === "AVAILABLE" &&
              this.location.Branch_Location_Number__c ===
              data[0].SM_PS_Current_Branch_Location_Number__c &&
              data[0].SM_PS_Equipment_Type__c === "RENTAL"
            ) {
              this.rentalLineItems.forEach((record) => {
                if (this.searchKey === record.AssetName) {
                  isAssetAlreadyAdded = true;
                }
              });
              if (!isAssetAlreadyAdded) {
                this.selectedAssetRow = data[0];
                //Added for Front-31380
                if (this.isMobile) {
                  this.modalHeader = `Asset # ${this.selectedAssetRow.Name}`;
                  this.isEditorRateShow = !this.isEditorRateShow;
                } else {
                  this.modalHeader = `Asset # ${this.selectedAssetRow.Name}`;
                  this.toggleEditorModalForQuickAdd();
                }
              }
            }
            //Front-31380, Front-31385
            else if (this.isMobile) {
              this.assetNotFound = true;
            }
          } else {
            this.fetchProdItems();
          }
        })
        .catch((error) => {
          logger.log("Error is " + JSON.stringify(error));
        });
    }
  }

  async fetchProdItems() {
    await getProductItem({ bulkAssetname: this.searchKey })
      .then((data) => {
        if (data.length > 0) {
          let isAssetAlreadyAdded = false;
          logger.log("data from ProductItem :: " + JSON.stringify(data));
          this.rentalLineItems.forEach((record) => {
            if (this.searchKey === record.AssetName) {
              isAssetAlreadyAdded = true;
            }
          });
          if (!isAssetAlreadyAdded) {
            this.selectedAssetRow = data[0];
            this.modalHeader = `Asset # ${this.selectedAssetRow.Product2.itemNumberUsedByReservationsRentalOut__c}`;
            if (this.isMobile) {
              this.isEditorRateShow = !this.isEditorRateShow;
            } else {
              this.toggleEditorModalForQuickAdd();
            }
          }
        }
        //Front-31380,31385
        else {
          this.assetNotFound = true;
        }
      })
      .catch((error) => {
        logger.log("Error is " + JSON.stringify(error));
      });
  }
  // FRONT-20221 Ends

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

  get isRecordListNotEmpty() {
    return this.rentalLineItems?.length > 0;
  }

  _parentRecord;
  @api get parentRecord() {
    return this._parentRecord;
  }
  set parentRecord(value) {
    this._parentRecord = value;
    this.setReadOnly();
  }

  get disableRemoveItem() {
    return this._disableRemoveItem;
  }

  set disableRemoveItem(value) {
    this._disableRemoveItem = value;
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
            title: "",
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

  handleRowAction(event) {
    const action = event.detail.action;
    this.selectedAssetRow = event.detail.row;
    console.log("selectedRow is :- " + JSON.stringify(this.selectedAssetRow));
    switch (action.name) {
      case "edit_order_line":
        this.actionName = "EditAction";
        this.editLineItem();
        break;
      case "remove_order_line": //FRONT-20111 Testing code
        console.log("Inside remove line item serialize");
        this.actionName = "RemoveAction";
        this.refs.selectedItemRemoveModal.toggleModal();
        break;
      case "view_line_item_asset":
        this.viewLineItemAsset();
        break;
      default:
        break;
    }
  }

  //Front-16656  and Front-20676
  editLineItem() {
    if (!this.isMobile) {
      this.modalHeader = `Asset # ${this.selectedAssetRow.AssetName}`;
      this.toggleEditorModal();
    }
  }
  viewLineItemAsset() {
    //FRONT-16654
    let assetId = this.selectedAssetRow.AssetId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: assetId,
        actionName: "view"
      }
    });
  }
  handleRowSave() { }
  handleLineItemSelection(event) {
    this.selectedRows = event.target.getSelectedRows(); // FRONT-28588
    if (this.selectedRows.length > 0) {
      this._disableRemoveItem = false;
    } else {
      this._disableRemoveItem = true;
    }
    //FRONT-20115 starts
    if (this.selectedRows.length > 1) {
      this.isEditAllDisabled = false;
    } else {
      this.isEditAllDisabled = true;
    }
    //FRONT-20115 ends
    logger.log("selectedRows", JSON.stringify(this.selectedRows));
  }

  getRowActions(record, doneCallback) {
    let actions;
    if (record.isBulkAsset) {
      actions = bulkLineActions;
    } else {
      actions = serializedLineActions;
    }
    doneCallback(actions);
  }

  toggleViewContent(event) {
    let currentItemId = event.target.dataset.lineItemId;
    console.log("@@currentItemId::", currentItemId);
    let toggleType = event.target.dataset.toggleType;
    this.rentalLineItems = this.rentalLineItems.map((item) => {
      console.log("@@item.Id::", item.Id);
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
  // set records(value) {
  //   this.rentalLineItems = value;
  // }

  //Front-16656  and Front-20676
  handleConfirm = () => {
    this.isConfirm = true;
    let orderItmObjRef;
    //Added for 31380
    if (this.actionName === "EditAction") {
      orderItmObjRef = this.refs.editRentalLineItem;
    } else if (this.isEditorRateShow) {
      orderItmObjRef = this.refs.orderItemObject;
    } else {
      orderItmObjRef = this.refs.RentalorderItemObject;
    }
    let stagedOrderItmRecord = orderItmObjRef.getUpdatedOrderItem();
    //Added for Front-31380
    if (stagedOrderItmRecord) {
      if (!this.isEditorRateShow) {
        this.updateOrderItemRecord(stagedOrderItmRecord);
      } else {
        this.createOrderItemRecord(stagedOrderItmRecord);
      }
    }
  };
  //Front-16656  and Front-20676
  handleCloseButtonClick = () => {
    this.toggleEditorModal();
    this.handleCloseModal();
  };
  //Front-16656  and Front-20676
  //on modal close resetting the selected Asset row variable
  // handleCloseModal() {
  //   this.selectedAssetRow = null;
  // }
  //Front-16656  and Front-20676
  toggleEditorModal() {
    console.log("called");
    const editorModal = this.template.querySelector(
      ".rentalassetcontainermodal"
    );
    if (editorModal) {
      editorModal.toggleModal();
    }
  }

  toggleEditorModalForQuickAdd() {
    console.log("called");
    const editorModal = this.template.querySelector(
      ".quickaddassetcontainermodal"
    );
    if (editorModal) {
      editorModal.toggleModal();
    }
  }
  //start for Front-16656
  async updateOrderItemRecord(orderItemProp) {
    if (orderItemProp.Id) {
      const fields = {};
      fields["Id"] = orderItemProp.Id;
      fields["Line_Comments__c"] = orderItemProp?.lineItemNotes;
      fields["Min_Rate__c"] = orderItemProp?.minRate;
      fields["Daily_Rate__c"] = orderItemProp?.day;
      fields["Weekly_Rate__c"] = orderItemProp?.week;
      fields["Monthly_Rate__c"] = orderItemProp?.fourWeek;
      fields["Meter_Reading_Out__c"] = orderItemProp?.HourMeterReading;
      fields["Discount_Percentage__c"] = orderItemProp?.rateDiscount;
      fields["Quantity"] = orderItemProp?.itemQty;
      fields["Free_Flag__c"] = orderItemProp?.noCharge;
      fields["Date_Time_Out__c"] = this.isMobile
        ? orderItemProp?.dateOutVarMobile
        : "";
      const recordInput = {
        fields: fields
      };
      await updateRecord(recordInput)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "",
              message:
                this.selectedAssetRow.AssetName +
                " has been successfully updated.",
              variant: "success"
            })
          );
        })
        .catch((error) => {
          logger.log("error in create Order Item:", JSON.stringify(error.body));
        });
      refreshApex(this.wiredLineItemsResult);
    }
    this.isConfirm = false;
    this.showEditScreen = false;
    this.toggleEditorModal();
  }

  //end for Front-16656

  //start for FRONT-28588
  //FRONT-20111
  removeLineItem = () => {
    this.handleRemoveLineItem();
  };

  //FRONT-20111
  async handleRemoveLineItem() {
    this.props = {
      isDisable: true
    };
    let orderItemList = [];
    const row = this.selectedAssetRow;

    let orderItemObj = {};
    orderItemObj.Id = row.hasOwnProperty("Id") ? row.Id : row;
    orderItemList.push(orderItemObj);

    await this.handleDelete(orderItemList);
    this.refs.selectedItemRemoveModal.toggleModal();
    this.props = {
      isDisable: false
    };
  }

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
    this.refs.selectedAllItemRemoveModal.toggleModal();
  };

  handleRemoveItemsCloseModal() { }

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
      this.handleCancel();
    }
  }

  async handleDelete(orderItemList) {
    await deleteOrderItems({
      orderItemList: orderItemList
    })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "",
            message: "Your item(s) has been removed.",
            variant: "success"
          })
        );
        const messagePayload = {
          origin: "rentalLineItems",
          action: "refresh"
        };
        publish(this.messageContext, lineItemUpdate, messagePayload);
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
  //end for FRONT-28588

  //FRONT-31374
  handleEditClick(event) {
    this.modalHeader =
      this.rentalLineItems[event.target.dataset.index].AssetHeader;
    this.selectedAssetRow = this.rentalLineItems[event.target.dataset.index];
    this.showEditScreen = true;
  }
  //Front-31380
  async createOrderItemRecord(orderItemProp) {
    let orderItemObjectFields = {};
    let message = "";
    if (this.selectedAssetRow.Product2.Bulk_Item__c) {
      message =
        this.selectedAssetRow.Product2.itemNumberUsedByReservationsRentalOut__c;
      orderItemObjectFields = {
        OrderId: this.recordId,
        Product2Id: this.selectedAssetRow.Product2Id,
        Quantity: orderItemProp?.itemQty,
        UnitPrice: 0,
        Line_Comments__c: orderItemProp?.lineItemNotes,
        Discount_Percentage__c: orderItemProp?.rateDiscount,
        Min_Rate__c: orderItemProp?.minRate,
        Daily_Rate__c: orderItemProp?.day,
        Weekly_Rate__c: orderItemProp?.week,
        Monthly_Rate__c: orderItemProp?.fourWeek,
        Date_Time_Out__c: this.isMobile ? orderItemProp?.dateOutVarMobile : ""
      };
    } else {
      message = this.selectedAssetRow.Name;
      orderItemObjectFields = {
        OrderId: this.recordId,
        Product2Id: this.selectedAssetRow.Product2Id,
        Quantity: orderItemProp?.itemQty,
        UnitPrice: 0,
        Line_Comments__c: orderItemProp?.lineItemNotes,
        Discount_Percentage__c: orderItemProp?.rateDiscount,
        Min_Rate__c: orderItemProp?.minRate,
        Daily_Rate__c: orderItemProp?.day,
        Weekly_Rate__c: orderItemProp?.week,
        Monthly_Rate__c: orderItemProp?.fourWeek,
        Meter_Reading_Out__c: orderItemProp?.hourMeterReading,
        SBQQ__Asset__c: this.selectedAssetRow.Id,
        Date_Time_Out__c: this.isMobile ? orderItemProp?.dateOutVarMobile : ""
      };
    }
    let orderItemObject = {
      apiName: "OrderItem",
      fields: orderItemObjectFields
    };
    await createRecord(orderItemObject)
      .then((response) => {
        this.isEditorRateShow = false;
        const newEvent = new ShowToastEvent({
          title: "",
          message: message + " has been successfully added",
          variant: "success"
        });
        this.dispatchEvent(newEvent);
      })
      .catch((error) => {
        logger.log(
          "error in create Order Item:",
          JSON.stringify(error.body),
          error.status,
          error.statustext
        );
      });
    refreshApex(this.wiredLineItemsResult);
    this.isConfirm = false;
  }
  renderedCallback() {
    Promise.all([loadStyle(this, borderStyle)])
      .then(() => {
        logger.log("Files loaded");
      })
      .catch((error) => {
        logger.log(error.body.message);
      });
  }
  get showInputSearch() {
    if (!this.assetNotFound && !this.isEditorRateShow) {
      return true;
    }
  }
  //added for FRONT-31384 - Mobile Change
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
        lineItemType: "Rental"
      }
    });
    this.dispatchEvent(selectedEvent);
  }

  //Added for FRONT-31386
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
          lineItemType: "Rental"
        }
      });
      this.dispatchEvent(selectedEvent);
    }
  }

  //added for FRONT-31384 - Mobile Change
  handleCancel() {
    this.selectedRecordstoRemove = [];
    const selectedEvent = new CustomEvent("cancelclick", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(selectedEvent);
  }

  //added for FRONT-31384 - Mobile Change
  handleRemoveScreen(lineItemsToRemoveMobile) {
    logger.log("under handleAttributeChange");
    let recordstoshow = [];
    recordstoshow = this.rentalLineItems.filter((item1) => {
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

  //added for FRONT-31384 - Mobile Change
  _showRemoveScreen;
  @api
  set showRemoveScreen(value) {
    logger.log('ShowRemove Screen Called' + value);
    this._showRemoveScreen = value;
    if (value) {
      this.handleRemoveScreen(this.selectedRecordstoRemove);
    }
  }

  get showRemoveScreen() {
    logger.log('showRemoveCall from UI');
    return this._showRemoveScreen;
  }

  //added for FRONT-31384 - Mobile Change
  handleRemove() {
    logger.log("under handle remove");
    this.selectedRecordstoRemove = [];
    if (this.finalrecordstoremove.length > 0) {
    this.deleteOrderItemList(this.finalrecordstoremove);
    }
  }
  //added for FRONT-31384 - Mobile Change
  finalRecordstoRemove(event) {
    logger.log("under finalselected");
    this.finalrecordstoremove = [];
    this.selectedRecordstoRemove = [];
    this.finalrecordstoremove = event.detail;
  }

  //added for FRONT-3110 and FRONT-31111 - Mobile
  subscribeToMessageChannel() {
    this.subscription = subscribe(
      this.messageContext,
      lineItemUpdate,
      (message) => this.handleMessage(message)
    );
  }

  handleMessage(message) {
    refreshApex(this.wiredLineItemsResult);
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }
}