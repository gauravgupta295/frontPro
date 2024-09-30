import CONTACT_SALUTATION_FIELD from "@salesforce/schema/Contact.Salutation";
import CONTACT_FIRST_NAME_FIELD from "@salesforce/schema/Contact.FirstName";
import CONTACT_LAST_NAME_FIELD from "@salesforce/schema/Contact.LastName";
import CONTACT_MIDDLE_NAME_FIELD from "@salesforce/schema/Contact.MiddleName";
import CONTACT_PHONE_NUMBER_FIELD from "@salesforce/schema/Contact.Phone";
import CONTACT_EMAIL_FIELD from "@salesforce/schema/Contact.Email";
import CONTACT_ACCOUNT_ID_FIELD from "@salesforce/schema/Contact.AccountId";
import CONTACT_ACCOUNT_NAME_FIELD from "@salesforce/schema/Contact.Account.Name";
import PREFERRED_CONTACT_METHOD_FIELD from "@salesforce/schema/Contact.Preferred_Contact_Method__c";
import CONTACT_ROLE_FIELD from "@salesforce/schema/Contact.Role__c";
import CONTACT_DESCRIPTION_FIELD from "@salesforce/schema/Contact.Description";
import CONTACT_STATUS_FIELD from "@salesforce/schema/Contact.Status__c";
import CONTACT_DL_STATE_FIELD from "@salesforce/schema/Contact.Drivers_License_State__c";
import CONTACT_DL_NUMBER_FIELD from "@salesforce/schema/Contact.Drivers_License__c";
import CONTACT_MOBILE_FIELD from "@salesforce/schema/Contact.MobilePhone";
import REPORTS_TO_FIELD from "@salesforce/schema/Contact.ReportsToId";
import CONTACT_BIRTHDATE_FIELD from "@salesforce/schema/Contact.Birthdate";
import CONTACT_LEADSOURCE_FIELD from "@salesforce/schema/Contact.LeadSource";
import CONTACT_ASSISTANTNAME_FIELD from "@salesforce/schema/Contact.AssistantName";
import CONTACT_DONOTCAL_FIELD from "@salesforce/schema/Contact.DoNotCall";
import CONTACT_EMAILOPTOUT_FIELD from "@salesforce/schema/Contact.HasOptedOutOfEmail";
import CONTACT_MAILING_CITY_FIELD from "@salesforce/schema/Contact.MailingCity";
import CONTACT_MAILING_STATE_FIELD from "@salesforce/schema/Contact.MailingState";
import CONTACT_MAILING_STREET_FIELD from "@salesforce/schema/Contact.MailingStreet";
import CONTACT_MAILING_POSTAL_CODE_FIELD from "@salesforce/schema/Contact.MailingPostalCode";
import CONTACT_MAILING_COUNTRY_FIELD from "@salesforce/schema/Contact.MailingCountry";
import CONTACT_SUFFIX from "@salesforce/schema/Contact.Suffix";
import CONTACT_TITLE from "@salesforce/schema/Contact.Title";
import CONTACT_FAX from "@salesforce/schema/Contact.Fax";
import CONTACT_ASST_PHONE from "@salesforce/schema/Contact.AssistantPhone";
import CONTACT_FAXOPTOUT_FIELD from "@salesforce/schema/Contact.HasOptedOutOfFax";

import ID_FIELD from "@salesforce/schema/Contact.Id";

const CONTACT_FIELDS = {
  CONTACT_SALUTATION_FIELD,
  CONTACT_FIRST_NAME_FIELD,
  CONTACT_LAST_NAME_FIELD,
  CONTACT_MIDDLE_NAME_FIELD,
  CONTACT_PHONE_NUMBER_FIELD,
  CONTACT_EMAIL_FIELD,
  CONTACT_ACCOUNT_ID_FIELD,
  PREFERRED_CONTACT_METHOD_FIELD,
  CONTACT_ROLE_FIELD,
  CONTACT_DESCRIPTION_FIELD,
  CONTACT_STATUS_FIELD,
  CONTACT_DL_STATE_FIELD,
  CONTACT_DL_NUMBER_FIELD,
  CONTACT_MOBILE_FIELD,
  REPORTS_TO_FIELD,
  CONTACT_BIRTHDATE_FIELD,
  CONTACT_LEADSOURCE_FIELD,
  CONTACT_ASSISTANTNAME_FIELD,
  CONTACT_DONOTCAL_FIELD,
  CONTACT_EMAILOPTOUT_FIELD,
  CONTACT_MAILING_CITY_FIELD,
  CONTACT_MAILING_STATE_FIELD,
  CONTACT_MAILING_STREET_FIELD,
  CONTACT_MAILING_POSTAL_CODE_FIELD,
  CONTACT_MAILING_COUNTRY_FIELD,
  ID_FIELD,
  CONTACT_SUFFIX,
  CONTACT_ACCOUNT_NAME_FIELD,
  CONTACT_TITLE,
  CONTACT_FAX,
  CONTACT_ASST_PHONE,
  CONTACT_FAXOPTOUT_FIELD
};
export default CONTACT_FIELDS;