import {api,wire } from 'lwc';
import {updateRecord,getRecord} from "lightning/uiRecordApi";
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import LightningModal from 'lightning/modal';
import QTY_ON_HAND from'@salesforce/schema/ProductItem.QuantityOnHand';
import QTY_Available from'@salesforce/schema/ProductItem.SM_PS_PartsMerch_Available_Quantity__c';
import PC_QUANTITY_CONSUMED from '@salesforce/schema/ProductConsumed.QuantityConsumed';
import BIN_LOC from '@salesforce/schema/ProductItem.SM_PS_Bin_Location_1__c';
import PC_LABOR_CODE from '@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c';
import PC_ID from '@salesforce/schema/ProductConsumed.Id';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import PC_QUANTITY_CUSTOM from '@salesforce/schema/ProductConsumed.SF_PS_Quantity__c';


export default class Sbr_3_0_sfsEditPartsCmp extends LightningModal {
    @api
    productItemSfId;
    @api headerText; 
    isSpinner=false;
    @api record={}
    @api quantityConsumedValue
    @api laborCodeValue
    qtyOnHand;
    qtyAvailable;
    // For UI/UX Feedback
    averageCostDisplay;
    sellPriceDisplay;
    listPriceDisplay;
    isProductItemSelected=true;
    pcLaborCodes
    shippedQty;
    backQty;
    originalBackQty;
    binLoc;
    itemType;
    connectedCallback() {
       // For UI/UX Feedback
        console.log("EDIT PARTS:"+JSON.stringify(this.record));
    // this.averageCostDisplay=String(this.record.averageCost).replace('USD ','$');
      //this.averageCostDisplay=this.record.averageCost;
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
      this.listPriceDisplay=this.record?.listPrice?.toLocaleString('en-US', {
        style: 'currency',
        currency: 'USD',
      });
      if(this.listPriceDisplay?.includes('USD'))
      {
       this.listPriceDisplay=String(this.record.listPrice).replace('USD ','$');
      }
      // this.sellPriceDisplay=String(this.record.sellPrice).replace('USD ','$');
      // this.listPriceDisplay=String(this.record.listPrice).replace('USD ','$');
       console.log('average price'+this.averageCostDisplay);
       console.log("originalBackorderQty: "+this.record.originalBackorderQty);
       console.log("shippedQty: "+this.record.shippedQty);
       console.log("backOrderedQty: "+this.record.backOrderedQty);
       this.shippedQty=this.record.shippedQty ? this.record.shippedQty : '-' ;
       this.backQty=this.record.backOrderedQty ? this.record.backOrderedQty : '-' ;
       this.originalBackQty=this.record.originalBackorderQty ? this.record.originalBackorderQty : '-' ;
        console.log(this.productItemSfId);
        this.itemType=this.record?.itemType;
      
       
    }


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
    @wire(getRecord,{recordId:'$productItemSfId',fields:[QTY_ON_HAND,QTY_Available,BIN_LOC]})
    productItemData(result)
    {
        if(result.data)
        {
            //console.log('this is data f5orm wire');
            console.log("PI Form EDIT:"+JSON.stringify(result.data))
            this.qtyOnHand=result.data?.fields?.QuantityOnHand.value;
            this.qtyAvailable=result.data?.fields?.SM_PS_PartsMerch_Available_Quantity__c.value;
            this.binLoc=result.data?.fields?.SM_PS_Bin_Location_1__c.value;
           // console.log("BIN LOC VALUE"+this.binLoc);
          //  console.log("qtyAvailable value"+this.qtyAvailable);
        }
        if(result.error)
        {
            console.log('this is error '+JSON.stringify(result.error));
        }
    }
    

    handleLaborCodeChange(event){
        //console.log(event.target.value);
        this.laborCodeValue=event.target.value;
        //console.log(this.record.laborCodeValue);

    }

    handleQuantityChange(event){
        //console.log(event.target.value);
       this.quantityConsumedValue=event.target.value;
       //console.log(this.record.quantityConsumedValue);
    }
    // Handle to save records
    handleSave(){
       //console.log(this.record)

        let recsToBeEdited={}
        recsToBeEdited.Id=this.record.productConsumedid;
        recsToBeEdited.columnOne=this.record.itemNumber?.length>13?(((this.record.itemNumber+'').substring(0,13))+'..'):this.record.itemNumber;;
        recsToBeEdited.columnTwo=this.record.stockClass;
        recsToBeEdited.columnThree=this.record.desc?.length>20?((this.record.desc.substring(0,20))+'..'):this.record.desc;
        recsToBeEdited.ColumnFour=this.quantityConsumedValue;
        let rec= JSON.parse(JSON.stringify(this.record));
        rec.laborCodeValue=this.laborCodeValue;
        rec.quantityConsumedValue=this.quantityConsumedValue;

        let qty = this.template.querySelector('.qty');
        //console.log('this.record.quantityConsumedValue-t '+this.quantityConsumedValue+" --his.record.OriginalquantityConsumed " +this.record.OriginalquantityConsumed)
        let diff= this.quantityConsumedValue-this.record.OriginalquantityConsumed
        //console.log('diff b/w orginal and eneterd '+diff);
        let diffVal=this.qtyOnHand-diff;
        //onsole.log('diff val b/w qoh and diff '+diffVal);
        // this.isErrorQuantityOnHand=diffVal<0?true:false;
        /*if(this.isErrorQuantityOnHand)
        {
        
         qty.setCustomValidity("Quantity consumed can't be greater than the product item quantity on hand.");
        }
        else{
         qty.setCustomValidity("");
        }*/
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input'),...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        rec.quantityOnHand=diffVal;
        rec.OriginalquantityConsumed=this.quantityConsumedValue;
        //recsToBeEdited.detail={details:rec};
        if(/*this.isErrorQuantityOnHand==false &&*/ isInputsCorrect)
        {
            //console.log("SAVE");
            const fields = {};
            fields[PC_QUANTITY_CUSTOM.fieldApiName]=this.quantityConsumedValue;
            //fields[PC_QUANTITY_CONSUMED.fieldApiName]=this.quantityConsumedValue;
            fields[PC_LABOR_CODE.fieldApiName]=this.laborCodeValue;  
            fields[PC_ID.fieldApiName] =this.record.productConsumedid;
            const recordInput = { fields };
            //console.log(JSON.stringify(recordInput));
            this.isSpinner=true;
            updateRecord(recordInput).then(result=>{
                //console.log("Success EDIT: "+ JSON.stringify(result));
                const selectedEvent = new CustomEvent("editrow",{
                    detail: {'recs':recsToBeEdited,"recDetail":rec}
                    });
                    this.dispatchEvent(selectedEvent);

                    // Closes the popup/Modal
                    this.isSpinner=false;
                    this.close('okay');
            }).catch(error => {
                console.log("Erorr EDIT: "+ JSON.stringify(error));
                this.isAccessError=true;
            })
            
            



        }

        


    }


    


}