import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import ACCOUNTTYPE_FIELD from "@salesforce/schema/Account.RecordTypeId";
import EMAIL from "@salesforce/schema/Account.E_mail_Address__c";
import getRecordTypeInfo from "@salesforce/apex/SBR_3_0_CustomLookupController.getRecordTypeInfo";
import DRIVERS_LICENSE from "@salesforce/schema/Account.Drivers_License__c";
import DRIVERS_LICENSE_STATE from "@salesforce/schema/Account.Driver_s_License_State__c";
//import ADDITIONAL_COMMENTS from '@salesforce/schema/Account.Additional_Comment__c';
import { createRecord } from "lightning/uiRecordApi";
import POSTAL_CODE from "@salesforce/schema/Account.BillingPostalCode";
import CITY from "@salesforce/schema/Account.BillingCity";
import COUNTRY from "@salesforce/schema/Account.BillingCountry";
import PROVINCE from "@salesforce/schema/Account.BillingState";
import BILLING_STREET from "@salesforce/schema/Account.BillingStreet";
import COUNTRY_CODE from "@salesforce/schema/Account.BillingCountryCode";
import STATE_CODE from "@salesforce/schema/Account.BillingStateCode";
import STATUS from "@salesforce/schema/Account.Status__c"; //Added as part of FRONT-7308
import state_code_prospect from "@salesforce/schema/Account.ShippingStateCode";
import COUNTRY_CODE_PROSPECT from "@salesforce/schema/Account.ShippingCountryCode";
import BIRTH_DATE from "@salesforce/schema/Account.BirthDate__c";
import DESCRIPTION from "@salesforce/schema/Account.Comments__c";
import SHIPPING_STREET from "@salesforce/schema/Account.ShippingStreet";
import SHIPPING_CITY from "@salesforce/schema/Account.ShippingCity";
import SHIPPING_ZIP from "@salesforce/schema/Account.ShippingPostalCode";
import PARENT_ID from "@salesforce/schema/Account.ParentId"; //Added as part of bugfix FRONT-17224
import BYPASS_DUPLICATE_RULES_FIELD from "@salesforce/schema/Account.Bypass_Duplicate_Rules__c";
import { appName, FL_APP_NAME } from "c/sbr_3_0_frontlineUtils";

import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import createSObject from "@salesforce/apex/SBR_3_0_DMLOpsController.createSObject";
import updateSObject from "@salesforce/apex/SBR_3_0_DMLOpsController.updateSObject";

//Added as part of FRONT-1270
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import CONTACT_FIRST_NAME from "@salesforce/schema/Contact.FirstName";
import CONTACT_LAST_NAME from "@salesforce/schema/Contact.LastName";
import CONTACT_ACCOUNT_ID from "@salesforce/schema/Contact.AccountId";
import CONTACT_EMAIL from "@salesforce/schema/Contact.Email";
import CONTACT_MAILING_CITY from "@salesforce/schema/Contact.MailingCity";
import CONTACT_MAILING_STATE from "@salesforce/schema/Contact.MailingState";
import CONTACT_MAILING_STREET from "@salesforce/schema/Contact.MailingStreet";
import CONTACT_MAILING_POSTAL_CODE from "@salesforce/schema/Contact.MailingPostalCode";
import CONTACT_MAILING_COUNTRY from "@salesforce/schema/Contact.MailingCountry";
import CONTACT_PHONE_NUMBER from "@salesforce/schema/Contact.Phone";
import CONTACT_DL_NUMBER from "@salesforce/schema/Contact.Drivers_License__c";
import CONTACT_DL_STATE from "@salesforce/schema/Contact.Drivers_License_State__c";
import CONTACT_PRIMARY from "@salesforce/schema/Contact.Primary_Contact__c";
import mobileTemplate from "./sbr_3_0_customModalCmpMobile.html";
import desktopTemplate from "./sbr_3_0_customModalCmp.html";

import DL_STATES from "@salesforce/schema/Account.Driver_s_License_State__c";
//Added as part of FRONT-1616
//Custom labels
import LABELS from "c/sbr_3_0_customLabelsCmp";
import { loadStyle } from "lightning/platformResourceLoader";
import Sbr_3_0_customModalCmp_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmp_Css";
import Sbr_3_0_customModalCmpDesktop_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmpDesktop_Css";

import {
  isEmpty,
  isUndefined,
  isUndefinedOrNull
} from "c/sbr_3_0_frontlineUtils";
import modalCss from "@salesforce/resourceUrl/sbr_3_0_customModalCss"; //FRONT-6234

//const fieldsForForm =[NAME_FIELD,PHONE_FIELD,Country_field,State_field,City_field,Street_field,Postal_code_field,Email_field]
const NON_CREDIT_RECORD_TYPE_NAME = "Non-Credit";
const PROSPECT_RECORD_TYPE_NAME = "Prospect";
const ERROR_STACK = ["badInput", "valueMissing"];
const NEW_ACTION_OVERRIDE = "NewActionOverride";
const STANDARD_RECORD_PAGE_PAGEREFERENCE = "standard__recordPage";
const VIEW_ACTION = "view";
const CANCEL_ACTION = "cancel";
const logger = Logger.create(true);
// FRONT-2996 ,3449 Starts
const DUPLICATE_ERROR_CODE = "DUPLICATES_DETECTED";
const NEW_RESOLUTION = "new";
const EXISTING_RESOLUTION = "existing";
const RESERVATION_ORDER_ORIGIN = "orderrequireCustomLookup";
const QUOTE_ORIGIN = "quoterequireCustomLookup";
// FRONT-2996,3449 Ends
//FRONT-3543
const CLASS_1 = "class1";
const BILLING_ADDRESS = "BillingAddress";
const SHIPPING_ADDRESS = "ShippingAddress";
const NEW_SCREEN = "NewScreen";
const ACTIVE_STATUS = "Active"; //Added as part of FRONT-7308
// FRONT-3545 End
export default class Sbr_3_0_customModalCmp extends LightningElement {
  @api errorMsg = "";
  @api errorTitle = "";
  @api successTitle = "";
  @api successMsg = "";
  @api parentcmp;
  @api fromaccountpg;
  _recordType;
  @api get recordtype() {
    return this._recordType;
  }

