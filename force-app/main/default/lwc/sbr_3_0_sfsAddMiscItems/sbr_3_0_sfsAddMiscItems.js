import { LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
import {api,wire } from 'lwc';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getRecord} from "lightning/uiRecordApi";
//Product consumed field
import PC_PRD_DES from '@salesforce/schema/ProductConsumed.SF_PS_Description__c'
import PC_PRD_SKU from '@salesforce/schema/ProductConsumed.SF_PS_Product_SKU__c';
//import PC_STK_CLS from '@salesforce/schema/ProductConsumed.SF_PS_Stock_Class__c';
import PC_QUANTITY_CUSTOM from '@salesforce/schema/ProductConsumed.SF_PS_Quantity__c';
import PC_PRICEBOOKENTRY_ID from '@salesforce/schema/ProductConsumed.PricebookEntryId';
import PC_ITEM_TYPE from '@salesforce/schema/ProductConsumed.SF_PS_ItemType__c';
import PC_QUANTITY_CONSUMED from '@salesforce/schema/ProductConsumed.QuantityConsumed';
import PC_LABOR_CODE from '@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c';
//import PC_PI_ID from '@salesforce/schema/ProductConsumed.ProductItemId';
import PC_PROD_ITEM_CUSTOM from "@salesforce/schema/ProductConsumed.SF_PS_Product_Item__c";
import PC_AVG_COST from '@salesforce/schema/ProductConsumed.SF_PS_Cost_Price__c';
import PC_SELL_PRICE from '@salesforce/schema/ProductConsumed.SF_PS_Selling_Price__c';
import PC_LIST_PRICE from '@salesforce/schema/ProductConsumed.SF_PS_List_Price__c';
import PC_UOM from '@salesforce/schema/ProductConsumed.SF_PS_Unit_Of_Measure__c';
import PC_WOID from '@salesforce/schema/ProductConsumed.WorkOrderId';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import { createRecord } from 'lightning/uiRecordApi';
import getProductDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductDetails';


export default class Sbr_3_0_sfsAddMiscItems extends LightningModal {

@api headerText;
@api woId;
@api woCompanyCode;
@api woLaborCode;
@api woBillCustOrLOc;
@api branchLocationNumber;
disableSellingPrice=false;
productSfId;
productItemId;
itemNum;
stockClass;
desc;
avgCostDisplay;
sellPriceDisplay;
listPriceDisplay;
uom;
productType;
laborCodeValue;
quantityConsumedValue;
pcLaborCodes;
pricebookEntryId;
isProductSelected=false;
isErrorPriceBookEntry=false;
isErrorProductId=false;
isSpinner=false;
Name;
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
            console.log(data.values);
            this.pcLaborCodes=data.values;

        }else{
            console.log(JSON.stringify(error));
        }
}

// ConnectedCallback
connectedCallback(){
    this.laborCodeValue=this.woLaborCode;
    if(this.woBillCustOrLOc == 'L'){
        this.disableSellingPrice = true;
        this.sellPriceDisplay=0;
    }
}

// Handele parts# chnage
handleProductChange(event){
    let productId= event.detail.selectedRecord.Id;
    this.productSfId= productId;
    this.isErrorPriceBookEntry=false;
    this.isErrorProductId=false;
    // See other fields
    if(productId!=undefined){
        this.isProductSelected=true;
    }else{
        this.isProductSelected=false;
    }

    // Fail safe server call to get product details
    if(productId!=undefined){
        if(productId){

            getProductDetails({prodId:productId}).then(data=>{
                console.log("Product Data:"+ JSON.stringify(data));
                let result=data.Item;
                this.productType=result.Product_Type__c;
                this.itemNum=result.SM_PS_Item_number__c;
                this.stockClass=result.Stock_class__c;
                this.desc=result.Description__c;
                this.avgCostDisplay='$'+Number(result.Average_Cost__c).toFixed(2);
                this.sellPriceDisplay='$'+Number(result.Sell_Price__c).toFixed(2);
                this.listPriceDisplay='$'+Number(result?.List_Price__c).toFixed(2);
                this.avgCost=result.Average_Cost__c;
                this.Name=result.Name;
                if(data.Item.ProductItems && data.Item.ProductItems.length){
                    let productItemRec=this.getProductItem(data.Item.ProductItems);
                    this.productItemId=productItemRec?.Id;
                    
                    this.avgCost=productItemRec?.SM_PS_Last_Cost__c>0 ? productItemRec.SM_PS_Last_Cost__c : (this.avgCost > 0 ? this.avgCost : 0);
                    this.avgCostDisplay='$'+Number(this.avgCost).toFixed(2);
                }
                this.uom=result.QuantityUnitOfMeasure;
                
                this.sellPrice=result.Sell_Price__c;
                this.listPrice=result.List_Price__c;
                
                //Story - SERV-18796
                if(this.woBillCustOrLOc == 'L'){
                    this.sellPrice=0;
                }
                let pricebookEntries=data.PricebookEntry;
                let pricebook=this.handlePricebookEntrySelection(pricebookEntries);
                console.log('this is pricebook '+pricebook);
                console.log(pricebook);
                if(pricebook && pricebook.Id ){
                    this.pricebookEntryId=pricebook?.Id;
                    this.isErrorPriceBookEntry=false;
                }
                else{
                    this.isErrorPriceBookEntry=true;
                }
               
            });
        }
    }

   

}


// To handle quantity change
handleQuantityChange(event){
    this.quantityConsumedValue=event.detail.value;
    console.log("LC:"+this.quantityConsumedValue);

}

handleSellingPriceChange(event){
    this.sellPriceDisplay=event.detail.value; 
    this.sellPrice=event.detail.value; 
}

