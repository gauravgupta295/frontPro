import { LightningElement,api,wire,track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import {FlowNavigationBackEvent,FlowAttributeChangeEvent,FlowNavigationNextEvent} from "lightning/flowSupport";

export default class Sbr_3_0_sfsWoTableBasedOnAsset extends LightningElement {
    // public properties with initial default values 
    @api defaultRecordId = ''; // To default record in look up
    @api selectedRecordId; // To give selectedRecordId as output of this component to consume in flow 
    @api recordId; // To pass list view filter Id
    @api rowCount=10 ; // To pass number of row to fetch on initial load and on load more event
    @api isReadonly=false;
    
    //Private properties
    columns=[   
                { label  : "SF Work Order#", fieldName : "WorkOrderNumberUrl" , type : "url" , typeAttributes: { label: { fieldName: 'WorkOrderNumber' }, target : "_blank", }},
                { label : "RM Work Order#", fieldName : "SF_PS_RM_WO_Number__c"},
                { label : "WO Description", fieldName : "SF_PS_Work_Order_Des__c"},
                { label : "Status", fieldName : "Status"},
            ];
    processedData=[]; // final data inside data table
    showTable=false; // to decide whether show table or not
    NoDataFound=false; // to Show block with info as no data found
    offset=10;
    initialRowCount;
    recordCount; //  records count fetched in wire call
    pageSize; //  offset in wire call result
    dynamicClass; // To show table height auto or fix 300px
    
    // To initialize properties 
    connectedCallback(){
        if(this.defaultRecordId){
            this.selectedRecordId=this.defaultRecordId;
        }
        console.log('disbale territory '+ this.isReadonly);
        this.initialRowCount=parseInt(this.rowCount);
        console.log('Checkpoint connect callback ::'+ typeof this.initialRowCount +'::'+this.initialRowCount)
        this.offset=this.initialRowCount;
    }
    
    // method to fetch WO record related to selected asset
    @wire(getRelatedListRecords, {
        parentRecordId: '$selectedRecordId',
        relatedListId: 'WorkOrders',
        fields: ['WorkOrder.Id','WorkOrder.SF_PS_RM_WO_Number__c','WorkOrder.WorkOrderNumber','WorkOrder.Status','WorkOrder.SF_PS_Work_Order_Des__c'],
        sortBy: ['WorkOrder.CreatedDate'],
        where: '{ and: [ {Status : { eq: "O" }}, { RecordType : { DeveloperName : {eq : "SF_PS_Inspection_Record"}}}]}',
        pageSize : '$offset'
    }) fetchedResult({error, data}){
        if(data){
            console.log('getRelatedListRecords Wire method is called '+ data.records.length);
            if(data.records.length>0){
                this.recordCount=data.count;
                this.pageSize=data.pageSize;
                this.showTable=true;
                this.NoDataFound=false;
                this.dynamicClass="tableContainer";
                if(this.recordCount < this.initialRowCount){
                    this.dynamicClass="autoHeightTable";
                }
                this.sentizeData(data.records);
            } else {
                this.NoDataFound=true;
                this.showTable=false;
            }
        }else if(error){
            this.processedData=[];
            this.NoDataFound=true;
            console.log('error::'+ JSON.stringify(error))
        }
    }

    // Event Handler for onchange
    handleOnChange(event){
        let selectedAssetId=this.template.querySelector('lightning-input-field').value;
        if(!selectedAssetId){
            this.processedData=[];
            this.showTable=false;
            this.NoDataFound=false;
            this.selectedRecordId=null;
        }else{
            this.selectedRecordId=selectedAssetId;
            this.offset=this.initialRowCount;
        }
    }

    //Event handler for onloadmore of data table
    loadMoreData(event){
        console.log('Inside load more event...');
        if(this.recordCount>=this.pageSize){
            this.offset=this.initialRowCount+this.offset;
        } else{
            event.target.enableInfiniteLoading = false;
        }
    }
    
    //Event handler of onnext of flow button lwc
    handleNext(event){
        if(this.selectedRecordId){
            console.log('Inside next event ');
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        else{
            this.showValidationError=true;
        }
    }

    //Event Handler of oncancel of flow button lwc
    handleCancel(event){
        let link= `${window.location.origin}/lightning/o/WorkOrder/list`;
        if(this.recordId){
            link+='?filterName='+this.recordId;
        }
        window.location.href=link;
    }

    // Method to format data in data table required format
    sentizeData(records){
       this.processedData= records.map( rec => {
            return {
                Id : rec.fields.Id.value,
                WorkOrderNumberUrl : '/'+rec.fields.Id.value,
                WorkOrderNumber : rec.fields.WorkOrderNumber.value,
                SF_PS_RM_WO_Number__c  : rec.fields.SF_PS_RM_WO_Number__c.value,
                Status : rec.fields.Status.displayValue,
                SF_PS_Work_Order_Des__c : rec.fields.SF_PS_Work_Order_Des__c.value
            }
        } )
       // console.log(JSON.stringify(this.processedData));
    }
}