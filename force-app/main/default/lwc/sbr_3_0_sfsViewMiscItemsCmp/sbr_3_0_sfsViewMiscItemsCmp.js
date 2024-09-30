import { api,wire,track } from 'lwc';
import LightningModal from 'lightning/modal';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import PC_LABOR_CODE from '@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c';

export default class Sbr_3_0_sfsViewMiscItemsCmp extends LightningModal {
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
            this.finalformattedData["column6"] = this.pcLaborCodes[this.selectedRecord.laborCodeValue];
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
            "column5" : "Part Name:",
            "column6" : "labor Code:",
            "column7" : "Shipped Quantity:",
            "column8" : "Backorder Quantity:",
            "column9" : "Original Backordered Quantity:",
            "column10" : "Item Type:",
            "column11" : "Avg. Cost:",
            "column12" : "Sell Price:",
            "column13" : "List Price:",
            "column14" : "UOM:"
        };
        this.finalformattedData={
            "column1" : recievedData?.itemNumber,
            "column2" : recievedData?.stockClass,
            "column3" : recievedData?.desc,
            "column4" : recievedData?.quantityConsumedValue,
            "column5" : recievedData?.Name,
            "column6" : recievedData?.laborCodeDisplayValue,
            "column7" : recievedData?.shippedQty ? recievedData.shippedQty : '-',
            "column8" : recievedData?.backOrderedQty ? recievedData.backOrderedQty : '-',
            "column9" : recievedData?.originalBackorderQty? recievedData.originalBackorderQty : '-',
            "column10" : recievedData?.itemType,
            "column11" : recievedData?.averageCost ? ((typeof recievedData.averageCost =='string') ? (recievedData.averageCost).replace('USD ','$') : '$'+((recievedData.averageCost).toFixed(2))) : '$0.00',
            "column12" : recievedData?.sellPrice ? ((typeof recievedData.sellPrice =='string') ? (recievedData.sellPrice).replace('USD ','$') : '$'+((recievedData.averageCost).toFixed(2))) : '$0.00',
            "column13" : recievedData?.listPrice ? ((typeof recievedData.listPrice =='string') ? (recievedData.listPrice).replace('USD ','$') : '$'+((recievedData.listPrice).toFixed(2))) : '$0.00',
            "column14" : recievedData?.uom
        }        
    }
}