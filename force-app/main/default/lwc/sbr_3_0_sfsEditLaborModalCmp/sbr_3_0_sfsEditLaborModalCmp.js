import { api,wire } from 'lwc';
import LightningModal from 'lightning/modal';
import MECHANIC_NAME_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Mechanic_Name__c';
import RATE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Hourly_Internal_Rate__c';
import LINE_TYPE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Line_Type__c';
import DURATION_FIELD from '@salesforce/schema/WorkOrderLineItem.Duration';
import LABOR_CODE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Labor_Code__c';
import WORK_ORDER_ID_FIELD from '@salesforce/schema/WorkOrderLineItem.WorkOrderId';
import WOLI_ID_FIELD from '@salesforce/schema/WorkOrderLineItem.Id';
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord} from "lightning/uiRecordApi";
import  getServiceResource from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourceById';

const fields = [RATE_FIELD, LINE_TYPE_FIELD, DURATION_FIELD,LABOR_CODE_FIELD,MECHANIC_NAME_FIELD ];

export default class Sbr_3_0_sfsEditLaborCmp extends LightningModal{
   // API Variables
   @api headerText;
   @api workOrderId;
   @api woliId;
   @api serviceResourceId;
   @api mechanicId;
   @api laborCodeArray=[];
   @api lineTypeArray=[];
   @api selectedMechanicRate;
   @api serviceResourceLaborType;
   @api isServiceLeader;
   // Local Variables
   mechanicRate;
   lineType;
   duration;
   laborCode;
   mechanicSfId
   charCountHours=0;
   lineTypeValue;
   laborCodeValue;
   labelRate='Rate:';
   labelHoursOrMiles="Hours/Miles:"
   charCountTravelRate;
   // Error Message Variables
   errorMessageMechanicName=false;
   errorMessageLineType=false;
   serviceResourceRate;
   hoursHelpText=true;
   isAccessError=false;

