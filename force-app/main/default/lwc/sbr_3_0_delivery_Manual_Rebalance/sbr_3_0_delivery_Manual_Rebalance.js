import { LightningElement, track, api } from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import DESKTOP_TEMPLATE from "./sbr_3_0_deliveryManualRebalanceDesktop/sbr_3_0_delivery_Manual_RebalanceDesktop.html";
import MOBILE_TEMPLATE from "./sbr_3_0_deliveryManualRebalanceMobile/sbr_3_0_delivery_Manual_RebalanceMobile.html";
import WARNING_DESKTOP_TEMPLATE from "./sbr_3_0_deliveryManualRebalanceDesktop/sbr_3_0_deliveryManualRebalanceWarning.html";
import WARNING_MOBILE_TEMPLATE from "./sbr_3_0_deliveryManualRebalanceMobile/sbr_3_0_deliveryManualRebalanceWarning.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import sbr_3_0_customDataTableCSS from "@salesforce/resourceUrl/sbr_3_0_customDataTable_css";
import { loadStyle } from "lightning/platformResourceLoader";
/*Start:Story#FRONT-8094: Added by Gopal Raj*/
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import isOrderItemNotBulk from "@salesforce/apex/SBR_3_0_Delivery_Manual_Rebal_Controller.isOrderItemNotBulk";
import nullifyAssetRecord from "@salesforce/apex/SBR_3_0_Delivery_Manual_Rebal_Controller.nullifyAssetRecord";

/*End:Story#FRONT-8094: Added by Gopal Raj*/

export default class Sbr_3_0_delivery_Manual_Rebalance extends LightningElement {
  isDisabled = true;
  isPreviousId;
  @track isMobile = false;
  @api orderRecordDetails;
  @api orderRecordId; //Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj
  label = LABELS;
  selectedClass = "slds-button slds-button_neutral active-state";
  unselectedClass = "slds-button slds-button_neutral selected-btn";
  defaultLocationBtnClass = "slds-button slds-button_neutral active-state";
  otherLocationBtnClass = "slds-button slds-button_neutral selected-btn";
  activeTab = "default-location";
  detailsCmpId = "";
  fulfillmentPercentage = "";
  /*Start:Story#FRONT-8094: Added by Gopal Raj*/
  isShowModal = false;
  value = "call_toast";
  selectedRows = [];
  /*End:Story#FRONT-8094: Added by Gopal Raj*/
  locationNumber;
  catClassList;
  catClassRequestedQtyMap;

  @track _tabs = [
    {
      title: LABELS.DEFAULTLOCATION,
      Content: "DefaultLocation",
      Id: "1",
      contentClass: "slds-tabs_default__content slds-show",
      itemClass: "slds-tabs_default__item slds-is-active selected-tab",
      isDefaultLocationSelected: true
    },
    {
      title: LABELS.OTHERLOCATION,
      Content: "OtherLocation",
      Id: "2",
      contentClass: "slds-tabs_default__content slds-hide",
      itemClass: "slds-tabs_default__item",
      isOtherLocationSelected: false
    }
  ];
  @track mobiletabs = [
    {
      title: LABELS.DEFAULTLOCATION,
      Content: "DefaultLocation",
      Id: "1",
      contentClass: "slds-tabs_default__content slds-show",
      itemClass: "slds-button slds-button_neutral active-state",
      isDefaultLocationSelected: true
    },
    {
      title: LABELS.OTHERLOCATION,
      Content: "OtherLocation",
      Id: "2",
      contentClass: "slds-tabs_default__content slds-hide",
      itemClass: "slds-button slds-button_neutral selected-btn",
      isOtherLocationSelected: false
    }
  ];
  @track displayAssetAssignedWarning = true;

  get Tabs() {
    return this._tabs;
  }
  toggleProdInqMobile(e) {
    let currentState = e.target.value;
    this.defaultLocationBtnClass = this.unselectedClass;
    this.otherLocationBtnClass = this.unselectedClass;
    switch (currentState) {
      case "Default Locations":
        this.defaultLocationBtnClass = this.selectedClass;
        this.activeTab = "default-location";
        this.handleClick(e);
        break;
      case "Other Locations":
        this.otherLocationBtnClass = this.selectedClass;
        this.activeTab = "other-location";
        this.handleClick(e);
        break;
      default:
        break;
    }
  }
  connectedCallback() {
    this.isMobile = FORM_FACTOR === "Small";
  }
  handleClick(event) {
    //when you click tabs, hide fulfillment component
    this.detailsCmpId = "";
    this._tabs = this.mobiletabs = this.Tabs.map((tab) => {
      let value = `is${tab.Content}Selected`;
      if (tab.Id === event.target.dataset.link) {
        if (tab.Id !== this.isPreviousId) {
          this.isDisabled = true;
        }
        tab.contentClass = "slds-tabs_default__content slds-show";
        tab.itemClass = "slds-tabs_default__item slds-is-active selected-tab";
        if (this.isMobile) {
          tab.itemClass = "slds-button slds-button_neutral active-state";
        }
        tab[value] = true;
        this.isPreviousId = tab.Id;
      } else {
        tab.contentClass = "slds-tabs_default__content slds-hide";
        tab.itemClass = "slds-tabs_default__item";
        if (this.isMobile) {
          tab.itemClass = "slds-button slds-button_neutral selected-btn";
        }
        tab[value] = false;
      }

      return tab;
    });
  }

