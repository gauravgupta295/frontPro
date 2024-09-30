import { LightningElement, api, track, wire } from "lwc";
import { isUndefinedOrNull, isEmpty } from "c/sbr_3_0_frontlineUtils";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";

import ACCOUNTTYPE_FIELD from "@salesforce/schema/Account.RecordTypeId";
import ACCOUNTTYPE_NAME_FIELD from "@salesforce/schema/Account.RecordType.Name";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import ID_FIELD from "@salesforce/schema/Contact.Id";
import CONTACT_NAME_FIELD from "@salesforce/schema/Contact.Name";
import CONTACT_PHONE_NUMBER_FIELD from "@salesforce/schema/Contact.Phone";
import CONTACT_EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import CONTACT_PRIMARY_FIELD from "@salesforce/schema/Contact.Primary_Contact__c";
import DESKTOP_TEMPLATE from "./sbr_3_0_SignTCCmpDesktop.html";
import MOBILE_LANDING_PAGE_TEMPLATE from "./sbr_3_0_SignTCMobileScreens/sbr_3_0_SignTCMobileLandingPage/sbr_3_0_SignTCMobileLandingPage.html";
import MOBILE_CONTACT_SELECT_PAGE_TEMPLATE from "./sbr_3_0_SignTCMobileScreens/sbr_3_0_SignTCMobileContactPage/sbr_3_0_SignTCMobileContactPage.html";
import noContentSvg from '@salesforce/resourceUrl/NoContentSVG'

const NON_CREDIT_RECORD_TYPE_NAME = "Non-Credit";
const HEADER_TITLE = "Terms and Conditions Review";
const REVIEW_TEXT =
  "Review and receive signature for Sunbelt's updated Account Terms and Conditions with the options below:";
const DISABLED_METHOD_SECTION_CLASSES = "disabled-method-section";
const ACCOUNT_RECORD_FIELDS = [ACCOUNTTYPE_FIELD, ACCOUNTTYPE_NAME_FIELD];

const CONTACT_FIELD_TO_QUERY = [
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_PHONE_NUMBER_FIELD.fieldApiName}`,
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_EMAIL_FIELD.fieldApiName}`,
  `${CONTACT_OBJECT.objectApiName}.${ID_FIELD.fieldApiName}`,
  `${CONTACT_OBJECT.objectApiName}.${CONTACT_NAME_FIELD.fieldApiName}`
];
const PRIMARY_CONTACT_WHERE_CLAUSE = `{  ${CONTACT_PRIMARY_FIELD.fieldApiName}: { eq: true }}] }`;
const CONTACT_RELATIONSHIP_NAME = "Contacts";
const NON_CREDIT_AUTHORIZED_CONTACT_LABEL =
  "Authorized Contact for this Account";
const CREDIT_AUTHORIZED_CONTACT_LABEL =
  "Select an authorized contact for the account";
const SELECTED_CONTACT_DEFAULT_CSS_CLASSES =
  "slds-input_faux slds-combobox__input slds-combobox__input-value";
const SMALL_FORM_FACTOR = "Small";
export default class Sbr_3_0_SignTCCmp extends LightningElement {
  @api
  recordId;
  @api sObjectName;
  primaryContact;
  @track
  methodOptions = [
    {
      label: "E-Signature",
      value: "e_sign",
      checked: false,
      info: "Get e-signature now on device."
    },
    {
      label: "Text Message",
      value: "text_message",
      checked: false,
      info: "Send text message to receive e-signature."
    },
    {
      label: "E-mail",
      value: "e_mail",
      checked: false,
      info: "Send e-mail to receive e-signature."
    },
    {
      label: "Print T&C",
      value: "print",
      checked: false,
      info: "Print and get a physical signature."
    }
  ];
  @track contactList = [];
  @track copyContactList = [];
  _accountWiredResult;
  _contactWiredResult;
  title = HEADER_TITLE;
  reviewText = REVIEW_TEXT;
  _recordTypeName;
  _selectedTCMethod;
  _contactWhereClause;
  _contactRelationship;
  @track selectedContactValue = "";
  @track showContacts = false;
  isMobile = false;
  @track searchContactsMobile = false;
  currentTemplate = this.isMobileView
    ? MOBILE_LANDING_PAGE_TEMPLATE
    : DESKTOP_TEMPLATE;

  connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
  }

  render() {
    return this.currentTemplate;
  }

  @wire(getRecord, { recordId: "$recordId", fields: ACCOUNT_RECORD_FIELDS })
  accountRecordWired(value) {
    this._accountWiredResult = value;
    const { data, error } = value;
    if (error) {
      this.showToast("Error", "Error while getting account details");
    } else if (data) {
      this.setRecordType(data);
      this.setContactQueryConfigs();
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: "$recordId",
    relatedListId: "$_contactRelationship",
    fields: CONTACT_FIELD_TO_QUERY,
    where: "$_contactWhereClause",
    pageSize: 500
  })
  contactRecordWired(value) {
    this._contactWiredResult = value;
    const { error, data } = value;
    if (data && data.records.length > 0) {
      this.buildAuthorizedContacts(data.records);
      data.records.map((contact) => {
        this.contactList.push(contact.fields);
      });

      this.contactList.map((contact) =>
        this.copyContactList.push({
          name: contact.Name.value,
          id: contact.Id.value,
          Email: contact.Email.value, 
          Phone: contact.Phone.value
        })
      );
      this.contactList = data.records;

      this.error = undefined;
    } else if (error) {
      this.showToast(
        "Error",
        "Error while getting authorized contact(s) details"
      );
    }
  }
  get hasPrimaryContact() {
    return !isUndefinedOrNull(this.primaryContact);
  }

  get hasNoPrimaryContact() {
    return !this.hasPrimaryContact;
  }

  get isNotNonCredit() {
    return this._recordTypeName !== NON_CREDIT_RECORD_TYPE_NAME;
  }
  get computedMethodSectionClasses() {
    return this.hasPrimaryContact ? "" : `${DISABLED_METHOD_SECTION_CLASSES}`;
  }

  get isContinueBtnDisabled() {
    return !(this.hasPrimaryContact && !isEmpty(this._selectedTCMethod));
  }

  get contactName() {
    return this.hasPrimaryContact
      ? getFieldValue(this.primaryContact, CONTACT_NAME_FIELD)
      : "";
  }
  get contactEmail() {
    return this.hasPrimaryContact
      ? getFieldValue(this.primaryContact, CONTACT_EMAIL_FIELD)
      : "--";
  }

  get contactPhone() {
    let phone = getFieldValue(this.primaryContact, CONTACT_PHONE_NUMBER_FIELD);

    return this.hasPrimaryContact && phone
      ? phone.replace(/^(\d{3})(\d{3})(\d{4})/, "$1-$2-$3")
      : "--";
  }
  handleMethodChange(event) {
    event.stopPropagation();
    this._selectedTCMethod = event.target.value;
    this.methodOptions = this.methodOptions.map((method) => {
      if (method.value === this._selectedTCMethod) {
        method.checked = true;
      } else {
        method.checked = false;
      }
      return method;
    });
  }

  handleSkipClick() {
    this.dispatchEvent(new CustomEvent("closeaction"));
  }

  setRecordType(data) {
    this._recordTypeName = getFieldValue(data, ACCOUNTTYPE_NAME_FIELD);
  }

  setContactQueryConfigs() {
    this._contactRelationship = CONTACT_RELATIONSHIP_NAME;
    this._contactWhereClause = this.isNotNonCredit
      ? ""
      : PRIMARY_CONTACT_WHERE_CLAUSE;
  }

  buildAuthorizedContacts(contacts) {
    if (!this.isNotNonCredit) {
      this.primaryContact = contacts[0];
      return;
    }
  }

  showToast(title, message, variant = "error") {
    const event = new ShowToastEvent({
      title,
      message,
      variant
    });
    this.dispatchEvent(event);
  }

  showContactOptions(e) {
    this.showContacts = true;
  }

  selectSearchResult(event) {
    let selectedContactId = event.currentTarget.dataset.value;
    this.primaryContact = this.contactList.find(
      (contact) => contact.id == selectedContactId
    );

    this.currentTemplate = this.currentTemplate == MOBILE_CONTACT_SELECT_PAGE_TEMPLATE ? MOBILE_LANDING_PAGE_TEMPLATE : this.currentTemplate
     
  }

  removeContact(event) {
    this.primaryContact = null;
  }

  hideContactOptions(event) {
    this.showContacts = false;
  }

  resetContactList() {
    this.copyContactList = [];
    this.contactList.map((contact) =>
      this.copyContactList.push(contact.Name.value)
    );
  }

  createNewContact(event) {
  }

  get authorizedContactLabel() {
    return this._recordTypeName
      ? this.isNotNonCredit
        ? CREDIT_AUTHORIZED_CONTACT_LABEL
        : NON_CREDIT_AUTHORIZED_CONTACT_LABEL
      : "";
  }

  get computedSelectedContactClasses() {
    return this.isNotNonCredit
      ? SELECTED_CONTACT_DEFAULT_CSS_CLASSES
      : `${SELECTED_CONTACT_DEFAULT_CSS_CLASSES} selected-contact`;
  }

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  handleShowContactMobile() {
    this.currentTemplate = MOBILE_CONTACT_SELECT_PAGE_TEMPLATE;
  }

  closeContactSearch() {
    this.currentTemplate = MOBILE_LANDING_PAGE_TEMPLATE;
  }

}