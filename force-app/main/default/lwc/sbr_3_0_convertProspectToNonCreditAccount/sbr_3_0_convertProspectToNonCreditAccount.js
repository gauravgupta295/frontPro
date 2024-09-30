import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { Logger, isUndefinedOrNull } from "c/sbr_3_0_frontlineUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import BILLING_STREET from "@salesforce/schema/Account.BillingStreet";
import CITY_FIELD from "@salesforce/schema/Account.BillingCity";
import STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";
import POSTALCODE_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import ACCOUNTTYPE_FIELD from "@salesforce/schema/Account.RecordTypeId";
import ID_FIELD from "@salesforce/schema/Account.Id";
import EMAIL from "@salesforce/schema/Account.E_mail_Address__c";
import DRIVERS_LICENSE from "@salesforce/schema/Account.Drivers_License__c";
import DRIVERS_LICENSE_STATE from "@salesforce/schema/Account.Driver_s_License_State__c";
import DESCRIPTION from "@salesforce/schema/Account.Comments__c";
import BIRTH_DATE from "@salesforce/schema/Account.BirthDate__c";
import SHIPPING_STREET from "@salesforce/schema/Account.ShippingStreet";
import SHIPPING_CITY from "@salesforce/schema/Account.ShippingCity";
import COUNTRY_CODE_PROSPECT from "@salesforce/schema/Account.ShippingCountryCode";
import state_code_prospect from "@salesforce/schema/Account.ShippingStateCode";
import SHIPPING_ZIP from "@salesforce/schema/Account.ShippingPostalCode";
import PARENT_ACCOUNT from "@salesforce/schema/Account.ParentId";
import OTHER_PHONE from "@salesforce/schema/Account.PersonOtherPhone__c";
import FAX from "@salesforce/schema/Account.Fax";
import UNIQUE_PREFERENCE from "@salesforce/schema/Account.Unique_Preferences_Hot_Buttons__c";
import PRIMARY_EQUIPMENT from "@salesforce/schema/Account.Primary_Equipment_Used__c";
import RENTAL_OPPORTUNITY from "@salesforce/schema/Account.Rental_Opportunity__c";
import SPECIALITY_OPPORTUNITY from "@salesforce/schema/Account.Specialty_Opportunity__c";
import OTHER_OPPORTUNITY from "@salesforce/schema/Account.Other_Opportunity__c";
import EQUIPMENT from "@salesforce/schema/Account.Equipment_Preference__c";
import OTHER_PREFERENCE from "@salesforce/schema/Account.Other_Preferences__c";
import PREFERRED_CONTACT_METHOD from "@salesforce/schema/Account.Preferred_method_of_Contact__c";
import STRATEGY from "@salesforce/schema/Account.Strategy_Last_Updated__c";
import { getRecord } from "lightning/uiRecordApi";
import { updateRecord } from "lightning/uiRecordApi";
import {
  createRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
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
import ACCOUNT_STATUS_FIELD from "@salesforce/schema/Account.Status__c";
//labels
import BILLINGINFO from "@salesforce/label/c.SBR_3_0_BillingInfo";
import GENERALINFO from "@salesforce/label/c.SBR_3_0_GeneralInfo";
import CONFIRSTNAME from "@salesforce/label/c.SBR_3_0_ContactFirstname";
import CONLASTNAME from "@salesforce/label/c.SBR_3_0_ContactLastname";
import SHIPPINGINFO from "@salesforce/label/c.SBR_3_0_ShippingInfo";
import ACCOUNTNAME from "@salesforce/label/c.SBR_3_0_AccountName";
import PHONE from "@salesforce/label/c.SBR_3_0_Phone";
import ACC_EMAIL from "@salesforce/label/c.SBR_3_0_Email";
import DLSTATE from "@salesforce/label/c.SBR_3_0_DLState";
import DLNUMBER from "@salesforce/label/c.SBR_3_0_DLNumber";
import DOB from "@salesforce/label/c.SBR_3_0_DOB";
import COMMENTS from "@salesforce/label/c.SBR_3_0_Comments";
import BILL_ADDRESS from "@salesforce/label/c.SBR_3_0_BillingAddress";
import STREET_ADDRESS from "@salesforce/label/c.SBR_3_0_StreetAddress";
import BILL_COUNTRY from "@salesforce/label/c.SBR_3_0_BillingCountry";
import BILL_STREET from "@salesforce/label/c.SBR_3_0_BillingStreet";
import BILL_CITY from "@salesforce/label/c.SBR_3_0_BillingCity";
import BILL_STATE from "@salesforce/label/c.SBR_3_0_BillingState";
import BILL_POSTALCODE from "@salesforce/label/c.SBR_3_0_BillingpostalCode";
import NON_CREDIT_ACC from "@salesforce/label/c.SBR_3_0_NewAccountNC";
import PROSPECT_ACC from "@salesforce/label/c.SBR_3_0_NewAccountProspect";
import CANCEL from "@salesforce/label/c.SBR_3_0_Cancel";
import SAVE from "@salesforce/label/c.SBR_3_0_Save";
import SHIP_COUNTRY from "@salesforce/label/c.SBR_3_0_Country";
import SHIP_STREET from "@salesforce/label/c.SBR_3_0_Street";
import SHIP_CITY from "@salesforce/label/c.SBR_3_0_City";
import SHIP_STATE from "@salesforce/label/c.SBR_3_0_State";
import SHIP_ZIPCODE from "@salesforce/label/c.SBR_3_0_Zipcode";
import NEW_ACCOUNT from "@salesforce/label/c.SBR_3_0_NewAccount";
import CLOSE from "@salesforce/label/c.SBR_3_0_Close";
import NEXT from "@salesforce/label/c.SBR_3_0_Next";
import SELECT_RECORD_TYPE from "@salesforce/label/c.SBR_3_0_SelectRecType";
import SELECT_BILL_ADDRS from "@salesforce/label/c.SBR_3_0_SelectBillingAddr";
import SELECT_SHIP_ADDRS from "@salesforce/label/c.SBR_3_0_SelectShippingAddrs";
import SAVE_AND_SELECT from "@salesforce/label/c.SBR_3_0_SaveAndSelect";
import mobileTemplate from "./sbr_3_0_convertProspectToNonCreditAccountMobile.html";
import desktopTemplate from "./sbr_3_0_convertProspectToNonCreditAccount.html";
import createProspectacc from "@salesforce/label/c.SBR_3_0_CreateProspectAcc";
import convertToNCAccount from "@salesforce/label/c.SBR_3_0_ConvertNCAccount";
import accountFromQuickActionTemplate from "./accountRecordTypeConversionFromQuickAction.html";
import accoutFromQuickActionMobile from "./accountRecordTypeConversionFromQuickActionMobile.html";
import Sbr_3_0_customModalCmp_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmp_Css";
import Sbr_3_0_customModalCmpDesktop_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmpDesktop_Css";
import { loadStyle } from "lightning/platformResourceLoader";
//START::Modified as part of FRONT-3223, FRONT-3224
import CONTACTINFO from "@salesforce/label/c.SBR_3_0_ContactInfo";
import REQUIRED_FIELDS_MISSING from "@salesforce/label/c.SBR_3_0_RequireFIeldsErrorMsg";
import USE_NUMBERS_ONLY from "@salesforce/label/c.SBR_3_0_PhoneNumbersOnlyErr";
import TEN_DIGIT_PHONE from "@salesforce/label/c.SBR_3_0_10DigitPhnErrorMsg";
import INVALID_EMAIL from "@salesforce/label/c.SBR_3_0_InvalidEmailErrorMsg";
import EITHER_PHONE_EMAIL from "@salesforce/label/c.sbr_3_0_eitherphoneEmail";
import INVALID_EMAIL_FORMAT from "@salesforce/label/c.SBR_3_0_InvalidEmailFormatErr";
import REQUIRED_FIELD_MISSING_TITLE from "@salesforce/label/c.SBR_3_0_RequireFIeldsErrTitle";
import ERROR_TITLE from "@salesforce/label/c.SBR_3_0_ErrorTitle";
import DOB_ERROR_TITLE from "@salesforce/label/c.SBR_3_0_DOBErrTitle";
import INVALID_DOB from "@salesforce/label/c.SBR_3_0_InvalidDOBErrMsg";
import DOBValidation from "@salesforce/label/c.DOB_Validation";
import DOBErrMsg from "@salesforce/label/c.SBR_3_0_DOBErrMsg"; //FRONT-3222 Added to use in html data-bad-input-message
import INVALIDPHONEERRMSG from "@salesforce/label/c.SBR_3_0_InvalidPhoneErrorMsg"; //FRONT-3222 Added to use in phone validation on save
import SEARCH_ADDRESS from "@salesforce/label/c.Search_Address";

//FRONT-3880, FRONT-3883, FRONT-4002, FRONT-3881 START
import updateSObject from "@salesforce/apex/SBR_3_0_DMLOpsController.updateSObject";
import createSObject from "@salesforce/apex/SBR_3_0_DMLOpsController.createSObject";
import LABELS from "c/sbr_3_0_customLabelsCmp";
//FRONT-3880, FRONT-3883, FRONT-4002, FRONT-3881 END

const ERROR_STACK = ["badInput", "valueMissing"];
import { isEmpty } from "c/sbr_3_0_frontlineUtils";
//END::Modified as part of FRONT-3223, FRONT-3224

//START:FRONT:84
import Sbr_3_0_customModalCmp from "@salesforce/resourceUrl/Pros_NonCredit_Css";
import Sbr_3_0_customModalCmp_Css1 from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
//END:FRONT:84
import SAVE_SELECT from "@salesforce/label/c.SBR_3_0_SaveAndSelect";

//import Account from '@salesforce/schema/Case.Account';
const logger = Logger.create(true);
const PARENTCMP = "requireCustomLookup";

// FRONT-3880, 4002 , FRONT-4001, FRONT-3881, FRONT-3883 START
const DUPLICATE_ERROR_CODE = "DUPLICATES_DETECTED";
const NEW_RESOLUTION = "new";
const EXISTING_RESOLUTION = "existing";
const NEW_ACTION_OVERRIDE = "NewActionOverride";
const NON_CREDIT_RECORD_TYPE_NAME = "Non-Credit";
// FRONT-3880, 4002 , 4001, FRONT-3881, FRONT-3883 END

// FRONT-3942 Start
const FIELD_LENGTH_CONFIG_MAPPING = {
  street: {
    maxLength: 30,
    message: "Use up to 30 characters only."
  },
  city: {
    maxLength: 20,
    message: "Use up to 20 characters only."
  },
  postalCode: {
    maxLength: 10,
    message: "Use up to 10 characters only."
  },
  Comments__c: {
    maxLength: 40,
    message: "Use up to 40 characters only."
  }
};
// FRONT-3942 End
const ACTIVE_STATUS = "Active";
export default class Sbr_3_0_convertProspectToNonCreditAccount extends NavigationMixin(
  LightningElement
) {
  @api callmobiletemplate; //FRONT-4002
  @api parentcmp = "ActionButton"; //4481
  @api variant;
  @track showSpinner = false;
  @api recordId;
  @api objectApiName = "Account";
  //@track objectInfo;
  @track nameValue;
  @track phonevalue;
  @track emailValue;
  @track dlValue;
  @track dlStateValue;
  @track dobValue;
  @track descriptionValue;
  @track strStreet = "";
  @track strCity = "";
  @track strState = "";
  @track strCountry = "";
  @track strPostalCode = "";
  @track noError = false;
  displayToast = false;
  showSuccessToast = false;
  //@track countryOptions=[];
  //@track statecodeData=[];
  @track currentRecordTypeId;
  @track nonCreditRecord = false;
  @track otherPhone;
  @track fax;
  @track uniquePref;
  @track rentalOpp;
  @track otherOpp;
  @track prefContact;
  @track equipPref;
  @track splOpp;
  @track primaryEquip;
  @track strategyUpdate;
  @track otherPref;
  @track anotherflag;
  accountId = "";
  dlStateOptions = [];
  _recordTypeName;
  screenName = "ConvertScreen"; //FRONT-3880,3881
  today = new Date().toISOString().slice(0, 10); //FRONT 3223
  firstName = "";
  lastName = "";
  _countries = [];
  _countryToStates = {};
  isMobile = false;
  isError = false;
  isSaveAndSelect = false;
  errorTitle = "";
  errorMsg = "";
  successTitle = "";
  successMsg = "";
  label = {
    BILLINGINFO,
    GENERALINFO,
    CONFIRSTNAME,
    CONLASTNAME,
    SHIPPINGINFO,
    ACCOUNTNAME,
    createProspectacc,
    convertToNCAccount,
    DOBValidation,
    PHONE,
    ACC_EMAIL,
    DLSTATE,
    DLNUMBER,
    DOB,
    COMMENTS,
    BILL_ADDRESS,
    STREET_ADDRESS,
    BILL_COUNTRY,
    BILL_STREET,
    BILL_CITY,
    BILL_STATE,
    BILL_POSTALCODE,
    NON_CREDIT_ACC,
    PROSPECT_ACC,
    CANCEL,
    SAVE,
    SAVE_AND_SELECT,
    SHIP_COUNTRY,
    SHIP_STREET,
    SHIP_CITY,
    SHIP_STATE,
    SHIP_ZIPCODE,
    NEW_ACCOUNT,
    CLOSE,
    NEXT,
    SELECT_RECORD_TYPE,
    SELECT_BILL_ADDRS,
    SELECT_SHIP_ADDRS,
    SHIPPINGINFO,
    CONTACTINFO,
    REQUIRED_FIELDS_MISSING,
    USE_NUMBERS_ONLY,
    TEN_DIGIT_PHONE,
    INVALID_EMAIL,
    EITHER_PHONE_EMAIL,
    INVALID_EMAIL_FORMAT,
    REQUIRED_FIELD_MISSING_TITLE,
    ERROR_TITLE,
    DOB_ERROR_TITLE,
    INVALID_DOB,
    DOBErrMsg,
    INVALIDPHONEERRMSG,
    SEARCH_ADDRESS
  };
  // FRONT-3942 Start
  _lengthExceededFields = {};
  // FRONT-3942 End
  render() {
    // Added for FRONT-4002
    if (
      (this.isMobile && this.variant != "plain") ||
      this.callmobiletemplate == true
    ) {
      return mobileTemplate;
    }
    //FRONT - 4881
    else if (
      (this.isMobile && this.variant === "plain") ||
      this.callmobiletemplate == true
    ) {
      return accoutFromQuickActionMobile;
    } else {
      if (this.variant === "plain") {
        return accountFromQuickActionTemplate;
      } else {
        return desktopTemplate;
      }
    }
  }
  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    // FRONT -2545
    if (this.isMobile) {
      loadStyle(this, Sbr_3_0_customModalCmp_Css);
      loadStyle(this, Sbr_3_0_customModalCmp);
    } else {
      loadStyle(this, Sbr_3_0_customModalCmpDesktop_Css);
    }
    logger.log("ParentCmp::" + this.parentcmp);
    window.setTimeout(() => {
      if (this.callmobiletemplate) {
        let input;
        input = this.template.querySelector(".contactFirstName");
        if (input) {
          input.focus();
        }
      }
    }, 0);
  }

  //START:FRONT:84
  renderedCallback() {
    Promise.all([loadStyle(this, Sbr_3_0_customModalCmp_Css1)])
      .then(() => {
        console.log("Files loaded");
      })
      .catch((error) => {
        console.log(error.body.message);
      });
    /*FRONT-18942 Starts */
    this.removeDefaultCloseIconView();
    /*FRONT-18942 Ends */
  }
  //END:FRONT:84

  // FRONT-3880 Starts
  duplicateResolverPayload;
  _bypassDuplicateRules = false;
  // FRONT-3880 Ends

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  objectInfo;

  @wire(getObjectInfo, {
    objectApiName: ACCOUNT_OBJECT
  })
  getRecordTypesId(data, error) {
    if (data.data) {
      const rtis = data.data.recordTypeInfos;
      this.NonCreditrecordTypeId = Object.keys(rtis).find(
        (rti) => rtis[rti].name === "Non-Credit"
      );
      this.prospectrecordTypeId = Object.keys(rtis).find(
        (rti) => rtis[rti].name === "Prospect"
      );
      /* FRONT-808 Starts */
      this.setGuestRecordTypeId(rtis);
      /* FRONT-808 Ends */
      if (rtis[this.prospectrecordTypeId]) {
        this.recordTypeName = rtis[this.prospectrecordTypeId].name;
      }
    }
  }
  // objectInfo;

  get statecodeData() {
    return this._countryToStates[this.strCountry] || [];
  }
  get countryOptions() {
    return this._countries;
  }

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: COUNTRY_FIELD
  })
  countryCode({ data, error }) {
    if (data) {
      this._countries = data?.values;
    }
  }

  //getting states for picklist
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: STATE_FIELD
  })
  stateCode({ data, error }) {
    if (!data) {
      return;
    }

    console.log("controller values", data.controllerValues);
    const validForNumberToCountry = Object.fromEntries(
      Object.entries(data.controllerValues).map(([key, value]) => [value, key])
    );
    console.log("map", validForNumberToCountry);
    this._countryToStates = data.values.reduce((accumulatedStates, state) => {
      const countryIsoCode = validForNumberToCountry[state.validFor[0]];
      // console.log("accumulatedStates",accumulatedStates);
      // console.log("STate",state);
      // console.log("countryIsoCode",countryIsoCode)

      return {
        ...accumulatedStates,
        [countryIsoCode]: [
          ...(accumulatedStates?.[countryIsoCode] || []),
          state
        ]
      };
    }, {});
  }

  //getting DL states for picklist
  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: DRIVERS_LICENSE_STATE
  })
  DlstateCode({ data, error }) {
    if (data) {
      this.dlStateOptions = data.values;
    }
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      NAME_FIELD,
      PHONE_FIELD,
      EMAIL,
      BILLING_STREET,
      CITY_FIELD,
      STATE_FIELD,
      POSTALCODE_FIELD,
      COUNTRY_FIELD,
      ACCOUNTTYPE_FIELD,
      EQUIPMENT,
      OTHER_PREFERENCE,
      PREFERRED_CONTACT_METHOD,
      DESCRIPTION
    ]
  })
  fetchAcc({ error, data }) {
    if (data) {
      let result = [];

      console.log("data", data.fields.BillingStateCode.value);
      this.nameValue = data.fields.Name.value;
      this.phonevalue = data.fields.Phone.value;
      this.emailValue = data.fields.E_mail_Address__c.value;
      this.strStreet = data.fields.BillingStreet.value;
      this.strCity = data.fields.BillingCity.value;
      this.strState = data.fields.BillingStateCode.value;
      this.strCountry = data.fields.BillingCountryCode.value;
      this.strPostalCode = data.fields.BillingPostalCode.value;
      this.currentRecordTypeId = data.fields.RecordTypeId.value;
      this.descriptionValue = data.fields.Comments__c.value;
      if (this.currentRecordTypeId == this.NonCreditrecordTypeId) {
        this.nonCreditRecord = true;
      } else {
        this.nonCreditRecord = false;
      }
      // FRONT-808 Starts
      this.recordTypeName = data?.recordTypeInfo?.name;
      // FRONT-808 Ends
    } else if (error) {
      console.log(error);
      // this.error = error;
    }

    console.log("this.QUIPMENT", this.QUIPMENT);
  }
  handleCancelClick() {
    const closeEvent = new CustomEvent("closemodal");
    this.dispatchEvent(closeEvent);
  }
  handleFieldChange(event) {
    if (event.target.name === "FirstName") {
      this.firstName = event.target.value;
      if (this.firstName !== "") {
        this.firstName =
          this.firstName[0].toUpperCase() + this.firstName.slice(1);
      }
      this.setAccountName();
    }
    if (event.target.name === "LastName") {
      this.lastName = event.target.value;
      if (this.lastName !== "") {
        this.lastName = this.lastName[0].toUpperCase() + this.lastName.slice(1);
      }
      this.setAccountName();
    }
    if (
      event.target.name === "AccountName" ||
      event.target.name === "ProspectAccountName"
    ) {
      this.nameValue = event.detail.value;
    }
    if (event.target.title === "DOB") {
      //this.dob = event.detail.value;
      this.dobValue = event.detail.value;
    }
    // FRONT-3942 Start
    if (event.target.name === "Comments__c") {
      this.descriptionValue = event.target.value;
    }
    // FRONT-3942 End
    if (event.target.title === "Driver_s_License_State__c") {
      this.dlStateValue = event.detail.value;
    }
    if (event.target.title === "Drivers_License__c") {
      this.dlValue = event.detail.value;
    }
  }
  //START FRONT-3221,3223
  // FRONT-3942 Start
  handleFieldBlur(event) {
    let fieldName = event.target.name || event.target.dataset.name;
    switch (fieldName) {
      case "Phone":
        this.validatePhone(event);
        break;
      case "email":
        this.validateEmail(event);
        break;
      case "Address":
        this.validateAddress(event);
        break;
      case "Comments__c":
        this.validateComment(event);
        break;
      default:
        break;
    }
  }
  // FRONT-3942 End
  validatePhone(event) {
    let value = event.target.value;
    let hasError = false;
    const regex = /^\d+$/;
    if (!regex.test(value) && !isEmpty(value)) {
      event.target.setCustomValidity(this.label.USE_NUMBERS_ONLY);
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
      event.target.setCustomValidity(this.label.INVALID_EMAIL_FORMAT);
      event.target.reportValidity();
      hasError = true;
    }
    if (!hasError && value) {
      event.target.setCustomValidity("");
      event.target.reportValidity();
    }
  }
  //END FRONT-3221,3223

  // FRONT-3880, 4002, FRONT-3881, FRONT-3883 Starts - Duplicate Detection Resolver
  //FRONT - 4481
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
    this.handleSaveAndSelectClick(event);
  }

  handleResolutionByExisting(event) {
    this.clearBypassDuplicateRules();
    const selectedAccount = {
      Id: event.detail.selectedRecord.Id,
      Name: event.detail.selectedRecord.Name,
      RecordTypeId: event.detail.selectedRecord.RecordTypeId,
      RecordTypeName: event.detail.selectedRecord["RecordType.Name"]
    };
    this.showEventForAddition();
    // if (this.isSaveAndSelect) {
    this.nameValue = selectedAccount.Name;
    this.recordId = selectedAccount.Id;

    this.selectAccountToCustomerInfo();
    //}
    this.closeModal();
    this.hideResults(selectedAccount);
  }

  @track accountSelected;
  hideResults(account) {
    let hideResults;
    this.accountSelected = account;
    if (account) {
      let accObj = { acc: account, newOrExistingAcc: "Existing" };
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
  closeModal() {
    const eventProps = {
      isModalOpen: false
    };
    const closeModal = new CustomEvent("closemodal", eventProps);
    this.dispatchEvent(closeModal);
  }
  handleDuplicateCancelClick(event) {
    this.duplicateResolverPayload = null;
  }

  clearBypassDuplicateRules() {
    this._bypassDuplicateRules = false;
  }

  get searchModalComputedClasses() {
    let classes = "slds-modal";
    if (!this.duplicateResolverPayload) {
      classes += " slds-fade-in-open";
    }
    if (!this.isMobile && this.variant === "plain") {
      classes += " convert-account-quick-action-modal";
    } //FRONT-4480
    return classes;
  }

  showEventForAddition(message = LABELS.TOASTMESSAGE) {
    if (this.parentcmp !== NEW_ACTION_OVERRIDE) {
      let addedTo =
        this.parentcmp === "quoterequireCustomLookup" ||
        this.parentcmp === "orderrequireCustomLookup"
          ? LABELS.CUSTOMER_INFO
          : LABELS.CART;
      const cEvent = new ShowToastEvent({
        title: "Success",
        message: message + " " + addedTo,
        variant: "success"
      });
      this.dispatchEvent(cEvent);
    }
  }

  // FRONT-3880, 4002, FRONT-3881, FRONT-3883Ends - Duplicate Detection Resolver

  handleSaveAndSelectClick(event) {
    this.isSaveAndSelect = true;
    this.handleSubmit(event);
  }

  selectAccountToCustomerInfo() {
    this.isSaveAndSelect = false;
    let recordTypeName = "Prospect";
    // FRONT-808 Starts
    if (this.isProspectOrGuestAccount) {
      recordTypeName = "Non-Credit";
    }
    // FRONT-808 Ends
    let paramData = {
      id: this.recordId,
      title: this.nameValue,
      Record_Type_Text__c: recordTypeName
    };

    let selectAccountEvent = new CustomEvent("selectaccount", {
      detail: paramData
    });
    this.dispatchEvent(selectAccountEvent);
  }
  handleSubmit(event) {
    //loadStyle(this, modalWidth);
    this.showSpinner = true;

    //START::Modified as part of FRONT-3223, FRONT-3224
    this.template.querySelectorAll("lightning-input").forEach((element) => {
      if (element.title === "Phone") {
        this.phonevalue = element.value;
      } else if (element.title === "email") {
        this.emailValue = element.value;
      } else if (element.title === "DOB") {
        this.dobValue = element.value;
      } else if (element.title == "Driver_s_License_State__c") {
        this.dlStateValue = element.value;
      } else if (element.title == "Drivers_License__c") {
        this.dlValue = element.value;
      }
    });
    //END::Modified as part of FRONT-3223, FRONT-3224

    this.template
      .querySelectorAll("lightning-input-field")
      .forEach((element) => {
        if (element.fieldName == "Driver_s_License_State__c") {
          this.dlStateValue = element.value;
        } else if (element.fieldName == "Drivers_License__c") {
          this.dlValue = element.value;
        } else if (element.fieldName == "Comments__c") {
          this.descriptionValue = element.value;
        } else if (element.fieldName == "PersonOtherPhone__c") {
          this.otherPhone = element.value;
        } else if (element.fieldName == "fax") {
          this.fax = element.value;
        } else if (element.fieldName == "Unique_Preferences_Hot_Buttons__c") {
          this.uniquePref = element.value;
        } else if (element.fieldName == "Rental_Opportunity__c") {
          this.rentalOpp = element.value;
        } else if (element.fieldName == "Other_Opportunity__c") {
          this.otherOpp = element.value;
        } else if (element.fieldName == "Preferred_method_of_Contact__c") {
          this.prefContact = element.value;
        } else if (element.fieldName == "Equipment_Preference__c") {
          this.equipPref = element.value;
        } else if (element.fieldName == "Primary_Equipment_Used__c") {
          this.primaryEquip = element.value;
        } else if (element.fieldName == "Specialty_Opportunity__c") {
          this.splOpp = element.value;
        } else if (element.fieldName == "Strategy_Last_Updated__c") {
          this.strategyUpdate = element.value;
        } else if (element.fieldName == "Other_Preferences__c") {
          this.otherPref = element.value;
        }
        //element.reportValidity();
      });

    //START:modified as part of FROMT-3224, 3223
    if (this.NonCreditrecordTypeId === this.currentRecordTypeId) {
      if (this.callValidateforProspect(event)) {
        this.showSpinner = false;
        if (
          this.emailValue != "" &&
          !this.emailValue.match(
            /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
          )
        ) {
          this.displayError(this.label.ERROR_TITLE, this.label.INVALID_EMAIL);
          this.isError = true;
          event.preventDefault();
        } else if (this.phonevalue != "" && this.phonevalue.length != 10) {
          if (!/^[0-9]+$/.test(this.phonevalue)) {
            this.displayError(
              this.label.ERROR_TITLE,
              this.label.INVALIDPHONEERRMSG
            );
            this.isError = true;
          }
          event.preventDefault();
        } else if (this.emailValue != "") {
          let msgTitle = this.label.REQUIRED_FIELD_MISSING_TITLE;
          let msgError = this.label.REQUIRED_FIELDS_MISSING;
          this.displayError(msgTitle, msgError);
          event.preventDefault();
        } else if (this.phonevalue != "") {
          let msgTitle = this.label.REQUIRED_FIELD_MISSING_TITLE;
          let msgError = this.label.REQUIRED_FIELDS_MISSING;
          this.displayError(msgTitle, msgError);
          event.preventDefault();
        }
      } else {
        this.callUpdateorCreatemethod();
      }
    } else {
      if (
        !this.lastName ||
        !this.firstName ||
        !this.nameValue ||
        !this.phonevalue ||
        !this.emailValue ||
        !this.dobValue ||
        !this.dlStateValue ||
        !this.dlValue
      ) {
        this.showSpinner = false;
        let msgTitle = this.label.REQUIRED_FIELD_MISSING_TITLE;
        let msgError = this.label.REQUIRED_FIELDS_MISSING;
        if (this.parentcmp === PARENTCMP) {
          this.errorTitle = msgTitle;
          this.errorMsg = msgError;
          this.displayToast = true;

          setTimeout(() => {
            this.displayToast = false;
          }, 3000);
        } else {
          this.displayError(msgTitle, msgError);
        }
        this.noError = true;
        event.preventDefault();
      } else if (
        this.strStreet == "" ||
        this.strCity == "" ||
        this.strState == "" ||
        this.strPostalCode == ""
      ) {
        logger.log("error here");
        this.showSpinner = false;
        let msgTitle = this.label.REQUIRED_FIELD_MISSING_TITLE;
        let msgError = this.label.REQUIRED_FIELDS_MISSING;
        if (this.parentcmp === PARENTCMP) {
          this.callCustomToastMsg(msgTitle, msgError);
        } else this.displayError(msgTitle, msgError);
        this.noError = true;
        event.preventDefault();
      } else if (this.dobValue) {
        this.showSpinner = false;
        // let dob = this.dobValue.split("-");
        // let yearEntered = parseInt(dob[0]);
        let today = new Date();
        today = today.toISOString().slice(0, 10);
        // let currentYear = today.split("-");
        // currentYear = parseInt(currentYear[0]);
        if (this.dobValue > today) {
          // if (this.parentcmp === PARENTCMP) {
          //   this.callCustomToastMsg(
          //     this.label.DOB_ERROR_TITLE,
          //     this.label.INVALID_DOB
          //   );
          // } else
          this.displayError(
            this.label.DOB_ERROR_TITLE,
            this.label.DOBValidation
          );
          this.noError = true;
        } else if (this.phonevalue != null) {
          if (!/^\d+$/.test(this.phonevalue)) {
            // if (this.parentcmp === PARENTCMP) {
            //   this.callCustomToastMsg(this.label.ERROR_TITLE, this.label.TEN_DIGIT_PHONE);
            // } else
            this.displayError(
              this.label.ERROR_TITLE,
              this.label.INVALIDPHONEERRMSG
            );
            this.noError = true;
          } else if (this.phonevalue.length !== 10) {
            // if (this.parentcmp === PARENTCMP) {
            //   this.callCustomToastMsg(
            //     this.label.ERROR_TITLE,
            //     this.label.TEN_DIGIT_PHONE
            //   );
            // } else
            this.displayError(
              this.label.ERROR_TITLE,
              this.label.TEN_DIGIT_PHONE
            );
            this.noError = true;
          } else if (
            !this.emailValue.match(
              /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
            )
          ) {
            // if (this.parentcmp === PARENTCMP) {
            //   this.callCustomToastMsg(this.label.ERROR_TITLE, this.label.INVALID_EMAIL);
            // } else
            this.displayError(this.label.ERROR_TITLE, this.label.INVALID_EMAIL);
            this.noError = true;
          } else if (Object.keys(this._lengthExceededFields).length > 0) {
            this.displayError(
              this.label.ERROR_TITLE,
              "Review and resolve the errors specified."
            );
            this.noError = true;
          } else {
            this.noError = false;
          }
        } else {
          this.noError = false;
        }
      } else {
        this.noError == false;
      }
      if (this.noError == false) {
        this.callUpdateorCreatemethod();
      }
    }
  }
  //END:modified as part of FROMT-3224, 3223

  /* START::Modified as part of FRONT-3224 */
  checkOnBlur(event) {
    const field = event.target.name;
    if (field === "Phone") {
      this.vaidateOnBlur(event);
    } else if (field === "email") {
      this.vaidateOnBlur(event);
    }
  }
  vaidateOnBlur(event) {
    let value = event.target.value;
    let hasError = false;
    if (event.target.title === "Phone") {
      const regex = /^\d+$/;
      if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.USE_NUMBERS_ONLY);
        event.target.reportValidity();
        hasError = true;
      }
    } else if (event.target.title === "email") {
      const regex =
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.INVALID_EMAIL_FORMAT);
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
  /* END::Modified as part of FRONT-3224 */

  callCustomToastMsg(msgTitle, msgError) {
    this.errorTitle = msgTitle;
    this.errorMsg = msgError;
    this.displayToast = true;

    setTimeout(() => {
      this.displayToast = false;
    }, 1000);
  }
  async callUpdateorCreatemethod() {
    this.showSpinner = true;
    const fields = {};
    fields[NAME_FIELD.fieldApiName] = this.nameValue;
    fields[PHONE_FIELD.fieldApiName] = this.phonevalue;
    fields[EMAIL.fieldApiName] = this.emailValue;
    // FRONT-808 Starts - Added guest check as well while conversion
    if (this.isProspectOrGuestAccount) {
      fields[ACCOUNTTYPE_FIELD.fieldApiName] = this.NonCreditrecordTypeId;
      fields[ID_FIELD.fieldApiName] = this.recordId;
      fields[DRIVERS_LICENSE.fieldApiName] = this.dlValue;
      fields[DRIVERS_LICENSE_STATE.fieldApiName] = this.dlStateValue;
      fields[BIRTH_DATE.fieldApiName] = this.dobValue;
      fields[BILLING_STREET.fieldApiName] = this.strStreet;
      fields[CITY_FIELD.fieldApiName] = this.strCity;
      fields[POSTALCODE_FIELD.fieldApiName] = this.strPostalCode;
      fields[COUNTRY_FIELD.fieldApiName] = this.strCountry;
      fields[STATE_FIELD.fieldApiName] = this.strState;
      fields[DESCRIPTION.fieldApiName] = this.descriptionValue;
      fields[ACCOUNT_STATUS_FIELD.fieldApiName] = ACTIVE_STATUS;
    } else if (this.NonCreditrecordTypeId === this.currentRecordTypeId) {
      fields[ACCOUNTTYPE_FIELD.fieldApiName] = this.prospectrecordTypeId;
      fields[SHIPPING_STREET.fieldApiName] = this.strStreet;
      fields[COUNTRY_CODE_PROSPECT.fieldApiName] = this.strCountry;
      fields[SHIPPING_CITY.fieldApiName] = this.strCity;
      fields[state_code_prospect.fieldApiName] = this.strState;
      fields[SHIPPING_ZIP.fieldApiName] = this.strPostalCode;
      fields[PARENT_ACCOUNT.fieldApiName] = this.parentId;
      fields[OTHER_PHONE.fieldApiName] = this.otherPhone;
      fields[FAX.fieldApiName] = this.fax;
      //fields[CREDIT_CODE_DESC.fieldApiName] = this.creditCodeDesc;
      fields[UNIQUE_PREFERENCE.fieldApiName] = this.uniquePref;
      fields[RENTAL_OPPORTUNITY.fieldApiName] = this.rentalOpp;
      fields[OTHER_OPPORTUNITY.fieldApiName] = this.otherOpp;
      fields[PREFERRED_CONTACT_METHOD.fieldApiName] = this.prefContact;
      fields[EQUIPMENT.fieldApiName] = this.equipPref;
      fields[PRIMARY_EQUIPMENT.fieldApiName] = this.primaryEquip;
      fields[SPECIALITY_OPPORTUNITY.fieldApiName] = this.spOpp;
      fields[STRATEGY.fieldApiName] = this.strategyUpdate;
      fields[OTHER_PREFERENCE.fieldApiName] = this.otherPref;
    }
    // braces open
    // FRONT-808 Starts
    if (this.isProspectOrGuestAccount) {
      // FRONT-808 Ends
      const recordInput = {
        apiName: ACCOUNT_OBJECT,
        fields: fields
      };
      let recordIn = fields;
      let message = LABELS.CONVERTEDACCOUNTTOAST;
      //FRONT 3880 , 4002,FRONT-3881, FRONT-3883 Start
      updateSObject({
        record: recordIn,
        allowDuplicateRule: this._bypassDuplicateRules
      })
        .then((result) => {
          this.showSpinner = false;
          if (result && result.isSuccess) {
            //front-4001, 4002, FRONT-3881, FRONT-3883
            this.accountId = result.attributes?.record?.Id;
            this.createNewContact();

            if (
              this.parentcmp === "quoterequireCustomLookup" ||
              this.parentcmp === "orderrequireCustomLookup" ||
              this.parentcmp === "customLookup"
            ) {
              let addedTo =
                this.parentcmp === "quoterequireCustomLookup" ||
                this.parentcmp === "orderrequireCustomLookup"
                  ? LABELS.CUSTOMER_INFO
                  : LABELS.CART;
              const newEvent = new ShowToastEvent({
                title: "Success",
                message: message + " " + addedTo,
                variant: "success"
              });
              this.dispatchEvent(newEvent);
            } else if (this.parentcmp === PARENTCMP) {
              //FRONT 4001
              if (
                this.parentcmp !== "quoterequireCustomLookup" &&
                this.parentcmp !== "orderrequireCustomLookup" &&
                this.parentcmp !== "customLookup"
              ) {
                this.displayToast = true;
                this.showSuccessToast = true;
                this.successTitle = "Success";
                this.errorMsg = "";
                this.errorTitle = "";
                this.successMsg =
                  fields[NAME_FIELD.fieldApiName] +
                  " converted from Prospect to Non-Credits";
              }
            } else if (this.variant === "plain") {
              // FRONT-808 Starts
              const newEvent = new ShowToastEvent({
                title: "Success",
                message: `${fields[NAME_FIELD.fieldApiName]} converted from ${
                  this.recordTypeName
                }  to Non-Credit`,
                variant: "success"
              });
              // FRONT-808 Ends
              this.dispatchEvent(newEvent);
              //started for Front 84
              notifyRecordUpdateAvailable([{ recordId: this.accountId }]);
              this[NavigationMixin.Navigate](
                {
                  type: "standard__recordPage",
                  attributes: {
                    recordId: this.accountId,
                    objectApiName: "Account",
                    actionName: "view"
                  }
                },
                true
              );
              //Ended for Front 84
              this.dispatchEvent(new CustomEvent("close"));
            }
            //start for FRONT-4481
            else if (this.parentcmp === "ActionButton") {
              // FRONT-808 Starts
              const newEvent = new ShowToastEvent({
                title: "Success",
                message: `${fields[NAME_FIELD.fieldApiName]} converted from ${
                  this.recordTypeName
                }  to Non-Credit`,
                variant: "success"
              });
              // FRONT-808 Ends
              this.dispatchEvent(newEvent);
            }
            //End for FRONT-4481
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
              this.refreshParentComponent();
              this.handleCancelClick();
              //If clicked on 'Save & Select' - Then after saving and updating the record, select the record as well in the Customer Info field
              if (this.isSaveAndSelect) {
                this.selectAccountToCustomerInfo();
              }
            }, 2000);
          } else {
            if (result.message === DUPLICATE_ERROR_CODE) {
              // FRONT-808
              if (this.isProspectOrGuestAccount) {
                //logger.log(result.attributes?.duplicateRecordIds)
                //FRONT-4600
                this.buildDuplicateErrorPayload(
                  result.attributes?.duplicateRecordIds,
                  result.attributes?.duplicateRuleName,
                  result.attributes?.duplicateRecords,
                  recordIn
                );
              } else {
                this.displayError(LABELS.DUPLICATE_ACCOUNT, result.message);
              }
            } else {
              this.displayError(LABELS.ERROR_OCCURED, result.message);
            }
          }
        })
        .catch((error) => {
          this.isLoading = false;
        })
        .finally(() => {
          this.isLoading = false;
        });
    } else if (this.NonCreditrecordTypeId === this.currentRecordTypeId) {
      const recordInputforCreate = {
        apiName: ACCOUNT_OBJECT.objectApiName,
        fields: fields
      };
      createRecord(recordInputforCreate)
        .then((account) => {
          this.dispatchEvent(new CustomEvent("close"));
          this.showSpinner = false;
          this.accountId = account.id;

          const cEvent = new ShowToastEvent({
            title: "Success",
            message: "Account request submitted.",
            variant: "success"
          });
          this.dispatchEvent(cEvent);

          this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: this.accountId,
              objectApiName: "Account",
              actionName: "view"
            }
          });

          // this.closeModal();
        })
        .catch((error) => {
          let errmessage = "";

          if (error.body.output.errors[0].errorCode != null) {
            errmessage = error.body.output.errors[0].errorCode;
          } else {
            errmessage = error.body.message;
          }
          this.showSpinner = false;
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error creating record",
              message: errmessage,
              variant: "error"
            })
          );
        });
    }
  }
  refreshParentComponent() {
    let refreshAccountListViewComponent = new CustomEvent("refreshcomponent");
    this.dispatchEvent(refreshAccountListViewComponent);
  }
  createNewContact() {
    const conFields = {};
    conFields[CONTACT_ACCOUNT_ID.fieldApiName] = this.accountId;
    conFields[CONTACT_FIRST_NAME.fieldApiName] = this.firstName;
    conFields[CONTACT_LAST_NAME.fieldApiName] = this.lastName;
    conFields[CONTACT_EMAIL.fieldApiName] = this.emailValue;
    conFields[CONTACT_PHONE_NUMBER.fieldApiName] = this.phonevalue;
    conFields[CONTACT_MAILING_STATE.fieldApiName] = this.strState;
    conFields[CONTACT_MAILING_CITY.fieldApiName] = this.strCity;
    conFields[CONTACT_MAILING_STREET.fieldApiName] = this.strStreet;
    conFields[CONTACT_MAILING_POSTAL_CODE.fieldApiName] = this.strPostalCode;
    conFields[CONTACT_MAILING_COUNTRY.fieldApiName] = this.strCountry;
    conFields[CONTACT_DL_NUMBER.fieldApiName] = this.dlValue;
    conFields[CONTACT_DL_STATE.fieldApiName] = this.dlStateValue;
    conFields[CONTACT_PRIMARY.fieldApiName] = true;

    const contactRecord = conFields;
    contactRecord.sobjectType = CONTACT_OBJECT.objectApiName;
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
  //modified as part of FRONT-3224
  callValidateforProspect(event) {
    if (this.nameValue == undefined || this.nameValue == "") {
      return true;
    } else if (this.phonevalue == "" && this.emailValue == "") {
      let phoneComp =
        this.template.querySelector(".prospectPhone") == null
          ? this.template.querySelector(".nonCreditPhone")
          : this.template.querySelector(".prospectPhone");
      let emailComp =
        this.template.querySelector(".prospectEmail") == null
          ? this.template.querySelector(".nonCreditEmail")
          : this.template.querySelector(".prospectEmail");

      phoneComp.setCustomValidity(this.label.EITHER_PHONE_EMAIL);
      phoneComp.reportValidity();

      emailComp.setCustomValidity(this.label.EITHER_PHONE_EMAIL);
      emailComp.reportValidity();
      this.isError = true;
      event.preventDefault();
      return true;
    } else if (
      this.emailValue != "" &&
      !this.emailValue.match(
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
      )
    ) {
      this.displayError(this.label.ERROR_TITLE, this.label.INVALID_EMAIL);
      this.isError = true;
      event.preventDefault();
      return true;
    } else if (this.phonevalue != "" && this.phonevalue.length != 10) {
      if (!/^[0-9]+$/.test(this.phonevalue)) {
        this.displayError(
          this.label.ERROR_TITLE,
          this.label.INVALIDPHONEERRMSG
        );
        this.isError = true;
      } else {
        this.displayError(this.label.ERROR_TITLE, this.label.TEN_DIGIT_PHONE);
        this.isError = true;
      }
      return true;
      //event.preventDefault();

      event.preventDefault();
    } else if (
      this.strStreet == undefined ||
      this.strCity == undefined ||
      this.strCountry == undefined ||
      this.strState == undefined ||
      this.strPostalCode == undefined ||
      this.strStreet == "" ||
      this.strCity == "" ||
      this.strCountry == "" ||
      this.strState == "" ||
      this.strPostalCode == ""
    ) {
      return true;
    }
  }

  handleError(event) {
    const evt = new ShowToastEvent({
      title: "Error!",
      message: event.detail.detail,
      variant: "error",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }
  addressInputChange(event) {
    console.log("this street::" + event.target.street);
    this.strStreet = event.target.street;
    this.strCity = event.target.city;
    this.strState = event.target.province;
    this.strCountry = event.target.country;
    console.log("con:" + event.target.country);
    this.strPostalCode = event.target.postalCode;
    // FRONT-3942 Start
    this.validateAddress(event);
    // FRONT-3942 End
  }

  displayError(msgTitle, msgError) {
    const newEvent = new ShowToastEvent({
      title: msgTitle,
      message: msgError,
      variant: "error"
    });
    this.dispatchEvent(newEvent);
  }
  handleCancel() {
    this.dispatchEvent(new CustomEvent("close"));
  }
  closeToast(event) {
    this.displayToast = false;
  }

  /*START: FRONT-3223*/
  handleDOBBlur(event) {
    const fieldTitle = event.target.title;
    switch (fieldTitle) {
      case "DOB":
        this.validateDOB(event);
        break;
    }
  }

  get dateOfBirthOverFlowMessage() {
    let vartoday = new Date();
    let options = { month: "2-digit", day: "2-digit", year: "numeric" };
    let formattedDate = vartoday.toLocaleDateString("en-US", options);
    console.log(formattedDate);
    return `Date must be ${formattedDate} or earlier.`;
  }

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
  /*END: FRONT-3223*/

  // FRONT-3942 Start
  validateAddress(event) {
    let addressFields = ["street", "city", "postalCode"];
    for (let field of addressFields) {
      if (FIELD_LENGTH_CONFIG_MAPPING[field]) {
        let currentFieldValue = event.target[field];
        this.validateField(field, currentFieldValue, event);
      }
    }
  }

  validateMaxLength(fieldName, fieldValue, event) {
    let fieldConfig = FIELD_LENGTH_CONFIG_MAPPING[fieldName];
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
      if (!hasExceededMaxLength) {
        event.target.setCustomValidityForField("", fieldName);
        event.target.reportValidity();
      } else {
        event.target.setCustomValidityForField(fieldConfig.message, fieldName);
        event.target.reportValidity();
      }
    } else if (event.target.setCustomValidity) {
      if (!hasExceededMaxLength) {
        event.target.setCustomValidity("");
      } else {
        event.target.setCustomValidity(fieldConfig.message);
      }
      event.target.reportValidity();
    }
    if (!hasExceededMaxLength) {
      this.removeFieldFromLengthExceededStack(fieldName);
    } else {
      this.addFieldToLengthExceededStack(fieldName);
    }
  }

  //START: FRONT-4567
  validateField(fieldName, fieldValue, event) {
    let fieldConfig = FIELD_LENGTH_CONFIG_MAPPING[fieldName];
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
      if (currentFieldValueLength === 0) {
        event.target.setCustomValidityForField(
          "Complete this field.",
          fieldName
        );
        event.target.reportValidity();
      } else if (!hasExceededMaxLength) {
        event.target.setCustomValidityForField("", fieldName);
        event.target.reportValidity();
      } else {
        event.target.setCustomValidityForField(fieldConfig.message, fieldName);
        event.target.reportValidity();
      }
    } else if (event.target.setCustomValidity) {
      if (!hasExceededMaxLength) {
        event.target.setCustomValidity("");
      } else {
        event.target.setCustomValidity(fieldConfig.message);
      }
      event.target.reportValidity();
    }
    if (!hasExceededMaxLength) {
      this.removeFieldFromLengthExceededStack(fieldName);
    } else {
      this.addFieldToLengthExceededStack(fieldName);
    }
  } //END : FRONT-4567

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
  //FRONT-4600 start
  handleDuplicateHardStopCancel() {
    this.handleCancel();
  }
  //FRONT-4600 end

  setAccountName() {
    let accName = [this.lastName, this.firstName].filter(Boolean).join(", ");
    this.nameValue = accName.trim();
    if (
      this.nameValue.length > 30 &&
      this.lastName !== "" &&
      this.lastName.length > 25 &&
      this.firstName.length >= 3
    ) {
      this.nameValue = [this.lastName.slice(0, 25), this.firstName.slice(0, 3)]
        .filter(Boolean)
        .join(", ");
    } else if (
      this.lastName === "" &&
      this.firstName !== "" &&
      this.nameValue.length > 30
    ) {
      this.nameValue = this.firstName.slice(0, 30);
    } else if (this.firstName === "") {
      this.nameValue = this.lastName.slice(0, 30);
    } else if (
      this.nameValue.length > 30 &&
      this.firstName !== "" &&
      this.lastName.length > 25 &&
      this.firstName.length >= 3
    ) {
      this.nameValue = [this.lastName.slice(0, 25), this.firstName.slice(0, 3)]
        .filter(Boolean)
        .join(", ");
    } else if (
      this.firstName === "" &&
      this.lastName !== "" &&
      this.nameValue.length > 30
    ) {
      this.nameValue = this.lastName.slice(0, 30);
    } else if (this.lastName === "") {
      this.nameValue = this.firstName.slice(0, 30);
    } else {
      if (this.firstName.length < 3) {
        this.nameValue = [
          this.lastName.slice(0, 28 - this.firstName.length),
          this.firstName.slice(0, this.firstName.length)
        ]
          .filter(Boolean)
          .join(", ");
      } else {
        this.nameValue = [
          this.lastName.slice(0, 25),
          this.firstName.slice(0, 28 - this.lastName.length)
        ]
          .filter(Boolean)
          .join(", ");
      }
    }
    return this.nameValue;
  }

  /**
   * FRONT-808 Start
   */
  get convertToNCAccountLabel() {
    return this.currentRecordTypeId === this.prospectrecordTypeId
      ? this.label.convertToNCAccount
      : "Convert Guest To Non-Credit";
  }

  setGuestRecordTypeId(rtis) {
    this.guestRecordTypeId = Object.keys(rtis).find(
      (rti) => rtis[rti].name === "Guest"
    );
  }

  get isProspectOrGuestAccount() {
    return (
      this.currentRecordTypeId === this.prospectrecordTypeId ||
      this.currentRecordTypeId === this.guestRecordTypeId
    );
  }

  /**
   * FRONT-808 End
   */
  /* FRONT-18942 - Added code to hide extra close icon when called from AURA quick actions - Starts */
  removeDefaultCloseIconView() {
    if (!this.rendered && this.variant === "plain") {
      this.rendered = true;
      let customStyle = `.closeIcon{
              display : none !important;
            }`;
      const rootNode = this.template.ownerDocument;
      this.customStyleDivElement = rootNode.createElement("div");
      const styleNode = rootNode.createElement("style");
      if (styleNode.styleSheet) {
        styleNode.styleSheet.cssText = customStyle;
      } else {
        styleNode.appendChild(rootNode.createTextNode(customStyle));
      }
      this.customStyleDivElement.appendChild(styleNode);
      rootNode.body.appendChild(this.customStyleDivElement);
    }
  }
  disconnectedCallback() {
    this.unsetDefaultCloseIconView();
  }
  unsetDefaultCloseIconView() {
    this.customStyleDivElement?.remove();
  }
  /* FRONT-18942 Ends */
}