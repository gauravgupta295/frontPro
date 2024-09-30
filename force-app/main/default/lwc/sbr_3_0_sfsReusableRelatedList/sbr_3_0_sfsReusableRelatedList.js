import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDynamicTableDataList from '@salesforce/apex/SBR_3_0_GetDynamicDataForDatatable.GetWrapperOfSObjectFieldColumnActionValues';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import UserPreferencesShowCityToExternalUsers from '@salesforce/schema/User.UserPreferencesShowCityToExternalUsers';

export default class Sbr_3_0_sfsReusableRelatedList extends NavigationMixin(LightningElement) {

    // try to get data by dynamically (We can add this LWC in edit page by passing this variable values)
    @track DataTableResponseWrappper;
    @track finalSObjectDataList;
    @api coloumnLableList = 'Product Consumed Number,Is Primary Part?,Stock class,Description,Quantity Unit Of Measure,Quantity,Shipped Quantity,Backordered Quantity,Selling Price,Extended Amount,Labor Code';
    @api fieldApiNamesWithType = 'ProductConsumedNumber:url,SF_PS_Is_Primary_Part__c:Checkbox,SF_PS_Stock_Class__c:text,SF_PS_Description__c:text,QuantityUnitOfMeasure:text,SF_PS_Quantity__c:text,SF_PS_Shipped_Qty__c:text,SF_PS_Backordered_Qty__c:text,SF_PS_Selling_Price__c:text,SF_PS_Sub_Total__c:text,SF_PS_Labor_Code__c:text';
    @api fieldApiNamesWithoutType = 'ProductConsumedNumber,SF_PS_Is_Primary_Part__c,SF_PS_Stock_Class__c,SF_PS_Description__c,QuantityUnitOfMeasure,SF_PS_Quantity__c,SF_PS_Shipped_Qty__c,SF_PS_Backordered_Qty__c,SF_PS_Selling_Price__c,SF_PS_Sub_Total__c,SF_PS_Labor_Code__c';
    @api relatedObjectApiName = 'ProductConsumed';
    @api parentFieldApiName = 'WorkOrderId';
    @api recordSize = '250';
    @api viewAll =false;
    // for lwc to another lwc call we use this Variables
    //@api actions;
    @api column;
    @api useInLwcParentChildCmp = false;
    @api recordsData;

    // comman variable for lwc and flow use
    @api title='Parts And Misc Items';
    @api recordId;
    @api icon = 'standard:product_consumed';
    @api parentObjectAPIName = 'WorkOrder';
    @api iconulternativeText = 'Product Consumed';
    @api relatedListObjectName = 'ProductsConsumed';
    @api sortFieldName = 'ProductConsumedNumberUrl';
    headerCountMsg ='0 items ';
    @api recordDisplayLimit = 10;
    processedData=[]; // final data inside data table
    workOrderId;
    recordCount=0;
    pageSize;
    hasMoreRecords=false;
    showTable=false;
    sortDirection = 'asc';
    sortedBy;
    countOfRec;
    hasSpinnerLoaderStart = false;
    displayRecs;


    connectedCallback(){
        this.workOrderId=this.recordId;
        console.log('this.useInLwcParentChildCmp::'+this.useInLwcParentChildCmp);
        if(this.useInLwcParentChildCmp == true ){
            this.processedData = this.recordsData;
            console.log('process data of lwc :::'+JSON.stringify(this.processedData));
            //this.DataTableResponseWrappper['lstDataTableColumns'] = this.column;
            if(this.processedData.length>this.recordDisplayLimit){
                this.headerCountMsg =  this.recordDisplayLimit+'+ items ';
                this.recordCount = this.recordDisplayLimit;
                this.hasMoreRecords = true;
            } else {
                this.headerCountMsg = this.processedData.length + ' items ';
                this.recordCount = this.processedData.length;
                this.hasMoreRecords = false;
            }
            if(this.processedData.length>0){
                this.showTable=true;
            }
        } else {
            this.handleRefresh();
        }
    }