  set recordtype(value) {
    this._recordType = value;
    this.selectedRecordId = this._recordType.id;
    this.recordTypeName = this._recordType.value;
    this.isNonCreditRecordType =
      this.recordTypeName === NON_CREDIT_RECORD_TYPE_NAME;
    this.isFormOpen = true;
  }
  @track modalHeader = "New Account";
  @track allListViews;
  @track accountTypeOptions = [];
  @track selectedRecordId;

  //RecordEditForm variables:
  @track modalHeader2 = "New Account : Non-Credit";
  @track modalHeader3 = "New Account : Prospect";
  @track sectionHeader1 = "General Info";
  @track sectionHeaderProspect = "Strategy/ Opportunity";
  @api isFormOpen = false;
  @track name = "";
  @track accountType = ACCOUNTTYPE_FIELD;
  @track objectApiNameForForm = "Account";
  @track phone = "";
  //SF-5395
  @track parentId = "";
  @track email = "";
  @track driversLicense = "";
  @track driversLicenseState = "";
  @track comments = "";
  @track zipcode = "";
  @track street = "";
  @track city = "";
  @track country = "";
  @track state = "";
  @track dob = "";
  @track description = "";
  @track equipment;
  disabled = false;
  showLoading = false;
  @api isNonCreditRecordType = false;
  @track uniquePref;
  @track otherPhone;
  @track rentalOpp;
  @track otherOpp;
  @track primaryEquip;
  @track prefContact;
  @track spOpp;
  @track strategy;
  @track otherPref;
  @track strategyDate;
  @track fax;
  @track creditCodeDesc;
  @track selectedId;
  @track parentId = "";
  hideButton = true;
  @api selectedParentAccount;
  today = new Date().toISOString().slice(0, 10);
  @track isError = false;
  @track hasDobError = false;
  @track displayToast = false;
  _countries = [];
  _countryToStates = {};
  accountId;
  isMobile = false;
  //FRONT-803
  recordTypeName;

  FIELDS = [];
  drivingStateOptions = [];
  errormsg;

  phoneVal = "";
  emailVal = "";
  // FRONT-2996 Starts
  duplicateResolverPayload;
  _bypassDuplicateRules = false;
  // FRONT-2996 Ends
  _lengthExceededFields = {};
  @wire(getPicklistValues, {
    recordTypeId: "$accountInfo.data.defaultRecordTypeId",
    fieldApiName: DL_STATES
  })
  getPicklistValues({ error, data }) {
    if (data) {
      // Map picklist values to buttons
      this.drivingStateOptions = data.values.map((plValue) => {
        return {
          label: plValue.label,
          value: plValue.value
        };
      });
    } else if (error) {
      // Handle error
    }
  }

  // fields = [ACCOUNTTYPE_FIELD, NAME_FIELD, PHONE_FIELD,DRIVERS_LICENSE,DRIVERS_LICENSE_STATE,BIRTH_DATE];

  // FRONT-1270
  fName = "";
  lName = "";
  conValue;
  contactId;
  contAccId;

  //FRONT-1616
  label = LABELS;
  // FRONT-3545 Start
  FIELD_LENGTH_CONFIG_MAPPING = {
    street: {
      maxLength: 30,
      message: this.label.STREETLIMIT
    },
    city: {
      maxLength: 20,
      message: this.label.CITYLIMIT
    },
    postalCode: {
      maxLength: 10,
      message: this.label.ZIPCODELIMIT
    },
    Comments__c: {
      maxLength: 40,
      message: this.label.COMMENTLIMIT
    }
  };
  // @api recordId;

  customLayoutStyle = "";
  screenName = NEW_SCREEN;
  render() {
    if (this.isMobile) {
      return mobileTemplate;
    } else {
      return desktopTemplate;
    }
  }

  connectedCallback() {
    //     console.log('parentcmp::'+this.recordId);
    console.log("parentcmp::" + this.parentcmp);

    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    //Added for 1268
    if (this.isMobile) {
      this.customLayoutStyle = "display: unset";
      loadStyle(this, Sbr_3_0_customModalCmp_Css);
    } else {
      loadStyle(this, Sbr_3_0_customModalCmpDesktop_Css);
    }
    //this.today = new Date().toISOString().slice(0, 10);
    if (this.parentcmp == "orderrequireCustomLookup") {
      this.isFormOpen = true;
      this.isNonCreditRecordType = true;
      this.recordTypeName = NON_CREDIT_RECORD_TYPE_NAME; //FRONT-803
    }
    //this.template.querySelector('combobox-input-6549').hide();
    this.setAppName();
  }