  /*Start:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/

  submitDetails() {
    this.disableConfirmButton();
    this.handleConfirm();
  }

  closeModal() {
    let payload = { eventType: "Close" };
    this.sendEvent(payload);
    this.isDisabled = true;
  }

  handlepopupEvent(event) {
    if (event.detail.eventType === "GoBack") {
      this.showSourcePopup();
      this.hideModalBox();
      this.enableConfirmButton();
    } else if (event.detail.eventType === "confirm") {
      this.value = event.detail.selectedvalue;
      this.confirmModalBox();
    }
  }

  confirmModalBox() {
    if (this.value === "call_server") {
      this.invokeServerCall();
    } else {
      this.confirmSuccessModal();
    }
  }

  handleConfirm() {
    isOrderItemNotBulk({ orderId: this.orderRecordId })
      .then((result) => {
        if (result === true) {
          this.showModalBox();
          this.hideSourcePopup();
        } else {
          this.confirmSuccessModal();
        }
      })
      .catch((error) => {
        console.error("Error at isOrderItemNotBulk method:" + error.message);
      });
  }

  invokeServerCall() {
    nullifyAssetRecord({
      orderId: this.orderRecordId,
      sourceBranchId: this.selectedRows[0].id
    })
      .then((result) => {
        if (result === "success") {
          this.confirmPopupEvent();
          this.showSuccessToast();
        } else {
          this.showErrorToast();
        }
      })
      .catch((error) => {
        this.showErrorToast();
      });
  }

  confirmSuccessModal() {
    let payload = {
      eventType: "confirmsuccess",
      selectrowid: this.selectedRows[0].id,
      selectedRow: this.selectedRows[0]
    };
    this.sendEvent(payload);
  }

  confirmPopupEvent() {
    let payload = {
      eventType: "confirmpopup",
      selectrowid: this.selectedRows[0].id
    };
    this.sendEvent(payload);
  }

  hideSourcePopup() {
    if (this.isMobile !== true) {
      let container = this.template.querySelector(".slds-modal");
      console.log("container>> " + container);
      container.classList.remove("slds-fade-in-open");
    }
  }

  showSourcePopup() {
    if (this.isMobile !== true) {
      let container = this.template.querySelector(".slds-modal");
      console.log("container>> " + container);
      container.classList.add("slds-fade-in-open");
    }
  }

  showModalBox() {
    this.isShowModal = true;
  }

  hideModalBox() {
    this.isShowModal = false;
  }

  enableConfirmButton() {
    this.isDisabled = false;
  }

  disableConfirmButton() {
    this.isDisabled = true;
  }

  sendEvent(payload) {
    const notifyEvent = new CustomEvent("notifyevent", {
      detail: payload
    });
    this.dispatchEvent(notifyEvent);
  }

  showSuccessToast() {
    const toastEvent = new ShowToastEvent({
      title: "Success!",
      message: "The new sourcing branch has been added to this reservation.",
      variant: "success"
    });

    this.dispatchEvent(toastEvent);
  }

  showErrorToast() {
    const toastEvent = new ShowToastEvent({
      title: "Error!",
      message: "An error occurred while trying to nullify asset value.",
      variant: "error"
    });

    this.dispatchEvent(toastEvent);
  }

  /*End:Story#FRONT-8094,FRONT-8747: Modified by Gopal Raj*/

  openRebalanceScreen() {
    this.displayAssetAssignedWarning = false;
  }

  changeOnConfirm(event) {
    if (event.detail.eventType === "enableConfirm") {
      this.isDisabled = false;
      this.selectedRows = event.detail.selectedRows; //Story#FRONT-8094,FRONT-8747: Added by Gopal Raj
    }
    if (event.detail.eventType === "disableConfirm") {
      this.isDisabled = true;
    }
  }

  showDetailsComponent(event) {
    this.detailsCmpId = event.detail.fulfillmentId;
    this.fulfillmentPercentage = event.detail.fulfillmentPercentage;
    this.locationNumber = event.detail.locationId;
    this.catClassList = event.detail.catClassList;
    this.catClassRequestedQtyMap = event.detail.catClassRequestedQtyMap;
  }

  openSourceBranchTable() {
    this.detailsCmpId = "";
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      /*if (
        this.orderRecordDetails.hasOrderItemAssetAssigned &&
        this.displayAssetAssignedWarning
      )
        renderTemplate = WARNING_MOBILE_TEMPLATE;
      else */ renderTemplate = MOBILE_TEMPLATE;
    } else {
      loadStyle(this, sbr_3_0_customDataTableCSS);
      /*if (
        // this.orderRecordDetails.hasOrderItemAssetAssigned &&
        this.displayAssetAssignedWarning
      )
        renderTemplate = WARNING_DESKTOP_TEMPLATE;
      else*/ renderTemplate = DESKTOP_TEMPLATE;
    }
    return renderTemplate;
  }
}