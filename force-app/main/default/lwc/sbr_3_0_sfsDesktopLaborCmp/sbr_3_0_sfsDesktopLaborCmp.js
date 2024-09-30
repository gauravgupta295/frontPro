import { LightningElement,api,track,wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WOLI_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import LABOR_CODE_FIELD from '@salesforce/schema/WorkOrderLineItem.SF_PS_Labor_Code__c';
import  getServiceResource from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourceById';
import {FlowNavigationBackEvent,FlowNavigationNextEvent} from "lightning/flowSupport";
import { NavigationMixin } from 'lightning/navigation';

export default class Sbr_3_0_sfsDesktopLaborCmp extends  NavigationMixin(LightningElement) {
   
    @api recordToBeDeleted;
    @api screen;
    showButtons;
    @api defaultLaborRows;
    @api defaultLaborCode;
    @api defaultTravelRows;
    @api title="Internal Labor";
    @api titleTravel='Mileage'
    @api baseUrlFromFlow;
    @api skiptoSummaryPageLabor=false;
    columns;
    @track rows = [{ uuid: this.createUUID() }];
    @api workOrderId;
    @api type='List';
    @api workOrderDesc;
    @api woType='Inspection';
    @api nextScreeenMsg=' Next screen is Add Misc Items.'
    valueTravelCode= '9010';
    valueLaborHours;
    valueTravelHours;
    recsTobeAddedTravel=[];
    recsTobeAddedLabor=[];
    mechanicSfId;
    // Error Variables
    @track laborCodeValues
    errorMessageMechanicName=false;
    errorMessageLineType=false;
    isAccessError=false;
    isSpinner=false;
    @track laborRows;
    @track travelRows;
    @api labors
    @api travels
    @api bothTravelLabor
    picklistValues = [];
    isErrorLaborMechanic=false;
    isErrorLaborDuration=false;
    isErrorLaborLbrc=false;
    isErrorTravelMechanic=false;
    isErrorTravelDuration=false;
    isErrorTravelLbrc=false;
    newLaborRecord={"SF_PS_Mechanic_Name__c":'',
            "SF_PS_Mechanic_Id__c":'',
            "Duration":'',
            "SF_PS_Hourly_Internal_Rate__c":0,
            "SF_PS_Labor_Code__c":'',
            'sobjectType' : 'WorkOrderLineItem',
            "SF_PS_Line_Type__c":'',
            "SVMXA360__LineType__c":"Labor"
            

            }
    newTravelRecord={"SF_PS_Mechanic_Name__c":'',
            "SF_PS_Mechanic_Id__c":'',
            "Duration":'',
            "SF_PS_Hourly_Internal_Rate__c":1,
            "SF_PS_Labor_Code__c":'9010',
            'sobjectType' : 'WorkOrderLineItem',
            "SF_PS_Line_Type__c":'MC',
            "SVMXA360__LineType__c":"Travel"
           
        }


    @api columnListLabor=[{ "label" : "Technician", "apiName" : "SF_PS_Mechanic_Name__c" }, 
        { "label" : "Technician Id", "apiName" : "SF_PS_Mechanic_Id__c" },
        { "label" : "Hours", "apiName" : "Duration" },
        { "label" : "Hourly Rate", "apiName" : "SF_PS_Hourly_Internal_Rate__c" },
        { "label" : "Labor Code", "apiName" : "SF_PS_Labor_Code__c" },
        { "label" : "Ext Amount", "apiName" : "extended" },
    ];
    @api columnListTravel=[{ "label" : "Technician", "apiName" : "SF_PS_Mechanic_Name__c" }, 
        { "label" : "Technician Id", "apiName" : "SF_PS_Mechanic_Id__c" },
        { "label" : "Mileage", "apiName" : "Duration" },
        { "label" : "Price/mile", "apiName" : "SF_PS_Hourly_Internal_Rate__c" },
        { "label" : "Labor Code", "apiName" : "SF_PS_Labor_Code__c" },
        { "label" : "Ext Amount", "apiName" : "extended" },

    ];
    // Calculate getter total labor
    get calculateLaborTotal(){
        let total=this.laborRows.reduce((prev,next)=>{
        if(next.extended)
        {
          
            return Number(next.extended)+Number(prev);
        }
        else{
           
            return Number(prev);
        }
    },0)
  
    this.dispatchEvent(new CustomEvent("labortotal",{detail:Number(total).toFixed(2)}));
        return Number(total).toFixed(2);
    }
    // Calculate getter Travel labor
    get calculateTravelTotal(){
        let total=this.travelRows.reduce((prev,next)=>{
        if(next.extended)
        {
           
            return Number(next.extended)+Number(prev);
        }
        else{
           
            return Number(prev);
        }


        },0)

        this.dispatchEvent(new CustomEvent("traveltotal",{detail:Number(total).toFixed(2)}));
      
        return Number(total).toFixed(2);
    }

    // To get WOLI Object metadata 
    @wire(getObjectInfo, { objectApiName: WOLI_OBJECT })
    woliInfo;
    // To get picklistvalues for Labor code
    @wire(getPicklistValues,
    {
        recordTypeId: '$woliInfo.data.defaultRecordTypeId',
        fieldApiName:  LABOR_CODE_FIELD
    }
    )laborCode(result){
    if(result.data){
        this.laborCodeValues=result.data.values
        console.log('this is labor'+JSON.stringify(result.data.values));
    }
    }
    // Connected call back
    connectedCallback(){
      if(this.woType=='Quote' &&(this.workOrderDesc=='CHECK IN RETURN'||this.workOrderDesc=='REMARKETING INSPECTION'||this.workOrderDesc=='NEW RENTAL EQUIP COMMISSIONING')){ 
            this.nextScreeenMsg='Next screen is Add Outside Labor.'; 
        }
      if(this.woType=='Inspection' &&(this.workOrderDesc=='CHECK IN RETURN'||this.workOrderDesc=='REMARKETING INSPECTION'||this.workOrderDesc=='NEW RENTAL EQUIP COMMISSIONING')){ 
            this.nextScreeenMsg='Next screen is Summary.';
        }
        console.log('this.nextScreeenMsg '+this.nextScreeenMsg +' wotye'+this.woType+' desc ' +this.workOrderDesc)
        //console.log('default: '+JSON.stringify(this.defaultTravelRows));
       // console.log('default: '+JSON.stringify(this.defaultLaborRows));
        if(this.defaultLaborCode)
        {
            this.newLaborRecord.SF_PS_Labor_Code__c=this.defaultLaborCode;
        }
        if(this.defaultLaborRows){
          this.laborRows=JSON.parse(JSON.stringify(this.defaultLaborRows));
         // console.log('default: '+JSON.stringify(this.laborRows));
        }
        else{
          this.initData();
        }

        if(this.defaultTravelRows)
        {
          this.travelRows=JSON.parse(JSON.stringify(this.defaultTravelRows));
          //console.log('default: '+JSON.stringify( this.travelRows));
        }
        else{
          this.initData();
        }
        
   
    //console.log('thisi slen '+this.laborRows.length)
    //console.log('thisi travel '+this.travelRows.length)
        if(this.screen=="Review"){
            this.showButtons=false;
        }else{
            this.showButtons=true;
        }

    }
    // To init the data
    initData(){
        if(!this.laborRows)
        {
             this.laborRows=[];
             this.createRow('labor')
        }
        if(!this.travelRows)
        {
            this.travelRows=[];
            this.createRow('travel');
        }
        
   
   // this.createLaborRow();
   
   

    }
   
    //create labor/travel rows
    addRow(event)
    {
        let name=event.target.name;
        this.createRow(name);
    }

    // Create new row 
    createRow(name) {
       
        let rows=[];
        let newRecord={};
        if(name=="labor"){
            //console.log([...this.laborRows]);
            rows=this.laborRows;
            //console.log('labpr: '+JSON.stringify(this.laborRows))
            newRecord=this.newLaborRecord;

        }
        else{
            rows=this.travelRows;
            newRecord=this.newTravelRecord;
        }
      
        let isNotValid=false;
        if(rows.length>0)
        {
        
           isNotValid= this.handleValidations(name);
        }
       
        
        if(!isNotValid){
        
            let obj={...newRecord};
            obj.uuid= this.createUUID();
            if(rows.length>0){
                obj.index=rows[rows.length-1].index+1;
            }
            else{
                obj.index=1;
            }
            rows.push(obj);
        }
}
    // TO remove row
    removeRow(event) {
        let name=event.target.name;
        let rows=[];
        if(name=="labor"){
            rows=this.laborRows;
        }
        else{
            rows=this.travelRows;
        }
        if(rows.length>1){
        rows.splice(event.target.value, 1);
        this.handleSkipButton();
        }
    }

    // TO create UUID
    createUUID() {
        var dt = new Date().getTime();
        var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = (dt + Math.random()*16)%16 | 0;
            dt = Math.floor(dt/16);
            return (c === 'x' ? r :(r&0x3|0x8)).toString(16);
        });
        return uuid;
        }

    // Handle when user chnages Mechanic name i.e Service resource
    handleMechanicNameChangeLabor(event){
        console.log(event.target.name);
        let Id= event.target.dataset.id;
        let name=event.target.name;
        let rows;
        console.log(Id);
        if(name=='laborResource'){
            rows = this.laborRows
        }
        else{
            rows = this.travelRows;
            
        }


        let selectedRecord = rows.find(data => data.uuid === Id);
        selectedRecord.mehanicError=false;

        if(event.detail.selectedRecord.Id!=undefined){
            this.mechanicSfId=event.detail.selectedRecord.Id;
            getServiceResource({serviceResId:event.detail.selectedRecord.Id})
            .then(result=>{
                console.log('Handle: '+JSON.stringify(result));
                selectedRecord.SF_PS_Mechanic_Id__c=result[0].SF_PS_Mechanic_Id__c;
                selectedRecord.SF_PS_Labor_Type__c=result[0].SF_PS_Labor_Type__c;
                selectedRecord.SF_PS_Mechanic_Name__c=event.detail.selectedRecord.Id;
                if(name=='laborResource')
                {
                selectedRecord.SF_PS_Hourly_Internal_Rate__c=result[0].SF_PS_Hourly_Internal_Rate__c;

                if(result[0].SF_PS_Labor_Type__c=="I"){
                   // selectedRecord.lineTypeLabel="Inside Labor"
                    selectedRecord.SF_PS_Line_Type__c="LI"
                }else if(result[0].SF_PS_Labor_Type__c=="O"){
                   // selectedRecord.lineTypeLabel="Outside Labor"
                    selectedRecord.SF_PS_Line_Type__c="LO"
                // Deafult case   
                }else{
                    //selectedRecord.lineTypeLabel="Inside Labor"
                    selectedRecord.lineTypeValue="LI"
                }
                
            }
            this.handleSkipButton(name);
            this.checkExtended(selectedRecord);
            });
        }else{
            selectedRecord.SF_PS_Mechanic_Name__c="";
            selectedRecord.SF_PS_Mechanic_Id__c="";
            if(name=='laborResource')
            {
                selectedRecord.SF_PS_Hourly_Internal_Rate__c=0;
            }
            else{
                selectedRecord.SF_PS_Hourly_Internal_Rate__c=1;
            }
            
            selectedRecord.SF_PS_Labor_Type__c=""
            selectedRecord.SF_PS_Mechanic_Name__c=""
            
            selectedRecord.lineTypeLabel="";
            selectedRecord.lineTypeValue="";
          //  selectedRecord.Duration=undefined;

            selectedRecord.extended="";
            selectedRecord.Duration="";
            this.handleSkipButton(name);
        }
    }
    // Handle Change for Labor/Travel Code
    handleChangeLaborCode(event) {
        let name=event.target.name;
        let Id= event.target.dataset.id;
        let selectedRecord;
        if(name=='LaborCodeLabor') {
                selectedRecord = this.laborRows.find(data => data.uuid === Id);
        }
        if(name=='LaborCodeTravel'){
            selectedRecord = this.travelRows.find(data => data.uuid === Id);
            
        }
            selectedRecord.SF_PS_Labor_Code__c=event.target.value;
            selectedRecord.lbrcError=false;
    }
    // Handle Change for Labor Hours
    handleLaborHoursChange(event){
        let hour_mile = event.detail.value;

        let name=event.target.name;
        let Id= event.target.dataset.id;
        let selectedRecord;
        if(name=='laborDuration')
        {
                selectedRecord = this.laborRows.find(data => data.uuid === Id);

        }
        if(name=='travelDuration')
        {
            selectedRecord = this.travelRows.find(data => data.uuid === Id);
            
        }
            selectedRecord.Duration=event.target.value;
            selectedRecord.DurationError=false;
            
            this.checkExtended(selectedRecord);
          
    }
    handleHourlyRateChange(event){
        
        let hourRate = event.detail.value;
        let name=event.target.name;
     
        let Id= event.target.dataset.id;
        let selectedRecord;
        if(name=='laborHourlyRate')
        {
                selectedRecord = this.laborRows.find(data => data.uuid === Id);

        }
        if(name=='travelHourlyRate')
        {
            selectedRecord = this.travelRows.find(data => data.uuid === Id);
            
        }
        // selectedRecord = this.travelRows.find(data => data.uuid === Id);
       
            selectedRecord.SF_PS_Hourly_Internal_Rate__c=hourRate;
            selectedRecord.hourlyError=false;
            this.checkExtended(selectedRecord);
         
        
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
    // Check Extended field
    checkExtended(selectedRecord){
        selectedRecord.extended=selectedRecord.Duration*selectedRecord.SF_PS_Hourly_Internal_Rate__c 
    }

    // Handle prevous click
    handlePrevious(){
        console.log("Previous-Parts screen");
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    // Handle next click
    hanldeNext(){
        // Sending data to flow
        this.productConsumedRecord=this.rows;
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);

    }

    // Handle Cancel Click : Navigation to Account List view(recent)
    handleCancel(event){

        let objectName='WorkOrder';
        window.location.href=`${window.location.origin}/lightning/o/${objectName}/list`;
       
    }
    
    handleValidations(type)
    {
        debugger
        let isAllValidationsError=false;
        let rows=[];
        if(type=='labor')
        {
            rows=this.laborRows;

        }
        else{
            rows=this.travelRows;

        }
        rows.forEach((row,index,arr) => {
            row.mehanicError=row.SF_PS_Mechanic_Name__c?false:true;
            row.DurationError=row.Duration && Number(row.Duration)>0?false:true;
            row.hourlyError= Number(row.SF_PS_Hourly_Internal_Rate__c) && Number(row.SF_PS_Hourly_Internal_Rate__c)>0?false:true;
           
            //row.lbrcError=row.SF_PS_Labor_Code__c?false:true;
            if( row.mehanicError||row.DurationError|| row.hourlyError/*||row.lbrcError*/)
            {
                isAllValidationsError=true;
                this.skiptoSummaryPageLabor=false;
            }

            //START - SERV-14263 Change | 2 Apr
            row.Duration = Number( row.Duration );
            if (type == 'travel' && !Number.isInteger(row.Duration)) {
                isAllValidationsError=true;
                this.skiptoSummaryPageLabor=false;
            }
            //END - SERV-14263 Change 
            
            
        });
        return isAllValidationsError;

    }
   @api hanldeNext()
    {
        let returnVal={}
        console.log(" L ROWS:"+JSON.stringify(this.laborRows));
        console.log(" R ROWS:"+JSON.stringify(this.travelRows));

        let laborIsNotValid=true;
        let travelIsNotValid=true;
        let travelNull=false;
        let laborNull=false;
        if(this.travelRows.length==1 && !this.travelRows[0].SF_PS_Mechanic_Name__c && !Number(this.travelRows[0].Duration)  &&  (this.travelRows[0].SF_PS_Hourly_Internal_Rate__c==1 ||! Number(this.travelRows[0].SF_PS_Hourly_Internal_Rate__c ) ))
        {
           // this.travelRows=[];
           travelNull=true;
            travelIsNotValid=false;
            

        }
        else
        {
            travelIsNotValid= this.handleValidations('travel');
        }
        if(this.screen=='Review')
        {
            if(this.laborRows.length==1 && !this.laborRows[0].SF_PS_Mechanic_Name__c && !this.laborRows[0].Duration  &&  !this.laborRows[0].SF_PS_Hourly_Internal_Rate__c   && travelNull){
                // this.travelRows=[];
                laborNull=true;
                    laborIsNotValid=false;
                    

            }
            else{
                    laborIsNotValid= this.handleValidations('labor');
            }

        }
        else{
            laborIsNotValid= this.handleValidations('labor');
        }



        console.log('Labor not valid '+laborIsNotValid +'Travel Not Valid '+ travelIsNotValid);
         
        
        if(!laborIsNotValid && !travelIsNotValid )
        {
            this.labors=this.laborRows;
            this.travels=this.travelRows;
          
            this.bothTravelLabor=[...this.laborRows,...this.travelRows];
    

            
            returnVal.isReview=true;
            returnVal.records=this.bothTravelLabor;
            
            
            if(this.screen=='Review')
            {
                let combined;
                if(laborNull && travelNull)
                {
                    returnVal.records=[];
                    returnVal.labors=[];
                    returnVal.travels=[];
                }
                else if(travelNull)
                {
                    returnVal.records=[...this.laborRows];
                    returnVal.labors=this.laborRows;
                }
                else
                {
                    combined=[...this.laborRows,...this.travelRows];
                    returnVal.records=combined;
                    returnVal.labors=this.laborRows;
                    returnVal.travels=this.travelRows;
                    
                }
                return JSON.stringify(returnVal);
            }
            else{
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
         
        }
        else if(this.screen=='Review')
        {
            return '[]';
        }
    }
   
    // Handle prevous click
    handlePrevious(){
        //console.log("Previous-Parts screen");
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);

      }

     // Handle go to Summary
      handleSummary(){
        //console.log("IT WORKSO ON LABOR");
        this.skiptoSummaryPageLabor=true;
        if(this.laborRows[0].SF_PS_Mechanic_Name__c!="" || this.travelRows[0].SF_PS_Mechanic_Name__c !="" || this.laborRows.length > 1)
      {
        this.hanldeNext();
        console.log('inside NEXT DT');
     
      }
      else
      {
        
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
       }
      }

      // Handle Skip Button show and hide
      handleSkipButton(name)
      {
        console.log('screen name'+this.screen);
    if(this.screen!="Review"){
      var comp = this.template.querySelector('c-sbr_3_0_sfs-desktop-flow-buttons');
       
          for(let i=0 ;i<=this.laborRows.length-1;i++)
          {
            console.log('labor item id'+JSON.stringify(this.laborRows[i]));
            if(this.laborRows[i].SF_PS_Mechanic_Name__c || this.travelRows[0].SF_PS_Mechanic_Name__c)
            {
              comp.showSkipButton=false;
             // console.log('inside if skip');
              break;
            }
            else
            {
             // console.log('inside else skip');
              comp.showSkipButton=true;
            }
          }
      }
    }
}