 // To get woli that is to be

@wire(getRecord, {
    recordId: "$woliId",
    fields
})
 editWoli({error,data}){
     if(data){
        console.log("data:"+JSON.stringify(data));
        this.duration=data.fields.Duration.value;
        this.charCountHours=String(this.duration).length;
        this.charCountTravelRate=String(1).length;
        this.lineTypeLabel=data.fields.SF_PS_Line_Type__c.displayValue;  // label
        this.laborCodeLabel=data.fields.SF_PS_Labor_Code__c.displayValue;// label
        this.lineTypeValue=data.fields.SF_PS_Line_Type__c.value; // Api name
        this.laborCodeValue=data.fields.SF_PS_Labor_Code__c.value; // Api Name
        // For travel , Change label to 'Rate($ per mile)' and 'Rate=1'
        if( this.lineTypeLabel=='Travel'){
            this.mechanicRate=1;
            this.labelRate='Rate ($ per miles):';
            this.serviceResourceRate=this.selectedMechanicRate;
            this.hoursHelpText=false;
            this.labelHoursOrMiles='Miles:';
            let input= this.refs.inputField;
            input.step='1';
            
        }else{
            this.mechanicRate=data.fields.SF_PS_Hourly_Internal_Rate__c.value;
              // To store seperate service resource rate (To be used in line type change handler)
            this.serviceResourceRate=data.fields.SF_PS_Hourly_Internal_Rate__c.value;
            this.hoursHelpText=true;
            this.labelHoursOrMiles='Hours:';
            // Rferencing hours/miles field
            let input= this.refs.inputField;
            input.step='0.01';
        }   
        // Remove duplicates for selected values : Line Type and 
        //for Service leader showl all three values (Inside , Outside and Travel)
        //for Technicain from phone two values (Inside , Travel)
        let tempArrayLineType=[];
        console.log("Service Leader: "+this.isServiceLeader);
        if(this.isServiceLeader==true){
            for(let dt of this.lineTypeArray){
                if(dt.value==this.lineTypeValue){
                }else{
                        tempArrayLineType.push(dt);
                }
          }
        }else if(this.lineTypeValue=='MC'){
            tempArrayLineType.push({attributes: null, label: 'Inside Labor', validFor: Array(0), value: 'LI'})
        }else if(this.lineTypeValue=='LI'){
            tempArrayLineType.push({"attributes":null,"label":"Travel","validFor":[],"value":"MC"});
        }else{
            tempArrayLineType.push({"attributes":null,"label":"Travel","validFor":[],"value":"MC"});
        }


        this.lineTypeArray=tempArrayLineType;
        console.log(JSON.stringify(this.lineTypeArray));
        // Remove duplicates for selected values : Labor Code
        let tempArrayLaborCode=[];
        for(let dt of this.laborCodeArray){
            if(dt.value==this.laborCodeValue){
            }else{
                tempArrayLaborCode.push(dt) 
            }
        }
       this.laborCodeArray=tempArrayLaborCode;

     }
 }

// Connected Call back LWC life cycle hook
connectedCallback() {
//this.mechanicSfId=this.defaultServiceResourceId;

}

// Handle when user chnages Mechanic name i.e Service resource
handleMechanicNameChange(event){
console.log("Service Resource Id:"+event.detail.selectedRecord.Id);
if(event.detail.selectedRecord.Id!=undefined){
    this.serviceResourceId=event.detail.selectedRecord.Id;
    this.lineType=this.template.querySelector("[data-field='LineType']").value;
    getServiceResource({serviceResId:event.detail.selectedRecord.Id})
    .then(result=>{
        this.mechanicId=result[0].SF_PS_Mechanic_Id__c;
        // For travel , Change label to 'Rate($ per mile)' and 'Rate=1'
        if(this.lineType=='MC'){
            this.mechanicRate=1;
            this.labelRate='Rate ($ per miles):';
              // To store seperate service resource rate (To be used in line type change handler)
              this.serviceResourceRate=result[0].SF_PS_Hourly_Internal_Rate__c;
        }else{
            this.mechanicRate=result[0].SF_PS_Hourly_Internal_Rate__c;
            // To store seperate service resource rate (To be used in line type change handler)
            this.serviceResourceRate=result[0].SF_PS_Hourly_Internal_Rate__c;
            this.serviceResourceLaborType=result[0].SF_PS_Labor_Type__c;
        }
        console.log("Service Resource Id:"+this.mechanicId+ this.mechanicRate);
    }).catch(error=>{
        console.log("ERROR:"+JSON.stringify(error));
    });
    }else{
        this.serviceResourceId=undefined;
    }   
}

handleChangeLineType(){
    this.lineType=this.template.querySelector("[data-field='LineType']").value;
    if(this.lineType=='MC'){
        this.mechanicRate=1;
        this.labelRate='Rate ($ per miles):';
        this.hoursHelpText=false;
        this.labelHoursOrMiles='Miles:';
        let input= this.refs.inputField;
        input.step='1';
    }else{
        console.log(this.serviceResourceRate);
        this.mechanicRate=this.serviceResourceRate;
        this.labelRate='Rate:';
        this.hoursHelpText=true;
        this.labelHoursOrMiles='Hours:';
        let input= this.refs.inputField;
        input.step='0.01';
    }
}

//Handle change of Labor Hours
handleLaborHoursChange(event){
    this.duration= event.detail.value;
    let input= this.refs.inputField;
    let char=this.refs.charCount;
    //Count charcters
    let content = input.value;
    this.charCountHours=' '+content.length;    
}

// Handle Chnage for Travel Rate (Only applicable from desktop and service leaders)
handleTravelRateChange(event){
    console.log("Travels RATE: "+event.detail.value);
    this.mechanicRate=event.detail.value;
    let input= this.refs.laborHourTravelInputField;
    let char=this.refs.charCount;
    //Count charcters
    let content = input.value;
    this.charCountTravelRate=' '+content.length;   
}

// Handle save change
handleSave(){
      
    console.log(" Labor Code: "+ this.template.querySelector("[data-field='LaborCode']").value+
    "\n  Duration: "+this.duration+
    "\n Line Type : "+this.template.querySelector("[data-field='LineType']").value+
    "\n Mechanic Id: "+this.mechanicId+
    "\n Mechanic Rate:"+ this.mechanicRate+
    "\n  Mechanic SF ID:"+this.serviceResourceId+
    "\n WOLI ID:"+this.woliId
  );

       

    let recsToBeEdited={}
        recsToBeEdited.Id=this.woliId
        recsToBeEdited.columnOne=this.mechanicId
        if(this.template.querySelector("[data-field='LineType']").value=='MC'){
            recsToBeEdited.columnTwo='Travel'  
        }else if(this.template.querySelector("[data-field='LineType']").value=='LI'){
            recsToBeEdited.columnTwo='Inside Labor'  
        }else if(this.template.querySelector("[data-field='LineType']").value=='LO'){
            recsToBeEdited.columnTwo='Outside Labor'  
        }
        recsToBeEdited.columnThree=String(this.template.querySelector("[data-field='LaborCode']").value).substring(0,4);
        recsToBeEdited.ColumnFour=this.duration;
        recsToBeEdited.ColumnFive=(Number(this.duration)*Number(this.mechanicRate)).toFixed(2);
        recsToBeEdited.detail=JSON.stringify({"SF_PS_Mechanic_Id__c":this.mechanicId,
                    "Id":this.serviceResourceId,"SF_PS_Hourly_Internal_Rate__c":this.mechanicRate,
                    "SF_PS_Labor_Type__c":this.serviceResourceLaborType});

    // Validation for EMPTY mechanic name field
    if(this.serviceResourceId==undefined){
        this.errorMessageMechanicName=true;
    }else{
        this.errorMessageMechanicName=false;
    }
    // Validation for all inputs    
    const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
    }, true);

    // Final validation for all fields on screen before editing
    if(isInputsCorrect && this.errorMessageMechanicName==false){
        console.log("EDIT");
        // Create the recordInput object
        const fields = {};
        fields[MECHANIC_NAME_FIELD.fieldApiName]=this.serviceResourceId;
        fields[RATE_FIELD.fieldApiName]=this.mechanicRate;
        fields[LINE_TYPE_FIELD.fieldApiName]=this.template.querySelector("[data-field='LineType']").value;
        fields[DURATION_FIELD.fieldApiName]=this.duration;
        fields[LABOR_CODE_FIELD.fieldApiName]=this.template.querySelector("[data-field='LaborCode']").value;
        fields[WOLI_ID_FIELD.fieldApiName]=this.woliId;
        console.log("Fields: "+ JSON.stringify(fields));
        const recordInput = { fields };
        // Updating record here 
        updateRecord(recordInput)
        .then(result => {
            console.log("Success EDIT: "+ result);
            this.isAccessError=false;
            // Created the event with the data.
            const selectedEvent = new CustomEvent("editrow",{
            detail: {'recs':recsToBeEdited}
            });

            // Dispatches the event.
            this.dispatchEvent(selectedEvent);

            // Closes the popup/Modal
            this.close('okay');
        })
        .catch(error => {
            console.log("Erorr EDIT: "+ JSON.stringify(error));
            this.isAccessError=true;
        })

      
    }

}

}