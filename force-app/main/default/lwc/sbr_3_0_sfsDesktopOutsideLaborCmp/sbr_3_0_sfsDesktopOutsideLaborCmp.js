import { LightningElement,api,track,wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WOLI_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import  getServiceResource from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourceById';
import {FlowNavigationBackEvent,FlowNavigationNextEvent} from "lightning/flowSupport";
import { NavigationMixin } from 'lightning/navigation';

export default class Sbr_3_0_sfsDesktopOutsideLaborCmp extends  NavigationMixin(LightningElement) {

        @api billCustLocL;
        loadSpinner = false;
        @api expenseToLoc;
        @api recordToBeDeleted;
        @api screen;
        showButtons;
        @api defaultLaborRows;
        @api defaultLaborCode;
        @api title="Outside Labor";
        @api titleTravel='Mileage'
        @api baseUrlFromFlow;
        @api skiptoSummaryPageLabor=false;
        columns;
        @track rows = [{ uuid: this.createUUID() }];
        @api workOrderId;
        @api type='List';
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
        newLaborRecord={"SF_PS_Vendor_PO_Num__c":'',
                "SF_PS_Outside_Labor_Des__c":'',
                "SF_PS_PO_Cost__c":'',
                "SF_PS_PO_Amount__c":'',
                "SF_PS_Labor_Code__c":'',
                'sobjectType' : 'WorkOrderLineItem',
                "SF_PS_Line_Type__c":'LO',
                "SVMXA360__LineType__c":"Labor"
                }
        @api columnListLabor=[{ "label" : "PO#", "apiName" : "SF_PS_Vendor_PO_Num__c" },
            { "label" : "Outside Labor Description", "apiName" : "SF_PS_Outside_Labor_Des__c" },
            { "label" : "PO Cost", "apiName" : "SF_PS_PO_Cost__c" },
            { "label" : "PO Amount", "apiName" : "SF_PS_PO_Amount__c" }
        ];
        @api disableAddButton = false;
        // Calculate getter total labor
        get calculateLaborTotal(){
            let total=this.laborRows.reduce((prev,next)=>{
                if(next.SF_PS_PO_Cost__c)
                {
                    return Number(next.SF_PS_PO_Amount__c)+Number(prev);
                }
                else{
                    return Number(prev);
                }
            },0)
            this.dispatchEvent(new CustomEvent("labortotal",{detail:Number(total).toFixed(2)}));
            return Number(total).toFixed(2);
        }
        // To get WOLI Object metadata 
        @wire(getObjectInfo, { objectApiName: WOLI_OBJECT })
        woliInfo;

        // Connected call back
        connectedCallback(){
           

            if(this.defaultLaborCode)
            {
                this.newLaborRecord.SF_PS_Labor_Code__c=this.defaultLaborCode;
            }
            if(this.defaultLaborRows){
                this.laborRows=JSON.parse(JSON.stringify(this.defaultLaborRows));
            }
            else{
                this.initData();
            }
            if(this.screen=="Review"){
                this.showButtons=false;
            }else{
                this.showButtons=true;
            }

            if(this.expenseToLoc == 'L')
            {
                this.billCustLocL = true;
            }
            else
            {
                this.billCustLocL = false;
            }
            console.log('this.billCustLocL::'+this.billCustLocL);
            console.log('this.expenseToLoc::'+this.expenseToLoc);
             // FT- regression:Check for more than two records.
            // Chnaged to lenght should  equal to two.
            if(this.laborRows?.length == 2){
                this.disableAddButton=true;
            }else{
                this.disableAddButton=false;
            }
        }

        // To init the data
        initData(){
            this.laborRows=[];
            this.createRow('labor');
        }

        //create labor/travel rows
        addRow(event)
        {
            let name=event.target.name;
            this.createRow(name);
            console.log('size of labor rows'+this.laborRows.length);
            // FT- regression:Check for more than two records
            // Chnaged to lenght should equal to two
            if(this.laborRows.length == 2){
                this.disableAddButton=true;
            }else{
                this.disableAddButton=false;
            }
        }

        // Create new row
        createRow(name){
            let rows=[];
            let newRecord={};
            console.log([...this.laborRows]);
            rows=this.laborRows;
            console.log('labpr: '+JSON.stringify(this.laborRows))
            newRecord=this.newLaborRecord;
            let isNotValid=false;
            if(rows.length>0)
            {
                isNotValid= this.handleValidations(name);
            }
            if(!isNotValid)
            {
                let obj={...newRecord};
                obj.uuid= this.createUUID();
                if(rows.length>0)
                {
                    obj.index=rows[rows.length-1].index+1;
                }
                else
                {
                    obj.index=1;
                }
                rows.push(obj);
            }
        }

        // TO remove row
        removeRow(event) {
            let name=event.target.name;
            let rows=[];
            this.disableAddButton=false;
            if(name=="labor")
            {
                rows=this.laborRows;
            }
            if(rows.length>1)
            {
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

        // Handle Change for vender PO Number
        handleVenderPONumberChange(event){
            let poNumber = event.detail.value;
            let Id= event.target.dataset.id;
            let selectedRecord;
            selectedRecord = this.laborRows.find(data => data.uuid === Id);
            selectedRecord.SF_PS_Vendor_PO_Num__c=poNumber;
            selectedRecord.poNumber=false;
            this.checkExtended(selectedRecord);
            this.handleSkipButton();
        }

        // Handle Change for vender PO Amount
        handlePOAmountChange(event){
            this.loadSpinner = true;
            let poAmount = event.detail.value;
            let Id= event.target.dataset.id;
            let selectedRecord;
            selectedRecord = this.laborRows.find(data => data.uuid === Id);
            selectedRecord.SF_PS_PO_Amount__c=poAmount;
            selectedRecord.poAmount=false;
            if(this.expenseToLoc!='L'){
                selectedRecord.SF_PS_PO_Cost__c=poAmount;
            }
            this.checkExtended(selectedRecord);
            this.loadSpinner = false;
        }

        // Handle Change for vender PO Cost
        handlePOCostChange(event){
            this.loadSpinner = true;
            let poCost = event.detail.value;
            let Id= event.target.dataset.id;
            let selectedRecord;
            selectedRecord = this.laborRows.find(data => data.uuid === Id);
            selectedRecord.SF_PS_PO_Cost__c=poCost;
            selectedRecord.poCost=false;
            if(this.expenseToLoc=='L'){
                selectedRecord.SF_PS_PO_Amount__c=poCost;
            }
            this.checkExtended(selectedRecord);
            this.loadSpinner = false;
        }

        // Handle Change for OutSide Labor Desc
        handlePODescChange(event){
            let poDesc = event.detail.value;
            let Id= event.target.dataset.id;
            let selectedRecord;
            selectedRecord = this.laborRows.find(data => data.uuid === Id);
            selectedRecord.SF_PS_Outside_Labor_Des__c=poDesc;
            selectedRecord.poDesc=false;
            this.checkExtended(selectedRecord);
        }

        // Check Extended field
        checkExtended(selectedRecord){
            //selectedRecord.extended=selectedRecord.Duration*selectedRecord.SF_PS_Hourly_Internal_Rate__c 
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
        handleCancel(event)
        {
            let objectName='WorkOrder';
            window.location.href=`${window.location.origin}/lightning/o/${objectName}/list`;
        }

        handleValidations(type)
        {
            let isAllValidationsError=false;
            let rows=[];
            rows=this.laborRows;
            rows.forEach((row,index,arr) => {
                row.poAmount= Number(row.SF_PS_PO_Amount__c) && Number(row.SF_PS_PO_Amount__c)>0?false:true;
                row.poCost= Number(row.SF_PS_PO_Cost__c) && Number(row.SF_PS_PO_Cost__c)>0?false:true;
                row.poNumber=row.SF_PS_Vendor_PO_Num__c?false:true;
                row.poDesc=row.SF_PS_Outside_Labor_Des__c?false:true;

                if( row.poAmount || row.poCost || row.poNumber || row.poDesc)
                {
                    isAllValidationsError=true;
                    this.skiptoSummaryPageLabor=false;
                }
            });
            return isAllValidationsError;
        }

        @api
        hanldeNext()
        {
            let laborIsNotValid=true;
            let laborNull=false;
            let returnVal={};
            if(this.screen=='Review')
            {
                if(this.laborRows.length==1 && !this.laborRows[0].SF_PS_Vendor_PO_Num__c && !this.laborRows[0].SF_PS_PO_Amount__c  &&  !this.laborRows[0].SF_PS_PO_Cost__c  )
                {
                    laborNull=true;
                    laborIsNotValid=false;
                }
                else
                {
                    laborIsNotValid= this.handleValidations('labor');
                }
            }
            else
            {
                laborIsNotValid= this.handleValidations('labor');
            }
            console.log('laborIsNotValid::'+laborIsNotValid);
            if(!laborIsNotValid )
            {
               
                this.labors=this.laborRows;
                if(this.screen=='Review')
                {
                    if(laborNull)
                    {
                        returnVal.records=[]
                    }
                    else{
                        returnVal.records=this.laborRows;
                    }
                    
                    returnVal.isReview=true;
                    
                    return JSON.stringify(returnVal);
                }
                else
                {
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                }
            }
            else if(this.screen=='Review')
            {
                let returnVal={};
                returnVal.isReview=false;
                returnVal.records=[];
                return JSON.stringify(returnVal);

            }
        }

        // Handle prevous click
        handlePrevious(){
            console.log("Previous-Parts screen");
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }

        // Handle go to Summary
        handleSummary(){
            console.log("IT WORKSO ON LABOR");
            this.skiptoSummaryPageLabor=true;
            if(this.laborRows[0].SF_PS_Vendor_PO_Num__c!="" || this.laborRows.length > 1)
            {
                this.hanldeNext();
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
            if(this.screen!="Review"){
                var comp = this.template.querySelector('c-sbr_3_0_sfs-desktop-flow-buttons');
                for(let i=0;i<=this.laborRows.length-1;i++)
                {
                    if(this.laborRows[i].SF_PS_Vendor_PO_Num__c )
                    {
                        comp.showSkipButton=false;
                        break;
                    }
                    else
                    {
                        comp.showSkipButton=true;
                    }
                }
            }
        }
    }