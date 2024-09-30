import { LightningElement } from "lwc";
import {
  isMobile,
  DynamicRecordFormMixin
} from "c/sbr_3_0_dynamicRecordFormUtility";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { TYPE, FIELD_EXECUTOR } from "./types";
export default class Sbr_3_0_drfInputComponent extends DynamicRecordFormMixin(
  LightningElement
) {
  type = TYPE.text;
  attributes;
  inputCmp = true;
  _fieldValue;
  get fieldValue() {
    return this._fieldValue;
  }

  set fieldValue(value) {
    this._fieldValue = value;
    //this.runExecutors();
  }

  connectedCallback() {
    this.fieldValue =
      FORM_STORE?.records[this.recordId]?.fields?.[this.field.apiName]?.value;

    this.registerListeners(this.handleMessage);
  }

  renderedCallback() {
    //if (!this._attributesSet) {
      this.setInputAttributes();
    //}
  }

  setInputAttributes() {
    let attributes = this.field.attributes
      ? structuredClone(this.field.attributes)
      : null;
    if (attributes) {
      this.attributes = attributes;
      if (this.inputElement) {
        this.applyAttributes();
        this.runExecutors();
        this._attributesSet = true;
      }
    }
  }

  applyAttributes() {
    const inputField = this.inputElement;
    for (let attribute in this.attributes) {
      inputField.setAttribute(attribute, this.attributes[attribute]);
    }
    if(isMobile && this.field.isReadOnly){
      this.inputElement.classList.add("greyBorderCon"); //apply grey color in input tag for mobile
    }
  }

  runExecutors() {
    let fieldType = TYPE[this.attributes?.type];
    let executors =
      fieldType && FIELD_EXECUTOR[fieldType]?.executors?.length > 0
        ? FIELD_EXECUTOR[fieldType].executors
        : [];
    for (let executor of executors) {
      executor.call(this);
    }
  }

  handleMessage(message) {
    try {
      let field = this.getMessagePayload(message);
      if (field && field.apiName === this.field.apiName) {
        this.fieldValue = field.value;
      }
    } catch (e) {
      console.error(e);
    }
  }

  get inputElement() {
    return this.template.querySelector(
      `lightning-input[data-field-name=${this.field.apiName}]`
    );
  }
}