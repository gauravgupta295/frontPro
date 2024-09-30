import { LightningElement,api,wire,track } from 'lwc';
import getPcTableRecs from '@salesforce/apex/SBR_3_0_ProductConsumedDA.getPcTableRecs';
import lightningAddMiscPartModalLWC from 'c/sbr_3_0_sfsAddMiscItems';
import lightningViewMiscPartsModalLWC from 'c/sbr_3_0_sfsViewMiscItemsCmp';
import lightningEditMiscItemsModalLWC from 'c/sbr_3_0_sfsEditMiscItemsCmp';
import {getRecord} from "lightning/uiRecordApi";
import COMPANY_CODE from '@salesforce/schema/WorkOrder.SF_PS_Company_Code__c';
import BRANCH_LOCATION_NUMBER from '@salesforce/schema/WorkOrder.ServiceTerritory.Branch_Location_Number__c';
import WO_DESC from '@salesforce/schema/WorkOrder.SF_PS_Work_Order_Des__c';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import { deleteRecord } from 'lightning/uiRecordApi';
import lightningDeleteModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import WO_LABOR_CODE from '@salesforce/schema/WorkOrder.SF_PS_LaborCode__c';
import WO_BILL_CUST_LOC from '@salesforce/schema/WorkOrder.SF_PS_BillCustOrLoc__c';
const columns = [
    { label: 'Item #' },
    { label: 'STK/C' },
    { label: 'Description'},
    { label: 'Qty'}
];

export default class Sbr_3_0_sfsMiscItemCmp extends LightningElement {

    //Api exposed Properties
    @api recordId;

    //Trackable properties
    @track recordData={};

    //Properties
    title='Miscellaneous Items';
    messageTitle ='Note: '
    message="Once Miscellaneous Items are entered, press the 'X' in the top left corner to save the information and return to the inspection."
    tableRecs;
    columns=columns;
    addButtonLabel='Add';
    viewButtonLabel='View';
    editButtonLabel='Edit';
    deleteButtonLabel='Delete';
    showTable=false;
    hideLastColumn=true;
    companyCode;
    woDesc;
    woLaborCode;
    woBillCustOrLOc;
    selectedRecords;
    branchLocationNumber;
    isWorkOrderClosedCancelled=false;
    msg='Misc Items cannot be added/updated on Closed or Canceled Work Order'
    showErrorForCheckInReturn=false;
    errorMsg;

    // To get Work Order Details/Data
    @wire(getRecord,{recordId:'$recordId',
                    fields:[COMPANY_CODE,BRANCH_LOCATION_NUMBER,
                            WO_DESC,WO_STATUS,WO_LABOR_CODE,WO_BILL_CUST_LOC]})
    workOrderData({data,error}){
        if(data){
            console.log('JSON. '+JSON.stringify(data));
            this.companyCode=data.fields.SF_PS_Company_Code__c.value;
            this.woDesc=data.fields.SF_PS_Work_Order_Des__c.value;
            let woStatus=data.fields.Status.value;
            this.woLaborCode=data.fields.SF_PS_LaborCode__c.value;
            this.woBillCustOrLOc=data.fields.SF_PS_BillCustOrLoc__c.value;
            this.branchLocationNumber=data.fields.ServiceTerritory.value.fields.Branch_Location_Number__c.value;
            if(woStatus=='C'|| woStatus=='D'){
                this.isWorkOrderClosedCancelled = true;
             }
             if(this.woDesc=='CHECK IN RETURN' || this.woDesc=='NEW RENTAL EQUIP COMMISSIONING' || this.woDesc=='REMARKETING INSPECTION'){
                this.showErrorForCheckInReturn=true;
                this.errorMsg='Misc Items cannot be added on Rent Ready, New Rental Equip Commissioning and Remarketing Inspections.'
            }

        } 
        else if(error){
            console.log('error occured '+JSON.stringify(error));
        }
    }

