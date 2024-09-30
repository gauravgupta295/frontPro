import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import FORM_FACTOR from "@salesforce/client/formFactor";
import getContactAccount from "@salesforce/apex/SBR_3_0_AccountDA.getContactAccount";
import duplicateList from "@salesforce/apex/SBR_3_0_CheckDuplicateRecords.duplicateList";
import findDuplicateFields from "@salesforce/apex/SBR_3_0_CheckDuplicateRecords.findDuplicateFields";

// Contact field
import CONTACT_NAME_FIELD from "@salesforce/schema/Contact.Name";

// FRONT-13865 start
import SUFFIX_NAME_FIELD from "@salesforce/schema/Contact.Suffix__c";
import FIRSTNAME_NAME_FIELD from "@salesforce/schema/Contact.First_Name__c";
import LASTNAME_NAME_FIELD from "@salesforce/schema/Contact.Last_Name__c";
import SALUTATION_NAME_FIELD from "@salesforce/schema/Contact.Salutation__c";
// FRONT-13865 end
import CONTACT_STATUS_FIELD from "@salesforce/schema/Contact.Status__c";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Contact.AccountId";
import TITLE_FIELD from "@salesforce/schema/Contact.Title";
import PHONE_FIELD from "@salesforce/schema/Contact.Phone";
import MOBILE_FIELD from "@salesforce/schema/Contact.MobilePhone";
import EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import FAX_FIELD from "@salesforce/schema/Contact.Fax";
import PREFERED_CONTACT_METHOD_FIELD from "@salesforce/schema/Contact.Preferred_Contact_Method__c";
import DRI_LICENSE from "@salesforce/schema/Contact.Drivers_License__c";
import DRI_LICENSESTATE from "@salesforce/schema/Contact.Drivers_License_State__c";
import ROLE_FIELD from "@salesforce/schema/Contact.Role__c";
import REPORT_TO_FIELD from "@salesforce/schema/Contact.ReportsToId";
import DESCRIPTION_FIELD from "@salesforce/schema/Contact.Description";
import BIRTHDAY_FIELD from "@salesforce/schema/Contact.Birthdate";
import LEAD_SOURCE_FIELD from "@salesforce/schema/Contact.LeadSource";
import ASSISTANT_NAME_FIELD from "@salesforce/schema/Contact.AssistantName";
import ASSISTANT_PHONE_FIELD from "@salesforce/schema/Contact.AssistantPhone";
import DONOT_CALL_FIELD from "@salesforce/schema/Contact.DoNotCall";
import EMAIL_OPT_OUT_FIELD from "@salesforce/schema/Contact.HasOptedOutOfEmail";
import FAX_OPT_OUT_FIELD from "@salesforce/schema/Contact.HasOptedOutOfFax";
//Added as part of FRONT-13991
import createContactCmpMobileTemplate from "./sbr_3_0_createContactRecordCmpMobile.html";
import createContactCmpDesktopTemplate from "./sbr_3_0_createContactRecordCmp.html";
import Sbr_3_0_address_Css from "@salesforce/resourceUrl/FrontLinesCSS";
import { loadStyle } from "lightning/platformResourceLoader";
//End of FRONT-13991

const COUNTRY = {
  "united states": "US",
  us: "US",
  canada: "CA",
  ca: "CA"
};

