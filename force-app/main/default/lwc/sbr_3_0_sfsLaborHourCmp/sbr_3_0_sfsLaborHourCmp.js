import { LightningElement,api,wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord } from 'lightning/uiRecordApi';
import lightningAddModalLWC from 'c/sbr_3_0_sfsAddLaborModalCmp';
import lightningViewModalLWC from 'c/sbr_3_0_sfsViewLaborModalCmp';
import lightningEditModalLwc from 'c/sbr_3_0_sfsEditLaborModalCmp';
import lightningDeleteModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import lightningErrorModalLWC from 'c/sbr_3_0_sfsGenericErrorMessageModal';
import getWoliListForTable from '@salesforce/apex/SBR_3_0_WorkOrderLineItemDA.getWoliTableRecs';
//import deleteWoliRecs from '@salesforce/apex/SBR_3_0_WorkOrderLineItemDA.deleteWoli';
import getAssignedServiceResource from '@salesforce/apex/SBR_3_0_ServiceResourceDA.getServiceResourceIdFromWorkOrderId';
import USER_ID from '@salesforce/user/Id';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WOLI_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import validatePsg from '@salesforce/apex/SBR_3_0_ServiceResourceDA.validateLoggedInResourcePermissionSetGroup';
import { deleteRecord } from 'lightning/uiRecordApi';
const columns = [
                    { label: 'Mech ID' },
                    { label: 'Line Type' },
                    { label: 'Labor Cd' },
                    { label: 'Hrs/Mi'},
                    { label: 'Total' }
                ];

export default class Sbr_3_0_sfsLaborHourCmp extends LightningElement {
    // Api variables / Public  Variable
    @api recordId;

    // Default once / Private Varible
    title='Labor and Travel Mileage '
    messageTitle ='Note: '
    message="Once Labor Hours and Travel Mileage are entered, press the 'X' in the top left corner to save the information and return to the inspection."
    tableRecs=[];
    columns=columns;
    addButtonLabel='Add';
    viewButtonLabel='View';
    editButtonLabel='Edit';
    deleteButtonLabel='Delete';
    refreshButtonLabel='Refresh';
    showTable=false;
    showDeleteConfirmation=false;

    // Local 
    woliRecs;
    error;
    defaultServiceResourceId;
    defaultServiceResourceLaborType;
    deafaultMechanicId;
    defaultMechanicRate;
    defaultLineTypeLabel; // (Inide or Outside)
    defaultLineTypeValue; // (LI or LO)
    addedRows;
    selectedRecords;
    recsToBeDelete=[];
    serviceAppointmentId;
    isServiceLeader;
    woliId;
    laborCodeArray=[];
    lineTypeArray=[];
    WoDesc;//work order description 
    woLaborCode; // work order labor code
    //Edit
    defaultEditServiceResourceId;
    deafaultEditMechanicId;
    defaultEditMechanicRate;
    defaultEditServiceResourceLaborType;
    isWorkOrderClosedCancelled=false;
    error;
    msg="Labor hours cannot be logged for Canceled or Closed Inspections.";
    
    

    // To get related WorkOrderLineItem for from WorkOder Id lightning UI api.
    @wire(getRelatedListRecords, {parentRecordId:'$recordId',
            relatedListId: 'WorkOrderLineItems',
            fields: [
                        'WorkOrderLineItem.SF_PS_Mechanic_Id__c',
                        'WorkOrderLineItem.SF_PS_Mechanic_Name__c',
                        'WorkOrderLineItem.SF_PS_Line_Type__c',
                        'WorkOrderLineItem.SF_PS_Labor_Code__c',
                        'WorkOrderLineItem.Duration',
                        'WorkOrderLineItem.SF_PS_Sub_Total__c',
                        'WorkOrderLineItem.SF_PS_Mechanic_Name__r.Name'
                    ],
    })listWoliRecs({error,data}){
        if(data){
            this.error = undefined;
            //this.woliRecs=this.woliRecordsToDisplay(data.records);
        } 
        else if(error){
            console.log(" ERROR: "+JSON.stringify(error));
        }
    }


    // Get Assigned Service resource Id from Apex
    @wire (getAssignedServiceResource,{workOderId:'$recordId'})
    defaultServiceResource({error,data}){
        if (data){
            this.defaultServiceResourceId=data;
            this.error = undefined;
        }
        else if (error){
            console.log(" ERROR: "+JSON.stringify(error));
            this.defaultServiceResourceId = undefined;
        }
    }

    // Get work order status
    @wire(getRecord, { 
        recordId: '$recordId',
        fields: [   
                    'WorkOrder.Status',
                    'WorkOrder.SF_PS_Work_Order_Des__c',
                    'WorkOrder.SF_PS_LaborCode__c'
                ]
    })workOrderRec({error,data}){
        if(data){
            console.log("WORK ORDER Data::"+JSON.stringify(data.fields.Status));
            if(data.fields.Status.value=='C' || data.fields.Status.value=='D'){
                this.isWorkOrderClosedCancelled=true;
            }
            else{
                this.isWorkOrderClosedCancelled=false;
            }
            this.WoDesc=data.fields.SF_PS_Work_Order_Des__c.value;
            this.woLaborCode=data.fields.SF_PS_LaborCode__c.value;
        }
        else{
            console.log(JSON.stringify(error));
        }
    }


