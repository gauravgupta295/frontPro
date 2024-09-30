import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  getPicklistValuesByRecordType,
  getObjectInfo
} from "lightning/uiObjectInfoApi";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import CONTACT_FIELDS from "./contactSchema";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import customContactMobileTemplate from "./sbr_3_0_customContactComponentMobile.html";
import customContactDesktopTemplate from "./sbr_3_0_customContactComponentDesktop.html";
import FORM_FACTOR from "@salesforce/client/formFactor";
import Sbr_3_0_address_Css from "@salesforce/resourceUrl/Sbr_3_0_AddressCss"; //FRONT-2620
import Sbr_3_0_customModalCmp_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmp_Css";
import { loadStyle } from "lightning/platformResourceLoader";
import {
  isEmpty,
  isUndefined,
  isUndefinedOrNull
} from "c/sbr_3_0_frontlineUtils";

import { createRecord } from "lightning/uiRecordApi";
const SMALL_FORM_FACTOR = "Small";
//Component created as part of FRONT-1679,FRONT-4582
export default class sbr_3_0_customContactComponent extends LightningElement {
  isModalOpen = false;
  isMobile;
  @api recordId;
  @api accountId;
  countryOptions;
  dlOptions;
  salutationOptions;
  provinceOptions;
  contactStatus;
  preferredMethod;
  roles;
  sal;
  leadSource;
  label = LABELS;
  _countries = [];
  _countryToStates = {};
  @track country = "";
  headerLabel;
  validSoFar = new Map();
  isLoading = false;
  today = new Date().toISOString().slice(0, 10);
  @track contactRecord = {};
  connectedCallback() {
    this.isMobile = FORM_FACTOR === SMALL_FORM_FACTOR;
    if (this.recordId) this.headerLabel = "Edit Contact";
    else this.headerLabel = "New Contact";
  }
  renderedCallback() {
    Promise.all([loadStyle(this, Sbr_3_0_address_Css)])
      .then(() => { })
      .catch((error) => { });
    if (this.isMobile) {
      this.refs.myDiv.scrollIntoView();//11400
    }
  }
  render() {
    if (this.isMobile) {
      loadStyle(this, Sbr_3_0_customModalCmp_Css);
      return customContactMobileTemplate;
    } else {
      return customContactDesktopTemplate;
    }
  }

  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  contactInfo;

  @wire(getPicklistValuesByRecordType, {
    objectApiName: CONTACT_OBJECT,
    recordTypeId: "$contactInfo.data.defaultRecordTypeId"
  })
  contactPicklistValuesWired({ error, data }) {
    if (data) {
      this.buildCountryOptions(data.picklistFieldValues.MailingCountryCode);
      this.buildCountryToStateMap(data.picklistFieldValues.MailingStateCode);
      this.buildDLStateOptions(
        data.picklistFieldValues.Drivers_License_State__c
      );
      this.buildStatus(data.picklistFieldValues.Status__c);
      this.buildPreferredMethod(
        data.picklistFieldValues.Preferred_Contact_Method__c
      );

      this.buildRole(data.picklistFieldValues.Role__c);
      this.buildLeadSource(data.picklistFieldValues.LeadSource);
      this.buildSalutation(data.picklistFieldValues.Salutation);
    } else if (error) {
    }
  }
  buildSalutation(field) {
    this.salutationOptions = field.values;
  }
  buildRole(field) {
    this.roles = field.values;
  }

  buildLeadSource(field) {
    this.leadSource = field.values;
  }
  buildCountryToStateMap(field) {
    const countryValToNumberMap = Object.fromEntries(
      Object.entries(field.controllerValues).map(([key, value]) => [value, key])
    );

    const countryToStates = {};

    for (let state of field.values) {
      const countryIsoCode = countryValToNumberMap[state.validFor[0]];
      if (isUndefined(countryToStates[countryIsoCode])) {
        countryToStates[countryIsoCode] = [];
      }
      countryToStates[countryIsoCode].push(state);
    }
    this._countryToStates = countryToStates;
  }

  buildCountryOptions(field) {
    this.countryOptions = field.values;
  }

  buildDLStateOptions(field) {
    this.dlOptions = field.values;
  }

  buildStatus(field) {
    this.contactStatus = field.values;
  }

  buildPreferredMethod(field) {
    this.preferredMethod = field.values;
  }

  get stateOptions() {
    let country =
      this.contactRecord?.[
        CONTACT_FIELDS.CONTACT_MAILING_COUNTRY_FIELD.fieldApiName
      ];
    return this._countryToStates?.[country] || [];
  }

  handleFieldFocusOut(event) {
    this.validateFieldsOnBlur(event);
  }

  handleCancelClick() {
    const closeEvent = new CustomEvent("closemodal");
    this.dispatchEvent(closeEvent);
  }

