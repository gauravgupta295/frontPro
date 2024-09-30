import { LightningElement,wire,api, track } from 'lwc';
import { getRecord ,getFieldValue} from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import MAKE_FIELD from '@salesforce/schema/Asset.SM_PS_Make__c';
import MODEL_FIELD from '@salesforce/schema/Asset.SM_PS_Model__c';
import SERIAL_NUMBER_FIELD from '@salesforce/schema/Asset.SM_PS_Serial_Number__c';
import WARRANTY_EXP_DATE from '@salesforce/schema/Asset.SM_PS_Warranty_Exp_Date__c';
import CAT_CLASS_DESC from '@salesforce/schema/Asset.SM_PS_Cat_Class_Description__c';
import STATUS from '@salesforce/schema/Asset.Status';
import WO_OBJECT from '@salesforce/schema/WorkOrder';
import WO_PRICEBOOK_ID from '@salesforce/schema/WorkOrder.Pricebook2Id';
import WO_SERVICE_TERRITORY_FIELD from '@salesforce/schema/WorkOrder.ServiceTerritoryId';
import WO_ASSET_FIELD from '@salesforce/schema/WorkOrder.AssetId'
import WO_PUT_IN_SHOP_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Put_Into_Shop__c';
import WO_PRIORITY_FIELD from '@salesforce/schema/WorkOrder.Priority';
import WORK_ORDER_DESC_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Work_Order_Des__c';
import WO_SELF_SCHEDULED_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Is_Self_Schedule__c';
import WO_SERVICE_CALL from '@salesforce/schema/WorkOrder.SF_PS_Service_Call__c';
import WO_RECORDTYPE_ID_FIELD from '@salesforce/schema/WorkOrder.RecordTypeId';
import { createRecord } from 'lightning/uiRecordApi';
import RoleName from '@salesforce/schema/User.UserRole.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getdefaultSTforLoggedInUser from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourcePrimaryTerittory';
import getEquipmentAlerts from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getEquipmentAlerts';
import USER_Id from '@salesforce/user/Id';
import getOpenWOForAsset from '@salesforce/apex/SBR_3_0_SfsGenerateInspectionController.getOpenWOToAsset';
import getStandardPriceBookId from '@salesforce/apex/SBR_3_0_SfsGenerateInspectionController.getStdPriceBook';
import lightninglwcWarningModal from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import taxCreditError from "@salesforce/label/c.Tax_Credit_WO_Description_Error";
import plantReadyError from "@salesforce/label/c.Plant_Ready_Eqp_Commisioning_WO_Des_Error";
import equipmentDecommissioningError from "@salesforce/label/c.Equipment_Decommissioning_WO_Desc_Error";
import wOByTechSchedulerToolError from "@salesforce/label/c.WO_By_Tech_Scheduler_Tool";
import preventativeMaintenanceError from "@salesforce/label/c.Preventative_Maintenance_Error";

const month = ["January","February","March","April",
                "May","June","July","August","September",
                "October","November","December"];
import getAssetDetaisApex from '@salesforce/apex/SBR_3_0_SfsGenerateInspectionController.getAssetById'
export default class Sbr_3_0_sfs_GenerateInspectionCmp extends NavigationMixin(LightningElement) {
    @track asset;
    @track equipmentAlerts=[];
    @track openWorkOrderForAsset=[];
    