export default class Sbr_3_0_createContactRecordCmp extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api relatedRecordId;
  @api objectApiName;

  @track duplicateContact = [];
  runOnce = false;
  isMobileApp = false;
  isGeneralSectionOpen = true;
  isAddressSectionOpen = true;
  isAdditionalInfoSectionOpen = true;
  phoneValue;

  @track contactInfo = {
    Name: {
      FirstName: "",
      LastName: "",
      MiddleName: null,
      Salutation: null,
      Suffix: null
    },
    // FRONT-13865 start
    FirstName: "",
    MiddleName: "",
    LastName: "",
    Suffix: null,
    Salutation: null,
    // FRONT-13865 end

    Status__c: "Active",
    AccountId: "",
    Title: null,
    Phone: "",
    MobilePhone: "",
    Email: "",
    Fax: "",
    Preferred_Contact_Method__c: "Any",
    Role__c: null,
    ReportsToId: null,
    Description: null,
    Birthdate: null,
    LeadSource: null,
    AssistantName: null,
    AssistantPhone: null,
    DoNotCall: false,
    HasOptedOutOfEmail: false,
    HasOptedOutOfFax: false
  };

  @track shippingAddress = {
    Street: "",
    City: "",
    State: "",
    PostalCode: "",
    Country: ""
  };

  columns = [
    { label: "Name", fieldName: "Name" },
    { label: "Email", fieldName: "Email" },
    { label: "Account", fieldName: "Account" },
    { label: "Account Number", fieldName: "RM_Account_Number__c" },
    {
      type: "button",
      typeAttributes: {
        label: "Show Record"
      }
    }
  ];
  mobileProps = {
    zIndex: 9004,
    footerClasses: "slds-p-around_none"
  };
  // FRONT-13865 start
  get salutationOptions() {
    return [
      { label: "Mr.", value: "Mr." },
      { label: "Ms.", value: "Ms." },
      { label: "Mrs.", value: "Mrs." },
      { label: "Doc", value: "Doc" },
      { label: "Prof.", value: "Prof." }
    ];
  }
  // FRONT-13865 end

  //Contact fields;
  birthday = BIRTHDAY_FIELD;
  leadSource = LEAD_SOURCE_FIELD;
  assistantName = ASSISTANT_NAME_FIELD;
  assistantPhone = ASSISTANT_PHONE_FIELD;
  donotCall = DONOT_CALL_FIELD;
  emailOptOut = EMAIL_OPT_OUT_FIELD;
  faxOptOut = FAX_OPT_OUT_FIELD;
  contactName = CONTACT_NAME_FIELD;

  // FRONT-13865 start
  contactFirstName = FIRSTNAME_NAME_FIELD;
  contactLastName = LASTNAME_NAME_FIELD;
  contactSuffix = SUFFIX_NAME_FIELD;
  contactSalutation = SALUTATION_NAME_FIELD;
  // FRONT-13865 end

  contactStatus = CONTACT_STATUS_FIELD;
  accountNameField = ACCOUNT_NAME_FIELD;
  titleField = TITLE_FIELD;
  phoneField = PHONE_FIELD;
  mobileField = MOBILE_FIELD;
  emailField = EMAIL_FIELD;
  faxField = FAX_FIELD;
  preferedContactMethosField = PREFERED_CONTACT_METHOD_FIELD;
  roleField = ROLE_FIELD;
  reportToField = REPORT_TO_FIELD;
  descriptionField = DESCRIPTION_FIELD;
  drilicense = DRI_LICENSE;
  drilicensestate = DRI_LICENSESTATE;
  showModal = false;
  toastType = null;
  toastMessage = "";
  isDuplicate = false;

  disableBtn = false;
  @api hideSaveCancel = false;

  @track salutationValue = "";
  showSpinner = false; //Added as part of FRONT-13991

  @api resetForm() {
    const inputFields = this.template.querySelectorAll("lightning-input-field");
    if (inputFields) {
      inputFields.forEach((field) => {
        field.reset();
      });
    }
    let customLookups = this.template.querySelectorAll(
      "c-s-b-r_3_0_custom-lookup-cmp"
    );
    if (customLookups) {
      customLookups.forEach((lookup) => {
        lookup.handleRemove();
      });
    }
  }

  handleDuplicateVal() {
    this.isDuplicate = !this.isDuplicate;
  }

  handleBack() {
    this.isDuplicate = !this.isDuplicate;
    this.showModal = !this.showModal;
  }

  connectedCallback() {
    if (FORM_FACTOR === "Small") {
      this.isMobileApp = true;
    }
    this.contactInfo.AccountId = this.relatedRecordId;
  }

  renderedCallback() {
    Promise.all([loadStyle(this, Sbr_3_0_address_Css)])
      .then(() => {})
      .catch((error) => {});
    if (this.hideSaveCancel) {
      this.hideSave();
    }
    if (!this.runOnce) {
      getContactAccount({ id: this.relatedRecordId })
        .then((data) => {
          if (
            data.Override_Address__City__s &&
            data.Override_Address__Street__s &&
            data.Override_Address__StateCode__s
          ) {
            this.shippingAddress.City = data.Override_Address__City__s;
            this.shippingAddress.Street = data.Override_Address__Street__s;
            this.shippingAddress.State = data.Override_Address__StateCode__s;
            this.shippingAddress.Country =
              data.Override_Address__CountryCode__s;
            this.shippingAddress.PostalCode =
              data.Override_Address__PostalCode__s;
          } else if (
            data.ShippingStreet &&
            data.ShippingCity &&
            data.ShippingState
          ) {
            this.shippingAddress.City = data.ShippingCity;
            this.shippingAddress.Street = data.ShippingStreet;
            this.shippingAddress.State = data.ShippingState;
            this.shippingAddress.Country = data.ShippingCountry;
            this.shippingAddress.PostalCode = data.ShippingPostalCode;
          } else {
            // billing address
            this.shippingAddress.City = data.BillingCity;
            this.shippingAddress.Street = data.BillingStreet;
            this.shippingAddress.State = data.BillingState;
            this.shippingAddress.Country = data.BillingCountry;
            this.shippingAddress.PostalCode = data.BillingPostalCode;
          }

          this.contactInfo.Phone = data.Phone;
        })
        .catch((error) => {
          console.log("error : ", JSON.stringify(error));
        });
      this.runOnce = true;
    }

    this.template
      .querySelector(".customcombobox")
      .classList.add("slds-form-element_horizontal");
    this.template
      .querySelectorAll("lightning-input")
      .forEach((ele) => ele.classList.add("slds-form-element_horizontal"));
  }

  handleInputChange(event) {
    this.contactInfo[event.target.name] = event.target.value;
  }

  handleRowAction(event) {
    const row = event.detail.row;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: row.Id,
        objectApiName: this.objectApiName,
        actionName: "view"
      }
    });
  }

  get sectionGeneralClass() {
    return this.isGeneralSectionOpen
      ? "slds-section slds-is-open"
      : "slds-section";
  }

  get sectionGeneralContentClass() {
    return this.isGeneralSectionOpen
      ? "slds-section__content"
      : "slds-section__content slds-hide";
  }

  get upIconStyle() {
    return this.isGeneralSectionOpen ? "" : "display: none;";
  }

  get downIconStyle() {
    return this.isGeneralSectionOpen ? "display: none;" : "";
  }

  toggleGeneralSection() {
    this.isGeneralSectionOpen = !this.isGeneralSectionOpen;
  }

  get sectionAddrClass() {
    return this.isAddressSectionOpen
      ? "slds-section slds-is-open"
      : "slds-section";
  }

  get sectionAddrContentClass() {
    return this.isAddressSectionOpen
      ? "slds-section__content"
      : "slds-section__content slds-hide";
  }

  toggleAddrSection() {
    this.isAddressSectionOpen = !this.isAddressSectionOpen;
  }

  get sectionGenIcon() {
    return this.isGeneralSectionOpen ? "\u2304" : "\uFF1E";
  }

  get sectionAdditionalInfoClass() {
    return this.isAdditionalInfoSectionOpen
      ? "slds-section slds-is-open"
      : "slds-section";
  }

  get sectionAdditionalInfoContentClass() {
    return this.isAdditionalInfoSectionOpen
      ? "slds-section__content"
      : "slds-section__content slds-hide";
  }

  toggleInfoSection() {
    this.isAdditionalInfoSectionOpen = !this.isAdditionalInfoSectionOpen;
  }

  hideSave() {
    this.template
      .querySelector('[data-id="save-cancel-section"]')
      .classList.add("slds-hide");
  }

  @api
  pressSave() {
    this.template.querySelector('[data-id="save-button"]').click();
  }

  handleAddressChange(event) {
    this.shippingAddress.City = event.detail.city;
    this.shippingAddress.Country = COUNTRY[event.detail.country.toLowerCase()];
    this.shippingAddress.State = event.detail.province;
    this.shippingAddress.PostalCode = event.detail.postalCode;
    this.shippingAddress.Street = event.detail.street;
  }

  handleSuccess(event) {
    let newRecordId = event.detail.id;
    // navigate to the new record

    const successEvent = new CustomEvent("createsuccess", {
      detail: { newRecordId }
    });
    this.dispatchEvent(successEvent);
    this.showSpinner = false;
    // show success message
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Created",
        message: "Contact created successfully!",
        variant: "success"
      })
    );
  }

  handleError(event) {
    this.disableBtn = false;
    let e = event.detail;
    this.showSpinner = false;
    if (e.detail) {
      // If the "detail" property is present, show the detail message as a sticky toast
      let errorMessage = e.detail;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: errorMessage,
          variant: "error"
        })
      );
    } else if (e.output && e.output.fieldErrors && e.output.fieldErrors.Name) {
      // If there is no "detail" property but "Name" fieldErrors exist, show the "Name" message as a sticky toast
      let errorMessage1 = e.output.fieldErrors.Name[0].message;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: errorMessage1,
          variant: "error"
        })
      );
    }
  }

  handleCancel() {
    const closeclickedevt = new CustomEvent("closeclicked", {
      detail: { close: true }
    });
    this.dispatchEvent(closeclickedevt);
  }

  handleOkay() {
    this.close("okay");
  }

  handleSubmit(event) {
    // try {
    this.showSpinner = true;
    event.preventDefault();
    event.stopPropagation(); // stop the form from submitting
    const fields = event.detail.fields;
    fields.MailingCountry = this.shippingAddress.Country;
    fields.MailingCity = this.shippingAddress.City;
    fields.MailingState = this.shippingAddress.State;
    fields.MailingStreet = this.shippingAddress.Street;
    fields.MailingPostalCode = this.shippingAddress.PostalCode;

    // FRONT-13865 start
    fields.FirstName = this.contactInfo.FirstName;
    fields.LastName = this.contactInfo.LastName;
    fields.MiddleName = this.contactInfo.MiddleName;
    fields.Salutation = this.contactInfo.Salutation;
    fields.Suffix = this.contactInfo.Suffix;
    this.contactInfo.Name.FirstName = this.contactInfo.FirstName;
    this.contactInfo.Name.LastName = this.contactInfo.LastName;
    this.contactInfo.Name.MiddleName = this.contactInfo.MiddleName;
    this.contactInfo.Name.Salutation = this.contactInfo.Salutation;
    this.contactInfo.Name.Suffix = this.contactInfo.Suffix;
    // end FRONT-13865
    const phone = this.template.querySelector('[data-id="phone"]');
    const mobilePhone = this.template.querySelector('[data-id="MobilePhone"]');

    if (phone) {
      fields.Phone = phone;
    }
    if (mobilePhone) {
      fields.MobilePhone = mobilePhone;
    }
    if (this.isMobileApp) {
      this.template.querySelector("lightning-record-edit-form").submit(fields);
    }

    duplicateList({
      contact: fields
    })
      .then((result) => {
        if (result.length > 0) {
          if (typeof result[0].Account === "object") {
            this.duplicateContact = [...result].map((item) => {
              return { ...item, Account: item.Account.Name };
            });
          } else {
            this.duplicateContact = [...result];
          }
          this.toastType = "Warning";
          this.toastMessage = "Contacts already exist with matching details : ";
          findDuplicateFields({ contact: fields }).then((result) => {
            for (let i = 0; i < result.length - 1; i++) {
              this.toastMessage += result[i] + " ,";
            }
            this.toastMessage += result[result.length - 1];
          });
          this.showModal = true;
          const scrolEvent = new CustomEvent("scroll", {
            detail: { scrollTop: true }
          });
          this.dispatchEvent(scrolEvent);
        } else {
          this.template
            .querySelector("lightning-record-edit-form")
            .submit(fields);
          this.disableBtn = true;
        }
      })
      .catch((error) => {
        console.log("error message : ", error.message);
      });
  }
  catch(error) {
    console.log("Error: ", error);
    console.log("Error: ", JSON.stringify(error));
  }
  //Added as part of FRONT-13991
  render() {
    if (this.isMobileApp) {
      return createContactCmpMobileTemplate;
    } else {
      return createContactCmpDesktopTemplate;
    }
  }

  handleSaveClick(event) {
    let buttonId = event.target.dataset.targetId;
    if (buttonId) {
      let btn = this.template.querySelector(".save-button");
      if (btn) {
        btn.click();
      }
    }
  }
}