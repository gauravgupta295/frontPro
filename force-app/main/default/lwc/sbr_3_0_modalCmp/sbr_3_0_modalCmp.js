/* eslint-disable @lwc/lwc/no-leading-uppercase-api-name */
/* eslint-disable eqeqeq */
/* eslint-disable @lwc/lwc/valid-api */
/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api } from "lwc";
const OUTER_MODAL_CLASS = "outerModalContent";
const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = "Escape";
const BUTTON_GREY_CSS_CLASS = "buttonGreyBoundary"; //FRONT-9276 : Grey Button CSS Class

export default class Sbr_3_0_modalCmp extends LightningElement {
  isOpen = false;
  @api header = "Modal Header";
  @api cancelBtnLabel = "Cancel";
  @api saveBtnLabel = "Save";
  @api backBtnLabel = "Back"; //Added as part of FRONT-2195
  @api variant = "base";
  @api cancelHandler;
  @api saveHandler;
  @api backBtnHandler; //Added as part of FRONT-2195
  @api isOrder = false;
  @api selectItem;
  @api closeBtnHandler;
  isSaveBtnDisabled = false;
  @api disbaleConfirmButton = false; //Added as part of 2195
  _showFooter = true;
  addedClass;
  @api type = "static";
  @api props;
  @api isDynamicFooter = false; //Added as part of FRONT-10855

  @api
  toggleModal() {
    this.isOpen = !this.isOpen;
    //let the outermost component know if modal is open to toggle aria-hidden attribute for accessibility
    //think about adding focus to first focusable element in modal if modal is open
    // if (this.isOrder) {
    const goBackEvent = new CustomEvent("returnpage", {});
    this.dispatchEvent(goBackEvent);
    //  }
  }

  @api
  closeModal(evt) {
    // Started for FRONT-6268
    if (evt.target.value) {
      const cancelEvent = new CustomEvent("cancelbutton", {});
      this.dispatchEvent(cancelEvent);
    }
    //Ended for FRONT-6268
    if (evt.target.value == "Back" && this.isOpen == true) {
      const goBackEvent = new CustomEvent("returnpage", {});
      this.dispatchEvent(goBackEvent);
    } else {
      this.isOpen = !this.isOpen;
    }
  }

  get modalClass() {
    const baseClass = "slds-modal " + OUTER_MODAL_CLASS + " ";
    return (
      baseClass + (this.isOpen ? "slds-show slds-fade-in-open" : "slds-hide")
    );
  }

  get containerClass() {
    const baseClass = "slds-modal__container outerModalContent ";

    if (this.variant === "wide") {
      this.addedClass = "wide-modal";
    } else if (this.variant === "large") {
      this.addedClass = "large-modal";
    } else if (this.variant === "fitLarge") {
      this.addedClass = "fit-large-modal";
    } else {
      this.addedClass = "";
    }
    //return baseClass + (this.variant === "wide" ? "wide-modal" : (this.variant === "large" ? "large-modal" : ""));//Modified as part of FRONT-2195
    return baseClass + this.addedClass;
  }

  get modalAriaHidden() {
    return !this.isOpen;
  }

  handleModalFocus() {}

  handleKeyPress(event) {
    if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
      this.toggleModal();
    }
  }

  get hasSaveHandler() {
    return this.saveHandler ? true : false;
  }

  @api
  disableSaveBtn() {
    this.isSaveBtnDisabled = true;
  }

  @api
  enableSaveBtn() {
    this.isSaveBtnDisabled = false;
  }

  //Added as part of FRONT-2195
  get hasBackButtonHandler() {
    return this.backBtnHandler ? true : false;
  }

  get disableSaveButton() {
    return this.props
      ? this.props.isDisable
      : this.saveBtnLabel === "Confirm"
        ? this.disbaleConfirmButton
        : false;
  }

  get saveButtonClass() {
    if (this.props?.isDisable) {
      return "slds-button slds-button_brand";
    }
    return !this.disbaleConfirmButton
      ? "slds-button slds-button_brand save-btn"
      : " slds-button slds-button_brand";
  }

  @api get showFooter() {
    return this._showFooter;
  }

  set showFooter(value) {
    this._showFooter = value;
  }

  get cancelClickHandler() {
    if (this.cancelHandler) {
      return this.cancelHandler;
    }
    return this.closeModal;
  }

  //FRONT-2195 Ends
  /*FRONT - 9276 : Methods to add Grey Boundary CSS Class for buttons */
  @api addGreyColourBoundaryToCancelButton() {
    let cancelBtn = this.template.querySelector(".cancel-btn");
    this.addCSSClassOnComp(cancelBtn, BUTTON_GREY_CSS_CLASS);
  }

  @api addGreyColourBoundaryToBackButton() {
    if (this.hasBackButtonHandler) {
      let backBtn = this.template.querySelector(".back-btn");
      this.addCSSClassOnComp(backBtn, BUTTON_GREY_CSS_CLASS);
    }
  }

  addCSSClassOnComp(comp, classToAdd) {
    comp?.classList?.add(classToAdd);
  }
  /* END : FRONT - 9276 */

  //FRONT-26714: to separate close Icon click for closing the modal and toggleModal method
  get closeBtnClickHandler() {
    if (this.closeBtnHandler) {
      return this.closeBtnHandler;
    }
    return this.toggleModal;
  }

  get isDynamicOpen() {
    return this.type === "dynamic" && this.isOpen;
  }

  _uuid;
  @api
  get uuid() {
    return this._uuid;
  }

  set uuid(value) {
    this._uuid = value;
  }

  connectedCallback() {
    this.generateUUID();
  }

  generateUUID() {
    if (!this.uuid) {
      this._uuid = crypto.randomUUID();
    }
  }

  /*FRONT-31379 : methods to directly open/close the modal without intervention */
  @api
  openModal() {
    this.isOpen = true;
  }

  @api
  closeOpenedModal() {
    this.isOpen = false;
  }
  /*END : FRONT-31379 */
}