//Get ProductItem based on location for misc item
getProductItem(productItems){
    let productItemRec=productItems.filter(item=>{
        return (item.Location.Branch_Location_Number__c==this.branchLocationNumber && item.Location.Company_Code__c==this.woCompanyCode);
            
        
    })
    return productItemRec;

}

// To handle quantity change
handleLaborCodeChange(event){
   
    this.laborCodeValue=event.detail.value;
    console.log("QC:"+this.laborCodeValue);
}


// New changes - Pricebook 
// To handle price book entry selection
handlePricebookEntrySelection(priceBookentries){
        
    for(let pb in priceBookentries){
        console.log("Company code "+this.woCompanyCode);
        // Check any entry matching currency code
        if(this.woCompanyCode=='01' && priceBookentries[pb].CurrencyIsoCode=="USD"){
         console.log("USA "+JSON.stringify(priceBookentries[pb]));
         return priceBookentries[pb];
        }else if(this.woCompanyCode=='02' && priceBookentries[pb].CurrencyIsoCode=="CAD"){
         console.log("CAD "+JSON.stringify(priceBookentries[pb]));
         return priceBookentries[pb];
        }    
    }
    return null; 
 
}

// Handle Save of PC type MISC
handleSave(){
    console.log("PRD SF ID:"+this.productSfId);
    console.log("LABOR CODE: "+this.laborCodeValue);
    console.log("Work order Id: "+this.woId);
    console.log("Quantity: "+this.quantityConsumedValue);
    console.log("Item Number: "+this.itemNum);
    console.log("Stock Class: "+this.stockClass);
    console.log("Desc: "+this.desc);
    console.log("PRD SKU: "+this.sku);
    console.log("Item Number SMPS: "+this.itemNum);
    console.log("AVG Cost: "+this.avgCost);
    console.log("SP: "+this.sellPrice);
    console.log("LP: "+this.listPrice);
    console.log("UOM:"+this.uom);
    console.log("PR TYPE:" +this.productType);

    let recsTobeAddedPartsTable={}; 
    let details= {}

    details.productId=this.productSfId;
    details.itemNumber=this.itemNum;         
    details.averageCost=this.avgCost;
    details.listPrice=this.listPrice;
    details.sellPrice=this.sellPrice;
    details.uom=this.uom;
    details.stockClass=this.stockClass;
    details.desc=this.desc;      
    details.quantityConsumedValue=this.quantityConsumedValue;
    details.laborCodeValue=this.laborCodeValue;
    details.itemType=this.productType;
    details.Name= this.Name;

    // Validation for Qty
    const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
    .reduce((validSoFar, inputField) => {
        inputField.reportValidity();
        return validSoFar && inputField.checkValidity();
    }, true);

    // Validating Labor code
    const isLaborCodeValid=[...this.template.querySelectorAll('lightning-combobox')]
    .reduce((validSoFar, inputField) => {
    inputField.reportValidity();
    return validSoFar && inputField.checkValidity();
   }, true);

   // Product Id not populated Error
   if(this.productSfId==undefined){
     this.isErrorProductId=true;
    }else{
  
     this.isErrorProductId=false;
    }

    if(isInputsCorrect==true &&  this.isErrorProductId==false && isLaborCodeValid==true && this.isErrorPriceBookEntry==false){
        console.log("Validation are good");

        const fields = {};
        recsTobeAddedPartsTable.columnOne=this.itemNum?.length>13?(((this.itemNum+'').substring(0,13))+'..'):this.itemNum;
        recsTobeAddedPartsTable.columnTwo=this.stockClass;
        recsTobeAddedPartsTable.columnThree=this.desc?.length>20?((this.desc.substring(0,20))+'..'):this.desc;
        recsTobeAddedPartsTable.ColumnFour=this.quantityConsumedValue;// This is SF_PS_Quantity

        fields[PC_QUANTITY_CUSTOM.fieldApiName]=this.quantityConsumedValue; // This is SF_PS_Quantity
        fields[PC_QUANTITY_CONSUMED.fieldApiName]=1;
        fields[PC_LABOR_CODE.fieldApiName]=this.laborCodeValue;
        fields[PC_ITEM_TYPE.fieldApiName]="MI";
        fields[PC_PRICEBOOKENTRY_ID.fieldApiName]= this.pricebookEntryId;
        fields[PC_PRD_DES.fieldApiName]=this.desc;
        fields[PC_AVG_COST.fieldApiName] = Number(this.avgCost);
        fields[PC_SELL_PRICE.fieldApiName]= Number(this.sellPrice);
        fields[PC_LIST_PRICE.fieldApiName] = Number(this.listPrice);
        fields[PC_UOM.fieldApiName] = String(this.uom);
        fields[PC_WOID.fieldApiName]=this.woId;
        fields[PC_PROD_ITEM_CUSTOM.fieldApiName] = this.productItemId;
        const recordInput = {apiName:PC_OBJECT.objectApiName,fields};
        console.log("RECORD TO SAVE:"+JSON.stringify(recordInput));
        this.isSpinner=true;
        // Save record here
        createRecord(recordInput)
        .then(result => {
            recsTobeAddedPartsTable.Id=result.id;
            details.productConsumedid=result.id;
            console.log("REC CRET"+JSON.stringify(result));
        
           // Created the event with the data.
            const selectedEvent = new CustomEvent("addrow", {
                detail: {'recs': recsTobeAddedPartsTable, "recDetail":details}
            });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
            this.isSpinner=false;
            this.close('okay');
            
       }).catch(error=>{
        console.log("ERROR:"+JSON.stringify(error));
        this.isSpinner=false;
       });
        
    }

}

}