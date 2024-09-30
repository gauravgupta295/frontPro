import { LightningElement, api, wire, track } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from "lightning/navigation";
import {
  IsConsoleNavigation,
  getFocusedTabInfo,
  closeTab
} from "lightning/platformWorkspaceApi"; //FRONT-14063
import Id from "@salesforce/user/Id";
import deleteOrder from "@salesforce/apex/SBR_3_0_DMLOpsController.deleteOrder"; //FRONT-14063
//FRONT-1946
import mobileTemplate from "./sbr_3_0_orderCancelMobileTemplate.html";
import defaultTemplate from "./sbr_3_0_orderCancelCmp.html"; //Added for Front-4412,4413
import desktopTemplate from "./sbr_3_0_orderCancelDesktopTemplate.html";
//FORNT-1946
import desktopReasonTemplate from "./sbr_3_0_orderCancelReasonDesktop.html"; //1946
import mobileReasonTemplate from "./sbr_3_0_orderCancelReasonMobile.html"; //FRONT-1954
import { updateRecord } from "lightning/uiRecordApi";
import { deleteRecord } from "lightning/uiRecordApi";
import { CurrentPageReference } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import STATUS_FIELD from "@salesforce/schema/Order.Status";
import QUOTE_STATUS from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c"; //FRONT-4412
import ID_FIELD from "@salesforce/schema/Order.Id";
import { loadStyle } from "lightning/platformResourceLoader";
import Sbr_3_0_customModalCmp_Css1 from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import REASON from "@salesforce/schema/Order.Reason_for_Cancellation__c";
import OTHER_FIELD from "@salesforce/schema/Order.Other_Reason__c";
import COMMENT_FIELD from "@salesforce/schema/Order.Order_Header_Comments__c";
import CONVERTED_QUOTE_STATUS from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c";
import CONVERTED_QUOTE_STATUS_REASON from "@salesforce/schema/SBQQ__Quote__c.SBQQ_Status_Reason__c";
import CONVERTED_QUOTE_Id from "@salesforce/schema/SBQQ__Quote__c.Id";
let FIELDS = ["Order.Status", "Order.RecordTypeId"]; //Modified for FRONT-4412,4413
//FRONT-1946 ended
import cancelOrder from "@salesforce/apex/SBR_3_0_API_CancelOrder.cancelOrder"; //FRONT-7898, FRONT-7899
import cancelQuote from "@salesforce/apex/SBR_3_0_API_CancelQuote.cancelQuote"; //Front-4588,Front-4589
import ToastContainer from "lightning/toastContainer";
//FRONT-7898 start
import { Logger } from "c/sbr_3_0_frontlineUtils";

//FRONT-15079
import fetchTotalDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDeposit";
import fetchTotalRefundDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDepositforRefund";
import TotalAmount from "@salesforce/schema/Order.Total_Rental_Amount__c";
import InvoiceAmount from "@salesforce/schema/Order.Total_Invoiced_Amount__c";
//FRONT-1946 Started
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import DepositRefunded from "@salesforce/label/c.SBR_3_0_Deposit_Successfully_Refunded";
import NoRefundGiven from "@salesforce/label/c.SBR_3_0_No_Refund_Given";

