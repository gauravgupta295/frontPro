import {LightningElement,api,wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WS_OBJECT from '@salesforce/schema/WorkOrder';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord} from "lightning/uiRecordApi";
import WO_DESC from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Work_Order_Des__c';
import CLAIM_TYPE from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Claim_Type__c';
import COMPLAINT_FIELD from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Complaint__c';
import CAUSE_FIELD from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Cause__c';
import CURE_FIELD from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Cure__c';
import EXCHANGE_REQ from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Exchange_Required__c';
import SERVICE_CALL from '@salesforce/schema/WorkStep.WorkOrder.SF_PS_Service_Call__c';
import PC_LABOR_CODE from "@salesforce/schema/WorkStep.WorkOrder.SF_PS_LaborCode__c";
import WO_ID_FIELD from '@salesforce/schema/WorkStep.WorkOrder.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import {
    ToastTypes
} from "c/utilsImageCapture";


const fields = [WO_DESC, CLAIM_TYPE, COMPLAINT_FIELD,CAUSE_FIELD,CURE_FIELD,PC_LABOR_CODE,EXCHANGE_REQ,SERVICE_CALL,WO_ID_FIELD ];

export default class Sbr_3_0_sfs_complaintCauseCureCmp extends LightningElement {

    complaintValue;
    causeValue;
    cureValue;
    woDesc;
    claimType;
    valueLaborCode;
    exchangeValue;
    serviceCallValue = 'Y';
    laborCodeValues;
    wsInfo;
    @api recordId;
    exchangeReqOptions;
    serviceCallOptions;
    wsId;
    woId;
    charCountComplaint = 0;
    charCountCause = 0;
    charCountCure = 0;
    hideToast
    toastType = null;
    WoRec;
    isSpinner=false;

    // Get object information
    @wire(getObjectInfo, { objectApiName: WS_OBJECT })
    wsInfo;

    //get picklist field values
    @wire(getPicklistValues,{
        recordTypeId: '$wsInfo.data.defaultRecordTypeId',
        fieldApiName:  'WorkOrder.SF_PS_LaborCode__c'
    })WorkOrderlaborCodeValues({error,data}){
        if(data){
            this.laborCodeValues=data.values;
        }
        else{
            console.log(JSON.stringify(error));
        }
    }

    //get picklist field values
    @wire(getPicklistValues,{
        recordTypeId: '$wsInfo.data.defaultRecordTypeId',
        fieldApiName:  'WorkOrder.SF_PS_Exchange_Required__c'
    })WorkOrderExchangeReqValues({error,data}){
        if(data){
            this.exchangeReqOptions=data.values;
        }
        else{
            console.log(JSON.stringify(error));
        }
    }

    //get picklist field values
    @wire(getPicklistValues,{
        recordTypeId: '$wsInfo.data.defaultRecordTypeId',
        fieldApiName:  'WorkOrder.SF_PS_Service_Call__c'
    })WorkOrderServiceCallValues({error,data}){
        if(data){
            this.serviceCallOptions=data.values;
        }
        else{
            console.log(JSON.stringify(error));
        }
    }

    @wire(getRecord, {
        recordId: "$wsId",
        fields
    })getDataOfWO({error,data}){
        if(data){
            this.WoRec=data;
            this.woDesc=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_Work_Order_Des__c?.value;
            this.complaintValue=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_Complaint__c?.value;
            this.causeValue=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_Cause__c?.value;
            this.cureValue=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_Cure__c?.value;
            this.claimType=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_Claim_Type__c?.value;
            this.valueLaborCode=this.WoRec?.fields?.WorkOrder?.value?.fields?.SF_PS_LaborCode__c?.value;
            this.woId=this.WoRec?.fields?.WorkOrder?.value?.fields?.Id?.value;
            this.charCountComplaint = this.complaintValue ? this.complaintValue.length : 0;
            this.charCountCause = this.causeValue ? this.causeValue.length : 0;
            this.charCountCure = this.cureValue ? this.cureValue.length : 0;
            this.isSpinner=false;
        }else{
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong. Ask your Salesforce admin for help.',
                    variant: 'Error',
                }),
            );
            this.isSpinner=false;
        }
    }

    //Display toast message
    get shouldShowToast() {
        return this.toastType != null;
    }

    get toastMessage() {
        return 'Work Step Status "Completed"'
    }

    //Get Work Order Field Values
    connectedCallback(){
        this.isSpinner=true;
        this.wsId = this.recordId;
    }

    handleComplaintChange(event){
        this.complaintValue = event.detail.value;
        if(this.complaintValue.length >= 51){
            this.complaintValue=this.complaintValue.substring(0, 50);
        }
        this.charCountComplaint = ' '+this.complaintValue.length;

    }

    handleCauseChange(event){
        this.causeValue = event.detail.value;
        if(this.causeValue.length >= 51){
            this.causeValue=this.causeValue.substring(0, 50);
        }
        this.charCountCause = ' '+this.causeValue.length;
    }

    handleCureChange(event){
        this.cureValue = event.detail.value;
        if(this.cureValue.length >= 51){
            this.cureValue=this.cureValue.substring(0, 50);
        }
        this.charCountCure = ' '+this.cureValue.length;
    }

    handleChangeLaborCode(event){
        console.log('event.detail.value:::'+event.detail.value);
        this.valueLaborCode = event.detail.value;
    }

    handleExchange(event){
        this.exchangeValue = event.detail.value;
    }

    handleServiceCallChange(event){
        this.serviceCallValue = event.detail.value;
    }

    //Validate All Required Field Values are filled or not.
    validateInputValues(){
        var isValid = true;
        var inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    hideToast() {
        this.toastType = null;
        this.closeAction();
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    //Update Field Values
    updateWO(){
        this.isSpinner=true;
        var validateSuccess = this.validateInputValues();
        if( validateSuccess == true){
            let fields = {};//WO_DESC, CLAIM_TYPE, COMPLAINT_FIELD,CAUSE_FIELD,CURE_FIELD,PC_LABOR_CODE,EXCHANGE_REQ,SERVICE_CALL
            fields['SF_PS_Complaint__c']=this.complaintValue;
            fields['SF_PS_Cause__c']=this.causeValue;
            fields['SF_PS_Cure__c']=this.cureValue;
            fields['SF_PS_LaborCode__c']=this.valueLaborCode;
            fields['SF_PS_Exchange_Required__c']=this.exchangeValue;
            fields['SF_PS_Service_Call__c']=this.serviceCallValue;
            fields['Id']=this.woId;
            var recordInput = { fields };
            // Updating record here
            updateRecord(recordInput).then(result => {
                fields={};
                fields['Id']= this.wsId;
                fields['Status']="Pass";
                let WS_recordInputMap = { fields };
                updateRecord(WS_recordInputMap).then(WS_result => {
                    this.toastType = ToastTypes.Success;
                    refreshApex(this.WoRec);
                    window.setTimeout(()=>{
                        this.isSpinner=false;
                        this.closeAction();
                    },2000);
                }).catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Something went wrong. Ask your Salesforce admin for help.',
                            variant: 'Error',
                        }),
                    );
                    this.isSpinner=false;
                }).catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Something went wrong. Ask your Salesforce admin for help.',
                            variant: 'Error',
                        }),
                    );
                    this.isSpinner=false;
                })
            })
        } else {
            this.isSpinner=false;
        }
    }

}