    assetSfId;
    createdWorkOrderSfId;
    createdServiceAppointId;
    assetSfName;
    serviceTerritorySfId;
    woDescoptions;
    woDescValue;
    isRequiredStyle=true;
    isErrorAsset=false;
    isErrorServiceTerittory=false;
    isAssetAlert=false;
    make;
    model;
    status;
    assetErrorMsg;
    assetErrors=false;
    assetWarning=false;
    serialNumber;
    companyCode;
    warrantyExpiryDate;
    companyCode;
    callClassDesc;
    currentMiHr;
    isAssetWarrantyExpiryDate=false;
    isOpenWorkOrderForAsset=false;
    defaultServiceTerritoryId;
    inspectionRecordTypeId;
    assetCCode;
    woInfo;
    stdPricebookId;
    annualInspecAsset=false;
    annualInspecfilter = ' AND ((SM_PS_Category__c = \'058\') OR (SM_PS_Category__c = \'066\' AND SM_PS_Class__c = \'1050\') OR (SM_PS_Category__c = \'066\'  AND SM_PS_Class__c = \'1070\') OR (SM_PS_Category__c = \'066\'  AND SM_PS_Class__c = \'1085\') OR (SM_PS_Category__c = \'066\'  AND SM_PS_Class__c = \'1075\') OR (SM_PS_Category__c = \'066\'  AND SM_PS_Class__c = \'1080\') OR (SM_PS_Category__c = \'007\') ) ';
    displayAssetmsg = true;
    putInShopMakeAvailableValue = 'N';
    priorityOptions;
    priorityValue='Low';
    //put in shop field hide and display variable
    showPutInShop=false;
        // To validate work order desc
        isWorkOrderValid=true;
    showPriority=false;
    PriorityDisabled=false;
    userRoleName;

    displayErrorForTechSchedulerTool = false;
    msgForTechSchedulerTool = '';

    labels = {
        taxCreditError,
        plantReadyError,
        equipmentDecommissioningError,
        wOByTechSchedulerToolError,
        preventativeMaintenanceError
    }

    get options() {
        return [
            { label:'Yes', value:'Y' },
            { label:'No', value:'N' }   
        ];
    }


        // Getting WorkOrder Priority Picklist Values
        @wire(getPicklistValues,{
            recordTypeId: '$woInfo.data.defaultRecordTypeId',
            fieldApiName:  'WorkOrder.Priority'
        })WorkOrderPriorityValues({error,data}){
            //console.log(data);
            if(data){
                this.priorityOptions=data.values;
            }
            else{
                console.log(JSON.stringify(error));
            }
        }

        @wire(getRecord, { recordId: USER_Id, fields: [RoleName] })
        userDetails({ error, data }) {
            if (error) {
                console.log(JSON.stringify(error));
            } else if (data) {
                if (data.fields.UserRole.value != null) {
                    this.userRoleName = data.fields.UserRole.value.fields.Name.value;
                }
               if(this.userRoleName!=undefined && this.userRoleName.includes('Technician')){
                this.PriorityDisabled=true;
               }
               console.log(JSON.stringify('Final Priority'+this.PriorityDisabled));
            }
        }
    // To avoid Datasync/caching issue: Moved logic to imperative call from apex when change in asset /asset select 
    /*@wire(getRecord, { recordId: '$assetSfId', 
    fields: [MAKE_FIELD, MODEL_FIELD,
        SERIAL_NUMBER_FIELD,
        WARRANTY_EXP_DATE,CAT_CLASS_DESC,
        STATUS] })assetData(result){
            this.asset=result
            if(result.data){
                console.log("Asset Data;"+JSON.stringify(result))
                this.make=result.data.fields.SM_PS_Make__c.value;
                //this.model=result.data.fields.SM_PS_Serial_Number__c.value;
                // Retro
                this.model=result.data.fields.SM_PS_Model__c.value;
                this.serialNumber=result.data.fields.SM_PS_Serial_Number__c.value;
                // Asset status
                this.status=result.data.fields.Status.value;
                var warrDate=result.data.fields.SM_PS_Warranty_Exp_Date__c.value;
                // For UI.UX Feedback
                var formatDate=new Date(warrDate);
                // Retro
                const currentDate = new Date();
                console.log("Curr Date: "+currentDate);
                var dateExp=String(warrDate).slice(-2);
                var monthExp=month[formatDate.getMonth()];
                var yearExp=formatDate.getFullYear();
                this.warrantyExpiryDate=dateExp+'-'+monthExp+'-'+yearExp;
                this.callClassDesc=result.data.fields.SM_PS_Cat_Class_Description__c.value;
                if(this.warrantyExpiryDate && formatDate >= currentDate){
                    this.isAssetWarrantyExpiryDate=true;
                }
                else{
                    this.isAssetWarrantyExpiryDate=false;
                }
                
            }

            if(result.error){
                console.log('this is error '+JSON.stringify(result.error));
            }
    }*/
    // To get WOLI Object metadata 
    @wire(getObjectInfo, { objectApiName: WO_OBJECT })
    WorkOrderData(result){
        this.woInfo=result;
        if(result.data){
            console.log(JSON.stringify(result.data));
            // console.log('this is generate inspection');
            // console.log(this.woInfo)
            // console.log(result.data.recordTypeInfos);
            const rtis =result.data.recordTypeInfos;
            const inspectionRecordType= Object.keys(rtis).find(rti => rtis[rti].name === 'Inspection Record');
            console.log('ins rec id'+inspectionRecordType);
            this.inspectionRecordTypeId=inspectionRecordType;
        }
        if(result.error){
            console.log(JSON.stringify(result.error));
        }
    }

    
    // Pickilist work order description 
    @wire(getPicklistValues,{
        recordTypeId: '$inspectionRecordTypeId',
        fieldApiName:  'WorkOrder.SF_PS_Work_Order_Des__c'
    })WorkOrderDescValues({error,data}){
        //console.log(data);
        if(data){
            this.woDescoptions=data.values;
            console.log('record id'+this.inspectionRecordTypeId);
        }
        else{
            console.log(JSON.stringify(error));
        }
    }