    // Call By handleRefresh function
    handleDataChange(data){
        let sObjectRelatedFieldListValues = [];
        for (let row of data.lstDataTableData)
        {
            const finalSobjectRow = {}
            let rowIndexes = Object.keys(row);
            rowIndexes.forEach((rowIndex) =>
            {
                const relatedFieldValue = row[rowIndex];
                if(relatedFieldValue.constructor === Object)
                {
                    this._flattenTransformation(relatedFieldValue, finalSobjectRow, rowIndex)
                }
                else
                {
                    finalSobjectRow[rowIndex] = relatedFieldValue;
                }
            });
            sObjectRelatedFieldListValues.push(finalSobjectRow);
        }
        this.DataTableResponseWrappper = data;
        this.finalSObjectDataList = sObjectRelatedFieldListValues;
        this.countOfRec = data.sizeOfRecords;
        this.recordCount = this.finalSObjectDataList.length;
        if(Number(data.sizeOfRecords)>this.recordDisplayLimit){
            this.headerCountMsg = this.recordDisplayLimit + '+ items ';
            this.hasMoreRecords = true;
        } else {
            this.headerCountMsg = data.sizeOfRecords + ' items ';
            this.hasMoreRecords = false;
        }
        this.sentizeData(this.finalSObjectDataList);
        
        
        if(this.processedData.length ==0){
            this.showTable = false;
            this.headerCountMsg = '';
        }else {
            this.sortedBy = this.sortFieldName;
            this.showTable = true;
            this.sortDataByField(this.sortedBy,this.sortDirection);
        }
        //changed by vikas SERV-14207
       // this.displayRecs=this.processedData;
        if(this.processedData.length>this.recordDisplayLimit){
            this.processedData= this.processedData.slice(0,10); 
        }
    }

    _flattenTransformation = (fieldValue, finalSobjectRow, fieldName) =>
    {
        let rowIndexes = Object.keys(fieldValue);
        rowIndexes.forEach((key) =>
        {
            let finalKey = fieldName + '.'+ key;
            finalSobjectRow[finalKey] = fieldValue[key];
        })
    }

    // Method to format data in data table required format
    sentizeData(records){
        this.processedData= records.map( rec => {
            let newUrlFields = {};
            let firstRow = true;
            this.fieldApiNamesWithType.split(',').forEach((fieldApiName) =>
            {
                if(firstRow == true){
                    if(fieldApiName.split(':').length == 3){
                        if(rec[fieldApiName.split(':')[1]] != undefined){
                            newUrlFields[fieldApiName.split(':')[0]] = '/'+rec['Id'];
                        }
                    }
                }
                else {
                    if(fieldApiName.split(':').length == 4){
                        if(rec[fieldApiName.split(':')[1]] != undefined){
                            newUrlFields[fieldApiName.split(':')[0]] = '/'+rec[fieldApiName.split(':')[1]];
                            rec[fieldApiName.split(':')[1]] = rec[fieldApiName.split(':')[2]];
                        }
                    }
                }
                firstRow = false;
            });
            return {
                ...rec,
                ...newUrlFields
                }
        });
    }

    get Title() {
        //changed by vikas SERV-14207
        let count=10;
        if(Number(this.countOfRec)<=this.recordDisplayLimit){
            count=this.countOfRec;
        }
        let title = this.title +' (' + count;
        if(this.hasMoreRecords){
            title+='+'
        }
        title+= ')';
        return title;
    }

