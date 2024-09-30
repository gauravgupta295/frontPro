import LightningModal from 'lightning/modal';
import {api,wire } from 'lwc';
import {updateRecord,getRecord} from "lightning/uiRecordApi";
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import QTY_ON_HAND from'@salesforce/schema/ProductItem.QuantityOnHand';
import QTY_Available from'@salesforce/schema/ProductItem.SM_PS_Quantity_Available__c';
import PC_QUANTITY_CONSUMED from '@salesforce/schema/ProductConsumed.QuantityConsumed';
import PC_LABOR_CODE from '@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c';
import PC_SELL_PRICE from '@salesforce/schema/ProductConsumed.SF_PS_Selling_Price__c';
import PC_ID from '@salesforce/schema/ProductConsumed.Id';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import PC_QUANTITY_CUSTOM from '@salesforce/schema/ProductConsumed.SF_PS_Quantity__c';

export default class Sbr_3_0_sfsEditMiscItemsCmp extends LightningModal  {

@api productSfId;
@api headerText; 
@api record={}
@api quantityConsumedValue
@api laborCodeValue
@api woBillCustOrLOc;
disableSellingPrice=false;
// For UI/UX Feedback
averageCostDisplay;
sellPriceDisplay;
sellPriceValue;
listPriceDisplay;
isProductSelected=true;
pcLaborCodes;
isSpinner=false;
itemType;


// To get WOLI Object metadata 
@wire(getObjectInfo, { objectApiName: PC_OBJECT })
pcInfo;

// Pickilist work order description 
@wire(getPicklistValues,{
    recordTypeId: '$pcInfo.data.defaultRecordTypeId',
    fieldApiName: 'ProductConsumed.SF_PS_Labor_Code__c'
})WorkOrderDescValues({error,data}){
        //console.log(data);
        if(data){
            this.pcLaborCodes=data.values;

        }else{
            console.log(JSON.stringify(error));
        }
}

// Connected call back
connectedCallback(){
    console.log("EDIT PARTS:"+JSON.stringify(this.record));
    this.averageCostDisplay=this.record?.averageCost?.toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
    });
    if(this.averageCostDisplay?.includes('USD'))
    {
    this.averageCostDisplay=String(this.record.averageCost).replace('USD ','$');
    }
    this.sellPriceDisplay=this.record?.sellPrice?.toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
    });
    if(this.sellPriceDisplay?.includes('USD'))
    {
    this.sellPriceDisplay=String(this.record.sellPrice).replace('USD ','$');
    }
    this.sellPriceValue = this.record?.newSellingPrice;
    this.listPriceDisplay=this.record?.listPrice?.toLocaleString('en-US', {
    style: 'currency',
    currency: 'USD',
    });
    if(this.listPriceDisplay?.includes('USD'))
    {
    this.listPriceDisplay=String(this.record?.listPrice).replace('USD ','$');
    }
    this.itemType=this.record?.itemType;
    if(this.woBillCustOrLOc == 'L'){
        this.disableSellingPrice = true;
    }
    // this.averageCostDisplay='$'+Number(this.record.averageCost).toFixed(2);
    //this.sellPriceDisplay='$'+Number(this.record.sellPrice).toFixed(2);

    // this.listPriceDisplay='$'+Number(this.record.listPrice).toFixed(2);
}

//Handle Quantity Chnage
handleQuantityChange(event){
   
    this.quantityConsumedValue=event.target.value;
    console.log(this.quantityConsumedValue);
 }

//Handle Labor code changes Chnage
handleLaborCodeChange(event){
    
    this.laborCodeValue=event.target.value;
    console.log(this.laborCodeValue);

}

handleSellingPriceChange(event){
    this.sellPriceDisplay=event.detail.value; 
    this.sellPriceValue =event.detail.value; 
}

// Handle to save records
handleSave(){
    console.log("Save: "+JSON.stringify(this.record));

     let recsToBeEdited={}
     recsToBeEdited.Id=this.record.productConsumedid;
     recsToBeEdited.columnOne=this.record.itemNumber?.length>13?(((this.record.itemNumber+'').substring(0,13))+'..'):this.record.itemNumber;;
     recsToBeEdited.columnTwo=this.record.stockClass;
     recsToBeEdited.columnThree=this.record.desc?.length>20?((this.record.desc.substring(0,20))+'..'):this.record.desc;
     recsToBeEdited.ColumnFour=this.quantityConsumedValue;
     let rec= JSON.parse(JSON.stringify(this.record));
     rec.laborCodeValue=this.laborCodeValue;
     rec.quantityConsumedValue=this.quantityConsumedValue;
     
     // Validating Quantity here
     const isInputsCorrect = [...this.template.querySelectorAll('lightning-input'),...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
    }, true);


    if(isInputsCorrect){

            console.log("SAVE");
            const fields = {};
            fields[PC_QUANTITY_CUSTOM.fieldApiName]=this.quantityConsumedValue;
            fields[PC_LABOR_CODE.fieldApiName]=this.laborCodeValue;  
            fields[PC_ID.fieldApiName] =this.record.productConsumedid;
            fields[PC_SELL_PRICE.fieldApiName] =this.sellPriceValue;
            const recordInput = { fields };
            console.log("Rec to be Edited:"+JSON.stringify(recordInput));
            this.isSpinner=true;
            updateRecord(recordInput).then(result=>{
                console.log("Success EDIT: "+ JSON.stringify(result));
                const selectedEvent = new CustomEvent("editrow",{
                    detail: {'recs':recsToBeEdited,"recDetail":rec}
                    });
                    this.dispatchEvent(selectedEvent);

                    // Closes the popup/Modal
                    this.isSpinner=false;
                    this.close('okay');
            }).catch(error => {
                console.log("Erorr EDIT: "+ JSON.stringify(error));
            })

    }

}

}