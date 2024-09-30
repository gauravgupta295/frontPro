import BILLING_STREET_FIELD from "@salesforce/schema/Account.BillingStreet";
import BILLING_CITY_FIELD from "@salesforce/schema/Account.BillingCity";
import BILLING_STATE_FIELD from "@salesforce/schema/Account.BillingStateCode";
import BILLING_POSTALCODE_FIELD from "@salesforce/schema/Account.BillingPostalCode";
import BILLING_COUNTRY_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import PHONE_FIELD from "@salesforce/schema/Account.Phone";
import ACCOUNTTYPE_FIELD from "@salesforce/schema/Account.RecordTypeId";
import ID_FIELD from "@salesforce/schema/Account.Id";
import EMAIL_FIELD from "@salesforce/schema/Account.E_mail_Address__c";
import DRIVERS_LICENSE_FIELD from "@salesforce/schema/Account.Drivers_License__c";
import DRIVERS_LICENSE_STATE_FIELD from "@salesforce/schema/Account.Driver_s_License_State__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Account.Comments__c";
import BIRTH_DATE_FIELD from "@salesforce/schema/Account.BirthDate__c";
import SHIPPING_STREET_FIELD from "@salesforce/schema/Account.ShippingStreet";
import SHIPPING_CITY_FIELD from "@salesforce/schema/Account.ShippingCity";
import SHIPPING_COUNTRY_CODE_FIELD from "@salesforce/schema/Account.ShippingCountryCode";
import SHIPPING_STATE_CODE_FIELD from "@salesforce/schema/Account.ShippingStateCode";
import SHIPPING_POSTALCODE_FIELD from "@salesforce/schema/Account.ShippingPostalCode";
import OTHER_PHONE_FIELD from "@salesforce/schema/Account.PersonOtherPhone__c";
const BILLING_ADDRESS = "BillingAddress";
const SHIPPING_ADDRESS = "ShippingAddress";
const ACCOUNT_FIELDS = {
  BILLING_STREET_FIELD,
  BILLING_CITY_FIELD,
  BILLING_STATE_FIELD,
  BILLING_POSTALCODE_FIELD,
  BILLING_COUNTRY_FIELD,
  NAME_FIELD,
  PHONE_FIELD,
  ACCOUNTTYPE_FIELD,
  ID_FIELD,
  EMAIL_FIELD,
  DRIVERS_LICENSE_FIELD,
  DRIVERS_LICENSE_STATE_FIELD,
  DESCRIPTION_FIELD,
  BIRTH_DATE_FIELD,
  SHIPPING_STREET_FIELD,
  SHIPPING_CITY_FIELD,
  SHIPPING_COUNTRY_CODE_FIELD,
  SHIPPING_STATE_CODE_FIELD,
  SHIPPING_POSTALCODE_FIELD,
  OTHER_PHONE_FIELD,
  BILLING_ADDRESS,
  SHIPPING_ADDRESS
};

export default ACCOUNT_FIELDS;