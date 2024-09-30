import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import deleteLineItems from "@salesforce/apex/SBR_3_0_LineItemCartCmpController.deleteLineItems";
import {
  getRecord,
  createRecord,
  deleteRecord,
  updateRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getProductKitComponents from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents";
//START-FRONT-7652,7653
import { loadStyle } from "lightning/platformResourceLoader";
import FrontLineCSS from "@salesforce/resourceUrl/FrontLinesCSS";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import saveSObjects from "@salesforce/apex/SBR_3_0_LineItemEditorCmpController.saveSObjects"; //FRONT-8694
//END-FRONT-7652,7653

import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);
export default class Sbr_3_0_lineItemsGridSectionCmp extends NavigationMixin(
  LightningElement
) {
  //Start FRONT-7977
  ADMIN_PROFILE_NAME = "System Administrator";
  LOCKED_RESERVATION_ORDER = "Locked Reservation Order";
  //End FRONT-7977
  @track kitCompArray = [];
  @track showCustomKitItem = false;
  isLoading = false;
  @track lineItems = []; //All Line Items
  @track disableEdit = false;
  @track lineId = "";
  @track selectedItemGroup = "";
  @track lineItemEditorDisplay = false;
  @track displaySubstituteDisplay = false;
  @track itemListDisplay = true;
  @api recordId;
  @api objectApiName;
  @track itemSelected;
  @track selectedRowsCount = 0;
  removeNotChecked = true;

  @api isMobile;
  @api label;
  @api accname;
  @api recordTypeName;
  @api iconName;
  @api columns;
  @api disableRemoveItem;
  @api disableBulkEdit;
  @api records;
  @api draftValues;
  @api draftErrors;
  //Start FRONT-7977
  @api currentUserRecord;
  @api parentRecord;
  //End FRONT-7977
  @api customerInfo;
  @api hidesubtotalcolumn; //Added as part of FRONT-9236
  lineItemName = ""; //FRONT-1906
  lineItemId;
  lineItemNoAvailabilityClass = "no-availability";
  showTooltip = false;
  _disableRemoveItem = true;
  _iconName = "standard:lead_list";
  showTabSet = false; //FRONT -1670, FRONT-1906
  selectedRecord = []; //FRONT - 6268
  isRentalOrFrontlineOrAccountRecordType = false;
  //START-FRONT-7652,7653
  isCancel = false;
  showCancelLineItem = false;
  cancelSelectedRows = [];
  selectedRowsToCancel = [];
  showCancel = false;
  labels = LABELS;
  _props;
  _orderStatus;
  _appNameFL;
  _orderRecordType;
  _accntRecordTypeName;
  recordsLength = 0; //FRONT-7655
  rentalItems = false; //FRONT-7655
  orderIsPartiallyFilled = false; //FRONT-9234
  /*START: FRONT-1958 */
  totalRequestedQuantity = 0;
  filledQuantity = 0;
  remainingQuantity = 0;
  /*END: FRONT-1958 */
  rendered = false; //FRONT-10479

  @api isReadOnly = false; //FRONT-11421 if false,
  _variantType;
  @api
  get variantType() {
    return this._variantType;
  }
  set variantType(value) {
    this._variantType = value;
  }
  @api
  get props() {
    return this._props;
  }

  set props(value) {
    this._props = value;
    this.init();
  }

  init() {
    this.setOrderStatus();
    this.setAppName();
    this.setRecordTypeName();
    this.setAccntRecdTypeNme();
    this.setCondition();
  }

  setOrderStatus() {
    this._orderStatus = this.props.orderStatus;
  }

  setAppName() {
    this._appNameFL = this.props.appNameFL;
  }

  @api
  setApplicationName(app) {
    this._appNameFL = app;
    this.showOrHideMinimumRateFld();
  }

  setRecordTypeName() {
    this._orderRecordType = this.props.orderRecordTypeName;
  }

  setAccntRecdTypeNme() {
    this._accntRecordTypeName = this.props.accountRecordTypeName;
  }

  setCondition() {
    if (
      this._appNameFL === "RAE Frontline" &&
      this.objectApiName === "Order" &&
      (this._orderStatus === "Draft" ||
        this._orderStatus === "Created" ||
        this._orderStatus === "Partially Filled") &&
      this._orderRecordType === "Reservation Order"
    ) {
      //Added Partially Filled condition as part of FRONT-9206
      this.showCancelLineItem = true;
      this.showCancel = true;
    } else {
      this.showCancelLineItem = false;
    }
    this.showOrHideMinimumRateFld();

    //FRONT-9234 Start
    if (
      this.objectApiName === "Order" &&
      this._orderStatus === "Partially Filled"
    ) {
      this.orderIsPartiallyFilled = true;
    }
    //FRONT-9234 End
  }
  //END-FRONT-7652,7653

  showOrHideMinimumRateFld() {
    if (this.isRental && this._appNameFL === "RAE Frontline") {
      if (
        this.objectApiName === "SBQQ__Quote__c" &&
        (this._accntRecordTypeName == "Prospect" ||
          this._accntRecordTypeName == "Credit" ||
          this._accntRecordTypeName == "Non-Credit" ||
          this._accntRecordTypeName == "Corp Link")
      ) {
        this.isRentalOrFrontlineOrAccountRecordType = true;
      } else if (
        this.objectApiName === "Order" &&
        (this._accntRecordTypeName == "Guest" ||
          this._accntRecordTypeName == "Credit" ||
          this._accntRecordTypeName == "Non-Credit" ||
          this._accntRecordTypeName == "Corp Link")
      ) {
        this.isRentalOrFrontlineOrAccountRecordType = true;
      }
    }
  }

  removeItems = (event) => {
    this.isLoading = true;
    // TODO : remove line below after tests
    //this.isMobile = true;

    event?.stopPropagation();
    this.closeModal(event);
    if (this.isMobile) {
      let removeItemsIndexArray = [];
      let indexOfItemsSelected = [];
      let recordIdsToDelete = [];
      let selectedRows = [];
      let itemsSelected = [];
      let removeItemRows;

      var elems = this.template.querySelectorAll("lightning-input");
      elems.forEach((element, index) => {
        if (element.checked) {
          removeItemsIndexArray.push(element.value);
          indexOfItemsSelected.push(index);
          selectedRows.push(element.value);
          itemsSelected.push(element);
        }
      });
      for (let i = removeItemsIndexArray.length - 1; i >= 0; i--) {
        let currIndex = removeItemsIndexArray[i];
        recordIdsToDelete.push(currIndex);
        // this.lineItems.splice(currIndex, 1);
      }

      if (this.objectApiName === "Order") {
        deleteLineItems({ lineIds: recordIdsToDelete })
          .then((data) => {
            this.records = this.records.filter(
              (row) => !selectedRows.includes(row.Id)
            );
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items deleted.",
                variant: "success"
              })
            );
            this.isLoading = false;
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error deleting Line Items",
                message: error,
                variant: "error"
              })
            );
            this.isLoading = false;
          });
      }
      //SAL-25840
      else if (this.objectApiName == undefined) {
        logger.log("I am PI page");

        this.records = this.records.filter(
          (row) => !selectedRows.includes(row.Id)
        );
        // this.updateLineItemGridData(this.records);
        const updateDetails = new CustomEvent("updateitemdata", {
          detail: this.records
        });
        this.dispatchEvent(updateDetails);
        logger.log(
          "## 2....check length lineitems in grid cmp... ",
          this.records.length
        );
        this.isLoading = false;

        if (this.variantType !== "Sales") {
          this.fireClearSelectedRecordEvent();
        }
      } else {
        removeItemRows = recordIdsToDelete.map((row) => deleteRecord(row));

        Promise.all(removeItemRows)
          .then((deletedItems) => {
            this.lineItems = this.lineItems.filter(
              (row) => !selectedRows.includes(row.Id)
            );
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items deleted.",
                variant: "success"
              })
            );
            this.isLoading = false;
          })
          .catch((deletedItemsError) => {
            logger.error("item delete error:", deletedItemsError.body.message);
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error deleting Line Items",
                message: deletedItemsError.body.message,
                variant: "error"
              })
            );
            this.isLoading = false;
          });
      }

      this.itemSelected = false;
    } else {
      this.isLoading = true;
      //let selectedRows = this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').selectedRows;
      let selectedRows = this.itemsToRemove;
      let removeItemRows;

      if (this.objectApiName === "Order") {
        deleteLineItems({ lineIds: selectedRows })
          .then((data) => {
            this.lineItems = this.lineItems.filter(
              (row) => !selectedRows.includes(row.Id)
            );
            this.updateLineItemGridData(this.lineItems);
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items deleted.",
                variant: "success"
              })
            );
            this.isLoading = false;
          })
          .catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error deleting Line Items",
                message: error,
                variant: "error"
              })
            );
            this.isLoading = false;
          });
      } else {
        removeItemRows = selectedRows.map((row) => deleteRecord(row));

        Promise.all(removeItemRows)
          .then((deletedItems) => {
            this.updateLineItemsTable();
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Success",
                message: "Line Items deleted.",
                variant: "success"
              })
            );
            this.isLoading = false;
          })
          .catch((deletedItemsError) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error deleting Line Items",
                message: deletedItemsError.body.message,
                variant: "error"
              })
            );
            this.isLoading = false;
          });
      }
      this.template.querySelector(".removeModal").toggleModal();
    }
  };

  //method to toggle item selected sticky footer when line items are selected/deselected
  handleRowSelection(event) {
    let tempArray = JSON.parse(JSON.stringify(this.records));
    let r = event.target;
    let i = tempArray.findIndex((e) => e.Id === r.value);
    let elements = this.template.querySelectorAll("lightning-input");
    let element = elements[i];
    element.checked = r.checked;
    setTimeout(() => {
      this.getRowInfos(elements);
    }, 200);

    /* FRONT-11379 */
    const selectedCountEvt = {
      detail: {
        variantType: this._variantType,
        selectedRecord: this.records[i],
        isChecked: r.checked
      }
    };

    this.dispatchEvent(new CustomEvent("selectedcountevt", selectedCountEvt));
    /* END : FRONT-11379 */
  }

  getRowInfos(arr) {
    this.selectedRowsCount = 0;
    this.itemSelected = false;
    for (let j = 0; j < arr.length; j++) {
      if (arr[j].checked) {
        //this.itemSelected = true;
        this.selectedRowsCount++;
      }
    }
    this.itemSelected = this.selectedRowsCount > 0 ? true : false;
    //START-FRONT-7652
    if (this.itemSelected > 0 && this.showCancelLineItem) {
      this.showCancel = true;
    } //END-FRONT-7652
    //Start FRONT-1931
    if (this._orderRecordType === this.LOCKED_RESERVATION_ORDER) {
      this.itemSelected = false;
      this.showCancel = false;
    }
    //End FRONT-1931
  }

  //method to handle actions in the selection panel on mobile
  selectionPanelActions(event) {
    switch (event.target.value) {
      case "selectAll":
        let elems = this.template.querySelectorAll("lightning-input");
        elems.forEach((element) => {
          if (!element.disabled) {
            //Added as part of FRONT-9206
            element.checked = true;
          }
        });
        this.getRowInfos(elems);
        break;
      case "remove":
        this.removeItems();
        break;
    }
  }

  toggleRemoveModal() {
    this.template.querySelector(".removeModal").toggleModal();
  }

  closeModal(ev) {
    this.template.querySelector(".removeModal")?.closeModal(ev);
  }
  get disableRemoveItem() {
    return this._disableRemoveItem;
  }

  set disableRemoveItem(value) {
    this._disableRemoveItem = value;
  }

  get disableBulkEdit() {
    //Start FRONT-7977
    let currentUserProfileName =
      this.currentUserRecord.fields.Profile?.value?.fields?.Name?.value;
    //FRONT-11421 Add disable bulk edit here for isReadOnly for Reservation Order otherwise existing condition
    if (this.objectApiName === "Order") {
      if (this.isReadOnly && this._orderRecordType === "Reservation Order") {
        return true;
      } else {
        return (
          (!this.records && this.records.length === 0) ||
          this.parentRecord.fields.Record_Type_Name__c?.value ===
            this.LOCKED_RESERVATION_ORDER ||
          ((this.parentRecord.fields.Reservation_Order_Number__c?.value ||
            this.parentRecord.fields.Contract_Order_Number__c?.value) &&
            currentUserProfileName !== this.ADMIN_PROFILE_NAME)
        );
      }
    } else if (this.objectApiName === "SBQQ__Quote__c" && this.isReadOnly) {
      //FRONT-10503 Disable for read only quotes.
      return true;
    } else {
      //End FRONT-7977
      return !this.records && this.records.length === 0;
    }
  }

  get iconName() {
    return this._iconName;
  }

  set iconName(value) {
    this._iconName = value;
  }

  get isRecordListNotEmpty() {
    return this.records?.length > 0;
  }

  get showHeaderButtons() {
    return this.objectApiName != undefined && this.objectApiName != "Cart__c";
  }

  get isQuoteOrOrder() {
    if (
      this.objectApiName === "SBQQ__Quote__c" ||
      this.objectApiName === "Order"
    ) {
      return true;
    } else {
      return false;
    }
  }

  get isAncillary() {
    return this.label && this.label.toLowerCase().includes("ancillary");
  }

  get isRentalOrSales() {
    return this.isRental || this.isSales;
  }

  get isSalesOrAncillary() {
    return this.isAncillary || this.isSales;
  }

  get isRentalOrSalesOrDelivery() {
    return this.isRental || this.isSales || this.isDelivery;
  }

  get isRentalOrSalesOrAncillary() {
    return this.isRental || this.isSales || this.isAncillary;
  }

  get isDelivery() {
    return this.label && this.label.toLowerCase().includes("delivery");
  }

  get isRental() {
    return this.label && this.label.toLowerCase().includes("rental");
  }
  get isSales() {
    return this.label && this.label.toLowerCase().includes("sales");
  }

  get itemListDisplayClass() {
    return this.itemListDisplay
      ? "hidden-mob-container show"
      : "hidden-mob-container";
  }
  get lineItemEditorDisplayClass() {
    return this.lineItemEditorDisplay
      ? "hidden-mob-container show"
      : "hidden-mob-container";
  }

  /* FRONT : 24214 */
  get showSubstituteLineItemButton() {
    logger.log("👉 sales check" + this.label + " <bool> " + this.isSales);
    return !this.isSales;
  }

  connectedCallback() {
    this.loadStyleSheet(); //FRONT-7652
  }

  /*START: FRONT-10479 */
  renderedCallback() {
    if (!this.rendered) {
      this.rendered = true;
      this.records.forEach((rec) => {
        if (rec.fullyConvertedItem) {
          let customStyle =
            `.manual-override-section .slds-table tr[data-row-key-value="` +
            rec.Id +
            `"] td:nth-child(1) .slds-checkbox {
            display : none !important;
          }`;
          const rootNode = this.template.ownerDocument;
          const newDiv = rootNode.createElement("div");
          newDiv.setAttribute("class", "manual-override-css");
          const styleNode = rootNode.createElement("style");
          if (styleNode.styleSheet) {
            styleNode.styleSheet.cssText = customStyle;
          } else {
            styleNode.appendChild(rootNode.createTextNode(customStyle));
          }
          newDiv.appendChild(styleNode);
          rootNode.body.appendChild(newDiv);
        }
      });
    }
  }
  /*END: FRONT-10479 */

  //START: FRONT-7652
  loadStyleSheet() {
    loadStyle(this, FrontLineCSS);
  }
  //END: FRONT-7652

  handleLineItemSelection(event) {
    let selectedRows = event.target.getSelectedRows();
    this.cancelSelectedRows = event.target.getSelectedRows(); //FRONT-7653
    //Start FRONT-7977
    if (this.objectApiName === "Order") {
      /*START: FRONT-10479 */
      this.cancelSelectedRows.forEach((rec) => {
        if (rec.fullyConvertedItem) {
          this.cancelSelectedRows = this.cancelSelectedRows.filter(
            (row) => row.fullyConvertedItem !== true
          );
        }
      });
      /*END: FRONT-10479 */
      let currentUserProfileName =
        this.currentUserRecord.fields.Profile?.value?.fields?.Name?.value;
      if (
        (this.parentRecord.fields.Reservation_Order_Number__c?.value ||
          this.parentRecord.fields.Contract_Order_Number__c?.value) &&
        currentUserProfileName !== this.ADMIN_PROFILE_NAME &&
        this.parentRecord.fields.Record_Type_Name__c?.value ===
          this.LOCKED_RESERVATION_ORDER
      ) {
        this._disableRemoveItem = true;
      } else if (selectedRows.length > 0) {
        this._disableRemoveItem = false;
      } else {
        this._disableRemoveItem = true;
      }
    } else {
      this._disableRemoveItem = selectedRows.length > 0 ? false : true;
    }
    //End FRONT-7977
  }

  handleItemAction(event) {
    let selectedRows = this.template.querySelector(
      "c-sbr_3_0_custom-data-table-cmp"
    ).selectedRows;
    const itemActionEvent = new CustomEvent("handleitemaction", {
      detail: {
        buttonName: event.target.dataset.name,
        selectedRows: selectedRows,
        isRental: event.target.dataset.isRental,
        isSales: event.target.dataset.isSales
      }
    });
    this.dispatchEvent(itemActionEvent);
  }

  //method to toggle line item editor on mobile
  editLineItemHandler(event) {
    this.selectedRecord = this.records[event.target.dataset.index];
    this.lineId = event.target.getAttribute("id").slice(0, 18);
    this.selectedItemGroup = event.target.getAttribute("data-groupid")
      ? event.target.getAttribute("data-groupid")
      : "";
    this.lineItemName = event.target.dataset.name; //FRONT-1906,1670
    this.itemListDisplay = false;
    /*START: FRONT-1958 */
    let selectedRecord = this.records[event.target.dataset.index];
    this.totalRequestedQuantity =
      selectedRecord.StatusCreated +
      selectedRecord.StatusFilled +
      selectedRecord.StatusCancel;
    if (selectedRecord.StatusFilled === null) {
      this.filledQuantity = 0;
    } else {
      this.filledQuantity = selectedRecord.StatusFilled;
    }
    this.remainingQuantity =
      this.totalRequestedQuantity -
      (selectedRecord.StatusFilled + selectedRecord.StatusCancel);
    /*END: FRONT-1958 */
    this.lineItemEditorDisplay = true;
  }
  closeLineItemEditor() {
    this.lineItemEditorDisplay = false;
    this.itemListDisplay = true;
  }

  substituteLineItemHandler(event) {
    this.selectedRecord = this.records[event.target.dataset.index];
    this.lineItemName = event.target.dataset.name;
    this.lineItemId = this.selectedRecord.id;
    this.itemListDisplay = false;
    this.displaySubstituteDisplay = true;
  }

  closeLineItemSubstituteDisplay() {
    this.displaySubstituteDisplay = false;
    this.itemListDisplay = true;
  }

  substituteLineItem(event) {
    this.closeLineItemSubstituteDisplay();
  }

  mobileSaveQuoteLine(event) {
    this.closeLineItemEditor();
    this.updateRecords(event); // FRONT-7383
    const showloading = new CustomEvent("showloading", {});
    this.dispatchEvent(showloading);
  }

  updateRecords(event) {
    let updatedObj = event.detail.data;

    this.records = this.records.map((fldValues) => {
      let obj = { ...fldValues };
      if (obj.Id == this.lineId) {
        try {
          obj.Min_Rate = updatedObj.Min_Rate__c;
        } catch (error) {}
        return obj;
      } else {
        return obj;
      }
    });
  }

  handleRowAction(event) {
    let selectedRows = this.template.querySelector(
      "c-sbr_3_0_custom-data-table-cmp"
    ).selectedRows;

    const rowActionEvent = new CustomEvent("handlerowaction", {
      detail: {
        newEvent: event,
        selectedRows: selectedRows
      }
    });
    logger.log("event, selectedRows", event, selectedRows);
    this.dispatchEvent(rowActionEvent);
  }

  handleRowSave(event) {
    let selectedRows = this.template.querySelector(
      "c-sbr_3_0_custom-data-table-cmp"
    ).selectedRows;
    const rowActionEvent = new CustomEvent("handlerowsave", {
      detail: {
        newEvent: event,
        selectedRows: selectedRows
      }
    });
    this.dispatchEvent(rowActionEvent);
  }
  mobileEditQuantity(event) {
    let updatedLineId = event.target.dataset.lineid;
    let updatedQuantity = event.target.value;
    const rowActionEvent = new CustomEvent("handlequantitysave", {
      detail: {
        lineid: updatedLineId,
        quantity: updatedQuantity
      }
    });
    this.dispatchEvent(rowActionEvent);
  }

  showKitComponents(event) {
    let index = Number(event.currentTarget.dataset.id);
    this.getKitItems(this.records[index], index);
  }

  async getKitItems(lineItem, index) {
    let data = [];
    try {
      let productId = lineItem.product ? lineItem.product : lineItem.Product;
      data = await getProductKitComponents({
        productId: JSON.parse(JSON.stringify(productId))
      });
      let tempData = JSON.parse(data);

      this.showCustomKitItem = !this.showCustomKitItem;
      if (this.records[index].kitItems.kitItemsValue.length == 0) {
        this.kitCompArray = tempData;
      }
    } catch (error) {
      logger.log("error in getKitComponents:");
      logger.log(error);
    }
  }
  handleTabSwitch(event) {
    logger.log("inside grid:");
  }
  //START: FRONT-7652,7653
  handleCancelItemAction() {
    if (!this.isMobile) {
      //FRONT-7656
      this.rentalItems = this.isRental; //FRONT-7655
      this.recordsLength = this.records.length; //FRONT-7655
    } //FRONT-7656
    this.isCancel = !this.isCancel;
    if (this.isMobile && this.selectedRowsCount === 1) {
      // FRONT-8694
      const closeCancelItemEvent = new CustomEvent("handleclosecancelmodel", {
        bubbles: true,
        composed: true
      });
      this.dispatchEvent(closeCancelItemEvent);
      var elems = this.template.querySelectorAll("lightning-input");
      elems.forEach((element, index) => {
        if (element.checked) {
          element.checked = false;
        }
      });
      this.selectedRowsCount = 0;
      this.itemSelected = false;
      this.showCancel = false;
    }
  }
  handleCancelChevronAction(event) {
    this.cancelSelectedRows = [];
    this.selectedRowsToCancel = [];
    let selectedRecord = this.records[event.target.dataset.index];
    this.cancelSelectedRows.push(selectedRecord);
    this.selectedRowsToCancel.push(selectedRecord.Id);
    // FRONT-8694
    const cancelItemEvent = new CustomEvent("componentload", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(cancelItemEvent);
    this.isCancel = true;
  }

  handleCancelbuttonAction() {
    //Start FRONT-7656
    this.rentalItems = this.isRental;
    this.recordsLength = this.records.length;
    //End FRONT-7656
    this.cancelSelectedRows = [];
    this.selectedRowsToCancel = [];
    var elems = this.template.querySelectorAll("lightning-input");
    elems.forEach((element, index) => {
      if (element.checked) {
        this.selectedRowsToCancel.push(element.value);
      }
    });

    this.cancelSelectedRows = this.records.filter((row) =>
      this.selectedRowsToCancel.includes(row.Id)
    );
    // FRONT-8694
    const cancelItemEvent = new CustomEvent("componentload", {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(cancelItemEvent);
    this.isCancel = true;
  }

  handleCancelAction(event) {
    if (this.isMobile) {
      // FRONT-8694
      const closeCancelItemEvent = new CustomEvent("handleclosecancelmodel", {
        bubbles: true,
        composed: true
      });
      this.dispatchEvent(closeCancelItemEvent);
      let recordsToDelete = event.detail.itemsToRemove; //FRONT-7654
      this.isLoading = true;
      let recordIdsToDelete = [];
      let orderItemsToUpdateCancelFlag = []; //FRONT-8694
      //START: FRONT-7654
      for (let i = recordsToDelete.length - 1; i >= 0; i--) {
        let currIndex = recordsToDelete[i];
        recordIdsToDelete.push(currIndex.Id);
        /* START FRONT-8694*/
        let newItem = {
          Id: recordsToDelete[i].Id,
          Item_Marked_For_Cancellation__c: true,
          is_Line_Item_Hidden__c: true
        };
        orderItemsToUpdateCancelFlag.push(newItem);
        /* END FRONT-8694*/
      } //END: FRONT-7654
      if (this.objectApiName === "Order") {
        /* START FRONT-8694*/
        if (this._orderStatus == "Created") {
          this.updateLineItems(null, orderItemsToUpdateCancelFlag, "OrderItem");
          this.records = this.records.filter(
            (row) => !recordIdsToDelete.includes(row.Id)
          );
          this.isLoading = false;
          this.dispatchEvent(
            new ShowToastEvent({
              message: this.labels.LINE_ITEMS_CANCEL_SUCCESS,
              variant: "success"
            })
          );
          const itemActionEvent = new CustomEvent("updateparent", {
            detail: {
              updatedRecords: this.records,
              isRental: this.isRental,
              isSales: this.isSales
            }
          });
          this.dispatchEvent(itemActionEvent);
          if (recordIdsToDelete.length > 0) {
            var elems = this.template.querySelectorAll("lightning-input");
            elems.forEach((element, index) => {
              if (element.checked) {
                element.checked = false;
              }
            });
            this.selectedRowsCount = 0;
            this.itemSelected = false;
            this.showCancel = false;
          }
          /* END FRONT-8694*/
        } else {
          deleteLineItems({ lineIds: recordIdsToDelete })
            .then((data) => {
              //START: FRONT-7654
              this.records = this.records.filter(
                (row) => !recordIdsToDelete.includes(row.Id)
              ); //END: FRONT-7654
              this.isLoading = false;
              this.dispatchEvent(
                new ShowToastEvent({
                  message: this.labels.LINE_ITEMS_CANCEL_SUCCESS,
                  variant: "success"
                })
              );
              const itemActionEvent = new CustomEvent("updateparent", {
                detail: {
                  updatedRecords: this.records,
                  isRental: this.isRental,
                  isSales: this.isSales
                }
              });
              this.dispatchEvent(itemActionEvent);
              //START: FRONT-7654
              if (recordIdsToDelete.length > 0) {
                var elems = this.template.querySelectorAll("lightning-input");
                elems.forEach((element, index) => {
                  if (element.checked) {
                    element.checked = false;
                  }
                });
                this.selectedRowsCount = 0;
                this.itemSelected = false;
                this.showCancel = false;
              } //END: FRONT-7654
            })
            .catch((error) => {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: this.labels.SINGLE_ITEM_CANCEL,
                  message: error,
                  variant: "error"
                })
              );
            });
        }
      }
    } else {
      let actionName = "cancelItems";
      const itemActionEvent = new CustomEvent("handleitemaction", {
        detail: {
          buttonName: actionName,
          selectedRows: event.detail.itemsToRemove
        }
      });
      this.dispatchEvent(itemActionEvent);
    }
  }
  //END: FRONT-7652, FRONT-7653

  //FRONT-1674
  onlineItemTooltipClicked(event) {
    let selectedRecord = this.records[event.target.dataset.index];
    if (!selectedRecord.clicked) {
      selectedRecord.clicked = true;
    } else {
      selectedRecord.clicked = false;
    }
  }

  notificationFromSubstituteScreen(event) {
    this.displaySubstituteDisplay = false;
    this.itemListDisplay = true;
    const selectedEvent = new CustomEvent("eventnotification", {
      detail: event.detail
    });
    // Dispatches the event.
    this.dispatchEvent(selectedEvent);
  }

  /*FRONT-8793 The method shows or hides the tooltip in mobile view. */
  onIconClicked(event) {
    try {
      logger.log("👉 onIconClicked : ");
      let tooltipId = event?.target?.id;
      logger.log("👉 tooltipId : " + tooltipId);
      let tooltipDiv = this.template.querySelector(`div[id="${tooltipId}"]`);
      if (tooltipDiv) {
        if (
          tooltipDiv.style.visibility === "hidden" ||
          tooltipDiv.style.visibility === ""
        ) {
          tooltipDiv.style.visibility = "visible";
        } else {
          tooltipDiv.style.visibility = "hidden";
        }
      }
    } catch (error) {
      logger.log("[-] Error :" + error.stack);
    }
  }

  getCheckboxStyling(event) {
    logger.log("checkbox");
    return "textInput";
  }

  //Start FRONT-1931
  isLockedOrder() {
    //FRONT-11422 Changed from a getter to normal method. The getter is now changed to isLockedOrReadOnlyOrder.
    if (
      this.parentRecord.fields.Record_Type_Name__c?.value ===
      this.LOCKED_RESERVATION_ORDER
    )
      return true;
    return false;
  }
  //End FRONT-1931

  //START FRONT-11422
  //Added product details handler
  productDetailsItemHandler(event) {
    this.selectedRecord = this.records[event.target.dataset.index];
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.selectedRecord.product,
        actionName: "view"
      }
    });
  }

  //Getter to hide actions if order is locked or readonly.
  get isLockedOrReadOnlyOrder() {
    return this.isLockedOrder() || this.isReadOnly;
  }
  //END FRONT-11422

  //START FRONT-13033 Added method to determine if record is quote or not
  get isQuote() {
    if (this.objectApiName === "SBQQ__Quote__c") {
      return true;
    } else {
      return false;
    }
  }
  //END FRONT-13033

  async updateLineItems(quoteItems, orderItems, objType) {
    logger.log("insidee mobile canclel" + JSON.stringify(orderItems));
    const reslt = await saveSObjects({
      quoteLines: [quoteItems],
      orderLines: orderItems,
      objectType: objType
    });
  }

  //FRONT-11379
  @api
  selectionPanelActionsForPI() {
    let elems = this.template.querySelectorAll("lightning-input");
    elems.forEach((element) => {
      if (!element.disabled) {
        //Added as part of FRONT-9206
        element.checked = true;
      }
    });
    this.getRowInfos(elems);
  }

  @api
  toggleRemoveModalForPI(evt) {
    this.removeItems(evt);
  }

  get removeItemHandler() {
    return this.variantType === "Sales"
      ? this.removeItemsForPI
      : this.removeItems;
  }

  removeItemsForPI = (evt) => {
    this.removeItems(evt);
    this.fireClearSelectedRecordEvent(this._selectedRecordIdToBeRemovedPayload);
    this._selectedRecordIdToBeRemovedPayload = null;
  };

  fireClearSelectedRecordEvent(payload) {
    const removeSelectedRecordFromPIEvent = new CustomEvent(
      "removeselectedrecordfrompievent",
      {
        detail: { payload }
      }
    );
    this.dispatchEvent(removeSelectedRecordFromPIEvent);
  }
  handleRemovePISelectedRow(event) {
    const rows = this.records;
    logger.log("!!!! this.records >> " + JSON.stringify(this.records));
    const rowIndex = rows.findIndex((r) => r.Id === event?.target?.dataset?.id);
    let selectedRecord = this.records[rowIndex];
    logger.log("rowIndex >>" + rowIndex);
    logger.log("selectedRecord >> " + JSON.stringify(selectedRecord));
    let selectedElem = this.template.querySelector(
      `lightning-input[data-id="${selectedRecord.Id}"]`
    );
    if (selectedElem) {
      selectedElem.checked = true;
    }

    const selectedCountEvt = {
      detail: {
        variantType: this._variantType,
        selectedRecord: selectedRecord,
        isChecked: true
      }
    };

    this.dispatchEvent(new CustomEvent("selectedcountevt", selectedCountEvt));
    this._selectedRecordIdToBeRemovedPayload = {
      Id: selectedRecord.Id
    };
    this.toggleRemoveModal();
  }
  /* END : FRONT - 11379 */

  // FRONT-15894
  showNotes(event) {
    const id = event.target.title;
    const updatedData = { showNoteItem: true };
    this.records = this.records.map((item) =>
      item.Id === id ? { ...item, ...updatedData } : item
    );
  }
  // FRONT-15894
  hideNotes(event) {
    const id = event.target.title;
    const updatedData = { showNoteItem: false };
    this.records = this.records.map((item) =>
      item.Id === id ? { ...item, ...updatedData } : item
    );
  }

  handleRowNotesAction(event) {
    const customEvt = new CustomEvent('notesiconselectedresult', {
      detail: event
    });

    this.dispatchEvent(customEvt);
  }
}