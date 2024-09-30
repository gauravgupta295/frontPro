import { LightningElement, api, wire, track } from "lwc";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import {
  getRecord,
  getFieldValue,
  updateRecord,
  notifyRecordUpdateAvailable
} from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import ACCOUNT_FIELDS from "./accountSchema";
import CONTACT_FIELDS from "./contactSchema";
import editAccountDesktopTemplate from "./editAccountDesktop.html";
import editAccountMobileTemplate from "./editAccountMobile.html";
import editAccountDesktopFromQuickActionTemplate from "./editAccountDesktopFromQuickAction.html";
import Sbr_3_0_address_Css from "@salesforce/resourceUrl/Sbr_3_0_AddressCss"; //FRONT-2620
import updateSObject from "@salesforce/apex/SBR_3_0_DMLOpsController.updateSObject"; //FRONT-3878
import { refreshApex } from "@salesforce/apex";
import {
  isEmpty,
  isUndefined,
  isUndefinedOrNull
} from "c/sbr_3_0_frontlineUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
const NON_CREDIT_RECORD_TYPE_NAME = "Non-Credit";
const PROSPECT_RECORD_TYPE_NAME = "Prospect";
const PROSPECT_RECORD_TYPE_FIELDS = [
  ACCOUNT_FIELDS.NAME_FIELD,
  ACCOUNT_FIELDS.PHONE_FIELD,
  ACCOUNT_FIELDS.EMAIL_FIELD,
  ACCOUNT_FIELDS.DESCRIPTION_FIELD,
  ACCOUNT_FIELDS.SHIPPING_STREET_FIELD,
  ACCOUNT_FIELDS.SHIPPING_CITY_FIELD,
  ACCOUNT_FIELDS.SHIPPING_COUNTRY_CODE_FIELD,
  ACCOUNT_FIELDS.SHIPPING_STATE_CODE_FIELD,
  ACCOUNT_FIELDS.SHIPPING_POSTALCODE_FIELD,
  ACCOUNT_FIELDS.ACCOUNTTYPE_FIELD
];
const NON_CREDIT_RECORD_TYPE_FIELDS = [
  ACCOUNT_FIELDS.NAME_FIELD,
  ACCOUNT_FIELDS.PHONE_FIELD,
  ACCOUNT_FIELDS.EMAIL_FIELD,
  ACCOUNT_FIELDS.DESCRIPTION_FIELD,
  ACCOUNT_FIELDS.BILLING_STREET_FIELD,
  ACCOUNT_FIELDS.BILLING_CITY_FIELD,
  ACCOUNT_FIELDS.BILLING_COUNTRY_FIELD,
  ACCOUNT_FIELDS.BILLING_STATE_FIELD,
  ACCOUNT_FIELDS.BILLING_POSTALCODE_FIELD,
  ACCOUNT_FIELDS.ACCOUNTTYPE_FIELD,
  ACCOUNT_FIELDS.DRIVERS_LICENSE_FIELD,
  ACCOUNT_FIELDS.DRIVERS_LICENSE_STATE_FIELD,
  ACCOUNT_FIELDS.BIRTH_DATE_FIELD
];
const RECORD_TYPE_TO_FIELD_MAPPING = {
  [NON_CREDIT_RECORD_TYPE_NAME]: NON_CREDIT_RECORD_TYPE_FIELDS,
  [PROSPECT_RECORD_TYPE_NAME]: PROSPECT_RECORD_TYPE_FIELDS
};
const MODAL_HEADER_PREFIX = "Edit Account"; //20281
const INFORMATION_HEADER = "General Info ";
const CONTACT_FIELD_TO_QUERY = [
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_FIELDS.CONTACT_FIRST_NAME_FIELD.fieldApiName}`,
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_FIELDS.CONTACT_LAST_NAME_FIELD.fieldApiName}`,
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_FIELDS.ID_FIELD.fieldApiName}`
];
const CONTACT_RECORD_FIELDS = [
  CONTACT_FIELDS.CONTACT_FIRST_NAME_FIELD,
  CONTACT_FIELDS.CONTACT_LAST_NAME_FIELD,
  CONTACT_FIELDS.ID_FIELD
];

const PRIMARY_CONTACT_WHERE_CLAUSE = `{  ${CONTACT_FIELDS.CONTACT_PRIMARY_FIELD.fieldApiName}: { eq: true }}] }`;

//Custom labels
import BILLINGINFO from "@salesforce/label/c.SBR_3_0_BillingInfo";
import GENERALINFO from "@salesforce/label/c.SBR_3_0_GeneralInfo";
import CONFIRSTNAME from "@salesforce/label/c.SBR_3_0_ContactFirstname";
import CONLASTNAME from "@salesforce/label/c.SBR_3_0_ContactLastname";
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
import CANCEL from "@salesforce/label/c.SBR_3_0_Cancel";
import SAVE from "@salesforce/label/c.SBR_3_0_Save";
import SHIP_COUNTRY from "@salesforce/label/c.SBR_3_0_Country";
import SHIP_STREET from "@salesforce/label/c.SBR_3_0_Street";
import SHIP_CITY from "@salesforce/label/c.SBR_3_0_City";
import SHIP_STATE from "@salesforce/label/c.SBR_3_0_State";
import SHIP_ZIPCODE from "@salesforce/label/c.SBR_3_0_Zipcode";
import CLOSE from "@salesforce/label/c.SBR_3_0_Close";
import SELECT_BILL_ADDRS from "@salesforce/label/c.SBR_3_0_SelectBillingAddr";
import SELECT_STREET_ADDRESS from "@salesforce/label/c.SBR_3_0_SelectShippingAddrs";
import ADDRESSINFO from "@salesforce/label/c.SBR_3_0_ShippingInfo";
import CONTACTINFO from "@salesforce/label/c.SBR_3_0_ContactInfo";
import INVALIDEMAILERRMSG from "@salesforce/label/c.SBR_3_0_InvalidEmailErrorMsg";
import REQUIREDFIELDSERRMSG from "@salesforce/label/c.SBR_3_0_RequireFIeldsErrorMsg";
import REQUIREDFIELDSERRTITLE from "@salesforce/label/c.SBR_3_0_RequireFIeldsErrTitle";
import INVALIDPHONEERRMSG from "@salesforce/label/c.SBR_3_0_InvalidPhoneErrorMsg";
import PHONEERRMSG from "@salesforce/label/c.SBR_3_0_10DigitPhnErrorMsg";
import DOBERRMSG from "@salesforce/label/c.SBR_3_0_DOBErrMsg";
import ERRTITLE from "@salesforce/label/c.SBR_3_0_ErrorTitle";
import DOBERRTITLE from "@salesforce/label/c.SBR_3_0_DOBErrTitle";
import PHONENUMONLYERR from "@salesforce/label/c.SBR_3_0_PhoneNumbersOnlyErr";
import EMAILINVALIDFORMATERR from "@salesforce/label/c.SBR_3_0_InvalidEmailFormatErr";
import DOBValidation from "@salesforce/label/c.DOB_Validation";
import SAVE_AND_SELECT from "@salesforce/label/c.SBR_3_0_SaveAndSelect";
import SEARCH_ADDRESS from "@salesforce/label/c.Search_Address";
import { loadStyle } from "lightning/platformResourceLoader";
import Sbr_3_0_customModalCmp_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmp_Css";
import Sbr_3_0_customModalCmpDesktop_Css from "@salesforce/resourceUrl/Sbr_3_0_customModalCmpDesktop_Css";
const ERROR_STACK = ["badInput", "valueMissing"]; //3223

//FRONT-3878 ,4001 Starts
const DUPLICATE_ERROR_CODE = "DUPLICATES_DETECTED";
const NEW_RESOLUTION = "new";
const EXISTING_RESOLUTION = "existing";
import LABELS from "c/sbr_3_0_customLabelsCmp";
// FRONT-3878 ,4001 Ends
// FRONT-3545 Start
const FIELD_LENGTH_CONFIG_MAPPING = {
  street: {
    maxLength: 30,
    message: LABELS.STREETLIMIT
  },
  city: {
    maxLength: 20,
    message: LABELS.CITYLIMIT
  },
  postalCode: {
    maxLength: 10,
    message: LABELS.ZIPCODELIMIT
  },
  Comments__c: {
    maxLength: 40,
    message: LABELS.COMMENTLIMIT
  }
};

// FRONT-3545 End

export default class Sbr_3_0_editAccountCmp extends LightningElement {
  _props;
  @api
  get props() {
    return this._props;
  }

  set props(value) {
    this._props = value;
    this.init();
  }

  _recordId;
  _recordTypeId;
  _recordTypeName;
  _fields;
  _contactFields;
  _accountWiredResult;
  _contactWiredResult;
  informationHeader = INFORMATION_HEADER;
  _initialAccountRecord;
  @track
  accountRecord;
  _initialContactRecord;
  @track
  contactRecord;
  isLoading = true;
  countryOptions;
  dlOptions;
  @api recordId;
  isMobile;
  isNewRender = true;
  fromRecordPage = false;
  today = new Date().toISOString().slice(0, 10); //FRONT 3223
  //FRONT-3878 ,4001 Starts
  duplicateResolverPayload;
  _bypassDuplicateRules = false;
  isTransactionFlow = true; //FRONT - 4466
  @api parentcmp = "ActionButton"; //FRONT - 4469
  screenName = "EditScreen";
  // FRONT-3878 ,4001 Ends
  // START FRONT-20757 & FRONT-20761
  drfAccountWrapper = false;
  mobileProps = {
    fullScreen: true
  };
  activeSections = ["General Info", "Billing Info"];
  // END FRONT-20757 & FRONT-20761

  //START: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125
  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    if (this.isMobile) {
      loadStyle(this, Sbr_3_0_customModalCmp_Css);
    } else {
      loadStyle(this, Sbr_3_0_customModalCmpDesktop_Css);
    }
    // Addded if for FRONT-20757 & FRONT-20761
    if (this.parentcmp === "drfAccountLookupWrapper") {
      this.drfAccountWrapper = true;
    }
  }

  render() {
    if (this.isMobile) {
      return editAccountMobileTemplate;
    } else {
      if (this.fromRecordPage) {
        return editAccountDesktopFromQuickActionTemplate;
      } else {
        return editAccountDesktopTemplate;
      }
    }
  }

  renderedCallback() {
    if (this.isMobile) {
      let input;
      if (
        this._recordTypeName === PROSPECT_RECORD_TYPE_NAME &&
        this.isNewRender
      ) {
        input = this.template.querySelector('[data-id="prospectAccount"]');
      } else if (
        this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME &&
        this.isNewRender
      ) {
        input = this.template.querySelector('[data-id="contactFirstName"]');
      }
      if (input) {
        input.focus();
        this.isNewRender = false;
      }
    }
    //START: FRONT-2620
    Promise.all([loadStyle(this, Sbr_3_0_address_Css)])
      .then(() => {})
      .catch((error) => {}); ////END: FRONT-2620
    /*FRONT-18942 Starts */
    this.removeDefaultCloseIconView();
    /*FRONT-18942 Ends */
  }
  //END: FRONT-3033, FRONT-2621, FRONT- 3115, FRONT-3125

  errorMsg = "";
  errorTitle = "";
  showCustomToastMessage = false;
  isError = false;
  isSaveAndSelect = false;
  showsuccess = false;
  successmesg;
  successtitl;

  label = {
    DOBValidation,
    BILLINGINFO,
    GENERALINFO,
    CONFIRSTNAME,
    CONLASTNAME,
    ACCOUNTNAME,
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
    CANCEL,
    SAVE,
    SHIP_COUNTRY,
    SHIP_STREET,
    SHIP_CITY,
    SHIP_STATE,
    SHIP_ZIPCODE,
    CLOSE,
    SELECT_BILL_ADDRS,
    ADDRESSINFO,
    CONTACTINFO,
    INVALIDEMAILERRMSG,
    REQUIREDFIELDSERRMSG,
    REQUIREDFIELDSERRTITLE,
    INVALIDPHONEERRMSG,
    PHONEERRMSG,
    ERRTITLE,
    DOBERRMSG,
    DOBERRTITLE,
    PHONENUMONLYERR,
    EMAILINVALIDFORMATERR,
    SAVE_AND_SELECT,
    SELECT_STREET_ADDRESS,
    SEARCH_ADDRESS // START FRONT-12393
  };

  _lengthExceededFields = {};
  @wire(getRecord, { recordId: "$_recordId", fields: "$_fields" })
  accountRecordWired(value) {
    this._accountWiredResult = value;
    const { data, error } = value;
    if (error) {
      console.log("accountRecordWired error");
      // TODO : Hanlde ERROR
    } else if (data) {
      this.buildAccountRecord(data);
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: "$_recordId",
    relatedListId: "Contacts",
    fields: "$_contactFields",
    where: PRIMARY_CONTACT_WHERE_CLAUSE,
    pageSize: 1
  })
  contactRecordWired(value) {
    this._contactWiredResult = value;
    const { error, data } = value;
    if (data && data.records.length > 0) {
      this.buildContactRecord(data.records[0]);
      this.error = undefined;
    } else if (data) {
      this.contactRecord = {};
    } else if (error) {
      // TODO : Hanlde ERROR
      this.error = error;
    }
  }

  @wire(getPicklistValuesByRecordType, {
    objectApiName: ACCOUNT_OBJECT,
    recordTypeId: "$_recordTypeId"
  })
  accountPicklistValuesWired({ error, data }) {
    if (data) {
      this.buildCountryOptions(data.picklistFieldValues.BillingCountryCode);
      this.buildCountryToStateMap(data.picklistFieldValues.BillingStateCode);
      this.buildDLStateOptions(
        data.picklistFieldValues.Driver_s_License_State__c
      );
    } else if (error) {
      //TODO Add error handling
    }
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

  init() {
    const { recordTypeName, recordId, recordTypeId, fromRecordPage } =
      this.props;
    this._recordTypeName = recordTypeName;
    this._recordTypeId = recordTypeId;
    this._recordId = recordId;
    this.fromRecordPage = fromRecordPage;

    this._fields = RECORD_TYPE_TO_FIELD_MAPPING[this._recordTypeName];
    if (this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME) {
      this._contactFields = CONTACT_FIELD_TO_QUERY;
    }
  }
  get headerLabel() {
    let recordTypeName = "";
    if (this._recordTypeName) {
      recordTypeName = `: ${this._recordTypeName}`; //modified for 20281,20282
    }
    return `${MODAL_HEADER_PREFIX}${recordTypeName}`;
  }

  get showProspectForm() {
    return (
      this.accountRecord && this._recordTypeName === PROSPECT_RECORD_TYPE_NAME
    );
  }

  get showNonCreditForm() {
    return (
      this.accountRecord &&
      this.contactRecord &&
      this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME
    );
  }

  buildAccountRecord(data) {
    const accountRecord = {};
    for (let field of this._fields) {
      accountRecord[field.fieldApiName] = getFieldValue(data, field);
    }
    this.accountRecord = accountRecord;
    this._initialAccountRecord = Object.assign({}, this.accountRecord);
    this.isLoading = false;
  }
  buildContactRecord(data) {
    const contactRecord = {};
    for (let field of CONTACT_RECORD_FIELDS) {
      contactRecord[field.fieldApiName] = getFieldValue(data, field);
    }
    if (this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME) {
      let accName = contactRecord.LastName + ", " + contactRecord.FirstName;
      this.accountRecord.Name = accName.trim();
    }
    this.contactRecord = contactRecord;
    this._initialContactRecord = Object.assign({}, this.contactRecord);
    this.isLoading = false;
  }

  //Method created for 'onBlur' event
  handleFieldFocusOut(event) {
    const fieldName = event.target.name || event.target.dataset.name;
    // eslint-disable-next-line default-case
    switch (fieldName) {
      case ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName:
        this.validateFieldsOnBlur(event);
        break;

      case ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName:
        this.validateFieldsOnBlur(event);
        break;

      case ACCOUNT_FIELDS.BIRTH_DATE_FIELD.fieldApiName:
        this.validateDOB(event);
        break;

      // FRONT-3545 Start
      case ACCOUNT_FIELDS.BILLING_ADDRESS:
        this.handleAddressMessage(event); //added as part of FRONT-18234
        this.validateAddress(event);

        break;

      case ACCOUNT_FIELDS.SHIPPING_ADDRESS:
        this.handleAddressMessage(event); //added as part of FRONT-18234
        this.validateAddress(event);

        break;

      case ACCOUNT_FIELDS.DESCRIPTION_FIELD.fieldApiName:
        this.validateComment(event);
        break;
      // FRONT-3545 End
    }
    let { record, field, value } = this.getSetterConfigs(event);
    this.setFieldValue(record, field, value);
  }

  validateDOB(event) {
    //START: FRONT-3223
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
    //END: FRONT-3223
  }

  //Validations on Phone and Email field on 'onBlur' event
  validateFieldsOnBlur(event) {
    let hasError = false;
    let value = event.target.value;
    /*  if(isEmpty(value)){
      event.target.setCustomValidity(this.label.);
    } */
    if (event.target.name == ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName) {
      const regex = /^\d+$/;

      if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.PHONENUMONLYERR);
        hasError = true;
      }
    } else if (event.target.name === ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName) {
      const regex =
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      if (!regex.test(value) && !isEmpty(value)) {
        event.target.setCustomValidity(this.label.EMAILINVALIDFORMATERR);
        hasError = true;
      }
    }

    //If there are no errors and there is value in either Phone or Email field,
    //then the custom validity message should dissappear from both fields.
    if (!hasError && value) {
      event.target.setCustomValidity("");

      if (event.target.name == ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName) {
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
      } else if (event.target.name == ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName) {
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
    }
    event.target.reportValidity();
  }

  handleFieldChange(event) {
    const fieldName = event.target.name || event.target.dataset.name;
    console.log("fieldName:" + fieldName);
    // eslint-disable-next-line default-case
    switch (fieldName) {
      case ACCOUNT_FIELDS.BILLING_ADDRESS:
        this.handleAddressMessage(event);
        this.validateAddress(event);
        this.setBillingAddress(this.accountRecord, this.getAddress(event));
        break;
      case ACCOUNT_FIELDS.SHIPPING_ADDRESS:
        this.handleAddressMessage(event);
        this.validateAddress(event);
        this.setShippingAddress(this.accountRecord, this.getAddress(event));
        break;
    }
  }

  //START: FRONT-2620
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

    address.reportValidity();
    //this.validateAddress(event);
  } //END : FRONT-2620

  get dateOfBirthOverFlowMessage() {
    let vartoday = new Date();
    let options = { month: "2-digit", day: "2-digit", year: "numeric" };
    let formattedDate = vartoday.toLocaleDateString("en-US", options);
    return `Date must be ${formattedDate} or earlier.`;
  }
  get stateOptions() {
    let country =
      this.accountRecord?.BillingCountryCode ||
      this.accountRecord?.ShippingCountryCode ||
      "";
    return this._countryToStates?.[country] || [];
  }

  setFieldValue(record, fieldName, value) {
    record[fieldName] = value;
  }

  setBillingAddress(record, { street, province, postalCode, country, city }) {
    record[ACCOUNT_FIELDS.BILLING_STREET_FIELD.fieldApiName] = street;
    record[ACCOUNT_FIELDS.BILLING_STATE_FIELD.fieldApiName] = province;
    record[ACCOUNT_FIELDS.BILLING_POSTALCODE_FIELD.fieldApiName] = postalCode;
    record[ACCOUNT_FIELDS.BILLING_COUNTRY_FIELD.fieldApiName] = country;
    record[ACCOUNT_FIELDS.BILLING_CITY_FIELD.fieldApiName] = city;
  }

  setShippingAddress(record, { street, province, postalCode, country, city }) {
    record[ACCOUNT_FIELDS.SHIPPING_STREET_FIELD.fieldApiName] = street;
    record[ACCOUNT_FIELDS.SHIPPING_STATE_CODE_FIELD.fieldApiName] = province;
    record[ACCOUNT_FIELDS.SHIPPING_POSTALCODE_FIELD.fieldApiName] = postalCode;
    record[ACCOUNT_FIELDS.SHIPPING_COUNTRY_CODE_FIELD.fieldApiName] = country;
    record[ACCOUNT_FIELDS.SHIPPING_CITY_FIELD.fieldApiName] = city;
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

  getSetterConfigs(event) {
    let recordContext = event.target.dataset.context;
    if (event.target.name === "FirstName") {
      let firstNameVal = event.target.value;
      if (!isUndefined(this.contactRecord.LastName)) {
        let accName = this.contactRecord.LastName + ", " + firstNameVal;
        this.accountRecord.Name = accName.trim();
      }
      this.contactRecord.FirstName = firstNameVal;
    }
    if (event.target.name === "LastName") {
      let lastNameVal = event.target.value;
      if (!isUndefined(this.contactRecord.FirstName)) {
        let accName = lastNameVal + ", " + this.contactRecord.FirstName;
        this.accountRecord.Name = accName.trim();
      }
      this.contactRecord.LastName = lastNameVal;
    }
    if (
      this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME &&
      !this.contactRecord.FirstName &&
      !this.contactRecord.LastName
    ) {
      this.accountRecord.Name = "";
    }
    const config = {
      field: event.target.name || event.target.dataset.name,
      value: event.target.value
    };
    if (
      recordContext === ACCOUNT_OBJECT.objectApiName ||
      isUndefined(recordContext)
    ) {
      config.record = this.accountRecord;
    } else if (recordContext === CONTACT_OBJECT.objectApiName) {
      config.record = this.contactRecord;
    }
    return config;
  }

  //Method called on 'Cancel' click
  handleCancelClick() {
    const closeEvent = new CustomEvent("closemodal");
    this.dispatchEvent(closeEvent);
  }

  //Method called on'Save' click
  handleSaveClick(event) {
    event.preventDefault();
    if (this.validateFieldsOnSave(event)) {
      this.displayError(
        this.label.REQUIREDFIELDSERRTITLE,
        this.label.REQUIREDFIELDSERRMSG
      );
    } else {
      if (!this.isError) {
        this.isLoading = true;
        //Only update the record if there are any changes
        if (
          ((this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME &&
            JSON.stringify(this._initialContactRecord) ===
              JSON.stringify(this.contactRecord)) ||
            this._recordTypeName === PROSPECT_RECORD_TYPE_NAME) &&
          JSON.stringify(this._initialAccountRecord) ===
            JSON.stringify(this.accountRecord)
        ) {
          this.isLoading = false;
          this.handleCancelClick();
          if (this.isSaveAndSelect) {
            this.selectAccountToCustomerInfo();
          }
        } else {
          this.updateAccountRecord(event);
        }
      }
    }
  }

  //Method called on 'Save and Select' Click
  handleSaveAndSelectClick(event) {
    this.isSaveAndSelect = true;
    this.handleSaveClick(event);
  }
  //FRONT -3848
  selectAccountToCustomerInfo() {
    this.isSaveAndSelect = false;
    let paramData = {
      id: this._recordId,
      title: this.accountRecord[ACCOUNT_FIELDS.NAME_FIELD.fieldApiName],
      Record_Type_Text__c: this._recordTypeName,
      RecordTypeId:
        this.accountRecord[ACCOUNT_FIELDS.ACCOUNTTYPE_FIELD.fieldApiName]
    };
    let selectAccountEvent = new CustomEvent("selectaccount", {
      detail: paramData
    });
    this.dispatchEvent(selectAccountEvent);
  }

  //Method called to validate the fields on 'Save' or 'Save and Select' click, before updating the record
  validateFieldsOnSave(event) {
    this.isError = false;
    if (this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME) {
      if (
        !this.contactRecord[
          CONTACT_FIELDS.CONTACT_FIRST_NAME_FIELD.fieldApiName
        ] ||
        !this.contactRecord[
          CONTACT_FIELDS.CONTACT_LAST_NAME_FIELD.fieldApiName
        ] ||
        !this.accountRecord[ACCOUNT_FIELDS.NAME_FIELD.fieldApiName] ||
        !this.accountRecord[ACCOUNT_FIELDS.BILLING_STREET_FIELD.fieldApiName] ||
        !this.accountRecord[ACCOUNT_FIELDS.BILLING_CITY_FIELD.fieldApiName] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.BILLING_COUNTRY_FIELD.fieldApiName
        ] ||
        !this.accountRecord[ACCOUNT_FIELDS.BILLING_STATE_FIELD.fieldApiName] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.BILLING_POSTALCODE_FIELD.fieldApiName
        ] ||
        !this.accountRecord[ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.DRIVERS_LICENSE_FIELD.fieldApiName
        ] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.DRIVERS_LICENSE_STATE_FIELD.fieldApiName
        ] ||
        !this.accountRecord[ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName] ||
        !this.accountRecord[ACCOUNT_FIELDS.BIRTH_DATE_FIELD.fieldApiName]
      ) {
        return true;
      }
    }
    if (this._recordTypeName === PROSPECT_RECORD_TYPE_NAME) {
      if (
        !this.accountRecord[ACCOUNT_FIELDS.NAME_FIELD.fieldApiName] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.SHIPPING_STREET_FIELD.fieldApiName
        ] ||
        !this.accountRecord[ACCOUNT_FIELDS.SHIPPING_CITY_FIELD.fieldApiName] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.SHIPPING_COUNTRY_CODE_FIELD.fieldApiName
        ] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.SHIPPING_STATE_CODE_FIELD.fieldApiName
        ] ||
        !this.accountRecord[
          ACCOUNT_FIELDS.SHIPPING_POSTALCODE_FIELD.fieldApiName
        ]
      ) {
        return true;
      }
    }

    //validate birthdate for noncredit
    if (
      this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME &&
      this.accountRecord[ACCOUNT_FIELDS.BIRTH_DATE_FIELD.fieldApiName]
    ) {
      var birthDate =
        this.accountRecord[ACCOUNT_FIELDS.BIRTH_DATE_FIELD.fieldApiName];
      var CurrentDate = new Date();
      birthDate = new Date(birthDate);
      if (birthDate == null) {
        this.displayError(
          this.label.REQUIREDFIELDSERRTITLE,
          this.label.REQUIREDFIELDSERRMSG
        );
        this.isError = true;
      } else if (birthDate > CurrentDate) {
        this.displayError(this.label.DOBERRTITLE, this.label.DOBValidation);
        this.isError = true;
      } else {
        this.isError = false;
      }
    }

    if (
      !this.accountRecord[ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName] &&
      !this.accountRecord[ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName]
    ) {
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
    } else if (this.accountRecord[ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName]) {
      if (
        !/^\d+$/.test(
          this.accountRecord[ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName]
        )
      ) {
        this.displayError(this.label.ERRTITLE, this.label.INVALIDPHONEERRMSG); //FRONT-3224
        this.isError = true;
      } else if (
        this.accountRecord[ACCOUNT_FIELDS.PHONE_FIELD.fieldApiName].length != 10
      ) {
        this.displayError(this.label.ERRTITLE, this.label.PHONEERRMSG);
        this.isError = true;
      }
    }
    if (
      !this.isError &&
      this.accountRecord[ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName]
    ) {
      if (
        !this.accountRecord[ACCOUNT_FIELDS.EMAIL_FIELD.fieldApiName].match(
          /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
        )
      ) {
        this.displayError(this.label.ERRTITLE, this.label.INVALIDEMAILERRMSG);
        this.isError = true;
      }
    }
    if (Object.keys(this._lengthExceededFields).length > 0) {
      this.displayError(
        this.label.ERRTITLE,
        "Review and resolve the errors specified."
      );
      this.isError = true;
    }
  }

  //Method to update the Account record after editing and has no errors.
  async updateAccountRecord(event) {
    let fields;
    let recordInput;

    let recordUpdatemessage =
      this.accountRecord[ACCOUNT_FIELDS.NAME_FIELD.fieldApiName] +
      " information has been successfully updated.";
    let message = LABELS.UPDATEDACCOUNTTOAST; //FRONT-4001
    this.accountRecord[ACCOUNT_FIELDS.ID_FIELD.fieldApiName] = this._recordId;

    fields = this.accountRecord;
    recordInput = fields;
    //START: FRONT: 3878, FRONT-4001
    await updateSObject({
      record: recordInput,
      allowDuplicateRule: this._bypassDuplicateRules
    })
      .then((result) => {
        if (result && result.isSuccess) {
          // Addded if for FRONT-20757 & FRONT-20761
          if (this.parentcmp === "drfAccountLookupWrapper") {
            let message = "Account Details have been updated successfully.";
            const cEvent = new ShowToastEvent({
              message: message,
              variant: "success"
            });
            this.dispatchEvent(cEvent);
          }
          if (
            !this.isSaveAndSelect ||
            (this.parentcmp !== "quoterequireCustomLookup" &&
              this.parentcmp !== "orderrequireCustomLookup" &&
              this.parentcmp !== "customLookup" &&
              this.parentcmp !== "drfAccountLookupWrapper") // FRONT-20757 & FRONT-20761
          ) {
            this.fireToastEvent(recordUpdatemessage);
          }
          if (
            this.isSaveAndSelect &&
            (this.parentcmp === "quoterequireCustomLookup" ||
              this.parentcmp === "orderrequireCustomLookup" ||
              this.parentcmp === "customLookup")
          ) {
            console.log("inside second if");

            let addedTo =
              this.parentcmp === "quoterequireCustomLookup" ||
              this.parentcmp === "orderrequireCustomLookup"
                ? LABELS.CUSTOMER_INFO
                : LABELS.CART;
            message = message + " " + addedTo;
            this.fireToastEvent(message);
          }
          notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
          setTimeout(() => {
            this.refreshParentComponent();
            this.handleCancelClick();
          }, 2000);
        } else {
          if (result.message === DUPLICATE_ERROR_CODE) {
            if (this._recordTypeName === NON_CREDIT_RECORD_TYPE_NAME) {
              this.buildDuplicateErrorPayload(
                result.attributes?.duplicateRecordIds,
                result.attributes?.duplicateRuleName,
                result.attributes?.duplicateRecords,
                recordInput
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
    //If clicked on 'Save & Select' - Then after saving and updating the record, select the record as well in the Customer Info field
    if (this.isSaveAndSelect) {
      this.selectAccountToCustomerInfo();
    }
    //END: FRONT: 3878, FRONT-4001
  }

  //Method to display Error Toast message
  displayError(errortitle, msg) {
    // console.log("msg::" + msg, errortitle);
    // this.errorMsg = msg;
    // this.errorTitle = errortitle;
    // this.showCustomToastMessage = true;
    const newEvent = new ShowToastEvent({
      title: errortitle,
      message: msg,
      variant: "error"
    });
    this.dispatchEvent(newEvent);
    //   setTimeout(() => {
    //     this.closeCustomToastMessage();
    //  }, 3000);
  }

  closeCustomToastMessage() {
    this.showCustomToastMessage = false;
  }

  //Method called after Save click (after record update)
  //To refresh the parent component i.e. sbr_3_0_customAccountListViewCmp
  refreshParentComponent() {
    let refreshAccountListViewComponent = new CustomEvent("refreshcomponent");
    this.dispatchEvent(refreshAccountListViewComponent);
  }

  /**
   * FRONT-3225,FRONT-3227
   */
  get footerStyle() {
    if (this.fromRecordPage || this.drfAccountWrapper) {
      return "slds-modal__footer bottomfooter";
    } else {
      return "slds-modal__footer";
    }
  }
  /**
   * FRONT-3225,FRONT-3227
   */
  get saveVariant() {
    if (this.fromRecordPage) {
      return "brand";
    } else {
      return "neutral";
    }
  }
  /**
   * FRONT-3225,FRONT-3227
   */
  get saveButtonStyle() {
    if (this.fromRecordPage) {
      return "brand-button slds-var-p-left_small";
    } else {
      return "neutral-button slds-var-p-left_small";
    }
  }

  // FRONT-3878 ,4001 Starts - Duplicate Detection Resolver
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

    this._recordId = selectedAccount.Id;
    this.accountRecord[ACCOUNT_FIELDS.NAME_FIELD.fieldApiName] =
      selectedAccount.Name;

    this.showEventForAddition();
    this.closeModal();
    if (this.isSaveAndSelect) {
      this.selectAccountToCustomerInfo();
    }
    this.hideResults(selectedAccount);
  }
  closeModal() {
    const eventProps = {
      isModalOpen: false
    };
    const closeModal = new CustomEvent("closemodal", eventProps);
    this.dispatchEvent(closeModal);
  }

  @track accountSelected;
  hideResults(account) {
    let hideResults;
    this.accountSelected = account;
    if (account) {
      let accObj = { acc: account, newOrExistingAcc: "New" };
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
    if (this.fromRecordPage && !this.isMobile) {
      classes += " edit-account-quick-action-modal";
    }
    return classes;
  }

  showEventForAddition(message = LABELS.TOASTMESSAGE) {
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

  fireToastEvent(message) {
    const cEvent = new ShowToastEvent({
      title: "Success",
      message: message,
      variant: "success"
    });
    this.dispatchEvent(cEvent);
  }
  // FRONT-3878 ,4001 Ends - Duplicate Detection Resolver

  // FRONT-3545 Start
  validateAddress(event) {
    let addressFields = ["street", "city", "postalCode"];
    for (let field of addressFields) {
      if (FIELD_LENGTH_CONFIG_MAPPING[field]) {
        let currentFieldValue = event.target[field];
        this.validateMaxLength(field, currentFieldValue, event);
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

  handleDuplicateHardStopCancel() {
    /* if(this.parentcmp==="ActionButton"){
      this.handleCancel();
    }
    else{*/
    this.handleCancelClick(); //FRONT-4596
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  /*handleYes(event){
    this._bypassDuplicateRules = true;
    this.duplicateResolverPayload = null;
    this.handleSaveClick(event);
  }*/
  /* FRONT-18942 - Added code to hide extra close icon when called from AURA quick actions - Starts */
  removeDefaultCloseIconView() {
    if (!this.rendered && this.fromRecordPage) {
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

  // FRONT-20757 & FRONT-20761
  @api refreshApexMethod() {
    return refreshApex(this._contactWiredResult);
  }
}