/* eslint-disable @lwc/lwc/no-leading-uppercase-api-name */
import { LightningElement,api,track,wire } from 'lwc';
import COMPANY_CODE from '@salesforce/schema/WorkOrder.SF_PS_Company_Code__c';
import BRANCH_LOCATION_NUMBER from '@salesforce/schema/WorkOrder.ServiceTerritory.Branch_Location_Number__c';
import WO_DESC from '@salesforce/schema/WorkOrder.SF_PS_Work_Order_Des__c';
import WO_BILCUST from '@salesforce/schema/WorkOrder.SF_PS_BillCustOrLoc__c';
import WO_STATUS from '@salesforce/schema/WorkOrder.Status';
import WO_LABOR_CODE from '@salesforce/schema/WorkOrder.SF_PS_LaborCode__c';
import {getRecord} from "lightning/uiRecordApi";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getProductItemDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails'
import FORM_FACTOR from '@salesforce/client/formFactor';
import { IsConsoleNavigation, getFocusedTabInfo,closeTab } from 'lightning/platformWorkspaceApi';
import getProductDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductDetails';
import { NavigationMixin } from 'lightning/navigation';
import lightningConfirmModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import callEstimateApi from '@salesforce/apex/SBR_3_0_Estimates_API_Service.parseWorkOrder';

