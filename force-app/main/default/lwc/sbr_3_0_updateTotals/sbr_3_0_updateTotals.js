import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import checkUserPermissions from "@salesforce/apex/SBR_3_0_UpdateTotals.checkUpdateablePermission";
import updateTotals from "@salesforce/apex/SBR_3_0_UpdateTotals.updateTotals";
import callSource from "@salesforce/apex/SBR_3_0_API_ReservationSourcingCall.callSource";
import callQuoteSource from "@salesforce/apex/SBR_3_0_API_QuoteSourcingCall.callSource";
import updateTotalsChannel from "@salesforce/messageChannel/updateTotalsChannel__c";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import { MessageContext, publish } from "lightning/messageService";
import callSourceFrontline from "@salesforce/apex/SBR_3_0_API_ReservationSourcingCall.callSourceFrontline"; //Added this method as part of FRONT-21763
import callQuoteSourceFrontline from "@salesforce/apex/SBR_3_0_API_QuoteSourcingCall.callSourceFrontline"; //Added this method as part of FRONT-21763
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { Logger } from "c/sbr_3_0_frontlineUtils";

const logger = Logger.create(true);
export default class sbr_3_0_updateTotals extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;
  @api callingUpdateTotalsFromUpdateReviewTab;
  @api isChanged;
  @track isError = false;
  @track isSuccess = false;
  @track isCloseDisabled = true;
  @track isRetryDisabled = true;
  @track isMobile = false;
  isButtonDisabled = false;
  appName;

  @track message;
  errorMessage;
  timerId;

  @track showSpinner = false;

  @wire(MessageContext)
  messageContext;

  @wire(checkUserPermissions, { recordId: "$calculatedRecordId" })
  wiredPermissions({ error, data }) {
    if (data) {
      this.objectApiName = data.objectApi;
      this.isButtonDisabled = !data.hasPermission;
      if (data.hasPermission) {
        this.refreshTotals();
      } else if (data.hasPermission == false) {
        this.setErrorMessage(
          "Sales Reps can only access this function for record they own. Please reach out to your manager if you need to update this record."
        );
        this.callValueChangeEvent();
      }
    } else if (error) {
      logger.log(
        "==error in wiredPermissions==",
        error.stack,
        "===",
        JSON.stringify(error)
      );
    }
    getRecordNotifyChange([{ recordId: this.recordId }]);
  }

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.getApp(); //FRONT-13994
  }

  refreshTotals() {
    this.callValueChangeEvent();
    this.showSpinner = true;
    this.message = "Updating totals...";
    this.isError = false;
    this.isSuccess = false;
    this.isCloseDisabled = true;
    this.isRetryDisabled = true;

    if (this.objectApiName == "Order") {
      this.toggleLoadingModalScreen();
      this.callSource();
    } else if (this.objectApiName == "SBQQ__Quote__c") {
      this.callQuoteSource();
    } else {
      this.showSpinner = false;
    }
    //this.callEstimateAPI2UpdateTotals();
  }

  async callSource() {
    this.showSpinner = true;
    //this.message = 'Calling Sourcing API..';
    this.isError = false;
    this.isSuccess = false;
    this.isCloseDisabled = true;
    this.isRetryDisabled = true;

    //Added this method as part of FRONT-21763
    if (this.isAppFrontline) {
      let record = FORM_STORE.updatedRecords[this.recordId];
      logger.log(
        this.isChanged,
        "==isfrontline==",
        this.isAppFrontline,
        "==record==",
        JSON.stringify(record)
      );
      if (record && this.isChanged) {
        await callSourceFrontline({
          orderObj: record,
          orderId: this.recordId
        });
      }
    }

    callSource({ orderId: this.recordId })
      .then((result) => {
        this.callThen(result);
      })
      .catch((error) => {
        this.callCatch(error);
      });
  }

  async callQuoteSource() {
    this.showSpinner = true;
    //this.message = 'Calling Sourcing API..';
    //this.isError = false;
    //this.isSuccess = false;
    //this.isCloseDisabled = true;
    //this.isRetryDisabled = true;
    if (this.isAppFrontline) {
      let record = FORM_STORE.updatedRecords[this.recordId];
      logger.log(
        this.isChanged,
        "==isfrontline==",
        this.isAppFrontline,
        "==record==",
        JSON.stringify(record)
      );
      if (record && this.isChanged) {
        await callQuoteSourceFrontline({
          quoteObj: record,
          quoteId: this.recordId
        });
      }
    }

    callQuoteSource({ quoteId: this.recordId })
      .then((result) => {
        this.callQuoteThen(result);
      })
      //23506
      // .then(this.callEstimateAPI2UpdateTotals())
      .catch((error) => {
        this.callQuoteCatch(error);
      });
  }

  setErrorMessage(msg) {
    this.isError = true;
    this.showSpinner = false;
    this.isCloseDisabled = false;
    this.isRetryDisabled = true;
    this.errorMessage = msg;
  }

  @api
  handleCloseClick() {
    const closeQA = new CustomEvent("close");
    this.dispatchEvent(closeQA);
    // this.navigateToViewPage();
  }
  // navigateToViewPage() {
  //     this[NavigationMixin.Navigate]({
  //     type: 'standard__recordPage',
  //     attributes: {
  //         recordId: this.recordId,
  //         objectApiName: 'SBQQ__Quote__c',
  //         actionName:'view'
  //     },
  //     });
  //  }

  @api
  handleRetryClick() {
    this.refreshTotals();
  }

  callValueChangeEvent() {
    const valueChangeEvent = new CustomEvent("valuechange", {
      detail: {
        isCloseDisabled: this.isCloseDisabled,
        isRetryDisabled: this.isRetryDisabled
      }
    });
    // Fire the custom event
    this.dispatchEvent(valueChangeEvent);
  }

  displayErrorMsg(error) {
    if (error != null && error.body != null && error.body.message != null) {
      if (
        error.body.message.includes(
          "The Reservation submission was unsuccessful."
        )
      ) {
        this.errorMessage =
          "Something went wrong, we could not complete your request!";
      } else {
        this.errorMessage = error.body.message;
      }
    } else {
      this.errorMessage = "Failed to retrieve Sourcing Branch";
    }
  }

  //START FRONT-13994, 13996
  getApp() {
    getAppName()
      .then((results) => {
        this.appName = results;
      })
      .catch((error) => {
        logger.log(
          "==error in getAppName==",
          error.stack,
          "===",
          JSON.stringify(error)
        );
      });
  }

  get isAppFrontline() {
    return this.appName === "RAE Frontline";
  }

  showUpdateTotalsFooter() {
    if (this.appName === "RAE Frontline" && this.isError) {
      const errorUpdateTotalsEvent = new CustomEvent("errorupdatetotals");
      this.dispatchEvent(errorUpdateTotalsEvent);
    }
  }
  //END FRONT-13994, 13996

  get calculatedRecordId() {
    if (this.appName) {
      return this.recordId;
    } else {
      return undefined;
    }
  }

  callThen(result) {
    this.isSuccess = true;
    //START : FRONT-13993,FRONT-13995
    if (this.callingUpdateTotalsFromUpdateReviewTab) {
      const callEvent = new CustomEvent("updatetotalsuccess");
      this.dispatchEvent(callEvent);
    }
    //END : FRONT-13993,FRONT-13995
    this.showSpinner = false;
    this.isCloseDisabled = false;

    //FRONT-31379
    this.closeLoadingModal();

    getRecordNotifyChange([{ recordId: this.recordId }]);
    this.message = "Update Totals Success.";
    if (this.appName == "RAE Frontline") {
      //FRONT-13994
      this.handleCloseClick();
    } else {
      this.callValueChangeEvent();
    }
  }

  callCatch(error) {
    logger.log(
      "==error in callCatch==",
      error.stack,
      "===",
      JSON.stringify(error)
    );
    //FRONT-31379
    this.closeLoadingModal();

    this.isError = true;
    this.showSpinner = false;
    this.isCloseDisabled = false;
    this.isRetryDisabled = false;
    this.showUpdateTotalsFooter(); //FRONT-13994
    if (error.body.message != null) {
      this.errorMessage = error.body.message;
    } else {
      this.errorMessage = "Failed to retrieve Sourcing Branch";
    }
    getRecordNotifyChange([{ recordId: this.recordId }]);
    this.callValueChangeEvent();
  }

  callQuoteThen(result) {
    this.isSuccess = true;
    //START : FRONT-13993,FRONT-13995
    if (this.callingUpdateTotalsFromUpdateReviewTab) {
      const callEvent = new CustomEvent("updatetotalsuccess");
      this.dispatchEvent(callEvent);
    }
    //END : FRONT-13993,FRONT-13995
    this.showSpinner = false;
    this.isCloseDisabled = false;
    getRecordNotifyChange([{ recordId: this.recordId }]);
    //this.isRetryDisabled = true;
    this.message = "Update Totals Success.";
    if (this.appName == "RAE Frontline") {
      //FRONT- 13994
      this.handleCloseClick();
    } else {
      this.callValueChangeEvent();
    }
  }

  callQuoteCatch(error) {
    logger.log(
      "==error in callCatch==",
      error.stack,
      "===",
      JSON.stringify(error)
    );
    this.isError = true;
    this.showSpinner = false;
    this.isCloseDisabled = false;
    this.isRetryDisabled = false;
    this.showUpdateTotalsFooter(); //FRONT- 13994
    if (error.body.message != null) {
      this.errorMessage = error.body.message;
    }
    getRecordNotifyChange([{ recordId: this.recordId }]);
    this.displayErrorMsg(error);
    this.callValueChangeEvent();
  }

  /* FRONT-31379 */
  toggleLoadingModalScreen() {
    const loaderModal = this.refs.loaderModalCmp;
    if (loaderModal) {
      loaderModal.openModal();
      loaderModal.showFooter = false;
    }
  }

  closeLoadingModal() {
    const loaderModal = this.refs.loaderModalCmp;
    if (loaderModal) {
      loaderModal.closeOpenedModal();
      loaderModal.showFooter = false;
    }
  }

  get modalHeader() {
    return "Updating Totals";
  }
  /* FRONT-31379 */
}