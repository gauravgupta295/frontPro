import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSharedLocation from '@salesforce/apex/SBR_3_0_BranchDA.getLocation';
//SF-6992
import getAddressLatLong from '@salesforce/apex/SBR_3_0_createLeadController.getAddressLatLong';

import { CloseActionScreenEvent } from 'lightning/actions';

//import { isPhone } from 'lightning/platformUserAgentUtils';
import FORM_FACTOR from '@salesforce/client/formFactor';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_PARENTID_FIELD from '@salesforce/schema/Account.ParentId';
import ACCOUNT_RT_FIELD from '@salesforce/schema/Account.RecordTypeId';
import ACCOUNT_STREET_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingStreet';
import ACCOUNT_CITY_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingCity';
import ACCOUNT_STATE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingState';
import ACCOUNT_STATECODE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingStateCode';
import ACCOUNT_PCODE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingPostalCode';
import ACCOUNT_COUNTRY_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingCountry';
import ACCOUNT_COUNTRYCODE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingCountryCode';

import CONTACT_SALUTATION_FIELD from '@salesforce/schema/Contact.Salutation';
import CONTACT_FNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_MNAME_FIELD from '@salesforce/schema/Contact.MiddleName';
import CONTACT_LNAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_SUFFIX_FIELD from '@salesforce/schema/Contact.Suffix';
//SF-5340
import CONTACT_RELATED_ACC_ID from '@salesforce/schema/Contact.AccountId';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import CONTACT_MOBILE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import CONTACT_MAIL_COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';
import CONTACT_MAIL_STREET_FIELD from '@salesforce/schema/Contact.MailingStreet';
import CONTACT_MAIL_STATE_FIELD from '@salesforce/schema/Contact.MailingState';
import CONTACT_MAIL_CITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import CONTACT_MAIL_PCODE_FIELD from '@salesforce/schema/Contact.MailingPostalCode';
import {
    FlowNavigationNextEvent,
    FlowNavigationFinishEvent,
    FlowAttributeChangeEvent
} from "lightning/flowSupport";

import PROJECT_STREET_FIELD from '@salesforce/schema/Project__c.Street__c';
import PROJECT_CITY_FIELD from '@salesforce/schema/Project__c.City__c';
import PROJECT_STATE_FIELD from '@salesforce/schema/Project__c.State__c';
import PROJECT_ZIPCODE_FIELD from '@salesforce/schema/Project__c.ZIP_Code__c';
import PROJECT_COUNTRY_FIELD from '@salesforce/schema/Project__c.Country__c';
import PROJECT_LATLNG_FIELD from '@salesforce/schema/Project__c.Latitude_Longitude__c';

import ACCOUNT_LOOKUP_FIELD from '@salesforce/schema/Lead.Account__c';
import ACCOUNT_OFFICE_LOOKUP_FIELD from '@salesforce/schema/Lead.Office_Account__c';
import CONTACT_LOOKUP_FIELD from '@salesforce/schema/Lead.Contact__c';
import OPPTY_LOOKUP_FIELD from '@salesforce/schema/Lead.Opportunity__c';
import PROJECT_LOOKUP_FIELD from '@salesforce/schema/Lead.Project__c';
import NAME_FIELD from '@salesforce/schema/Lead.Name';
import SALUTATION_FIELD from '@salesforce/schema/Lead.Salutation';
import FNAME_FIELD from '@salesforce/schema/Lead.FirstName';
import MNAME_FIELD from '@salesforce/schema/Lead.MiddleName';
import LNAME_FIELD from '@salesforce/schema/Lead.LastName';
import SUFFIX_FIELD from '@salesforce/schema/Lead.Suffix';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import COMPANY_FIELD from '@salesforce/schema/Lead.Company';
import TITLE_FIELD from '@salesforce/schema/Lead.Title';
import PHONE_FIELD from '@salesforce/schema/Lead.Phone';
import MOBILE_FIELD from '@salesforce/schema/Lead.MobilePhone';
import EMAIL_FIELD from '@salesforce/schema/Lead.Email';
import WEBSITE_FIELD from '@salesforce/schema/Lead.Website';
import FAX_FIELD from '@salesforce/schema/Lead.Fax';
import LEAD_OWNER_FIELD from '@salesforce/schema/Lead.OwnerId';
import LEAD_ID_FIELD from '@salesforce/schema/Lead.Lead_Id__c';
import RELEASE_FIELD from '@salesforce/schema/Lead.Release__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Lead.Description';
import DECISION_MAKER_FIELD from '@salesforce/schema/Lead.Decision_Maker__c';
import SOURCE_CAMPAIGN_FIELD from '@salesforce/schema/Lead.Source_Campaign__c';
import MARKETO_LEAD_FIELD from '@salesforce/schema/Lead.Marketo_Lead__c';
import RATING_FIELD from '@salesforce/schema/Lead.Rating';
import BUDGET_AMOUNT_FIELD from '@salesforce/schema/Lead.Budget_Amount__c';
import BUDGET_STATUS_FIELD from '@salesforce/schema/Lead.Budget_Status__c';
import PREF_CONTACT_METHOD_FIELD from '@salesforce/schema/Lead.Preferred_Contact_Method__c';
import DNC_FIELD from '@salesforce/schema/Lead.DoNotCall';
import EMAIL_OPT_OUT_FIELD from '@salesforce/schema/Lead.HasOptedOutOfEmail';
import FAX_OPT_OUT_FIELD from '@salesforce/schema/Lead.HasOptedOutOfFax';
import MKTG_MATERIAL_OPT_OUT_FIELD from '@salesforce/schema/Lead.Marketing_Materials_Opt_Out__c';
import TOPIC_FIELD from '@salesforce/schema/Lead.Topic__c';
import SYNC_TO_MKTO_FIELD from '@salesforce/schema/Lead.Sync_to_Marketo__c';
import NEED_FIELD from '@salesforce/schema/Lead.Need__c';
import PROJECT_NEED_FIELD from '@salesforce/schema/Lead.Project_Need__c';
import EQP_NEED_FIELD from '@salesforce/schema/Lead.Equipment_Needs__c';
import REFERRING_PAGE_FIELD from '@salesforce/schema/Lead.Referring_Page__c';
import WATERMARK_FIELD from '@salesforce/schema/Lead.Watermark__c';
import BIZIBLE_ID_FIELD from '@salesforce/schema/Lead.Bizible_Id__c';
import BIRTHMARK_FIELD from '@salesforce/schema/Lead.Birthmark__c';
import MKTO_REFERRING_PAGE_FIELD from '@salesforce/schema/Lead.Mkto_Referring_Page__c';
import LEAD_SCORE_FIELD from '@salesforce/schema/Lead.Lead_Score__c';
import CATALOG_RQSTD_FIELD from '@salesforce/schema/Lead.Catalog_Requested__c';
import CATALOG_RQST_FIELD from '@salesforce/schema/Lead.Catalog_Request__c';
import ADDRESS_STREET_FIELD from '@salesforce/schema/Lead.Job_Address_Street__c';
import ADDRESS_CITY_FIELD from '@salesforce/schema/Lead.Job_Address_City__c';
import ADDRESS_STATE_FIELD from '@salesforce/schema/Lead.Job_Address_State__c';
import ADDRESS_PCODE_FIELD from '@salesforce/schema/Lead.Job_Address_Zip_Code__c';
import ADDRESS_COUNTRY_FIELD from '@salesforce/schema/Lead.Job_Address_Country__c';
import LAT_LONG_FIELD from '@salesforce/schema/Lead.Latitude_Longitude__c';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import LEAD_SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import NO_OF_EMPLOYEES_FIELD from '@salesforce/schema/Lead.NumberOfEmployees';
import SIC_CODE_FIELD from '@salesforce/schema/Lead.SIC_Code__c';
import SHARED_LOC_FIELD from '@salesforce/schema/Lead.Location__c';
import CUSTOMER_ADDRESS from '@salesforce/schema/Lead.Address';
import CUSTOMER_ADDRESS_STREET from '@salesforce/schema/Lead.Street';
import CUSTOMER_ADDRESS_CITY from '@salesforce/schema/Lead.City';
import CUSTOMER_ADDRESS_STATE from '@salesforce/schema/Lead.State';
import CUSTOMER_ADDRESS_STATECODE from '@salesforce/schema/Lead.StateCode';
import CUSTOMER_ADDRESS_ZIP from '@salesforce/schema/Lead.PostalCode';
import CUSTOMER_ADDRESS_COUNTRY from '@salesforce/schema/Lead.Country';
import CUSTOMER_ADDRESS_COUNTRYCODE from '@salesforce/schema/Lead.CountryCode';

