import { LightningElement,api,track,wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import getProductItemDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails';
import getProductDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductDetails';
import {FlowNavigationBackEvent,FlowAttributeChangeEvent,FlowNavigationNextEvent,FlowNavigationFinishEvent} from "lightning/flowSupport";
import { NavigationMixin } from 'lightning/navigation';
import { getRecord} from 'lightning/uiRecordApi';
import getPricebookentriesFrmProd from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getPricebookEntriesForProd';
import messageForSellingPrice from '@salesforce/label/c.Message_For_Selling_Price';

export default class Sbr_3_0_sfsDesktopMiscItemsCmp extends LightningElement {
    //Public exposed properties
    @api recordToBeDeleted;
    @api screen;
    @api additionalQuery;
    @api baseUrlFromFlow;
    @api companyCode;
    @api branchLoc;
    @api expenseToLoc
    @api default;
    @api defaultLaborCode;
    @api skiptoSummary;
    @api skiptoSummaryPage=false;
    @api showNextButton = false;
    @api miscellaneousItemsRecord=[];
    @api title="Miscellaneous Charges";
    @api columnList=[
                        { "label" : "Item Number", "apiName" : "ProductItemId" }, 
                        { "label" : "Description", "apiName" : "Description" },
                        { "label" : "UM", "apiName" : "SF_PS_Unit_Of_Measure__c" },
                        { "label" : "Labor Code", "apiName" : "SF_PS_Labor_Code__c" },
                        //{ "label" : "QOH", "apiName" : "QuantityOnHand" },
                        { "label" : "Qty", "apiName" : "QuantityConsumed" },
                        { "label" : "List Price/unit", "apiName" : "SF_PS_List_Price__c" },
                        { "label" : "Orig Selling Price", "apiName" : "SF_PS_Orig_Selling_Price__c" },
                        { "label" : "Discount%", "apiName" : "SF_PS_Discount_Percentage__c" },
                        { "label" : "New Sell Price/unit", "apiName" : "SF_PS_Selling_Price__c" },
                        { "label" : "Cost/unit", "apiName" : "SF_PS_Cost_Price__c" },
                        { "label" : "Ext Amount", "apiName" : "Selling_Price__c" },  // Change
                    ];

    @track pcLaborCodes;
    @track prdDetails;
    @track rows;
    NextScreenMessage;
    validationsErrorFound;
    showButtons; 
    disableSellingPrice=false;
    disableDiscount=false;
    minimumSellingPrice =1;
    isReviewScreen=false;
    productItemSfId;
    globalSelectedRecord;
    productSfId;
    isProductItemSelected=false;
    desc='-';
    uom='-';
    sellPrice=0;
    listPrice=0;
    sellPriceDisplay='-'
    listPriceDisplay='-'
    avgCost=0
    qtyOnHand='-'
    productName='-'
    binLoc='-'
    stockClass='-'
    itemNum='-'
    quantityConsumedValue=0
    extended='-'
    extendedVal='-';
    isErrorParts=false;
    isErrorLbrc=false;
    isErrorQtyConsumed=false;
    qohError=false;
    prevURL=''; 
    partsTotal;
    columns;
    picklistValues = [];
    hideDiscountForL = true;
    label = {
                messageForSellingPrice 
            };
    newRecord = {
                    "QuantityConsumed":'',
                    "ProductItemId":'',
                    "Description":'',
                    "SF_PS_Product2Id__c":'',         // Added for Misc Item only
                    "SF_PS_Last_Cost_Price__c":'',    // Added for Misc Item only
                    "SF_PS_Quantity_Consumed__c":'',  // Added for Misc Item only
                    "SF_PS_Unit_Of_Measure__c":'',    // good
                    "SF_PS_Selling_Price__c":'',      // good
                    "SF_PS_List_Price__c":'', 
                    "SF_PS_Orig_Selling_Price__c": '',
                    "SF_PS_Discount_Percentage__c": '',      // good
                    "SF_PS_Cost_Price__c":'',      // change
                    "SF_PS_Labor_Code__c":'',
                    "PricebookEntryId":'',
                    "tooltip":'',
                    "SF_PS_ItemType__c":'MI',
                    "Product2Id":"",      // Good
                    "attributes": {
                        "type": "ProductConsumed",//"ProductConsumed",
                        "url": ""
                    },
                    "minPriceError": false,
		            "isErrorDiscount": false,
		            "avgError": false,
                    "avgErrorMessage":"Selling price cannot be less than avg price",
                    "calculateDiscount" : false
                }

    
    // To get WOLI Object metadata 
    @wire(getObjectInfo, { objectApiName: PC_OBJECT })
    pcInfo;
    // Pickilist work order description 
    @wire(getPicklistValues,{ recordTypeId: '$pcInfo.data.defaultRecordTypeId',fieldApiName: 'ProductConsumed.SF_PS_Labor_Code__c'})
    WorkOrderDescValues({error,data}){
        console.log("recieved Data in wire::"+ data);
        console.log("pcInfo:: "+this.pcInfo);
        if(data){
            //this.pcLaborCodes=[{label:'-', value:'-',selected:true},...data.values];
            this.pcLaborCodes=data.values;
        }
        else{
            console.log("Error in wire method:: "+JSON.stringify(error));
        }
    }


    // Connected call back 
    connectedCallback(){
        // Labor code deafult
        if(this.defaultLaborCode){
            this.newRecord.SF_PS_Labor_Code__c=this.defaultLaborCode;
        }
        this.additionalQuery=` and Location.Company_Code__c='${this.companyCode}' and Location.Branch_Location_Number__c='${this.branchLoc}' and QuantityOnHand>0 `;
        console.log('Additional Query:: '+this.additionalQuery);
        console.log('this is exp '+this.expenseToLoc);
        console.log('default: '+JSON.stringify(this.default));
        // For Review Screen
        if(this.screen=="Review"){
            this.showButtons=false;
            this.disableSellingPrice=false;
            this.disableDiscount=false;
            this.hideDiscountForL=false;
            if(this.expenseToLoc=='L'){
                this.disableDiscount=true;
                this.hideDiscountForL=true;
                this.minimumSellingPrice = 0;
            }
            this.isReviewScreen=true;
        }
        else{
            this.showButtons=true;
            this.disableSellingPrice = true;
            this.disableDiscount=true;
            if(this.expenseToLoc=='L'){
                this.disableSellingPrice = false;
                this.minimumSellingPrice = 0;
                this.newRecord.SF_PS_Selling_Price__c=0;
            }
            this.isReviewScreen=false;
        }
        if(this.default){
            this.rows=JSON.parse(JSON.stringify(this.default));
            console.log('Current row in connected:: '+this.rows);
            console.log('default: '+JSON.stringify(this.default));
        }
        else{
            this.initData();
        }
        if(this.showNextButton == false){
            this.NextScreenMessage = 'Next screen is Summary.';
        }
        else {
            this.NextScreenMessage = 'Next screen is Add Outside Labor.'; 
        }
    }

    // To init rows and other data
    initData(){
        this.rows=[];
        this.createRow();
    }

    // To create new row 
    createRow() {
        let obj=JSON.parse(JSON.stringify(this.newRecord));
        obj.uuid= this.createUUID();

        if(this.rows.length>0){
            obj.index=this.rows[this.rows.length-1].index+1;
        }
        else{
            obj.index=1;
        }
        this.rows.push(obj);
    }

    // Create rwo unique UUID
    createUUID(){
        // var dt = new Date().getTime();
        // var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c){
        //                 var r = (dt + Math.random()*16)%16 | 0;
        //                 dt = Math.floor(dt/16);
        //                 return (c === 'x' ? r :(r&0x3|0x8)).toString(16);
        //             });
        // return uuid;
        let id=Date.now().toString(36) + Math.floor(Math.pow(10, 12) + Math.random() * 9*Math.pow(10, 12)).toString(36);
		    return id;
    }

    // To remove row
    removeRow(event) {
        if(this.rows.length>1){
            this.rows.splice(event.target.value, 1);
            this.handleSkipButton();
            if(this.hideDiscountForL == false){
                let buttonEnableCheck = true;
                if(this.screen == "Review"){
                    this.rows.forEach((rowsRecord) => {
                        if(rowsRecord.calculateDiscount == false){
                            buttonEnableCheck=false;
                        }
                    });
                }
                if(buttonEnableCheck == false){
                    this.dispatchEvent(new CustomEvent("delrow", { detail: true }));
                } else {
                    this.dispatchEvent(new CustomEvent("delrow", { detail: false }));
                }
            }
        }
        
    }

    // To add row and validate
    addRow() {
        console.log("ROWS Before add action:"+JSON.stringify(this.rows));
        if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalculate", { detail: true }));
		}
        // To check all validations
        let isAllValidationsError=false;
        for(let i=0 ;i<this.rows.length;i++){
            // Validation for Product # 
            if(this.rows[i].Product2Id==""){
                this.rows[i].isErrorParts=true;
            }
            else{
                this.rows[i].isErrorParts=false;
            }

            if(!this.rows[i].PricebookEntryId  && this.rows[i].Product2Id){
                this.rows[i].isErrorPriceBookEntry=true;
            }
            else{
                this.rows[i].isErrorPriceBookEntry=false;
            }

            // Validation for Quantity Consumed
            if(this.rows[i].QuantityConsumed==""){
                this.rows[i].isErrorQtyConsumed=true;
            }
            else{
                this.rows[i].isErrorQtyConsumed=false;
            }
            // Validation for Labor Code
            if(this.rows[i].SF_PS_Labor_Code__c==""||this.rows[i].SF_PS_Labor_Code__c=="-"){
                this.rows[i].isErrorLbrc=true;
            }
            else{
                this.rows[i].isErrorLbrc=false;
            }

            if(this.expenseToLoc=='L'){
                this.rows[i].isErrorsellingPrice=false;
                this.rows[i].avgError= false;
            }else{
                this.rows[i].isErrorsellingPrice= this.disableSellingPrice ==false ?this.rows[i].SF_PS_Selling_Price__c  ?false:true : false;
                this.rows[i].avgError= this.disableSellingPrice ==false ? this.rows[i].SF_PS_Selling_Price__c<this.rows[i].SF_PS_Cost_Price__c?true:false : false;
            }
            // Check all fields 
            if(this.rows[i].isErrorsellingPrice||this.rows[i].decimalError|| this.rows[i].avgError||this.rows[i].qohError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed|| this.rows[i].isErrorParts ){
                isAllValidationsError =true;
            }
        }

        console.log("isAllValidationsError Rows: "+isAllValidationsError)
        if(isAllValidationsError==false){
            this.rows.push({ uuid: this.createUUID(),...this.newRecord });
        }
        console.log("ROWS after add action:"+JSON.stringify(this.rows));
    }
    
    /*
        // Handele parts# chnage
        handleProductChange(event){
            let productId= event.detail.selectedRecord.Id;
            let Id= event.target.dataset.id;
            console.log(Id);
            let selectedRecord = this.rows.find(data => data.uuid === Id);
            //  Clearing validations
            selectedRecord.isErrorParts=false;
            this.productSfId=productId;
            //console.log(productId);
            if(productId!=undefined){
                if(productId){
                    getProductDetails({prodId:productId}).then(data=>{
                        let result=data.Item;
                        console.log(data);
                        console.log(result.Id);
                        //selectedRecord.SF_PS_Product2Id__c=productId;    
                        //selectedRecord.ProductItemId=productId;
                        selectedRecord.Product2Id=result.Id;
                        selectedRecord.SF_PS_Unit_Of_Measure__c=result.QuantityUnitOfMeasure;
                        selectedRecord.SF_PS_Selling_Price__c=result.Sell_Price__c;
                        selectedRecord.SF_PS_Last_Cost_Price__c=result.Last_Cost__c;         
                        if(selectedRecord.SF_PS_Selling_Price__c){
                            selectedRecord.isErrorsellingPrice=false;
                        }
                        selectedRecord.SF_PS_List_Price__c=result.List_Price__c;
                        selectedRecord.SF_PS_Cost_Price__c=result.Last_Cost__c;
                        selectedRecord.Description=result.Description__c;
                        //selectedRecord.SM_PS_Quantity_Available__c=result.SM_PS_Quantity_Available__c;
                        let pricebookEntries=data.PricebookEntry;
                        let pricebook=this.handlePricebookEntrySelection(pricebookEntries);
                        console.log('this is pricebook '+pricebook);
                        console.log(pricebook);
                        selectedRecord.PricebookEntryId=pricebook?.Id;
                        this.checkExtended(selectedRecord);
                    
                        console.log(result);
                        console.log(JSON.stringify(selectedRecord));
                        console.log('ROWS '+JSON.stringify(rows));

                    }).catch(error=>{
                        console.log (JSON.stringify(error))

                    })
                }
            }
            else{
                selectedRecord.ProductItemId="";
                selectedRecord.SF_PS_Unit_Of_Measure__c="";
                selectedRecord.SF_PS_Selling_Price__c="";
                selectedRecord.SF_PS_List_Price__c="";
                selectedRecord.SF_PS_Cost_Price__c="";
                selectedRecord.Description="";
                //selectedRecord.QuantityOnHand="";
                selectedRecord.extended=0
                this.isProductItemSelected=false;

            }
        }
    */


    // Handle quantity chnage
    handleQuantityChange(event){
        let Id= event.target.dataset.id;
        console.log('ID inside qtychangehandler:: '+Id);
        let selectedRecord = this.rows.find(data => data.uuid === Id);

        // clearing validation
        selectedRecord.SF_PS_Quantity_Consumed__c=event.detail.value
        selectedRecord.QuantityConsumed=event.detail.value;
        selectedRecord.isErrorQtyConsumed=false;
        selectedRecord.qohError=false;

        let isValid=event.target.checkValidity();
        if(isValid){
            selectedRecord.decimalError=false;
        }
        else{
            selectedRecord.decimalError=true;
        }
        this.checkExtended(selectedRecord);
        //this.calculateQoh(selectedRecord);
    }

    // Handle Labor code
    handleChangeLaborCode(event){
        let Id= event.target.dataset.id;
        let selectedRecord;
        selectedRecord = this.rows.find(data => data.uuid === Id);
        selectedRecord.isErrorLbrc=false;
        selectedRecord.SF_PS_Labor_Code__c=event.target.value;
    }

    handleSellingPriceChange(event){
        let Id= event.target.dataset.id;
        let selectedRecord;
        selectedRecord = this.rows.find(data => data.uuid === Id);
        console.log('Selected Record inside sellingpricechange:: '+JSON.stringify(selectedRecord));
        selectedRecord.SF_PS_Selling_Price__c=event.target.value;
        console.log('Event value:: '+event.target.value);
        selectedRecord.isErrorsellingPrice=false;
        selectedRecord.avgError=false;
        if( selectedRecord.SF_PS_Cost_Price__c && event.target.value<selectedRecord.SF_PS_Cost_Price__c){
            selectedRecord.avgError=true;
        }
        else{
            selectedRecord.avgError=false;
        }
        //Discount Calculation 
		if(selectedRecord.SF_PS_Orig_Selling_Price__c>=0 && selectedRecord.SF_PS_Selling_Price__c>=0 && selectedRecord.SF_PS_Orig_Selling_Price__c >selectedRecord.SF_PS_Selling_Price__c){
			selectedRecord.SF_PS_Discount_Percentage__c=(((selectedRecord.SF_PS_Orig_Selling_Price__c - selectedRecord.SF_PS_Selling_Price__c)/selectedRecord.SF_PS_Orig_Selling_Price__c)*100).toFixed(2);
		}
		else {
			selectedRecord.SF_PS_Discount_Percentage__c=0;
			selectedRecord.isErrorDiscount=false;
		}
        if(this.expenseToLoc=='L'){
            selectedRecord.avgError=false; 
            selectedRecord.isErrorsellingPrice=false;
            selectedRecord.isErrorDiscount=false;
        }
		this.checkExtended(selectedRecord);
        this.handleWarningAndErors(selectedRecord);
    }

    //handleDiscountChange
    //Handle discount change method to calculate selling price based on discount selected 
	handleDiscountChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord;
		let name=event.target.name;
		//selectedRecord = this.rows.find(data => data.uuid === Id);
		console.log('current Selected Record inside discount change::'+JSON.stringify(selectedRecord));
		
		selectedRecord = this.rows.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Discount_Percentage__c = event.target.value;
	
		if(selectedRecord.SF_PS_Discount_Percentage__c >=0 && selectedRecord.SF_PS_Discount_Percentage__c<100){
			selectedRecord.SF_PS_Selling_Price__c=Number((selectedRecord.SF_PS_Orig_Selling_Price__c - (selectedRecord.SF_PS_Orig_Selling_Price__c*selectedRecord.SF_PS_Discount_Percentage__c/100))).toFixed(2);
			selectedRecord.isErrorDiscount=false;
		}
		else{
			selectedRecord.SF_PS_Selling_Price__c= selectedRecord.SF_PS_Orig_Selling_Price__c;
			selectedRecord.isErrorDiscount=true;
		}
		this.checkExtended(selectedRecord);
        this.handleWarningAndErors(selectedRecord);
	}

    // Check Extended rate
    checkExtended(selectedRecord){
        if(this.expenseToLoc=='L'){
            selectedRecord.extended=selectedRecord.SF_PS_Selling_Price__c*selectedRecord.QuantityConsumed
        }
        else if(this.expenseToLoc=='C'||this.expenseToLoc=='$'){
            selectedRecord.extended=selectedRecord.SF_PS_Selling_Price__c*selectedRecord.QuantityConsumed;
        }
    }

    // Handle next click
    @api hanldeNext(){
        console.log("Next screen");
        console.log("ROWS recieved on next action:"+JSON.stringify(this.rows));
        let isAllValidationsError=false;
        console.log('Screen value ::'+ this.screen);
        if(this.screen=='Review' && this.rows.length==1 && !this.rows[0].ProductItemId && !this.rows[0].QuantityConsumed /*&& (this.rows[0].SF_PS_Labor_Code__c==""||this.rows[0].SF_PS_Labor_Code__c=="-")*/) {
            let returnVal={};
            returnVal.isReview=true;
            returnVal.records=[];
            return JSON.stringify(returnVal);
        }
        else{
            for(let i=0 ;i<=this.rows.length-1;i++){
                // Validation for Product # 
                if(this.rows[i].Product2Id==""){
                    this.rows[i].isErrorParts=true;
                }
                else{
                    this.rows[i].isErrorParts=false;
                }

                if(!this.rows[i].PricebookEntryId  && this.rows[i].Product2Id){
                    this.rows[i].isErrorPriceBookEntry=true;
                }
                else{
                    this.rows[i].isErrorPriceBookEntry=false;
                }

                // Validation for Quantity Consumed
                if(this.rows[i].QuantityConsumed==""){
                    this.rows[i].isErrorQtyConsumed=true;
                }
                else{
                    this.rows[i].isErrorQtyConsumed=false;
                }
                // Validation for Labor Code
                if(this.rows[i].SF_PS_Labor_Code__c==""||this.rows[i].SF_PS_Labor_Code__c=="-"){
                    this.rows[i].isErrorLbrc=true;
                }
                else{
                    this.rows[i].isErrorLbrc=false;
                }
                if(this.expenseToLoc=='L'){
                    this.rows[i].isErrorsellingPrice= false;
                    this.rows[i].avgError=false;     
                } else {
                    this.rows[i].isErrorsellingPrice= this.disableSellingPrice ==false ? this.rows[i].SF_PS_Selling_Price__c ?false:true : false;
                    this.rows[i].avgError= this.disableSellingPrice ==false ? this.rows[i].SF_PS_Selling_Price__c<this.rows[i].SF_PS_Cost_Price__c ?true:false : false;
                }
                // Check all fields 
                if( this.rows[i].qohError ||this.rows[i].decimalError||this.rows[i].isErrorsellingPrice||this.rows[i].avgError|| this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts ){
                    isAllValidationsError =true;
                }
            }
        }
        console.log("isAllValidationsError inside next action: "+isAllValidationsError)

        if(isAllValidationsError==false){
            // Sending data to flow
            this.miscellaneousItemsRecord=this.rows;
            if(this.screen=='Review'){
                let returnVal={};
                returnVal.isReview=true;
                returnVal.records=this.rows;
                return JSON.stringify(returnVal);
            }
            else {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }
        }
        else if(this.screen=='Review'){
            return '[]';
        }
    }

    // Handle Cancel Click
    handleCancel(event){
        // Navigation to Account List view(recent)
        let objectName='WorkOrder';
        window.location.href=`${window.location.origin}/lightning/o/${objectName}/list`;
    }

    // Calculate Total
    get calculateTotal(){
        let total=this.rows.reduce((prev,next)=>{
            if(next.extended){
                return Number(next.extended)+Number(prev);
            }
            else{
                return Number(prev);
            }
        },0)


        this.dispatchEvent(new CustomEvent("misctotal",{detail:Number(total).toFixed(2)}));
        return Number(total).toFixed(2);
    }

    // New changes - Pricebook 

    // Handele parts# chnage
    handleProductChange(event){
        if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalculate", { detail: true }));
		}
        let productId= event.detail.selectedRecord.Id;
        let Id= event.target.dataset.id;
        let selectedRecord = this.rows.find(data => data.uuid === Id);
        
        //  Clearing validations
        selectedRecord.isErrorParts=false;
        this.productSfId=productId;
        console.log('Recieved productID:: '+productId);
        if(productId!=undefined){
            if(productId){
                getProductDetails({prodId:productId}).then(data=>{
                    console.log('Recieved Data by wire:: '+ JSON.stringify(data));
                    let result=data.Item;
                    console.log('Id::'+ result.Id);
                    //selectedRecord.SF_PS_Product2Id__c=productId;    
                    //selectedRecord.ProductItemId=productId;
                    selectedRecord.Product2Id=result.Id;
                    //selectedRecord.SF_PS_Product2Id__c=productId;    
                    selectedRecord.ProductItemId=productId;
                    selectedRecord.SF_PS_Unit_Of_Measure__c=result.QuantityUnitOfMeasure;
                    if(this.expenseToLoc=='L'){
                        selectedRecord.SF_PS_Selling_Price__c=0;
                    }else{
                        selectedRecord.SF_PS_Selling_Price__c=result.Sell_Price__c;
                    }
                    selectedRecord.SF_PS_Last_Cost=result.Last_Cost__c;         
                    if(selectedRecord.SF_PS_Selling_Price__c){
                        selectedRecord.isErrorsellingPrice=false;
                    }
                    selectedRecord.SF_PS_List_Price__c=result.List_Price__c;
                    selectedRecord.SF_PS_Orig_Selling_Price__c = result.Sell_Price__c;
                    selectedRecord.Freight_Percentage__c=result.Freight_Percentage__c;
          			selectedRecord.Expected_Profit_Percent__c=result.Expected_Profit_Percent__c;
                    selectedRecord.SF_PS_Cost_Price__c=result.Last_Cost__c;
                    if(data.Item.ProductItems && data.Item.ProductItems.length){
                        let productItemRec=this.getProductItem(data.Item.ProductItems);
                        selectedRecord.SF_PS_Product_Item__c=productItemRec?.Id;
                        selectedRecord.SF_PS_Last_Cost= (productItemRec?.SM_PS_Last_Cost__c>0) ? productItemRec.SM_PS_Last_Cost__c : (result.Last_Cost__c>0 ? result.Last_Cost__c : 0 ); 
                        selectedRecord.SF_PS_Cost_Price__c=selectedRecord.SF_PS_Last_Cost;
                    }
                    selectedRecord.Description=result.Description__c?.length>255?(result.Description__c.substring(0,255)):result.Description__c;
                    selectedRecord.SF_PS_Description__c=result.Description__c?.length>20?((result.Description__c.substring(0,20))+'..'):result.Description__c;
                    selectedRecord.tooltip=result.Product2?.Description__c?.length>20?"tooltip top":"desc"
                    selectedRecord.descTitle=result.Description__c;
                    selectedRecord.Item_Number__c=result.Item_Number__c;
                    selectedRecord.Stock_class__c=result.Stock_class__c;
                    selectedRecord.calculateDiscount=false;
                    let pricebookEntries=data.PricebookEntry;
                    let pricebook=this.handlePricebookEntrySelection(pricebookEntries);
                    console.log('this is pricebook '+pricebook);
                    if(pricebook && pricebook.Id ){
                        selectedRecord.PricebookEntryId=pricebook?.Id;
                        selectedRecord.isErrorPriceBookEntry=false;
                    }
                    else{
                        selectedRecord.isErrorPriceBookEntry=true;
                    }
                    //selectedRecord.PricebookEntryId=pricebook?.Id;

                    this.handleSkipButton();
                    this.checkExtended(selectedRecord);
                    console.log(JSON.stringify(selectedRecord));
                    console.log('ROWS::after product change '+JSON.stringify(rows));

                }).catch(error=>{
                    console.log ('Error inside wire call:: '+JSON.stringify(error))
                })
            }
        }else{
            selectedRecord.ProductItemId="";
            selectedRecord.SF_PS_Unit_Of_Measure__c="";
            selectedRecord.SF_PS_Selling_Price__c="";
            selectedRecord.SF_PS_List_Price__c="";
            selectedRecord.SF_PS_Cost_Price__c="";
            selectedRecord.SF_PS_Orig_Selling_Price__c="";
            selectedRecord.SF_PS_Discount_Percentage__c="";
            selectedRecord.Description="";
			selectedRecord.tooltip=""
            //selectedRecord.QuantityOnHand="";
            selectedRecord.extended=0
            this.isProductItemSelected=false;
            selectedRecord.PricebookEntryId="";
            selectedRecord.Product2Id="";
            selectedRecord.QuantityConsumed="";
            selectedRecord.isErrorPriceBookEntry=false;
            selectedRecord.avgError=false;
            selectedRecord.Freight_Percentage__c="";
          	selectedRecord.Expected_Profit_Percent__c="";
			selectedRecord.warningError = false;
			selectedRecord.minPriceError = false;
			selectedRecord.isErrorDiscount = false;
            selectedRecord.calculateDiscount=false;
            selectedRecord.SF_PS_Description__c="";
            selectedRecord.SF_PS_Description__c="";
            selectedRecord.descTitle="";


            this.handleSkipButton();
        }
    }

    //Get productItem as per location for misc items
    getProductItem(productItems){
        let productItem=productItems.filter(item=>{
           return (item.Location.Branch_Location_Number__c==this.branchLoc && item.Location.Company_Code__c==this.companyCode)
        })
        return productItem.length>0 ? productItem[0] : productItem;
    }

    // To handle price book entry selection
    handlePricebookEntrySelection(priceBookentries){
        for(let pb in priceBookentries){
            console.log("Company code "+this.companyCode);
            if(this.companyCode=='01' && priceBookentries[pb].CurrencyIsoCode=="USD"){
                console.log("USA "+JSON.stringify(priceBookentries[pb]));
                return priceBookentries[pb];
            }
            else if(this.companyCode=='02' && priceBookentries[pb].CurrencyIsoCode=="CAD"){
                console.log("CAD "+JSON.stringify(priceBookentries[pb]));
                return priceBookentries[pb];
            }
        }
        return null;
    }

    // To handle Skip Button show and hide
    handleSkipButton(){
        console.log('screen name'+this.screen);
        if(this.screen!='Review'){
        var comp = this.template.querySelector('c-sbr_3_0_sfs-desktop-flow-buttons');
            for(let i=0 ;i<=this.rows.length-1;i++){
                console.log('product item'+JSON.stringify(this.rows[i]));
                if(this.rows[i].ProductItemId){
                    comp.showSkipButton=false;
                    console.log('inside if skip');
                    break;
                }
                else{
                    console.log('inside else skip');
                    comp.showSkipButton=true;
                }
            }
        }
    }
    
    handleSummary(){
        console.log('product consume data is DT' + this.rows);
        this.skiptoSummary = true;
        this.skiptoSummaryPage = true;
        /* const attributeChangeEvent = new FlowAttributeChangeEvent('skiptosummary', this.skiptoSummary);
        this.dispatchEvent(attributeChangeEvent);*/
        console.log('product item id DT' + this.rows[0].ProductItemId);
        if(this.rows[0].ProductItemId != "" || this.rows.length > 1){
            this.hanldeNext();
            console.log('inside NEXT DT');
        }
        else{
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    //get discount detail by API Calluots
	async handleCalculateDiscount(){
		if(this.screen == 'Review'){
			await this.validateErrorMethod();
		}
		else {
			this.validationsErrorFound = false;
		}

		if(this.validationsErrorFound == true){
			//Show error msg
		}
		else {
			console.log('click on calculate discount');
			this.dispatchEvent(new CustomEvent("taxcalculate", { detail: false}));
			// send JSON To Apex and get data for discount calculation for calculateDiscount = false raws
		}
	}

    validateErrorMethod(){
		this.validationsErrorFound = false;
		for (let i = 0; i < this.rows.length; i++) {
			// Validation for Parts # 
			if(this.rows[i].Product2Id == ""){
				this.rows[i].isErrorParts = true;
			} 
			else{
				this.rows[i].isErrorParts = false;
			}

			if(!this.rows[i].PricebookEntryId && this.rows[i].Product2Id && this.displayQOH){
				this.rows[i].isErrorPriceBookEntry = true;
			} 
			else{
				this.rows[i].isErrorPriceBookEntry = false;
			}
			
			// Validation for Quantity Consumed
			if(this.rows[i].QuantityConsumed == ""){
				this.rows[i].isErrorQtyConsumed = true;
			} 
			else{
				this.rows[i].isErrorQtyConsumed = false;
			}
			// Validation for Labor Code
			if(this.rows[i].SF_PS_Labor_Code__c == "" || this.rows[i].SF_PS_Labor_Code__c == "-"){
				this.rows[i].isErrorLbrc = true;
			} 
			else{
				this.rows[i].isErrorLbrc = false;
			}

			if(this.screen == "Review"){
				this.rows[i].isErrorsellingPrice = this.rows[i].SF_PS_Selling_Price__c != '' ? false : true;
			}
			
			//this.rows[i].avgError = this.rows[i].SF_PS_Selling_Price__c < this.rows[i].SF_PS_Cost_Price__c ? true : false;
			
			// Check all fields 
			if(this.rows[i].isErrorsellingPrice || this.rows[i].isErrorPriceBookEntry || this.rows[i].decimalError || this.rows[i].avgError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts || this.rows[i].minPriceError || this.rows[i].isErrorDiscount) {
				
				this.validationsErrorFound = true;
			}
		}
	}

    handleWarningAndErors(selectedRecord){
		//Last_Cost__c
		let warningPrice=selectedRecord.SF_PS_Last_Cost+((selectedRecord.Expected_Profit_Percent__c*selectedRecord.SF_PS_Last_Cost)/100);
		let errorPrice =selectedRecord.SF_PS_Cost_Price__c+((selectedRecord.Freight_Percentage__c*selectedRecord.SF_PS_Cost_Price__c)/100);
		selectedRecord.SF_PS_Warning_Price__c=warningPrice;
		selectedRecord.SF_PS_Error_Price__c=errorPrice;
		console.log('warning price= '+ selectedRecord.SF_PS_Warning_Price__c);
		console.log('error price= '+ selectedRecord.SF_PS_Error_Price__c);
		
		// Error
		if(this.expenseToLoc!='L' && (selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Error_Price__c) && !this.priceReadOnly){
			selectedRecord.minPriceError = true;
		}
		else{
			selectedRecord.minPriceError = false;
		}
			
		if( this.expenseToLoc!='L' && selectedRecord.SF_PS_Cost_Price__c && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Cost_Price__c && !this.priceReadOnly){
			selectedRecord.avgError = true;
			//selectedRecord.avgErrorMessage='Selling price cannot be more than avg price';
		}
		else{
			selectedRecord.avgError = false;
		}
		// Warning
		if((this.expenseToLoc!='L' && !selectedRecord.minPriceError && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Warning_Price__c) && !this.priceReadOnly){
			selectedRecord.warningError = true;
		}
		else{
			selectedRecord.warningError = false;
		}
	}
}