  errorLogs = [];
  validateFieldsOnBlur(event) {
    let hasError = false;
    let value = event.target.value;
    if (event.target.name == "FirstName" || event.target.name == "LastName") {
      if (value.trim().length == 0 || !value) {
        event.target.setCustomValidity("Complete this field");
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: "Please complete all the required fields."
        });
        hasError = true;
      }
    } else if (event.target.name == "Phone") {
      const regex = /^\d+$/;
      if (value.trim().length == 0 || !value) {
        event.target.setCustomValidity("Complete this field");
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: "Please complete all the required fields."
        });
        hasError = true;
      } else if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.PHONENUMONLYERR);
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: this.label.PHONENUMONLYERR
        });
        hasError = true;
      } else if (value.length != 10) {
        event.target.setCustomValidity("Please enter a 10 digit Phone Number");
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: "Please enter a 10 digit Phone Number"
        });
        hasError = true;
      }
    } else if (event.target.name === "Email") {
      const regex =
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      if (value.trim().length == 0 || !value) {
        event.target.setCustomValidity("Complete this field");
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: "Please complete all the required fields."
        });
        hasError = true;
      } else if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.EMAILINVALIDFORMATERR);
        this.errorLogs.push({
          fieldName: event.target.name,
          errorMessage: this.label.EMAILINVALIDFORMATERR
        });
        hasError = true;
      }
    }
    if (!hasError && value) {
      event.target.setCustomValidity("");
    }
    this.validSoFar.set(event.target.name, hasError);
    event.target.reportValidity();
    return hasError;
  }

  handleFieldChange(event) {
    let fieldName = event.target.name || event.target.dataset.name;
    this.contactRecord[fieldName] = event.target.value || event.target.checked;
  }

  addressInputChange(event) {
    this.street = event.target.street;
    let hasError = false;
    if (!this.street) {
      event.target.setCustomValidityForField("Complete this field.", "street");
      hasError = true;
    } else {
      event.target.setCustomValidityForField("", "street"); //Reset previously set message
    }
    this.province = event.target.province;
    if (!this.province) {
      hasError = true;
      event.target.setCustomValidityForField(
        "Complete this field.",
        "province"
      );
    } else {
      event.target.setCustomValidityForField("", "province"); //Reset previously set message
    }
    this.city = event.target.city;
    if (!this.city) {
      event.target.setCustomValidityForField("Complete this field.", "city");
      hasError = true;
    } else {
      event.target.setCustomValidityForField("", "city"); //Reset previously set message
    }
    this.postalCode = event.target.postalCode;
    if (!this.postalCode) {
      event.target.setCustomValidityForField(
        "Complete this field.",
        "postalCode"
      );
      hasError = true;
    } else {
      event.target.setCustomValidityForField("", "postalCode"); //Reset previously set message
    }
    this.conCountry = event.target.country;
    if (!this.conCountry) {
      event.target.setCustomValidityForField("Complete this field.", "country");
      hasError = true;
    } else {
      event.target.setCustomValidityForField("", "country"); //Reset previously set message
    }

    if (hasError) {
      event.target.reportValidity();
      this.errorLogs.push({
        fieldName: event.target.name,
        errorMessage: "Mailing Address is required."
      });
    }
    this.setBillingAddress(this.contactRecord, this.getAddress(event));
  }

  getAddress(event) {
    return {
      street: event.target.street,
      province: event.target.province,
      postalCode: event.target.postalCode,
      country: event.target.country,
      city: event.target.city
    };
  }
  setBillingAddress(record, { street, province, postalCode, country, city }) {
    record[CONTACT_FIELDS.CONTACT_MAILING_STREET_FIELD.fieldApiName] = street;
    record[CONTACT_FIELDS.CONTACT_MAILING_STATE_FIELD.fieldApiName] = province;
    record[CONTACT_FIELDS.CONTACT_MAILING_POSTAL_CODE_FIELD.fieldApiName] =
      postalCode;
    record[CONTACT_FIELDS.CONTACT_MAILING_COUNTRY_FIELD.fieldApiName] = country;
    record[CONTACT_FIELDS.CONTACT_MAILING_CITY_FIELD.fieldApiName] = city;
  }

  get dateOfBirthOverFlowMessage() {
    let vartoday = new Date();
    let options = { month: "2-digit", day: "2-digit", year: "numeric" };
    let formattedDate = vartoday.toLocaleDateString("en-US", options);
    console.log(formattedDate);
    return `Date must be ${formattedDate} or earlier.`;
  }

  submitDetails(event) {
    event.preventDefault();
    if (this.isInputValid()) {
      this.contactRecord[CONTACT_FIELDS.CONTACT_ACCOUNT_ID_FIELD.fieldApiName] =
        this.accountId;
      let fields = this.contactRecord;
      const recordInput = { apiName: CONTACT_OBJECT.objectApiName, fields };
      this.createContactRecord(recordInput);
    }
  }

  isInputValid() {
    let isValid = true;
    this.errorLogs = [];
    //let inputFields = this.template.querySelectorAll('.validate');
    this.template.querySelectorAll(".validate").forEach((inputField) => {
      console.log("fieldName" + inputField.name);
      let event = {};
      event.target = inputField;
      if (inputField.name) this.validateFieldsOnBlur(event);
      else this.addressInputChange(event);

      if (this.errorLogs.length > 0) {
        this.showToastMessage(
          "Required Fields Missing.",
          this.errorLogs[0].errorMessage,
          "error",
          "dismissable"
        );
        /*console.log('not valid');
          const evt = new ShowToastEvent({
          title: "Required Fields Missing.",
          message: this.errorLogs[0].errorMessage,
          variant: "error",
          mode: "dismissable"
        });
        this.dispatchEvent(evt);
        */
        isValid = false;
      }
    });
    return isValid;
  }

  createContactRecord(recordInput) {
    this.isLoading = true;
    createRecord(recordInput)
      .then((result) => {
        this.showToastMessage(
          "Success",
          "Contact successfully created.",
          "success",
          "dismissable"
        );
        /*
          const evt = new ShowToastEvent({
            title: "Success",
            message: "Contact successfully created.",
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(evt);
            */

        this.dispatchEvent(
          new CustomEvent("save", {
            detail: result
          })
        );
      })
      .catch((error) => {
        console.log("Error is" + JSON.stringify(error));
        this.showToastMessage(
          "Error",
          JSON.stringify(error.message),
          "error",
          "dismissable"
        );
        /* const evt = new ShowToastEvent({
              title: "Error",
              message: "Error in contact creation.",
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(evt);
            */
        this.isLoading = false;
      });
  }

  showToastMessage(title, message, variant, mode) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
      })
    );
  }
}