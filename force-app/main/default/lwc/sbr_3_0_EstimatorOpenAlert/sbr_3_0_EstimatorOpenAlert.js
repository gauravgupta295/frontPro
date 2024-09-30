import { LightningElement,api,wire} from 'lwc';
import getEstimatorDays from '@salesforce/apex/SBR_3_0_EstimatorOpenAlertController.getEstimatorOpenDays';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_DESC from '@salesforce/schema/WorkOrder.SF_PS_Work_Order_Des__c';
import {getRecord} from "lightning/uiRecordApi";

export default class Sbr_3_0_EstimatorOpenAlert extends LightningElement {
    @api recordId;
    @api label;
    @api calledFrom      = 'EstimatorOpenAlert';
    @api backgroundStyle = 'background-color: #f5cb1f';
    
    showEstimatorOpenAlert       = false;
    showEstimatorNotCreatedAlert = false;
    woStatus;
    woDesc;

    @wire (getRecord,{recordId:'$recordId',fields:[WO_DESC,WO_STATUS]})
    workOrderData({data,error}) {
        if(this.calledFrom == 'EstimatorOpenAlert'){
            if(data){
                console.log('JSON. '+JSON.stringify(data));
                this.woStatus = data.fields.Status.value;
                this.woDesc = data.fields.SF_PS_Work_Order_Des__c.value;
                if( this.woStatus == 'C' || this.woStatus == 'D' || this.woStatus == 'Closed with Exception' || this.woStatus == 'Cancel with Exception') {
                    this.showEstimatorOpenAlert = false;
                }
            }
            if(error){
                console.log('error occured '+JSON.stringify(error));
            }
        }
    }


    connectedCallback() {
        if(this.calledFrom == 'EstimatorOpenAlert'){
            getEstimatorDays({
                woOrDERecordId: this.recordId
            })
            .then((result) => {
                console.log("result : "+result);
                console.log("this.woStatus : ",this.woStatus)
                if(result != undefined && this.woStatus != 'C' && this.woStatus != 'D' && this.woStatus != 'Closed with Exception' && this.woStatus != 'Cancel with Exception') {
                    this.showEstimatorOpenAlert = true;
                    this.label = 'Estimator Open For ' + result.toString() + ' Days';   
                }
            })
            .catch((error) => {
                console.log("some error in code:", JSON.stringify(error));
            });
        } else if(this.calledFrom == 'EstimatorNotCreatedAlert'){
            this.showEstimatorNotCreatedAlert = true;
        }
    }

    get showAlert(){
        return (this.showEstimatorOpenAlert || this.showEstimatorNotCreatedAlert);
    }
}