/* sbr_3_0_crewListCmp.js */
import { LightningElement, api, wire, track } from 'lwc';
import getQuotesCrew from '@salesforce/apex/SBR_3_0_CrewDA.getQuotesCrew';
import updateCrewRecord from '@salesforce/apex/SBR_3_0_CrewDA.updateCrewRecord';
import { getRecord } from "lightning/uiRecordApi";
import getQuotesCrewRefresh from '@salesforce/apex/SBR_3_0_CrewDA.getQuotesCrewRefresh';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CREW_OBJECT from '@salesforce/schema/Crew__c';

import QUOTE_STATUS_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c';
import TASK_FIELD from '@salesforce/schema/Crew__c.Task__c';
import CREW_FIELD from '@salesforce/schema/Crew__c.Crew__c';
import SHIFT_FIELD from '@salesforce/schema/Crew__c.Shift__c';
import STANDARD_HOURS_FIELD from '@salesforce/schema/Crew__c.Standard_Hours__c';
import RATE_STANDARD_FIELD from '@salesforce/schema/Crew__c.Rate_Standard__c';
import OVERTIME_HOURS_FIELD from '@salesforce/schema/Crew__c.Overtime_Hours__c';
import RATE_OVERTIME_FIELD from '@salesforce/schema/Crew__c.Rate_Overtime__c';
import HOURS_TOTAL from '@salesforce/schema/Crew__c.Total_Hours__c';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const actions = [
    { label: 'Delete', name: 'delete' },
];

const COLS = [{
    label: 'Type',
    fieldName: TASK_FIELD.fieldApiName,
    type: 'picklistColumn',
    editable: true,
    typeAttributes: {
        placeholder: 'Choose Task',
        options: { fieldName: 'taskOptions' },
        value: { fieldName: TASK_FIELD.fieldApiName }, // default value for picklist,
        context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
    }
},
{
    label: 'Crew',
    fieldName: CREW_FIELD.fieldApiName,
    editable: true
},
{
    label: 'Shift',
    fieldName: SHIFT_FIELD.fieldApiName,
    editable: true
},
{
    label: 'STD Hours',
    fieldName: STANDARD_HOURS_FIELD.fieldApiName,
    editable: true
},
{
    label: 'STD Rate',
    fieldName: RATE_STANDARD_FIELD.fieldApiName,
    editable: true
},
{
    label: 'OT Hours',
    fieldName: OVERTIME_HOURS_FIELD.fieldApiName,
    editable: true
},
{
    label: 'OT Rate',
    fieldName: RATE_OVERTIME_FIELD.fieldApiName,
    editable: true
},
{
    label: 'Total Hours',
    fieldName: HOURS_TOTAL.fieldApiName,
    editable: true
},
{
    type: 'action',
    typeAttributes: { rowActions: actions, menuAlignment: 'right' },
},
];

export default class sbr_3_0_crewListCmp extends LightningElement {
    columns = COLS;
    @api recordId;
    draftValues = [];
    @track crew;
    @track taskOptions;
    wiredCrewData;
    spinner = false;
    isDelete = false;
    @track rowDeleteFlag=true;
    crewRecordId;

    isloading;

    channelName = '/event/SBR_3_0_Crew__e';
    subscription = {};
    @track crewRecords = [];



    connectedCallback() {
        console.log('crew quote recordId: ', this.recordId);
        this.handleSubscribe();
    }