import ACCOUNT_LOOKUP_FIELD_OPP from '@salesforce/schema/Opportunity.AccountId';
import SHARED_LOC_FIELD_OPP from '@salesforce/schema/Opportunity.SharedLocation__c';
import STREET_FIELD_OPP from '@salesforce/schema/Opportunity.Street__c';
import CITY_FIELD_OPP from '@salesforce/schema/Opportunity.City__c';
import STATE_FIELD_OPP from '@salesforce/schema/Opportunity.State__c';
import COUNTRY_FIELD_OPP from '@salesforce/schema/Opportunity.Country__c';
import ZIP_CODE_FIELD_OPP from '@salesforce/schema/Opportunity.ZIP_Code__c';

import SHARED_LOC_STREET_FIELD from '@salesforce/schema/Location.Street_Address__c';
import SHARED_LOC_CITY_FIELD from '@salesforce/schema/Location.City__c';
import SHARED_LOC_STATE_FIELD from '@salesforce/schema/Location.State__c';
import SHARED_LOC_PCODE_FIELD from '@salesforce/schema/Location.Zip_Code__c';
import SHARED_LOC_COUNTRY_FIELD from '@salesforce/schema/Location.Country__c';
import SHARED_LOC_LAT_LONG_FIELD from '@salesforce/schema/Location.Latitude_Longitude__c';

export default class Sbr_3_0_createLeadRecordCmp extends NavigationMixin(LightningElement) {

    //SF-5340
    @track changeTriggeredFromContact = false;
    @track phoneValue;
    @track mobileValue;
    @track emailValue;
    @track useContactAccount = false;
    @track wiredContactData;
    @track wiredAccountData;
    @api availableActions = [];
    @api createdLead;
    @api leadLat;
    @api leadLong;
    @track latLongFieldValue;
    @track showPopver = false;

    @api recordId;
    @api relatedRecordId;
    @api objectApiName;
    @track isMobileApp = false;
    @track isGeneralSectionOpen = true;
    @track isContactSectionOpen = true;
    @track isProjSectionOpen = true;
    @track isAddressSectionOpen = true;
    @track arrowValue = "&#709;";
    @track isRequired = true;
    errorMessage;

    //accountObjectInfo;

    accountId;
    officeAccountId;
    contactAccountId;
    defaultContactId;
    defaultOfficeAccountId;
    opportunityId;
    opportunityAccountId;
    defaultOpportunityId;
    projectId;
    project;
    opportunity;
    sharedLocationId;
    sharedLocation;
    sharedLocationLookupField;

    //Opp infos
    streetOppField;
    cityOppField;
    countryOppField;
    stateOppField;
    zipCodeOppField;

    streetValueDefault;
    cityValueDefault;
    stateValueDefault;
    zipValueDefault;
    countryValueDefault;
    latValueDefault;
    lngValueDefault;
    oldLatValue;
    oldLongValue;

