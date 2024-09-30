import { LightningElement, api, wire } from "lwc";
import {
  isMobile,
  DynamicRecordFormMixin
} from "c/sbr_3_0_dynamicRecordFormUtility";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { isArray } from "c/sbr_3_0_frontlineUtils"; // 13084
const INPUT_FIELD_TYPE = "Input Field";
const OUTPUT_FIELD_TYPE = "Output Field";
const CUSTOM_COMP_TYPE = "Custom Comp";
export default class Sbr_3_0_dynamicRecordFormElement extends DynamicRecordFormMixin(
  LightningElement
) {
  static renderMode = "light"; // the default is 'shadow'
  @api record;
  @api recordId;
  @api objectApiName;
  allowEventDispatch = false;
  componentConstructor;
  payload;
  hasValue = false;
  isMobile = isMobile; // 13084

  connectedCallback() {
    if (this.field.listenTo && !this.isCustomComp) {
      this.registerListeners(this.handleMessage);
    }

    if (this.isCustomComp && this.field.customCompName) {
      this.importCustomComponent();
    }
  }

  //added for Front-10499
  get showCustomLabel() {
    return this.field.showCustomLabel;
  }

  //added for Front-10499
  get variantType() {
    return this.field.showCustomLabel ? "label-hidden" : "label-stacked";
  }

  get isInputField() {
    return this.field?.type === INPUT_FIELD_TYPE;
  }

  get isOutputField() {
    return this.field?.type === OUTPUT_FIELD_TYPE;
  }

  get isCustomComp() {
    return this.field?.type === CUSTOM_COMP_TYPE;
  }

  get computedInputFieldClasses() {
    let inputclasses = `input-field-element ${this.computedFormFactorClasses} ${this.field.externalId}`;
    if (this.isCustomComp) {
      inputclasses += " slds-hide";
    }
    if (this.isHelpText) {
      inputclasses += this.computeHideStandardHelpTextClasses;
    }
    return inputclasses;
  }

  get computedOutPutFieldClasses() {
    //Added for Front-13084
    let outputClasses = "";
    if (this.isHelpText) {
      outputClasses += this.computeHideStandardHelpTextClasses;
    }
    return (
      `output-field-element ${this.computedFormFactorClasses} ${this.field.externalId}` +
      " outputLinkClass" +
      outputClasses
    );
  }

  get computedCustomCompClasses() {
    return `custom-comp-element ${this.computedFormFactorClasses} ${this.field.externalId}`;
  }

  get computedFormFactorClasses() {
    return `${isMobile ? "mobile" : "desktop"}`;
  }

  get fieldClasses() {
    return `${
      this.isInputField
        ? "input-field-element"
        : this.isOutputField
          ? "output-field-element"
          : "custom-comp-element slds-hide"
    } ${isMobile ? "mobile" : "desktop"} ${this.field.externalId}`;
  }

  get showInputField() {
    return this.isInputField || this.isCustomComp;
  }

  disconnectedCallback() {
    this.unregisterAllListeners();
  }

  handleMessage(message, eventName) {
    console.log(
      `${JSON.stringify(message)} event name ${eventName} Listened By ${
        this.field.externalId
      }`
    );
    let payload = message.detail || message;
    let field = isArray(payload)
      ? payload.filter(
          (payloadField) => payloadField.apiName === this.field.apiName
        )
      : payload;
    if (field && field.length > 0 && this.isInputField) {
      let fieldDetail = field[0];
      let fieldNode = this.querySelector(
        `lightning-input-field[data-field-name=${fieldDetail.apiName}]`
      );
      if (fieldNode) {
        fieldNode.value = fieldDetail.value || null;
        fieldNode.dispatchEvent(new CustomEvent("change"));
      }
    }
  }

  handleFieldChange(event) {
    //check required
    // if null --> checkvalidattiy
    try {
      this.hasValue = event?.target?.value;
      const inputElement = this.querySelector(
        `lightning-input-field[data-required='true']`
      );
      const fieldValue = inputElement?.value;
      if (inputElement && !fieldValue) {
        inputElement.setErrors({
          body: {
            output: {
              fieldErrors: {
                [this.field.apiName]: [{ message: "Complete this field." }]
              }
            }
          }
        });
      } else if (inputElement) {
        inputElement.setErrors("");
      }
      this.publishChange(this.field.externalId, this.getPayload(event));
    } catch (e) {
      console.log("error" + e);
    }
  }

  async importCustomComponent() {
    const componentName = `c/${this.field.customCompName}`;
    try {
      const { default: componentConstructor } = await import(componentName);
      this.componentConstructor = componentConstructor;
    } catch (e) {
      console.error(e);
    }
  }

  @api
  setPayload(payload) {
    this.payload =
      typeof payload === "string"
        ? payload
        : JSON.parse(JSON.stringify(payload));
  }

  getPayload(event) {
    let returnedPayload = {
      apiName: this.field.apiName,
      value: event.target.value
    };

    if (this.payload) {
      returnedPayload.payload = this.payload;
    }

    // This is used in lineItemEditorFrontLineCmp
    //FRONT-20093,20094 Starts
    if (!FORM_STORE.updatedRecords[this.recordId]) {
      FORM_STORE.updatedRecords[this.recordId] = {};
    }
    FORM_STORE.updatedRecords[this.recordId][this.field.apiName] =
      event.target.value;
    //FRONT-20093,20094 Ends
    return returnedPayload;
  }
  //Added for Front-13084
  get inputPlaceHolderClasses() {
    return this.hasValue ? "slds-hide" : "input-placeholder";
  }

  get isHelpText() {
    return this.field.helpText ? true : false;
  }

  get computeHideStandardHelpTextClasses() {
    return this.isHelpText ? " helpTextHideClass" : "";
  }

  get computedOuputFieldContainerClasses() {
    return this.showCustomLabel
      ? "slds-p-left_xx-small slds-m-bottom_x-small"
      : "";
  }
}