  //START: FRONT-4195
  renderedCallback() {
    Promise.all([loadStyle(this, modalCss)]) //added for FRONT-6234
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {
        console.log(error.body.message);
      });
  }

  //END: FRONT-4195

  //Modified as part of FRONT-3038, FRONT-3063
  setAccountName() {
    let accName = [this.lName, this.fName].filter(Boolean).join(", ");
    this.name = accName.trim();
    if (
      this.name.length > 30 &&
      this.lName !== "" &&
      this.lName.length > 25 &&
      this.fName.length >= 3
    ) {
      this.name = [this.lName.slice(0, 25), this.fName.slice(0, 3)]
        .filter(Boolean)
        .join(", ");
    } else if (
      this.lName === "" &&
      this.fName !== "" &&
      this.name.length > 30
    ) {
      this.name = this.fName.slice(0, 30);
    } else if (this.fName === "") {
      this.name = this.lName.slice(0, 30);
    } else if (
      this.name.length > 30 &&
      this.fName !== "" &&
      this.lName.length > 25 &&
      this.fName.length >= 3
    ) {
      this.name = [this.lName.slice(0, 25), this.fName.slice(0, 3)]
        .filter(Boolean)
        .join(", ");
    } else if (
      this.fName === "" &&
      this.lName !== "" &&
      this.name.length > 30
    ) {
      this.name = this.lName.slice(0, 30);
    } else if (this.lName === "") {
      this.name = this.fName.slice(0, 30);
    } else {
      if (this.fName.length < 3) {
        this.name = [
          this.lName.slice(0, 28 - this.fName.length),
          this.fName.slice(0, this.fName.length)
        ]
          .filter(Boolean)
          .join(", ");
      } else {
        this.name = [
          this.lName.slice(0, 25),
          this.fName.slice(0, 28 - this.lName.length)
        ]
          .filter(Boolean)
          .join(", ");
      }
    }
    return this.name;
  }
  //Front-3459
  CLASS1 = "class1";

  get myClass() {
    return this.CLASS1;
  }
  //end front-3459

  handleFieldChange(event) {
    if (event.target.name === "FirstName") {
      this.fName = event.target.value;
      if (this.fName !== "") {
        this.fName = this.fName[0].toUpperCase() + this.fName.slice(1);
      }
      this.setAccountName();
    }
    if (event.target.name === "LastName") {
      this.lName = event.target.value;
      if (this.lName !== "") {
        this.lName = this.lName[0].toUpperCase() + this.lName.slice(1);
      }
      this.setAccountName();
    }
    if (event.target.title == "Name") {
      this.name = event.detail.value;
      console.log("Name" + this.name);
    } else if (event.target.title == "Phone") {
      this.phone = event.detail.value;
      console.log("Phone", this.phone);
    } else if (event.target.title == "email") {
      this.email = event.detail.value;
      console.log("email", this.email);
    } else if (event.target.title == "License") {
      this.driversLicense = event.detail.value;
      console.log("License" + this.driversLicense);
    } else if (event.target.title == "licenseState") {
      this.driversLicenseState = event.detail.value;
      console.log("License State", this.driversLicenseState);
    } else if (event.target.title == "DOB") {
      this.dob = event.detail.value;
      console.log("DOB", this.dob);
    } else if (event.target.title == "comments") {
      this.description = event.detail.value;
      console.log("comments", this.description);
      //START: FRONT-18952: show comment length validation immediately
      this.validateComment(event);
      //END: FRONT-18952
    } else if (event.target.title == "ParentAccount") {
      this.parentId = event.detail.recordId;
      console.log("parentId", this.parentId);
    }
    console.log("Printing Title?", event.target.title);
  }

  //following code for dependent picklist (country:state)
  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  accountInfo;

  get statecodeData() {
    return this._countryToStates[this.country] || [];
  }

  get countryOptions() {
    return this._countries;
  }

  //getting countries for picklist
  @wire(getPicklistValues, {
    recordTypeId: "$accountInfo.data.defaultRecordTypeId",
    fieldApiName: COUNTRY_CODE
  })
  countryCode({ data, error }) {
    if (data) {
      console.log("opt::", data.values);
      this._countries = data.values;
      console.log("inside wire for countryoptions", data.values);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$accountInfo.data.defaultRecordTypeId",
    fieldApiName: STATE_CODE
  })
  stateCode({ data, error }) {
    if (error) {
      console.error(error);
    }
    if (!data) {
      return;
    }
    //console.log('controller values', data.controllerValues);
    const validForNumberToCountry = Object.fromEntries(
      Object.entries(data.controllerValues).map(([key, value]) => [value, key])
    );

    this._countryToStates = data.values.reduce((accumulatedStates, state) => {
      const countryIsoCode = validForNumberToCountry[state.validFor[0]];

      return {
        ...accumulatedStates,
        [countryIsoCode]: [
          ...(accumulatedStates?.[countryIsoCode] || []),
          state
        ]
      };
    }, {});
    console.log("Accumulated States", this._countryToStates);
  }

  errorCallback(error, stack) {
    console.error("errorcallback", error);
  }

  //Getting record type description here.
  @wire(getRecordTypeInfo, {
    sObjectApiName: "Account"
  })
  objectInfo({ error, data }) {
    if (data) {
      data = JSON.parse(JSON.stringify(data));
      this.allListViews = JSON.parse(JSON.stringify(data));
      console.log("check1", this.allListViews);
      console.log("check2", this.allListViews[0].Name);
      for (const line in this.allListViews) {
        console.log("checking name", this.allListViews[line].Name);
        if (
          this.allListViews[line].Name === PROSPECT_RECORD_TYPE_NAME ||
          this.allListViews[line].Name === NON_CREDIT_RECORD_TYPE_NAME
        ) {
          this.accountTypeOptions.push({
            label: this.allListViews[line].Name,
            value: this.allListViews[line].Name,
            id: this.allListViews[line].Id,
            description: this.allListViews[line].Description
          });
          if (this.parentcmp == "orderrequireCustomLookup") {
            if (this.allListViews[line].Name === NON_CREDIT_RECORD_TYPE_NAME) {
              this.selectedRecordId = this.allListViews[line].Id;
            }
          }
          /* if(this.allListViews[line].Name === NON_CREDIT_RECORD_TYPE_NAME) {
                        this.selectedRecordId = this.allListViews[line].Id;
                    } */
        }
        console.log("recordtype info?", this.accountTypeOptions);
      }
    } else if (error) {
      console.log(error);
    }
  }

  //   //  @wire(getRecord, { recordId: '$recordId', fields: ACCOUNTFIELDS})
  //   //  recordInfo({data, error}){
  //  //       if (data) {
  //             console.log('inside getrecord', this.recordId, data)
  //             this.isFormOpen = true;
  //         } else if (error) {
  //             console.log(error);
  //         }
  //     }

  handleRadioChange(event) {
    this.selectedRecordId = event.target.value;
    console.log("Radio", event.target.value);
    console.log(this.selectedRecordId);
    this.recordTypeName = event.target.title;
    if (this.recordTypeName == NON_CREDIT_RECORD_TYPE_NAME) {
      this.isNonCreditRecordType = true;
    } else {
      this.isNonCreditRecordType = false;
      // this.hideButton=true;
    }
    console.log("recordtypename:" + this.recordTypeName);
    //this.updateAccountTypeOptions();
    //console.error(error);
  }

  closeModal() {
    const eventProps = {
      isModalOpen: false
    };
    this.setNewActionOverrideSuccessPayload(eventProps);
    const closeModal = new CustomEvent("closemodal", eventProps);
    this.dispatchEvent(closeModal);
  }

  submitDetails(event) {
    if (this.selectedRecordId == undefined) {
      event.preventDefault();
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: "Select a record type.",
          variant: "warning"
        })
      );
      if (
        this.parentcmp == "quoterequireCustomLookup" ||
        this.parentcmp == "orderrequireCustomLookup"
      ) {
        this.errorTitle = "Error";
        this.errorMsg = "Select a record type.";
        this.displayToast = true;
        event.preventDefault();
        setTimeout(() => {
          this.displayToast = false;
        }, 3000);
      }
    } else {
      const submitdetails = new CustomEvent("submitdetails", {
        isModalOpen: false
      });
      this.dispatchEvent(submitdetails);
      this.isFormOpen = true;
    }

    if (this.isMobile) {
      this.customLayoutStyle = "display: unset";
    }
  }

  closeForm() {
    this.isFormOpen = false;
    this.closeModal();
  }

  genericInputChange(event) {
    console.log("event.target.dataset.name -- " + event.target.dataset.name);
    this.handleAddressMessage(event); //FRONT-4195
    this.street = event.target.street;
    this.state = event.target.province;
    this.zipcode = event.target.postalCode;
    this.country = event.target.country;
    this.city = event.target.city;
    //this.validateAddress(event);  //Shifted this method to handleAddressMessage function
    //FRONT-3545 added validations check for address fields here as well for better user experience
  }

  //Dispatching event to respective parent to auto-populate newly created account.
  @track accountSelected;
  hideResults(account) {
    console.log("account Id::", account);
    let hideResults;
    this.accountSelected = account;
    console.log("account selected::", this.accountSelected);
    if (account) {
      let accObj = { acc: account, newOrExistingAcc: "New" };
      console.log("entered if:");
      hideResults = new CustomEvent("hideresults", {
        detail: accObj
      });
    } else {
      hideResults = new CustomEvent("hideresults", {
        hideResults: false
      });
    }

    this.dispatchEvent(hideResults);
  }

  validateFields(event) {
    this.isError = false;

    if (this.isNonCreditRecordType) {
      if (
        !this.fName.trim() ||
        !this.lName.trim() ||
        !this.phone ||
        !this.email ||
        !this.driversLicense ||
        !this.driversLicenseState ||
        !this.dob
      ) {
        return true;
      }
      if (this.dob) {
        console.log("Inside this.dob");
        let today = new Date();
        today = today.toISOString().slice(0, 10);
        if (this.dob > today) {
          console.log("Inside future dob");
          this.displayError(this.label.DOBERRTITLE, this.label.DOBValidation);
          this.isError = true;
          event.preventDefault();
        }
      }
    }
    if (
      !this.name ||
      !this.street ||
      !this.city ||
      !this.country ||
      !this.state ||
      !this.zipcode
    ) {
      return true;
    } else if (!this.isNonCreditRecordType && !this.phone && !this.email) {
      console.log("enetered::");
      let phoneComp =
        this.template.querySelector(".prospectPhone") == null
          ? this.template.querySelector(".nonCreditPhone")
          : this.template.querySelector(".prospectPhone");
      let emailComp =
        this.template.querySelector(".prospectEmail") == null
          ? this.template.querySelector(".nonCreditEmail")
          : this.template.querySelector(".prospectEmail");

      phoneComp.setCustomValidity("Enter either a phone or email.");
      phoneComp.reportValidity();

      emailComp.setCustomValidity("Enter either a phone or email.");
      emailComp.reportValidity();
      this.isError = true;
      //return true;
    } else if (
      this.email &&
      !this.email.match(
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
      )
    ) {
      this.displayError(this.label.ERRTITLE, this.label.INVALIDEMAILERRMSG);
      this.isError = true;
      event.preventDefault();
    }

    //FRONT-3524 Moved this else if block above the 10 number validation if block so that it is checked first
    else if (this.phone && !/^\d+$/.test(this.phone)) {
      this.displayError(this.label.ERRTITLE, this.label.INVALIDPHONEERRMSG);
      this.isError = true;
      event.preventDefault();
    } else if (this.phone && this.phone.length !== 10) {
      this.displayError(this.label.ERRTITLE, this.label.PHONEERRMSG);
      this.isError = true;
      event.preventDefault();
    }

    //FRONT-3545 added checks for address fields length to show error toast message on Save
    else if (Object.keys(this._lengthExceededFields).length > 0) {
      this.displayError(
        this.label.ERRTITLE,
        "Review and resolve the errors specified."
      );
      this.isError = true;
    } else return false;
  }

  /* START::Modified as part of FRONT-3031,3032 */
  checkOnBlur(event) {
    const field = event.target.name;
    if (field === "Phone") {
      logger.log("inside checkonblur");
      this.vaidateOnBlur(event);
    } else if (field === "email") {
      this.vaidateOnBlur(event);
    }
  }
  vaidateOnBlur(event) {
    logger.log("inside validateonblur");
    let value = event.target.value;
    let hasError = false;
    if (event.target.name === "Phone") {
      logger.log("inside phone final");
      const regex = /^\d+$/;
      if (!regex.test(value) && !isEmpty(value)) {
        logger.log("inside regex");
        event.target.setCustomValidity(this.label.PHONENUMONLYERR);
        event.target.reportValidity();
        hasError = true;
      }
    } else if (event.target.name === "email") {
      const regex =
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.EMAILINVALIDFORMATERR);
        event.target.reportValidity();
        hasError = true;
      }
    }
    if (!hasError && value) {
      event.target.setCustomValidity("");
      event.target.reportValidity();
      if (event.target.name === "email") {
        let phoneComp =
          this.template.querySelector(".prospectPhone") == null
            ? this.template.querySelector(".nonCreditPhone")
            : this.template.querySelector(".prospectPhone");
        phoneComp =
          phoneComp == null
            ? this.template.querySelector(".nonCreditPhone")
            : phoneComp;
        phoneComp.setCustomValidity("");
        phoneComp.reportValidity();
      } else if (event.target.name === "Phone") {
        let emailComp =
          this.template.querySelector(".prospectEmail") == null
            ? this.template.querySelector(".nonCreditEmail")
            : this.template.querySelector(".prospectEmail");
        emailComp.setCustomValidity("");
        emailComp.reportValidity();
      }
    }
    if (!hasError && !value) {
      event.target.setCustomValidity("");
      event.target.reportValidity();
    }
  }
  /* END::Modified as part of FRONT-3031,3032 */

  handleSave(event) {
    //if (this.isNonCreditRecordType) {
    if (this.validateFields(event)) {
      this.displayError(
        this.label.REQUIREDFIELDSERRTITLE,
        this.label.REQUIREDFIELDSERRMSG
      );
      event.preventDefault();
    } else {
      if (!this.isError) {
        this.showLoading = true;
        this.callCreateRecord(event);
        event.preventDefault();
      }
    }
    //}
    /*else {
      console.log("for prospect account");
      if (this.validateFieldsProspect(event)) {
        this.displayError(
          this.label.REQUIREDFIELDSERRTITLE,
          this.label.REQUIREDFIELDSERRMSG
        );
        event.preventDefault();
      } else {
        if (!this.isError) {
          console.log("enetr::");
          this.showLoading = true;
          this.callCreateRecord(event);
        }
        event.preventDefault();
      }
    }*/
  }

  callCreateRecord(event) {
    console.log("This is in new Create Record Method.");
    event.preventDefault();
    const fields = {};
    fields[NAME_FIELD.fieldApiName] = this.name;
    fields[PARENT_ID.fieldApiName] = this.parentId; // SF-5395
    fields[PHONE_FIELD.fieldApiName] = this.phone;
    fields[EMAIL.fieldApiName] = this.email;
    fields[ACCOUNTTYPE_FIELD.fieldApiName] = this.selectedRecordId;

    if (this.isNonCreditRecordType) {
      fields[DRIVERS_LICENSE.fieldApiName] = this.driversLicense;
      fields[DRIVERS_LICENSE_STATE.fieldApiName] = this.driversLicenseState;
      fields[BILLING_STREET.fieldApiName] = this.street;
      fields[CITY.fieldApiName] = this.city;
      fields[POSTAL_CODE.fieldApiName] = this.zipcode;
      fields[COUNTRY_CODE.fieldApiName] = this.country;
      fields[STATE_CODE.fieldApiName] = this.state;
      fields[DESCRIPTION.fieldApiName] = this.description;
      fields[BIRTH_DATE.fieldApiName] = this.dob;
      fields[STATUS.fieldApiName] = ACTIVE_STATUS; //Added as part of FRONT-7308
      // // FRONT-3569 Starts - Skip Duplicate Rules if user selected new in the duplicate resolve screen
      // if (this._bypassDuplicateRules) {
      //   fields[BYPASS_DUPLICATE_RULES_FIELD.fieldApiName] = true;
      // }
      // // FRONT-3569 Ends - Skip Duplicate Rules if user selected new in the duplicate resolve screen
    } else {
      console.log("In prospect");
      fields[DESCRIPTION.fieldApiName] = this.description;
      fields[SHIPPING_STREET.fieldApiName] = this.street;
      fields[COUNTRY_CODE_PROSPECT.fieldApiName] = this.country;
      fields[SHIPPING_CITY.fieldApiName] = this.city;
      fields[state_code_prospect.fieldApiName] = this.state;
      fields[SHIPPING_ZIP.fieldApiName] = this.zipcode;
    }

    console.log("Fields recorded:", JSON.stringify(fields));
    if (!this.isError) {
      console.log("fields:", fields);
      const recordInput = fields;
      recordInput.sobjectType = this.objectApiNameForForm;

      let accountId = "";
      let acc = {};
      createSObject({
        record: recordInput,
        allowDuplicateRule: this._bypassDuplicateRules
      })
        .then((result) => {
          logger.log(result);
          this.showLoading = false;
          if (result && result.isSuccess) {
            let account = result.attributes?.record;
            this.contAccId = account.Id;
            acc = {
              Id: account.Id,
              Name: account.Name,
              RecordTypeId: account.RecordTypeId,
              RecordTypeName: this.recordTypeName, //Front-803
              Record_Type_Text__c: this.recordTypeName //FRONT-7371
            };
            console.log("acc:", acc);
            this.showLoading = false;
            accountId = account.Id;
            // calling createContact method - FRONT - 1270
            if (this.isNonCreditRecordType) {
              logger.log("inside n-c");
              this.createContact();
            }

            //FRONT-803 - different success msg for non-credit.
            if (
              this.isNonCreditRecordType &&
              this.parentcmp !== "accountsearchscreen"
            ) {
              // added check of parent for FRONT-13601
              let recordPageUrl = `/lightning/r/Account/${this.contAccId}/view?c__showTC=true`;
              const cEvent = new ShowToastEvent({
                title: "Success",
                message: "New Account has been successfully created. {0}",
                variant: "success",
                messageData: [
                  {
                    url: recordPageUrl,
                    label: "Get T&C Signature"
                  }
                ]
              });
              this.dispatchEvent(cEvent);
              // FRONT-3569 Starts - Show Toast Message For Addition to Cart/Customer Info
              this.showEventForAddition(
                "Account has been created and added to "
              );
              // FRONT-3569 Ends - Show Toast Message For Addition to Cart/Customer Info
            } else {
              const cEvent = new ShowToastEvent({
                title: "Success",
                message: "Account created",
                variant: "success"
              });
              this.dispatchEvent(cEvent);
            }
            this.closeModal();
            this.hideResults(acc);
          } else {
            if (result.message === DUPLICATE_ERROR_CODE) {
              if (this.isNonCreditRecordType) {
                logger.log(result.attributes?.duplicateRecordIds);
                logger.log("dup Recs:", result.attributes?.duplicateRecords);
                this.buildDuplicateErrorPayload(
                  result.attributes?.duplicateRecordIds,
                  result.attributes?.duplicateRuleName,
                  result.attributes?.duplicateRecords,
                  recordInput
                );
              } else {
                this.displayError(
                  "Duplicate Account detected.",
                  result.message
                );
              }
            } // FRONT-2996,3449 ends - Duplicate detected.
            else {
              this.displayError(
                "Error occured while creating a record.",
                result.message
              );
            }
          }
        })
        .catch((error) => {
          this.showLoading = false;
          logger.error("error:", error);
          this.displayError(
            "Error occured while creating a record.",
            error.body.message
          );
        });
    }
  }

  // Method for creating contact record FRONT - 1270
  createContact() {
    //for inserting contact record
    console.log("inside create contact");
    const conFields = {};
    conFields[CONTACT_ACCOUNT_ID.fieldApiName] = this.contAccId;
    conFields[CONTACT_FIRST_NAME.fieldApiName] = this.fName;
    conFields[CONTACT_LAST_NAME.fieldApiName] = this.lName;
    conFields[CONTACT_EMAIL.fieldApiName] = this.email;
    conFields[CONTACT_PHONE_NUMBER.fieldApiName] = this.phone;
    conFields[CONTACT_MAILING_STATE.fieldApiName] = this.state;
    conFields[CONTACT_MAILING_CITY.fieldApiName] = this.city;
    conFields[CONTACT_MAILING_STREET.fieldApiName] = this.street;
    conFields[CONTACT_MAILING_POSTAL_CODE.fieldApiName] = this.zipcode;
    conFields[CONTACT_MAILING_COUNTRY.fieldApiName] = this.country;
    //FRONT-900 START
    conFields[CONTACT_DL_NUMBER.fieldApiName] = this.driversLicense;
    conFields[CONTACT_DL_STATE.fieldApiName] = this.driversLicenseState;
    conFields[CONTACT_PRIMARY.fieldApiName] = true;
    //FRONT-900 END

    console.log("Contact Fields recorded:", conFields);

    const contactRecord = conFields;
    contactRecord.sobjectType = CONTACT_OBJECT.objectApiName;

    console.log("Rec:" + JSON.stringify(contactRecord));

    createSObject({
      record: contactRecord,
      allowDuplicateRule: this._bypassDuplicateRules
    })
      .then((result) => {
        if (result && result?.isSuccess) {
          this.contactId = result.attributes?.record?.Id;
          this.clearBypassDuplicateRules();
        } else {
          logger.error("Contact Creation Failed with ", result.message);
        }
      })
      .catch((error) => {
        console.log("Error in Contact Creation:" + JSON.stringify(error));
      });
  }

  @api
  displayError(errortitle, msg) {
    console.log("msg::" + msg);
    this.errorMsg = msg;
    this.errorTitle = errortitle;
    const newEvent = new ShowToastEvent({
      title: errortitle,
      message: msg,
      variant: "error"
    });
    this.dispatchEvent(newEvent);
    console.log("parent::" + this.parentcmp);
    if (
      this.parentcmp == "quoterequireCustomLookup" ||
      this.parentcmp == "orderrequireCustomLookup"
    ) {
      this.displayToast = true;
      //event.preventDefault();
      setTimeout(() => {
        this.displayToast = false;
      }, 3000);
    }
    console.log("thi::" + this.displayToast);
  }

  closeToast(event) {
    this.displayToast = false;
  }

  handleFieldBlur(event) {
    const fieldTitle =
      event.target.title || event.target.name || event.target.dataset.name;
    // eslint-disable-next-line default-case
    switch (fieldTitle) {
      case "DOB":
        this.validateDOB(event);
        break;

      case "Phone":
        this.validatePhone(event);
        break;

      case "email":
        this.validateEmail(event);
        break;

      // FRONT-3545 Start
      case BILLING_ADDRESS:
        //  this.validateAddress(event);  //Shifted this method to handleAddressMessage function
        this.handleAddressMessage(event); //Front-4195
        break;

      case SHIPPING_ADDRESS:
        //  this.validateAddress(event);  //Shifted this method to handleAddressMessage function
        this.handleAddressMessage(event); //Front-4195
        break;

      case "comments":
        this.validateComment(event);
        break;
      // FRONT-3545 End
    }
  }

  get dateOfBirthOverFlowMessage() {
    let vartoday = new Date();
    let options = { month: "2-digit", day: "2-digit", year: "numeric" };
    let formattedDate = vartoday.toLocaleDateString("en-US", options);
    console.log(formattedDate);
    return `Date must be ${formattedDate} or earlier.`;
  }
  //Modified as part of FRONT-3155
  validateDOB(event) {
    let hasError = false;
    for (let error of ERROR_STACK) {
      if (event.target.validity[error]) {
        let message = event.target.dataset[`${error}Message`];
        if (message) {
          this.template.querySelector("lightning-input[title='DOB']").value =
            null;
          event.target.setCustomValidity(message);
          hasError = true;
          break;
        }
      }
    }
    if (!hasError) {
      event.target.setCustomValidity("");
    }
    event.target.reportValidity();
  }

  setNewActionOverrideSuccessPayload(eventProps) {
    if (this.parentcmp === NEW_ACTION_OVERRIDE) {
      const detail = {};
      if (this.contAccId) {
        detail.action = VIEW_ACTION;
        detail.recordId = this.contAccId;
      } else {
        detail.action = CANCEL_ACTION;
      }

      eventProps.detail = detail;
    }
  }

  // FRONT-2996 ,3449 Starts - Duplicate Detection Resolver
  buildDuplicateErrorPayload(
    duplicateRecordIds,
    duplicateRuleName,
    duplicateRecords,
    currentRecord
  ) {
    this.duplicateResolverPayload = {
      currentRecord: currentRecord,
      duplicateRecordIds,
      duplicateRuleName,
      duplicateRecords,
      origin: this.parentcmp
    };
  }

  handleDuplicateResolveClick(event) {
    let resolveBy = event.detail.resolveBy;
    switch (resolveBy) {
      case NEW_RESOLUTION:
        this.handleResolutionByNew(event);
        break;
      case EXISTING_RESOLUTION:
        this.handleResolutionByExisting(event);
        break;
      default:
        break;
    }

    this.handleDuplicateCancelClick();
  }

  handleResolutionByNew(event) {
    this._bypassDuplicateRules = true;
    this.handleSave(event);
  }

  handleResolutionByExisting(event) {
    this.clearBypassDuplicateRules();
    const selectedAccount = {
      Id: event.detail.selectedRecord.Id,
      Name: event.detail.selectedRecord.Name,
      RecordTypeId: event.detail.selectedRecord.RecordTypeId,
      RecordTypeName: event.detail.selectedRecord["RecordType.Name"],
      Record_Type_Text__c: event.detail.selectedRecord["RecordType.Name"] //FRONT-7371
    };
    this.showEventForAddition();
    this.closeModal();
    this.hideResults(selectedAccount);
  }

  handleDuplicateCancelClick(event) {
    this.duplicateResolverPayload = null;
    this.setFocusOnButton(); //FRONT-12375: manually setting the focus to Save button
  }

  handleDuplicateHardStopCancel(event) {
    let eventProps = {
      isModalOpen: false
    };
    this.setNewActionOverrideSuccessPayload(eventProps);
    if (eventProps.detail && event.detail !== "NewActionOverride")
      eventProps.detail.action = null;

    const closeModal = new CustomEvent("closemodal", eventProps);
    this.dispatchEvent(closeModal);
    this.setFocusOnButton(); //FRONT-12375: manually setting the focus to Save button
  }

  clearBypassDuplicateRules() {
    this._bypassDuplicateRules = false;
  }

  get searchModalComputedClasses() {
    let classes = "slds-modal";
    if (!this.duplicateResolverPayload) {
      classes += " slds-fade-in-open";
    }
    return classes;
  }

  showEventForAddition(message = "Account has been added to ") {
    if (this.parentcmp !== NEW_ACTION_OVERRIDE) {
      let addedTo =
        this.parentcmp === RESERVATION_ORDER_ORIGIN ||
        this.parentcmp === QUOTE_ORIGIN
          ? "Customer Info"
          : "cart";
      const cEvent = new ShowToastEvent({
        title: "Success",
        message: `${message}${addedTo}`,
        variant: "success"
      });
      this.dispatchEvent(cEvent);
    }
  }

  // FRONT-2996,3449 Ends - Duplicate Detection Resolver

  //START: FRONT:3223
  validatePhone(event) {
    let value = event.target.value;
    let hasError = false;
    const regex = /^\d+$/;
    if (!regex.test(value) && !isEmpty(value)) {
      event.target.setCustomValidity(this.label.PHONENUMONLYERR);
      event.target.reportValidity();
      hasError = true;
    }
    if (!hasError && value) {
      event.target.setCustomValidity("");
      event.target.reportValidity();
    }
  }

  validateEmail(event) {
    let value = event.target.value;
    let hasError = false;
    const regex =
      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if (!regex.test(value) && !isEmpty(value)) {
      event.target.setCustomValidity(this.label.EMAILINVALIDFORMATERR);
      event.target.reportValidity();
      hasError = true;
    }
    if (!hasError && value) {
      event.target.setCustomValidity("");
      event.target.reportValidity();
    }
  }
  //END: FRONT:3223

  get saveOrSelect() {
    if (this.parentcmp === "NewActionOverride") {
      return this.label.SAVE;
    }
    return this.label.SAVE_AND_SELECT;
  }

  // FRONT-3545 Start
  validateAddress(event) {
    let addressFields = ["street", "city", "postalCode"];
    for (let field of addressFields) {
      if (this.FIELD_LENGTH_CONFIG_MAPPING[field]) {
        let currentFieldValue = event.target[field];
        this.validateMaxLength(field, currentFieldValue, event);
      }
    }
  }

  validateMaxLength(fieldName, fieldValue, event) {
    let fieldConfig = this.FIELD_LENGTH_CONFIG_MAPPING[fieldName];
    let maxLength = fieldConfig?.maxLength;
    let currentFieldValueLength = fieldValue?.length;
    let hasExceededMaxLength = false;
    if (
      !isUndefinedOrNull(maxLength) &&
      !isUndefinedOrNull(currentFieldValueLength) &&
      currentFieldValueLength > maxLength
    ) {
      hasExceededMaxLength = true;
    }
    if (event.target.setCustomValidityForField) {
      if (hasExceededMaxLength) {
        event.target.setCustomValidityForField(fieldConfig.message, fieldName);
        event.target.reportValidity();
      } else if (event.target.checkValidity()) {
        event.target.setCustomValidityForField("", fieldName);
      }
    } else if (event.target.setCustomValidity) {
      if (hasExceededMaxLength) {
        event.target.setCustomValidity(fieldConfig.message);
      } else {
        event.target.setCustomValidity("");
      }
      event.target.reportValidity();
    }

    if (hasExceededMaxLength) {
      this.addFieldToLengthExceededStack(fieldName);
    } else {
      this.removeFieldFromLengthExceededStack(fieldName);
    }
  }

  validateComment(event) {
    this.validateMaxLength(event.target.name, event.target.value, event);
  }

  addFieldToLengthExceededStack(fieldName) {
    this._lengthExceededFields[fieldName] = 1;
  }

  removeFieldFromLengthExceededStack(fieldName) {
    if (this._lengthExceededFields[fieldName]) {
      delete this._lengthExceededFields[fieldName];
    }
  }
  // FRONT-3545 End

  //START: FRONT-4195
  handleAddressMessage(event) {
    const address = this.template.querySelector("lightning-input-address");
    var street = address.street;
    if (!street) {
      address.setCustomValidityForField("Complete this field.", "street");
    } else {
      address.setCustomValidityForField("", "street"); //Reset previously set message
    }

    var city = address.city;
    if (!city) {
      address.setCustomValidityForField("Complete this field.", "city");
    } else {
      address.setCustomValidityForField("", "city");
    }

    var province = address.province;
    if (!province) {
      address.setCustomValidityForField("Complete this field.", "province");
    } else {
      address.setCustomValidityForField("", "province");
    }

    var postalCode = address.postalCode;
    if (!postalCode) {
      address.setCustomValidityForField("Complete this field.", "postalCode");
    } else {
      address.setCustomValidityForField("", "postalCode");
    }

    var country = address.country;
    if (!country) {
      address.setCustomValidityForField("Complete this field.", "country");
    } else {
      address.setCustomValidityForField("", "country"); //Reset previously set message
    }

    this.validateAddress(event);
    address.reportValidity();
  } //END : FRONT-4195

  //modified existing logic for getting appName Start
  async setAppName() {
    this.appName = await appName;
  }
  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }

  get showParentAccountAccField() {
    if (this.isFrontlineApp) {
      return false;
    } else {
      return true;
    }
  }
  //modified existing logic for getting appName End

  //FRONT-12375: manually setting the focus to the new account modal as part of accessibility issue fix
  @api
  setFocus() {
    const customModal = this.template.querySelector(".customModalCloseButton");
    if (customModal) {
      customModal.focus();
    }
  }

  //FRONT-12375: manually setting the focus to Save button
  setFocusOnButton() {
    setTimeout(() => {
      const savebutton = this.template.querySelector(
        '[data-id="saveOrSelect"]'
      );
      if (savebutton) {
        savebutton.focus();
      }
    }, 500);
  }
  //End of FRONT-12375
}