    connectedCallback(){
        // Get loggedIn user primary service teritory
        this.displayAssetmsg = true;
        this.reset();
        getdefaultSTforLoggedInUser({usrId:USER_Id}).then((result)=>{
            console.log("ST"+JSON.stringify(result));
            if(result){
                let defaultSTId=this.handlePrimaryAndRelocation(result);
                console.log("defaultSTId:"+defaultSTId);
                //this.defaultServiceTerritoryId=result;
                //this.defaultServiceTerritoryId='0Hh8G0000004J8GSAU';
                this.defaultServiceTerritoryId=String(defaultSTId);
                this.serviceTerritorySfId=String(defaultSTId);
                this.template.querySelector("c-sbr_3_0_sfs-generic-lookup").setDefaultRecordId(this.defaultServiceTerritoryId);
            }
            else{
                this.defaultServiceTerritoryId=undefined;
            }
        }).catch(error=>{
            console.log(JSON.stringify(error));
    
        });

        getStandardPriceBookId().then(result=>{
            console.log(JSON.stringify(result));
            this.stdPricebookId=result.Id;
        }).catch(error=>{
            console.log("Price book error: "+JSON.stringify(error));
    
        })
    }



    // To handle change in service terittory
    handleServiceTerritoryChange(event){
        console.log("SERVICE TERRITORY ID:"+event.detail.selectedRecord.Id);
        if(event.detail.selectedRecord.Id!=undefined){
            this.serviceTerritorySfId=event.detail.selectedRecord.Id;
        }
        else{
            this.serviceTerritorySfId=undefined;
        }
    }

