import BILLING_STREET_FIELD from "@salesforce/schema/Account.BillingStreet";
import BILLING_CITY_FIELD from "@salesforce/schema/Account.BillingCity";
import BILLING_STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";
import BILLING_POSTALCODE_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import BILLING_COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import RECORD_TYPEID_FIELD from "@salesforce/schema/Account.RecordTypeId";
import RECORD_TYPE_NAME_FIELD from "@salesforce/schema/Account.RecordType.Name";
import ID_FIELD from "@salesforce/schema/Account.Id";
import EMAIL_FIELD from "@salesforce/schema/Account.E_mail_Address__c";
import DRIVERS_LICENSE_FIELD from "@salesforce/schema/Account.Drivers_License__c";
import DRIVERS_LICENSE_STATE_FIELD from "@salesforce/schema/Account.Driver_s_License_State__c";
import STATUS_FIELD from "@salesforce/schema/Account.Status__c";

const ACCOUNT_FIELDS = {
  BILLING_STREET_FIELD,
  BILLING_CITY_FIELD,
  BILLING_STATE_FIELD,
  BILLING_POSTALCODE_FIELD,
  BILLING_COUNTRY_FIELD,
  NAME_FIELD,
  PHONE_FIELD,
  RECORD_TYPEID_FIELD,
  RECORD_TYPE_NAME_FIELD,
  ID_FIELD,
  EMAIL_FIELD,
  DRIVERS_LICENSE_FIELD,
  DRIVERS_LICENSE_STATE_FIELD,
  STATUS_FIELD
};

export default ACCOUNT_FIELDS;