    // Get Mechnaic Id and Rate of Service Resource
    @wire(getRecord, { 
    recordId: '$defaultServiceResourceId', 
    fields: [
                'ServiceResource.SF_PS_Mechanic_Id__c',
                'ServiceResource.SF_PS_Hourly_Internal_Rate__c',
                'ServiceResource.SF_PS_Labor_Type__c'
            ]
    })defaultMechanicId({error,data}){
        if(data) {
            console.log('Data in mechanic wire method::'+ JSON.stringify(data));
            this.deafaultMechanicId=data['fields']['SF_PS_Mechanic_Id__c'].value;
            this.defaultMechanicRate=data['fields']['SF_PS_Hourly_Internal_Rate__c'].value;
            this.defaultServiceResourceLaborType=data['fields']['SF_PS_Labor_Type__c'].value
            if(data['fields']['SF_PS_Labor_Type__c'].value=="I"){
                this.defaultLineTypeLabel="Inside Labor";
                this.defaultLineTypeValue="LI";
            }
            else if(data['fields']['SF_PS_Labor_Type__c'].value=="O"){
                this.defaultLineTypeLabel="Outside Labor";
                this.defaultLineTypeValue="LO";
            // Default case
            }
            else{
                this.defaultLineTypeLabel="Inside Labor";
                this.defaultLineTypeValue="LI";
            }
        } 
        else if (error) {
            console.log(error);
            this.error = error;
            this.deafaultMechanicId = undefined;
        }
    }

    // To get validate PSG of Service Resource logged in
    @wire(validatePsg,{userId:USER_ID,psgApiName:'Dispatcher'})
    isPsg({error,data}){
        if(data){
            this.isServiceLeader=true;
        }
        else{
            this.isServiceLeader=false
        }
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
    )laborCodeValues({error,data}){
        if (data){
            console.log(data);
            let tempArray=[];
            for(let dt of data.values){
                tempArray.push(dt) 
            }
            this.laborCodeArray=tempArray;
        } 
        else if(error){
            console.log(error);
            
        }
    }

    // To get picklistvalues for Line Type
    @wire(getPicklistValues,
    {
        recordTypeId: '$woliInfo.data.defaultRecordTypeId',
        fieldApiName:  'WorkOrderLineItem.SF_PS_Line_Type__c'
    })lineTypeValues({error,data}){
        if (data){
            console.log('Data in linetype value wire method::'+data);
            let tempArray=[];
            for(let dt of data.values){
                tempArray.push(dt) 
            }
            this.lineTypeArray=tempArray;
        } 
        else if (error) {
            console.log(error);
        }
    }
    
    
    // Life Cycle hook connected call back to load records at time of component loading.
    connectedCallback(){
        getWoliListForTable({recId:this.recordId}).then(result=> {
            let tempTableRecs=[];
            for(let rec of result){
                tempTableRecs.push({
                    Id:rec.Id,
                    columnOne:rec.SF_PS_Mechanic_Id__c,
                    columnTwo:rec.SF_PS_Line_Type__c,
                    columnThree:String(rec.SF_PS_Labor_Code__c).substring(0,4),
                    ColumnFour:rec.Duration,
                    ColumnFive:rec.SF_PS_Extended_Rate__c,
                    detail:JSON.stringify(rec.SF_PS_Mechanic_Name__r)
                })
            }
            this.tableRecs=tempTableRecs;
            console.log("Table REC COUNT:"+this.tableRecs.length);
            if(this.tableRecs.length>0){
                this.showTable=false;
                this.showTable=true;
            }
            else{
                this.showTable=false;
            }
        }).catch(error=>{
            console.log("Error getWoliListForTable : "+JSON.stringify(error));      
        });   
    }

    // To handle record selected for Edit or delete
    handleSelectClick(event){
        this.selectedRecords=JSON.stringify(event.detail);
        if(JSON.stringify(event.detail)!='[]'){
            console.log("Select Event Data:: "+JSON.stringify(event.detail));
            let selectedRec=JSON.parse(event.detail[0].detail);
            this.woliId=event.detail[0].Id;
            this.defaultEditServiceResourceId=selectedRec.Id;
            this.deafaultEditMechanicId=selectedRec.SF_PS_Mechanic_Id__c;
            this.defaultEditMechanicRate=selectedRec.SF_PS_Hourly_Internal_Rate__c;
            this.defaultEditServiceResourceLaborType=selectedRec.SF_PS_Labor_Type__c;
            console.log(this.woliId +  this.defaultEditServiceResourceId);
        }
    }


