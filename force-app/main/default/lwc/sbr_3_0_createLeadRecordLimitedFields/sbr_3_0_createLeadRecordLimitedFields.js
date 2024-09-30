import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_PARENTID_FIELD from '@salesforce/schema/Account.ParentId';
import ACCOUNT_RT_FIELD from '@salesforce/schema/Account.RecordTypeId';
import ACCOUNT_STREET_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingStreet';
import ACCOUNT_CITY_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingCity';
import ACCOUNT_STATE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingState';
import ACCOUNT_PCODE_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingPostalCode';
import ACCOUNT_COUNTRY_SHIPPING_FIELD from '@salesforce/schema/Account.ShippingCountry';

import CONTACT_SALUTATION_FIELD from '@salesforce/schema/Contact.Salutation';
import CONTACT_FNAME_FIELD from '@salesforce/schema/Contact.FirstName';
import CONTACT_MNAME_FIELD from '@salesforce/schema/Contact.MiddleName';
import CONTACT_LNAME_FIELD from '@salesforce/schema/Contact.LastName';
import CONTACT_SUFFIX_FIELD from '@salesforce/schema/Contact.Suffix';

import PROJECT_STREET_FIELD from '@salesforce/schema/Project__c.Street__c';
import PROJECT_CITY_FIELD from '@salesforce/schema/Project__c.City__c';
import PROJECT_STATE_FIELD from '@salesforce/schema/Project__c.State__c';
import PROJECT_ZIPCODE_FIELD from '@salesforce/schema/Project__c.ZIP_Code__c';
import PROJECT_COUNTRY_FIELD from '@salesforce/schema/Project__c.Country__c';

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
import ADDRESS_STREET_FIELD from '@salesforce/schema/Lead.Street';
import ADDRESS_CITY_FIELD from '@salesforce/schema/Lead.City';
import ADDRESS_STATE_FIELD from '@salesforce/schema/Lead.State';
import ADDRESS_PCODE_FIELD from '@salesforce/schema/Lead.PostalCode';
import ADDRESS_COUNTRY_FIELD from '@salesforce/schema/Lead.Country';
import LAT_LONG_FIELD from '@salesforce/schema/Lead.Latitude_Longitude__c';
import INDUSTRY_FIELD from '@salesforce/schema/Lead.Industry';
import LEAD_SOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import NO_OF_EMPLOYEES_FIELD from '@salesforce/schema/Lead.NumberOfEmployees';
import SIC_CODE_FIELD from '@salesforce/schema/Lead.SIC_Code__c';

import ACCOUNT_LOOKUP_FIELD_OPP from '@salesforce/schema/Opportunity.AccountId';
import SHARED_LOC_FIELD_OPP from '@salesforce/schema/Opportunity.SharedLocation__c';

import SHARED_LOC_STREET_FIELD from '@salesforce/schema/Location.Street_Address__c';
import SHARED_LOC_CITY_FIELD from '@salesforce/schema/Location.City__c';
import SHARED_LOC_STATE_FIELD from '@salesforce/schema/Location.State__c';
import SHARED_LOC_PCODE_FIELD from '@salesforce/schema/Location.Zip_Code__c';
import SHARED_LOC_COUNTRY_FIELD from '@salesforce/schema/Location.Country__c';

export default class Sbr_3_0_createLeadRecordLimitedFields extends NavigationMixin(LightningElement) {
    @api recordId;
    @api relatedRecordId;
    @api objectApiName;

    accountObjectInfo;

    accountId;
    officeAccountId;
    defaultOfficeAccountId;
    opportunityId;
    projectId;
    opportunity;
    sharedLocationId;
    sharedLocation;

    streetValueDefault;
    cityValueDefault;
    stateValueDefault;
    zipValueDefault;
    countryValueDefault;
    latValueDefault;
    lngValueDefault;

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
    industryField = INDUSTRY_FIELD;
    leadSourceField = LEAD_SOURCE_FIELD;
    noOfEmployeesField = NO_OF_EMPLOYEES_FIELD;
    sicCodeField = SIC_CODE_FIELD;
    isChangeAccount = false;
    officeAccountWhereClause = '';

    @track selectedAccount;
    @track selectedContact;
    @track selectedProject;


    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;

