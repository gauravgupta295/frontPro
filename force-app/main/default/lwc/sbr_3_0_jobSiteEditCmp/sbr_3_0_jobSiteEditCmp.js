import { LightningElement, api, track, wire } from "lwc";
import {
  DynamicRecordFormMixin,
  isMobile
} from "c/sbr_3_0_dynamicRecordFormUtility";
import JOBSITE_FIELDS from "./jobSiteSchema.js";
import DESKTOPTEMPLATE from "./desktop.html";
import MOBILETEMPLATE from "./mobile.html";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { FORM_STORE } from "c/sbr_3_0_dynamicRecordFormRegistry";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(true);

const JOBSITE_RECORD_FIELDS = [
  JOBSITE_FIELDS.JOBSITE_CONTACT,
  JOBSITE_FIELDS.JOBSITE_CONTACT_PHONE,
  JOBSITE_FIELDS.JOBSITE_PHONE,
  JOBSITE_FIELDS.JOBSITE_PONUMBER,
  JOBSITE_FIELDS.JOBSITE_JOB_NUMBER,
  JOBSITE_FIELDS.JOBSITE_STREET_ADDRESS,
  JOBSITE_FIELDS.JOBSITE_CITY,
  JOBSITE_FIELDS.JOBSITE_STATE,
  JOBSITE_FIELDS.JOBSITE_COUNTRY,
  JOBSITE_FIELDS.JOBSITE_ZIP_CODE,
  JOBSITE_FIELDS.JOBSITE_LATITUDE,
  JOBSITE_FIELDS.JOBSITE_LONGITUDE
];
export default class Sbr_3_0_jobSiteEditCmp extends DynamicRecordFormMixin(
  LightningElement
) {
  _recordId;
  @api
  get recordId() {
    return this._recordId;
  }

  set recordId(value) {
    this._recordId = value;
  }
  @api accountId;
  @track jobSiteRecord = {};
  activeSections = ["JobSite", "LocationDetails"];
  isMobile = isMobile;
  appName = FORM_STORE.appName;
  selectedContactId = "";
  whereClause = "";
  useCustomJobNumber = false;
  isDataLoaded = false;
  isLoading = false;
  preservedJobSiteRecord = {};

  connectedCallback() {
    this.jobSiteRecord.Id = this.recordId;
    if (this.accountId) {
      this.whereClause = " AccountId = '" + this.accountId + "'";
    }
  }

  @track wiredJobSiteResult;
  @wire(getRecord, { recordId: "$recordId", fields: JOBSITE_RECORD_FIELDS })
  wiredJobsSite(result) {
    this.wiredJobSiteResult = result;
    if (result.data) {
      this.jobSiteRecord = this.formatWireData(result.data.fields);
      this.selectedContactId = this.jobSiteRecord.Job_Site_Contact_0__c;
      this.jobSiteRecord.jobSiteContactPhone =
        this.jobSiteRecord.Job_Site_Contact_0__r?.fields?.Phone?.value;
      this.isDataLoaded = true;
      this.preservedJobSiteRecord = JSON.parse(
        JSON.stringify(this.jobSiteRecord)
      );
    } else if (result.error) {
      logger.log("Error fetching JobSite", JSON.stringify(result.error));
    }
  }

  formatWireData(fields) {
    const formattedData = {};
    for (const key in fields) {
      if (fields[key].value !== undefined) {
        formattedData[key] = fields[key].value;
      }
    }
    logger.log("==formattedData==", JSON.stringify(formattedData));
    return formattedData;
  }

  handleContactChange(event) {
    let selectedRecord = event.detail.selectedRecord;
    //lookup selection returning direct field values but
    //when creating new record its coming with fields node
    if (selectedRecord && selectedRecord.fields) {
      this.selectedContactId = selectedRecord.id;
      this.jobSiteRecord.jobSiteContactPhone =
        selectedRecord.fields?.Phone?.value;
    } else if (selectedRecord) {
      this.selectedContactId = selectedRecord.Id;
      this.jobSiteRecord.jobSiteContactPhone = selectedRecord.Phone;
    }
    this.jobSiteRecord.Job_Site_Contact_0__c = this.selectedContactId;
  }

  handleUseCustomJobNumber(event) {
    if (event.target.checked) {
      this.useCustomJobNumber = true;
    } else {
      this.useCustomJobNumber = false;
    }
  }

  handleFieldChange(event) {
    let fieldKey = event.currentTarget.dataset.fieldKey;
    this.jobSiteRecord[fieldKey] = event.target.value;
  }

  @api
  saveJobSiteDetails() {
    this.isLoading = true;
    let address = this.refs.mapPinDropCmp.getSelectedAddress();
    const jobSiteObjectFields = {
      Id: this.recordId,
      Job_Site_Contact_0__c: this.jobSiteRecord.Job_Site_Contact_0__c,
      Job_Site_Contact__c: this.jobSiteRecord.Job_Site_Contact__c,
      Purchase_Order_Number__c: this.jobSiteRecord.Purchase_Order_Number__c,
      Job_Number__c: this.jobSiteRecord.Job_Number__c,
      Street_Address__c: address.street,
      City__c: address.city,
      State__c: address.state,
      Country__c: address.country,
      Zip_Code__c: address.postalZipCode,
      Latitude_Longitude__Latitude__s: address.latitude,
      Latitude_Longitude__Longitude__s: address.longitude
    };
    let jobSiteObject = { fields: jobSiteObjectFields };

    updateRecord(jobSiteObject)
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            message: "Job Site Details changes have been updated successfully.",
            variant: "success"
          })
        );
        this.publishEvent(jobSiteObjectFields);
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent("closejobsitemodal"));
      })
      .catch((error) => {
        this.isLoading = false;
        logger.log("Error in updateRecord", JSON.stringify(error));
      });
  }

  getFullAddress(jobSiteObjectFields) {
    return (
      jobSiteObjectFields.Street_Address__c +
      "," +
      jobSiteObjectFields.City__c +
      "," +
      jobSiteObjectFields.State__c +
      "," +
      jobSiteObjectFields.Zip_Code__c +
      "," +
      jobSiteObjectFields.Country__c
    );
  }

  publishEvent(jobSiteObjectFields) {
    let selectedValue = {
      detail: [
        {
          apiName: "Job_Number__c",
          value: jobSiteObjectFields.Job_Number__c
        },
        {
          apiName: "Job_Location__c",
          value: this.getFullAddress(jobSiteObjectFields)
        },
        {
          apiName: "Jobsite_Contact__c",
          value: jobSiteObjectFields.Job_Site_Contact_0__c
        },
        {
          apiName: "Job_Site_Phone_Number__c",
          value: jobSiteObjectFields.Job_Site_Contact__c
        }
      ]
    };
    //this.updateDRFFieldUpdate(selectedValue);
    this.publishChange(this.field.externalId, selectedValue, true);
  }

  //to reset the values if user made changes and close the modal
  @api
  refreshJobSiteData() {
    this.isDataLoaded = false;
    this.jobSiteRecord = this.preservedJobSiteRecord;
    this.selectedContactId = this.jobSiteRecord.Job_Site_Contact_0__c;
  }

  render() {
    let renderTemplate;
    if (this.isMobile) {
      renderTemplate = MOBILETEMPLATE;
    } else {
      renderTemplate = DESKTOPTEMPLATE;
    }
    return renderTemplate;
  }
}