export default class Sbr_3_0_sfsDesktopAddPartsLwc extends NavigationMixin(LightningElement) {
fields;
@track state = { isLoading: false };
@track changeValues={};
productItemId
@api workOrderId;
isDiscountDisabled=false;
@api objectApiName;
@track fieldSet;
@api WoId='';
hideCalculateDiscount=false;

additionalQuery
branchLocationNumber
woLaborCode
woStatus
woDesc
billCust

woLoaded=false;
@wire(IsConsoleNavigation) isConsoleNavigation;
@api props;
@api headerText;
@api additionalQuery;
@api woCompanyCode;
@api woLaborCode;
itemType='P';
@track removedFieldset
indexOfRemoved;
productItemSfId;
productId;
pcLaborCodes;
isProductItemSelected=false;
branchLocationNumber
quantityConsumedValue;
partNumber;
errorProductItemId=false;
recsTobeAddedParts=[];
isSpinner=false;
extended=0;
isErrorQuantityOnHand=false;
isDiscountCalculated=false;
additionalQueryParts='';
additionalQueryMisc='';
isInventory=true;
//Start - Added by Ashish | SERV-12576
disableAddParts=false;
errorMessageToDisableAddingParts='';
//End - Added by Ashish | SERV-12576
QuantityNegativeError = false;
partNum
@wire(getRecord,{recordId:'$workOrderId',fields:[COMPANY_CODE,BRANCH_LOCATION_NUMBER,
        WO_DESC,WO_STATUS,WO_LABOR_CODE,WO_BILCUST]})
    workOrderData({data,error})
    {
        if(data){
            console.log('JSON. '+JSON.stringify(data));
            this.companyCode=data.fields.SF_PS_Company_Code__c.value;
            this.woDesc=data.fields.SF_PS_Work_Order_Des__c.value;
            let woStatus=data.fields.Status.value;
            this.woLaborCode=data.fields.SF_PS_LaborCode__c.value;
            this.changeValues.SF_PS_Labor_Code__c=this.woLaborCode;
            this.billCust=data.fields.SF_PS_BillCustOrLoc__c.value;

            if (data.fields.ServiceTerritory.value != undefined) {
                this.branchLocationNumber=data.fields.ServiceTerritory.value.fields.Branch_Location_Number__c.value;
            }
            this.additionalQueryParts=`Location.Company_Code__c='${this.companyCode}' and RecordType.DeveloperName='Parts_and_Merchandise' and Location.Branch_Location_Number__c='${this.branchLocationNumber}' and QuantityOnHand>0 `;
            this.additionalQueryMisc=` Product2.Product_Type__c like '%MISC%'`;

            //this.additionalQuery=`Location.Company_Code__c='${this.companyCode}' and Location.Branch_Location_Number__c='${this.branchLocationNumber}' and QuantityOnHand>0 `;
            //console.log(this.additionalQuery);

            if(this.billCust=='L'){
                this.isDiscountDisabled=true;
                this.hideCalculateDiscount=true;
            }else{
                this.isDiscountDisabled=false;
            }
            if(this.woDesc=='CHECK IN RETURN'){
                this.showErrorForCheckInReturn=true;
                this.isReadOnly=false;
                this.errorMsg='Parts cannot be added on Rent Ready Inspections.'
            }else if(woStatus=='C'||data.fields.Status.value=='D'){
                this.showErrorForCheckInReturn=false;
                this.isReadOnly=true;
                this.msg='Parts cannot be added/updated on Closed or Canceled Work Order'
            }else{
                this.isReadOnly=false;
                this.showErrorForCheckInReturn=false;
            }
            //Start - Added by Ashish | SERV-12576
            if (this.woDesc == 'NEW RENTAL EQUIP COMMISSIONING' || this.woDesc == 'REMARKETING INSPECTION' || this.woDesc == 'CHECK IN RETURN') {
                this.disableAddParts = true;
                this.errorMessageToDisableAddingParts = 'Parts can not be added for NEW RENTAL EQUIP COMMISSIONING, REMARKETING INSPECTION, CHECK IN RETURN Work Order.';
            } else {
                this.disableAddParts = false;
            }
            //End - Added by Ashish | SERV-12576
            this.woLoaded=true;
            this.state.isLoading=false;


        }
        if(error){
            console.log('error occured '+JSON.stringify(error));
        }
    }

get fieldWidth() {
    return (FORM_FACTOR == 'Large') ? this.props.largeff : this.props.smallff;
}
mapData()
{
    this.fieldSet.forEach(field=>{
        field.value=this.changeValues[field.apiname];
    })
    console.log(JSON.stringify(this.fieldSet));
}
handlePartNumberChange(event){
     this.partNum=event.target.value;

}


connectedCallback(){

    console.log('this is work order Id '+this.workOrderId);
    this.changeValues.WorkOrderId=this.workOrderId;
    this.changeValues.uuid=this.createUUID();
    this.fieldSet=JSON.parse(JSON.stringify(this.props.fieldSet));
    // if(this.props.objectapiname=='ProductConsumed'){
    //     this.fieldSet.find(data => data.apiname === 'WorkOrderId').value=this.workOrderId;
    // }
    // else if(this.props.objectapiname=='SF_PS_Quoted_Part__c'){
    //     this.fieldSet.find(data => data.apiname === 'SF_PS_WorkOrderId__c').value=this.workOrderId;
    // }
    if(!this.workOrderId)
    {
        this.woLoaded=true;
        this.state.isLoading=false;
    }
    else{
        this.state.isLoading=true;
    }


 }
 //Getter method to decide whether need to disable save button
 get checkValidations(){
    if(this.changeValues.isErrorDiscount || this.changeValues.minPriceError)
    {
        return true;
    }
    return false;
}
// Handele parts# chnage
productItemChange(event){
   let Id = event?.detail?.selectedRecord?.Id;
   if(event.target.name=='ProductItem'){
    this.productItemSfId=Id;
   }else{
    this.productId=Id;
    this.productItemSfId=undefined;
   }

   if(Id ){
    this.getProductDetails();
   }else{
    this.reset(this.changeValues);
   this.mapData();
   }
   event.preventDefault();
}
//Method to check if qty or cost price is updated
handleChange(event){
    console.log('datachanged inside handlechange event' +event.target.value+'--'+event.target.name);
    let name=event.target.name;
    this.changeValues[name]=event.target.value;
    if(name=='SF_PS_Quantity__c'||name=='SF_PS_Cost_Price__c')
    {
        if(this.changeValues[name] < 1 && name=='SF_PS_Quantity__c' && this.changeValues[name]){
            this.QuantityNegativeError = true;
            this.fieldSet.find(data => data.apiname === 'SF_PS_Quantity__c').invalidValueError=true; 
        } else {
            this.fieldSet.find(data => data.apiname === 'SF_PS_Quantity__c').invalidValueError=false; 
            this.QuantityNegativeError = false;
            this.checkExtended(this.changeValues);
        }
    }
    if(name=='SF_PS_ItemType__c')
    {
        let prevVal=this.itemType
        this.itemType=event.target.value;
        if(this.itemType =='MI' && this.billCust=='L'){
            this.isDiscountDisabled=false;
        } else {
            if(this.billCust=='L'){
                this.isDiscountDisabled=true;
            }else{
                this.isDiscountDisabled=false;
            }
        }
        if( (this.itemType && prevVal && prevVal!=this.itemType && !this.productItemSfId)|| this.itemType =='MI'  )
        {
            this.productItemSfId=undefined;
            this.reset(this.changeValues);
            this.mapData();
        }
    }
    if(name=='SF_PS_Selling_Price__c')
    {
        this.handleSellingPriceChange(event);
    }
    if(name=='SF_PS_Orig_Selling_Price__c' && (!this.isInventory)){
        this.changeValues.SF_PS_Selling_Price__c= event.target.value;
       //this.fieldSet.find(data => data.apiname === 'SF_PS_Selling_Price__c').value=orgPrice;
       this.handleSellingPriceChange(event);

    }
    if(name=='SF_PS_Part_Number__c')
    {
        this.partNum=event.target.value;

    }
    if(name=='SF_PS_Parts_Type__c')
    {
        this.isInventory=event.target.value=='Inventory'?true:false;
        if(!this.isInventory){
            this.partNum="";
            this.hideCalculateDiscount=true;
        }else if(this.billCust=='C'){
            this.hideCalculateDiscount=false;
        }
        this.withoutInventoryChecks(event.target.value);


    }
    if(name=='WorkOrderId'|| name=='SF_PS_WorkOrderId__c')
    {
        this.workOrderId=event.target.value;
        if(this.workOrderId)
        {
        this.woLoaded=false;
        this.reset(this.changeValues);
        this.mapData();
        }
        //this.woLoaded=true;



    }
}
withoutInventoryChecks(type)
{
    if(type=='Without Inventory')
    {
       // this.fieldSet.find(data => data.apiname === 'SF_PS_WorkOrderId__c').
       this.fieldSet.forEach((data,index)=>{
        if(data.apiname=='SM_PS_Description__c'||data.apiname=='SF_PS_Cost_Price__c'||data.apiname=='SF_PS_Orig_Selling_Price__c'){
            data.disabled=false;
            data.required=true;
        }
        if(data.apiname=='SF_PS_ItemType__c'){
            this.indexOfRemoved=index;
            this.removedFieldset={...data};

        }
        if(data.apiname=='SF_PS_List_Price__c'){
            data.disabled=false;

        }


       })
        this.fieldSet.splice(this.indexOfRemoved,1);

    }
    else{
        let elementExist=false;
        this.fieldSet.forEach(data=>{
            if(data.apiname=='SF_PS_List_Price__c'||data.apiname=='SM_PS_Description__c'||data.apiname=='SF_PS_Cost_Price__c'|| data.apiname=='SF_PS_Orig_Selling_Price__c')
            {
                data.disabled=true;
                data.required=false;
            }
            if(data.apiname=='SF_PS_ItemType__c')
            {
              elementExist=true;
            }
           })
        if(!elementExist)
        {
            this.fieldSet.splice(this.indexOfRemoved,0,this.removedFieldset);
        }
    }
    this.reset(this.changeValues);
    this.mapData();

    this.template.querySelector('[data-name="SF_PS_Quantity__c"]')?.reset();
    this.template.querySelector('[data-name="SM_PS_Description__c"]')?.reset();
    this.template.querySelector('[data-name="SF_PS_Cost_Price__c"]')?.reset();
    this.template.querySelector('[data-name="SF_PS_List_Price__c"]')?.reset();
    this.template.querySelector('[data-name="SF_PS_Orig_Selling_Price__c"]')?.reset();


}
// To handle price book entry selection
handlePricebookEntrySelection(priceBookentries){

    for(let pb in priceBookentries){
        console.log("Company code "+this.woCompanyCode);
        // Check any entry matching currency code
        if(this.companyCode=='01' && priceBookentries[pb].CurrencyIsoCode=="USD"){
        console.log("USA "+JSON.stringify(priceBookentries[pb]));
        return priceBookentries[pb];
        }else if(this.companyCode=='02' && priceBookentries[pb].CurrencyIsoCode=="CAD"){
        console.log("CAD "+JSON.stringify(priceBookentries[pb]));
        return priceBookentries[pb];
        }
    }
    return null;

}
get lookup()
{
    if(this.itemType=='MI'){
        return false;
    }
    return true;
}
get lookupLabel()
{
    if(this.itemType=='MI'){
        return 'Product';
    }
    return 'Product Item';
}
getProductDetails()
{
    if(!this.lookup){
        getProductDetails({prodId:this. productId}).then(data=>{
            console.log('Recieved Data by wire:: '+ JSON.stringify(data));
            let result=data.Item;
            console.log('Id::'+ result.Id);
            let productId=result.Id;
            this.changeValues.SF_PS_Discount_Percentage__c = 0;
            this.changeValues.Product2Id=result.Id;
            this.changeValues.ProductItemId=productId;
            this.changeValues.SF_PS_Unit_Of_Measure__c=result.QuantityUnitOfMeasure;
            // FT2-Reg
            this.changeValues.SF_PS_Product_SKU__c=result.Product_SKU__c;
            this.changeValues.SF_PS_Selling_Price__c=result.Sell_Price__c;
            if(this.itemType =='MI' && this.billCust=='L'){
                this.changeValues.SF_PS_Selling_Price__c=0;
            }
            this.changeValues.SF_PS_Last_Cost=result.Last_Cost__c;
            if(this.changeValues.SF_PS_Selling_Price__c){
                this.changeValues.isErrorsellingPrice=false;
            }
            this.changeValues.SF_PS_List_Price__c=result.List_Price__c;
            this.changeValues.SF_PS_Orig_Selling_Price__c = result.Sell_Price__c;
            this.changeValues.Freight_Percentage__c=result.Freight_Percentage__c;
            this.changeValues.Expected_Profit_Percent__c=result.Expected_Profit_Percent__c;
            this.changeValues.SF_PS_Cost_Price__c=result.Last_Cost__c;
            if(data.Item.ProductItems && data.Item.ProductItems.length){
                let cost=this.getAvgCost(data.Item.ProductItems);
                this.changeValues.SF_PS_Cost_Price__c=cost?cost:0;
                let productItemRec=this.getProductItem(data.Item.ProductItems);
                this.changeValues.ProductItemId=productItemRec?.Id;
                this.changeValues.SF_PS_Product_Item__c=productItemRec?.Id;
                this.changeValues.SF_PS_Last_Cost= (productItemRec?.SM_PS_Last_Cost__c>0) ? productItemRec.SM_PS_Last_Cost__c : (result.Last_Cost__c>0 ? result.Last_Cost__c : 0 );
                this.changeValues.SF_PS_Cost_Price__c=this.changeValues.SF_PS_Last_Cost;
            }
            this.changeValues.SF_PS_Description__c=result.Description__c;
            this.changeValues.SM_PS_Description__c = result.Description__c;

            //this.changeValues.SF_PS_Description__c=result.Description__c;
            this.changeValues.Item_Number__c=result.Item_Number__c;
            this.changeValues.SF_PS_Stock_Class__c=result.Stock_class__c;
            let pricebookEntries=data.PricebookEntry;
            let pricebook=this.handlePricebookEntrySelection(pricebookEntries);
            console.log('this is pricebook '+pricebook);
            if(pricebook && pricebook.Id ){
                this.changeValues.PricebookEntryId=pricebook?.Id;
                this.changeValues.isErrorPriceBookEntry=false;
            }
            else{
                this.changeValues.isErrorPriceBookEntry=true;
            }
            this.changeValues.PricebookEntryId=pricebook?.Id;

            console.log(JSON.stringify(this.changeValues));
            this.mapData();

        }).catch(error=>{
            console.log ('Error inside wire call:: '+JSON.stringify(error))
        })
    }else{
            getProductItemDetails({ productItemId: this.productItemSfId }).then(data => {
                let result = data.Item;
                console.log(data);
                this.handleData(data);
                let productItemId=result.Id;
                this.changeValues.ProductItemId = productItemId
                this.changeValues.SF_PS_Unit_Of_Measure__c = result.Product2.QuantityUnitOfMeasure;
                // FT2-Reg
                this.changeValues.SF_PS_Product_SKU__c=result.Product2.Product_SKU__c;
                this.changeValues.SF_PS_Selling_Price__c = result.Product2.Sell_Price__c;
                this.changeValues.SF_PS_Orig_Selling_Price__c = result.Product2.Sell_Price__c;
               // let productype=
                this.changeValues.SF_PS_Discount_Percentage__c = 0;
                if (this.changeValues.SF_PS_Selling_Price__c) {
                    this.changeValues.isErrorsellingPrice = false;
                }
                let prodType = String(result.SM_PS_Product_Type__c);
                if (prodType.toLocaleLowerCase().includes("parts")) {
                    this.template.querySelector('[data-name="SF_PS_ItemType__c"]').value = "P";
                } else {
                    this.template.querySelector('[data-name="SF_PS_ItemType__c"]').value = "M";
                }
                this.changeValues.Product2Id = result.Product2Id;
                this.changeValues.calculateDiscount = false;
                this.changeValues.SF_PS_Product_Item__c = productItemId
                this.changeValues.SF_PS_List_Price__c = result.Product2.List_Price__c;
                this.changeValues.SF_PS_Cost_Price__c = result.SM_PS_Average_Cost__c>0 ? result.SM_PS_Average_Cost__c : ( result.SM_PS_Last_Cost__c> 0 ? result.SM_PS_Last_Cost__c : 0)
                this.changeValues.SF_PS_Description__c = result.SM_PS_Description__c;
                this.changeValues.SM_PS_Description__c = result.SM_PS_Description__c;
                this.changeValues.SF_PS_Last_Cost = result?.SM_PS_Last_Cost__c>0 ? result.SM_PS_Last_Cost__c : (result?.Product2.Last_Cost__c > 0 ? result.Product2.Last_Cost__c : 0 );
                this.changeValues.Freight_Percentage__c=result.Product2.Freight_Percentage__c;
                this.changeValues.Expected_Profit_Percent__c=result.Product2.Expected_Profit_Percent__c;
                this.changeValues.Item_Number__c=result.Product2.Item_Number__c;
                this.changeValues.SF_PS_Stock_Class__c=result.Product2.Stock_class__c;
                console.log('Freight_Percentage__c '+ this.changeValues.Freight_Percentage__c);
                console.log('Expected_Profit_Percent__c '+ this.changeValues.Expected_Profit_Percent__c);
                this.handleWarningAndErors(this.changeValues);
                //selectedRecord.QuantityOnHand=result.QuantityOnHand;
                this.changeValues.SM_PS_Quantity_Available__c = result.SM_PS_PartsMerch_Available_Quantity__c;
                this.checkExtended(this.changeValues);
                let pricebookEntries = data.PricebookEntry;
                let pricebook = this.handlePricebookEntrySelection(pricebookEntries);

                    if(pricebook && pricebook.Id){
                        this.changeValues.PricebookEntryId = pricebook?.Id;
                        this.changeValues.isErrorPriceBookEntry = false;
                    }
                    else{
                        this.changeValues.isErrorPriceBookEntry = true;
                    }
                if(this.changeValues.SF_PS_Discount_Percentage__c<0 && this.changeValues.SF_PS_Discount_Percentage__c>100){
                    this.changeValues.isErrorDIscount = true;
                }
                console.log(result);
                console.log(JSON.stringify(this.changeValues));
                this.mapData();

            }).catch(error => {
                console.log(JSON.stringify(error))
            })
        }
}
//Get productItem as per location for misc items
getProductItem(productItems){
    let productItem=productItems.filter(item=>{
        return (item.Location.Branch_Location_Number__c==this.branchLoc && item.Location.Company_Code__c==this.companyCode)
    })
    return productItem.length>0 ? productItem[0] : productItem;
}

reset(selectedRecord)
{

            selectedRecord.ProductItemId = "";
			selectedRecord.SF_PS_Unit_Of_Measure__c = "";
			selectedRecord.SF_PS_Selling_Price__c = "";
			selectedRecord.SF_PS_List_Price__c = "";
			selectedRecord.SF_PS_Orig_Selling_Price__c = "";
			selectedRecord.SF_PS_Discount_Percentage__c = "";
			selectedRecord.SF_PS_Cost_Price__c = "";
			selectedRecord.SF_PS_Description__c = "";
			selectedRecord.QuantityOnHand = "";
			selectedRecord.extended = 0
			selectedRecord.QuantityConsumed = "";
			this.isProductItemSelected = false;
			selectedRecord.SM_PS_Quantity_Available__c = "";
			selectedRecord.PricebookEntryId = "";
			selectedRecord.Product2Id = "";
			selectedRecord.isErrorPriceBookEntry = false;
			selectedRecord.Freight_Percentage__c="";
          	selectedRecord.Expected_Profit_Percent__c="";
            selectedRecord.SF_PS_Warning_Price__c="";
            selectedRecord.SF_PS_Error_Price__c="";
            selectedRecord.SF_PS_Minimum_Price__c="";
            selectedRecord.SF_PS_Stock_Class__c="";
            selectedRecord.SF_PS_Quantity__c="";

            selectedRecord.SM_PS_Description__c="";

            this.partNum="";

			selectedRecord.warningError = false;
			selectedRecord.minPriceError = false;
			selectedRecord.isErrorDiscount = false;
			selectedRecord.calculateDiscount=false;
            this.extended="";
}

handleData(data)
{

}
 //Method to fire model to get input to proceed further if selling price is lower than warning price but greater than min price
async showPopup()
{
    await lightningConfirmModalLWC.open({
        size: 'small',
        description: 'Accessible description of modal purpose',
        content: 'Discount applied is greater than the suggested sale amount for one or more parts. Click ‘yes’ to proceed.',
        headerText:'Confirmation',
        onyesclick:(e)=>{

             this.confirm=true;
             return;
         }
     });

 }
 //Method to handle new selling price change
 handleSellingPriceChange(event){
    let selectedRecord = this.changeValues;
    console.log('Selected Row on selling price change :: '+JSON.stringify(selectedRecord));
    selectedRecord.SF_PS_Selling_Price__c = event.target.value;
    console.log('new selling price::'+selectedRecord.SF_PS_Selling_Price__c);
    selectedRecord.isErrorsellingPrice = false;
    selectedRecord.avgError = false;
    if(this.isInventory)
    {
        this.handleWarningAndErors(selectedRecord);
        //Discount Calculation
        if(selectedRecord.SF_PS_Orig_Selling_Price__c>=0 && selectedRecord.SF_PS_Selling_Price__c>=0 && selectedRecord.SF_PS_Orig_Selling_Price__c >selectedRecord.SF_PS_Selling_Price__c && this.billCust!='L'){
            selectedRecord.SF_PS_Discount_Percentage__c=(((selectedRecord.SF_PS_Orig_Selling_Price__c - selectedRecord.SF_PS_Selling_Price__c)/selectedRecord.SF_PS_Orig_Selling_Price__c)*100).toFixed(2);
        }
        else {
            selectedRecord.SF_PS_Discount_Percentage__c=0;
            selectedRecord.isErrorDiscount=false;
        }
    }

    this.checkExtended(selectedRecord);
}


//Method to validate for warning and min price error
handleWarningAndErors(selectedRecord){
    //Last_Cost__c
    let warningPrice=selectedRecord.SF_PS_Last_Cost+((selectedRecord.Expected_Profit_Percent__c*selectedRecord.SF_PS_Last_Cost)/100);
    let errorPrice =selectedRecord.SF_PS_Cost_Price__c+((selectedRecord.Freight_Percentage__c*selectedRecord.SF_PS_Cost_Price__c)/100);
    selectedRecord.SF_PS_Warning_Price__c=warningPrice;
    selectedRecord.SF_PS_Error_Price__c=errorPrice;
    selectedRecord.SF_PS_Minimum_Price__c=errorPrice;
    // Error
    if(this.billCust!='L' && (selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Error_Price__c) && !this.priceReadOnly){
        selectedRecord.minPriceError = true;
    }
    else{
        selectedRecord.minPriceError = false;
    }

    if(this.billCust!='L' && selectedRecord.SF_PS_Cost_Price__c && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Cost_Price__c && !this.priceReadOnly){
        selectedRecord.avgError = true;
    }
    else{
        selectedRecord.avgError = false;
    }
    // Warning
    if((this.billCust!='L' && !selectedRecord.minPriceError && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Warning_Price__c) && !this.priceReadOnly){
        selectedRecord.warningError = true;
    }
    else{
        selectedRecord.warningError = false;
    }
}
 //Method to handler discount change in form
 handleDiscountChange(event){
    //let fields = this.record[this.recordId].fields;
    let selectedRecord=this.changeValues;
    selectedRecord.SF_PS_Discount_Percentage__c = event.target.value;
    if(selectedRecord.SF_PS_Discount_Percentage__c >=0 && selectedRecord.SF_PS_Discount_Percentage__c<100 && (selectedRecord.SF_PS_Orig_Selling_Price__c>=0)){
        selectedRecord.SF_PS_Selling_Price__c=(selectedRecord.SF_PS_Orig_Selling_Price__c - (selectedRecord.SF_PS_Orig_Selling_Price__c*selectedRecord.SF_PS_Discount_Percentage__c/100)).toFixed(2);
        selectedRecord.isErrorDiscount=false;
    }
    else{
        selectedRecord.SF_PS_Selling_Price__c= selectedRecord.SF_PS_Orig_Selling_Price__c;
        selectedRecord.isErrorDiscount=true;
    }
    this.checkExtended(selectedRecord);
    if(this.isInventory){
        this.handleWarningAndErors(selectedRecord);
    }

}
//Method to handle default cancel event to perform custom logic on cancel button
handleCancel(event){
    event.preventDefault();
    if (this.isConsoleNavigation) {
        getFocusedTabInfo().then((tabInfo) => {
            closeTab(tabInfo.tabId);
        }).catch(function(error) {
            console.log('Error in cancel event'+ error);
        });
    }
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.workOrderId,
            objectApiName: this.props.objectapiname,
            actionName: 'view'
        },
    });
    return false;
}
//Method to perform extended amount
checkExtended(selectedRecord){
    console.log(selectedRecord.SF_PS_Quantity__c)

    if(this.itemType =='MI' && this.billCust=='L'){
        this.extended = selectedRecord.SF_PS_Selling_Price__c * selectedRecord.SF_PS_Quantity__c;
    }
    else if(this.billCust == 'L'){
        console.log('inside L')
        this.extended = selectedRecord.SF_PS_Cost_Price__c * selectedRecord.SF_PS_Quantity__c;
    } 
    else if(this.billCust == 'C' || this.billCust == '$'){
        console.log('inside C')
        this.extended = selectedRecord.SF_PS_Selling_Price__c * selectedRecord.SF_PS_Quantity__c;
    }
    console.log(this.extended);
}
//Method to perform input data validation in all input fields
checkValidation() {

    let Id=this.lookup?this.productItemSfId:this.productId;
    this.changeValues.quantityError=this.changeValues.SF_PS_Quantity__c?false:true;
    this.changeValues.sellingError=this.changeValues.SF_PS_Selling_Price__c?false:true;
    this.changeValues.laborError=this.changeValues.SF_PS_Labor_Code__c?false:true;
    //this.changeValues.laborError=this.changeValues.SF_PS_Labor_Code__c?false:true;
    if(!this.isInventory){
        this.changeValues.partError=this.partNum?false:true;
        this.changeValues.lookupError=false;
    }
    else{
        this.changeValues.partError==false;
        this.changeValues.lookupError=Id?false:true;

    }
    this.changeValues.workOrderError=this.workOrderId?false:true;

    const allValid = [...this.template.querySelectorAll('lightning-input-field')]
        .reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();

                }, true);
    if(this.QuantityNegativeError || this.changeValues.quantityError||this.changeValues.partError || this.changeValues.isErrorPriceBookEntry||this.changeValues.laborError|| this.changeValues.laborError||this.changeValues.lookupError|| this.changeValues.workOrderError){
    return true;
    }
    return false;
}
//On Success event handler to handle tab navigation and toast message on successful update
onSuccess(event) {
    this.state.isLoading = true;
    //this.props.recordid = event.detail.id;
    this.showToastMessage('Success!', 'success', this.props.sucessmessage);

    let  tabDetail;
    //this.btnToggel();
    if (this.isConsoleNavigation) {
        getFocusedTabInfo().then((tabInfo) => {
            closeTab(tabInfo.tabId);
        }).catch(function(error) {
            console.log('Error on success event'+ error);
        });
    }
    //this.state.isLoading = false;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: event.detail.id,
            objectApiName:'ProductConsumed',
            actionName: 'view'
        },
    });
}
//On Error event to show error in toast message if any error occured
onError(event) {
    this.state.isLoading = false;
    let message = '';
    if (event.detail.detail)
    {
        message = event.detail.detail;
    }
    else if(event.detail.message)
    {
        message = event.detail.message;
    }
    // console.log('error' +event.detail.detail);
    // this.showToastMessage('ERROR', 'error', 'DETAIL : ' + '\n' + `\n ${event.detail.detail}`);
    this.showToastMessage('ERROR', 'error', 'DETAIL : ' + '\n' + '\n ' + message);
}
//On Submit event handler to perform custom logic
async onSubmit(event) {

    console.log('fields are  '+JSON.stringify(event.detail.fields))
    event.preventDefault();
   if( this.checkValidation())
   {
    return;
   }
    this.state.isLoading=true;
    let executeNext=false;
    if(this.changeValues.warningError){
        await this.showPopup();
        executeNext=this.confirm;
        console.log('this is execute next'+executeNext);
    }
    else{
        executeNext=true;
    }
    if(executeNext){
        const fields = event.detail.fields;
        fields.PricebookEntryId=this.changeValues.PricebookEntryId;
        fields.SF_PS_Product_Item__c=this.changeValues.SF_PS_Product_Item__c;
        if(this.isInventory && this.props.objectapiname=='SF_PS_Quoted_Part__c')
        {
            fields.SF_PS_ProductItem__c=this.changeValues.SF_PS_Product_Item__c;
            fields.SF_PS_Product2Id__c=this.changeValues.Product2Id;
        }


        fields.QuantityConsumed=1;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }else{
        this.state.isLoading=false;
    }
}
//Generic toast message method
showToastMessage(title,variant,message) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: 'dismissable'
    });
    this.dispatchEvent(event);
}