const logger = Logger.create(true);
//FRONT-7898 end
export default class Sbr_3_0_orderCancelCmp extends NavigationMixin(
  LightningElement
) {
  /* Defining labels */
  label = {
    DepositRefunded,
    NoRefundGiven
  };
  isMobile = false;
  cancelButtonLabel = "No";
  header = LABELS.CANCELORDERHEADER;
  //1946 Started
  CancelBtn = LABELS.CANCEL;
  ConfirmBtn = LABELS.CONFIRM;
  ReasonForCancel = LABELS.REASON_CANCEL_FIELD;
  Otherreason = LABELS.OTHER_REASON_FIELD;
  OtherReasonPlaceholder = LABELS.OTHER_REASON_PLACEHOLDER;
  CommentsField = LABELS.COMMENTS;
  //1946 Ended
  @api recordId;
  @api objectApiName;
  @api props;
  @api orderId;
  userId = Id;
  //1946 start
  idtoPass = "";
  defaultTemplateFlag = true; //Front-4412, 4413
  status;
  currentPageReference = null;
  isLoading = false;
  cancelMessage = LABELS.CANCELORDERMESSAGE;
  cancelAlert = LABELS.CANCELORDERALERT;
  yesButton = LABELS.YESBUTTON;
  noButton = LABELS.NOBUTTON;
  showCancelModal = false;
  options;
  showReasonField = false;
  picklistval;
  heightSpin;
  widthSpin;
  value = "";
  quoteCancelMessage = LABELS.CANCEL_QUOTE_MSG; //FRONT-4412, 4413
  rendered = false;
  //1946 ended
  otherReasonValue = ""; //FRONT-1954
  disableConfirm = true; //FRONT-1954
  //1946 start
  commentVal;
  OrderrecordTypeId;
  ComboboxValueChange = false;
  comboboxClose = false;
  //1946 ended
  objectAction = ""; //FRONT-4412
  showQuoteMessage = false; //FRONT-4412, 4413

  // Refund  Deposit-  FRONT-15079
  @track depositAmount = "0.00";
  @track refundAmount = "0.00";
  @track noRefund = false;
  @track paymentMethod;
  isLoaded = false;
  @track totalAmount;
  @track InvoiceAmount = "0.00";
  @api isRefundAvailable = false;
  @api isRefundNotAvailable = false;
  @track isfromcancel = false;
  @api norefundgiven = false;
  //FRONT-29566: uncommented as it was not closing the Tab when cancelling an Order
  @wire(IsConsoleNavigation) isConsoleNavigation; //FRONT-14063
  //FRONT-29566/29567
  convertedQuoteRecordId;
  convertedQuoteStatus;
  convertedQuoteStatusReason;
  //FRONT-29566/29567

  connectedCallback() {
    /*FRONT-15984 Starts */
    this.removeDefaultCloseIconView();
    /*FRONT-15984 Ends */
    //start for FRONT-1946
    if (this.orderId) {
      this.defaultTemplateFlag = false; //Front-11393
      this.recordId = this.orderId;
    }
    //ended for FRONT-1946
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      if (this.orderId) {
        this.defaultTemplateFlag = false; //Front-11393
        this.recordId = this.orderId;
      } else {
        //FRONT-4413 started
        if (this.objectApiName === "SBQQ__Quote__c") {
          FIELDS = [
            "SBQQ__Quote__c.SBQQ__Status__c",
            "SBQQ__Quote__c.RecordTypeId"
          ];
        } else {
          FIELDS = [
            "Order.Status",
            "Order.RecordTypeId",
            "Order.Converted_Quote_Status__c",
            "Order.Converted_Quote_Status_Reason__c",
            "Order.SBQQ__Quote__c"
          ];
        }
        //FRONT-4413
        this.recordId = this.props?.recordId; //FRONT-1954
      }
    }
    //started for FRONT-1946
    if (!this.isMobile) {
      window.addEventListener("resize", () => {
        this.handleScreenResize();
      });
    }
    //ended for FRONT-1946
  }
  //start for 1946
  handleScreenResize() {
    let contCla = this.template.querySelector(".contClass");
    //Added a check to avoid the error if element is not found
    if (contCla) {
      this.heightSpin = contCla.getBoundingClientRect().width;
    }
  }
  //ended for FRONT-1946
  renderedCallback() {
    Promise.all([loadStyle(this, Sbr_3_0_customModalCmp_Css1)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {
        console.log(error.body.message);
      });
  }
  //FRONT-1946 Start
  @wire(getPicklistValues, {
    recordTypeId: "$OrderrecordTypeId",
    fieldApiName: REASON
  })
  reasonForCancel;
  //FRONT-1946 End
  render() {
    //started for FRONT-4412, 4413
    if (this.defaultTemplateFlag) {
      return defaultTemplate;
    }

    if (this.objectApiName === "SBQQ__Quote__c") {
      this.showQuoteMessage = true;
    }
    //ended for FRONT-4412, 4413
    //FRONT-1954

    if (this.showCancelModal === true && this.isMobile === true) {
      return mobileTemplate;
    } //FRONT-1946 start
    else if (this.showCancelModal === true && this.isMobile === false) {
      return desktopTemplate;
    } else if (this.showCancelModal === false && this.isMobile === false) {
      return desktopReasonTemplate;
    } else if (this.showCancelModal === false && this.isMobile === true) {
      //FRONT-1954
      return mobileReasonTemplate;
    }
    //FRONT-1946 end
  }

  @wire(CurrentPageReference)
  getPageReferenceParameters(currentPageReference) {
    if (currentPageReference) {
      this.objectAction = currentPageReference.attributes.apiName; //FRONT-4412
      //started for FRONT-4412
      if (
        currentPageReference.attributes.apiName === "SBQQ__Quote__c.Cancel2"
      ) {
        FIELDS = [
          "SBQQ__Quote__c.SBQQ__Status__c",
          "SBQQ__Quote__c.RecordTypeId"
        ]; //FRONT-4412
      } else {
        FIELDS = [
          "Order.Status",
          "Order.RecordTypeId",
          "Order.Converted_Quote_Status__c",
          "Order.Converted_Quote_Status_Reason__c",
          "Order.SBQQ__Quote__c"
        ];
      }
      //ended for FRONT-4412
      this.recordId = currentPageReference.state.recordId;
    }
  }

  //FRONT-1946 start
  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (error) {
    } else if (data) {
      if (data.fields.RecordTypeId.value) {
        this.OrderrecordTypeId = data.fields.RecordTypeId.value;
      }
      //Modified for Front-11393
      if (this.objectApiName === "Order" || this.orderId) {
        //FRONT-4412, 4413
        this.status = data.fields.Status.value;
        //START: FRONT-29566/295678
        this.convertedQuoteRecordId = data?.fields?.SBQQ__Quote__c?.value;
        this.convertedQuoteStatus =
          data?.fields?.Converted_Quote_Status__c?.value;
        this.convertedQuoteStatusReason =
          data?.fields?.Converted_Quote_Status_Reason__c?.value;
        //END: FRONT-29566/295678
      }
      //started for FRONT-4412, 4413
      if (this.objectApiName === "SBQQ__Quote__c") {
        this.status = data.fields.SBQQ__Status__c.value;
      }
      //ended for FRONT-4412, 4413
      if (this.status === "Draft" && this.objectApiName !== "SBQQ__Quote__c") {
        this.showCancelModal = true;
        this.defaultTemplateFlag = false; //Added for FRONT-4412, 4413
      } else if (
        this.status === "Partially Filled" ||
        this.status === "Created"
      ) {
        this.showCancelModal = false;
        this.defaultTemplateFlag = false; //Added for FRONT-4412, 4413
      }
      //Started for FRONT-4412, 4413
      //Modified for FRONT-4588,4589
      else if (this.objectApiName === "SBQQ__Quote__c") {
        this.showCancelModal = true;
        this.defaultTemplateFlag = false;
      }
      //Ended for FRONT-4412, 4413
    }
  }
  //FRONT-1946 end
  closeMethod() {
    if (this.isMobile) {
      const closeEvent = new CustomEvent("closemodal");
      this.dispatchEvent(closeEvent);
    } else {
      this.dispatchEvent(new CloseActionScreenEvent());
      //start for FRONT-1946
      const closeCancelEvent = new CustomEvent("closecancelmodal");
      this.dispatchEvent(closeCancelEvent);
      //ended for FRONT-1946
    }
  }
  // FRONT-1946 start
  get spinStyle() {
    let contCla = this.template.querySelector(".contClass");
    //Added a check to avoid the error if element is not found
    if (contCla) {
      this.widthSpin = contCla.getBoundingClientRect().width;
      this.heightSpin =
        contCla.getBoundingClientRect().height -
        0.4 * contCla.getBoundingClientRect().height;
      return `width:${this.widthSpin}px !important; height:${this.heightSpin}px !important;`;
    }
    return "";
  }
  // FRONT-1946 end

  handleYes() {
    //this.isLoading = true;
    let fields = {};
    //Started for FRONT-4412, 4413
    if (this.objectApiName === "SBQQ__Quote__c") {
      fields[QUOTE_STATUS.fieldApiName] = LABELS.CANCLEORDERSTATUS;
    } else {
      fields[STATUS_FIELD.fieldApiName] = LABELS.CANCLEORDERSTATUS;
    }
    //ended for FRONT-4412, 4413
    if (!this.recordId && this.isMobile) {
      fields[ID_FIELD.fieldApiName] = this.props.recordId;
    } else {
      fields[ID_FIELD.fieldApiName] = this.recordId;
    }
    //start for FRONT-1946
    if (this.picklistval) {
      fields[REASON.fieldApiName] = this.picklistval;
    }
    if (this.otherReasonValue) {
      fields[OTHER_FIELD.fieldApiName] = this.otherReasonValue;
    }
    if (this.commentVal) {
      fields[COMMENT_FIELD.fieldApiName] = this.commentVal;
    }
    //ended for FRONT-1946
    let recordInput = { fields };
    //started for FRONT-7898, FRONT-7899
    if (this.status === "Created") {
      cancelOrder({ orderId: this.recordId, reasonCode: this.picklistval })
        .then((response) => {
          if (response === "Success") {
            this.updateRecordStatus(recordInput);
          } else {
            this.showCustomToast("ERROR", LABELS.ERROR_API_TEXT, "Error");
          }
        })
        .catch((error) => {
          logger.log(error + JSON.stringify(error));
          this.showCustomToast("ERROR", LABELS.ERROR_API_TEXT, "Error");
        });
    }
    //Start for Front-4588, Front-4589
    else if (
      this.objectApiName === "SBQQ__Quote__c" &&
      this.status === "Submitted"
    ) {
      cancelQuote({ quoteId: this.recordId })
        .then((response) => {
          if (response === "Success") {
            this.updateRecordStatus(recordInput);
          } else if (response === "Failed") {
            this.showCustomToast(
              "ERROR",
              "This Quote couldn’t be Cancelled at this time due to an internal error, please try again.",
              "Error"
            );
          } else {
            this.showCustomToast("ERROR", response, "Error");
          }
        })
        .catch((error) => {
          logger.log(error + JSON.stringify(error));
          this.showCustomToast("ERROR", LABELS.ERROR_API_TEXT, "Error");
        });
    } else if (this.objectApiName === "Order" && this.status === "Draft") {
      //FRONT-14063
      this.deleteOrders();
    }
    //End for Front-4588, Front-4599
    else {
      this.updateRecordStatus(recordInput);
    } //ended for FRONT-7898, FRONT-7899
  }
  //FRONT-14063
  deleteOrders() {
    deleteOrder({ orderId: this.recordId })
      .then((response) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Record deleted",
            variant: "success"
          })
        );
        this.closeTabs(); //FRONT-14063
      })
      .catch((error) => {
        console.log("Error:" + JSON.stringify(error));
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Error Deleting Record",
            variant: "error"
          })
        );
      });
  }

  closeTabs() {
    if (!this.isMobile) {
      if (this.isConsoleNavigation) {
        getFocusedTabInfo()
          .then((tabInfo) => {
            closeTab(tabInfo.tabId);
            //FRONT-29566/29567
            this.redirectToQuoteOnCancelOrder();
          })
          .catch(function (error) {
            console.log(error);
          });
      }
    } else {
      if (this.convertedQuoteRecordId) {
        this.redirectToQuoteOnCancelOrder();
      } else {
        this[NavigationMixin.Navigate](
          {
            type: "standard__objectPage",
            attributes: {
              objectApiName: this.objectApiName,
              actionName: "list"
            },
            state: {
              filterName: "Recent"
            }
          },
          false
        );
      }
    }
  }

  handleConfirm() {
    //started for FRONT-1946
    if (this.showCancelModal === false) {
      let reasonPicklist = this.template.querySelector(".reasonPicklist");
      let reasonList = this.template.querySelector(".otherReasonClass");
      if (!reasonPicklist.value) {
        reasonPicklist.setCustomValidity(LABELS.REQUIRED_TEXT);
        reasonPicklist.reportValidity();
      } else if (reasonPicklist.value === "12" && !reasonList.value.trim()) {
        //FRONT-12770 Picklist value has been changed. Other = 12 now.
        reasonList.setCustomValidity(LABELS.REQUIRED_TEXT);
        reasonList.reportValidity();
      } else {
        this.showCancelModal = true;
      }
    }
    //ended for FRONT-1946
  }
  //Started for 1946
  handleOtherReasonChange(event) {
    this.otherReasonValue = event.target.value;
    if (this.template.querySelector(".otherReasonClass")) {
      let reasonList = this.template.querySelector(".otherReasonClass");
      if (reasonList.value.trim()) {
        reasonList.setCustomValidity("");
        reasonList.reportValidity();
      }
    }
    //ended for 1946
    // FRONT-1954
    if (this.showCancelModal == false && this.isMobile == true) {
      this.disableConfirmMethod();
    }
  }
  handleChange(event) {
    //1946 started
    if (this.template.querySelector(".reasonPicklist")) {
      let reasonPicklist = this.template.querySelector(".reasonPicklist");
      if (reasonPicklist.value) {
        reasonPicklist.setCustomValidity("");
        reasonPicklist.reportValidity();
      }
    }
    //1946 ended
    this.picklistval = event.target.value;
    this.otherReasonValue = "";
    if (event.target.value === "12") {
      //FRONT-12770 Picklist value has been changed. Other = 12 now.
      this.showReasonField = true;
    } else {
      this.showReasonField = false;
    }
    // FRONT-1954
    if (this.showCancelModal == false && this.isMobile == true) {
      this.disableConfirmMethod();
    }
  }
  //started for FRONT-1946
  handleComment(event) {
    this.commentVal = event.target.value;
  }
  //Ended for FRONT-1946

  // FRONT-1954
  disableConfirmMethod() {
    if (
      (this.picklistval != "" && this.picklistval !== "12") ||
      (this.picklistval === "12" && this.otherReasonValue != "")
    ) {
      //FRONT-12770 Picklist value has been changed. Other = 12 now.
      this.disableConfirm = false;
    } else {
      this.disableConfirm = true;
    }
  }

  //START FRONT-7898,7899
  showCustomToast(title, msg, variant) {
    const newEvent = new ShowToastEvent({
      title: title,
      message: msg,
      variant: variant
    });
    this.dispatchEvent(newEvent);
    this.isLoading = false;
    this.closeMethod();
  }
  updateRecordStatus(recordInput) {
    updateRecord(recordInput)
      .then(() => {
        //Added for FRONT-4412, 4413
        if (this.objectApiName == "SBQQ__Quote__c") {
          this.showCustomToast("Success", LABELS.CANCEL_QUOTE_TOAST, "success");
        }
        //Ended for FRONT-4412, 4413
        else {
          const newEvent = new ShowToastEvent({
            title: "Success",
            message: LABELS.CANCELORDERTOAST,
            variant: "success"
          });
          this.dispatchEvent(newEvent);
          this.isLoading = false;
          this.closeMethod();
        }
      })
      .catch((error) => {
        console.log(JSON.stringify(error));
        this.isLoading = false;
      });
  } //END FRONT-7898,7899

  /* FRONT-15984 - Added code to hide extra close icon when called from AURA quick actions - Starts */
  removeDefaultCloseIconView() {
    if (!this.rendered) {
      this.rendered = true;
      let customStyle = `.closeIcon{
              display : none !important;
            }`;
      const rootNode = this.template.ownerDocument;
      this.customStyleDivElement = rootNode.createElement("div");
      const styleNode = rootNode.createElement("style");
      if (styleNode.styleSheet) {
        styleNode.styleSheet.cssText = customStyle;
      } else {
        styleNode.appendChild(rootNode.createTextNode(customStyle));
      }
      this.customStyleDivElement.appendChild(styleNode);
      rootNode.body.appendChild(this.customStyleDivElement);
    }
  }
  disconnectedCallback() {
    this.unsetDefaultCloseIconView();
  }
  unsetDefaultCloseIconView() {
    this.customStyleDivElement?.remove();
  }
  /* FRONT-15984 Ends */

  /* Code Added for FRONT-15079 */
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [TotalAmount, InvoiceAmount]
  })
  totalAmount({ error, data }) {
    if (data) {
      if (getFieldValue(data, TotalAmount) != null) {
        this.totalAmount = getFieldValue(data, TotalAmount).toFixed(2);
      }
      if (getFieldValue(data, InvoiceAmount) != null) {
        this.InvoiceAmount = getFieldValue(data, InvoiceAmount).toFixed(2);
      }
      this.setAllData();
    } else if (error) {
      console.error(error);
    }
  }

  async setAllData() {
    try {
      this.getTotalDeposit();
    } finally {
      //  this.showSpinner = false;
    }
  }

  /* Fetch total deposit */
  getTotalDeposit() {
    Promise.all([
      this.getFetchTotalRefundDeposit(),
      this.getFetchTotalDeposit()
    ]); //FRONT-15561 FRONT-15916
  }
  getFetchTotalRefundDeposit() {
    //FRONT-15561 FRONT-15916
    fetchTotalRefundDeposit({ orderId: this.recordId })
      .then((data) => {
        if (data != null) {
          this.depositAmount = data.toFixed(2);
        } else {
          this.depositAmount = "0.00";
        }
      })
      .catch((error) => {
        console.error("error", error);
      });
  }

  getFetchTotalDeposit() {
    //FRONT-15561 FRONT-15916
    fetchTotalDeposit({ orderId: this.recordId })
      .then((data) => {
        this.refundAmount = (data.toFixed(2) - this.InvoiceAmount).toFixed(2);
        if (this.refundAmount <= 0) {
          if (this.noRefundgiven == false || this.noRefundgiven == undefined) {
            this.noRefund = true;
          }
          this.refundAmount = 0;
          if (
            this.isRefundNotAvailable === false &&
            this.isRefundAvailable === false
          ) {
            this.isRefundNotAvailable = true;
          }
        } else {
          if (
            this.isRefundNotAvailable === false &&
            this.isRefundAvailable === false
          ) {
            this.isRefundAvailable = true;
          }
        }
      })
      .catch((error) => {
        console.error("error", error);
      });
  }

  handleCallFromRefund() {
    this.isRefundAvailable = false;
    this.isLoading = false;
    this.isRefundNotAvailable = true;
    this.noRefund = false;
    this.norefundgiven = true;
  }
  /* End of FRONT-15079 */

  //START: FRONT-29566/29567
  redirectToQuoteOnCancelOrder() {
    if (this.convertedQuoteRecordId && this.convertedQuoteStatus) {
      let fields = {};
      fields[CONVERTED_QUOTE_Id.fieldApiName] = this.convertedQuoteRecordId;
      fields[CONVERTED_QUOTE_STATUS.fieldApiName] = this.convertedQuoteStatus;
      fields[CONVERTED_QUOTE_STATUS_REASON.fieldApiName] =
        this.convertedQuoteStatusReason;
      updateRecord({ fields })
        .then(() => {
          this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: this.convertedQuoteRecordId,
              actionName: "view"
            }
          });
        })
        .catch((error) => {
          logger.log("Error in UpdateRecord", JSON.stringify(error));
        });
    }
  }
  //END: FRONT-29566/29567
}