    // To handel work order desc change
    handleWorkOrderDescChange(event){
        this.isWorkOrderValid=true;
        this.woDescValue=event.detail.value;
        // Before Condition: Geeting prrior value to check is Annual inspection or not
        if(this.annualInspecAsset==true){
            this.reset();
        }
        else if(this.annualInspecAsset==false && this.woDescValue=='ANNUAL INSPECTION'){
            this.reset();
        }
        this.handlePutInShopDefaultLogic(this.status,event.detail.value);
        if(this.woDescValue=='ANNUAL INSPECTION'){
            this.annualInspecAsset=true;
        }
        else{
            this.annualInspecAsset=false; 
        }

        if(this.woDescValue!='ANNUAL INSPECTION' && this.woDescValue!='BREAKDOWN SERVICE CALL' && this.woDescValue!='CHECK IN RETURN'){
            this.showPutInShop = true;
        }
        else {
            this.showPutInShop = false;
        }

        if(this.woDescValue=='DAMAGE - RPP CLAIM' || this.woDescValue=='DAMAGE - RPP TIRE CLAIM' || this.woDescValue=='CUSTOMER RESPONSIBLE INCIDENT' || this.woDescValue=='Used Equipment Warranty (SPF)' || this.woDescValue=='RECAP' ){
            this.displayErrorForTechSchedulerTool = true;
            this.msgForTechSchedulerTool = this.woDescValue +' '+ this.labels.wOByTechSchedulerToolError;
        } else if(this.woDescValue=='WORK ORDER CREDIT'){
            this.displayErrorForTechSchedulerTool = true;
            this.msgForTechSchedulerTool = this.woDescValue +' '+ 'Description is not allowed in Mobile.';
        }
        else {
            this.displayErrorForTechSchedulerTool = false;
            this.msgForTechSchedulerTool = '';
        }

        if(this.woDescValue!=null){
            this.showPriority = true;
            switch(this.woDescValue){
                case "CHECK IN RETURN":
                case "REMARKETING INSPECTION":
                case "VEHICLE REPAIRS":
                case "REPLACEMENT ENGINE":
                case "REPLACEMENT TIRES":
                case "RECAP":
                case "Used Equipment Warranty (SPF)":
                case "INSPECTION DEFECT ACTION REQD":
                case "BOOM CABLE REPLACEMENT":
                case "WORK ORDER CREDIT":
                    this.priorityValue="Low";
                    break;
                case "WARRANTY":
                case "NEW RENTAL EQUIP COMMISSIONING":
                case "CUSTOMER RESPONSIBLE INCIDENT":
                    this.priorityValue="Medium";
                    break;
                case "EQUIPMENT REPAIR":
                case "PREVENTATIVE MAINTENANCE":
                case "DAMAGE - RPP CLAIM":
                case "DAMAGE - RPP TIRE CLAIM":
                    this.priorityValue="High";
                    break;
                case "ANNUAL INSPECTION":
                case "BREAKDOWN SERVICE CALL":
                case "DAMAGE - CUSTOMER BILLED":
                    this.priorityValue="Critical";
                    break;
                default:
                    this.priorityValue='';
            }
        }
        else {
            this.showPriority = false;
        }
    }

    // To handle change in asset number
    handleAssetNumberChange(event){
        this.isErrorAsset=false;
        console.log("Asset ID:"+event.detail.selectedRecord.Id);
        this.assetErrors=false;
        if(event.detail.selectedRecord.Id!=undefined){
            this.assetSfId=event.detail.selectedRecord.Id;
            this.assetSfName=event.detail.selectedRecord.Name;
            console.log(this.assetSfId); 
            this.getEquipmentAlert();
            this.getOpenWorkOrderForAsset(this.assetSfId);
            this.getAssetDetails(event.detail.selectedRecord.Id);
        }
        else{
            this.reset();
        }
    }

    reset(){
        this.assetSfId=undefined;
        this.status="";
        this.assetSfName="";
        this.make="";
        this.model="";
        this.serialNumber="";
        this.isAssetWarrantyExpiryDate=false;
        this.warrantyExpiryDate="";
        this.callClassDesc="";
        this.currentMiHr="";
        this.equipmentAlerts=[];
        this.isAssetAlert=false;
        this.isOpenWorkOrderForAsset=false;
    }

    // Handle put in shop
    handlePutInShopChange(event){
        this.putInShopMakeAvailableValue = event.detail.value;
        console.log("PUT IN SHOP:"+this.putInShopMakeAvailableValue);
    }

    //Handle priority
    handlePriorityChange(event){
        this.priorityValue=event.detail.value;
        console.log("Priority: "+this.priorityValue);
    }