    @wire(getRecord, {
        recordId: '$selectedAccount', fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PARENTID_FIELD, ACCOUNT_RT_FIELD,
            'Account.Override_Address__Street__s', 'Account.Override_Address__City__s', 'Account.Override_Address__StateCode__s', 'Account.Override_Address__PostalCode__s',
            'Account.Override_Address__CountryCode__s', ACCOUNT_STREET_SHIPPING_FIELD, ACCOUNT_CITY_SHIPPING_FIELD, ACCOUNT_STATE_SHIPPING_FIELD,
            ACCOUNT_PCODE_SHIPPING_FIELD, ACCOUNT_COUNTRY_SHIPPING_FIELD]
    })
    wiredAccount;
    // Bug Sal-5536 fix
    @wire(getRecord, {
        recordId: '$account', fields: [ACCOUNT_NAME_FIELD, ACCOUNT_PARENTID_FIELD, ACCOUNT_RT_FIELD,
            'Account.Override_Address__Street__s', 'Account.Override_Address__City__s', 'Account.Override_Address__StateCode__s', 'Account.Override_Address__PostalCode__s',
            'Account.Override_Address__CountryCode__s', ACCOUNT_STREET_SHIPPING_FIELD, ACCOUNT_CITY_SHIPPING_FIELD, ACCOUNT_STATE_SHIPPING_FIELD,
            ACCOUNT_PCODE_SHIPPING_FIELD, ACCOUNT_COUNTRY_SHIPPING_FIELD]
    })
    changeAccountCall;

    @wire(getRecord, { recordId: '$selectedContact', fields: [CONTACT_SALUTATION_FIELD, CONTACT_FNAME_FIELD, CONTACT_MNAME_FIELD, CONTACT_LNAME_FIELD, CONTACT_SUFFIX_FIELD] })
    wiredContact;

    @wire(getRecord, { recordId: '$selectedProject', fields: [PROJECT_STREET_FIELD, PROJECT_CITY_FIELD, PROJECT_STATE_FIELD, PROJECT_ZIPCODE_FIELD, PROJECT_COUNTRY_FIELD] })
    wiredProject;

    @wire(getRecord, { recordId: '$opportunityId', fields: [ACCOUNT_LOOKUP_FIELD_OPP, SHARED_LOC_FIELD_OPP] })
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
        }
        else if (data) {
            this.opportunity = data;
            let oppAccId = this.opportunity.fields.AccountId.value;
            this.selectedAccount = oppAccId;
            this.account = oppAccId;
            this.sharedLocationId = this.opportunity.fields.SharedLocation__c.value;
        }
    }

    @wire(getRecord, { recordId: '$sharedLocationId', fields: [SHARED_LOC_STREET_FIELD, SHARED_LOC_CITY_FIELD, SHARED_LOC_STATE_FIELD, SHARED_LOC_PCODE_FIELD, SHARED_LOC_COUNTRY_FIELD] })
    wiredLocation({ error, data }) {
        if (error) {
            console.log('wiredLocError ' + error);
        }
        else if (data) {
            this.sharedLocation = data;
        }
    }

    connectedCallback() {
        if (this.objectApiName === 'Account') {
            this.selectedAccount = this.relatedRecordId;
        }
        if (this.objectApiName === 'Opportunity') {
            this.opportunityId = this.relatedRecordId;
        }
        if (this.objectApiName === 'Project__c') {
            this.selectedProject = this.relatedRecordId;
            this.projectId = this.relatedRecordId;
        }
    }
    handleOfficeAccount(event) {
        if (event.detail.selectedRecord != undefined) {
            this.officeAccountId = event.detail.selectedRecord.Id;
        }
        else {
            this.officeAccountId = '';
        }
    }
    handleAccountChange(event) {
        // Bug Sal-5536 fix
        this.isChangeAccount = true;
        this.account = event.detail.value[0];
    }
    handleContactChange(event) {
        this.selectedContact = event.detail.value[0];
    }
    handleOpportunityChange(event) {
        this.opportunityId = event.detail.value[0];
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
        if (this.objectApiName == 'Account' && this.accRtId == this.officeRtId) {
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
        }
        else if (this.isOfficeAccount) {
            return getFieldValue(this.wiredAccount.data, ACCOUNT_PARENTID_FIELD);
        }
        else if (this.isBillingAccount) {
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
        this.officeWhere = value;
    }
    get officeWhere() {
        if (this.account != undefined && this.account != null) {
            this.officeAccountWhereClause = 'ParentId = \'' + this.account + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        }
        else {
            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
        }
        return this.officeAccountWhereClause;
    }
    set officeWhere(value) {
        if (this.account != undefined && this.account != null) {
            this.officeAccountWhereClause = 'ParentId = \'' + value + '\' AND RecordTypeId = \'' + this.officeRtId + '\'';
        }
        else {
            this.officeAccountWhereClause = 'RecordTypeId = \'' + this.officeRtId + '\'';
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
        return this.isChangeAccount == true ?
            getFieldValue(this.changeAccountCall.data, ACCOUNT_NAME_FIELD) :
            getFieldValue(this.wiredAccount.data, ACCOUNT_NAME_FIELD);
    }
    get salutationValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_SALUTATION_FIELD);
    }
    get fnameValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_FNAME_FIELD);
    }
    get mnameValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_MNAME_FIELD);
    }
    get lnameValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_LNAME_FIELD);
    }
    get suffixValue() {
        return getFieldValue(this.wiredContact.data, CONTACT_SUFFIX_FIELD);
    }
    get streetValue() {
        if (this.objectApiName == 'Account') {
            if (this.useAccountOverrideAddress) {
                return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__Street__s');
            }
            return getFieldValue(this.wiredAccount.data, ACCOUNT_STREET_SHIPPING_FIELD);
        }
        else if (this.objectApiName == 'Opportunity') {
            return getFieldValue(this.sharedLocation, SHARED_LOC_STREET_FIELD);
        }
        else if (this.objectApiName == 'Project__c') {
            return getFieldValue(this.wiredProject.data, PROJECT_STREET_FIELD);
        }
    }
    get cityValue() {
        if (this.objectApiName == 'Account') {
            if (this.useAccountOverrideAddress) {
                return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__City__s');
            }
            return getFieldValue(this.wiredAccount.data, ACCOUNT_CITY_SHIPPING_FIELD);
        }
        else if (this.objectApiName == 'Opportunity') {
            return getFieldValue(this.sharedLocation, SHARED_LOC_CITY_FIELD);
        }
        else if (this.objectApiName == 'Project__c') {
            return getFieldValue(this.wiredProject.data, PROJECT_CITY_FIELD);
        }
    }
    get stateValue() {
        if (this.objectApiName == 'Account') {
            if (this.useAccountOverrideAddress) {
                return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__StateCode__s');
            }
            return getFieldValue(this.wiredAccount.data, ACCOUNT_STATE_SHIPPING_FIELD);
        }
        else if (this.objectApiName == 'Opportunity') {
            return getFieldValue(this.sharedLocation, SHARED_LOC_STATE_FIELD);
        }
        else if (this.objectApiName == 'Project__c') {
            return getFieldValue(this.wiredProject.data, PROJECT_STATE_FIELD);
        }
    }
    get postalcodeValue() {
        if (this.objectApiName == 'Account') {
            if (this.useAccountOverrideAddress) {
                return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__PostalCode__s');
            }
            return getFieldValue(this.wiredAccount.data, ACCOUNT_PCODE_SHIPPING_FIELD);
        }
        else if (this.objectApiName == 'Opportunity') {
            return getFieldValue(this.sharedLocation, SHARED_LOC_PCODE_FIELD);
        }
        else if (this.objectApiName == 'Project__c') {
            return getFieldValue(this.wiredProject.data, PROJECT_ZIPCODE_FIELD);
        }
    }
    get countryValue() {
        if (this.objectApiName == 'Account') {
            if (this.useAccountOverrideAddress) {
                return getFieldValue(this.wiredAccount.data, 'Account.Override_Address__CountryCode__s');
            }
            return getFieldValue(this.wiredAccount.data, ACCOUNT_COUNTRY_SHIPPING_FIELD);
        }
        else if (this.objectApiName == 'Opportunity') {
            return getFieldValue(this.sharedLocation, SHARED_LOC_COUNTRY_FIELD);
        }
        else if (this.objectApiName == 'Project__c') {
            return getFieldValue(this.wiredProject.data, PROJECT_COUNTRY_FIELD);
        }
    }
    handleSubmit(event) {
        try {
            event.preventDefault();       // stop the form from submitting
            const fields = event.detail.fields;
            fields.Office_Account__c = this.officeAccountId;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
        catch (e) {

        }
    }
    handleSuccess(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                actionName: 'view'
            }
        });
    }
    handleError(event) {
        console.log('error' + event);
    }
    close() {
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
}