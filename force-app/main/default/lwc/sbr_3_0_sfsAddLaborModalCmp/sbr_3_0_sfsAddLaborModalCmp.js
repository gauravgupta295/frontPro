import {api,wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WOLI_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import MECHANIC_NAME_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Mechanic_Name__c';
import RATE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Hourly_Internal_Rate__c';
import LINE_TYPE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Line_Type__c';
import DURATION_FIELD from '@salesforce/schema/WorkOrderLineItem.Duration';
import LABOR_CODE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Labor_Code__c';
import WORK_ORDER_ID_FIELD from '@salesforce/schema/WorkOrderLineItem.WorkOrderId';
import { createRecord } from 'lightning/uiRecordApi';
import  getServiceResource from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourceById';


export default class Sbr_3_0_sfsAddLaborModalCmp extends LightningModal{

// public/api Variable
@api headerText;
@api workOrderId;
@api woliId;
@api defaultServiceResourceId;
@api mechanicId;
@api mechanicRate;
@api lineTypeLabel;
@api lineTypeValue;
@api serviceResourceLaborType
@api isServiceLeader;
@api currRecords;
@api WoDescription;
@api woLaborCode;
// Local Variables
isMultipleTravelError=false;
valueLaborCode;
//valueTravelCode= '9010 - TRAVEL TIME';
valueTravelCode= '9010';
valueLaborHours;
valueTravelHours;
valueLineTypeLabor;
valueLineTypeTravel;
isLabor=false;
isTravel=false;
mechanicSfId;
recsTobeAddedTravel=[];
recsTobeAddedLabor=[];
recsTobeAdded=[];
mechanicRateTravel=1;
// Error Variables
errorMessageMechanicName=false;
errorMessageLineType=false;
isAccessError=false;
isSpinner=false;


// Connected call back life cycle hook LWC
connectedCallback() {
    this.mechanicSfId=this.defaultServiceResourceId;
    this.charCountTravelRate=String(1).length;
    // Bug - Now should be populated from work order
    this.valueLaborCode=this.woLaborCode;
    /*if(this.WoDescription == 'CHECK IN RETURN'){
        this.valueLaborCode='9100';
    }
    else if(this.WoDescription == 'ANNUAL INSPECTION'){
        this.valueLaborCode='9600';
    }
    else if(this.WoDescription && this.WoDescription!='Work Order Credit'){
        this.valueLaborCode='9000';
    }*/
}

// To get WOLI Object metadata 
@wire(getObjectInfo, { objectApiName: WOLI_OBJECT })
woliInfo;

// To get picklistvalues for Labor code
@wire(getPicklistValues,
    {
        recordTypeId: '$woliInfo.data.defaultRecordTypeId',
        fieldApiName:  'WorkOrderLineItem.SF_PS_Labor_Code__c'
    }
)laborCodeValues;

// Handle when user selects labor
handleLaborSelect(event){
    let check = event.detail.checked;
    if(check==true){
        this.isLabor=true;
        this.valueLineTypeLabor=event.target.value;
        console.log(event.target.value);
    }
    else{
        this.isLabor=false;
        this.valueLineTypeLabor=undefined;
    }
}

// Handle when user selects Travel
handleTravelSelect(event){
    let check = event.detail.checked;
    if(check==true){
        this.isTravel=true;
        this.valueLineTypeTravel=event.target.value;    
    }
    else{
        this.isTravel=false;
        this.isMultipleTravelError=false;
        this.valueLineTypeTravel=undefined;
    }
}

// Handle when user chnages Mechanic name i.e Service resource
handleMechanicNameChange(event){
    if(event.detail.selectedRecord.Id!=undefined){
        this.mechanicSfId=event.detail.selectedRecord.Id;
        getServiceResource({serviceResId:event.detail.selectedRecord.Id})
        .then(result=>{
            console.log('Handle: '+JSON.stringify(result));
            this.mechanicId=result[0].SF_PS_Mechanic_Id__c;
            this.mechanicRate=result[0].SF_PS_Hourly_Internal_Rate__c;
            this.serviceResourceLaborType=result[0].SF_PS_Labor_Type__c;
            if(result[0].SF_PS_Labor_Type__c=="I"){
                this.lineTypeLabel="Inside Labor"
                this.lineTypeValue="LI"
            }
            else if(result[0].SF_PS_Labor_Type__c=="O"){
                this.lineTypeLabel="Outside Labor"
                this.lineTypeValue="LO"
            // Deafult case   
            }
            else{
                this.lineTypeLabel="Inside Labor"
                this.lineTypeValue="LI"
            }
        });
    }
    else{
        this.mechanicSfId=undefined;
    }
}

// Handle Change for Labor Code
handleChangeLaborCode(event) {
    this.valueLaborCode = event.detail.value;
}

// Handle Change for Travel Code
handleChangeTravelCode(event) {
    this.valueTravelCode = event.detail.value;
}

// Handle Change for Labor Hours
handleLaborHoursChange(event){
    this.valueLaborHours = event.detail.value;
    let input= this.refs.laborHourInputField;
    let char=this.refs.charCountLabor;
    //Count charcters
    let content = input.value;
    char.textContent=' '+content.length;   
}

// Handle Chnage for Travel Hours
handleTravelHoursChange(event){
    this.valueTravelHours = event.detail.value;
    let input= this.refs.travelHourInputField;
    let char=this.refs.charCountTravel;
    //Count charcters
    let content = input.value;
    char.textContent=' '+content.length;
}

// Handle Chnage for Travel Rate (Only applicable from desktop and service leaders)
handleTravelRateChange(event){
    this.mechanicRateTravel=event.detail.value;
    let input= this.refs.laborHourTravelInputField;
    let char=this.refs.charCount;
    //Count charcters
    let content = input.value;
    this.charCountTravelRate=' '+content.length; 
}

// Handle click on Save
handleSave(){
    console.log(JSON.stringify(this.currRecords));
    if(this.isTravel && this.currRecords){
        this.currRecords.forEach(rec=>{
            if(rec.columnTwo=='Travel'){
                this.isMultipleTravelError=true;
            }
        })

        if(this.isMultipleTravelError){
            return;
        }
    }
    this.isMultipleTravelError=false;
    console.log(" Labor Code: "+ this.valueLaborCode+
        "\n Tavel Code: "+this.valueTravelCode+
        "\n Labor Hours: "+this.valueLaborHours+
        "\n Travel Hours: "+this.valueTravelHours+
        "\n Line Type Labor: "+this.valueLineTypeLabor+
        "\n Line Type Travel: "+this.valueLineTypeTravel+
        "\n Mechanic Id: "+this.mechanicId+
        "\n Mechanic Rate:"+ this.mechanicRate+
        "\n Mechanic Rate Travel:"+this.mechanicRateTravel+
        "\n  Mechanic SF ID:"+this.mechanicSfId+
        "\n  Travel checked:"+this.isTravel+
        "\n  Labor checked:"+this.isLabor
    );


    // Validation for EMPTY mechanic name field
    if(this.mechanicSfId==undefined){
        this.errorMessageMechanicName=true;
    }
    else{
        this.errorMessageMechanicName=false;
    }

    // Validation for Not selecting Line type
    if(this.isLabor==false && this.isTravel==false){
        this.errorMessageLineType =true;
    }
    else{
        this.errorMessageLineType =false;
    }

    // Validation for all inputs
    const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
                            .reduce((validSoFar, inputField) =>{
                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity();
                            }, true);
    // Validation for all  combobox/picklist
    const isComboBoxCorrect=[...this.template.querySelectorAll('lightning-combobox')]
                            .reduce((validSoFar, inputField) => {
                                inputField.reportValidity();
                                return validSoFar && inputField.checkValidity();
                            }, true);

    // Final validation for all fields on screen before saving
    if(isInputsCorrect && isComboBoxCorrect && this.errorMessageMechanicName==false && this.errorMessageLineType ==false){
        console.log("SAVE"); 
        // Saving here WOLI which were LIne Type is "Labor"
        if(this.isLabor==true && this.isTravel==false){
            this.addLabor();
        // Saving here WOLI which were LIne Type is "travel"  
        }
        else if(this.isTravel==true && this.isLabor==false){
            this.addTravel();
        // Saving two WOLI which were Line Type is "travel" and "Labor"     
        }
        else if(this.isTravel==true && this.isLabor==true){
            const fields = {};
            fields[MECHANIC_NAME_FIELD.fieldApiName]=this.mechanicSfId;
            fields[RATE_FIELD.fieldApiName]=this.mechanicRate;
            fields[LINE_TYPE_FIELD.fieldApiName]=this.valueLineTypeLabor;
            fields[DURATION_FIELD.fieldApiName]=this.valueLaborHours;
            fields[LABOR_CODE_FIELD.fieldApiName]=this.valueLaborCode;
            fields[WORK_ORDER_ID_FIELD.fieldApiName]=this.workOrderId;
            const recordInput = { apiName:WOLI_OBJECT.objectApiName,fields};
            this.isSpinner=true;
            // Labor record creation
            createRecord(recordInput)
            .then(result => {
                // To capture access error for sharing rules
                this.isAccessError=false;
                this.recsTobeAdded.push({
                    Id : result.id,
                    columnOne : this.mechanicId,
                    columnTwo : this.lineTypeLabel,
                    columnThree : String(this.valueLaborCode).substring(0,4),
                    ColumnFour : this.valueLaborHours,
                    ColumnFive : Number(Number(this.valueLaborHours)*Number(this.mechanicRate)).toFixed(2),
                    detail : JSON.stringify({   
                                                "SF_PS_Mechanic_Id__c" : this.mechanicId,
                                                "Id":this.mechanicSfId,
                                                "SF_PS_Hourly_Internal_Rate__c":this.mechanicRate,
                                                "SF_PS_Labor_Type__c":this.serviceResourceLaborType})
                                            });
                    // Travel record creation
                    const fields = {};
                    fields[MECHANIC_NAME_FIELD.fieldApiName] = this.mechanicSfId;
                    //fields[RATE_FIELD.fieldApiName]=this.mechanicRate;
                    fields[RATE_FIELD.fieldApiName] = this.mechanicRateTravel;
                    fields[LINE_TYPE_FIELD.fieldApiName] = this.valueLineTypeTravel;
                    fields[DURATION_FIELD.fieldApiName] = this.valueTravelHours;
                    fields[LABOR_CODE_FIELD.fieldApiName] = this.valueTravelCode;
                    fields[WORK_ORDER_ID_FIELD.fieldApiName] = this.workOrderId;
                    const recordInput = { apiName:WOLI_OBJECT.objectApiName,fields}
                    createRecord(recordInput).then(result => {
                        // To capture access error for sharing rules
                        this.isAccessError=false;
                        console.log("Create R"+JSON.stringify(result));
                        this.recsTobeAdded.push({
                            Id:result.id,
                            columnOne:this.mechanicId,
                            columnTwo:"Travel",
                            columnThree:String(this.valueTravelCode).substring(0,4),
                            ColumnFour:this.valueTravelHours,
                            ColumnFive:Number(Number(this.valueTravelHours)*Number(this.mechanicRateTravel)).toFixed(2),
                            detail:JSON.stringify({"SF_PS_Mechanic_Id__c":this.mechanicId,
                            "Id":this.mechanicSfId,"SF_PS_Hourly_Internal_Rate__c":this.mechanicRate,
                            "SF_PS_Labor_Type__c":this.serviceResourceLaborType})
                        });
                        // Created the event with the data.
                        const selectedEvent = new CustomEvent("addrow", {
                            detail: {'recs':this.recsTobeAdded}
                        });
                        // Dispatches the event.
                        this.dispatchEvent(selectedEvent);
                        this.isSpinner=false;
                        this.close('okay');
                    
                    }).catch(error => {
                        console.log("Erorr ADD Travel "+ JSON.stringify(error)); 
                        // To capture access error for sharing rules
                        this.isSpinner=false;
                        this.isLabor=false;
                        this.isTravel=false;
                        this.isAccessError=true;
                    })
                }).catch(error => {
                    console.log("Erorr ADD Labor "+ JSON.stringify(error)); 
                    // To capture access error for sharing rules
                    this.isSpinner=false;
                    this.isLabor=false;
                    this.isTravel=false;
                    this.isAccessError=true;
                })
        }
        //this.close('okay');
    }
}           

// To add Labor Hours
addLabor(){
    const fields = {};
    fields[MECHANIC_NAME_FIELD.fieldApiName] = this.mechanicSfId;
    fields[RATE_FIELD.fieldApiName] = this.mechanicRate;
    fields[LINE_TYPE_FIELD.fieldApiName] = this.valueLineTypeLabor;
    fields[DURATION_FIELD.fieldApiName] = this.valueLaborHours;
    fields[LABOR_CODE_FIELD.fieldApiName] = this.valueLaborCode;
    fields[WORK_ORDER_ID_FIELD.fieldApiName] = this.workOrderId;
    const recordInput = { apiName: WOLI_OBJECT.objectApiName,fields};
    this.isSpinner=true;
    createRecord(recordInput).then(result => {
        // To capture access error for sharing rules
        this.isAccessError=false;
        this.recsTobeAddedLabor.push({
            Id:result.id,
            columnOne:this.mechanicId,
            columnTwo:this.lineTypeLabel,
            columnThree:String(this.valueLaborCode).substring(0,4),
            ColumnFour:this.valueLaborHours,
            ColumnFive:Number(Number(this.valueLaborHours)*Number(this.mechanicRate)).toFixed(2),
            detail:JSON.stringify({"SF_PS_Mechanic_Id__c":this.mechanicId,
                    "Id":this.mechanicSfId,"SF_PS_Hourly_Internal_Rate__c":this.mechanicRate,
                    "SF_PS_Labor_Type__c":this.serviceResourceLaborType
                })
            });
        // Created the event with the data.
        const selectedEvent = new CustomEvent("addrow", {
            detail: {'recs':this.recsTobeAddedLabor}
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        this.isSpinner=false;
        this.close('okay');
    }).catch(error => {
        console.log("Erorr ADD Labor "+ JSON.stringify(error)); 
        // To capture access error for sharing rules
        this.isSpinner=false;
        this.isLabor=false;
        this.isTravel=false;
        this.isAccessError=true;
    })

}

// To add Travel Hours
addTravel(){
    const fields = {};
    fields[MECHANIC_NAME_FIELD.fieldApiName]=this.mechanicSfId;
    //fields[RATE_FIELD.fieldApiName]=this.mechanicRate;
    fields[RATE_FIELD.fieldApiName]=this.mechanicRateTravel;
    fields[LINE_TYPE_FIELD.fieldApiName]=this.valueLineTypeTravel;
    fields[DURATION_FIELD.fieldApiName]=this.valueTravelHours;
    fields[LABOR_CODE_FIELD.fieldApiName]=this.valueTravelCode;
    fields[WORK_ORDER_ID_FIELD.fieldApiName]=this.workOrderId;
    const recordInput = { apiName:WOLI_OBJECT.objectApiName,fields}
    this.isSpinner=true;
    createRecord(recordInput).then(result =>{
        // To capture access error for sharing rules
        this.isAccessError=false;
        console.log("Create R"+JSON.stringify(result));
        this.recsTobeAddedTravel.push({
            Id:result.id,
            columnOne:this.mechanicId,
            columnTwo:"Travel",
            columnThree:String(this.valueTravelCode).substring(0,4),
            ColumnFour:this.valueTravelHours,
            ColumnFive:Number(Number(this.valueTravelHours)*Number(this.mechanicRateTravel)).toFixed(2),
            detail:JSON.stringify({"SF_PS_Mechanic_Id__c":this.mechanicId,
                        "Id":this.mechanicSfId,"SF_PS_Hourly_Internal_Rate__c":this.mechanicRate,
                        "SF_PS_Labor_Type__c":this.serviceResourceLaborType})
            });
        // Created the event with the data.
        const selectedEvent = new CustomEvent("addrow", {
            detail: {'recs':this.recsTobeAddedTravel}
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        this.isSpinner=false;
        this.close('okay');
    }).catch(error => {
        console.log("Erorr ADD Labor "+ JSON.stringify(error)); 
        // To capture access error for sharing rules
        this.isSpinner=false;
        this.isLabor=false;
        this.isTravel=false;
        this.isAccessError=true;
    })
}
}