createPayload(part){
    console.log('parts:'+ JSON.stringify(part));

    let result = {
        "cost": part.SF_PS_Cost_Price__c,
        //hardcoding
    "itemNumber": part.Item_Number__c,
    //"itemNumber": "HS1490",
        "laborCode": Number(part.SF_PS_Labor_Code__c),
        "quantity":part.SF_PS_Quantity__c,
        "sellingPrice":part.SF_PS_Selling_Price__c,
        "sourceReferenceLineNumber": part.uuid,
        "stockClass": part.SF_PS_Stock_Class__c,
        //hardcoding
        // "stockClass": SBPOW,
        "unitOfMeasure": part.SF_PS_Unit_Of_Measure__c
        }
    return result;
}
//Method to call estimates API.
async getDiscounts(finalPayload){
    this.state.isLoading=true;
    await callEstimateApi({woId:this.workOrderId,existingPayload:finalPayload}).then(response=>{

        console.log('response:::'+response);
        let result= JSON.parse(response);
        if(this.isDiscountCalculated==false|| this.isDiscountCalculated && !this.changeValues.SF_PS_Discount_Percentage__c ){
            this.isDiscountCalculated=true;
            this.changeValues.SF_PS_Discount_Percentage__c=result.estimatesItems[0]?.discountPercent;
        }
        const eventMock={
            target : {
                value : this.changeValues.SF_PS_Discount_Percentage__c
            }
        }
        this.handleDiscountChange(eventMock);

        this.state.isLoading=false;
    }).catch(error=>{
        this.isDiscountCalculated=true;

        console.log('estimate api error '+JSON.stringify(error));
        //this.disableSavePopUp = true;
        //this.loadSpinner = false;
        this.state.isLoading=false;
        })


}
//disable Discount
get disableDiscount(){
    return ( this.billCust=="L")
}
//CalculateDiscount
calculateDiscount(){
    let valid=this.checkValidation();
    console.log(valid+' this is validity ');
    if(valid){
        return;
    }

    let json={};
    json.parts=[this.createPayload(this.changeValues)];
    json.outsideLabor=[];
    json.insideLabor= [];
    json.outsideLabor= [];
    json.mileage= {};
    let payload=JSON.stringify(json);
    console.log(payload);
    this.getDiscounts(payload);

}

createUUID(){
    let id=Date.now().toString(36) + Math.floor(Math.pow(10, 12) + Math.random() * 9*Math.pow(10, 12)).toString(36);
    return id;
}
get checkDiscountCalculated()
{
    if(this.billCust=='L' ){
        //return this.checkValidation();
        return false;
    }
    if(!this.isInventory){

        return this.checkValidations;

    }
    if(this.isDiscountCalculated)
    {
    return this.checkValidations;
    }
    return true;

}

hideErrorMessage(event) {
    this.disableAddParts = false;
    this.handleCancel(event);
}

}