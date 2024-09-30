import { LightningElement, wire, api, track } from "lwc";
import {
  getRecord,
  getFieldValue,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import {
  MessageContext,
  publish,
  subscribe,
  unsubscribe
} from "lightning/messageService";
import RecordAction from "@salesforce/messageChannel/RecordAction__c";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";
import updateRecords from "@salesforce/apex/sbr_3_0_drfDMLServiceDelegator.updateRecord";
import submitRecord from "@salesforce/apex/sbr_3_0_drfDMLServiceDelegator.submitRecordToRM";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import checkRecord from "@salesforce/apex/SBR_3_0_DynamicRecordFormController.checkRecord"; // FRONT - 13994, 13996
import { appName, FL_APP_NAME } from "c/sbr_3_0_frontlineUtils";
import { NavigationMixin } from "lightning/navigation";

import LABELS from "c/sbr_3_0_customLabelsCmp";
//added for FRONT-23924 START
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c'; 
import createTransaction from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction"; 
import { createMessageContext} from 'lightning/messageService';
import { updateRecord } from "lightning/uiRecordApi";
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
//added for FRONT-23924 END

import DefaultTemplate from "./sbr_3_0_dynamicRecordFormCollector.html";
import mobileTemplate from "./sbr_3_0_dynamicRecordFormCollectorMobileTemplate.html"; 

const ID_FIELD = "Id";
const IS_EDIT_IN_PROGRESS_FIELD = "Is_Edit_In_Progress__c";
const LAST_EDITED_BY = "Last_Edit_By__c";
const logger = Logger.create(true);
const SAVE_ACTION = "save";
const SUBMITTED_ACTION = "submitted";
const REGISTER_ACTION = "register";
const CANCEL_ACTION = "cancel";
const ERROR_ACTION = "error";
const COLLECTOR_POS_REQ_ACTION = "collectorpos_req";
const COLLECTOR_POS_RES_ACTION = "collectorpos_res";
const ALL_LISTENERS = "All";
const SPINNER_CLASS = "spinner";
const LOADING_MESSAGE = "Loading...";
const SAVING_RECORD_MESSAGE = "Saving...";
const RENTALMAN_QUOTE_ID_DISPLAY_FIELD_API = "Rentalman_Quote_Id_Display__c"; //FRONT - 25229
const RESERVATION_NUMBER_FIELD_API = "Reservation_Order_Number__c";
const RENTALMAN_QUOTE_NUMBER_FIELD_API = "Rentalman_Quote_Id__c"; //FRONT-2050,10257
const STALE_TOTALS = "Pending_Tax_Calculation__c"; // FRONT-20239, FRONT-18373
const ORDER_STATUS = "Status"; //FRONT-13995
const RECORDTYPE = "RecordType.Name"; //FRONT-13995
const ORDER_NAME = "Name"; //FRONT-24247
const QUOTE_NAME = "Quote_Name__c"; //FRONT-25229
export default class Sbr_3_0_dynamicRecordFormCollector extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  _objectApiName;
  @api
  get objectApiName() {
    return this._objectApiName;
  }
  @api showUpdateTotalsFooter;

  set objectApiName(value) {
    this._objectApiName = value;
    if (this._objectApiName === "SBQQ__Quote__c") {
      this.fieldsToQuery = [
        `${this.objectApiName}.${ID_FIELD}`,
        `${this.objectApiName}.${IS_EDIT_IN_PROGRESS_FIELD}`,
        `${this.objectApiName}.${RENTALMAN_QUOTE_NUMBER_FIELD_API}`,
        `${this.objectApiName}.${STALE_TOTALS}`,
        `${this.objectApiName}.${RECORDTYPE}` //FRONT-13995
      ];
    } else if (this._objectApiName === "Order") {
      this.fieldsToQuery = [
        `${this.objectApiName}.${ID_FIELD}`,
        `${this.objectApiName}.${IS_EDIT_IN_PROGRESS_FIELD}`,
        `${this.objectApiName}.${RESERVATION_NUMBER_FIELD_API}`,
        `${this.objectApiName}.${STALE_TOTALS}`, // FRONT-13995
        `${this.objectApiName}.${ORDER_STATUS}`, // FRONT-13995
        `${this.objectApiName}.${RECORDTYPE}` //FRONT-13995
      ];
    }
  }

  _actionName;

  @api
  get actionName() {
    return this._actionName;
  }

  set actionName(value) {
    this._actionName = value;
  }
  _isHeadless = false;
  @api
  get isHeadless() {
    return this._isHeadless;
  }

  set isHeadless(value) {
    this._isHeadless = Boolean(value);
  }
  @api depositAmountValue;

  @track isCSSLoaded = false;
  subscription = null;
  isEditMode = false;
  idField;
  isEditInProfressField;
  fields = {};
  isLoading = false;
  lastMessage;
  currentMessage;
  spinnerMessage = LOADING_MESSAGE;
  hasError;
  isMobile = false;
  requiredFields;
  alertMessage = "";
  isValidationError = false;
  showDiscardChanges = false;
  hasAPISubmitted;
  reservationOrderNumber;
  staleTotals = true; //FRONT-13994
  showReviewToast = false; //FRONT-13994, 13996
  rentalManQuoteId; //FRONT-2050,10257
  saveButtonText = "Save"; //FRONT-14065
  cancelButtonText = "Cancel"; //FRONT-14065
  isContract = false; //Front-13084
  /* START : FRONT-13995 */
  staleTotalsOrder;
  orderStatus;
  orderRecType;
  quoteRecType;
  callCreateOrder = true;
  errMsg = "";
  isDataLoaded = false; // FRONT-20459
  /* END : FRONT-13995 */
  orderName; //FRONT-24247
  quoteName; //FRONT-25229
  @track hasRentalManId = false; //FRONT-14065
  @track FORM_STORE_local = FORM_STORE;
  @track reservationStatus;
  @track saveError = false;
  //added for FRONT-23924 START
  @api recordDetails = {}; 
  transactionId = '';
  paymentProcessing = false;
  @api createReservation=false;
  paymentOptionSelected;
  terminalValue = '';
  @api paymentMethodRelatedData;
  isRendered;
  errorMessage;
 //added for FRONT-23924 END
 isApiCallComplete = false;


  // @wire(MessageContext)
  // messageContext;
  messageContext = createMessageContext(); //added for FRONT-23924
  @wire(getRecord, {
    recordId: "$recordId",
    fields: "$fieldsToQuery"
  })
  wiredRecord({ error, data }) {
    if (data) {
      this.isDataLoaded = true; // FRONT-20459
      this.isEditMode = data.fields.Is_Edit_In_Progress__c.value;
      //FRONT-14065 start
      if (this._objectApiName === "SBQQ__Quote__c") {
        this.rentalManQuoteId = data.fields.Rentalman_Quote_Id__c.value;
        this.staleTotals = data.fields.Pending_Tax_Calculation__c.value; //FRONT-13994, FRONT-20239, FRONT-18373
      } else if (this._objectApiName === "Order") {
        this.reservationOrderNumber =
          data.fields.Reservation_Order_Number__c.value;
        /* START : FRONT-13995 */
        this.staleTotalsOrder = data.fields?.Pending_Tax_Calculation__c?.value; //FRONT-20239, FRONT-18373
        this.orderStatus = data.fields?.Status?.value;
        this.orderRecType = data.fields?.RecordType?.displayValue;
        /* END : FRONT-13995 */
      }
      if (this.reservationOrderNumber || this.rentalManQuoteId) {
        this.hasRentalManId = true;
      }
      this.getButtonLabels();
      if (this.isHeadless) {
        this.runHeadLessActions();
      }
      //FRONT-14065 end
    } else if (error) {
      logger.error(error);
    }
  }

  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
    this.setAppName();
    this.subscribeToMessageChannel();
    this.addResizeEventListener();
    this.depositAmountValue = this.createReservation ? this.recordDetails?.amountCollected : this.depositAmountValue;
    [this.terminalValue, this.paymentOptionSelected] = [this.recordDetails?.terminal, this.recordDetails?.paymentMethod]
  }

  render() {
    if (this.isMobile == true) {
        return mobileTemplate;
    } else {
        return DefaultTemplate;
    }
}

  async setAppName() {
    this.appName = await appName;
  }

  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }

  getButtonLabels() {
    if (this._objectApiName === "SBQQ__Quote__c") {
      if (!this.rentalManQuoteId) {
        this.saveButtonText = "Create Quote";
        this.cancelButtonText = "Cancel";
      } else {
        this.saveButtonText = "Save";
        this.cancelButtonText = "Discard Changes";
      }
    }
    //START::FRONT - 14063
    if (this._objectApiName === "Order") {
      logger.log("reservationOrderNumber1:" + this.reservationOrderNumber);
      //Front-13084
      if (this.orderRecType === 'Create Contract') {
        this.isContract = true;
        this.saveButtonText = "Create Contract";
        this.cancelButtonText = "Cancel";
      }
      else {
        //Front-13084
        if (!this.reservationOrderNumber) {
          this.saveButtonText = "Create Reservation";
          this.cancelButtonText = "Cancel";
        } else {
          this.saveButtonText = "Save";
          this.cancelButtonText = "Discard Changes";
        }
      }
    }
    //END::FRONT - 14063
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        RecordAction,
        (message) => this.handleMessage(message)
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleCancelClick(event) {
    event?.preventDefault();
    //START::FRONT - 14063
    //Added for 13084
    if (this._objectApiName === "Order" && !this.reservationOrderNumber
      && this.orderRecType != 'Create Contract') {
      this.dispatchEvent(new CustomEvent("deleterecord"));
    } else {
      this.spinnerMessage = LOADING_MESSAGE;
      window.scrollTo(0, 0);
      this.lastMessage = this.currentMessage;
      this._actionName = CANCEL_ACTION;
      this.hasError = false;
      this.updateEditInProgress();
    }
  }

  async updateEditInProgress() {
    let fields = {};
    fields[ID_FIELD] = this.recordId;
    fields[IS_EDIT_IN_PROGRESS_FIELD] = false;
    fields[LAST_EDITED_BY] = "";
    this.saveRecord(fields);
  }

  handleMessage(message) {
    logger.log("#### Response Collector ", message.origin, message.action);
    let action = message.action;
    this.currentMessage = message;
    switch (action) {
      case SUBMITTED_ACTION:
        this.handleDynamicFormsSubmit(message);
        break;
      case COLLECTOR_POS_REQ_ACTION:
        this.sendPositionDetails(message);
        break;
      case REGISTER_ACTION:
        logger.log("#### Register ", message);
        break;
      case ERROR_ACTION:
        logger.log("#### Error ", JSON.stringify(message.params));
        this.requiredFields = message.params;

        this.setError(true);
        break;
      default:
        logger.log("Not a valid action");
    }
  }

  async saveRecord(data) {
    await this.waitForDataLoaded(); // FRONT-20459
    /* Added if else for FRONT-13993 , FRONT-13995 */
    if (
      this.appName === "RAE Frontline" &&
      ((this.staleTotalsOrder &&
        this.objectApiName === "Order" &&
        this.orderRecType === "Reservation Order") ||
        (this.staleTotals && this.objectApiName === "SBQQ__Quote__c")) &&
      !this.isMobile &&
      this._actionName === SAVE_ACTION
    ) {
      if (this.objectApiName === "Order") {
        this.errMsg =
          "You have updated the order, Please click on the Order Review tab to confirm before submitting the Reservation";
      } else {
        this.errMsg =
          "You have updated the quote, Please click on the Quote Review tab to confirm before submitting the Quote";
      }
       //this.callCreateOrder = false; //added for FRONT-23924
      this.callSaveRecord(data); //added for FRONT-23924
    } else if (
      this.appName === "RAE Frontline" &&
      this.isMobile &&
      this._actionName === SAVE_ACTION &&
      (this._objectApiName === "SBQQ__Quote__c" ||
        this.objectApiName === "Order")
    ) {
      //START: FRONT-13994, 13996
      checkRecord({ objectName: this.objectApiName, recordId: this.recordId })
        .then((result) => {
          this.showReviewToast = result;
          if (this.showReviewToast) {
            if (this._objectApiName === "Order") {
              this.errMsg =
                "You have updated the Order, please click on the Order Review tab to confirm before submitting the Order";
            } else {
              this.errMsg =
                "You have updated the Quote, please click on the Quote Review tab to confirm before submitting the Quote";
            }
            this.setError(true);
            this.dispatchEvent(
              new ShowToastEvent({
                title: "",
                message: this.errMsg,
                variant: "error"
              })
            );
          } else {
            if (this.objectApiName === "Order" && this.orderRecType === "Reservation Order") {
              this.closeEditActionDelegator();
            }
            this.callSaveRecord(data);
          }
        })
        .catch((error) => {
          logger.error("Error in Show Toast", error);
        });
      // END: FRONT-13994, 13996
    } else {
      this.callSaveRecord(data);
    }
  }

  closeEditActionDelegator() {
    this.dispatchEvent(
      new CustomEvent("closeeditactiondelegator", {
        detail: {
          hidetemplate: false,
          isCreateReservation : true
        }
      })
    );
  }


  async callSaveRecord(data) {
    this.hasAPISubmitted = false;
    this.isLoading = true;
    this.isValidationError = false;
    this.hasError = false; //adding for debug purpose
    if (!this.hasError) {
      const recordInput = {
        objectApiName: this.objectApiName,
        fields: data,
        actionType: this._actionName
      };
      await updateRecords(recordInput)
        .then(() => {
          if (this._actionName === SAVE_ACTION) {
            //added rentalman quoteid inside condition FRONT-2050,10257
            this.spinnerMessage = "Submitting...";
            this.executeSubmitAction();
            this.isValidationError = false;
          }
          else
          {
            if (this.isMobile) {
              this.navigateToRecord();
            }
          }
        })
        .catch((error) => {
          this.saveError = true;
          const errorNode = error.body.pageErrors || error.body.fieldErrors;
          const errorMessage = errorNode[0].message;
          this.isValidationError = true;
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Review the error on this page.",
              message: errorMessage,
              variant: "error"
            })
          );
        });
      if (!this.hasAPISubmitted)
        await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
    } else {
      let sections = {};

      // Iterate through the array and organize field names
      this.requiredFields.fields.forEach(function (field) {
        if (!sections[field.sectionName]) {
          sections[field.sectionName] = [];
        }
        sections[field.sectionName].push(field.fieldName);
      });

      for (let section in sections) {
        this.alertMessage +=
          section + ": " + sections[section].join(", ") + "\n , ";
      }
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Required Fields Missing",
          message:
            "Please complete the following required fields. " +
            this.alertMessage.slice(0, -2),
          variant: "error"
        })
      );
      if (this.isMobile) {
        this.isLoading = false;
        this.requiredFields = [];
        this.alertMessage = "";
        return;
      }
    }
    if (this.isMobile && this.isValidationError) {
      this.isLoading = false;
      this.requiredFields = [];
      this.alertMessage = "";
      return;
    }

    this.isLoading = false;
    this.requiredFields = [];
    if (!this.hasAPISubmitted) this.closeAuraAction();
  }

  isValidString(inputString) {
    const regexPattern = /^[a-zA-Z0-9\-_\. ]*$/;
    return regexPattern.test(inputString);
  }

  handleSaveClick() {
    this.setError(false);
    this.spinnerMessage = SAVING_RECORD_MESSAGE;
    this.fields[ID_FIELD] = this.recordId;
    this.reservationOrderNumber =
      FORM_STORE.records[this.recordId]?.fields?.[
        RESERVATION_NUMBER_FIELD_API
      ]?.value;
    this.rentalManQuoteId =
      FORM_STORE.records[this.recordId]?.fields?.[
        RENTALMAN_QUOTE_ID_DISPLAY_FIELD_API
      ]?.value;
    //FRONT-24247,FRONT-25229
    this.orderName =
      FORM_STORE.records[this.recordId]?.fields?.[
        ORDER_NAME
      ]?.value;
    this.quoteName =
      FORM_STORE.records[this.recordId]?.fields?.[
        QUOTE_NAME
      ]?.value;
    
    //added object check FRONT-2050,10257 END
    publish(this.messageContext, RecordAction, {
      action: SAVE_ACTION
    });
    this._actionName = SAVE_ACTION;
    this.saveRecord(this.fields);
   
  }

  handleDynamicFormsSubmit(message) {
    this.fields = Object.assign({}, this.fields, message.params.fields);
  }

  renderedCallback() {
    if(this.isRendered) return;
    if (!this._currentYPos && !this.isHeadless) {
      this.getCurrentYPost();
    }
    if (this.createReservation && !this.isMobile) {
      const STYLE = document.createElement("style");
      STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
          max-width: 35rem;   
          min-width: 35rem;
      }`;
      this.template.querySelector('.record-form-collector-container').appendChild(STYLE);

      const hideExtraCloseIcon = document.createElement("style");
      hideExtraCloseIcon.innerText = `.slds-button_icon-bare{
          content-visibility :hidden;
          visibility: collapse;
      }`;
      this.template.querySelector('.record-form-collector-container').appendChild(hideExtraCloseIcon);

      const STYLEN = document.createElement("style");
      const STYLEN1 = document.createElement("style");
      STYLEN.innerText = ` .header{
      content-visibility :hidden;
      }`;
      STYLEN1.innerText = ` .slds-card__header{
          content-visibility :hidden;
      }`;
      this.template.querySelector('.record-form-collector-container').appendChild(STYLEN);
      this.template.querySelector('.record-form-collector-container').appendChild(STYLEN1)
    }
    this.isRendered = true
  }

  getCurrentYPost() {
    const footer = this.template.querySelector(".dynamic-form-footer");
    if (footer) {
      this._currentYPos = footer.getBoundingClientRect().top;
    }
  }

  sendPositionDetails() {
    publish(this.messageContext, RecordAction, {
      action: COLLECTOR_POS_RES_ACTION,
      params: {
        top: this._currentYPos
      },
      origin: this.lastMessage?.origin || this.currentMessage.origin
    });
    this.lastMessage = null;
  }

  addResizeEventListener() {
    if (!this.isMobile && !this.isHeadless) {
      window.addEventListener("resize", () => {
        this.getCurrentYPost();
        this.sendPositionDetails({ origin: ALL_LISTENERS });
      });
    }
  }

  closeAuraAction() {
    this.dispatchEvent(
      new CustomEvent("closeauraaction", {
        detail: {
          action: this.actionName
        }
      })
    );
    //added for FRONT-23924 START
      const message = {
        closeModal: true
    };
    publish(this.messageContext, CLOSE_MODAL, { payload: message });
    //added for FRONT-23924 END
  }
  handleCloseAction() {
    this.dispatchEvent(
      new CustomEvent("closeauraaction", {
        detail: {
          action: "Cancel"
        }
      })
    );
      //added for FRONT-23924 START
    const message = {
      closeModal: true
    };
    publish(this.messageContext, CLOSE_MODAL, { payload: message });
    //added for FRONT-23924 END
    if (this.isMobile) {
      this.navigateToRecord();
    }
  }

  runHeadLessActions() {
    switch (this.actionName) {
      case SAVE_ACTION:
        this.handleSaveClick();
        break;
      case CANCEL_ACTION:
        this.handleCancelClick();
        break;
      default:
        logger.log("No action name set");
    }
  }

  get showButtons() {
    return this.isEditMode && !this.isHeadless;
  }

  get spinnerClass() {
    return this.isHeadless ? SPINNER_CLASS : "";
  }

  setError(value) {
    this.hasError = value;
  }
  async executeSubmitAction() {
    this.hasAPISubmitted = true;
    this.isLoading = true;
    console.log('executeSubmitAction : 674');
    let recordDetailsString = ''

    if (this.objectApiName == 'Order') {
      this.paymentProcessing = true;
      recordDetailsString = JSON.stringify(this.recordDetails, null, "\t");  //added for FRONT-23924
      await this.createTransactionRecord();  //added for FRONT-23924
    }
    await submitRecord({
      objectApiName: this.objectApiName,
      recordId: this.recordId,
      transactionId: this.transactionId,
      recordDetails: recordDetailsString
    })
      .then(async (response) => {
        logger.log("executeSubmitAction Response" , response);
        if (this.objectApiName == 'Order') {
          await this.processOrderAPIResponse(response);
        }
        this.saveError = false;

        if (this.appName === "RAE Frontline" &&
          this.objectApiName === "Order" &&
          this.orderRecType === "Reservation Order" &&
          this._actionName === SAVE_ACTION) {
          // this.dispatchEvent( //commented for FRONT-23924
          //   new ShowToastEvent({
          //     title: "Success",
          //     message: this.reservationOrderNumber ? LABELS.EDITS_SAVED : `${this.orderName} has been successfully created.`, //FRONT-24247
          //       variant: "success"
          //     })
          //   );
        }
        else {
          this.dispatchEvent(
            new CustomEvent("closeauraaction", {
              detail: {
                closeModal: true
              }
            })
          );

          this.dispatchEvent( //commented for FRONT-23924
            new ShowToastEvent({
              title: "Success",
              message: this.rentalManQuoteId ? LABELS.EDITS_SAVED : `${this.quoteName} has been successfully created.`, //FRONT-25229
              variant: "success"
            })
          );
        }

        if (this.isMobile) {
          //this.navigateToRecord();
        }
      })
      .catch((error) => {
        console.error('error in execute action', error);
        this.errorMessage = error?.body?.message || error?.body || error;
        this.saveError = true;
        // this.dispatchEvent( //commented for FRONT-23924
        //   new ShowToastEvent({
        //     title: "Error",
        //     message: error.body.message,
        //     variant: "error"
        //   })
        // );
      }).finally(() => {
        this.isApiCallComplete = true;
        this.isLoading = false;
        this.isHeadless = false;
        if (this.objectApiName != 'Order') {
          this.closeAuraAction(); //commented for FRONT-23924
        }
      })

    await notifyRecordUpdateAvailable([{ recordId: this.recordId }]); //commented for FRONT-23924
  }

  async processOrderAPIResponse(response) {
    try {
      response = JSON.parse(response);
      const { detailSeqNumber } = response?.data;
      const isNonCard = ['Cash Currency', 'Check', 'Pay on Return'].includes(this.paymentOptionSelected);
      if (isNonCard && detailSeqNumber) {
        await this.updateTransactionRecord(detailSeqNumber);
      }
    } catch (error) {
      console.log('error in processOrderAPIResponse', error);
      this.errorMessage = error?.body?.message || error?.body || error;
    }
  }

  async updateTransactionRecord(detailSeqNumber) { //added for FRONT-23924
    const fields = {
      Id: this.transactionId,
      RM_Detail_Sequence_Number__c: detailSeqNumber
    };
    const recordInput = { fields };
    updateRecord(recordInput).then(result => {
      const message = {
        messageToSend: 'success',
        sourceSystem: "From Comp : MakeADeposit"
      };
      publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
    }).catch(error => {
      console.error('Error updating transaction record:', error);
      this.errorMessage = error?.body?.message || error?.body || error;
    });
  }

 async  createTransactionRecord(){ //added for FRONT-23924
  const recordDetailsString = JSON.stringify(this.recordDetails, null, "\t");
  logger.log('Parameters==',this.recordId+'-'+recordDetailsString);
    await createTransaction({
      orderRecordId: this.recordId,
      paymentDepositData : recordDetailsString
    })
      .then(data => {
        console.log('inside createTransaction',data)
        if (data != null) {
          this.transactionId = data;
        }
      }).catch(error => {
        console.error('Error in createTransactionRecord', error);
        this.errorMessage = error?.body?.message || error?.body || error;
      })
  }

  //START FRONT-13994, 13996
  handleRetryClick() {
    logger.log('handleRetryClick1')
    let retryEvent = new CustomEvent("retry");
    this.dispatchEvent(retryEvent);
  }

  handleCloseClick() {
    this.showUpdateTotalsFooter = false;
    let closeUpdateTotals = new CustomEvent("closeupdatetotals");
    this.dispatchEvent(closeUpdateTotals);
  }

  //FRONT-13995
  async getApp() {
    try {
      const results = await getAppName();
      this.appName = results;
    } catch (error) {
      logger.error("Error:", error);
    }
  }
  //END FRONT-13994, 13996

  waitForDataLoaded() {
    // FRONT-20459
    return new Promise((resolve) => {
      const checkDataInterval = setInterval(() => {
        if (this.isDataLoaded) {
          clearInterval(checkDataInterval);
          resolve();
        }
      }, 100);
    });
  }

  navigateToRecord() {
    if (this.recordId && this.objectApiName) {
      this[NavigationMixin.Navigate](
        {
          type: "standard__recordPage",
          attributes: {
            recordId: this.recordId,
            actionName: "view"
          }
        }
      );
    }
  }
}