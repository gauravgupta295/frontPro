import LightningModal from "lightning/modal";
import { api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
// Product Fields
//import AVG_COST_PRICE from "@salesforce/schema/ProductItem.Product2.Average_Cost__c";
import LIST_PRICE from "@salesforce/schema/ProductItem.Product2.List_Price__c";
import SELL_PRICE from "@salesforce/schema/ProductItem.Product2.Sell_Price__c";
import UOM from "@salesforce/schema/ProductItem.Product2.QuantityUnitOfMeasure";
import STL_CLS from "@salesforce/schema/ProductItem.Product2.Stock_class__c";
import DES from "@salesforce/schema/ProductItem.Product2.Description__c";
import SKU from "@salesforce/schema/ProductItem.Product2.Product_SKU__c";
import ITEM_NUM from "@salesforce/schema/ProductItem.Product2.SM_PS_Item_number__c";
import ITEM_TYPE from "@salesforce/schema/ProductItem.Product2.Item_Type__c";
import PRODUCT_TYPE from "@salesforce/schema/ProductItem.Product2.Product_Type__c";
// Product item fields
//CR
import AVG_COST_PRICE from '@salesforce/schema/ProductItem.SM_PS_Average_Cost__c';
import QUANTITY_AVAILABLE from "@salesforce/schema/ProductItem.SM_PS_Quantity_Available__c";
import ITEM_NUMBER from "@salesforce/schema/ProductItem.SM_PS_Item_Number__c";
import STOCK_CLASS from "@salesforce/schema/ProductItem.SM_PS_Stock_Class__c";
import DESCRIPTION from "@salesforce/schema/ProductItem.SM_PS_Description__c";
import BIN_LOC from "@salesforce/schema/ProductItem.SM_PS_Bin_Location_1__c";
import QTY_ON_HAND from "@salesforce/schema/ProductItem.QuantityOnHand";
import PROD_NAME from "@salesforce/schema/ProductItem.Product2.Name";
//Product consumed field
import PC_PROD_ITEM_CUSTOM from "@salesforce/schema/ProductConsumed.SF_PS_Product_Item__c";
import PC_PRD_DES from "@salesforce/schema/ProductConsumed.SF_PS_Description__c";
import PC_PRD_SKU from "@salesforce/schema/ProductConsumed.SF_PS_Product_SKU__c";
//import PC_STK_CLS from '@salesforce/schema/ProductConsumed.SF_PS_Stock_Class__c';
import PC_QUANTITY_CUSTOM from "@salesforce/schema/ProductConsumed.SF_PS_Quantity__c";
import PC_PRICEBOOKENTRY_ID from "@salesforce/schema/ProductConsumed.PricebookEntryId";
import PC_ITEM_TYPE from "@salesforce/schema/ProductConsumed.SF_PS_ItemType__c";
import PC_QUANTITY_CONSUMED from "@salesforce/schema/ProductConsumed.QuantityConsumed";
import PC_LABOR_CODE from "@salesforce/schema/ProductConsumed.SF_PS_Labor_Code__c";
import PC_PI_ID from "@salesforce/schema/ProductConsumed.ProductItemId";
import PC_AVG_COST from "@salesforce/schema/ProductConsumed.SF_PS_Cost_Price__c";
import PC_SELL_PRICE from "@salesforce/schema/ProductConsumed.SF_PS_Selling_Price__c";
import PC_LIST_PRICE from "@salesforce/schema/ProductConsumed.SF_PS_List_Price__c";
import PC_UOM from "@salesforce/schema/ProductConsumed.SF_PS_Unit_Of_Measure__c";
import PC_WOID from "@salesforce/schema/ProductConsumed.WorkOrderId";
import PC_OBJECT from "@salesforce/schema/ProductConsumed";
import { createRecord } from "lightning/uiRecordApi";
// New Chnages - Pricebook
import getPricebookentriesFrmProd from "@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getPricebookEntriesForProd";
import getProductItemDetails from "@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails";
export default class Sbr_sfsAddPartsCmp extends LightningModal {
  @api headerText;
  @api woId;
  @api additionalQuery;
  @api woCompanyCode;
  @api woLaborCode;
  productItemSfId;
  pcLaborCodes;
  isProductItemSelected = false;
  itemNum;
  stockClass;
  binLoc;
  avgCost;
  productType;
  // For UI/UX Feedback
  avgCostDisplay;
  sellPrice;
  sku;
  // For UI/UX Feedback
  sellPriceDisplay;
  listPrice;
  // For UI/UX Feedback
  listPriceDisplay;
  productName;
  uom;
  uomValue;
  desc;
  qtyOnHand;
  laborCodeValue;
  branchLocationNumber;
  companyCode;
  quantityConsumedValue;
  errorProductItemId = false;
  recsTobeAddedParts = [];
  isSpinner = false;
  isErrorQuantityOnHand = false;
  //New Changes -Pricebook
  errorProductPriceBook = false;
  pricebookEntryId;
  //New changes - Pricebook
  itemType;

  // To get WOLI Object metadata
  @wire(getObjectInfo, { objectApiName: PC_OBJECT })
  pcInfo;

  // Pickilist work order description
  @wire(getPicklistValues, {
    recordTypeId: "$pcInfo.data.defaultRecordTypeId",
    fieldApiName: "ProductConsumed.SF_PS_Labor_Code__c"
  })
  WorkOrderDescValues({ error, data }) {
    //console.log(data);
    if (data) {
      this.pcLaborCodes = data.values;
    } else {
      console.log(JSON.stringify(error));
    }
  }

  /* moved into separate apex imperative call method
  @wire(getRecord, {
    recordId: "$productItemSfId",
    fields: [
      AVG_COST_PRICE,
      LIST_PRICE,
      SELL_PRICE,
      ITEM_NUMBER,
      STOCK_CLASS,
      DESCRIPTION,
      UOM,
      BIN_LOC,
      QTY_ON_HAND,
      PROD_NAME,
      QUANTITY_AVAILABLE,
      STL_CLS,
      DES,
      SKU,
      ITEM_NUM,
      ITEM_TYPE,
      PRODUCT_TYPE
    ]
  })
  productItemData(result) {
    if (result.data) {
      // console.log('here is product=Item data')
      // console.log(result.data);
      console.log("PI DATA:" + JSON.stringify(result.data));
      //this.itemNum=result.data.fields.SM_PS_Item_Number__c.value;
      //this.stockClass=result.data.fields.SM_PS_Stock_Class__c.value;
      this.binLoc = result.data.fields.SM_PS_Bin_Location_1__c.value;
      //this.desc=result.data.fields.SM_PS_Description__c.value;
      this.qtyOnHand = result.data.fields.QuantityOnHand.value;
      this.qtyAvail = result.data.fields.SM_PS_Quantity_Available__c.value;
      // CR retro fit:
      this.avgCost =result.data.fields.SM_PS_Average_Cost__c.value;;
      this.sellPrice =
        result.data.fields.Product2.value.fields.Sell_Price__c.value;
      this.listPrice =
        result.data.fields.Product2.value.fields.List_Price__c.value;
      // For UI/UX Feedback
      /*this.avgCostDisplay =
        "$" + result.data.fields.Product2.value.fields.Average_Cost__c.value;
      //this.sellPriceDisplay =
        "$" + result.data.fields.Product2.value.fields.Sell_Price__c.value;
      this.listPriceDisplay =
        "$" + result.data.fields.Product2.value.fields.List_Price__c.value;
        this.avgCostDisplay=result.data?.fields?.SM_PS_Average_Cost__c?.value?.toLocaleString('en-US', {
          style: 'currency',
          currency: 'USD',
          });
      this.sellPriceDisplay=result.data?.fields?.Product2?.value?.fields?.Sell_Price__c?.value?.toLocaleString('en-US', {
          style: 'currency',
          currency: 'USD',
          });
      this.listPriceDisplay=result.data?.fields?.Product2?.value?.fields?.List_Price__c?.value?.toLocaleString('en-US', {
          style: 'currency',
          currency: 'USD',
          });
        this.uom =
        result.data.fields.Product2.value.fields.QuantityUnitOfMeasure.displayValue;
      this.productName = result.data.fields.Product2.value.fields.Name.value;
      this.stockClass =
        result.data.fields.Product2.value.fields.Stock_class__c.value;
      this.desc = result.data.fields.Product2.value.fields.Description__c.value;
      this.sku = result.data.fields.Product2.value.fields.Product_SKU__c.value;
      this.itemNum =
        result.data.fields.Product2.value.fields.SM_PS_Item_number__c.value;
      this.itemType =
        result.data.fields.Product2.value.fields.Item_Type__c.value;
      this.productType =
        result.data.fields.Product2.value.fields.Product_Type__c.value;
      // console.log("PRD ID:"+result.data.fields.Product2.value.id);
      // New changes - Pricebook
      getPricebookentriesFrmProd({
        prodId: result.data.fields.Product2.value.id
      })
        .then((result) => {
          console.log("PRICEBOOK ENTRYLIST" + JSON.stringify(result));
          let validPricebookEntry = this.handlePricebookEntrySelection(result);
          console.log("Valid Price Book Entry: " + validPricebookEntry);
          if (validPricebookEntry == null) {
            this.errorProductPriceBook = true;
            console.log("NULL");
          } else {
            this.errorProductPriceBook = false;
            this.pricebookEntryId = validPricebookEntry.Id;
            console.log("ELSE");
          }
        })
        .catch((error) => {
          console.log("PRICEBOOK ERROR" + JSON.stringify(error));
          this.errorProductPriceBook = true;
        });
    }

    if (result.error) {
      console.log("this is error " + JSON.stringify(result.error));
    }
  }*/

  // ConnectedCallback
  connectedCallback() {
    this.laborCodeValue = this.woLaborCode;
  }

  handleProductItemChange(event) {
    let productItemId = event.detail.selectedRecord.Id;
    this.productItemSfId = productItemId;
    this.errorProductPriceBook = false;
    console.log(productItemId);
    if (productItemId != undefined) {
      this.isProductItemSelected = true;
      this.fetchProductItemDetails(productItemId);
    } else {
      this.isProductItemSelected = false;
    }
  }

  handleLaborCodeChange(event) {
    this.laborCodeValue = event.detail.value;
    console.log(this.laborCodeValue);
  }

  handleQuantityChange(event) {
    this.quantityConsumedValue = event.detail.value;
  }

  // Handle to save records
  handleSave() {
    //    console.log("LABOR CODE: "+this.laborCodeValue);
    //    console.log("Work order Id: "+this.woId);
    //    console.log("Quantity: "+this.quantityConsumedValue);
    //    console.log("Product Item SF ID: "+this.productItemSfId);
    //    console.log("Item Number: "+this.itemNum);
    //console.log("Stock Class: "+this.stockClass);
    //console.log("Desc: "+this.desc);
    //console.log("PRD SKU: "+this.sku);
    //console.log("Item Number SMPS: "+this.itemNum);
    //    console.log("AVG Cost: "+this.avgCost);
    //    console.log("SP: "+this.sellPrice);
    //    console.log("LP: "+this.listPrice);
    //    console.log("UOM:"+this.uom);
    //    console.log("QTY ON HAND:"+this.qtyOnHand);
    let recsTobeAddedParts = {};
    let details = {};
    details.productItemId = this.productItemSfId;
    details.customProductItemId = this.productItemSfId;
    details.itemNumber = this.itemNum;
    details.averageCost = this.avgCost;
    details.listPrice = this.listPrice;
    details.sellPrice = this.sellPrice;
    details.uom = this.uom;
    details.stockClass = this.stockClass;
    details.desc = this.desc;
    details.binLoc = this.binLoc;
    details.Name = this.productName;
    details.quantityConsumedValue = this.quantityConsumedValue; // This is SF_PS_Quantity
    //details.OriginalquantityConsumed=this.quantityConsumedValue;
    details.laborCodeValue = this.laborCodeValue;
    details.itemType=this.productType;
    details.qtyAvail=this.qtyAvail;

    if (this.productItemSfId) {
      // New changes - Pricebook - removed QOH logic
      /*let qty = this.template.querySelector('.qty')
            this.isErrorQuantityOnHand=this.quantityConsumedValue>this.qtyOnHand?true:false;
            if(this.isErrorQuantityOnHand)
            {









            qty.setCustomValidity("Quantity consumed can't be greater than the product item quantity on hand.");
            }
            else{
            qty.setCustomValidity("");
            }
            let diff=this.qtyOnHand-this.quantityConsumedValue;
            details.quantityOnHand=diff;*/
    }
    // Validation for all inputs
    const isInputsCorrect = [
      ...this.template.querySelectorAll("lightning-input")
    ].reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);

    // Validating Labor code
    const isLaborCodeValid = [
      ...this.template.querySelectorAll("lightning-combobox")
    ].reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);

    //console.log('this is before error '+ this.productItemSfId);
    if (this.productItemSfId == undefined) {
      // console.log('this is error '+ this.productItemSfId);
      this.errorProductItemId = true;
    } else {
      // console.log('this is not error '+ this.productItemSfId);
      this.errorProductItemId = false;
    }

    //console.log('this is AFTER error '+ this.productItemSfId);

    if (
      isInputsCorrect == true &&
      this.errorProductItemId == false &&
      isLaborCodeValid == true &&
      this.isErrorQuantityOnHand == false &&
      this.errorProductPriceBook == false
    ) {
      console.log("SAVE");
      const fields = {};
      recsTobeAddedParts.columnOne =
        this.itemNum?.length > 13
          ? (this.itemNum + "").substring(0, 13) + ".."
          : this.itemNum;
      recsTobeAddedParts.columnTwo = this.stockClass;
      recsTobeAddedParts.columnThree =
        this.desc?.length > 20 ? this.desc.substring(0, 20) + ".." : this.desc;
      recsTobeAddedParts.ColumnFour = this.quantityConsumedValue; // This is SF_PS_Quantity
      // New Chnages - Pricebook
      fields[PC_QUANTITY_CUSTOM.fieldApiName] = this.quantityConsumedValue; // This is SF_PS_Quantity
      fields[PC_QUANTITY_CONSUMED.fieldApiName] = 1;
      fields[PC_LABOR_CODE.fieldApiName] = this.laborCodeValue;
      let prodType = String(this.productType);
      if (prodType.toLocaleLowerCase().includes("parts")) {
        fields[PC_ITEM_TYPE.fieldApiName] = "P";
      } else {
        fields[PC_ITEM_TYPE.fieldApiName] = "M";
      }

      fields[PC_PRICEBOOKENTRY_ID.fieldApiName] = this.pricebookEntryId;
      // fields[PC_STK_CLS.fieldApiName]= this.stockClass;
      fields[PC_PRD_DES.fieldApiName] = this.desc;
      fields[PC_PRD_SKU.fieldApiName] = this.sku;

      //fields[PC_PI_ID.fieldApiName] =this.productItemSfId;
      // CR
      fields[PC_PROD_ITEM_CUSTOM.fieldApiName] = this.productItemSfId;
      fields[PC_AVG_COST.fieldApiName] = Number(this.avgCost);
      fields[PC_SELL_PRICE.fieldApiName] = Number(this.sellPrice);
      fields[PC_LIST_PRICE.fieldApiName] = Number(this.listPrice);
      fields[PC_UOM.fieldApiName] = String(this.uom);
      fields[PC_WOID.fieldApiName] = this.woId;
      const recordInput = { apiName: PC_OBJECT.objectApiName, fields };
      console.log(recordInput);
      this.isSpinner = true;
      createRecord(recordInput)
        .then((result) => {
          (recsTobeAddedParts.Id = result.id),
            (details.productConsumedid = result.id);
          console.log(JSON.stringify(result));
          this.recsTobeAddedParts.push({
            Id: result.id,
            columnOne: this.itemNum?.length > 13 ? (this.itemNum + "").substring(0, 13) + ".." : this.itemNum,
            columnTwo: this.stockClass,
            columnThree: this.desc?.length > 20 ? this.desc.substring(0, 20) + ".." : this.desc,
            ColumnFour: this.quantityConsumedValue
          });

          // Created the event with the data.
          const selectedEvent = new CustomEvent("addrow", {
            detail: { recs: recsTobeAddedParts, recDetail: details }
          });
          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
          this.isSpinner = false;
          this.close("okay");
        })
        .catch((error) => {
          console.log("ERROR:" + JSON.stringify(error));
          this.isSpinner = false;
        });
    }
  }

  // New changes - Pricebook

  // To handle price book entry selection
  handlePricebookEntrySelection(priceBookentries) {
    for (let pb in priceBookentries) {
      console.log("Company code " + this.woCompanyCode);
      // Check any entry matching currency code
      if (
        this.woCompanyCode == "01" &&
        priceBookentries[pb].CurrencyIsoCode == "USD"
      ) {
        console.log("USA " + JSON.stringify(priceBookentries[pb]));
        return priceBookentries[pb];
      } else if (
        this.woCompanyCode == "02" &&
        priceBookentries[pb].CurrencyIsoCode == "CAD"
      ) {
        console.log("CAD " + JSON.stringify(priceBookentries[pb]));
        return priceBookentries[pb];
      }
    }
    return null;
  }

  //Get product Item fresh copy
  fetchProductItemDetails(RecId){
    getProductItemDetails({productItemId : RecId}).then(
        data => {
            let result = data.Item;
            console.log(data);
            if(result){
                //Mapping data 
                this.binLoc = result.SM_PS_Bin_Location_1__c;
                this.qtyOnHand = result.QuantityOnHand;
                this.qtyAvail = result.SM_PS_PartsMerch_Available_Quantity__c;
                //CR retro fit:
                //this.avgCost =result.SM_PS_Average_Cost__c;
                //CR retro fit:
                // CR SERV-13081
                // Check for not equal to undefined and zero
                if(result.SM_PS_Average_Cost__c && result.SM_PS_Average_Cost__c!=0){
                  this.avgCost =result.SM_PS_Average_Cost__c;
  
                }else{
                      
                      if(result.SM_PS_Last_Cost__c && result.SM_PS_Last_Cost__c!=0){
                        this.avgCost =result.SM_PS_Last_Cost__c;
                      }else{
                        this.avgCost=0;
                      }
                    
                }
                console.log("Final average cost after business logic: "+ this.avgCost);
                this.sellPrice = result.Product2.Sell_Price__c;
                this.listPrice = result.Product2.List_Price__c;
                this.avgCostDisplay=this.avgCost?.toLocaleString('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
                this.sellPriceDisplay=result.Product2?.Sell_Price__c?.toLocaleString('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
                this.listPriceDisplay=result.Product2?.List_Price__c?.toLocaleString('en-US', {
                    style: 'currency',
                    currency: 'USD',
                });
                this.uom = result.Product2?.QuantityUnitOfMeasure;
                this.productName = result.Product2?.Name;
                this.stockClass = result.Product2?.Stock_class__c;
                this.desc = result.Product2?.Description__c;
                this.sku = result.Product2?.Product_SKU__c;
                this.itemNum = result?.SM_PS_Item_Number__c;
                this.itemType = result.Product2?.Item_Type__c;
                this.productType = result.Product2?.Product_Type__c;
            }
            
            let pricebookEntries= data?.PricebookEntry;
            let validPricebookEntry = this.handlePricebookEntrySelection(pricebookEntries);
            console.log("Valid Price Book Entry: " + validPricebookEntry);
            if (validPricebookEntry == null) {
                this.errorProductPriceBook = true;
            } 
            else {
                this.errorProductPriceBook = false;
                this.pricebookEntryId = validPricebookEntry.Id;
            }
        }
    )
  } 
  
}