    // Connected Call back
    connectedCallback(){
        getPcTableRecs({recId:this.recordId})
        .then(result=> {
            let tempTableRecs=[];
            for(let rec of result){
                let details={}
                console.log("TABLE RECS PC:"+JSON.stringify(rec));
                details.itemNumber=rec?.Product2?.SM_PS_Item_number__c;
                if(!rec?.Product2?.Average_Cost__c){
                    details.averageCost='USD '+Number('0').toFixed(2);
                }
                else{
                    details.averageCost='USD '+Number(rec?.Product2?.Average_Cost__c).toFixed(2);
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
                // details.listPrice='USD '+Number(rec?.Product2?.List_Price__c).toFixed(2)
                // details.sellPrice='USD '+Number(rec?.Product2?.Sell_Price__c).toFixed(2);
                details.uom=rec.Product2?.QuantityUnitOfMeasure;
                details.stockClass=rec?.Product2?.Stock_class__c;
                details.desc=rec.Product2.Description__c;
                //details.binLoc=rec?.ProductItem?.SM_PS_Bin_Location_1__c;
                details.productConsumedid=rec?.Id;
                details.Name=rec?.Product2?.Name;
                details.quantityConsumedValue=rec?.SF_PS_Quantity__c;
                details.OriginalquantityConsumed=rec?.QuantityConsumed;
                details.laborCodeDisplayValue=rec?.SF_PS_Labor_Code__c;
                details.laborCodeValue=details.laborCodeDisplayValue.substring(0,4);
                details.originalBackorderQty=rec?.SF_PS_Original_Backordered_Quantity__c
                details.shippedQty=rec?.SF_PS_Shipped_Qty__c;
                details.backOrderedQty=rec?.SF_PS_Backordered_Qty__c;
                details.newSellingPrice=rec?.SF_PS_Selling_Price__c;
                details.itemType=rec?.SF_PS_ItemType__c;
                // Add just Misc items not parts
                if(rec.SF_PS_ItemType__c=='Miscellaneous'){
                    tempTableRecs.push({
                        Id:rec.Id,
                        columnOne:rec.Product2?.SM_PS_Item_number__c?.length>13?(((rec.Product2.SM_PS_Item_number__c+'').substring(0,13))+'..'):rec.Product2.SM_PS_Item_number__c,
                        columnTwo:rec.Product2?.Stock_class__c,
                        columnThree:rec.Product2?.Description__c?.length>20?((rec.Product2.Description__c.substring(0,20))+'..'):rec.Product2.Description__c,
                        ColumnFour:rec.SF_PS_Quantity__c,
                        //detail:JSON.stringify(rec.Product2)
                        detail:JSON.stringify({details})
                    })
                }  
            }
            
            this.tableRecs=tempTableRecs;
            console.log("Table REC COUNT:"+JSON.stringify(this.tableRecs.length));
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
        //console.log("ADD");
        await lightningAddMiscPartModalLWC.open({
            size: 'small',
            headerText:'Add Misc Items',
            woId:this.recordId,
            woCompanyCode:this.companyCode,
            woLaborCode:this.woLaborCode,
            woBillCustOrLOc:this.woBillCustOrLOc,
            branchLocationNumber:this.branchLocationNumber,
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
        console.log('Event data::'+ JSON.stringify(eventData));
        try{
            await lightningViewMiscPartsModalLWC.open({
                size: 'small',
                headerText:'View Misc Items',
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
            this.recordData=record.details;
        }
    }

    // Handles updation of records
    async handleEditClick(){
        await lightningEditMiscItemsModalLWC.open({
            size: 'small',
            headerText:'Edit Misc Items',
            record:this.recordData,
            quantityConsumedValue:this.recordData.quantityConsumedValue,
            laborCodeValue:this.recordData.laborCodeValue,
            woBillCustOrLOc:this.woBillCustOrLOc,
            productSfId:this.recordData.productId,
            oneditrow:(e)=>{
                let row=JSON.parse(JSON.stringify(e.detail.recs));
                let details= JSON.parse(JSON.stringify(e.detail.recDetail));
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
            }
        });
    }


    // Delete Multiple Recs
    deleteMultiRec(index,array){
        if(index==array.length){
            return;
        }else{
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