    accountLookupField = ACCOUNT_LOOKUP_FIELD;
    officeAccountLookupField = ACCOUNT_OFFICE_LOOKUP_FIELD;
    contactLookupField = CONTACT_LOOKUP_FIELD;
    opportunityLookupField = OPPTY_LOOKUP_FIELD;
    projectLookupField = PROJECT_LOOKUP_FIELD;
    nameField = NAME_FIELD;
    salutationField = SALUTATION_FIELD;
    firstNameField = FNAME_FIELD;
    middleNameField = MNAME_FIELD;
    lastNameField = LNAME_FIELD;
    suffixField = SUFFIX_FIELD;
    statusField = STATUS_FIELD;
    companyField = COMPANY_FIELD;
    titleField = TITLE_FIELD;
    phoneField = PHONE_FIELD;
    mobileField = MOBILE_FIELD;
    emailField = EMAIL_FIELD;
    websiteField = WEBSITE_FIELD;
    faxField = FAX_FIELD;
    leadOwnerField = LEAD_OWNER_FIELD;
    leadIdField = LEAD_ID_FIELD;
    releaseField = RELEASE_FIELD;
    descriptionField = DESCRIPTION_FIELD;
    decisionMakerField = DECISION_MAKER_FIELD;
    sourceCampaignField = SOURCE_CAMPAIGN_FIELD;
    marketoLeadField = MARKETO_LEAD_FIELD;
    ratingField = RATING_FIELD;
    budgetAmountField = BUDGET_AMOUNT_FIELD;
    budgetStatusField = BUDGET_STATUS_FIELD;
    preferredContactMethodField = PREF_CONTACT_METHOD_FIELD;
    doNotCallField = DNC_FIELD;
    emailOptOutField = EMAIL_OPT_OUT_FIELD;
    faxOptOutField = FAX_OPT_OUT_FIELD;
    marketingMaterialsOptOutField = MKTG_MATERIAL_OPT_OUT_FIELD;
    topicField = TOPIC_FIELD;
    syncToMarketoField = SYNC_TO_MKTO_FIELD;
    needField = NEED_FIELD;
    projectNeedField = PROJECT_NEED_FIELD;
    equipmentNeedsField = EQP_NEED_FIELD;
    referringPageField = REFERRING_PAGE_FIELD;
    watermarkField = WATERMARK_FIELD;
    bizibleIdField = BIZIBLE_ID_FIELD;
    birthmarkField = BIRTHMARK_FIELD;
    mktoReferringPageField = MKTO_REFERRING_PAGE_FIELD;
    leadScoreField = LEAD_SCORE_FIELD;
    catalogRequestedField = CATALOG_RQSTD_FIELD;
    catalogRequestField = CATALOG_RQST_FIELD;
    streetField = ADDRESS_STREET_FIELD;
    cityField = ADDRESS_CITY_FIELD;
    stateField = ADDRESS_STATE_FIELD;
    postalcodeField = ADDRESS_PCODE_FIELD;
    countryField = ADDRESS_COUNTRY_FIELD;
    latLongField = LAT_LONG_FIELD;
    customerAddressField = CUSTOMER_ADDRESS;
    custStreetField = CUSTOMER_ADDRESS_STREET;
    custCityField = CUSTOMER_ADDRESS_CITY;
    custStateField = CUSTOMER_ADDRESS_STATECODE;
    custPostalcodeField = CUSTOMER_ADDRESS_ZIP;
    custCountryField = CUSTOMER_ADDRESS_COUNTRYCODE;
    industryField = INDUSTRY_FIELD;
    leadSourceField = LEAD_SOURCE_FIELD;
    noOfEmployeesField = NO_OF_EMPLOYEES_FIELD;
    sicCodeField = SIC_CODE_FIELD;
    sharedLocationLookupField = SHARED_LOC_FIELD;
    isChangeAccount = false;
    officeAccountWhereClause = '';
    contactWhereClause = '';
    opportunityWhereClause = '';
    //contactWhere;
    isLeadShare = false;
    @api isFromMap = false;
    newLeadId;
    @track selectedAccount;
    @track selectedContact;
    @track selectedProject;

    disableBtn = false;
    @api hideRelatedSection = false;
    @api hideSaveCancel = false;
    @api jobStreetValueDefault = '';
    @api jobCityValueDefault = '';
    @api jobStateValueDefault = '';
    @api jobPostalValueDefault = '';
    @api jobCountryValueDefault = '';
    @api latitudeDefault = '';
    @api longitudeDefault = '';

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;