    //get Equipment Alerts from Due Service 
    getEquipmentAlert(){
        getEquipmentAlerts({assetId:this.assetSfId}).then(data=>{
            console.log('this is the data');
            console.log(data)
            this.equipmentAlerts=data;
            this.isAssetAlert=data.length?true:false;
        }).catch(err=>{
            this.isAssetAlert=false;
            console.log('this is error '+JSON.stringify(err));

        })
    }
    
    // get Open Work Order for Asset
    getOpenWorkOrderForAsset(assetId){
        getOpenWOForAsset({assetId:this.assetSfId}).then((result)=>{
            console.log('OPEN WO FOR ASSET: '+JSON.stringify(result));
            this.openWorkOrderForAsset=result;
            // If not WO associated to asset
            if(result.length==0){
                this.isOpenWorkOrderForAsset=false;
            }
            else{
                this.isOpenWorkOrderForAsset=true;
            }
        }).catch(error=>{
            console.log(JSON.stringify(error));
        });
    }



    // To generate self scheduled inspection
    async generateInspection(){
        console.log("Asset status: " + this.status);
        console.log("WOD Description: "+ this.woDescValue);
        this.handleAssetstatusErrors(this.woDescValue,this.status);
        // CR: Serv: 17886
        var serviceCallValue=this.handleServiceCallPopulation(this.woDescValue,this.status);


        // Validating service terittory as required
        if(this.serviceTerritorySfId==undefined){
            this.isErrorServiceTerittory=true;
        }
        else{
            this.isErrorServiceTerittory=false;
        }

        // Validating Work order desc
       /* const isWorkOrderValid=[...this.template.querySelectorAll('lightning-combobox')].reduce((validSoFar, inputField) => {
                                    inputField.reportValidity();
                                    return validSoFar && inputField.checkValidity();
                                }, true);*/
                                        // Validating woroder desc as required
        if(this.woDescValue==undefined){
            this.isWorkOrderValid=false;
        }
        else{
            this.isWorkOrderValid=true;
        }
        
        // Validating asset as required
        if(this.assetSfId==undefined){
            this.isErrorAsset=true;
        }
        else{
            this.isErrorAsset=false;
        }


        // Final Validation
        if(this.isErrorServiceTerittory==false && this.isWorkOrderValid==true && this.isErrorAsset==false && this.assetErrors==false && this.displayErrorForTechSchedulerTool==false){
            const fields = {};
            fields[WO_SERVICE_TERRITORY_FIELD.fieldApiName]=this.serviceTerritorySfId;
            fields[WORK_ORDER_DESC_FIELD.fieldApiName]=this.woDescValue;
            fields[WO_ASSET_FIELD.fieldApiName]=this.assetSfId;
            fields[WO_SELF_SCHEDULED_FIELD.fieldApiName]=true;
            fields[WO_RECORDTYPE_ID_FIELD.fieldApiName]=this.inspectionRecordTypeId;
            fields[WO_PUT_IN_SHOP_FIELD.fieldApiName]=this.putInShopMakeAvailableValue;
            fields[WO_PRIORITY_FIELD.fieldApiName]=this.priorityValue;
            //fields[WO_RECORDTYPE_ID_FIELD.fieldApiName]='0128D000000P0ISQA0';
            //fields[WO_PRICEBOOK_ID.fieldApiName]='01s5e0000096ktSAAQ';
            fields[WO_PRICEBOOK_ID.fieldApiName]=this.stdPricebookId;
            fields[WO_SERVICE_CALL.fieldApiName]=serviceCallValue;
            const recordInput = {apiName:WO_OBJECT.objectApiName,fields};
            console.log(recordInput);

            if(this.status=="IN PROGRESS"){
                await lightninglwcWarningModal.open({
                    size: 'small',
                    description: 'Accessible description of modal purpose',
                    content: 'There is already a Rent Ready / Annual Inspection is In Progress. Do you still wish to continue?',
                    headerText:'Warning',
                    onyesclick:(e)=>{
                        // Warning and create record 
                        this.handleInspectionrecordCreation(recordInput);
                    }
                });
            }
            else{
                this.handleInspectionrecordCreation(recordInput);
            }
        }
    }

