import { LightningElement, api,wire } from "lwc";
import { isMobile } from "c/sbr_3_0_dynamicRecordFormUtility"; 
import Sbr_3_0_dynamicFormEditActionDelegatorDesktop from "./sbr_3_0_dynamicFormEditActionDelegatorDesktop.html";
import Sbr_3_0_dynamicFormEditActionDelegatorMobile from "./sbr_3_0_dynamicFormEditActionDelegatorMobile.html";
import QUOTE_RECORD_FORMS from "@salesforce/label/c.SBR_3_0_drfQuoteRecordForms";
import ORDER_RECORD_FORMS from "@salesforce/label/c.SBR_3_0_drfOrderRecordForms";
import CONTRACT_RECORD_FORMS from "@salesforce/label/c.SBR_3_0_drfContOrderRecordForms"; //13084
import { getRecord } from "lightning/uiRecordApi"; //13084
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

import {subscribe,unsubscribe,APPLICATION_SCOPE,MessageContext,} from 'lightning/messageService';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
// End for FRONT-4587
//Added for Front-13084
const OBJNAME_TO_CONFIGMAPPING = {
  Contract: CONTRACT_RECORD_FORMS,
  Order: ORDER_RECORD_FORMS,
  SBQQ__Quote__c: QUOTE_RECORD_FORMS
};

const OBJNAME_TO_LABELMAPPING = {
  Contract: 'Create Contract',
  Order: 'Edit Reservation',
  SBQQ__Quote__c: 'Edit Quote'
};
//Added for Front-13084
const FIELDS = [
  "Order.RecordType.Name"
];
export default class Sbr_3_0_dynamicFormEditActionDelegator extends NavigationMixin(LightningElement) {
  isMobile = isMobile;
  showUpdateTotalsFooter = false;  //FRONT-13994
  @api recordId;
  _objectApiName;
  /*added below line for front-22306*/
  recordTypeName = ''; //13084
  mobileProps = {
    footerClasses: "slds-text-align_center"
  };

  @api get objectApiName() {
    return this._objectApiName;
  }
  set objectApiName(value) {
    this._objectApiName = value;
    this.config = OBJNAME_TO_CONFIGMAPPING[this.objectApiName];

  }

  get screenHeading()
  {
    //13084
    if (this.recordTypeName == 'Create Contract' && this.isMobile) {
      return OBJNAME_TO_LABELMAPPING['Contract'];
    }
    return OBJNAME_TO_LABELMAPPING[this.objectApiName];
  }
  isReadView = true;
  config;


  isEditInProgress;

  UserId = Id;
  isOpenOrderCancelCmp = false;
  props = {};

  //Added for 30809
  isCreateReservation = false;
  isShowDynamicRecordForm = true;
  subscription = null;
  @wire(MessageContext)
  messageContext;


  //Added for 13084
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.recordTypeName = data.recordTypeInfo.name;
      if (this.recordTypeName == 'Create Contract' && this.isMobile) {
        this.config = OBJNAME_TO_CONFIGMAPPING['Contract'];
      }
    } else if (error) {

    }
  }

  connectedCallback() {
    this.isFromOrder = this.objectApiName == 'Order'
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeFromMessageChannel();
  }


  subscribeToMessageChannel() {
    if (this.subscription) {
      return;
    }
    this.subscription = subscribe(
      this.messageContext,
      CLOSE_MODAL,
      (message) => this.handleMessage(message)
    );
  }

  unsubscribeFromMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage(message) {
    if (message.payload.closeModal && message.payload.isPaymentSuccessful) {
      this.navigateToRecord();
    }

  } 

  

  navigateToRecord() {
    if (this.isMobile) {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
          recordId: this.recordId,
          objectApiName: 'Order',
          actionName: 'view'
        }
      });
    }
  }

  hideEditActionDelegator(event) {
    this.isShowDynamicRecordForm = event.detail.hidetemplate;
    this.isCreateReservation = event.detail.isCreateReservation;
  }

  //Ended for 13084
  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = Sbr_3_0_dynamicFormEditActionDelegatorMobile;
      this.buildProps();
    }


    else {
      renderTemplate = Sbr_3_0_dynamicFormEditActionDelegatorDesktop;
    }
    return renderTemplate;
  }

  buildProps() {
    let props = {
      recordId: this.recordId,
    };
    this.props = props;
  }


  handleCloseAction(event) {
    event.stopPropagation();
    let detail = event.detail;
    if (this.isMobile && !detail) {
      this.isReadView = false;
    } else {
      this.dispatchEvent(new CustomEvent("closeauraaction"));
    }
  }

  handleDeleteRecord() {
    this.isOpenOrderCancelCmp = true;
  }

  closeOrderCancelCmp() {
    this.isOpenOrderCancelCmp = false;
  }

  //START FRONT-13994
  handleRetry(event) {
    this.template.querySelector("c-sbr_3_0_dynamic-record-form").handleRetryUpdateTotals();
  }

  handleCloseUpdateTotals(event) {
    this.template.querySelector("c-sbr_3_0_dynamic-record-form").handleCloseUpdateTotals();
  }

  handleHideUpdatetotals(event) {
    this.showUpdateTotalsFooter = false;
    this.template.querySelector("c-sbr_3_0_dynamic-record-form").updateTotalsFooter(false);
  }

  handleUpdateTotalError(event) {
    this.showUpdateTotalsFooter = true;
    this.template.querySelector("c-sbr_3_0_dynamic-record-form").updateTotalsFooter(true);
  }
  //END FRONT-13994
}