    @wire(getRecord, {
        recordId: '$selectedAccount',
        fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PARENTID_FIELD, ACCOUNT_RT_FIELD,
            'Account.Override_Address__Street__s', 'Account.Override_Address__City__s', 'Account.Override_Address__StateCode__s', 'Account.Override_Address__PostalCode__s','Account.Latitude_Longitude__Latitude__s','Account.Latitude_Longitude__Longitude__s',
            'Account.Override_Address__CountryCode__s', ACCOUNT_STREET_SHIPPING_FIELD, ACCOUNT_CITY_SHIPPING_FIELD, ACCOUNT_STATE_SHIPPING_FIELD, ACCOUNT_STATECODE_SHIPPING_FIELD,
            ACCOUNT_PCODE_SHIPPING_FIELD, ACCOUNT_COUNTRY_SHIPPING_FIELD, ACCOUNT_COUNTRYCODE_SHIPPING_FIELD, 'Account.BillingLatitude', 'Account.BillingLongitude', 'Account.ShippingLatitude', 'Account.ShippingLongitude',
            'Account.Override_Address__Latitude__s', 'Account.Override_Address__Longitude__s'
        ]
    })
    wiredAccount;

    //SF-8071 added this get the office account info
    @wire(getRecord, {
        recordId: '$officeAccountId',
        fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PARENTID_FIELD, ACCOUNT_RT_FIELD,
            'Account.Override_Address__Street__s', 'Account.Override_Address__City__s', 'Account.Override_Address__StateCode__s', 'Account.Override_Address__PostalCode__s', 'Account.Latitude_Longitude__Latitude__s', 'Account.Latitude_Longitude__Longitude__s',
            'Account.Override_Address__CountryCode__s', ACCOUNT_STREET_SHIPPING_FIELD, ACCOUNT_CITY_SHIPPING_FIELD, ACCOUNT_STATE_SHIPPING_FIELD, ACCOUNT_STATECODE_SHIPPING_FIELD,
            ACCOUNT_PCODE_SHIPPING_FIELD, ACCOUNT_COUNTRY_SHIPPING_FIELD, ACCOUNT_COUNTRYCODE_SHIPPING_FIELD, 'Account.BillingLatitude', 'Account.BillingLongitude', 'Account.ShippingLatitude', 'Account.ShippingLongitude',
            'Account.Override_Address__Latitude__s', 'Account.Override_Address__Longitude__s'
        ]
    })
    wiredOfficeAcct({ error, data }) {
        if (error) {
            console.log('wiredOfficeAccountError ' + JSON.stringify(error));
        } else if (data) {      
            let wiredAcData = data;
            if (wiredAcData?.fields?.Latitude_Longitude__Longitude__s != null && wiredAcData?.fields?.Latitude_Longitude__Longitude__s != undefined) {
                this.longitudeDefault = wiredAcData.fields.Latitude_Longitude__Longitude__s?.value;
            }
            if (wiredAcData?.fields?.Latitude_Longitude__Latitude__s != null && wiredAcData?.fields?.Latitude_Longitude__Latitude__s != undefined) {
                this.latitudeDefault = wiredAcData.fields.Latitude_Longitude__Latitude__s?.value;
            }
        }
    }

    // Bug Sal-5536 fix / //SF-5340
    @wire(getRecord, {
        recordId: '$account',
        fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PARENTID_FIELD, ACCOUNT_RT_FIELD,
            'Account.Override_Address__Street__s', 'Account.Override_Address__City__s', 'Account.Override_Address__StateCode__s', 'Account.Override_Address__PostalCode__s',
            'Account.Override_Address__CountryCode__s', ACCOUNT_STREET_SHIPPING_FIELD, ACCOUNT_CITY_SHIPPING_FIELD, ACCOUNT_STATE_SHIPPING_FIELD, ACCOUNT_STATECODE_SHIPPING_FIELD,
            ACCOUNT_PCODE_SHIPPING_FIELD, ACCOUNT_COUNTRY_SHIPPING_FIELD, ACCOUNT_COUNTRYCODE_SHIPPING_FIELD,
            'Account.E_mail_Address__c', 'Account.Phone', 'Account.BillingCountry', 'Account.BillingState', 'Account.BillingPostalCode', 'Account.BillingStreet',
            'Account.BillingCity', 'Account.BillingLatitude', 'Account.BillingLongitude', 'Account.ShippingLatitude', 'Account.ShippingLongitude',
            'Account.Override_Address__Latitude__s', 'Account.Override_Address__Longitude__s'
        ]
    })
    changeAccountCall({ error, data }) {
        if (error) {
            console.log('wiredAccountError ' + JSON.stringify(error));
        } else if (data) {
           
            this.wiredAccountData = data;
            if (!this.changeTriggeredFromContact) {
                this.emailValue = this.wiredAccountData.fields.E_mail_Address__c.value ? this.wiredAccountData.fields.E_mail_Address__c.value : '';
                this.phoneValue = this.wiredAccountData.fields.Phone.value ? this.wiredAccountData.fields.Phone.value : '';
                this.setAccountAddress(this.wiredAccountData.fields);
            }

            // Updates for SF-6321 : updating lat , long from office account itself instead of parent account
            if (this.isOfficeAccount && this.wiredAccount!=null && this.wiredAccount!=undefined ){
                let wiredAcData= this.wiredAccount.data;
                if (wiredAcData?.fields?.Latitude_Longitude__Longitude__s != null && wiredAcData?.fields?.Latitude_Longitude__Longitude__s != undefined) {
                    this.longitudeDefault = wiredAcData.fields.Latitude_Longitude__Longitude__s?.value;
                }
                if (wiredAcData?.fields?.Latitude_Longitude__Latitude__s != null && wiredAcData?.fields?.Latitude_Longitude__Latitude__s != undefined) {
                    this.latitudeDefault = wiredAcData.fields.Latitude_Longitude__Latitude__s?.value;
                }
            }
        }
    }

    setAccountAddress(addr) {
        // Override Address
        console.log('addr  '+JSON.stringify(addr));
        if (this.isAddressComplete(addr.Override_Address__City__s.value, addr.Override_Address__CountryCode__s.value, addr.Override_Address__PostalCode__s.value,
            addr.Override_Address__StateCode__s.value, addr.Override_Address__Street__s.value)) {
            this.streetValueTemp = addr.Override_Address__Street__s.value;
            this.cityValueTemp = addr.Override_Address__City__s.value;
            this.stateValueTemp = addr.Override_Address__StateCode__s.value;
            this.postalcodeValueTemp = addr.Override_Address__PostalCode__s.value;
            this.countryValueTemp = addr.Override_Address__CountryCode__s.value;
            this.latitudeDefault = addr.Override_Address__Latitude__s.value;
            this.longitudeDefault = addr.Override_Address__Longitude__s.value;
            
            // Shipping/Steet Address         
        } else if (this.isAddressComplete(addr.ShippingCity.value, addr.ShippingCountry.value, addr.ShippingPostalCode.value,
            addr.ShippingState.value, addr.ShippingStreet.value)) {
            this.streetValueTemp = addr.ShippingStreet.value;
            this.cityValueTemp = addr.ShippingCity.value;
            this.stateValueTemp = addr.ShippingState.value;
            this.postalcodeValueTemp = addr.ShippingPostalCode.value;
            this.countryValueTemp = addr.ShippingCountry.value;
            this.latitudeDefault = addr.ShippingLatitude.value;
            this.longitudeDefault = addr.ShippingLongitude.value;
            
            // Billing Address
        } else {
            this.streetValueTemp = addr.BillingStreet.value;
            this.cityValueTemp = addr.BillingCity.value;
            this.stateValueTemp = addr.BillingState.value;
            this.postalcodeValueTemp = addr.BillingPostalCode.value;
            this.countryValueTemp = addr.BillingCountry.value;
            this.latitudeDefault = addr.BillingLatitude.value;
            this.longitudeDefault = addr.BillingLongitude.value;
            
        }
    }

    isAddressComplete(city, country, postalCode, state, street) {
        console.log('**** ', city, country, postalCode, state, street);
        return city && country && postalCode && state && street;
    }
    //SF-5340
    @wire(getRecord, {
        recordId: '$selectedContact', fields: [CONTACT_RELATED_ACC_ID, CONTACT_SALUTATION_FIELD, CONTACT_FNAME_FIELD, CONTACT_MNAME_FIELD,
            CONTACT_LNAME_FIELD, CONTACT_SUFFIX_FIELD, CONTACT_EMAIL_FIELD, CONTACT_PHONE_FIELD,
            CONTACT_MOBILE_FIELD, CONTACT_MAIL_STREET_FIELD, CONTACT_MAIL_STATE_FIELD,
            CONTACT_MAIL_CITY_FIELD, CONTACT_MAIL_PCODE_FIELD, CONTACT_MAIL_COUNTRY_FIELD]
    })
    wiredContact({ error, data }) {
        if (error) {
            console.log('wiredContactError ' + JSON.stringify(error));
        } else if (data) {
            this.wiredContactData = data;
           
            this.changeTriggeredFromContact = true;
            //this.account = data.fields.AccountId.value;
            //to be filled with contact address
            this.phoneValue = data.fields.Phone.value ? data.fields.Phone.value : '';
            this.mobileValue = data.fields.MobilePhone.value ? data.fields.MobilePhone.value : '';
            this.emailValue = data.fields.Email.value ? data.fields.Email.value : '';
            this.streetValueTemp = data.fields.MailingStreet.value ? data.fields.MailingStreet.value : '';
            this.cityValueTemp = data.fields.MailingCity.value ? data.fields.MailingCity.value : '';
            this.stateValueTemp = data.fields.MailingState.value ? data.fields.MailingState.value : '';
            this.postalcodeValueTemp = data.fields.MailingPostalCode.value ? data.fields.MailingPostalCode.value : '';
            this.countryValueTemp = data.fields.MailingCountry.value ? data.fields.MailingCountry.value : '';
            
        }
    }

    @wire(getRecord, { recordId: '$selectedProject', fields: [PROJECT_STREET_FIELD, PROJECT_CITY_FIELD, PROJECT_STATE_FIELD, PROJECT_ZIPCODE_FIELD, PROJECT_COUNTRY_FIELD, 'Project__c.Latitude_Longitude__Longitude__s', 'Project__c.Latitude_Longitude__Latitude__s'] })
    wireProject({ error, data }) {
        if (error) {
            console.log('wiredProjError ' + JSON.stringify(error));
        } else if (data) {

            this.project = data;
           

            if (data.fields.Latitude_Longitude__Longitude__s != null || data.fields.Latitude_Longitude__Longitude__s != undefined) {
                this.longitudeDefault = data.fields.Latitude_Longitude__Longitude__s.value;
            }
            if (data.fields.Latitude_Longitude__Latitude__s != null || data.fields.Latitude_Longitude__Latitude__s != undefined) {
                this.latitudeDefault = data.fields.Latitude_Longitude__Latitude__s.value;
            }
        }
    }

    @wire(getRecord, { recordId: '$opportunityId', fields: [ACCOUNT_LOOKUP_FIELD_OPP, SHARED_LOC_FIELD_OPP, STREET_FIELD_OPP, CITY_FIELD_OPP, STATE_FIELD_OPP, COUNTRY_FIELD_OPP, ZIP_CODE_FIELD_OPP] })
    wiredOpportunity({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading opportunity',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {

            this.opportunity = data;
            let oppAccId = this.opportunity.fields.AccountId.value;
            this.selectedAccount = oppAccId;
            this.account = oppAccId;
            this.contactAccountId = oppAccId;
            this.sharedLocationId = this.opportunity.fields.SharedLocation__c.value;
            this.streetOppField = this.opportunity.fields.Street__c.value;
            this.cityOppField = this.opportunity.fields.City__c.value;
            this.countryOppField = this.opportunity.fields.Country__c.value;
            this.stateOppField = this.opportunity.fields.State__c.value;
            this.zipCodeOppField = this.opportunity.fields.ZIP_Code__c.value;
        }
    }

    @wire(getRecord, { recordId: '$sharedLocationId', fields: [SHARED_LOC_STREET_FIELD, SHARED_LOC_CITY_FIELD, SHARED_LOC_STATE_FIELD, SHARED_LOC_PCODE_FIELD, SHARED_LOC_COUNTRY_FIELD, 'Location.Latitude_Longitude__Longitude__s', 'Location.Latitude_Longitude__Latitude__s'] })
    wiredLocation({ error, data }) {
        if (error) {
            console.log('wiredLocError ' + JSON.stringify(error));
        } else if (data) {

            this.sharedLocation = data;

            if (data.Latitude_Longitude__Longitude__s != null || data.Latitude_Longitude__Longitude__s != undefined) {
                this.longitudeDefault = data.Latitude_Longitude__Longitude__s;
            }
            if (data.Latitude_Longitude__Latitude__s != null || data.Latitude_Longitude__Latitude__s != undefined) {
                this.latitudeDefault = data.Latitude_Longitude__Latitude__s;
            }
            
        }
    }

    @api resetForm() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => { field.reset(); });
        }
        let customLookups = this.template.querySelectorAll('c-s-b-r_3_0_custom-lookup-cmp');
        if (customLookups) {
            customLookups.forEach(lookup => { lookup.handleRemove(); });
        }
    }

    connectedCallback() {
        if (FORM_FACTOR === 'Small') {
            this.isMobileApp = true;
        }
        if (this.objectApiName === 'Account') {
            this.selectedAccount = this.relatedRecordId;
            this.isLeadShare = true;
        }
        if (this.objectApiName === 'Opportunity') {
            this.opportunityId = this.relatedRecordId;
            this.isLeadShare = true;
        }
        if (this.objectApiName === 'Project__c') {
            this.selectedProject = this.relatedRecordId;
            this.projectId = this.relatedRecordId;
            this.isLeadShare = true;
        }

    }

    renderedCallback() {
        if (this.hideSaveCancel) {
            this.hideSave();
        }
    }


    handleOfficeAccount(event) {
        if (event.detail.selectedRecord != undefined && JSON.stringify(event.detail.selectedRecord) != '{}') {
            this.oldLatValue = this.latitudeDefault;
            this.oldLongValue = this.longitudeDefault;
            this.officeAccountId = event.detail.selectedRecord.Id;
            // this.contactWhere();
        } else {

            this.officeAccountId = '';
            this.latitudeDefault = this.oldLatValue;
            this.longitudeDefault = this.oldLongValue;
        }
    }

    //SF-5340
    handleAccountChange(event) {
        // Bug Sal-5536 fix
        this.isChangeAccount = true;
        this.selectedAccount = event.detail.value[0];
        this.account = event.detail.value[0];
        this.contactAccountId = this.account;

        if (event.detail.value[0] == undefined) {
            // SF-6111
            this.template.querySelector('[data-id="companyNameValueId"]').value = '';
            this.wiredAccountData = null;
            this.selectedAccount = null;
            this.account = null;
            this.accountId = null;
            this.relatedRecordId = null;
            this.emptyForm();
        }
        else if (this.account != null && this.account != '') {
            this.disableBtn = false;
        }
        const element = this.template.querySelector('[data-id="contactLookup"]');
        element.handleRemove();
    }

    //SF-5340
    handleContactChange(event) {
        this.useContactAccount = true;
        // this.selectedContact = event.detail.value[0];
        this.selectedContact = event.detail.selectedRecord?.Id;
        if (this.selectedContact != null && this.selectedContact != '') {
            this.template.querySelector('[data-id="fnameValueId"]').value = this.fnameValue;
            this.template.querySelector('[data-id="lnameValueId"]').value =  this.lnameValue;
            this.disableBtn = false;
        } else {
            this.emptyForm();
        }
    }

    //SF-5340
    setSelectedProject(event) {
        this.selectedProject = event.target.value;
    }

    emptyForm() {
        this.phoneValue = '';
        this.mobileValue = '';
        this.emailValue = '';
        if (!this.isBillingOrOfficeAccount) {
            this.streetValueTemp = '';
            this.cityValueTemp = '';
            this.stateValueTemp = '';
            this.postalcodeValueTemp = '';
            this.countryValueTemp = '';
        }
        //this.template.querySelector('[data-id="companyNameValueId"]').value = '';
        //this.template.querySelector('[data-id="accountId"]').value = '';
        this.template.querySelector('[data-id="fnameValueId"]').value = '';
        this.template.querySelector('[data-id="lnameValueId"]').value = '';
    }

    handleOpportunityChange(event) {
        this.opportunityId = event.detail.selectedRecord?.Id;
        if (this.opportunityId != null && this.opportunityId != '') {
            this.disableBtn = false;
        }
    }

    handleSharedLocationChange(event) {
        this.sharedLocation = event.detail.value[0];
        
        if (this.sharedLocation != null && this.sharedLocation != '') {
            this.disableBtn = false;

            getSharedLocation({ id: this.sharedLocation })
                .then(result => {

                    this.sharedLocationId = result.Id;
                    this.sharedLocation = {
                        'apiName': 'Location',
                        'fields': result
                    };
                    
                    if (result.Latitude_Longitude__Longitude__s != null || result.Latitude_Longitude__Latitude__s != null) {
                        this.longitudeDefault = result.Latitude_Longitude__Longitude__s;
                        this.latitudeDefault = result.Latitude_Longitude__Latitude__s;
                    }
                    // populate Lead job address per SF-5340
                    this.jobStreetValueDefault = result.Street_Address__c;
                    this.jobCityValueDefault = result.City__c;
                    this.jobStateValueDefault = result.State__c;
                    this.jobPostalValueDefault = result.Zip_Code__c;
                    this.jobCountryValueDefault = result.Country__c;
                })
                .catch(error => {
                    console.log('Error in getSharedLocation: ' + error.body.message);
                });
        }
    }

    get accRtId() {
        return getFieldValue(this.wiredAccount.data, ACCOUNT_RT_FIELD);
    }
    get officeRtId() {
        if (this.accountObjectInfo.data != undefined) {
            const rtis = this.accountObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).find(rti => rtis[rti].name === 'Office');
        }
        return;
    }
    get billingRtIds() {
        if (this.accountObjectInfo.data != undefined) {
            const rtis = this.accountObjectInfo.data.recordTypeInfos;
            return Object.keys(rtis).filter(rti => (rtis[rti].name === 'Credit' || rtis[rti].name === 'Non-Credit' || rtis[rti].name === 'Prospect'));
        }
        return;
    }
    get isOfficeAccount() {
        if (this.objectApiName == 'Account' && this.accRtId != undefined && this.accRtId == this.officeRtId) {
            return true;
        }
        return false;
    }
    get isBillingAccount() {
        if (this.billingRtIds != null && this.billingRtIds.includes(this.accRtId)) {
            return true;
        }
        return false;
    }
    get isBillingOrOfficeAccount() {
        if (this.isOfficeAccount || this.isBillingAccount) {
            return true;
        }
        return false;
    }
    get account() {
        if (this.accountId != undefined) {
            return this.accountId;
        } else if (this.isOfficeAccount) {
            return getFieldValue(this.wiredAccount.data, ACCOUNT_PARENTID_FIELD);
        } else if (this.isBillingAccount) {
            return this.relatedRecordId;
        }
    }

    set account(value) {
        this.accountId = value;
    }

    get officeAccount() {
        if (this.isOfficeAccount) {
            this.defaultOfficeAccountId = this.relatedRecordId;
            this.officeAccountId = this.relatedRecordId;
            return this.relatedRecordId;
        }
        return '';
    }

    set officeAccount(value) {
        this.officeAccountId = value;
    }

    get contactAccount() {
        if (this.contactAccountId != null || this.contactAccountId != '') {
            if (this.objectApiName == 'Account') {
                this.contactAccountId = this.relatedRecordId;
            } else if (this.objectApiName == 'Opportunity') {

                this.contactAccountId = this.account;
            } else if (this.objectApiName == 'Project__c') {

                this.contactAccountId = this.account;
            }
            return this.contactAccountId;
        };
    }

    set contactAccount(value) {
        this.contactAccountId = value;
    }

    get contactWhere() {
       
        if (this.selectedAccount && this.officeAccountId) {
            this.contactWhereClause = '(AccountId = \'' + this.selectedAccount + '\' OR AccountId = \'' + this.officeAccountId + '\')';
        } else if (this.selectedAccount) {
            this.contactWhereClause = 'AccountId = \'' + this.selectedAccount + '\'';
        }
        return this.contactWhereClause;
    }

    set contactWhere(value) {
        let accountCheck = (this.account != undefined && this.account != null);
        let officeAccountCheck = (this.officeAccountId != undefined && this.officeAccountId != null);
        if (accountCheck && officeAccountCheck) {
            this.contactWhereClause = '(AccountId = \'' + this.account + '\' OR AccountId = \'' + this.officeAccountId + '\')';
        } else if (accountCheck) {
            this.contactWhereClause = 'AccountId = \'' + this.account + '\'';
        }
    }

    get officeWhere() {
        if (this.account != undefined && this.account != null) {
            this.officeAccountWhereClause = 'ParentId = \'' + this.account + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        } else {

            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
        }
        return this.officeAccountWhereClause;
    }

    set officeWhere(value) {
        if (this.account != undefined && this.account != null) {
            this.officeAccountWhereClause = 'ParentId = \'' + value + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        } else {

            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
        }
    }

    get opportunityWhere() {
        if (this.account != undefined && this.account != null) {
            this.opportunityWhereClause = 'AccountId =\'' + this.account + '\'';
        } else {
            this.opportunityWhereClause = '';
        }
        return this.opportunityWhereClause;
    }

    set opportunityWhere(value) {
        if (this.account != undefined && this.account != null) {
            this.opportunityWhereClause = 'AccountId =\'' + this.account + '\'';
        } else {
            this.opportunityWhereClause = '';
        }
    }

    get useAccountOverrideAddress() {
        // we will only check street to determine if we will use all override or all Shipping compount fields
        // this is to prevent mixing/matching between the two fields. i.e. Override City with a Shipping Street
        const streetVal = getFieldValue(this.wiredAccount.data, 'Account.Override_Address__Street__s');
        if (this.objectApiName == 'Account' && streetVal != null) {
            return true;
        }
        return false;
    }
    get companyNameValue() {
        // Bug Sal-5536 fix
        // return this.isChangeAccount == true ? getFieldValue(this.changeAccountCall.data, ACCOUNT_NAME_FIELD) : 
        //         getFieldValue(this.wiredAccount.data, ACCOUNT_NAME_FIELD);
        return this.wiredAccountData?.fields?.Name.value;
    }
    get salutationValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_SALUTATION_FIELD);
    }
    get fnameValue() {
        //return getFieldValue(this.wiredContact.data, CONTACT_FNAME_FIELD);
        return this.wiredContactData?.fields?.FirstName?.value;
    }
    get mnameValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_MNAME_FIELD);
    }
    get lnameValue() {
        //return getFieldValue(this.wiredContact.data, CONTACT_LNAME_FIELD);
        return this.wiredContactData?.fields?.LastName?.value;
    }
    get suffixValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_SUFFIX_FIELD);
    }
    get streetValue() {
        /*if (this.useAccountOverrideAddress) {
            return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__Street__s');
        }
        return getFieldValue(this.wiredAccount.data, ACCOUNT_STREET_SHIPPING_FIELD);*/
        if (this.isChangeAccount) {
            if (this.account != null) {
                // if (this.useAccountOverrideAddress) {
                //     return getFieldValue(this.changeAccountCall.data, 'Account.Override_Address__Street__s');
                // }
                // return getFieldValue(this.changeAccountCall.data, ACCOUNT_STREET_SHIPPING_FIELD);
                return this.streetValueTemp;
            }
        } else if (this.useContactAccount) {
            return this.streetValueTemp;
        }
        else {
            if (this.account != null) {
                if (this.useAccountOverrideAddress) {
                    return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__Street__s');
                }
                return getFieldValue(this.wiredAccount.data, ACCOUNT_STREET_SHIPPING_FIELD);
            }
        }
    }
    get cityValue() {
        /*if (this.useAccountOverrideAddress) {
            return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__City__s');
        }
        return getFieldValue(this.wiredAccount.data, ACCOUNT_CITY_SHIPPING_FIELD);*/

        if (this.isChangeAccount) {
            if (this.account != null) {
                // if (this.useAccountOverrideAddress) {
                //     return getFieldValue(this.changeAccountCall.data, 'Account.Override_Address__City__s');
                // }
                // return getFieldValue(this.changeAccountCall.data, ACCOUNT_CITY_SHIPPING_FIELD);
                return this.cityValueTemp;
            }
        } else if (this.useContactAccount) {
            return this.cityValueTemp;
        }
        else {
            if (this.account != null) {
                if (this.useAccountOverrideAddress) {
                    return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__City__s');
                }
                return getFieldValue(this.wiredAccount.data, ACCOUNT_CITY_SHIPPING_FIELD);
            }
        }


    }
    get stateValue() {
        if (this.isChangeAccount) {
            if (this.account != null) {
                return this.stateValueTemp;
            }
        } else if (this.useContactAccount) {
            return this.stateValueTemp;
        } else {
            if (this.account != null) {
                if (this.useAccountOverrideAddress) {
                    return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__StateCode__s');
                }
                return getFieldValue(this.wiredAccount.data, ACCOUNT_STATE_SHIPPING_FIELD);
            }
        }
    }
    get postalcodeValue() {
        /*if (this.useAccountOverrideAddress) {
            return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__PostalCode__s');
        }
        return getFieldValue(this.wiredAccount.data, ACCOUNT_PCODE_SHIPPING_FIELD);*/

        if (this.isChangeAccount) {
            if (this.account != null) {
                // if (this.useAccountOverrideAddress) {
                //     return getFieldValue(this.changeAccountCall.data, 'Account.Override_Address__PostalCode__s');
                // }
                // return getFieldValue(this.changeAccountCall.data, ACCOUNT_PCODE_SHIPPING_FIELD);
                return this.postalcodeValueTemp;
            }
        } else if (this.useContactAccount) {
            return this.postalcodeValueTemp;
        }
        else {
            if (this.account != null) {
                if (this.useAccountOverrideAddress) {
                    return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__PostalCode__s');
                }
                return getFieldValue(this.wiredAccount.data, ACCOUNT_PCODE_SHIPPING_FIELD);
            }
        }
    }
    get countryValue() {
        /* if (this.useAccountOverrideAddress) {
             return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__CountryCode__s');
         }
         return getFieldValue(this.wiredAccount.data, ACCOUNT_COUNTRY_SHIPPING_FIELD);*/

        if (this.isChangeAccount) {
            if (this.account != null) {
                // if (this.useAccountOverrideAddress) {
                //     return getFieldValue(this.changeAccountCall.data, 'Account.Override_Address__CountryCode__s');
                // }
                // return getFieldValue(this.changeAccountCall.data, ACCOUNT_COUNTRY_SHIPPING_FIELD);
                return this.countryValueTemp;
            }
        } else if (this.useContactAccount) {
            return this.countryValueTemp;
        }
        else {
            if (this.account != null) {
                if (this.useAccountOverrideAddress) {
                    return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__CountryCode__s');
                }
                return getFieldValue(this.wiredAccount.data, ACCOUNT_COUNTRY_SHIPPING_FIELD);
            }
        }
    }

    get jobStreetValue() {
        if (this.objectApiName == 'Opportunity' && this.sharedLocation && this.sharedLocation.fields) {
            return getFieldValue(this.sharedLocation, SHARED_LOC_STREET_FIELD);
        }
        else  if (this.objectApiName == 'Opportunity') {
            return this.streetOppField;
        }
        else if (this.objectApiName == 'Project__c' || this.selectedProject) {

            return getFieldValue(this.project, PROJECT_STREET_FIELD);
        } else {

            return this.jobStreetValueDefault;
        }
    }
    get jobCityValue() {
        if (this.objectApiName == 'Opportunity' && this.sharedLocation && this.sharedLocation.fields) {
            return getFieldValue(this.sharedLocation, SHARED_LOC_CITY_FIELD);
        }
        else  if (this.objectApiName == 'Opportunity') {
            return this.cityOppField;   
        }
        else if (this.objectApiName == 'Project__c' || this.selectedProject) {

            return getFieldValue(this.project, PROJECT_CITY_FIELD);
        } else {

            return this.jobCityValueDefault;
        }
    }
    get jobStateValue() {
        if (this.objectApiName == 'Opportunity' && this.sharedLocation && this.sharedLocation.fields) {
            return getFieldValue(this.sharedLocation, SHARED_LOC_STATE_FIELD);
        } 
        else  if (this.objectApiName == 'Opportunity') {
            return this.stateOppField;   
        }
        else if (this.objectApiName == 'Project__c' || this.selectedProject) {

            return getFieldValue(this.project, PROJECT_STATE_FIELD);
        } else {

            return this.jobStateValueDefault;
        }
    }
    get jobPostalValue() {
        if (this.objectApiName == 'Opportunity' && this.sharedLocation && this.sharedLocation.fields) {
            return getFieldValue(this.sharedLocation, SHARED_LOC_PCODE_FIELD);
        }
        else  if (this.objectApiName == 'Opportunity') {
            return this.zipCodeOppField;   
        }
        else if (this.objectApiName == 'Project__c' || this.selectedProject) {

            return getFieldValue(this.project, PROJECT_ZIPCODE_FIELD);
        } else {

            return this.jobPostalValueDefault;
        }
    }
    get jobCountryValue() {
        if (this.objectApiName == 'Opportunity' && this.sharedLocation && this.sharedLocation.fields) {
            return getFieldValue(this.sharedLocation, SHARED_LOC_COUNTRY_FIELD);
        }
        else  if (this.objectApiName == 'Opportunity') {
            return this.countryOppField;   
        }
        else if (this.objectApiName == 'Project__c' || this.selectedProject) {

            return getFieldValue(this.project, PROJECT_COUNTRY_FIELD);
        } else {

            return this.jobCountryValueDefault;
        }
    }

    // get latLongFieldValue() {
    //     if (this.sharedLocation !== null || this.sharedLocation !== undefined && this.sharedLocation.apiName != null || this.sharedLocation.apiName !== undefined && this.sharedLocation.apiName === 'Location') {
    //         return getFieldValue(this.sharedLocation, SHARED_LOC_LAT_LONG_FIELD);
    //     }
    // }

    get sectionGeneralClass() {
        return this.isGeneralSectionOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get sectionContactClass() {
        return this.isContactSectionOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get sectionGeneralContentClass() {
        return this.isGeneralSectionOpen ? 'slds-section__content' : 'slds-section__content slds-hide';
    }

    get sectionContactInfoContentClass() {
        return this.isContactSectionOpen ? 'slds-section__content' : 'slds-section__content slds-hide';
    }

    get upIconStyle() {
        return this.isGeneralSectionOpen ? '' : 'display: none;';
    }

    get downIconStyle() {
        return this.isGeneralSectionOpen ? 'display: none;' : '';
    }
    toggleGeneralSection() {
        this.isGeneralSectionOpen = !this.isGeneralSectionOpen;
    }

    toggleContactSection() {
        this.isContactSectionOpen = !this.isContactSectionOpen;
    }

    get sectionProjClass() {
        return this.isProjSectionOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get sectionProjContentClass() {
        return this.isProjSectionOpen ? 'slds-section__content .accordion' : 'slds-section__content slds-hide';
    }

    toggleProjSection() {
        this.isProjSectionOpen = !this.isProjSectionOpen;
    }

    get sectionAddrClass() {
        return this.isAddressSectionOpen ? 'slds-section slds-is-open' : 'slds-section';
    }

    get sectionAddrContentClass() {
        return this.isAddressSectionOpen ? 'slds-section__content .accordion' : 'slds-section__content slds-hide';
    }

    toggleAddrSection() {
        this.isAddressSectionOpen = !this.isAddressSectionOpen;
    }

    get sectionGenIcon() {
        return this.isGeneralSectionOpen ? '\u2304' : '\uFF1E';
    }

    get sectionProjIcon() {
        return this.isProjSectionOpen ? '\u1D20' : '\uFF1E';
    }

    get sectionAddrIcon() {
        return this.isAddressSectionOpen ? '\u1D20' : '\uFF1E';
    }

    hideSave() {
        this.template.querySelector('[data-id="save-cancel-section"]').classList.add('slds-hide');
    }

    @api
    pressSave() {
        this.template.querySelector('[data-id="save-button"]').click();
    }

    //SF-6259
    isNotNullOrEmpty(val) {
        return val && val !== '';
    }

    //SF-6259, SF-6413
    validateAddress(city, state, pCode) {
        if (this.isNotNullOrEmpty(city)
            || this.isNotNullOrEmpty(state)
            || this.isNotNullOrEmpty(pCode)) {
            return true;
        } else {
            return false;
        }
    }

    //SF-6259
    async handleSubmit(event) {
        try {
            event.preventDefault(); // stop the form from submitting
            const fields = event.detail.fields;
            let proceed = true;
            //SF-6259, SF-6413
            //Check for Job Address fields first and get Lat Long details
            if (this.validateAddress(fields.Job_Address_City__c, fields.Job_Address_State__c, fields.Job_Address_Zip_Code__c)) {
                await getAddressLatLong({
                    line1: fields.Job_Address_Street__c,
                    line2: '',
                    city: fields.Job_Address_City__c,
                    state: fields.Job_Address_State__c,
                    zip: fields.Job_Address_Zip_Code__c,
                    country: fields.Job_Address_Country__c
                })
                    .then(result => {
                        this.latitudeDefault = result.latitude;
                        this.longitudeDefault = result.longitude;
                    })
                    .catch(error => {

                        console.error(error);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Failed to retrieve the lat-long for the entered address. Please try again. If issue persists, contact your System Administrator.',
                                variant: 'error'
                            })
                        );
                        proceed = false;
                        return;
                    });

                    if (!proceed) return; 
            }

            if (this.validateAddress(fields.City, fields.StateCode, fields.PostalCode) 
                || this.validateAddress(fields.Job_Address_City__c, fields.Job_Address_State__c, fields.Job_Address_Zip_Code__c && proceed)) {

                fields.Office_Account__c = this.officeAccountId;
                fields.Contact__c = this.selectedContact;
                fields.Latitude = this.latitudeDefault;
                fields.Longitude = this.longitudeDefault;
                fields.Opportunity__c = this.opportunityId;
                if (this.latLongFieldValue != undefined || this.latLongFieldValue != null) {
                    fields.Latitude_Longitude__c = this.latLongFieldValue;
                }
                
                this.leadLat = this.latitudeDefault ? this.latitudeDefault : '';
                this.leadLong = this.longitudeDefault ? this.longitudeDefault : '';
                this.template.querySelector('lightning-record-edit-form').submit(fields);
                this.disableBtn = true;
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'At minimum, City OR Zip Code OR State (Country is required to pick a State) is required.',
                        variant: 'error'
                    })
                );
            }

        } catch (e) {
            console.log('Error: ', e);
            console.log('Error: ', JSON.stringify(e));
        }
    }
    handleSuccess(event) {
        this.resetForm();
        if (this.isLeadShare || this.isFromMap || this.showNext) {
            this.createdLead = event.detail.id;
            if (this.availableActions.find((action) => action === "NEXT")) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
        }

        if (!this.isLeadShare && !this.isFromMap) {
            this.newLeadId = event.detail.id;
            let newRecordId = event.detail.id;
            const closeclickedevt = new CustomEvent('closeclicked', {
                detail: { newRecordId },
            });
            // Fire the custom event
            this.dispatchEvent(closeclickedevt);
        }
    }
    handleError(event) {
        this.disableBtn = false;
        this.errorMessage = event.detail.detail;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.errorMessage,
                    variant: 'error'
                })
            );
        this.showPopver = this.errorMessage ? true : false;
        console.log('error ->' + this.errorMessage);
    }

    hidePopover() {
        this.showPopver = false;
    }
    handleCancel() {
        if (this.isLeadShare) {
           
            if (this.relatedRecordId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.relatedRecordId,
                        actionName: 'view'
                    }
                });
            } else {
                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'Lead',
                        actionName: 'home'
                    }
                });
            }
        }

        if (!this.isLeadShare) {
            let cancel = true;
            const cancelclickedevt = new CustomEvent('cancelclicked', {
                detail: { cancel },
            });
            // Fire the custom event
            this.dispatchEvent(cancelclickedevt);
        }
    }

    get showCancel() {
        return !this.isFromMap;
    }
    get showNext() {
        return this.relatedRecordId || this.isFromMap;
    }
    get showSave() {
        return !this.relatedRecordId && !this.isFromMap;
    }
}