    showAllList() {
        if(this.useInLwcParentChildCmp == true ){
            // Created the event with the data.
            const viewAllAction = new CustomEvent("handleviewallaction");
            // Dispatches the event.
            this.dispatchEvent(viewAllAction);
        }else {
            var compDefinition = {
                componentDef: "c:sbr_3_0_sfsReusableRelatedList",
                attributes: {
                    title:this.title,
                    icon :this.icon,
                    column:this.column,
                    relatedListObjectName :this.relatedListObjectName,
                    sortFieldName: this.sortFieldName,
                    headerCountMsg:'0 items ',
                    recordDisplayLimit:30,
                    coloumnLableList: this.coloumnLableList,
                    fieldApiNamesWithType:this.fieldApiNamesWithType,
                    fieldApiNamesWithoutType:this.fieldApiNamesWithoutType,
                    relatedObjectApiName:this.relatedObjectApiName,
                    parentFieldApiName:this.parentFieldApiName,
                    parentObjectAPIName:this.parentObjectAPIName,
                    iconulternativeText:this.iconulternativeText,
                    relatedListObjectName :this.relatedListObjectName,
                    sortFieldName:this.sortFieldName,
                    useInLwcParentChildCmp:'false',
                    recordId:this.workOrderId,
                    viewAll:true
    }
            };
            // Base64 encode the compDefinition JS object
            var encodedCompDef = btoa(JSON.stringify(compDefinition));
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/one/one.app#' + encodedCompDef
                }
            });
            /*this[NavigationMixin.Navigate]({
                type: 'standard__recordRelationshipPage',
                attributes: {
                    recordId: this.workOrderId,
                    objectApiName: this.parentObjectAPIName,
                    relationshipApiName: this.relatedListObjectName,
                    actionName: 'view'
                }
            });*/
        }
    }

    handleRowActions(event) {
        if(this.useInLwcParentChildCmp == true ){
            const clickedActionName = event.detail.action.name;
            const row = event.detail.row;
            console.log('row.Id:::'+row.Id);
            // Created the event with the data.
            const rowActionEvent = new CustomEvent("handlerowaction", {
                detail:{id: row.Id,rowactionname: clickedActionName}
            });
            // Dispatches the event.
            this.dispatchEvent(rowActionEvent);
        }else {
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            this.recordId = row.Id;
            switch (actionName) {
                case 'view':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: row.Id,
                            actionName: 'view'
                        }
                    });
                    break;
                case 'edit':
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: row.Id,
                            objectApiName: this.relatedObjectApiName,
                            actionName: 'edit'
                        }
                    });
                    break;
                case 'delete':
                    this.delRecord(row);
                    break;
            }
        }
    }

    delRecord(row)
    {
        this.hasSpinnerLoaderStart = true;
        deleteRecord(row.Id).then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Record deleted",
                    variant: "success",
                }),
            );
            this.handleRefresh();
            this.hasSpinnerLoaderStart = false;
        }).catch((error) => {
            console.log('error:::'+JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error deleting record",
                    message: error?.body?.message+'/n' + error?.body?.output?.errors[0]?.message,
                    variant: "error",
                }),
            );
            this.hasSpinnerLoaderStart = false;
        });
    }

    handleCreateRecord()
    {
        if(this.useInLwcParentChildCmp == true ){
            // Created the event with the data.
            const createRecordEvent = new CustomEvent("handlecreaterecord");
            // Dispatches the event.
            this.dispatchEvent(createRecordEvent);
        } else {
            const defaultValues = encodeDefaultFieldValues({
                WorkOrderId: this.workOrderId
            });
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.relatedObjectApiName,
                    actionName: 'new'
                },
                state: {
                    defaultFieldValues: defaultValues,
                },
            });
        }
    }

    sortBy(field, reverse, primer){
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };
        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    handleSortdata(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        if(this.useInLwcParentChildCmp == true ){
            this.sortDataByFieldByAnotherLWC(sortedBy,sortDirection);
        }else {
            this.sortDataByField(sortedBy,sortDirection);
        }
    }

    sortDataByField(sortedBy ,sortDirection ){
        const cloneData = [...this.processedData];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.processedData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
        const sortByCol = this.DataTableResponseWrappper.lstDataTableColumns.find(column => this.sortedBy === column.fieldName);
        if(this.countOfRec>this.recordDisplayLimit){
            this.headerCountMsg = this.recordDisplayLimit+'+ items ' + ' • Sorted by '+sortByCol.label;
        } else {
            this.headerCountMsg =  this.countOfRec + ' items ' + ' • Sorted by '+sortByCol.label;
        }
    }

    sortDataByFieldByAnotherLWC(sortedBy ,sortDirection ){
        const cloneData = [...this.processedData];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.processedData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
        const sortByCol = this.column.find(column => this.sortedBy === column.fieldName);
        if(this.countOfRec>this.recordDisplayLimit){
            this.headerCountMsg = this.recordDisplayLimit+'+ items ' + ' • Sorted by '+sortByCol.label;
        } else {
            this.headerCountMsg =  this.countOfRec + ' items ' + ' • Sorted by '+sortByCol.label;
        }
    }

    handleRefresh(){
        if(this.useInLwcParentChildCmp == true ){
            // Created the event with the data.
            const selectedEvent = new CustomEvent("handleonrefresh");
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        } else {
            this.hasSpinnerLoaderStart = true;
            getDynamicTableDataList({ columLableList : this.coloumnLableList,fieldApiNamesWithType : this.fieldApiNamesWithType, fieldApiNamesWithoutType : this.fieldApiNamesWithoutType , relatedObjectApiName :this.relatedObjectApiName , parentFieldApiName : this.parentFieldApiName, recordId : this.workOrderId,recordSize: this.recordSize})
            .then((result) => {
                this.handleDataChange(result);
                this.hasSpinnerLoaderStart = false;
            })
            .catch((error) => {
                this.error = error;
                this.showTable = false;
                this.hasSpinnerLoaderStart = false;
            });
        }
    }

}