    handleAssetstatusErrors(woDesc,assetStatus){
        console.log("In handle: "+woDesc);
        console.log("In handle: "+assetStatus);
        // Case:3 Annual for : I = In Transit, J = Junked, V = Returned to Vendor,T = Stolen ,M = Missing Lost
        if(woDesc =='ANNUAL INSPECTION' && (assetStatus=='IN TRANSIT' || assetStatus=='RETURNED TO VENDOR' || assetStatus=='STOLEN' || assetStatus=='MISSING LOST')){
            this.assetErrors=true;
            this.assetErrorMsg = 'Cannot Generate Inspection if the Equipment Status is in '+assetStatus;
            //Case: 3 EQUIPMENT REPAIR : J = Junked, V = Returned to Vendor,T = Stolen ,M = Missing Lost
        }
        else if((woDesc=='EQUIPMENT REPAIR' || woDesc =='BREAKDOWN SERVICE CALL' 
            || woDesc=='DAMAGE - CUSTOMER BILLED' || woDesc=='DAMAGE - RPP CLAIM' 
            || woDesc== 'DAMAGE - RPP TIRE CLAIM'|| woDesc=='CUSTOMER RESPONSIBLE INCIDENT' 
            || woDesc=='WARRANTY' || woDesc=='REPLACEMENT ENGINE' 
            || woDesc=='REPLACEMENT TIRES'|| woDesc=='BOOM CABLE REPLACEMENT' 
            || woDesc=='INSPECTION DEFECT ACTION REQD'|| woDesc=='CENTRAL SERVICES @ PC LABOR' 
            || woDesc=='Used Equipment Warranty (SPF)' || woDesc=='RECAP'
            || woDesc=='VEHICLE REPAIRS' || woDesc=='NEW RENTAL EQUIP COMMISSIONING') 
            && ( assetStatus=='RETURNED TO VENDOR' 
            || assetStatus=='STOLEN'|| assetStatus=='MISSING LOST' || assetStatus=='IN PROGRESS'))
        {
            // CR-SERV-17886
            if (woDesc == 'BREAKDOWN SERVICE CALL' && (assetStatus != 'ON RENT' 
            && assetStatus != 'ON RENTAL PURCHASE' && assetStatus != 'SCHEDULED FOR PICKUP')) {
                this.assetErrors=true;
                this.assetErrorMsg = 'Cannot create Breakdown Service Call WO as Equipment Status is not \'On Rent, On Rental Purchase or Schedule for Pickup\'';
            } 
            else {
                this.assetErrors=true;
                this.assetErrorMsg = 'Cannot Generate Inspection if the Equipment Status is in '+assetStatus;
            }

                //Case: 3: Rent Ready : I = In Transit, J = Junked, V = Returned to Vendor,T = Stolen ,M = Missing Lost
                // O= ON RENT, U=SCHEDULED FOR PICKUP, P=ON RENTAL PURCHASE ,N = Down < 20 Days ,
                //D = Down > 20 Days, S = Sold ,K = On Truck ,Q= SATELITE BRANCH
        }
        else if(woDesc=='CHECK IN RETURN' && (assetStatus=='IN TRANSIT' || assetStatus=='RETURNED TO VENDOR' 
            || assetStatus=='STOLEN' || assetStatus=='MISSING LOST'
            || assetStatus=='ON RENT' || assetStatus=='SCHEDULED FOR PICKUP' || assetStatus=='ON RENTAL PURCHASE' 
            || String(assetStatus).includes('DOWN') || assetStatus=='DOWN - MORE THAN 20 DAYS' || assetStatus=='ON TRUCK'
            || assetStatus=='SATELITE BRANCH' || assetStatus=='SOLD'))
        {
            this.assetErrors=true;
            this.assetErrorMsg = 'Cannot Generate Inspection if the Equipment Status is in '+assetStatus;
        } 
        // CR-SERV-17886
        else if (woDesc == 'BREAKDOWN SERVICE CALL' && (assetStatus != 'ON RENT' 
                && assetStatus != 'ON RENTAL PURCHASE' && assetStatus != 'SCHEDULED FOR PICKUP')) {
            this.assetErrors=true;
            this.assetErrorMsg = 'Cannot create Breakdown Service Call WO as Equipment Status is not \'On Rent, On Rental Purchase or Schedule for Pickup\'';
        }
        else if (woDesc=='TAX CREDIT' || woDesc=='EQUIPMENT DECOMMISSIONING' || woDesc=='PLANT READY EQP COMMISSIONING' || woDesc=='PREVENTATIVE MAINTENANCE') {
            this.assetErrors=true;
            if (woDesc=='TAX CREDIT') {
                this.assetErrorMsg = this.labels.taxCreditError; 
            }
            else if (woDesc=='EQUIPMENT DECOMMISSIONING') {
                this.assetErrorMsg = this.labels.equipmentDecommissioningError;
            }
            else if (woDesc=='PLANT READY EQP COMMISSIONING'){
                this.assetErrorMsg = this.labels.plantReadyError;
            }
            else if (woDesc=='PREVENTATIVE MAINTENANCE'){
                this.assetErrorMsg = this.labels.preventativeMaintenanceError;
            }
        } 
        else{
            this.assetErrors=false;
            this.assetErrorMsg='';
        }
    }

