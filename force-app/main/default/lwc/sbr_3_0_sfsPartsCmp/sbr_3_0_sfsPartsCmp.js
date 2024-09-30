import { LightningElement,api,wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import lightningAddPartsModalLWC from 'c/sbr_3_0_sfsAddPartsCmp';
import lightningEditPartsModalLWC from 'c/sbr_3_0_sfsEditPartsCmp';
import lightningViewPartsModalLWC from 'c/sbr_3_0_sfsViewPartsModalCmp';
import lightningDeleteModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import { deleteRecord } from 'lightning/uiRecordApi';
import getPcTableRecs from '@salesforce/apex/SBR_3_0_ProductConsumedDA.getPcTableRecs';
import {getRecord} from "lightning/uiRecordApi";
import COMPANY_CODE from '@salesforce/schema/WorkOrder.SF_PS_Company_Code__c';
import BRANCH_LOCATION_NUMBER from '@salesforce/schema/WorkOrder.ServiceTerritory.Branch_Location_Number__c';
import WO_DESC from '@salesforce/schema/WorkOrder.SF_PS_Work_Order_Des__c';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_LABOR_CODE from '@salesforce/schema/WorkOrder.SF_PS_LaborCode__c';


const columns = [
    { label: 'Item #' },
    { label: 'STK/C' },
    { label: 'Description'},
    { label: 'Qty'}
];

export default class Sbr_3_0_sfsPartsCmp extends LightningElement {

    @api recordId;
    @track recordData={}
    
    title='Branch Inventory';
    messageTitle ='Note: '
    message="Once Branch Inventory is entered, press the 'X' in the top left corner to save the information and return to the inspection."
    tableRecs;
    columns=columns;
    addButtonLabel='Add';
    viewButtonLabel='View';
    editButtonLabel='Edit';
    deleteButtonLabel='Delete';
    showTable=false;
    productConsumedRecs
    recsToBeDelete=[];
    productItemId;
    hideLastColumn=true;
    additionalQuery
    woLoaded=false;
    woDesc;
    woLaborCode;
    errorMsg;
    showErrorForCheckInReturn=false;
    isReadOnly=false;
    msg;
   

    @wire(getRecord,{recordId:'$recordId',fields:[COMPANY_CODE,BRANCH_LOCATION_NUMBER,
        WO_DESC,WO_STATUS,WO_LABOR_CODE]})
    workOrderData({data,error}){
        if(data){
            console.log('JSON. '+JSON.stringify(data));
            this.companyCode=data.fields.SF_PS_Company_Code__c.value;
            this.woDesc=data.fields.SF_PS_Work_Order_Des__c.value;
            let woStatus=data.fields.Status.value;
            this.woLaborCode=data.fields.SF_PS_LaborCode__c.value;
            this.branchLocationNumber=data.fields.ServiceTerritory.value.fields.Branch_Location_Number__c.value;
            this.additionalQuery=`Location.Company_Code__c='${this.companyCode}' and RecordType.DeveloperName='Parts_and_Merchandise' and (SM_PS_Product_Type__c like '%Parts%' or SM_PS_Product_Type__c like '%Mer%') and Location.Branch_Location_Number__c='${this.branchLocationNumber}' `;
            //this.additionalQuery=`Location.Company_Code__c='${this.companyCode}' and Location.Branch_Location_Number__c='${this.branchLocationNumber}' and QuantityOnHand>0 `;
            console.log(this.additionalQuery);
            
            if(this.woDesc=='CHECK IN RETURN' || this.woDesc=='NEW RENTAL EQUIP COMMISSIONING' || this.woDesc=='REMARKETING INSPECTION'){
                this.showErrorForCheckInReturn=true;
                this.isReadOnly=false;
                this.errorMsg='Parts cannot be added on Rent Ready, New Rental Equip Commissioning and Remarketing Inspections.'
            }else if(woStatus=='C'||data.fields.Status.value=='D'){
                this.showErrorForCheckInReturn=false;
                this.isReadOnly=true;
                this.msg='Parts cannot be added/updated on Closed or Canceled Work Order'
            }else{
                this.isReadOnly=false;
                this.showErrorForCheckInReturn=false;
            }
            this.woLoaded=true;
        }
        else if(error){
            console.log('error occured '+JSON.stringify(error));
        }
    }


    connectedCallback(){
        getPcTableRecs({recId:this.recordId})
        .then(result=> {
        // console.log("Parts RECS FROM APEX: "+JSON.stringify(result));
            //console.log(result);
            let tempTableRecs=[];
            for(let rec of result){
                let details={}
                //details.productItemId=rec?.ProductItem?.Id
                // details.itemNumber=rec?.Product2?.Item_Number__c;
                details.itemNumber=rec?.SF_PS_Product_Item__r?.SM_PS_Item_Number__c;
                //details.quantityOnHand=rec?.ProductItem?.QuantityOnHand;
                if(!rec?.SF_PS_Cost_Price__c){
                    details.averageCost='USD '+Number('0').toFixed(2);
                }
                else{
                    details.averageCost='USD '+Number(rec?.SF_PS_Cost_Price__c).toFixed(2);
                }
                if(!rec?.Product2?.List_Price__c){
                    details.listPrice='USD '+Number('0').toFixed(2);
                }
                else{
                    details.listPrice='USD '+Number(rec?.Product2?.List_Price__c).toFixed(2);
                }
                if(!rec?.Product2?.Sell_Price__c){
                    details.sellPrice='USD '+Number('0').toFixed(2);
                }
                else{
                    details.sellPrice='USD '+Number(rec?.Product2?.Sell_Price__c).toFixed(2);
                }
                details.uom=rec.Product2?.QuantityUnitOfMeasure;
                //details.stockClass=rec?.Product2?.Stock_class__c;
                details.stockClass=rec?.SF_PS_Product_Item__r?.SM_PS_Stock_Class__c;
                details.desc=rec.Product2?.Description__c;
                details.binLoc=rec?.SF_PS_Product_Item__r?.SM_PS_Bin_Location_1__c;
                details.productConsumedid=rec?.Id;
                details.Name=rec?.Product2?.Name;
                details.quantityConsumedValue=rec?.SF_PS_Quantity__c;
                details.OriginalquantityConsumed=rec?.QuantityConsumed;
                details.qtyAvail=rec?.SF_PS_Product_Item__r?.SM_PS_PartsMerch_Available_Quantity__c;
                details.laborCodeDisplayValue=rec?.SF_PS_Labor_Code__c;
                details.laborCodeValue=details.laborCodeDisplayValue.substring(0,4);
                details.originalBackorderQty=rec?.SF_PS_Original_Backordered_Quantity__c
                details.shippedQty=rec?.SF_PS_Shipped_Qty__c;
                details.backOrderedQty=rec?.SF_PS_Backordered_Qty__c;
                details.customProductItemId=rec?.SF_PS_Product_Item__c;
                details.itemType=rec?.SF_PS_ItemType__c;
                if(rec?.SF_PS_ItemType__c == 'Parts' || rec?.SF_PS_ItemType__c == 'Merchandise'){
                    tempTableRecs.push({
                        Id:rec.Id,
                        columnOne:rec?.SF_PS_Product_Item__r?.SM_PS_Item_Number__c?.length>13?(((rec?.SF_PS_Product_Item__r?.SM_PS_Item_Number__c+'').substring(0,13))+'..'):rec?.SF_PS_Product_Item__r?.SM_PS_Item_Number__c,
                        columnTwo:rec?.SF_PS_Product_Item__r?.SM_PS_Stock_Class__c,
                        columnThree:rec.Product2?.Description__c?.length>20?((rec.Product2.Description__c.substring(0,20))+'..'):rec.Product2.Description__c,
                        ColumnFour:rec.SF_PS_Quantity__c,
                        //detail:JSON.stringify(rec.Product2)
                        detail:JSON.stringify({details})
                    })
                }
            }
            this.tableRecs=tempTableRecs;
            console.log('Tab Recs::' + JSON.stringify(this.tableRecs));
            if(this.tableRecs.length>0){
                this.showTable=false;
                this.showTable=true;
            }else{
                this.showTable=false;
            }
        }).catch(error=>{
            console.log("Error getWoliListForTable : "+JSON.stringify(error));      
        });  
    }


    // Handles click of Add Button
    async handleAddClick(){
        await lightningAddPartsModalLWC.open({
            size: 'small',
            headerText:'Add Parts',
            woId:this.recordId,
            additionalQuery:this.additionalQuery,
            woCompanyCode:this.companyCode,
            woLaborCode:this.woLaborCode,
            onaddrow:(e)=>{
                let row=JSON.parse(JSON.stringify(e.detail.recs));
                let details= JSON.parse(JSON.stringify(e.detail.recDetail));
                row.detail=JSON.stringify({details});
                this.tableRecs = this.tableRecs.concat(row);
                this.showTable=false;
                this.showTable=true;  
            }
        });
    }

    //Handle view button event
    async handleViewClick(event){
        let eventData=JSON.parse(event.detail[0].detail).details;
        debugger;
        console.log('SelectedRecordId::'+ JSON.stringify(eventData));
        try{
            await lightningViewPartsModalLWC.open({
                size: 'small',
                headerText:'View Parts',
                selectedRecord : eventData
            });
        }
        catch(error){
            console.log("error in modal Open::"+ JSON.stringify(error));
        }
        
        this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();
    }

    // Handles selection of records
    handleSelectClick(event){
        this.selectedRecords=JSON.stringify(event.detail);
        console.log('this is selected records '+this.selectedRecords);
        if(JSON.stringify(event.detail)!='[]'){
            let record=JSON.parse(event.detail[0].detail);
            let selectedRec=JSON.parse(event.detail[0].detail);
            console.log("Selected Data: "+JSON.stringify(record));
            this.recordData=record.details;
        }
    }

    // Handles updation of records
    async handleEditClick(){
        console.log("productItemSfId 1"+JSON.stringify(this.recordData));
        console.log("productItemSfId 1"+this.recordData.productItemId);
        await lightningEditPartsModalLWC.open({
            size: 'small',
            headerText:'Edit Parts',
            record:this.recordData,
            quantityConsumedValue:this.recordData.quantityConsumedValue,
            laborCodeValue:this.recordData.laborCodeValue,
            productItemSfId:this.recordData.customProductItemId,

            oneditrow:(e)=>{
                let row=JSON.parse(JSON.stringify(e.detail.recs));
                let details= JSON.parse(JSON.stringify(e.detail.recDetail));
                //console.log(details);
                row.detail=JSON.stringify({details});
                let tempArray=[]
                for(let rec of this.tableRecs){
                    if(rec.Id==e.detail.recs.Id){
                        tempArray.push(row)
                    }else{
                        tempArray.push(rec)
                    }
                }
                this.tableRecs=[];
                this.tableRecs= this.tableRecs.concat(tempArray);
                this.selectedRecords="";
                this.recordData="";
                this.showTable=false;
                this.showTable=true;
            }
        });
        this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();
    }

    //To handle delete click  button 
    async handleDeleteClick(event){
        await lightningDeleteModalLWC.open({
            size: 'small',
            description: 'Accessible description of modal purpose',
            content: 'Are you sure want to delete these records ?',
            headerText:'Confirmation',
            onyesclick:(e)=>{
                let recordsToDeleteList=[]
                for(let recs of JSON.parse(this.selectedRecords)){
                    //recordsToDeleteList.push({Id:recs.Id});
                    recordsToDeleteList.push(recs.Id);
                }
                let tempTableRecs=this.tableRecs;
                for(let recs of recordsToDeleteList){
                    tempTableRecs.splice(tempTableRecs.findIndex(row => row.Id === recs),1);
                }
                this.tableRecs=[]
                this.tableRecs= this.tableRecs.concat(tempTableRecs);

                if(this.tableRecs.length>0){
                    this.showTable=false;
                    this.showTable=true;
                }else{
                    this.showTable=false;
                }
                this.template.querySelector('c-sbr_3_0_sfs-generic-data-table').handleRemoveSelection();
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
        }else{
            //console.log("Elem:"+array[index]+" Index:"+index+"len:"+array.length)
            deleteRecord(array[index]).then((result) => {
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