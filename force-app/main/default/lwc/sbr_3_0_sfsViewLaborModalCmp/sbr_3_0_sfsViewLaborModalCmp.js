import { api,wire,track } from 'lwc';
import LightningModal from 'lightning/modal';
import MECHANIC_NAME_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Mechanic_Name__r.Name';
import RATE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Hourly_Internal_Rate__c';
import LINE_TYPE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Line_Type__c';
import DURATION_FIELD from '@salesforce/schema/WorkOrderLineItem.Duration';
import LABOR_CODE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Labor_Code__c';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';

const fieldList = [RATE_FIELD, LINE_TYPE_FIELD, DURATION_FIELD,LABOR_CODE_FIELD,MECHANIC_NAME_FIELD ];
export default class Sbr_3_0_sfsViewLaborModalCmp extends LightningModal {
    @api selectedRecordId;
    @api mechanicId;
    

    //Private properties 
    _recievedData;
    
    @track finalformattedData={};
    @track finalFieldLabels={};

    connectedCallback(){
        console.log("inside view modal :: "+ this.selectedRecordId);
    }
    //get Selected WOli details 
    @wire(getRecord ,{ recordId : '$selectedRecordId', fields : fieldList})
    WoliData({error,data}){
        debugger;
        if(data){
            this._recievedData=data.fields;
            this.finalformattedData={
                "column1" : getFieldValue(data, MECHANIC_NAME_FIELD),
                "column2" : this.mechanicId,
                "column3" : (this._recievedData.SF_PS_Hourly_Internal_Rate__c.value)? ('$'+ Number(this._recievedData.SF_PS_Hourly_Internal_Rate__c.value).toFixed(2)) : '-',
                "column4" : this._recievedData.SF_PS_Line_Type__c.displayValue,
                "column5" : this._recievedData.SF_PS_Labor_Code__c.displayValue,
                "column6" : this._recievedData.Duration.value
            }
        
            console.log("formatted Data::" +JSON.stringify(this.finalformattedData));
            if(this._recievedData.SF_PS_Line_Type__c.displayValue =="Travel"){
                this.finalFieldLabels={
                    "column1" : "Mechanic Name:",
                    "column2" : "Mechanic ID:",
                    "column3" : "Rate ($ per miles):",
                    "column4" : "Line Type:",
                    "column5" : "Labor Code:",
                    "column6" : "Miles:"
                }
            }
            else{
                this.finalFieldLabels={
                    "column1" : "Mechanic Name:",
                    "column2" : "Mechanic ID:",
                    "column3" : "Rate:",
                    "column4" : "Line Type:",
                    "column5" : "Labor Code:",
                    "column6" : "Hours:"
                }
            }
        }  
        else if(error){
            console.log("Error at wire for getselectedWOLI" + JSON.stringify(error));
        }
        
    }
}