    // To handle Add click  button 
    async handleAddClick(event){
    console.log("ADD", this.recordId);
        await lightningAddModalLWC.open({
            size: 'small',
            headerText:'Add Labor',
            workOrderId:this.recordId,
            defaultServiceResourceId:this.defaultServiceResourceId,
            mechanicId:this.deafaultMechanicId,
            mechanicRate:this.defaultMechanicRate,
            lineTypeLabel:this.defaultLineTypeLabel,
            lineTypeValue:this.defaultLineTypeValue,
            serviceResourceLaborType:this.defaultServiceResourceLaborType,
            isServiceLeader:this.isServiceLeader,
            currRecords:this.tableRecs,
            WoDescription : this.WoDesc,
            woLaborCode:this.woLaborCode,
            onaddrow:(e)=>{
                console.log("ADD ONCE"+JSON.stringify(e.detail.recs));
                this.tableRecs = this.tableRecs.concat(e.detail.recs);
                localStorage.setItem('OfflineRecs',JSON.stringify(this.tableRecs));
                localStorage.setItem('Add','Add');
                this.showTable=false;
                this.showTable=true;  
            }
        });
    }

    // To handle view click 
    async handleViewClick(event){
        debugger;
        try{
            const result= await lightningViewModalLWC.open({
                size: 'small',
                selectedRecordId : event.detail[0].Id,
                mechanicId : JSON.parse(event.detail[0].detail).SF_PS_Mechanic_Id__c
            })
        }
        catch(error){
            console.log("Error::" + JSON.stringify(error));
        }        
        this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();

    }

    // To handle edit click
    async handleEditClick(){
        await lightningEditModalLwc.open({
            size: 'small',
            headerText:'Edit Labor',
            workOrderId:this.recordId,
            woliId:this.woliId,
            serviceResourceId:this.defaultEditServiceResourceId,
            mechanicId:this.deafaultEditMechanicId,
            laborCodeArray:this.laborCodeArray,
            lineTypeArray:this.lineTypeArray,
            selectedMechanicRate:this.defaultEditMechanicRate,
            serviceResourceLaborType:this.defaultEditServiceResourceLaborType,
            isServiceLeader:this.isServiceLeader,
            WoDescription:this.WoDesc,
            oneditrow:(e)=>{
                console.log(JSON.stringify(e.detail.recs));
                let tempArray=[]
                for(let rec of this.tableRecs){
                    if(rec.Id==e.detail.recs.Id){
                        tempArray.push(e.detail.recs)
                    }
                    else{
                        tempArray.push(rec)
                    }
                }
                this.tableRecs=[];
                this.tableRecs= this.tableRecs.concat(tempArray);
                this.showTable=false;
                this.showTable=true;
            }

        });
        this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();
    }


    // To handle delete click  button 
    async handleDeleteClick(event){
        await lightningDeleteModalLWC.open({
            size: 'small',
            description: 'Accessible description of modal purpose',
            content: 'Are you sure want to delete these records ?',
            headerText:'Confirmation',
            onyesclick:(e)=>{
                //console.log('DELETE SELECTED RECORDS:'+this.selectedRecords);
                let recordsToDeleteList=[]
                for(let recs of JSON.parse(this.selectedRecords)){
                    //recordsToDeleteList.push({Id:recs.Id});
                    recordsToDeleteList.push(recs.Id);
                }
                let tempTableRecs=this.tableRecs;
                for(let recs of recordsToDeleteList){
                    console.log(JSON.stringify(recs));
                    //console.log(JSON.stringify(row));
                    tempTableRecs.splice(tempTableRecs.findIndex(row => row.Id === recs),1);
                }
                this.tableRecs=[]
                this.tableRecs= this.tableRecs.concat(tempTableRecs);
                if(this.tableRecs.length>0){
                    this.showTable=false;
                    this.showTable=true;
                }
                else{
                    this.showTable=false;
                }
                this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();
                console.log('DELETE SELECTED RECORDS:'+JSON.stringify(recordsToDeleteList));
                
                this.deleteMultiRec(0,recordsToDeleteList);
                /*deleteWoliRecs({woliRecsToDelete:recordsToDeleteList})
                    .then(result=>{
                        console.log(JSON.stringify(result));
                    }).catch(error=>{
                        console.log(JSON.stringify(error));
                        this.error=JSON.stringify(error);
                        lightningErrorModalLWC.open({
                            size: 'small',
                            description: 'Accessible description of modal purpose',
                            content: 'Insufficient access to Work Order record.',
                        });

                    });*/
            }
        });
    }

    deleteMultiRec(index,array){
        if(index==array.length){
            return;
        }
        else{
            console.log("Elem:"+array[index]+" Index:"+index+"len:"+array.length)
            deleteRecord(array[index])
            .then((result) => {
                console.log(JSON.stringify(result));
                this.deleteMultiRec(index+1,array)
            }).catch(error=> {
                console.log(JSON.stringify(error));
                lightningErrorModalLWC.open({
                    size: 'small',
                    description: 'Accessible description of modal purpose',
                    content: 'Insufficient access to Work Order record.',
                });
            });
        }
    }
}