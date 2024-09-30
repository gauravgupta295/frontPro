import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getRecords from '@salesforce/apex/PPA_TransportationLWCController.getRecords';
import clearTransportationRates from '@salesforce/apex/PPA_TransportationLWCController.clearTransportationRates';
import { notifyRecordUpdateAvailable, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RECORD_TYPE_FIELD from '@salesforce/schema/PPA_Price_List__c.RecordType.DeveloperName';
import STATUS_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_Status__c';
import COMPANYID from '@salesforce/schema/PPA_Price_List__c.PPA_CompanyId__c';
import HASPERMISSION from '@salesforce/schema/PPA_Price_List__c.PPA_hasEditPermission__c';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import clearModal from 'c/pPA_ConfirmClearRatesModalLWC'
import { loadStyle } from 'lightning/platformResourceLoader';
import PPALWCCSS from '@salesforce/resourceUrl/PPA_lwcCSS';


// updated the fieldName fields to represent object's field api names
// because the datatable component will map its columns to record fields
const actions = [
    { label: 'Clear Rates', name: 'clear' }
];

const col1 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Miles', fieldName: 'PPA_Old_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '11-20 Miles', fieldName: 'PPA_Old_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '21-30 Miles', fieldName: 'PPA_Old_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '31-40 Miles', fieldName: 'PPA_Old_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '40+ Miles', fieldName: 'PPA_Old_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true }
];

const col2 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Miles', fieldName: 'PPA_New_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '11-20 Miles', fieldName: 'PPA_New_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '21-30 Miles', fieldName: 'PPA_New_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '31-40 Miles', fieldName: 'PPA_New_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '40+ Miles', fieldName: 'PPA_New_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

const col3 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Miles', fieldName: 'PPA_New_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '11-20 Miles', fieldName: 'PPA_New_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '21-30 Miles', fieldName: 'PPA_New_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '31-40 Miles', fieldName: 'PPA_New_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '40+ Miles', fieldName: 'PPA_New_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true }
];

const col4 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Kilometers', fieldName: 'PPA_Old_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '11-20 Kilometers', fieldName: 'PPA_Old_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '21-30 Kilometers', fieldName: 'PPA_Old_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '31-40 Kilometers', fieldName: 'PPA_Old_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: '40+ Kilometers', fieldName: 'PPA_Old_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true }
];

const col5 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Kilometers', fieldName: 'PPA_New_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '11-20 Kilometers', fieldName: 'PPA_New_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '21-30 Kilometers', fieldName: 'PPA_New_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '31-40 Kilometers', fieldName: 'PPA_New_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: '40+ Kilometers', fieldName: 'PPA_New_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: true, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

const col6 = [
    { label: 'Truck Type', fieldName: 'PPA_Truck_Type__c', type: 'text', hideDefaultActions: true },
    { label: '0-10 Kilometers', fieldName: 'PPA_New_Band1__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '11-20 Kilometers', fieldName: 'PPA_New_Band2__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '21-30 Kilometers', fieldName: 'PPA_New_Band3__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '31-40 Kilometers', fieldName: 'PPA_New_Band4__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: '40+ Kilometers', fieldName: 'PPA_New_Excess__c', type: 'currency', cellAttributes: { alignment: 'left' }, editable: false, hideDefaultActions: true },
    { label: 'Transportation Rate Summary', fieldName: 'PPA_Transportation_Rate_Summary__c', type: 'text', hideDefaultActions: true }
];

export default class PPA_TransportationTableLWC extends LightningElement {

    @api recordId; // Record Id passed from the PriceList Record Page
    @api transType;
    record;
    recordTypeName;
    recordStatus;
    companyId;
    dataToRefresh;
    transportationData;
    error;
    col1 = col1;
    col2 = col2;
    col3 = col3;
    col4 = col4;
    col5 = col5;
    col6 = col6;
    colDisplay;
    clearRows = [];
    draftValues = [];
    areRowsValid = false;
    showClearButton = false;
    showSpinner = true;
    okToProcess = true;
    isCSSLoaded = false;
    hasEditPermission = false;
    readOnlyMode = true;
    showButtons = false;
    actionTypes ={load : 'LOAD', cancel : 'CANCEL'};
    htmlHeader = '';


