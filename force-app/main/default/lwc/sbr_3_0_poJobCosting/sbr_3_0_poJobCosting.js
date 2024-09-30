import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from "@salesforce/client/formFactor";
import getJobsitesByAccounts from '@salesforce/apex/SBR_3_0_POJobCostingController.getJobsitesByAccounts';
import CUSTOMER_NUMBER from "@salesforce/schema/Purchase_Order__c.Customer__c";
import JOB_SITE from "@salesforce/schema/Purchase_Order__c.Job_Site__c";
import ID_FIELD from "@salesforce/schema/Purchase_Order__c.Id";
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

const SMALL_FORM_FACTOR = "Small";
const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Customer__r.Name', 'Purchase_Order__c.Job_Site__r.JobsiteName__c', 'Purchase_Order__c.Customer__c', 'Purchase_Order__c.Job_Site__c'];
export default class Sbr_3_0_poJobCosting extends LightningElement {
    @api recordId;
    selectedAccount = '';
    selectedLocation = '';
    acctFilterClause= '';
    hasSelAccValue = false;
    isReadOnlyMode = true;
    customerNumber = '';
    jobNumber= '';
    disabledValue = '---None---';
    hasCusNum = false;
    hasLocNum = false;
    selAccId = '';
    selLocId = '';
    hasCustChanged = false;
    fieldsSectionClass = 'slds-grid slds-p-top_medium';
    buttonAlignClass = 'slds-col slds-size_1-of-1 slds-p-horizontal_small';
    acctFilterClause = 'RecordType.Name != \'Vendor\'';
    showEdit = true;
    connectedCallback() {
        console.log('recordId:', this.recordId);
        if(this.isMobileView) {
            this.fieldsSectionClass = this.fieldsSectionClass + ' slds-grid_vertical';
        }
        else {
            this.buttonAlignClass = this.buttonAlignClass + ' slds-align_absolute-center';
        }
    }
    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            if (data.fields.Status__c.value != null) {
                let poStatus = data.fields.Status__c.value;
                if (poStatus == 'Cancelled' || poStatus == 'Received') {
                    this.showEdit = false;
                }
                else {
                    if (data.fields.Customer__c.value != null) {
                        this.customerNumber = data.fields.Customer__r.displayValue;
                        this.hasCusNum = true;
                        this.selAccId = data.fields.Customer__c.value;
                    }
                    else {
                        this.hasCusNum = false;
                        this.selAccId = '';
                        this.customerNumber = '';
                    }
                    if (data.fields.Job_Site__c.value != null) {
                        this.jobNumber = data.fields.Job_Site__r.value.fields.JobsiteName__c.value;
                        this.hasLocNum = true;
                        this.selLocId = data.fields.Job_Site__c.value;
                    }
                    else {
                        this.hasLocNum = false;
                        this.selLocId = '';
                        this.jobNumber = '';
                    }
                }
            }
        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }
    selectedCustChange(event) {
        this.hasCustChanged = true;
        this.selLocId = '';
        this.selAccId = '';
        console.log(event);
        if (Object.entries(event.detail.selectedRecord).length > 0) {
            this.hasSelAccValue = true;            
            let recId = event.detail.selectedRecord.Id;
            this.selectedAccount = recId;
            let selAccIds = [];
            selAccIds.push(this.selectedAccount);
            this.getJobSites(selAccIds);
        }
        else{
            this.selectedAccount = '';
            this.selectedLocation = '';
            this.hasSelAccValue = false;
            this.disabledValue = '---None---';
        }
    }
    getJobSites(selAccIds) {
        getJobsitesByAccounts({ accIds: selAccIds })
            .then(result => {
                console.log(result);
                let jobSiteIds = [];
                result.forEach(currentItem => {
                    jobSiteIds.push(currentItem.Id);
                });
                if (jobSiteIds.length > 0) {
                    let filterIds = 'Id IN ' + JSON.stringify(jobSiteIds);
                    filterIds = filterIds.replace('[', '(').replace(']', ')').replaceAll("\"", "'");
                    console.log('filterIds:', filterIds);
                    let locCmp = this.template.querySelector('[data-id="locationComp"]');
                    locCmp.whereClause = filterIds;
                }
                else {
                    this.hasSelAccValue = false;
                    this.disabledValue = 'No Job Sites Found for Selected Account';
                }
            })
            .catch(error => {
                console.log(error);
            });
    }
    selectedALocChange(event) {
        if (Object.entries(event.detail.selectedRecord).length > 0) {
            let recId = event.detail.selectedRecord.Id;
            this.selectedLocation = recId;
        }
        else {
            this.selectedLocation = '';
            let selAccIds = []; 
            if (!this.hasCustChanged && this.hasCusNum) {
                selAccIds.push(this.selAccId);
            }
            else {
                selAccIds.push(this.selectedAccount);
            }
            this.getJobSites(selAccIds);
        }
    }
    handleEditClick(event) {
        this.isReadOnlyMode = false;
        if(this.hasCusNum) {
            this.hasSelAccValue = true;
            let selAccIds = [];
            selAccIds.push(this.selAccId);
            this.getJobSites(selAccIds);
        }
    }
    handleCancel(event) {
        this.isReadOnlyMode = true;
    }
    handleSave(event) {
        // Create the recordInput object
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CUSTOMER_NUMBER.fieldApiName] = this.selectedAccount;
        fields[JOB_SITE.fieldApiName] = this.selectedLocation;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Record updated successfully.",
                        variant: "success",
                    }),
                );
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            })
            .catch((error) => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "Please reach out to your administrator.",
                        variant: "error",
                    }),
                );
            });
        this.isReadOnlyMode = true;
        this.hasSelAccValue = false;
        this.hasCusNum = false;
        this.hasLocNum = false;
    }
}