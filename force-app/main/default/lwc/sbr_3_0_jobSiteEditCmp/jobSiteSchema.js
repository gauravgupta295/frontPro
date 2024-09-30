import JOBSITE_CONTACT from "@salesforce/schema/AssociatedLocation.Job_Site_Contact_0__c";
import JOBSITE_CONTACT_PHONE from "@salesforce/schema/AssociatedLocation.Job_Site_Contact_0__r.Phone";
import JOBSITE_PHONE from "@salesforce/schema/AssociatedLocation.Job_Site_Contact__c";
import JOBSITE_PONUMBER from "@salesforce/schema/AssociatedLocation.Purchase_Order_Number__c";
import JOBSITE_JOB_NUMBER from "@salesforce/schema/AssociatedLocation.Job_Number__c";
import JOBSITE_STREET_ADDRESS from "@salesforce/schema/AssociatedLocation.Street_Address__c";
import JOBSITE_CITY from "@salesforce/schema/AssociatedLocation.City__c";
import JOBSITE_STATE from "@salesforce/schema/AssociatedLocation.State__c";
import JOBSITE_COUNTRY from "@salesforce/schema/AssociatedLocation.Country__c";
import JOBSITE_ZIP_CODE from "@salesforce/schema/AssociatedLocation.Zip_Code__c";
const JOBSITE_LATITUDE = "AssociatedLocation.Latitude_Longitude__Latitude__s";
const JOBSITE_LONGITUDE = "AssociatedLocation.Latitude_Longitude__Longitude__s";

const JOBSITE_FIELDS = {
  JOBSITE_CONTACT,
  JOBSITE_CONTACT_PHONE,
  JOBSITE_PHONE,
  JOBSITE_PONUMBER,
  JOBSITE_JOB_NUMBER,
  JOBSITE_STREET_ADDRESS,
  JOBSITE_CITY,
  JOBSITE_STATE,
  JOBSITE_COUNTRY,
  JOBSITE_ZIP_CODE,
  JOBSITE_LATITUDE,
  JOBSITE_LONGITUDE
};
export default JOBSITE_FIELDS;