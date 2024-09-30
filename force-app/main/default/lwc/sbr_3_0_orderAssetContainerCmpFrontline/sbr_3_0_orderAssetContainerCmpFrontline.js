import { api, LightningElement, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import STATUS from "@salesforce/schema/Order.Status";
import RECORD_TYPE_NAME from "@salesforce/schema/Order.RecordType.Name";
import getOrderAssetColumns from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns";
import getOrderAssetData from "@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredOrderItems";
import schedulePickupTicket from "@salesforce/apex/SBR_3_0_API_PickupTicket.getPickupTicketNumberNew";
import getProfileBranchChronosDetails from "@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProfileBranchChronosDetails";
import sendEmail from "@salesforce/apex/SBR_3_0_EmailClass.sendEmail";
import SetAssetstatus from "@salesforce/apex/SBR_3_0_OrderAssetController.SetAssetstatus";
import CreateOrderItemDetail from "@salesforce/apex/SBR_3_0_OrderAssetController.CreateOrderItemDetail";
import ORDER_OBJECT from "@salesforce/schema/Order";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import USER_ID from "@salesforce/user/Id";
import USER_CONTACTID from "@salesforce/schema/User.ContactId";
import USER_EMAIL from "@salesforce/schema/User.Email";
import USER_NAME from "@salesforce/schema/User.Name";
import { CloseActionScreenEvent } from "lightning/actions";
import {
  APPLICATION_SCOPE,
  subscribe,
  MessageContext,
  unsubscribe
} from "lightning/messageService";
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c";
import getPickupTicketDetails from "@salesforce/apex/SBR_3_0_OrderAssetController.getOrderDetailItems"; //SADAPUR, 13808
import { NavigationMixin } from "lightning/navigation"; //Added as part of 2208
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG"; //Added as part of 6276
import { loadStyle } from "lightning/platformResourceLoader"; //Added as part of 2208
import { Logger } from "c/sbr_3_0_frontlineUtils";
import actionMenuCss from "@salesforce/resourceUrl/sbr_3_0_orderAssetContainerCmp_css"; //Added as part of 2208
import LABELS from "c/sbr_3_0_customLabelsCmp"; //added as a part of 6276
import EDIT_ORDER from "@salesforce/schema/Order.Is_Edit_In_Progress__c"; //Added as part of FRONT-15703
import LAST_EDITED_BY from "@salesforce/schema/Order.Last_Edit_By__c"; //Added as part of FRONT-15703
const PICKUP_STATUSES = ["ON RENT", "ON RENT PURCHASE"];
const SERVICE_STATUSES = [
  "ON RENT",
  "ON RENT PURCHASE",
  "SCHEDULED FOR PICKUP"
];
const MODAL_COLUMN_FIELD_NAMES = [
  "itemName",
  "assetNumber",
  "Quantity",
  "jobsiteName"
];

const assetLineActions = [
  { label: "Re-Assign Asset ", name: "view_re_assign_asset" },
  { label: "Remove Asset", name: "remove_asset" },
  { label: "View Asset Details", name: "view_asset_details" }
];
const logger = Logger.create(true);
export default class Sbr_3_0_orderAssetContainerCmpFrontline extends NavigationMixin(
  LightningElement
) {
  LOCKED_RESERVATION_ORDER = "Locked Reservation Order"; //FRONT-7977
  @api tabsPanelHeight;
  @api recordId;
  @api objectApiName;
  @api isMobileRequestView = false;
  @track isMobilePickup = false;
  @track isMobileService = false;
  @track isRequestPickup = false;
  @track isRequestService = false;
  @track isRequestView = false;
  showListViews = false;

  showSpinner = false;
  @track isSchedulePickup = false;
  orderId;
  orderStatus;
  @track draftValues = [];
  hasReservation = false;
  orderRecordType;
  showEntireModal = true;

  isMobile = false;
  @track mobileIsLoading = false;
  rowsOffsetMobile = 0;

  selectedmultivalues = LABELS.SBR_3_0_AssetStatusPicklistValues;
  @track data = [];
  columns = [];
  showTable = false;
  rowsOffset = 0;
  batchSize = 7;
  queryParams = "";
  searchKey = "";
  selectedStatus = "";
  hideNoRecordPage = false;

  haverecords = true; //Added as part of 6276
  noContentimageUrl = noContentSvg; //Added as part of 6276
  mapdata = [];
  requestType;
  modalHeader;
  modalColumns = [];
  @track modalData = [];
  modalOffset = 0;
  viewOid = false;
  showPickupForm;
  showServiceTicketWindow;
  pickupTicket;
  pickupTicketRequestedBy;
  pickupRequestedDate;
  serviceRequestedDate;
  serviceTicketContact;
  orderItemComments;
  //25058
  pickupTicketQuantity;
  pickupTicketItems = [];

  @track showLoading;

  @track pickupComments;
  @track pickupDate;
  pickupBranch;
  pickupCovidRelated;

  serviceProductName;
  serviceMake;
  serviceModel;
  serviceAssetNum;
  serviceSerialNum;
  serviceContractNum;
  serviceYear;
  serviceJobSite;
  branchEmail;
  userId = USER_ID;
  currUser = {};
  currModal;

  modalErrorHeader;
  modalErrorContent;

  orderAssetStatus = "";
  selectedAssetHasOID = false;

  showAssetList = true;
  selectedStatuses = [];
  showRequestScreen;
  @api mobileRequestType;
  lineItemClass;
  requestHeader;
  listClass;
  headerDisplayClass;
  showHeader = true;
  showMobileOID = false;
  isFilterClicked = false;
  isOnScroll = false;
  tooltipText = LABELS.ASSET_TAB_TOOL_TIP;
  cancelButtonLabel = "Cancel";
  saveButtonLabel = "Next";
  quantityTableColumns = [];
  @track selectedRows = [];
  @track preSelectedRows = [];
  @track productId;
  @track parentId;
  @track orderItemId;
  @wire(MessageContext)
  messageContext;
  selectedOption = "";
  showViewAssetDetails = false;

  selectedAssetId = "";
  // @track openViewAssetModal = false;
  @track selectedOrderItem = {};


  @track openAssetModal = false;
  options = [
    { label: "Option 1", value: "option1" },
    { label: "Option 2", value: "option2" },
    { label: "Option 3", value: "option3" }
  ];
  sourceLocation;
  isEditOrder = false; //Added as part of FRONT-15703
  lastEditedByUser = ""; //Added as part of FRONT-15703
  handleDropdownChange(event) {
    this.selectedOption = event.detail.value;
  }

  @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
  orderObjectInfo;

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [STATUS, RECORD_TYPE_NAME, EDIT_ORDER, LAST_EDITED_BY] //Modified as part of FRONT-15703
  })
  wiredOrder({ error, data }) {
    if (error) {
      console.error(error);
    } else if (data) {
      this.orderId = data.id;
      this.orderStatus = data.fields.Status.value;
      this.orderRecordType = getFieldValue(data, RECORD_TYPE_NAME);
      this.hasReservation = this.orderStatus === "Reservation Created";
      this.isEditOrder = getFieldValue(data, EDIT_ORDER); //Added as part of FRONT-15703
      this.lastEditedByUser = getFieldValue(data, LAST_EDITED_BY); //Added as part of FRONT-15703
      if (!this.isMobileRequestView) {
        this.template
          .querySelector("c-sbr_3_0_order-asset-list-header-cmp")
          .orderStatusChangedHandler(this.orderRecordType);
      }

      if (!this.isMobile) {
        if (this.columns.length < 1) {
          this.getOrderAssetColumns();
        }
      } else {
        this.getOrderAssetData(
          0,   //changed as a part of FRONT-22120
          false,
          this.isMobileRequestView
        );
      }
    }
  }

  @wire(getProfileBranchChronosDetails, {
    objectId: "$orderId",
    objectApiName: "Order"
  })
  wiredSourceLocation({ error, data }) {
    if (data) {
      this.sourceLocation = data;
      console.log(
        " this.sourceLocation >> " + JSON.stringify(this.sourceLocation)
      );
    } else if (error) {
      this.sourceLocation = undefined;
    }
  }

  @wire(getRecord, {
    recordId: "$userId",
    fields: [USER_CONTACTID, USER_NAME, USER_EMAIL]
  })
  wiredUser({ error, data }) {
    if (data) {
      this.currUser = data;
    } else if (error) {
      this.currUser = undefined;
    }
  }

  @api filterAssets(event) {
    this.rowsOffset = 0;
    this.selectedStatuses = event.detail.filters;
    this.getOrderAssetData(this.rowsOffset, false, false);
  }

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;

    if (this.isMobileRequestView) {
      this.listClass = "item-list-ctr slds-scrollable_y request-list";
      this.lineItemClass = "line-item slds-p-around_medium request-view-item";
      this.requestType = this.mobileRequestType;
      this.requestHeader =
        this.mobileRequestType === "pickup"
          ? "Schedule Pick Up"
          : "Create Service Ticket";
      if (this.requestType === "pickup") {
        this.isRequestPickup = true;
        this.isRequestService = false;
        this.isSchedulePickup = true;
      }
      if (this.requestType === "serviceTkt") {
        this.isRequestService = true;
        this.isRequestPickup = false;
        this.isSchedulePickup = false;
        this.requestHeader = "Create Service Ticket";
      }
    } else {
      this.lineItemClass = "line-item slds-p-around_medium";
      this.listClass = "item-list-ctr slds-scrollable_y";
    }
  }

  updateShowAssetList(event) {
    this.showAssetList = !event.detail.filtersOpen;
  }

  get assetHeaderDisplayClass() {
    return this.showHeader ? "show" : "hide";
  }

  get assetListDisplayClass() {
    return this.showAssetList ? "show" : "hide";
  }
  get showRadioButton() {
    let i = this.isRequestService ? true : false;
    return i;
  }
  handleSearch(event) {
    let data = event.detail;

    this.rowsOffset = 0;
    this.searchKey = data.searchKey;
    this.getOrderAssetData(this.rowsOffset, false, false);
  }

  refreshOLITable() {
    this.template
      .querySelector("c-sbr_3_0_order-asset-list-header-cmp")
      .resetFilterPanel();
  }

  handleAssetStatusChange(event) {
    let data = event.detail;
    this.isFilterClicked = true;
    this.isOnScroll = false;

    if (data) {
      //START: FRONT-15431: gettting the status array from correct node
      const arrayofstatus = data.selectedStatus.selectedStatus;
      //END: FRONT-15431
      this.selectedStatus = arrayofstatus.toString();
      this.rowsOffset = 0;

      this.getOrderAssetData(this.rowsOffset, false, false);
    }
  }

  handleRequestSelection(event) {
    this.requestType = event.detail.selectedRequest;
    this.isSchedulePickup = false; // make quantity column read only
    if (this.isMobile) {
      this.showRequestScreen = true;
      this.showHeader = false;
      this.showAssetList = false;

      if (this.requestType === "pickup") {
        this.isRequestPickup = true;
        this.isRequestService = false;
        this.isSchedulePickup = true;
      }
      if (this.requestType === "serviceTkt") {
        this.isRequestService = true;
        this.isRequestPickup = false;
        this.isSchedulePickup = false;
        this.requestHeader = "Create Service Ticket";
      }
    } else {
      if (this.requestType === "pickup" || this.requestType === "serviceTkt") {
        // if there is an Rent asset, run below. Otherwise show message
        let foundRent = false;
        for (let i = 0; i < this.data.length; i++) {
          if (PICKUP_STATUSES.includes(this.data[i]?.Status__c)) {
            foundRent = true;
          }
        }

        if (foundRent) {
          let modalTable = this.template.querySelector(
            '[data-id="modal-table"]'
          );
          let quantityTable = this.template.querySelector(
            '[data-id="quantity-table"]'
          );
          this.modalOffset = 0;
          this.modalData = [];

          if (this.requestType === "pickup") {
            this.modalHeader = "Schedule Pick Up";
            this.isSchedulePickup = true; // make quantity column editable
            quantityTable.maxRowSelection = null; //this throws an error in the console, but it also removes any value to maxRowSelection which is the whole point of this line, so...
          } else if (this.requestType === "serviceTkt") {
            this.modalHeader = "Create Service Ticket";
            lightningTable.maxRowSelection = 1;
          } else {
            this.modalHeader = "Unknown Modal";
          }
          this.getOrderAssetData(this.modalOffset, false, true);
          modalTable.toggleModal();
        } else {
          let modalError = this.template.querySelector(
            '[data-id="modal-error"]'
          );
          this.modalErrorHeader =
            this.requestType === "pickup"
              ? "Schedule Pick Up"
              : "Create Service Ticket";
          this.modalErrorContent = "This Order has no on rent items.";
          modalError.toggleModal();
        }
      }
    }
  }

  scheduleRequest = async (event) => {
    event.stopPropagation();
    let count = 0;
    let mobileRows = this.data.filter((row) => row._isChecked);
    //change for SAL-22395
    if (this.isMobile) {
      if (mobileRows) {
        this.selectedRows = mobileRows;
      }
    } else {
      let quantityTable = this.template.querySelector(
        '[data-id="quantity-table"]'
      );
      if (quantityTable) {
        this.selectedRows = quantityTable.getSelectedRows();
      }
    }

    if (this.selectedRows.length === 0) {
      // show error toast
      this.showNotification(
        "Error",
        "Please select at least one asset to navigate forward",
        "error"
      );
    } else if (this.saveButtonLabel === "Schedule Pick Up") {
      try {
        if (!this.pickupDate) {
          this.showNotification("Error", "Please select pickup date", "error");
          return;
        }

        if (!this.pickupBranch) {
          this.showNotification(
            "Error",
            "Please select pickup branch",
            "error"
          );
          return;
        }

        this.showSpinner = true;

        let equipmentsArr = [];
        this.selectedRows.forEach((item) => {
          let equipments = {};
          if (item.isEditableFlag) {
            equipments["quantity"] = item.pickupQuantity;
          } else {
            equipments["quantity"] = item.Quantity;
          }
          equipments["equipmentNumber"] = item.assetNumber;
          equipments["lineItemId"] = item.Id;
          equipmentsArr.push(equipments);
        });

        let pickupDetails = {
          pickupDate: this.pickupDate,
          requestedById: this.userId,
          equipments: equipmentsArr,
          comments: this.pickupComments
        };

        this.schedulePickupTicketHandler(JSON.stringify(pickupDetails));

        this.showEntireModal = false;
        this.showSpinner = false;

        this.dispatchEvent(new CloseActionScreenEvent());
        if (this.isMobile) {
          this.isMobileRequestView = false;
          this.isMobilePickup = false;
          this.isRequestView = false;
          this.rowsOffset = 0;
          this.data = [];
          this.getOrderAssetData(0, false, this.isMobileRequestView);
          this.showHeader = true;
          this.showAssetList = true;
          this.showRequestScreen = false;
        }
      } catch (error) {
        console.error("\n @@ pickup error = " + error);
      }
    } else {
      if (this.requestType === "pickup") {
        this.saveButtonLabel = "Schedule Pick Up";
        this.requestHeader = "Schedule Pick Up";
        if (this.isMobile) {
          this.isRequestView = true;
          this.isMobilePickup = true;
          this.isMobileService = false;
        } else {
          this.showPickupForm = true;
        }
      } else {
        let modalTable = this.template.querySelector('[data-id="modal-table"]');
        let serviceTicketModal = this.template.querySelector(
          '[data-id="service-ticket-modal"]'
        );
        this.currModal = serviceTicketModal;
        if (this.isMobile) {
          this.isRequestView = true;
          this.isMobileService = true;
          this.isMobilePickup = false;
          this.isRequestService = false;
        } else {
          this.showServiceTicketWindow = true;
        }

        this.saveButtonLabel = "Create Service Ticket";

        let selectedAsset = this.selectedRows[0];

        this.serviceProductName = selectedAsset.Product2.Name;
        this.serviceMake = selectedAsset.SBQQ__Asset__r.SM_PS_Make__c;
        this.serviceModel = selectedAsset.SBQQ__Asset__r.SM_PS_Model__c;
        this.serviceAssetNum = selectedAsset.SBQQ__Asset__r.SM_PS_Asset_Id__c;
        this.serviceSerialNum =
          selectedAsset.SBQQ__Asset__r.SM_PS_Serial_Number__c;
        this.serviceContractNum = selectedAsset.Order.ContractId;
        this.serviceYear = selectedAsset.SBQQ__Asset__r.SM_PS_Model_Year__c;
        this.serviceJobSite = selectedAsset.Order.Jobsite__r.JobsiteName__c;
        if (selectedAsset.Order.Branch_Email__c != null) {
          this.branchEmail = selectedAsset.Order.Branch_Email__c;
        } else {
          this.branchEmail = selectedAsset.Order.Branch__r.Branch_Email__c;
        }

        if (!this.isMobile) {
          serviceTicketModal.toggleModal();
          modalTable.toggleModal();
        }
      }
      this.cancelButtonLabel = "Back";
    }
  };

  schedulePickupTicketHandler(pickupDetails) {
    schedulePickupTicket({ pickupDetails: pickupDetails })
      .then((data) => {
        if (data.includes("error")) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: `Failed to create Pickup Ticket. Please reach out to Support team if issue persists.`,
              variant: "error"
            })
          );
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: `Pickup Ticket created successfully.`,
              variant: "success"
            })
          );
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }
  setStatus() {
    let orderItemRecordsParam = JSON.stringify(this.mapdata);
    let pickupCommentParam = this.pickupComments;
    let pickupDateParam = this.pickupDate;
    let loggedinUserParam = this.userId;
    SetAssetstatus({
      orderItemRecords: orderItemRecordsParam,
      pickupComment: pickupCommentParam,
      pickupDate: pickupDateParam,
      loggedInUser: loggedinUserParam
    })
      .then(() => {
        console.log("Output from setStatus ");
      })
      .catch((error) => {
        console.log("Error log");
        console.error(error);
      });
  }

  sendServiceTicket = (event) => {
    try {
      event.stopPropagation();
      let serviceTicketModal = this.template.querySelector(
        '[data-id="service-ticket-modal"]'
      );
      if (!this.isMobile) {
        serviceTicketModal.toggleModal();
      }

      this.showServiceTicketWindow = false;
      let emailDetails = {
        addContact: "",
        toAddress: [this.branchEmail],
        frm: this.currUser.fields.Email.value,
        bcc: "",
        subject:
          "Service Requested for " +
          this.serviceContractNum +
          ", " +
          this.serviceAssetNum,
        body:
          this.currUser.fields.Name.value +
          " has submitted " +
          this.serviceAssetNum +
          " for Service.  Please see below for details:<br>" +
          "<br>Customer Contact: " +
          this.serviceTicketContact +
          "<br>Comments: " +
          this.pickupComments +
          "<br>Product Name: " +
          this.serviceProductName +
          "<br>Make: " +
          this.serviceMake +
          "<br>Model: " +
          this.serviceModel +
          "<br>Asset #: " +
          this.serviceAssetNum +
          "<br>Serial #: " +
          this.serviceSerialNum +
          "<br>Contract #: " +
          this.serviceContractNum +
          "<br>Year: " +
          this.serviceYear +
          "<br>Job Site: " +
          this.serviceJobSite,
        recId: this.serviceContractNum,
        frmName: this.currUser.fields.Name.value
      };

      sendEmail({ emailStr: JSON.stringify(emailDetails) })
        .then(() => {
          this.showNotification(
            "Success!",
            "Email Sent Successfully!",
            "success"
          );
          if (this.isMobile) {
            this.isMobileRequestView = false;
            this.isMobilePickup = false;
            this.isRequestService = false;
            this.isRequestView = false;
            this.rowsOffset = 0;
            this.data = [];
            this.getOrderAssetData(0, false, this.isMobileRequestView);
            this.showHeader = true;
            this.showAssetList = true;
            this.showRequestScreen = false;
          }
        })
        .catch((error) => {
          this.showNotification("Error", error.body.message, "error");
        });
    } catch (e) {
      this.showNotification("Error", e.body.message, "error");
    }
  };

  handleRequestCancelButton() {
    const statusChangeEvent = new CustomEvent("cancelrequest", {});
    this.dispatchEvent(statusChangeEvent);
  }
  handleRequestPreviousButtonMobile() {
    this.showHeader = true;
    this.isMobile = true;
    this.isRequestView = false;
    this.isMobilePickup = false;
    this.showAssetList = true;
    this.isSchedulePickup = false;
    this.saveButtonLabel = "Previous Screen";
  }

  cancelRequest() {
    this.showHeader = true;
    this.showAssetList = true;
    this.isSchedulePickup = false;
    this.showRequestScreen = false;
  }

  loadMoreItems(event) {
    let datatableTarget = event.target;
    datatableTarget.isLoading = true;
    this.getOrderAssetData(this.rowsOffset, true, false);
  }

  loadMoreModalItems(event) {
    let datatableTarget = event.target;
    datatableTarget.isLoading = true;
    this.getOrderAssetData(this.modalOffset, true, true);
  }

  loadMoreDataMobile(event) {
    this.hideNoRecordPage = true;
    this.isOnScroll = true;
    this.isFilterClicked = false;
    this.haverecords = true;
    if (
      event.target.scrollTop >
        event.target.scrollHeight - event.target.offsetHeight &&
      !this.mobileIsLoading
    ) {
      this.mobileIsLoading = true;
      new Promise((resolve, reject) => {
        setTimeout(() => {
          this.getOrderAssetData(this.rowsOffset, true, false);

          resolve();
        }, 3000);
      }).then(() => (this.mobileIsLoading = false));

    }
  }
  handleQuantityEdit(event) {
    let draftTableValues = this.template.querySelector(
      '[data-id="quantity-table"]'
    );
    let recId = event.detail.recordId;
    this.modalData.forEach((curVal) => {
      if (curVal.Id === recId) {
        curVal.pickupQuantity = event.detail.value;
      }
    });
    let selectedRecords = this.template
      .querySelector('[data-id="quantity-table"]')
      .getSelectedRows();
    selectedRecords.forEach((currentItem) => {
      if (recId === currentItem.Id) {
        currentItem.pickupQuantity = event.detail.value;
      }
    });
  }

  async handleEdit(event) {
    draftTableValues.forEach((curVal) => {
      const objWithIdIndex = this.draftValues.findIndex(
        (obj) => obj.Id === curVal.Id
      );
      if (objWithIdIndex > -1) {
        this.draftValues.splice(objWithIdIndex, 1);
      }
      if (curVal.Quantity < 1) {
        this.showNotification(
          "Error",
          "Quantity can not be less than One",
          "error"
        );
        return;
      }
      this.draftValues.push(curVal);
      this.draftValues[curVal.Id] = curVal.Quantity;
    });
    selectedRecords.forEach((currentItem) => {
      if (
        this.draftValues[currentItem.Id] &&
        this.draftValues[currentItem.Id] >= 1
      ) {
        currentItem.Quantity = this.draftValues[currentItem.Id];
      }
    });
  }

  onRowSelection(event) {
    let selectedRows = [];
    selectedRows = event.detail.selectedRows;
    if (selectedRows.length === this.modalData.length) {
      this.modalData.forEach(function (e) {
        if (e.isEditableFlag) {
          e.pickupQuantity = e.createdQuantity;
        }
      });
      this.modalData = [...this.modalData];
    }
    if (selectedRows.length === 0) {
      this.modalData.forEach(function (e) {
        if (e.isEditableFlag) {
          e.pickupQuantity = 0;
        }
      });
      this.modalData = [...this.modalData];
    }
  }

  decrement(event) {
    const itemNum = event.target.value;
    const filteredNumbers = this.data.map((element) => {
      if (element.assetNumber === itemNum) {
        if (element.Quantity > 1) {
          element.Quantity -= 1;
        }
      }
    });
  }

  increment(event) {
    const itemNum = event.target.value;
    const filteredNumbers = this.data.map((element) => {
      if (element.assetNumber === itemNum) {
        element.Quantity += 1;
      }
    });
  }

  handlePickupQuantityChange(event) {
    let assetId = event.currentTarget.dataset.id;
    let quantValue = event.target.value;
    this.data.forEach(function (e) {
      if (e.Id === assetId) {
        e.pickupQuantity = quantValue;
      }
    });
  }
  setQuantityValue() {}

  //FRONT-8764 - Start
  //To calculate the column width dynamically and apply to Asset Table on Assets tab
  getColumnWidth(orderAssetCols) {
    const viewPortWidth = window.innerWidth;
    let columnWidthMap = {};
    if (orderAssetCols) {
      orderAssetCols.forEach((item) => {
        if (item.fixedWidth__c)
          columnWidthMap[item.DeveloperName] =
            (item.fixedWidth__c * (viewPortWidth - 50)) / 100;
      });
    }
    return columnWidthMap;
  }
  //FRONT-8764 - End

  getOrderAssetColumns() {
    getOrderAssetColumns()
      .then((data) => {
        if (!this.isMobile) {
          let orderAssetCols = data.filter(
            (col) => col.Context__c === "Order Asset"
          );
          orderAssetCols.sort((a, b) => a.Order__c - b.Order__c);

          //FRONT-8764 - Start
          let columnWidthMap = this.getColumnWidth(orderAssetCols);
          //FRONT-8764 - End

          orderAssetCols.forEach((col) => {
            let colItem = {};
            colItem.label = col.Label;
            colItem.fieldName = col.Field_Name__c;
            colItem.hideDefaultActions = true;
            colItem.sortable = col.IsSortable__c;
            colItem.type = col.Type__c ? col.Type__c : "text";
            colItem.wrapText = true;
            if (col.fixedWidth__c) {
              if (
                col.Width_Unit__c === "Percent" &&
                columnWidthMap[col.DeveloperName]
              ) {
                colItem.initialWidth = columnWidthMap[col.DeveloperName];
              } else {
                colItem.initialWidth = col.fixedWidth__c;
              }
            }
            this.columns.push(colItem);
            this.queryParams += col.Field_Name__c + ",";
          });

          let modalCols1 = this.columns.filter((col) =>
            MODAL_COLUMN_FIELD_NAMES.includes(col.fieldName)
          );
          const modalsCols2 = JSON.parse(JSON.stringify(modalCols1));
          modalsCols2.forEach((col) => {
            col.sortable = false;
          });
          this.modalColumns = modalsCols2;
          let quantityColumn;
          const testCol = this.modalColumns;
          testCol.forEach((col) => {
            col.sortable = false;
            if (col.fieldName === "Quantity") {
              col.type = "customQuantity";

              col.typeAttributes = {
                isEditableFlag: { fieldName: "isEditableFlag" },
                itemRecord: { fieldName: "itemRecord" },
                pickupQuantity: { fieldName: "pickupQuantity" },
                createdQuantity: { fieldName: "createdQuantity" }
              };
              quantityColumn = col;
            }
          });
          let quantityTable = [];
          if (quantityColumn) {
            quantityTable = testCol.filter((e) => {
              return e.fieldName !== "Quantity";
            });
            quantityTable.push(quantityColumn);
          }

          this.quantityTableColumns = quantityTable;
          //changes end
          this.columns.forEach((col) => {
            if (col.fieldName === "Quantity") col.sortable = false;
            col.editable = false;
            if (col.fieldName === "assetNumber") {
              //Start FRONT-7977
              if (this.orderRecordType === this.LOCKED_RESERVATION_ORDER) {
                col.type = "text";
                col.typeAttributes = {
                  label: { fieldName: "assetNumber" },
                  fieldName: "assetNumber",
                  name: "view_assign_asset"
                };
              } else {
                //END FRONT-7977
                col.type = "button";
                col.typeAttributes = {
                  label: { fieldName: "assetNumber" },
                  fieldName: "assetNumber",
                  name: "view_assign_asset",
                  target: "_blank",
                  variant: "base"
                };
              }
            }
          });
          this.showTable = true;
          this.getOrderAssetData(this.rowsOffset, false, false);

          this.columns.push({
            type: "action",
            typeAttributes: {
              rowActions: this.getRowActions.bind(this),
              menuAlignment: "auto"
            }
          });
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }

  //FRONT-6275 Created this method to set Status field to be queried as SBQQ__Asset__r.Status for Reservation Order
  buildReservationOrderWhereClause(offset, isLoadingMoreItems, isModal) {
    return this.buildBaseWhereClause(
      offset,
      isLoadingMoreItems,
      isModal,
      "SBQQ__Asset__r.Status"
    );
  }

  //FRONT-6275 Created this method to set Status field to be queried as Status__c for Contract Order
  buildContractOrderWhereClause(offset, isLoadingMoreItems, isModal) {
    return this.buildBaseWhereClause(
      offset,
      isLoadingMoreItems,
      isModal,
      "Status__c"
    );
  }

  // Generic Method to create where clause as per conditions, called from getOrderAssetData method
  buildBaseWhereClause(
    offset,
    isLoadingMoreItems,
    isModal,
    statusAssetOrOrderItem
  ) {
    let whereClause = "";
    if (
      this.selectedStatus &&
      !this.selectedStatus.includes(",") &&
      !this.selectedStatus.includes("Any Status") &&
      !this.selectedStatus.includes("Unassigned")
    ) {
      whereClause = `${whereClause} AND ${statusAssetOrOrderItem} = '${this.selectedStatus}'`;
    } else if (
      this.selectedStatus &&
      (this.selectedStatus.includes(",") ||
        this.selectedStatus.includes("Any Status") ||
        this.selectedStatus.includes("Unassigned"))
    ) {
      //this.selectedStatus = this.selectedStatus.replaceAll("Unassigned", "");
      if (this.selectedStatus.includes("Unassigned")) {
        if (this.selectedStatus === "Unassigned") {
          whereClause += " AND " + statusAssetOrOrderItem + " ='' ";
        } else {


          let regex = /,/g;
          let str = this.selectedStatus;
          str = str.replace(regex, "','");
          let res = str.replace("Unassigned", "");
          whereClause +=
            " AND " + statusAssetOrOrderItem + " IN('" + res + "')";
        }
      } else if (!this.selectedStatus.includes("Any Status")) {
        whereClause +=
          " AND " +
          statusAssetOrOrderItem +
          " IN ('" +
          this.selectedStatus.replaceAll(",", "','") +
          "') ";
      } else {
        let regex = /,/g;
        let str = this.selectedmultivalues;
        str = str.replace(regex, "','");
        let res = str.replace("Any Status", "");
        whereClause += " AND " + statusAssetOrOrderItem + " IN('" + res + "')";
      }
    } else if (this.selectedStatuses.length > 0) {
      let statusClause =
        " AND " +
        statusAssetOrOrderItem +
        " IN ('" +
        this.selectedStatuses.join("', '") +
        "') ";
      whereClause += statusClause;
    } else if (isModal) {
      let statuses =
        this.requestType === "pickup" || this.requestType === "serviceTkt"
          ? PICKUP_STATUSES
          : SERVICE_STATUSES;
      let stringStatuses = statuses.map((status) => {
        return "'" + status + "'";
      });
      let statusString = stringStatuses.join(", ");
      whereClause = `${whereClause} AND ${statusAssetOrOrderItem} IN (${statusString})`;
    }
    return whereClause;
  }

  /*FRONT-6275 Changes in this method as we need Status field in where clause to be different for Contract and Reservation Orders
   * For Reservation Order, it will be SBQQ__Asset__r.Status
   * For Contract Order, it will be Status__c
   * Created two methods for sending these two seperate field names using two diferent methods each for Contract and Reservation
   */
  getOrderAssetData(offset, isLoadingMoreItems, isModal) {
    let whereClause = "";
    if (this.orderRecordType === "Contract Order") {
      whereClause = this.buildContractOrderWhereClause(
        offset,
        isLoadingMoreItems,
        isModal
      );
    } else {
      whereClause = this.buildReservationOrderWhereClause(
        offset,
        isLoadingMoreItems,
        isModal
      );
    }
    getOrderAssetData({
      orderId: this.orderId,
      offset: offset,
      batchSize: 7,
      searchKey: this.searchKey,
      whereClause: whereClause
    })
      .then((data) => {
        let tempData = JSON.parse(JSON.stringify(data));
        //Added as part of 6276
        if (tempData == "") {
          if (this.hideNoRecordPage == false) {
            this.haverecords = false;
          }

          if (this.isFilterClicked) {
            this.haverecords = false;
            this.hideNoRecordPage = false;
          }
          if (this.isOnScroll) {
            this.haverecords = true;
            this.hideNoRecordPage = true;

          }
        } else {
          this.haverecords = true;
        }
        // change for SAL-16762
        data = tempData.map((row) => {
          // let rowStatus = (row.SBQQ__Asset__c != undefined && row.SBQQ__Asset__r?.Status != null) ? this.changeTextFormat(row.SBQQ__Asset__r?.Status): '';
          // console.log('rowStatus >> '+rowStatus);
          // console.log('Errror2 >> '+(row.SBQQ__Asset__c!=undefined) ? this.changeTextFormat(row.SBQQ__Asset__r?.Status):'');
          if (row.Product2.Bulk_Item__c) {
            return {
              ...row,
              Quantity:
                (row.Quantity ? row.Quantity > 0 : false) &&
                (row.Status_Created_Qty__c
                  ? row.Status_Created_Qty__c > 0
                  : false)
                  ? row.Status_Created_Qty__c
                  : row.Quantity
                    ? row.Quantity
                    : 0,
              itemRecord: row.Id,
              assetName: row.SBQQ__Asset__r?.Name,
              contract:
                row.SBQQ__Asset__r?.SM_PS_Last_Transaction_Invoice_Number__c,
              itemName: row.Product2.Name,
              catClass: row.Product2.Product_SKU__c,
              assetNumber: this.isMobile
                ? row.SBQQ__Asset__r?.Name
                : row.SBQQ__Asset__c !== undefined
                  ? row.SBQQ__Asset__r?.Name
                  : //Start FRONT-7977
                    this.orderRecordType !== this.LOCKED_RESERVATION_ORDER
                    ? "Assign Asset" //added as FRONT-6225
                    : "",
              //End FRONT-7977

              jobsiteName: row.Asset_Contract_Job_Site__c,
              isEditableFlag:
                row.Product2.Bulk_Item__c && !row.Product2.IsSerialized
                  ? true
                  : false,
              createdQuantity:
                (row.Quantity ? row.Quantity > 0 : false) &&
                (row.Status_Created_Qty__c
                  ? row.Status_Created_Qty__c > 0
                  : false)
                  ? row.Status_Created_Qty__c
                  : row.Quantity
                    ? row.Quantity
                    : 0,
              pickupQuantity: 0,
              status: row.Status__c, //this.orderRecordType === 'Contract Order' ? row.Status__c :"",
              hasOID:
                this.orderRecordType === "Contract Order" &&
                row.Status__c === "SCHEDULED FOR PICKUP"
            };
          } else {
            return {
              ...row,
              itemRecord: row.Id,
              assetName: row.SBQQ__Asset__r?.Name,
              itemName: row.Product2.Name,
              catClass: row.Product2.Product_SKU__c,
              contract:
                row.SBQQ__Asset__r?.SM_PS_Last_Transaction_Invoice_Number__c, //added as FRONT-6225
              assetNumber:
                //Modified for FRONT-1931
                row.SBQQ__Asset__c !== undefined
                  ? row.SBQQ__Asset__r?.Name
                  : //Start FRONT-7977
                    this.orderRecordType !== this.LOCKED_RESERVATION_ORDER
                    ? "Assign Asset" //added as FRONT-6225
                    : "",
              //End FRONT-7977
              //row.Product2.Bulk_Item__c?row.Product2.itemNumberUsedByReservationsRentalOut__c:row.SBQQ__Asset__r?.Name,
              jobsiteName: row.Asset_Contract_Job_Site__c,
              isEditableFlag:
                row.Product2.Bulk_Item__c && !row.Product2.IsSerialized
                  ? true
                  : false,
              createdQuantity:
                (row.Quantity ? row.Quantity > 0 : false) &&
                (row.Status_Pick_Created_Qty__c
                  ? row.Status_Pick_Created_Qty__c > 0
                  : false)
                  ? row.Quantity - row.Status_Pick_Created_Qty__c
                  : row.Quantity
                    ? row.Quantity
                    : 0,
              pickupQuantity: 0,
              status:
                this.orderRecordType === "Contract Order"
                  ? row.Status__c
                  : row?.SBQQ__Asset__r?.statusLabel, //row.SBQQ__Asset__r?.Status, //Modified as part of FRONT-7994
              // : (rowStatus) ? rowStatus : '',
              hasOID:
                this.orderRecordType === "Contract Order" &&
                row.Status__c === "SCHEDULED FOR PICKUP",
              assetLink: "/" + row.SBQQ__Asset__c
            };
          }
        });
        if (!this.isMobile) {
          let infiniteLoadingStatus = data.length >= this.batchSize;

          if (isModal) {
            this.template.querySelector(
              '[data-id="modal-table"]'
            ).enableInfiniteLoading = infiniteLoadingStatus;

            this.modalData = isLoadingMoreItems
              ? this.modalData.concat(data)
              : data;
            this.modalOffset += data.length;
            this.template.querySelector(
              '[data-id="modal-table"]'
            ).isLoading = false;
          } else {
            this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            ).enableInfiniteLoading = infiniteLoadingStatus;

            this.data = isLoadingMoreItems ? this.data.concat(data) : data;
            this.rowsOffset += data.length;

            this.template
              .querySelector("c-sbr_3_0_order-asset-list-header-cmp")
              .searchCompletionHandler(this.rowsOffset);
            this.template.querySelector(
              "c-sbr_3_0_custom-data-table-cmp"
            ).isLoading = false;
          }
        } else {
          //mobile
          this.data = isLoadingMoreItems ? this.data.concat(data) : data;
          this.rowsOffset += data.length;
          this.template
            .querySelector("c-sbr_3_0_order-asset-list-header-cmp")
            .searchCompletionHandler(this.rowsOffset);
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  //sorting needs to be refactored
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;

  sortBy(field, reverse, primer) {
    const key = primer
      ? function (x) {
          return primer(x[field]);
        }
      : function (x) {
          return x[field];
        };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }

  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.data];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.data = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  //Modified as part of 2208
  handleRowAction(event) {
    this.viewOid = true;
    const action = event.detail.action;
    const row = event.detail.row;
    this.productId = row.Product2.Id;
    logger.log("action >> " + JSON.stringify(action));
    switch (action.name) {
      case "view_re_assign_asset":
        this.showAssignAssetScreen(event);
        break;
      case "view_assign_asset":
        if (row.SBQQ__Asset__c !== undefined) {
          // this.navigateToRecordPage(row.SBQQ__Asset__c);
          // this.selectedAssetId = row.SBQQ__Asset__c;
          // this.openViewAssetModal = true;
          // this.selectedOrderItem = row;
          // console.log('row >> '+JSON.stringify(row));
          this.showAssignAssetScreen(event);
        } else {
          this.showAssignAssetScreen(event);
        }
        break;
      case "remove_asset":
        this.showAssignAssetScreen(event);
        break;
      case "view_asset_line":
        for (let i = 0; i < this.data.length; i++) {
          if (this.data[i].Id === this.assetId) {
            this.selectedAssetHasOID = false;
            if (
              this.data[i].SBQQ__Asset__r != null &&
              this.data[i].Order_Item_Detail__c != null
            ) {
              if (this.data[i].Status__c === "SCHEDULED FOR PICKUP") {
                this.selectedAssetHasOID = true;
              } else {
                this.selectedAssetHasOID = false;
              }
            } else if (
              this.data[i].Product2.Bulk_Item__c &&
              this.data[i].Order_Item_Detail__c != null
            ) {
              this.selectedAssetHasOID = true;
            }
            //25058, SADAPUR
            getPickupTicketDetails({
              orderLineItemId: this.assetId
            })
              .then((result) => {
                let tempOrdeItemDtlsData = JSON.parse(JSON.stringify(result));
                this.pickupTicketItems = tempOrdeItemDtlsData.map((rowVar) => {
                  this.pickupTicket = rowVar.Pickup_Ticket__c;
                  this.pickupTicketRequestedBy =
                    rowVar.Pickup_Ticket_Request_By__c; //138080
                  this.pickupRequestedDate = rowVar.Pickup_Requested_Date__c;
                  this.orderItemComments = rowVar.Order_Item_Comments__c;
                  this.selectedAssetHasOID = true;
                  this.pickupTicketQuantity = rowVar.Created_Qty__c;
                  return {
                    ...rowVar
                  };
                });
              })
              .catch((error) => {
                console.log(error);
              });
            //}
          }
        }
        this.modalHeader = "Order Item Details";
        this.template.querySelector("c-sbr_3_0_modal-cmp").toggleModal();
        break;
      case "view_asset_details":
        this.showViewAssetDetailsForDesktop(row?.SBQQ__Asset__c);
        break;
      default:

    }
  }

  handleMobileOIDClick(event) {
    this.assetId = event.target.dataset.value;

    let asset = this.data.filter((obj) => {
      return obj.Id === this.assetId;
    });
    this.selectedAssetHasOID = false;
    this.selectedAssetHasOID = asset[0].hasOID ? true : false;
    let orderItemDtls = [];
    getPickupTicketDetails({
      orderLineItemId: asset[0].Id
    })
      .then((result) => {
        let tempOrdeItemDtlsData = JSON.parse(JSON.stringify(result));
        this.pickupTicketItems = tempOrdeItemDtlsData.map((row) => {
          this.pickupTicket = row.Pickup_Ticket__c;
          this.pickupTicketRequestedBy = row.Pickup_Ticket_Request_By__c; //138080
          this.pickupRequestedDate = row.Pickup_Requested_Date__c;
          this.orderItemComments = row.Order_Item_Comments__c;
          this.selectedAssetHasOID = true;
          this.pickupTicketQuantity = row.Created_Qty__c;
          return {
            ...row
          };
        });
        this.showMobileOID = true;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  closeMobileOID() {
    this.showMobileOID = false;
    this.clearOIDFields();
  }

  populateOIDFields(oid) {
    this.pickupTicket = oid.Pickup_Ticket__c;
    this.pickupTicketRequestedBy = oid.Pickup_Ticket_Request_By__c; //13808
    if (!oid.Pickup_Requested_Date__c) {
      this.pickupRequestedDate = new Date(oid.Pickup_Requested_Date__c);
    } else {
      this.pickupRequestedDate = oid.Pickup_Requested_Date__c;
    }
    if (!oid.Service_Requested_Date__c) {
      this.serviceRequestedDate = new Date(oid.Service_Requested_Date__c);
    } else {
      this.serviceRequestedDate = oid.Service_Requested_Date__c;
    }
    this.serviceTicketContact = oid.Service_Ticket_Contact__r?.Name;
    this.orderItemComments = oid.Order_Item_Comments__c;
  }

  clearOIDFields() {
    this.pickupTicket = "";
    this.pickupTicketRequestedBy = "";
    this.pickupRequestedDate = "";
    this.serviceRequestedDate = "";
    this.serviceTicketContact = "";
    this.orderItemComments = "";
    this.selectedAssetHasOID = false;
  }

  handleSelectAll(event) {
    let r = event.target;
    this.data.forEach(function (e) {
      e._isChecked = r.checked;
    });
    if (r.checked) {
      this.data.forEach(function (e) {
        if (e.isEditableFlag) {
          e.pickupQuantity = e.createdQuantity;
        }
      });
    }
    if (!r.checked) {
      this.data.forEach(function (e) {
        if (e.isEditableFlag) {
          e.pickupQuantity = 0;
        }
      });
    }
  }

  handleRowSelection(event) {
    let r = event.target;
    if (!r.checked) {
      this.template.querySelector(".selectAll").checked = false;
    }
    let i = this.data.findIndex((e) => e.Id === r.value);
    this.data[i]._isChecked = r.checked;
  }

  handlePickUpBack() {
    this.showPickupForm = false;

    if (this.cancelButtonLabel !== "Back") {
      this.pickupDate = null;
      this.pickupBranch = null;
      this.pickupComments = null;
    }
    this.cancelButtonLabel = "Cancel";
    this.saveButtonLabel = "Next";
    let selectedIds = [];
    this.selectedRows.forEach((e) => {
      selectedIds.push(e.Id);
    });
    this.preSelectedRows = selectedIds;
    let temp = this.data.filter((row) => row._isChecked);
  }

  handleServiceTktBack() {
    let modalTable = this.template.querySelector('[data-id="modal-table"]');
    let serviceTicketModal = this.template.querySelector(
      '[data-id="service-ticket-modal"]'
    );
    serviceTicketModal.toggleModal();
    modalTable.toggleModal();
    this.showPickupForm = false;
    this.cancelButtonLabel = "Cancel";
    this.saveButtonLabel = "Next";
    this.pickupComments = "";
  }

  handlePickupBranch(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.pickupBranch = event.detail.selectedRecord.Id;
    } else {
      this.pickupBranch = "";
    }
  }

  handleCustomerContact(event) {
    if (event.detail.selectedRecord !== undefined) {
      this.serviceTicketContact = event.detail.selectedRecord.Id;
    } else {
      this.serviceTicketContact = "";
    }
  }

  updateComments(event) {
    this.pickupComments = event.detail.value;
  }

  upadatepickupDate(event) {
    this.pickupDate = event.detail.value;
  }

  showNotification(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }

  get branchWhere() {
    return "RecordType.Name = 'Branch'";
  }

  showAssignAssetScreen(event) {
    if (this.isEditOrder && this.userId === this.lastEditedByUser) {
      this.assetId = event.target?.dataset?.value || event.detail?.row?.Id;
      if (this.assetId) {
        let asset = this.data.filter((obj) => {
          return obj.Id === this.assetId;
        });
        this.productId = asset[0].Product2Id;
        this.parentId = asset[0].SBQQ__Asset__c;
        this.orderItemId = asset[0].Id;
      }
      this.openAssetModal = true;
    }
  }

  hideAssignAssetScreen() {
    this.openAssetModal = false;
    this.getOrderAssetData(0, false, false);
  }

  // @api hideViewAssetScreen(){
  //   this.openViewAssetModal = false;
  // }

  //Added as part of FRONT-6273
  getRowActions(row, doneCallback) {
    const actions = [];
    if (
      this.orderRecordType !== this.LOCKED_RESERVATION_ORDER &&
      this.isEditOrder &&
      this.userId === this.lastEditedByUser
    ) {
      //FRONT-7977 Modifed as part of FRONT-15703
      if (row.SBQQ__Asset__c !== undefined) {
        actions.push(
          { label: "Re-Assign Asset ", name: "view_re_assign_asset" },
          { label: "Remove Asset", name: "remove_asset" },
          { label: "View Asset Details", name: "view_asset_details" }
        );
      } else {
        actions.push({
          label: "Assign Asset ",
          name: "view_assign_asset",
          class: "green-menu-item"
        });
      }
      //Start FRONT-7977
    } else {
      if (row.SBQQ__Asset__c !== undefined) {
        actions.push({
          label: "View Asset Details",
          name: "view_asset_details"
        });
      }
      //   else {

      //  }
    }
    //End FRONT-7977
    doneCallback(actions);
  }

  //Added as part of FRONT-6273
  navigateToRecordPage(recordId) {
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: "Asset",
        actionName: "view"
      }
    }).then((generatedUrl) => {
      window.open(generatedUrl);
    });
  }

  //Added as part of FRONT-6273
  renderedCallback() {
    Promise.all([loadStyle(this, actionMenuCss)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {
        console.log(error.body.message);
      });

    //FRONT-8764 - Start - to cover full window height by Asset Table
    const tableContainer = this.template.querySelector(".oal-inner-container");
    const viewPortHeight = window.innerHeight;
    if (tableContainer) {
      const finalHeight =
        viewPortHeight -
        tableContainer.getBoundingClientRect().top -
        tableContainer.offsetTop / 2 +
        10;
      tableContainer.style.height = finalHeight + "px";
    }
    //FRONT-8764 - End
  }

  showViewAssetDetailsForDesktop(assetId) {
    this.selectedAssetId = assetId;
    this.showViewAssetDetails = true;
  }

  handleViewAssetDetails(event) {
    this.selectedAssetId = event.target.dataset.assetId;
    this.showViewAssetDetails = true;
  }

  hideViewAssetScreen() {
    this.selectedAssetId = null;
    this.showViewAssetDetails = false;
  }

  //Start FRONT-1931
  get isLockedOrder() {
    if (this.orderRecordType === this.LOCKED_RESERVATION_ORDER) 
    	return true;
	return false;
  }
  //End FRONT-1931

  // changeTextFormat(status) {
  //   let result = "";
  //   let capitalizeNext = true;

  //   for (const char of status) {
  //     if (/[a-zA-Z]/.test(char)) {
  //       if (capitalizeNext) {
  //         result += char.toUpperCase();
  //         capitalizeNext = false;
  //       } else {
  //         result += char.toLowerCase();
  //       }
  //     } else {
  //       result += char;
  //       capitalizeNext = true;
  //     }
  //   }
  //   return result;
  // }
  //Added as part of FRONT-15703
  get displayMenuActions() {
    let showActions;
    if (
      this.orderRecordType !== this.LOCKED_RESERVATION_ORDER &&
      this.isEditOrder &&
      this.userId === this.lastEditedByUser
    )
      showActions = true;
    else if (this.orderRecordType === this.LOCKED_RESERVATION_ORDER)
      showActions = false;
    return showActions;
  }
  // FRONT-15703 Ends
}