    // To create inspection
    handleInspectionrecordCreation(recordInput){
        createRecord(recordInput).then(result => {
            this.createdWorkOrderSfId=result.id;
            this.reset();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Inspection is generated successfully.',
                    variant: 'success',
                }),
            );

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url:`com.salesforce.fieldservice://v1/sObject/${result.id}/details`
                }
            });
        
        }).catch(error=>{
            console.log(JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }
        
    handlePrimaryAndRelocation(stms){
        let  primaryStId='';
        for(let stm in stms){
            console.log("Handle"+JSON.stringify(stms[stm]));
            // If Relocation ST found return ST id
            if(stms[stm].TerritoryType=='R'){
                console.log('Relocation');
                console.log("Handle"+JSON.stringify(stms[stm].EffectiveStartDate));
                console.log("Handle"+JSON.stringify(stms[stm].EffectiveEndDate));
                const currentDate = new Date();
                currentDate.setHours(0,0,0,0);
                console.log("Curr Date: "+currentDate.setHours(0,0,0,0));
                var formatStartDate=new Date(stms[stm].EffectiveStartDate);
                formatStartDate.setHours(0,0,0,0);
                var formatEndDate=new Date(stms[stm].EffectiveEndDate);
                formatEndDate.setHours(0,0,0,0);
                console.log("Handle"+formatStartDate);
                console.log("Handle"+formatEndDate);
                if(currentDate>= formatStartDate && currentDate<=formatEndDate){
                    console.log("I have relocation"+stms[stm].Id);
                    return stms[stm].ServiceTerritoryId;
                }
            }
            
            // if relocation not found store primary ST Id
            if(stms[stm].TerritoryType=='P'){
                console.log('Primary');
                console.log("Handle"+JSON.stringify(stms[stm].EffectiveStartDate));
                console.log("Handle"+JSON.stringify(stms[stm].EffectiveEndDate));
                const currentDate = new Date();
                currentDate.setHours(0,0,0,0);
                console.log("Curr Date: "+currentDate);
                var formatStartDate=new Date(stms[stm].EffectiveStartDate);
                formatStartDate.setHours(0,0,0,0);
                var formatEndDate=new Date(stms[stm].EffectiveEndDate);
                formatEndDate.setHours(0,0,0,0);
                console.log("Handle"+formatStartDate);
                console.log("Handle"+formatEndDate);
                if(stms[stm].EffectiveEndDate){
                    if(currentDate>= formatStartDate && currentDate<=formatEndDate){
                        console.log("I have primary with enddate"+stms[stm].Id);
                        primaryStId= stms[stm].ServiceTerritoryId;
                    }
                }
                else{
                    console.log("I have primary with no end date"+stms[stm].Id);
                    primaryStId =stms[stm].ServiceTerritoryId;
                    
                }
            }
        }

        // if Relocation found return ST id if primary found return primary one
        if(primaryStId!=''){
            return primaryStId;
        }
    }

    // Asset details server call
    getAssetDetails(assId){

        getAssetDetaisApex({assetId:assId}).then(result=>{
            console.log("FROM APEX"+JSON.stringify(result));
            this.make=result.SM_PS_Make__c;
            // Retro
            this.model=result.SM_PS_Model__c;
            this.serialNumber=result.SM_PS_Serial_Number__c
            // Asset status
            this.status=result.Status;
            var warrDate=result.SM_PS_Warranty_Exp_Date__c;
            // For UI.UX Feedback
            var formatDate=new Date(warrDate);
            // Retro
            const currentDate = new Date();
            console.log("Curr Date: "+currentDate);
            var dateExp=String(warrDate).slice(-2);
            var monthExp=month[formatDate.getMonth()];
            var yearExp=formatDate.getFullYear();
            this.warrantyExpiryDate=dateExp+'-'+monthExp+'-'+yearExp;
            this.callClassDesc=result.SM_PS_Cat_Class_Description__c;
            this.currentMiHr=result.SM_PS_Current_MiHr__c;
            console.log('current mileage and hr'+this.currentMiHr);
            if(this.warrantyExpiryDate && formatDate >= currentDate){
                this.isAssetWarrantyExpiryDate=true;
            }
            else{
                this.isAssetWarrantyExpiryDate=false;
            }
            // Checking put in shop logic here
            this.handlePutInShopDefaultLogic(this.status,this.woDescValue);
        });

    }

    // TO handle put in shop default logic
    handlePutInShopDefaultLogic(assetStatus,woDesc){
        // As per Serv-8579
        //Case 3: A & R  Statuses
        //Create - Default to down the asset (Put in Shop - Y)
        // Else all (Put in Shop - N)
        console.log("Asset Status:+"+assetStatus+"WOD:"+woDesc);

        if((woDesc=='EQUIPMENT REPAIR' || woDesc =='BREAKDOWN SERVICE CALL' 
            || woDesc=='DAMAGE - CUSTOMER BILLED' || woDesc=='DAMAGE - RPP CLAIM' 
            || woDesc== 'DAMAGE - RPP TIRE CLAIM'|| woDesc=='CUSTOMER RESPONSIBLE INCIDENT' 
            || woDesc=='WARRANTY' || woDesc=='REPLACEMENT ENGINE' 
            || woDesc=='REPLACEMENT TIRES'|| woDesc=='BOOM CABLE REPLACEMENT' 
            || woDesc=='INSPECTION DEFECT ACTION REQD'|| woDesc=='CENTRAL SERVICES @ PC LABOR' 
            || woDesc=='Used Equipment Warranty (SPF)' || woDesc=='RECAP'
            || woDesc=='VEHICLE REPAIRS' || woDesc=='NEW RENTAL EQUIP COMMISSIONING') 
            && (assetStatus=='AVAILABLE' || assetStatus=='RETURNED - NEED CHECK OUT' ))
        {
            this.putInShopMakeAvailableValue='Y'
        }
        else{
            this.putInShopMakeAvailableValue='N'
        }
    }
  /* CR - SERV: 17886 : If (Work Order Description = ‘Breakdown Service Call’) and (If Asset.Status = ‘On Rent’ || Asset.Status= ‘On Rental Purchase’ || Asset.Status='Schedule for Pickup')
        Set Service Call=Y;
        Else Service Call=N*/
  handleServiceCallPopulation(woDesc,assetStatus){

    if (woDesc == 'BREAKDOWN SERVICE CALL' && (assetStatus != 'ON RENT' 
                || assetStatus != 'ON RENTAL PURCHASE' || assetStatus != 'SCHEDULED FOR PICKUP')){
                    return 'Y';
    }else{
                    return 'N';
    } 

  }
}