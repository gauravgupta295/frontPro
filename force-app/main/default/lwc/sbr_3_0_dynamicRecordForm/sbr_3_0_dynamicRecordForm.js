/* Component Name - Sbr_3_0_dynamicRecordForm
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Component to render record form dynamically on the basis of the Config attribute and Record_Page__mdt metadata
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Komal Dwivedi          12-Oct-2023          Initial version*/

import { LightningElement, api, wire } from "lwc";
import {
  MessageContext,
  publish,
  subscribe,
  unsubscribe
} from "lightning/messageService";
import RecordAction from "@salesforce/messageChannel/RecordAction__c";
import getConfigurations from "@salesforce/apex/SBR_3_0_DynamicRecordFormController.getConfigurations";
import checkRecord from "@salesforce/apex/SBR_3_0_DynamicRecordFormController.checkRecord"; // FRONT - 13994
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { FORM_REGISTRY, FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility";
import { loadStyle } from "lightning/platformResourceLoader";
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import DEFAULT_MOBILE_TEMPLATE from "./mobile/default.html";
import DEFAULT_DESKTOP_TEMPLATE from "./desktop/default.html";

const COL2_LAYOUT = "2 Col";
const SAVE_ACTION = "save";
const SUBMITTED_ACTION = "submitted";
const ERROR_ACTION = "error";
// eslint-disable-next-line no-unused-vars
const REGISTER_ACTION = "register";
const COLLECTOR_POS_REQ_ACTION = "collectorpos_req";
const COLLECTOR_POS_RES_ACTION = "collectorpos_res";
const ALL_LISTENERS = "All";
const HEIGHT_PROP = "height";
const logger = Logger.create(true);

export default class Sbr_3_0_dynamicRecordForm extends LightningElement {
  @api
  config;
  @api
  recordId;
  @api
  objectApiName;
  @api
  showPageLabel = false;

  showUpdateTotals = false;
  appName;
  reviewPanelOpen = false;
  lineItemsPanelOpen = false;
  showReviewToast;
  errMsg = '';
  dynamicForms;
  activeSection = [];
  isMobile = isMobile;
  additionalFields = {};
  @wire(MessageContext)
  messageContext;
  subscription;
  storeInitialized = false;
  errorFields = [];
  isPanelOpen = false;
  mobileProps = {
    variant: "static"
  };
  @wire(getConfigurations, { mappingName: "$config" })
  getConfigurationWired({ error, data }) {
    if (data) {
      this.dynamicForms = JSON.parse(JSON.stringify(data));
      this.buildFieldData();
      //this.generateFormHeightOnLoad();
      this.loadStyleSheet();
      this.error = null;
    } else if (error) {
      logger.error("e", error);
    }
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
    this.addToFormRegistry(this);
    this.getUserAssignedApp();
    this.addPreventDefaultSubmit();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
    this.removeFromFormRegistry();
    this.flushStore();
    this.removePreventDefaultSubmit();
  }

  getUserAssignedApp() {
    getAppName()
      .then((results) => {
        this.appName = results;
      })
      .catch((error) => {
        logger.error(error);
      });
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

  handleMessage(message) {
    logger.log("#### Response Form", message.origin, message.action);
    let action = message.action;
    switch (action) {
      case SAVE_ACTION:
        this.handleSave();
        break;
      case COLLECTOR_POS_RES_ACTION:
        if (
          (message.origin === this.config ||
            message.origin === ALL_LISTENERS) &&
          this._footerTop !== message.params.top
        ) {
          this._footerTop = message.params.top;
          const container = this.template.querySelector(
            ".dynamic-form-container"
          );
          this.calculateHeight(container, this._footerTop);
          this.setFormHeight(this._footerTop);
        }
        break;
      default:
        logger.log("Not a valid action");
    }
  }

  handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();

    let fields = event.detail.fields;

    if (this.additionalFields) {
      fields = { ...fields, ...this.additionalFields };
    }
    publish(
      this.messageContext,
      RecordAction,
      this.buildRecordActionPayload(SUBMITTED_ACTION, {
        fields
      })
    );
  }

  buildFieldData() {
    let fields = [];
    for (let page of this.dynamicForms) {
      for (let section of page.sections) {
        section.fields = section.fields.map((field) => {
          let fieldApiName = `${this.objectApiName}.${field.apiName}`;

          fields.push(fieldApiName);
          return {
            ...field,
            sectionLabel: section.label
          };
        });
      }
    }
  }

  buildRecordActionPayload(action, _params, origin = this.config) {
    let payload = {
      action,
      params: _params,
      origin
    };

    return payload;
  }

  handleSave() {
    try {
      logger.log("inside handle save");
      if (!this.checkValidity()) {
        let fields = this.errorFields;
        logger.log("errorFields" + JSON.stringify(fields));
        publish(
          this.messageContext,
          RecordAction,
          this.buildRecordActionPayload(ERROR_ACTION, {
            fields
          })
        );
      } else {
        this.template.querySelector(".drf_submitBtn")?.click();
      }
    } catch (error) {
      logger.log("error in Sbr_3_0_dynamicRecordForm" + JSON.stringify(error));
    }
  }

  renderedCallback() {
    if ((!this._formHeight && this._footerTop) || this._formHeight) {
      this.setFormHeight(this._footerTop);
    }
  }

  generateFormHeightOnLoad() {
    this.getCachedHeight();
    if (!this._footerTop && !this._formHeight) {
      this.requestFooterPosition();
    } else {
      this.setFormHeight(null);
    }
  }

  setFormHeight(topPos) {
    const container = this.template.querySelector(".dynamic-form-container");
    this.getCachedHeight();
    if (container) {
      if (!this._formHeight) {
        this.calculateHeight(container, topPos);
      }
      this.setHeight(container);
    }
  }

  calculateHeight(container, topPos) {
    if (container) {
      let containerTop = container.getBoundingClientRect().top;
      this._formHeight = topPos - containerTop - 20;
      FORM_REGISTRY.setComponentPropsInRegistry(
        this,
        HEIGHT_PROP,
        this._formHeight
      );
    }
  }

  setHeight(container) {
    container.style.height = `${this._formHeight}px`;
  }

  addToFormRegistry() {
    FORM_REGISTRY.register(this);
  }

  removeFromFormRegistry() {
    FORM_REGISTRY.unregisterAll(this);
  }

  getCachedHeight() {
    let cachedHeight = FORM_REGISTRY.getComponentPropFromRegistry(
      this,
      HEIGHT_PROP
    );
    this._formHeight = cachedHeight;
  }

  requestFooterPosition() {
    let message = this.buildRecordActionPayload(COLLECTOR_POS_REQ_ACTION, {});
    logger.log("#### Requestor Form", message.origin, message.action);
    publish(this.messageContext, RecordAction, message);
  }

  loadStyleSheet() {
    for (let form of this.dynamicForms) {
      if (form.styleSheet) {
        loadStyle(this, form.styleSheet);
      }
    }
  }

  checkValidity() {
    let All_Valid = true;
    let currentScope = this;
    currentScope.errorFields = [];
    this.template
      .querySelectorAll("lightning-input-field[data-required=true]")
      .forEach(function (inputField) {
        if (!inputField.value) {
          All_Valid = false;

          let errorField = {
            fieldName: inputField.dataset.fieldLabel,
            sectionName: inputField.dataset.sectionLabel
          };
          currentScope.errorFields.push(errorField);
        }
      });
    return All_Valid;
  }

  handleFieldValueSet(event) {
    event.stopPropagation();
    let detail = event.detail;
    let fieldName =
      event.target.dataset?.fieldName || detail?.fieldName || event.target.name;
    if (detail) {
      this.additionalFields[fieldName] = detail.value;
    }
  }

  handleCustomFieldChange(event) {
    event.stopPropagation();
    const updatedFields = event.detail;
    const source = event.detail.source || event?.target?.field?.externalId;
    let formElement = this.template.querySelector(
      `c-sbr_3_0_dynamic-record-form-element[data-field-id=${source}]`
    );
    if (updatedFields) {
      for (let field of updatedFields) {
        let fieldNode = this.template.querySelector(
          `lightning-input-field[data-field-name=${field.apiName}]`
        );
        if (fieldNode) {
          fieldNode.value = field.value || null;
          if (field.payload) {
            if (source) {
              if (formElement) {
                formElement.setPayload(field.payload);
              }
            }
          }
          fieldNode.dispatchEvent(new CustomEvent("change"));
        } else {
          this.additionalFields[field.apiName] = field.value;
        }
      }
    }
  }

  handleLoad(event) {
    const formDetail = event.detail;
    this.setRecord(formDetail);
    this.setObjectInfos(formDetail);
    this.setAppName();
    this.storeInitialized = true; // ALWAYS KEEP THIS AT THE END
  }

  setRecord(formDetail) {
    if (formDetail?.records && formDetail.records[this.recordId]) {
      let record = formDetail.records[this.recordId];
      if (!FORM_STORE.records) {
        FORM_STORE.records = {};
      }
      let existingRecord = FORM_STORE.records[this.recordId] || {};
      FORM_STORE.records[this.recordId] = Object.assign(
        {},
        existingRecord,
        record
      );
      if (!FORM_STORE.updatedRecords[this.recordId]) {
        FORM_STORE.updatedRecords[this.recordId] = {};
      }
    }
  }

  setObjectInfos(formDetail) {
    if (formDetail?.objectInfos) {
      if (!FORM_STORE.objectInfos) {
        FORM_STORE.objectInfos = {};
      }
      for (let objectInfo in formDetail.objectInfos) {
        FORM_STORE.objectInfos[objectInfo] = formDetail.objectInfos[objectInfo];
      }
    }
  }

  flushStore() {
    if (FORM_STORE.records[this.recordId]) {
      delete FORM_STORE.records[this.recordId];
    }
  }

  showToastNotification(event) {
    try {
      this.template
        .querySelector("c-sbr_3_0_custom-toast-component")
        .showToast({
          title: event.detail.title,
          message: event.detail.message,
          variant: event.detail.variant,
          mode: event.detail.mode,
          showIcon: event.detail.showIcon,
          classList: event.detail.classList
        });
    } catch (error) {
      console.error("error" + error);
      console.log("error" + JSON.stringify(error));
    }
  }

  hideToastNotification(event) {
    try {
      this.template
        .querySelector("c-sbr_3_0_custom-toast-component")
        .hideToast();
    } catch (error) {
      console.error("error" + error);
      console.log("error" + JSON.stringify(error));
    }
  }

  addPreventDefaultSubmit() {
    this.template.addEventListener("click", this.clickListenerCallback);
    this.template.addEventListener("keydown", this.clickListenerCallback);

    // document.addEventListener("click", this.clickListenerCallback);
  }

  removePreventDefaultSubmit() {
    this.template.removeEventListener("click", this.clickListenerCallback);
    this.template.addEventListener("keydown", this.clickListenerCallback);
    // document.removeEventListener("click", this.clickListenerCallback);
  }

  clickListenerCallback(event) {
    event.stopPropagation();
    if (event.keyCode === 13) {
      event.preventDefault();
    }
  }

  render() {
    return this.isMobile ? DEFAULT_MOBILE_TEMPLATE : DEFAULT_DESKTOP_TEMPLATE;
  }

  handleTogglePanel(event) {
    event.stopPropagation();
    let targetPanelId = event.target.dataset.targetPanelId;
    //START FRONT-13994
    this.showUpdateTotals = false;
    if (targetPanelId) {
      if((targetPanelId == 'Quote_Quote_Review_Tab' || targetPanelId =='Order_Review_Tab_Mobile') && this.appName == "RAE Frontline") {
        this.reviewPanelOpen = !this.reviewPanelOpen;
        if (this.reviewPanelOpen) {
          this.callUpdateTotals();
        } else {
          let hideUpdateTotalsEvent = new CustomEvent("hideupdatetotals", {
            detail: {
              showUpdateTotals: false
            }
          });
          this.dispatchEvent(hideUpdateTotalsEvent);
        }
      }
      if((targetPanelId == 'Quote_LineItem_Tab' || targetPanelId =='Order_LineItem_Tab') && this.appName == "RAE Frontline") {
        this.lineItemsPanelOpen = !this.lineItemsPanelOpen;
        if(this.lineItemsPanelOpen && targetPanelId == 'Quote_LineItem_Tab'){
          this.checkQuoteOrderRecord();
        } else if(this.lineItemsPanelOpen && targetPanelId == 'Order_LineItem_Tab') {
          this.checkQuoteOrderRecord();
        }
      }
      //END FRONT-13994
      let targetPanel = this.template.querySelector(
        `div[data-panel-id="${targetPanelId}"]`
      );
      let tabList = this.template.querySelector(".tab-list");
      let mobileScreen = this.template.querySelector(
        `c-sbr_3_0_mobile-screen[data-panel-id="${targetPanelId}"]`
      );
      if (targetPanel) {
        this.isPanelOpen = !this.isPanelOpen;
        targetPanel.classList.toggle("slds-hide");
        targetPanel.classList.toggle("slds-is-open");
        if (this.isPanelOpen) {
          targetPanel.removeAttribute("hidden");
        } else {
          targetPanel.setAttribute("hidden", "");
        }
        if (tabList) {
          tabList.classList.toggle("slds-hide");
        }
        if (mobileScreen) {
          mobileScreen.toggleScreen({
            hidePreviousTitle: true,
            hidePreviousFooter: false
          });
        }
      }
    }
  }

  //START FRONT-13994
  callUpdateTotals() {
    if(this.objectApiName == 'SBQQ__Quote__c' || this.objectApiName == 'Order') {
      checkRecord({ objectName: this.objectApiName, recordId: this.recordId })
        .then(result => {
          this.showUpdateTotals = result;
          let updateTotalsEvent = new CustomEvent("updatetotals", {
            detail: {
              showUpdateTotals: this.showUpdateTotals
            }
          });
          this.dispatchEvent(updateTotalsEvent);
        })
        .catch(error => {
            console.error('Error in update totals', error);
        });
    }
  }

  checkQuoteOrderRecord() {
    if(this.objectApiName == 'SBQQ__Quote__c') {
      this.errMsg = 'You have updated the Quote, please click on the Quote Review tab to confirm before submitting the Quote';
    } else if(this.objectApiName == 'Order') {
      this.errMsg = 'You have updated the Order, please click on the Order Review tab to confirm before submitting the Order';
    }
    checkRecord({ objectName: this.objectApiName, recordId: this.recordId })
    .then(result => {
        this.showReviewToast = result;
        if (this.showReviewToast == true) {
          let obj = {
            "detail" : {
            "title" : "",
            "message" : this.errMsg,
            "variant" : "info",
            "mode" : "sticky"
            }
            }
          this.showToastNotification(obj);
        }
      })
    .catch(error => {
      console.error('Error in Show Toast', error);
      });
  }

  handleClose() {
    this.showUpdateTotals = false;
  }

  @api
  handleRetryUpdateTotals() {
    this.template.querySelector("c-sbr_3_0_update-totals").handleRetryClick();
  }

  @api
  handleCloseUpdateTotals() {
    this.template.querySelector("c-sbr_3_0_update-totals").handleCloseClick();
  }

  @api updateTotalsFooter(footerVal) {
    this.showUpdateTotals = footerVal;
  }

  handleErrorUpdateTotals() {
    let updateTotalsErrorEvent = new CustomEvent("updatetotalerror", {
      detail: {}
    });
    this.dispatchEvent(updateTotalsErrorEvent);
  }

  //START FRONT-13994

  setAppName() {
    FORM_STORE.appName = this.appName;
  }
}