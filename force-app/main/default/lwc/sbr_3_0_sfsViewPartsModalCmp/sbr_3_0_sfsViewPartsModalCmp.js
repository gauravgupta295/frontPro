import { api,wire,track } from 'lwc';
import LightningModal from 'lightning/modal';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import PC_LABOR_CODE from '@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c';

export default class Sbr_3_0_sfsViewPartsModalCmp  extends LightningModal {
    @api selectedRecord;
    @api headerText;
   
    @track finalformattedData={};
    @track finalFieldLabels={};
    @track pcLaborCodes={};
    
    // To get WOLI Object metadata 
    @wire(getObjectInfo, { objectApiName: PC_OBJECT })
    pcInfo;
    
    // Pickilist work order description 
    @wire(getPicklistValues,{
        recordTypeId: '$pcInfo.data.defaultRecordTypeId',
        fieldApiName: PC_LABOR_CODE
    })WorkOrderDescValues({error,data}){
        //console.log(data);
        if(data){
            for(let rec of data.values){
                this.pcLaborCodes[rec.value]=rec.label;
            }
            console.log('labor code received::'+ JSON.stringify(this.pcLaborCodes));
            this.finalformattedData["column8"] = this.pcLaborCodes[this.selectedRecord.laborCodeValue];
        }else{
            console.log(JSON.stringify(error));
        }
    }
    
    connectedCallback(){
        let recievedData=this.selectedRecord;
        console.log('RecievedData in view modal::'+JSON.stringify(recievedData));
        this.finalFieldLabels={
            "column1" : "Item#:",
            "column2" : "STK/C:",
            "column3" : "Description:",
            "column4" : "Quantity:",
            "column5" : "BIN Loc:",
            "column6" : "Part Name:",
            "column7" : "Quantity Available:",
            "column8" : "labor Code:",
            "column9" : "Shipped Quantity:",
            "column10" : "Backorder Quantity:",
            "column11" : "Original Backordered Quantity:",
            "column12" : "Item Type:",
            "column13" : "Avg. Cost:",
            "column14" : "Sell Price:",
            "column15" : "List Price:",
            "column16" : "UOM:"
        };

        this.finalformattedData={
            "column1" : recievedData?.itemNumber,
            "column2" : recievedData?.stockClass,
            "column3" : recievedData?.desc,
            "column4" : recievedData?.quantityConsumedValue,
            "column5" : recievedData?.binLoc,
            "column6" : recievedData?.Name,
            "column7" : recievedData?.qtyAvail,
            "column8" : recievedData?.laborCodeDisplayValue,
            "column9" : recievedData?.shippedQty ? recievedData.shippedQty : '-',
            "column10" : recievedData?.backOrderedQty ? recievedData.backOrderedQty : '-',
            "column11" : recievedData?.originalBackorderQty? recievedData.originalBackorderQty : '-',
            "column12" : recievedData?.itemType,
            "column13" : recievedData?.averageCost ? ((typeof recievedData.averageCost =='string') ? (recievedData.averageCost).replace('USD ','$') : '$'+((recievedData.averageCost).toFixed(2))) : '$0.00',
            "column14" : recievedData?.sellPrice ? ((typeof recievedData.sellPrice =='string') ? (recievedData.sellPrice).replace('USD ','$') : '$'+((recievedData.sellPrice).toFixed(2))) : '$0.00',
            "column15" : recievedData?.listPrice ? ((typeof recievedData.listPrice =='string') ? (recievedData.listPrice).replace('USD ','$') : '$'+((recievedData.listPrice).toFixed(2))) : '$0.00',
            "column16" : recievedData?.uom
        }
    }
}