    renderedCallback() {
        if (!this.isCSSLoaded) {
            loadStyle(this, PPALWCCSS + '/PPAlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_FIELD, STATUS_FIELD, HASPERMISSION, COMPANYID] })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.recordTypeName = getFieldValue(this.record, RECORD_TYPE_FIELD);
            this.recordStatus = getFieldValue(this.record, STATUS_FIELD);
            this.hasEditPermission = getFieldValue(this.record, HASPERMISSION);
            this.companyId = getFieldValue(this.record, COMPANYID);

            if (this.companyId == '01') {
                this.htmlHeader = 'Miles';
                if (this.recordTypeName == 'PPA_Renewal') {
                    if (this.recordStatus == 'Draft') {
                        if (this.hasEditPermission) {
                            // this.colDisplay = this.col2;
                            // this.showClearButton = true;    
                            this.readOnlyMode = false;
                        }
                        else {
                            this.colDisplay = this.col3;
                            this.showClearButton = false;
                            this.readOnlyMode = true;
                        }
                    }
                    else {
                        this.colDisplay = this.col3;
                        this.showClearButton = false;
                        this.readOnlyMode = true;
                    }
                } else {
                    this.colDisplay = this.col1;
                    this.showClearButton = false;
                    this.readOnlyMode = true;
                }
            }
            else {
                this.htmlHeader = 'Kilometers';
                if (this.recordTypeName == 'PPA_Renewal') {
                    if (this.recordStatus == 'Draft') {
                        if (this.hasEditPermission) {
                            // this.colDisplay = this.col5;
                            // this.showClearButton = true;    
                            this.readOnlyMode = false;
                        }
                        else {
                            this.colDisplay = this.col6;
                            this.showClearButton = false;
                            this.readOnlyMode = true;
                        }
                    }
                    else {
                        this.colDisplay = this.col6;
                        this.showClearButton = false;
                        this.readOnlyMode = true;
                    }
                } else {
                    this.colDisplay = this.col4;
                    this.showClearButton = false;
                    this.readOnlyMode = true;
                }
            }

            this.error = null;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getRecords, { priceListId: '$recordId', transType: '$transType' })
    wiredTransportationRates(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.transportationData = result.data;
            this.refreshScreen(this.actionTypes.load);
        }
        else if (result.error) {
            this.error = result.error.body.message;
            this.showSpinner = false;
        }
    }

    refreshScreen(actionType) {
        this.selectedRows = [];
        this.draftValues = [];
        this.error = null;
        this.showSpinner = false;
        this.showButtons = false;
        let inputs = this.template.querySelectorAll("lightning-input[class*='changedInput']");
        if (inputs.length > 0) { 
            inputs.forEach(inputCmp => {    
                inputCmp.classList.remove('changedInput');  
                // On cancel, clear the validity messages if any and reset the value original value.      
                if(actionType == this.actionTypes.cancel || 
                    (this.clearRows.length > 0 && !this.clearRows.includes(inputCmp.dataset.recordid))){
                    inputCmp.dataset.value = (inputCmp.dataset.value !== undefined) ? inputCmp.dataset.value : '';
                    if (inputCmp.value !== inputCmp.dataset.value || !inputCmp.checkValidity()) {
                        inputCmp.value = inputCmp.dataset.value;
                        if(!inputCmp.checkValidity() && inputCmp.value === ''){
                            // Per WHATWG - html.spec.whatwg.org/multipage/input.html#attr-input-value
                            //"If the value of the element is not a valid floating-point number, then set it to the empty string instead.
                            // Even though browser sets it to empty string, UI still retains the invalid value unless again set to a valid number.
                            // That's why setting it to '0' first then to '' to clear it from UI.
                            inputCmp.value = 0;
                            inputCmp.value = '';
                        }
                        inputCmp.value = !isNaN(parseFloat(inputCmp.value)) ? parseFloat(inputCmp.value).toFixed(2) : inputCmp.value;
                        inputCmp.setCustomValidity("");
                        inputCmp.reportValidity();
                    }
                }
            })            
        }
        this.clearRows = [];
    }
    
    handleChange(event) {
        this.showButtons = true;
        const inputControl = event.currentTarget;
        const fieldName = inputControl.dataset.id;
        const recordId = inputControl.dataset.recordid;
        let originalVal = inputControl.dataset.value;
        let currentVal = event.detail.value;

        originalVal = (originalVal !== undefined) ? originalVal : '';
        currentVal = (currentVal !== undefined) ? currentVal : '';

        //const value = this.template.querySelector(`[data-recordId=${recordId}][data-id=${fieldName}]`).dataset.value;
        
        if(inputControl.validity.badInput){
            inputControl.classList.add('changedInput');
        }

        // IF the field value has either no change or reverted to the original value.
        if ((isNaN(parseFloat(currentVal)) && originalVal === currentVal) || 
            (!isNaN(parseFloat(currentVal)) && parseFloat(originalVal).toFixed(2) === parseFloat(currentVal).toFixed(2))) {
            if (this.draftValues.length > 0 && this.draftValues.some(x => x.Id === recordId.toString())) {
                let draftRecord = this.draftValues.find(x => x.Id === recordId.toString());

                // delete the field from the draft record as there is no change to the original value.
                if (draftRecord.hasOwnProperty(fieldName)) {
                    delete draftRecord[fieldName];

                    // IF the record was sent to save but failed validation, 
                    // then remove the property 'PPA_Rates_Loaded__c' added in save method, if no change.
                    if(draftRecord.hasOwnProperty('PPA_Rates_Loaded__c')){
                        delete draftRecord['PPA_Rates_Loaded__c'];
                    }
                    inputControl.classList.remove('changedInput');
                    // IF the record do not have any fields updated and only field on the record is "ID"
                    // then delete the record from draft records.
                    if (Object.keys(draftRecord).length <= 1) {
                        let index = this.draftValues.findIndex(x => x.Id === recordId.toString());
                        this.draftValues.splice(index, 1);
                    }
                }
            }
        }
        else {
            inputControl.classList.add('changedInput');
            // IF the record already has field(s) modified by the user then update the draft record.
            if (this.draftValues.length > 0 && this.draftValues.some(x => x.Id === recordId.toString())) {
                let draftRecord = this.draftValues.find(x => x.Id === recordId.toString());
                let index = this.draftValues.findIndex(x => x.Id === recordId.toString());
                // Blank value is also a valid value.
                if(!isNaN(parseFloat(currentVal)) || currentVal === ''){
                    draftRecord[fieldName] = (currentVal !== '') ? parseFloat(currentVal).toFixed(2) : currentVal;
                    this.draftValues[index] = draftRecord;
                }
            }
            // First time update to a record. Create the draft record.
            else {
                // Blank value is also a valid value.
                if(!isNaN(parseFloat(currentVal)) || currentVal === ''){
                    let draftRecord = {};
                    draftRecord.Id = recordId.toString();
                    draftRecord[fieldName] = (currentVal !== '') ? parseFloat(currentVal).toFixed(2) : currentVal;
                    this.draftValues.push(draftRecord);
                }
            }
        }
    }

    // PPA2 - Lightning data table row action - won't be invoked as editing is moved to HTML table.
    handleRowAction(event) {
        const recordId = event.detail.row.Id;
        const action = event.detail.action.name;
        if (action == 'clear') {
            if (recordId != null) {
                for (var i = 0; i < this.transportationData.length; i++) {
                    if (this.transportationData[i].Id == recordId && this.transportationData[i].PPA_Rates_Loaded__c) {
                        this.clearValues(recordId);
                    }
                }
            }
        }
    }
    
    //Lightning menu button click event
    handleMenuSelect(event) {
        const recordId = event.currentTarget.dataset.id;
        if (event.detail.value == 'clear') {
            if (recordId != null) {
                for (var i = 0; i < this.transportationData.length; i++) {
                    if (this.transportationData[i].Id == recordId && this.transportationData[i].PPA_Rates_Loaded__c) {
                        this.clearValues(recordId);
                    }
                }
            }
        }
    }

    // Lightning button 
    handleCancelEdits() {
        this.refreshScreen(this.actionTypes.cancel);
     }
 
    
    // PPA2 - Lightning data table method - won't be invoked as editing is moved to HTML table.
    handleSave(event) {
        this.showSpinner = true;
        this.okToProcess = true;

        const draftValues = event.detail.draftValues;
        if (draftValues.length > 0) {
            saveRecords(draftValues);
        }
    }
    
    handleSaveTableRecords() {
        const allValid = [
            ...this.template.querySelectorAll("lightning-input[class*='changedInput']")]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }, true);
        if (allValid) {
            if( this.draftValues.length > 0){
                this.showSpinner = true;
                this.okToProcess = true;
                this.saveRecords(this.draftValues);
            }
            else {
                const event = new ShowToastEvent({
                    title: 'No records to update',
                    message: 'There are no records to update',
                    variant : 'info'
                    //message: result
                });
                this.dispatchEvent(event);
            }
        } else {
            const event = new ShowToastEvent({
                title: 'Invalid values',
                message: 'The value(s) provided are not valid',
                variant : 'error'
                //message: result
            });
            this.dispatchEvent(event);
        }
    }

    async clearValues(recordId) {
        this.clearRows = [];

        const result = await clearModal.open({
            size: 'small',
            description: 'This is a clear confirmation modal',
            modalHeader: 'Clear Rates',
            modalBody: 'Are you sure you want to clear the current Transportation Rates?'
        });

        if (result) {
            this.showSpinner = true;
            this.clearRows.push(recordId);

            clearTransportationRates({ recordIds: this.clearRows })
                .then(result => {
                    console.log('Success');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Records updated successfully',
                            variant: 'success'
                        })
                    );
                    // Display fresh data in the datatable
                    refreshApex(this.dataToRefresh);

                    if (this.readOnlyMode) {
                        this.template.querySelector('lightning-datatable').draftValues = [];
                    }
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating or refreshing records',
                            message: error.body.message,
                            variant: 'success'
                        })
                    );
                });
        }

        this.showSpinner = false;
    }


    async saveRecords(draftValues) {

        const records = draftValues.slice().map((draftValue) => {
            if (!draftValue.PPA_New_Band1__c &&
                !draftValue.PPA_New_Band2__c &&
                !draftValue.PPA_New_Band3__c &&
                !draftValue.PPA_New_Band4__c &&
                !draftValue.PPA_New_Excess__c) {
                draftValue.PPA_Rates_Loaded__c = false;
            }
            else {
                draftValue.PPA_Rates_Loaded__c = true;
            }
            const fields = Object.assign({}, draftValue);

            // validation for all values >= 0 
            if (
                (draftValue.PPA_New_Band1__c !== undefined && draftValue.PPA_New_Band1__c < 0) ||
                (draftValue.PPA_New_Band2__c !== undefined && draftValue.PPA_New_Band2__c < 0) ||
                (draftValue.PPA_New_Band3__c !== undefined && draftValue.PPA_New_Band3__c < 0) ||
                (draftValue.PPA_New_Band4__c !== undefined && draftValue.PPA_New_Band4__c < 0) ||
                (draftValue.PPA_New_Excess__c !== undefined && draftValue.PPA_New_Excess__c < 0)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'All values must be greater than or equal to zero',
                        variant: 'error'
                    })
                );

                this.okToProcess = false;
            }

            // Additional validation for PPA_New_Excess__c < 10
            if (draftValue.PPA_New_Excess__c !== undefined && draftValue.PPA_New_Excess__c > 10) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'The value in the "40+" column cannot exceed $10',
                        variant: 'error'
                    })
                );

                this.okToProcess = false;
            }

            return { fields };
        });

        try {
            if (this.okToProcess) {
                const recordUpdatePromises = records.map((record) =>
                    updateRecord(record)
                );
                await Promise.all(recordUpdatePromises);

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );

                // Display fresh data in the datatable
                await refreshApex(this.dataToRefresh);

                if (this.readOnlyMode) {
                    //hide the save and cancel button
                    this.template.querySelector('lightning-datatable').draftValues = [];
                }
                else {
                    this.draftValues = []
                    this.showButtons = false;
                    this.inputCSSRemoved = false;
                }
            }
        }
        catch (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: 'If a value is entered for one milage band, then all milage bands must be filled in',
                    variant: 'error'
                })
            );
        };

        this.showSpinner = false;
    }

}