    handleSubscribe() {
        subscribe(this.channelName, -1, this.messageCallback).then(response => {
            console.log('Subscription request sent to : ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response : ', JSON.stringify(response));
        })
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    messageCallback = (response) => {
        console.log('message : ', JSON.stringify(response));
        this.refreshData();
    }

    @wire(getQuotesCrew, { quoteId: '$recordId' })
    wireCrew(result) {
        this.wiredCrewData = result;
        if (result.data) {
            this.crew = JSON.parse(JSON.stringify(result.data));
            this.crew.forEach(ele => {
                ele.taskOptions = this.taskOptions;
            })
        } else if (result.error) {
            this.crew = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: CREW_OBJECT })
    crewObjectMetadata;


    @wire(getRecord, { recordId: '$recordId', fields: [QUOTE_STATUS_FIELD] })
    wiredQuote({ error, data }) {
        if (error) {
            console.log('wiredQuote Error ' + error);
        }
        else if (data) {
            if(data.fields.SBQQ__Status__c.value && data.fields.SBQQ__Status__c.value =='In Review'){
                this.rowDeleteFlag=false;
            }
        }
    }

    //fetch picklist options
    @wire(getPicklistValues, {
        recordTypeId: "$crewObjectMetadata.data.defaultRecordTypeId",
        fieldApiName: TASK_FIELD
    })
    wirePickList({ error, data }) {
        if (data) {
            console.log('picklistValues result below:');
            console.log(data);
            this.taskOptions = data.values;
        } else if (error) {
            console.log('picklistValues error below:');
            console.log(error);
        }
    }

    get totalHours() {
        let result = 0;
        this.crew.forEach(each => {
            if (each.Standard_Hours__c) {
                result += each.Standard_Hours__c;
            }
            if (each.Overtime_Hours__c) {
                result += each.Overtime_Hours__c;
            }
        });
        return result;
    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));

        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.data = [...copyData];
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    handleCellChange(event) {
        //this.updateDraftValues(event.detail.draftValues[0]);
        let draftValues = event.detail.draftValues;
        draftValues.forEach(ele => {
            this.updateDraftValues(ele);
        })
    }

    async handleSave(event) {
        this.isloading = true;
        let records = [];
        // Convert datatable draft values into record objects
        event.detail.draftValues.slice().forEach((draftValue) => {

            const fields = Object.assign({}, draftValue);
            records.push(fields);
        });
        // Clear all datatable draft values
        this.draftValues = [];
        try {
            
            await updateCrewRecord({ records: records });

            getQuotesCrewRefresh({ quoteId: this.recordId })
                .then(result => {
                    this.crew = result;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Crews updated',
                            variant: 'success'
                        })
                    );
                })
                .catch(error => {
                    console.error('Error Occured : ', error);
                });
                this.isloading = false;

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating or reloading crews',
                    message: error.body.message,
                    variant: 'error'
                })
            );
            this.isloading = false;
        }
    }

    handleRowAction(event) {
        this.spinner = true;
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
            case 'delete':
                if (this.recordId) {
                    this.crewRecordId = row.Id;
                    console.log('this.crewRecordId : ' + this.crewRecordId);
                    /* deleteRecord(row.Id)
                        .then(() => {
                            
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Record deleted',
                                    variant: 'success'
                                })
                            );
                            this.spinner = false;
                            this.refreshData();
                        })
                        .catch(error => {
                            this.spinner = false;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error deleting record',
                                    message: error.body.message,
                                    variant: 'error'
                                })
                            );
                        }); */
                        if(this.rowDeleteFlag == false){
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error deleting record',
                                    message: 'Quotes may only be edited if Status is Draft or by Sales Managers if Status is In Review',
                                    variant: 'error'
                                })
                            )
                            this.spinner = false;
                            break;
                        }
                    this.isDelete = true;
                    this.spinner = false;
                    this.refreshData();
                }
                break;
        }
    }

    refreshData() {
        return refreshApex(this.wiredCrewData);
    }
    get flowInputVariables() {
        return [{
            name: 'recordId',
            type: 'String',
            value: this.crewRecordId
        }];
    }
    handleFlowStatusChange(event) {
        console.log('Flow status->' + event.detail.status);
        if (event.detail.status === 'FINISHED_SCREEN') {
            console.log('Flow Finished');
            const outputVariables = event.detail.outputVariables;
            for (let i = 0; i < outputVariables.length; i++) {
                const outputVar = outputVariables[i];
                if (outputVar.name == 'message' && outputVar.value == 'success') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record deleted',
                            variant: 'success'
                        })
                    );
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: outputVar.value, // SAL-26710 replacing to fix the component error while deleting the crew expense 
                            variant: 'error'
                        })
                    )
                }
            }

            this.spinner = false;
            this.refreshData();
        }
        this.isDelete = false;
    }

    handleCancel(){
        // Clear all datatable draft values
        this.draftValues = [];
    }
}