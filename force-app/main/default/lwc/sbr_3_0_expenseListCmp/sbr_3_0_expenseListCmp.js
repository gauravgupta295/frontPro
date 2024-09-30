/* sbr_3_0_expenseListCmp.js */
import { LightningElement, api, wire, track } from 'lwc';
import getQuotesExpenses from '@salesforce/apex/SBR_3_0_ExpenseDA.getQuotesExpense';
import getQuotesExpenseRefresh from '@salesforce/apex/SBR_3_0_ExpenseDA.getQuotesExpenseRefresh';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from "lightning/uiRecordApi";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import EXPENSE_OBJECT from '@salesforce/schema/SBR_Expense__c';

import QUOTE_STATUS_FIELD from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Status__c';
import NAME_FIELD from '@salesforce/schema/SBR_Expense__c.Name';
import TYPE_FIELD from '@salesforce/schema/SBR_Expense__c.ExpenseType__c';
import QUANTITY_FIELD from '@salesforce/schema/SBR_Expense__c.Quantity__c';
import PRICE_FIELD from '@salesforce/schema/SBR_Expense__c.Price__c';
import REGION_KEY from '@salesforce/schema/SBR_Expense__c.Analysis_Region_Key__c';
import LAST_MODIFIED_DATE from '@salesforce/schema/SBR_Expense__c.LastModifiedDate';
import TOTAL from '@salesforce/schema/SBR_Expense__c.Total__c';

import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const actions = [
    { label: 'Delete', name: 'delete' },
];

const COLS = [{
        label: 'Name',
        fieldName: NAME_FIELD.fieldApiName,
        editable: false
    },
    {
        label: 'Analysis Region Key',
        fieldName: REGION_KEY.fieldApiName,
        editable: false
    },

    {
        label: 'Type',
        fieldName: TYPE_FIELD.fieldApiName,
        type: 'picklistColumn',
        editable: true,
        typeAttributes: {
            placeholder: 'Choose Type',
            options: { fieldName: 'typeOptions' },
            value: { fieldName: TYPE_FIELD.fieldApiName }, // default value for picklist,
            context: { fieldName: 'Id' } // binding row Id with context variable to be returned back
        }
    },

    {
        label: 'Price',
        fieldName: PRICE_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Quantity',
        fieldName: QUANTITY_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Total',
        fieldName: TOTAL.fieldApiName,
        type: 'currency',
        typeAttributes: { minimumFractionDigits: 0, maximumFractionDigits: 2 },
        editable: false
    },
    {
        label: 'Last Modified Date',
        type: 'date-local',
        fieldName: LAST_MODIFIED_DATE.fieldApiName,
        typeAttributes: {
            month: "2-digit",
            day: "2-digit"
        },
        editable: false
    },
    {
        type: 'action',
        typeAttributes: { rowActions: actions, menuAlignment: 'right' },
    },
];

export default class sbr_3_0_expenseListCmp extends LightningElement {
    columns = COLS;
    @api recordId;
    draftValues = [];
    @track expense;
    @track typeOptions;
    @track wiredExpenseData;
    spinner = false;
    isDelete = false;
    expenseRecordId;
    @track rowDeleteFlag=true;

    //platform event
    channelName = '/event/SBR_3_0_Expense__e';
    subscription = {};
    @track expenseRecords = [];

    connectedCallback() {
        console.log('expense quote recordId: ', this.recordId);
        this.handleSubscribe();
    }

    handleSubscribe() {
        subscribe(this.channelName, -1, this.messageCallback).then(response => {
            console.log('Subscription request sent to : ', JSON.stringify(response.channel));
            this.subscription = response;
        });
    }

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

    @api refreshListData(){
        console.log('in refreshListData '+this.recordId);
        getQuotesExpenses({quoteId: this.recordId})
            .then( 
            result =>{
                console.log('in refreshListData11 '+JSON.stringify(result));
            if(result){
             this.expense = JSON.parse(JSON.stringify(result.data));
             console.log('in refreshListData1');
            }
            else {
            console.log('error getting refreshListData');
            }
            })
            .catch(error => {
            console.log(error);
            });


     //   this.refreshData();
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


    @wire(getQuotesExpenses, { quoteId: '$recordId' })
    wireExpense(result) {
        this.wiredExpenseData = result;
        if (result.data) {
            console.log('getQuotesExpenses -> ', JSON.parse(JSON.stringify(result.data)));
            console.log('this.typeOptions -> ', this.typeOptions);
            this.expense = JSON.parse(JSON.stringify(result.data));
            //this.setDependentPicklist();
        } else if (result.error) {
            console.log('error -> ' + JSON.stringify(result.error));
            this.expense = undefined;
        }
    }

    @wire(getObjectInfo, { objectApiName: EXPENSE_OBJECT })
    expenseObjectMetadata;

    //fetch picklist options
    @wire(getPicklistValues, {
        recordTypeId: "$expenseObjectMetadata.data.defaultRecordTypeId",
        fieldApiName: TYPE_FIELD
    })
    wirePickList({ error, data }) {
        if (data) {
            console.log('picklistValues result below:');
            console.log(data);
            this.typeOptions = data;
            this.setDependentPicklist();
        } else if (error) {
            console.log('picklistValues error below:');
            console.log(error);
        }
    }

    // get totalPrice(){
    //     let result = 0;
    //     this.expense.forEach(each => {
    //         if(each.Price__c){
    //             result += each.Price__c;
    //         }
    //     });
    //     return result;
    // }

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
        // Convert datatable draft values into record objects
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });

        // Clear all datatable draft values
        this.draftValues = [];

        try {
            // Update all records in parallel thanks to the UI API
            const recordUpdatePromises = records.map((record) =>
                updateRecord(record)
            );
            await Promise.all(recordUpdatePromises);

            // Report success with a toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Expenses updated',
                    variant: 'success'
                })
            );

            getQuotesExpenseRefresh({ quoteId: this.recordId })
                .then(result => {
                    console.log('result : ', result);
                    this.expense = result;
                })
                .catch(error => {
                    console.log('Error Occured : ', error);
                });

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating or reloading expenses',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }

    setDependentPicklist() {
        if (this.expense && this.typeOptions) {
            this.expense.forEach(ele => {
                let key = this.typeOptions.controllerValues[ele.Analysis_Region_Key__c];
                ele.typeOptions = this.typeOptions.values.filter(opt => opt.validFor.includes(key));
            })
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
                    this.expenseRecordId = row.Id;
                    console.log('this.expenseRecordId : ' + this.expenseRecordId);
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
                           // this.spinner = false;

                        })
                        .catch(error => {
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
        return refreshApex(this.wiredExpenseData);
    }
    get flowInputVariables() {
        return [{
            name: 'recordId',
            type: 'String',
            value: this.expenseRecordId
        }];
    }
    handleFlowStatusChange(event) {
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
                            message: outputVar.value,
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

}