import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import getProductItemDetails from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getProductItemDetails'
import { FlowNavigationBackEvent, FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from "lightning/flowSupport";
import { NavigationMixin } from 'lightning/navigation';
import getPricebookentriesFrmProd from '@salesforce/apex/Sbr_3_0_sfsDesktopPartsCmpController.getPricebookEntriesForProd';
import warningForSellingPrice from '@salesforce/label/c.Message_For_Selling_Price';

export default class Sbr_3_0_sfsDesktopPartsCmp extends NavigationMixin(LightningElement) {
	//public properties exposed as API
	@api recordToBeDeleted;
	@api screen;
	@api additionalQuery;
	@api baseUrlFromFlow;
	@api companyCode;
	@api branchLoc;
	@api expenseToLoc
	@api default;
	@api defaultInventory;
	@api defaultLaborCode;
	@api skiptoSummary;
	@api skiptoSummaryPage = false;
	@api woType = 'Inspection';
	@api productConsumedRecord = [];
	@api inventoryProductConsumedRecord = [];
	@api columnList;
	@api withoutInventoryColumnList;
	@api title = "Parts";
	@api titleWithoutInventory="Non-Stocked Parts";
	@api workOrder;
	@api workOrderDescription;
	isWODescWarranty = false;

	validationsErrorFound;
	productItemSfId;
	showButtons;
	displayQOH = true;
	displayPartsWithoutInventory = true;
	isProductItemSelected = false;
	desc = '-';
	uom = '-';
	sellPrice = 0;
	listPrice = 0;
	sellPriceDisplay = '-'
	listPriceDisplay = '-'
	avgCost = 0
	qtyOnHand = '-'
	productName = '-'
	binLoc = '-'
	stockClass = '-'
	itemNum = '-'
	quantityConsumedValue = 0
	extended = '-'
	extendedVal = '-';
	isErrorParts = false;
	isErrorLbrc = false;
	isErrorQtyConsumed = false;
	isErrorForSellingPrice = false;
	isErrorDescription = false;
	isErrorCostPrice = false;
	qohError = false;
	isErrorOriginalSellPrice = false;
	isReviewScreen=false;
	prevURL = '';
	partsTotal;
	columns;
	picklistValues = []
	priceReadOnly=true;
	sellPriceWarning=warningForSellingPrice;
	isNotPartsWithoutInventory = true;
	isNotPartsWithInventory = true;
	isPartsBothInventory = true;
	newSellPriceReadOnly = false;
	discountPercentageReadOnly = false;
	originalSellPriceReadOnly = false;
	listPriceReadOnly = false;
	isAllValidationsError = false;
	partsNull = false;
	partsWithoutInventoryNull = false;
	isAddNewLineItemClicked = false;
	hideDiscountForL = true;

	@track isNextScreen = true;
	@track rows;
	@track rowsWithoutInventory;
	@track pcLaborCodes;
	//To create new row with these fields for Inventory Items
	newRecord = {
		"SF_PS_Parts_Type__c" : 'Inventory',
		"QuantityConsumed": '',
		"ProductItemId": '',
		"Description": '',
		"SF_PS_Unit_Of_Measure__c": '',
		"SF_PS_Selling_Price__c": '',
		"SF_PS_List_Price__c": '',
		"SF_PS_Orig_Selling_Price__c": '',
		"SF_PS_Discount_Percentage__c": '',
		"SF_PS_Cost_Price__c": '',
		"SF_PS_Labor_Code__c": '',
		"PricebookEntryId": '',
		"Product2Id": "",
		"tooltip":"",
		"SF_PS_ItemType__c": 'P',
		"minPriceError": false,
		"isErrorDiscount": false,
		"avgError": false,
		"attributes": {
		"type": "ProductConsumed",
		"url": ""
		},
		"avgErrorMessage": "Selling price cannot be less than avg price",
		"calculateDiscount" : false
	}
	//To create new row with these fields for non-inventory
	newRecordWithoutInventory = {
		"SF_PS_Parts_Type__c" : 'Without Inventory',
		"SF_PS_Part_Num__c":'',
		"QuantityConsumed": '',
		"ProductItemId": '',
		"Description": '',
		"SF_PS_Unit_Of_Measure__c": 'EA',
		"SF_PS_Orig_Selling_Price__c":'',
		"SF_PS_Labor_Code__c": '',
		"SF_PS_List_Price__c":'',
		"SF_PS_Selling_Price__c": '',
		"SF_PS_Discount_Percentage__c":'',
		"SF_PS_Cost_Price__c": '',
		"PricebookEntryId": '',
		"Product2Id": "",
		"SF_PS_ItemType__c": 'P',
		"minPriceError": false,
		"isErrorDiscount": false,
		"avgError": false,
		"attributes": {
		"type": "ProductConsumed",
		"url": ""
		},
		"avgErrorMessage": "Selling price cannot be less than avg price",
		"calculateDiscount" : false
	}

	//To get WOLI Object metadata 
	@wire(getObjectInfo, { objectApiName: PC_OBJECT })
	pcInfo;
	
	// Pickilist work order description 
	@wire(getPicklistValues, {
		recordTypeId: '$pcInfo.data.defaultRecordTypeId',
		fieldApiName: 'ProductConsumed.SF_PS_Labor_Code__c'
	}) WorkOrderDescValues({ error, data }) {
		console.log(data);
		console.log(this.pcInfo);
		if (data) {
			this.pcLaborCodes=[...data.values];
		} else {
		console.log(JSON.stringify(error));
		}
	}
	
	// Connected call back 
	connectedCallback(){
		this.withoutInventoryColumnList= [	
											{ "label": "Part #", "apiName": "SF_PS_Part_Num__c" },
											{ "label": "Description", "apiName": "Description" },
											{ "label": "UM", "apiName": "SF_PS_Unit_Of_Measure__c" },
											{ "label": "Labor Code", "apiName": "SF_PS_Labor_Code__c" },
											{ "label": "Qty", "apiName": "QuantityConsumed" },
											{ "label": "List Price/unit", "apiName": "SF_PS_List_Price__c" },
											{ "label": "Orig Sell Price", "apiName": "SF_PS_Orig_Selling_Price__c" },
											{ "label": "Disc%", "apiName": "SF_PS_Discount_Percentage__c" },
											{ "label": "New Sell Price/unit", "apiName": "SF_PS_Selling_Price__c" },
											{ "label": "Cost/unit", "apiName": "SF_PS_Cost_Price__c" },
											{ "label": "Ext Amount", "apiName": "Selling_Price__c" },
										];

		// For inspection check , display QOH or not
		if (this.woType == 'Inspection') {
			this.isWODescWarranty = this.workOrderDescription === 'WARRANTY' ? true : false;
			this.displayQOH = true;
			this.displayPartsWithoutInventory = false;
			// Column list 
			this.columnList = this.isWODescWarranty ? [	
								{ "label": "Part #", "apiName": "ProductItemId" },
								{ "label": "Description", "apiName": "Description" },
								{ "label": "UM", "apiName": "SF_PS_Unit_Of_Measure__c" },
								{ "label": "Labor Code", "apiName": "SF_PS_Labor_Code__c" },
								{ "label": "Is Primarty Part?", "apiName": "SF_PS_Is_Primary_Part__c" },
								{ "label": "Qty", "apiName": "QuantityConsumed" },
								{ "label": "List Price/unit", "apiName": "SF_PS_List_Price__c" },
								{ "label": "Orig Sell Price", "apiName": "SF_PS_Orig_Selling_Price__c" },
								{ "label": "Disc%", "apiName": "SF_PS_Discount_Percentage__c" },
								{ "label": "New Sell Price/unit", "apiName": "SF_PS_Selling_Price__c" },
								{ "label": "Cost/unit", "apiName": "SF_PS_Cost_Price__c" },
								{ "label": "Ext Amount", "apiName": "Selling_Price__c" },
							] : 
							[	
								{ "label": "Part #", "apiName": "ProductItemId" },
								{ "label": "Description", "apiName": "Description" },
								{ "label": "UM", "apiName": "SF_PS_Unit_Of_Measure__c" },
								{ "label": "Labor Code", "apiName": "SF_PS_Labor_Code__c" },
								{ "label": "Qty", "apiName": "QuantityConsumed" },
								{ "label": "List Price/unit", "apiName": "SF_PS_List_Price__c" },
								{ "label": "Orig Sell Price", "apiName": "SF_PS_Orig_Selling_Price__c" },
								{ "label": "Disc%", "apiName": "SF_PS_Discount_Percentage__c" },
								{ "label": "New Sell Price/unit", "apiName": "SF_PS_Selling_Price__c" },
								{ "label": "Cost/unit", "apiName": "SF_PS_Cost_Price__c" },
								{ "label": "Ext Amount", "apiName": "Selling_Price__c" },
							];
		}
		else{
			this.displayQOH = false;
			this.displayPartsWithoutInventory = true;
			
			// Column list 
			this.columnList = [ 
								{ "label": "Part #", "apiName": "ProductItemId" },
								{ "label": "Description", "apiName": "Description" },
								{ "label": "UM", "apiName": "SF_PS_Unit_Of_Measure__c" },
								{ "label": "Labor Code", "apiName": "SF_PS_Labor_Code__c" },
								{ "label": "Qty", "apiName": "QuantityConsumed" },
								{ "label": "List Price/unit", "apiName": "SF_PS_List_Price__c" },
								{ "label": "Orig Sell Price", "apiName": "SF_PS_Orig_Selling_Price__c" },
								{ "label": "Disc%", "apiName": "SF_PS_Discount_Percentage__c" },
								{ "label": "New Sell Price/unit", "apiName": "SF_PS_Selling_Price__c" },
								{ "label": "Cost/unit", "apiName": "SF_PS_Cost_Price__c" },
								{ "label": "Ext Amount", "apiName": "Selling_Price__c" },
							];
		}

		if(this.defaultLaborCode) {
			console.log('Default Labour code::', this.defaultLaborCode);
			this.newRecord.SF_PS_Labor_Code__c = this.defaultLaborCode;
			this.newRecordWithoutInventory.SF_PS_Labor_Code__c = this.defaultLaborCode;
		}
		// this.additionalQuery=` and Location.Company_Code__c='${this.companyCode}' and Location.Branch_Location_Number__c='${this.branchLoc}' and QuantityOnHand>0 `;
		this.additionalQuery = `Location.Company_Code__c='${this.companyCode}' and (Product2.Product_Type__c like '%Parts%' OR Product2.Product_Type__c like '%Merch%') and Location.Branch_Location_Number__c='${this.branchLoc}' `;
		console.log(this.additionalQuery);
		console.log('this is exp ' + this.expenseToLoc);
		console.log('default: ' + JSON.stringify(this.default));
		
		if (this.screen == "Review") {
			if(this.expenseToLoc == 'L'){
				this.hideDiscountForL = true;
				this.priceReadOnly=true;
			}else {
				this.hideDiscountForL = false;
				this.priceReadOnly=false;
			}
			this.showButtons = false;
			this.newSellPriceReadOnly=false;
			this.isReviewScreen=true;
		} 
		else {
			this.showButtons = true;
			this.priceReadOnly=true;
			this.isReviewScreen=false;
		}
        // with inventory
		if(this.default){
			this.rows = JSON.parse(JSON.stringify(this.default));
			console.log(this.rows);
			console.log('default: ' + JSON.stringify(this.default));
		}
		else{
			this.initData();
		}
		//without inventory
		if(this.woType != 'Inspection'){
			this.checkBillCustOrLoc();
			if(this.defaultInventory){
				this.rowsWithoutInventory = JSON.parse(JSON.stringify(this.defaultInventory));
				console.log(this.rowsWithoutInventory);
				console.log('defaultInventory: ' + JSON.stringify(this.defaultInventory));
			}
			else{
				this.initDataNonInventory();
			}
		}
	}
	//To Check billcust TO location and set flags accordingly
	checkBillCustOrLoc(){
		if(this.screen == "Review"){
			this.originalSellPriceReadOnly= true;
			this.newSellPriceReadOnly = false;
			this.listPriceReadOnly = true;
			if(this.expenseToLoc == 'L'){
				this.discountPercentageReadOnly = true;
				this.newSellPriceReadOnly = true;
			}
			else{
				this.discountPercentageReadOnly = false;
			}
		}

		if(this.screen != "Review"){
			this.discountPercentageReadOnly = true;
			this.newSellPriceReadOnly = true;
			if(this.expenseToLoc == 'L'){
				this.originalSellPriceReadOnly = true;
			}
			else{
				this.originalSellPriceReadOnly = false;
			}

		}
	}

	// To init rows and other data
	initData(){
		this.rows = [];
		this.createRow();
	}

	// To init rows and other data for non-inventory
	initDataNonInventory(){
		this.rowsWithoutInventory = [];
		this.createWithoutInventoryRow();
	}

	// To create new row 
	createRow(){
		let obj = JSON.parse(JSON.stringify(this.newRecord));
		obj.uuid = this.createUUID();
		if(this.rows.length > 0){
			obj.index = this.rows[this.rows.length - 1].index + 1;
		}
		else{
			obj.index = 1;
		}
		this.rows.push(obj);
		console.log('parts uid is'+obj.uuid);
	}

	// To create new row 
	createWithoutInventoryRow(){
		let obj = JSON.parse(JSON.stringify(this.newRecordWithoutInventory));
		obj.uuid = this.createUUID();
		if(this.rowsWithoutInventory.length > 0){
			obj.index = this.rowsWithoutInventory[this.rowsWithoutInventory.length - 1].index + 1;
		}
		else{
			obj.index = 1;
		}
		this.rowsWithoutInventory.push(obj);
		console.log('without inventory id'+obj.uuid);
	}

	// Create rwo unique UUID
	createUUID(){
		// var dt = new Date().getTime();
		// var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
		// 	var r = (dt + Math.random() * 16) % 16 | 0;
		// 	dt = Math.floor(dt / 16);
		// 	return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
		// });
		// return uuid;
		let id=Date.now().toString(36) + Math.floor(Math.pow(10, 12) + Math.random() * 9*Math.pow(10, 12)).toString(36);
		return id;
	}

	// To remove row
	removeRow(event){
		let name=event.target.name;
		if(name=="partsWithoutInventory"){
			if(this.rowsWithoutInventory.length > 1){
				this.rowsWithoutInventory.splice(event.target.value, 1);
				this.handleSkipButton();
			}
		}
		else{
			if(this.rows.length > 1){
				this.rows.splice(event.target.value, 1);
				this.handleSkipButton();
				if(this.hideDiscountForL== false){
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
	}
	// To add row and validate
	addRow(){
		if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalculate", { detail: true }));
		}
		console.log("ROWS Before:" + JSON.stringify(this.rows));
		// To check all validations
		let isAllValidationsError = false;
		for (let i = 0; i < this.rows.length; i++) {
			console.log("ROWS Before1");
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
				console.log("ROWS Before3");
			} 
			else{
				this.rows[i].isErrorQtyConsumed = false;
				console.log("ROWS Before3");
			}

			// Validation for Labor Code
			if(this.rows[i].SF_PS_Labor_Code__c == "" || this.rows[i].SF_PS_Labor_Code__c == "-"){
				this.rows[i].isErrorLbrc = true;
				console.log("ROWS Before4");
			} 
			else{
				this.rows[i].isErrorLbrc = false;
				console.log("ROWS Before4");
			}

			if(this.screen == "Review"){
				this.rows[i].isErrorsellingPrice = this.rows[i].SF_PS_Selling_Price__c ? false : true;
			}
			
			//this.rows[i].avgError = this.rows[i].SF_PS_Selling_Price__c < this.rows[i].SF_PS_Cost_Price__c ? true : false;
			
			// Check all fields 
			if(this.rows[i].isErrorsellingPrice || this.rows[i].isErrorPriceBookEntry || this.rows[i].decimalError || this.rows[i].avgError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts || this.rows[i].minPriceError || this.rows[i].isErrorDiscount) {
				
				isAllValidationsError = true;
			}
			console.log("ROWS Before4");
		}
		
		console.log("isAllValidationsError Rows: " + isAllValidationsError)
		if (isAllValidationsError == false) {
			this.rows.push({ uuid: this.createUUID(), ...this.newRecord });
		}
		console.log("ROWS:" + JSON.stringify(this.rows));
	}


	addWithoutInventoryRow(){
		if(this.screen =='Review' && this.expenseToLoc == 'C'){
			this.originalSellPriceReadOnly=false;
		}
		
	    //this.checkBillCustOrLoc();
        console.log("ROWS Before:" + JSON.stringify(this.rowsWithoutInventory));
		// To check all validations
		let isAllValidationsErrorWithoutInventory = false;
		for (let i = 0; i < this.rowsWithoutInventory.length; i++) {
			console.log("ROWS Before1");
			// Validation for Parts # 
			if(this.rowsWithoutInventory[i].SF_PS_Part_Num__c == ""){
				this.rowsWithoutInventory[i].isErrorPartsNumber= true;
				console.log("ROWS Before3");
			} 
			else{
				this.rowsWithoutInventory[i].isErrorPartsNumber = false;
				console.log("ROWS Before3");
			}
			// Validation for Description
			if(this.rowsWithoutInventory[i].Description == ""){
				this.rowsWithoutInventory[i].isErrorDescription= true;
				console.log("ROWS Before3");
			} 
			else{
				this.rowsWithoutInventory[i].isErrorDescription = false;
				console.log("ROWS Before3");
			}
	
			// Validation for Quantity Consumed
			if(this.rowsWithoutInventory[i].QuantityConsumed == ""){
				this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory = true;
				console.log("ROWS Before3");
			} 
			else{
				this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory = false;
				console.log("ROWS Before3");
			}
				// Validation for Cost Price
			if(this.rowsWithoutInventory[i].SF_PS_Cost_Price__c == ""){
					this.rowsWithoutInventory[i].isErrorCostPrice = true;
					console.log("ROWS Before3");
			} 
			else{
					this.rowsWithoutInventory[i].isErrorCostPrice = false;
					console.log("ROWS Before3");
			}
			// Validation for Labor Code
			if(this.rowsWithoutInventory[i].SF_PS_Labor_Code__c == "" || this.rowsWithoutInventory[i].SF_PS_Labor_Code__c == "-"){
				this.rowsWithoutInventory[i].isErrorLbrc = true;
				console.log("ROWS Before4");
			} 
			else{
				this.rowsWithoutInventory[i].isErrorLbrc = false;
				console.log("ROWS Before4");
			}
			// Validation for orginal sell price
			if(this.expenseToLoc == 'C' && this.rowsWithoutInventory[i].SF_PS_Orig_Selling_Price__c ==""){
				this.rowsWithoutInventory[i].isErrorOriginalSellPrice = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorOriginalSellPrice = false;
			}
			
			// Check all fields 
			if( this.rowsWithoutInventory[i].isErrorLbrc || this.rowsWithoutInventory[i].isErrorQtyConsumed|| this.rowsWithoutInventory[i].isErrorOriginalSellPrice || this.rowsWithoutInventory[i].isErrorCostPrice || this.rowsWithoutInventory[i].isErrorDescription || this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory)  {
				
				isAllValidationsErrorWithoutInventory = true;
			}
			console.log("ROWS Before4");
		}
		
		console.log("isAllValidationsError Rows: " + isAllValidationsErrorWithoutInventory)
		if (isAllValidationsErrorWithoutInventory == false) {
			this.rowsWithoutInventory.push({ uuid: this.createUUID(), ...this.newRecordWithoutInventory });
		}
		console.log("ROWS:" + JSON.stringify(this.rowsWithoutInventory));
	
		/*console.log("ROWS Before:" + JSON.stringify(this.rowsWithoutInventory));
		this.rowsWithoutInventory.push({ uuid: this.createUUID(), ...this.newRecordWithoutInventory });*/
	}

	// Handele parts# chnage
	handleProductItemChange(event){
		if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalculate", { detail: true }));
		}
		let productItemId = event.detail.selectedRecord.Id;
		let Id = event.target.dataset.id;
		console.log(Id);
		console.log("Test")
		let selectedRecord = this.rows.find(data => data.uuid === Id);
		//  Clearing validations
		selectedRecord.isErrorParts = false;
		this.productItemSfId = productItemId;
		//console.log(productItemId);
		if (productItemId != undefined) {
			this.isProductItemSelected = true;
			if(productItemId){
				getProductItemDetails({ productItemId: productItemId }).then(data => {
					let result = data.Item;
					console.log(data);
					selectedRecord.ProductItemId = productItemId
					selectedRecord.SF_PS_Unit_Of_Measure__c = result.Product2.QuantityUnitOfMeasure;
					selectedRecord.SF_PS_Selling_Price__c = result.Product2.Sell_Price__c;
					selectedRecord.SF_PS_Orig_Selling_Price__c = result.Product2.Sell_Price__c;
					selectedRecord.SF_PS_Discount_Percentage__c = 0;
					if (selectedRecord.SF_PS_Selling_Price__c) {
						selectedRecord.isErrorsellingPrice = false;
					}
					selectedRecord.Product2Id = result.Product2Id;
					selectedRecord.calculateDiscount = false;
					selectedRecord.SF_PS_Product_Item__c = productItemId
					selectedRecord.SF_PS_List_Price__c = result.Product2.List_Price__c;
					selectedRecord.SF_PS_Cost_Price__c = result.SM_PS_Average_Cost__c>0 ? result.SM_PS_Average_Cost__c : ( result.SM_PS_Last_Cost__c> 0 ? result.SM_PS_Last_Cost__c : 0);
					selectedRecord.Description=result.Product2?.Description__c?.length>255?(result.Product2.Description__c.substring(0,255)):result.Product2?.Description__c;
                    selectedRecord.SF_PS_Description__c=result.Product2?.Description__c?.length>20?((result.Product2.Description__c.substring(0,20))+'..'):result.Product2?.Description__c;
                    selectedRecord.tooltip=result.Product2?.Description__c?.length>20?"tooltip top":"desc"
					selectedRecord.descTitle=result.Product2.Description__c;
                   
					selectedRecord.SF_PS_Last_Cost = result?.SM_PS_Last_Cost__c>0 ? result.SM_PS_Last_Cost__c : (result?.Product2.Last_Cost__c > 0 ? result.Product2.Last_Cost__c : 0 );
          			selectedRecord.Freight_Percentage__c=result.Product2.Freight_Percentage__c;
          			selectedRecord.Expected_Profit_Percent__c=result.Product2.Expected_Profit_Percent__c;
          			selectedRecord.Item_Number__c=result.Product2.Item_Number__c;
          			selectedRecord.Stock_class__c=result.Product2.Stock_class__c;
					console.log('Freight_Percentage__c '+ selectedRecord.Freight_Percentage__c);
          			console.log('Expected_Profit_Percent__c '+ selectedRecord.Expected_Profit_Percent__c);
          			this.handleWarningAndErors(selectedRecord);
					//selectedRecord.QuantityOnHand=result.QuantityOnHand;
					selectedRecord.SM_PS_Quantity_Available__c = result.SM_PS_PartsMerch_Available_Quantity__c;
					
					let pricebookEntries = data.PricebookEntry;
					let pricebook = this.handlePricebookEntrySelection(pricebookEntries);
					if (this.displayQOH) {
						console.log(pricebook);
						if(pricebook && pricebook.Id){
							selectedRecord.PricebookEntryId = pricebook?.Id;
							selectedRecord.isErrorPriceBookEntry = false;
						}
						else{
							selectedRecord.isErrorPriceBookEntry = true;
						}
					}
					else{
						selectedRecord.isErrorPriceBookEntry = false;
					}
					if(selectedRecord.SF_PS_Discount_Percentage__c<0 && selectedRecord.SF_PS_Discount_Percentage__c>100){
						selectedRecord.isErrorDIscount = true;
					}

					this.handleSkipButton();
					this.checkExtended(selectedRecord);
					
					// if(this.woType=='Inspection')
					// {
					// this.calculateQoh(selectedRecord);
					// }
					
					console.log(result);
					console.log(JSON.stringify(selectedRecord));
					console.log('ROWS ' + JSON.stringify(rows));
					
				}).catch(error => {
					console.log(JSON.stringify(error))
				})
			
			}
		}
		else{
			selectedRecord.ProductItemId = "";
			selectedRecord.SF_PS_Unit_Of_Measure__c = "";
			selectedRecord.SF_PS_Selling_Price__c = "";
			selectedRecord.SF_PS_List_Price__c = "";
			selectedRecord.SF_PS_Orig_Selling_Price__c = "";
			selectedRecord.SF_PS_Discount_Percentage__c = "";
			selectedRecord.SF_PS_Cost_Price__c = "";
			selectedRecord.Description = "";
			selectedRecord.QuantityOnHand = "";
			selectedRecord.extended = 0
			selectedRecord.tooltip=""
			selectedRecord.QuantityConsumed = "";
			this.isProductItemSelected = false;
			selectedRecord.SM_PS_Quantity_Available__c = "";
			selectedRecord.PricebookEntryId = "";
			selectedRecord.Product2Id = "";
			selectedRecord.isErrorPriceBookEntry = false;
			selectedRecord.Freight_Percentage__c="";
          	selectedRecord.Expected_Profit_Percent__c="";
			selectedRecord.warningError = false;
			selectedRecord.minPriceError = false;
			selectedRecord.isErrorDiscount = false;
			selectedRecord.calculateDiscount=false;
			selectedRecord.SF_PS_Description__c="";
			selectedRecord.descTitle="";

			if(this.isWODescWarranty) {
				selectedRecord.SF_PS_Is_Primary_Part__c = false;
			}

			this.handleSkipButton();
		}
	}

	//calculate qoh
	calculateQoh(selectedRecord){
		let qoh = selectedRecord.QuantityOnHand;
		let quantity = selectedRecord.QuantityConsumed
		//let filteredRows=this.rows.filter(row=>row.ProductItemId==selectedRecord.ProductItemId);
		let total = this.rows.reduce((prev, next) => {
			if(next.ProductItemId == selectedRecord.ProductItemId){
				return Number(prev) + Number(next.QuantityConsumed)
			}
			else{
				return Number(prev);
			}
		}, 0)
		if(qoh < total){
			selectedRecord.qohError = true;
			selectedRecord.qohErrorMessage = `Entered Quantity exceeds Quantity On hand `;
		}
		else{
			selectedRecord.qohError = false;
			selectedRecord.qohErrorMessage = ""
		}
	}

	// Handle Primary Part selection
	handleChangePrimaryPart(event) {
		let rowId = event.target.dataset.id;
		// if(event.target.checked) {
			this.rows = this.rows.map(row => {
				return { 
					...row,
					SF_PS_Is_Primary_Part__c: row.uuid === rowId ? event.target.checked : false,
				}
			});
		// }
	}

	// Handle quantity chnage
	handleQuantityChange(event){
		/*if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalucate", { detail: true }));
		}*/
		let Id = event.target.dataset.id;
		console.log(Id);
		let name=event.target.name;
		console.log('name inside quantity'+name);
		let selectedRecord;
		if(name=="partsWithoutInventory"){
			selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);

		}
		else{
		selectedRecord = this.rows.find(data => data.uuid === Id);
		}
		// clearing validation
		selectedRecord.QuantityConsumed = event.detail.value;
		selectedRecord.isErrorQtyConsumed = false;
		selectedRecord.isErrorQtyConsumedWithoutInventory = false;
		selectedRecord.qohError = false;
		let isValid = event.target.checkValidity();
		if(isValid){
			selectedRecord.decimalError = false;
		}
		else{
			selectedRecord.decimalError = true;
		}
		this.checkExtended(selectedRecord);
		// if(this.woType=='Inspection'){
		//   this.calculateQoh(selectedRecord);
		// }
	}

	handlePartNumberChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Part_Num__c = event.detail.value;
		selectedRecord.Item_Number__c=event.detail.value;
		selectedRecord.isErrorPartsNumber = false;
		if(selectedRecord.SF_PS_Part_Num__c ==""){
			selectedRecord.Description="";
			selectedRecord.SF_PS_Unit_Of_Measure__c="";
			selectedRecord.QuantityConsumed="";
			selectedRecord.SF_PS_List_Price__c="";
			selectedRecord.SF_PS_Orig_Selling_Price__c="";
			selectedRecord.SF_PS_Discount_Percentage__c="";
			selectedRecord.SF_PS_Selling_Price__c="";
			selectedRecord.SF_PS_Cost_Price__c="";
			selectedRecord.extended="";
		}
		this.handleSkipButton();
		
	}

	handleDescriptionChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.Description = event.detail.value;
		selectedRecord.isErrorDescription = false;
		console.log('description value is'+selectedRecord.Description);
    }

	handleChangeLaborCode(event){
		let Id = event.target.dataset.id;
		let selectedRecord;
		selectedRecord = this.rows.find(data => data.uuid === Id);
		selectedRecord.isErrorLbrc = false;
		selectedRecord.SF_PS_Labor_Code__c = event.target.value;
	}

	handleTooltip(event)
	{
		
		if(tooltip){
			tooltip.classList.toggle("toggle");

		}
	}
	handleMouseover(event) {
		let target=event.target;
		console.log(target);
		//let tooltip=target.querySelector('[data-id="tooltip"]')
		let tooltip=event.target.nextElementSibling;
		console.log(tooltip);
		if(tooltip){
		tooltip.classList.remove('slds-transition-hide');
		tooltip.classList.add('slds-transition-show');
		}
	}
	
	handleMouseLeave(event) {
		let target=event.target;
		console.log(target);
		 let tooltip=event.target.nextElementSibling;
		//`let tooltip=target.querySelector('[data-id="tooltip"]')
		console.log(tooltip);
		if(tooltip){
			tooltip.classList.remove('slds-transition-show');
			tooltip.classList.add('slds-transition-hide');
		}
	}

	handleCostPriceChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Cost_Price__c = event.detail.value;
		selectedRecord.isErrorCostPrice = false;
		this.checkExtended(selectedRecord);
	}

	handleListPriceChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_List_Price__c = event.detail.value;
	}

	handleOriginalSellingPriceChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Orig_Selling_Price__c = event.detail.value;
		selectedRecord.SF_PS_Selling_Price__c= event.detail.value;
		selectedRecord.isErrorOriginalSellPrice = false;
		this.checkExtended(selectedRecord);
	}

	handleNewSellPriceChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Selling_Price__c = event.detail.value;

		//Discount Calculation 
		if(selectedRecord.SF_PS_Orig_Selling_Price__c>=0 && selectedRecord.SF_PS_Selling_Price__c>=0 && selectedRecord.SF_PS_Orig_Selling_Price__c >selectedRecord.SF_PS_Selling_Price__c){
			selectedRecord.SF_PS_Discount_Percentage__c=(((selectedRecord.SF_PS_Orig_Selling_Price__c - selectedRecord.SF_PS_Selling_Price__c)/selectedRecord.SF_PS_Orig_Selling_Price__c)*100).toFixed(2);
		}
		else {
			selectedRecord.SF_PS_Discount_Percentage__c=0;
			selectedRecord.isErrorDiscount=false;
		}
	}

	handleDiscountPercentageChange(event){
		let Id = event.target.dataset.id;
		let selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		selectedRecord.SF_PS_Discount_Percentage__c = event.detail.value;
		if(selectedRecord.SF_PS_Discount_Percentage__c >=0 && selectedRecord.SF_PS_Discount_Percentage__c<100){
			selectedRecord.SF_PS_Selling_Price__c=Number((selectedRecord.SF_PS_Orig_Selling_Price__c - (selectedRecord.SF_PS_Orig_Selling_Price__c*selectedRecord.SF_PS_Discount_Percentage__c/100))).toFixed(2);
			selectedRecord.isErrorDiscount=false;
		}
		else{
			selectedRecord.SF_PS_Selling_Price__c= selectedRecord.SF_PS_Orig_Selling_Price__c;
			selectedRecord.isErrorDiscount=true;
		}
	}

	handleSellingPriceChange(event){
		/*if(this.screen == "Review"){
			this.dispatchEvent(new CustomEvent("taxcalucate", { detail: true }));
		}*/
		let Id = event.target.dataset.id;
		let name=event.target.name;
		console.log(Id);
		let selectedRecord;
		if(name=="partsWithoutInventory"){
			selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);
		}
		else{
			selectedRecord = this.rows.find(data => data.uuid === Id);
		}
		//selectedRecord = this.rows.find(data => data.uuid === Id);
		console.log(JSON.stringify(selectedRecord));
		selectedRecord.SF_PS_Selling_Price__c = event.target.value;
		console.log(event.target.value);
		console.log(selectedRecord.SF_PS_Selling_Price__c);
		selectedRecord.isErrorsellingPrice = false;
		selectedRecord.avgError = false;
		if(name != "partsWithoutInventory"){
    		this.handleWarningAndErors(selectedRecord);
		}
		
		//Discount Calculation 
		if(selectedRecord.SF_PS_Orig_Selling_Price__c>=0 && selectedRecord.SF_PS_Selling_Price__c>=0 && selectedRecord.SF_PS_Orig_Selling_Price__c >selectedRecord.SF_PS_Selling_Price__c){
			selectedRecord.SF_PS_Discount_Percentage__c=(((selectedRecord.SF_PS_Orig_Selling_Price__c - selectedRecord.SF_PS_Selling_Price__c)/selectedRecord.SF_PS_Orig_Selling_Price__c)*100).toFixed(2);
		}
		else {
			selectedRecord.SF_PS_Discount_Percentage__c=0;
			selectedRecord.isErrorDiscount=false;
		}
		this.checkExtended(selectedRecord);
	}
	// Check Extended rate
	checkExtended(selectedRecord){
		if(this.expenseToLoc == 'L'){
			selectedRecord.extended = selectedRecord.SF_PS_Cost_Price__c * selectedRecord.QuantityConsumed
		}
		else if(this.expenseToLoc == 'C' || this.expenseToLoc == '$'){
			selectedRecord.extended = selectedRecord.SF_PS_Selling_Price__c * selectedRecord.QuantityConsumed;
		}
	}

	// Handle prevous click
	handlePrevious(){
		console.log("Previous-Parts screen");
		const navigateBackEvent = new FlowNavigationBackEvent();
		this.dispatchEvent(navigateBackEvent);
	}

	// Handle next click
	@api hanldeNext(){
		if (this.woType == 'Inspection') {
			this.handlePartsNext();
		}
		else{
			console.log("Next screen");
			console.log("ROWS:" + JSON.stringify(this.rows));
			let isAllValidationsError = false;
			let isAllValidationsErrorWithoutInventory = false;
			console.log(this.screen);
          	if (this.screen == 'Review'){
				this.isNextScreen= false;
				this.partsNull = this.checkPartsIsEmpty();
				this.partsWithoutInventoryNull = this.checkPartsWithoutInventoryIsEmpty();
				if(this.partsNull ==true && this.partsWithoutInventoryNull == true){
					let returnVal = {};
					returnVal.isReview = true;
					returnVal.records = [];
					returnVal.recordsWithoutInventory = [];
					this.isNotPartsWithoutInventory = true;
					this.isNotPartsWithInventory = true;
					return JSON.stringify(returnVal);	
				}
				else if(this.partsNull == true && this.partsWithoutInventoryNull ==false){
					this.isNotPartsWithoutInventory = false;
					
				}
				else if(this.partsNull == false && this.partsWithoutInventoryNull ==true){
					this.isNotPartsWithInventory = false;
				}
				else{
					this.isNotPartsWithoutInventory = false;
					this.isNotPartsWithInventory = false;
				}
				/*  let returnVal = {};
					if(this.rows.length == 1 && !this.rows[0].ProductItemId && !this.rows[0].QuantityConsumed /*&& (this.rows[0].SF_PS_Labor_Code__c==""||this.rows[0].SF_PS_Labor_Code__c=="-"))
					/*{
				/*	this.isNotPartsWithInventory = true;
					}
					else{
						this.isNotPartsWithInventory = false;
					}
				//to do same condition for without inventory
					if(this.rowsWithoutInventory.length == 1 && !this.rowsWithoutInventory[0].SF_PS_Part_Num__c && 
						!this.rowsWithoutInventory[0].QuantityConsumed){
						this.isNotPartsWithoutInventory = true;
					}
					else{
						this.isNotPartsWithoutInventory = false;
					}
				
					if(this.isNotPartsWithInventory == true )
					{
					console.log('inside both DT');
					//let returnVal = {};
					returnVal.isReview = true;
					returnVal.records = [];
					//returnVal.recordsWithoutInventory = [];
					//return JSON.stringify(returnVal);
					}
					if(this.isNotPartsWithoutInventory == true){
					console.log('inside both DT isNotPartsWithoutInventory');
					//let returnVal = {};
					returnVal.isReview = true;
					//returnVal.records = [];
					returnVal.recordsWithoutInventory = [];
					//return JSON.stringify(returnVal);

					}
					if(this.isNotPartsWithInventory == true && this.isNotPartsWithoutInventory == true){
						return JSON.stringify(returnVal);
					}
				*/
			}
	
			//	else{
			if(this.isNextScreen == true){
				for (let i = 0; i <= this.rows.length - 1; i++) {
					if(this.rows.length > 1 || this.rows[i].ProductItemId =='' || this.rows[i].QuantityConsumed ==''){
                    	this.isNotPartsWithInventory = false;
						break;
					}
					else{
						this.isNotPartsWithInventory = true;
						break;
					}
				}
				//	this.isNotPartsWithInventory =false;
				//to do all fields check
				if(this.rowsWithoutInventory[0].SF_PS_Part_Num__c ==''
				 	&& this.rowsWithoutInventory[0].Description=='' &&
				 	!this.rowsWithoutInventory[0].QuantityConsumed &&
				 	!this.rowsWithoutInventory[0].SF_PS_Orig_Selling_Price__c &&
				 	!this.rowsWithoutInventory[0].SF_PS_Cost_Price__c)
				{
                    this.isNotPartsWithoutInventory = true;
				}
				else{
					this.isNotPartsWithoutInventory = false;
				}
		    }
			else{
			
				this.isNotPartsWithInventory  = this.checkPartsIsEmpty();
				this.isNotPartsWithoutInventory = this.checkPartsWithoutInventoryIsEmpty();
			}

			if(this.isNotPartsWithInventory == false){
				console.log('isNotPartsWithInventory validations');
				for (let i = 0; i <= this.rows.length - 1; i++) {
					// Validation for Parts # 
					if (this.rows[i].Product2Id == "") {
						this.rows[i].isErrorParts = true;
					}
					else{
						this.rows[i].isErrorParts = false;
					}

					if(!this.rows[i].PricebookEntryId && this.rows[i].Product2Id && this.displayQOH){
						this.rows[i].isErrorPriceBookEntry = true;
					}
					else {
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
					else {
						this.rows[i].isErrorLbrc = false;
					}

					if(this.screen == "Review"){
						//diksha changed true false interchange - check vikas
						this.rows[i].isErrorsellingPrice = this.rows[i].SF_PS_Selling_Price__c  ? false : true;
					}
					
					//this.rows[i].avgError = this.rows[i].SF_PS_Selling_Price__c < this.rows[i].SF_PS_Cost_Price__c ? true : false;
					
					// Check all fields 
					if(this.rows[i].isErrorPriceBookEntry || this.rows[i].decimalError || this.rows[i].isErrorsellingPrice || this.rows[i].avgError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts || this.rows[i].minPriceError || this.rows[i].isErrorDiscount){
						isAllValidationsError = true;
						this.skiptoSummary = false;
						this.skiptoSummaryPage = false;
					}
				}
			} 
		
			if(this.isNotPartsWithoutInventory == false){
				isAllValidationsErrorWithoutInventory = this.checkValidationsForPartsWithoutInventory();
				console.log('isNotPartsWithoutInventory validations');
			}
			//	}

			console.log("isAllValidationsError: " + isAllValidationsError)
			if(isAllValidationsError == false && isAllValidationsErrorWithoutInventory == false){
				/*if(this.screen != 'Review' && this.expenseToLoc != ' L'){
					//calculate discount by api
					await this.handleCalculateDiscount();
				}*/
			
				// Sending data to flow
				this.productConsumedRecord = this.rows;
				this.inventoryProductConsumedRecord = this.rowsWithoutInventory;
				console.log('this is screen ' + this.screen);
				console.log('rowsWithoutInventory' + JSON.stringify(this.rowsWithoutInventory));
				if(this.screen == 'Review'){
					let returnVal = {};
					returnVal.isReview = true;
					if(this.partsNull == false && this.partsWithoutInventoryNull ==true){
						returnVal.records = this.rows;
						returnVal.recordsWithoutInventory=[]
					}
					else if(this.partsNull == true && this.partsWithoutInventoryNull ==false){
						//	returnVal.records = this.rows;
						returnVal.recordsWithoutInventory= this.rowsWithoutInventory;
						returnVal.records = [];
					}
					else{
						returnVal.records = this.rows;
						returnVal.recordsWithoutInventory= this.rowsWithoutInventory;
					}
					console.log('LAST inventory value is'+JSON.stringify(returnVal.recordsWithoutInventory));
					console.log('LAST parts value is'+JSON.stringify(returnVal.records));
					console.log('JSON.stringify(returnVal):::'+JSON.stringify(returnVal));
					return JSON.stringify(returnVal);
				}
				else{
					const navigateNextEvent = new FlowNavigationNextEvent();
					this.dispatchEvent(navigateNextEvent);
				}
			}
	
			else if(this.screen == 'Review'){
				return '[]';
			}
		}
	}
	
 	checkPartsIsEmpty(){
		if(this.rows.length == 1 && !this.rows[0].ProductItemId && !this.rows[0].QuantityConsumed){
	    	return true;
		}
		return false;
	}

	checkPartsWithoutInventoryIsEmpty(){
		if(this.rowsWithoutInventory.length == 1 
			&& this.rowsWithoutInventory[0].SF_PS_Part_Num__c ==''
			&& this.rowsWithoutInventory[0].Description=='' 
			&&	!this.rowsWithoutInventory[0].QuantityConsumed 
			&&	!this.rowsWithoutInventory[0].SF_PS_Orig_Selling_Price__c 
			&&	!this.rowsWithoutInventory[0].SF_PS_Cost_Price__c)
		{
			return true;
		}
		return false;
	}
 

	// Handle next for parts inpection flow click
	@api handlePartsNext(){
		console.log("Next screen");
		console.log("ROWS:" + JSON.stringify(this.rows));
		let isAllValidationsError = false;
		console.log(this.screen);
		if (this.screen == 'Review' && this.rows.length == 1 && !this.rows[0].ProductItemId && !this.rows[0].QuantityConsumed /*&& (this.rows[0].SF_PS_Labor_Code__c==""||this.rows[0].SF_PS_Labor_Code__c=="-")*/){
			let returnVal = {};
			returnVal.isReview = true;
			returnVal.records = [];
			return JSON.stringify(returnVal);
		}
		else{
			for (let i = 0; i <= this.rows.length - 1; i++) {
				// Validation for Parts # 
				if (this.rows[i].Product2Id == "") {
					this.rows[i].isErrorParts = true;
				}
				else{
					this.rows[i].isErrorParts = false;
				}

				if(!this.rows[i].PricebookEntryId && this.rows[i].Product2Id && this.displayQOH){
					this.rows[i].isErrorPriceBookEntry = true;
				
				}
				else {
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
				else {
					this.rows[i].isErrorLbrc = false;
				}
				if(this.screen == "Review"){
					this.rows[i].isErrorsellingPrice = this.rows[i].SF_PS_Selling_Price__c  ? false : true;
				}
				
				//this.rows[i].avgError = this.rows[i].SF_PS_Selling_Price__c < this.rows[i].SF_PS_Cost_Price__c ? true : false;
				
				// Check all fields 
				if(this.rows[i].isErrorPriceBookEntry || this.rows[i].decimalError || this.rows[i].isErrorsellingPrice || this.rows[i].avgError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts || this.rows[i].minPriceError || this.rows[i].isErrorDiscount){
					isAllValidationsError = true;
					this.skiptoSummary = false;
					this.skiptoSummaryPage = false;
				}
			}
		}

		console.log("isAllValidationsError: " + isAllValidationsError)
		if(isAllValidationsError == false){
			// Sending data to flow
			this.productConsumedRecord = this.rows;
			console.log('this is screen ' + this.screen);
			if(this.screen == 'Review'){
				let returnVal = {};
				returnVal.isReview = true;
				returnVal.records = this.rows;
				return JSON.stringify(returnVal);
			}
			else{
				const navigateNextEvent = new FlowNavigationNextEvent();
				this.dispatchEvent(navigateNextEvent);
			}
		}
		else if(this.screen == 'Review'){
			return '[]';
		}
	}


	checkValidationsForPartsWithoutInventory(){
      let isAllValidationsError= false;
		for (let i = 0; i <= this.rowsWithoutInventory.length - 1; i++) {
			// Validation for Parts Number
			if (this.rowsWithoutInventory[i].SF_PS_Part_Num__c == "") {
				this.rowsWithoutInventory[i].isErrorPartsNumber = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorPartsNumber = false;
			}
			// Validation for Description
			if (this.rowsWithoutInventory[i].Description == "") {
				this.rowsWithoutInventory[i].isErrorDescription = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorDescription = false;
			}
			// Validation for Quantity Consumed
			if(this.rowsWithoutInventory[i].QuantityConsumed == ""){
				this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory = false;
			}

			// Validation for Labor Code
			if(this.rowsWithoutInventory[i].SF_PS_Labor_Code__c == "" || this.rowsWithoutInventory[i].SF_PS_Labor_Code__c == "-"){
				this.rowsWithoutInventory[i].isErrorLbrcWithoutInventory = true;
			}
			else {
				this.rowsWithoutInventory[i].isErrorLbrcWithoutInventory = false;
			}
			// Validation for orginal sell price
			if(this.expenseToLoc == 'C' && this.rowsWithoutInventory[i].SF_PS_Orig_Selling_Price__c ==""){
				this.rowsWithoutInventory[i].isErrorOriginalSellPrice = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorOriginalSellPrice = false;
			}
			// Validation for Cost per unit
			if(this.rowsWithoutInventory[i].SF_PS_Cost_Price__c ==""){
				this.rowsWithoutInventory[i].isErrorCostPrice = true;
			}
			else{
				this.rowsWithoutInventory[i].isErrorCostPrice = false;
			}

			if(this.rowsWithoutInventory[i].isErrorPartsNumber || this.rowsWithoutInventory[i].isErrorDescription || 
				this.rowsWithoutInventory[i].isErrorQtyConsumedWithoutInventory || 
				this.rowsWithoutInventory[i].isErrorLbrcWithoutInventory || this.rowsWithoutInventory[i].isErrorOriginalSellPrice || 
				this.rowsWithoutInventory[i].isErrorCostPrice
			){
				isAllValidationsError = true;
				this.skiptoSummary = false;
				this.skiptoSummaryPage = false;
			}
			
		}
		return isAllValidationsError;
	}

	// Handle Cancel Click
	handleCancel(event){
		// Navigation to Account List view(recent)
		let objectName = 'WorkOrder';
		window.location.href = `${window.location.origin}/lightning/o/${objectName}/list`;
	}

	get calculateTotal(){
		let total = this.rows.reduce((prev, next) => {
			if(next.extended){
				return Number(next.extended) + Number(prev);
			}
			else{
				return Number(prev);
			}
		}, 0)

		//this.dispatchEvent(new CustomEvent("partotal", { detail: Number(total).toFixed(2) }));
		return Number(total).toFixed(2);
	}

	get calculateTotalForWithoutInventory(){
		console.log('json value is without parts==>'+JSON.stringify(this.rowsWithoutInventory));
		let total = this.rowsWithoutInventory.reduce((prev, next) => {
			if(next.extended){
				return Number(next.extended) + Number(prev);
			}
			else{
				return Number(prev);
			}
		}, 0)

		//this.dispatchEvent(new CustomEvent("partwithoutinventorytotal", { detail: Number(total).toFixed(2) }));
		return Number(total).toFixed(2);
	}

	handleSummary(){
		if (this.woType == 'Inspection') {
			this.handleSummaryForParts();
		}
		else{
			this.isNextScreen = false;
			console.log('product consume data is DT' + this.rows);
			console.log('handle Summary'+this.rowsWithoutInventory.length);
			this.skiptoSummary = true;
			this.skiptoSummaryPage = true;
			/* const attributeChangeEvent = new FlowAttributeChangeEvent('skiptosummary', this.skiptoSummary);
			this.dispatchEvent(attributeChangeEvent);*/
			console.log('product item id DT' + this.rows[0].ProductItemId);
			if(this.rows[0].ProductItemId != "" || this.rows.length > 1 || this.rowsWithoutInventory.length > 1 || this.rowsWithoutInventory[0].SF_PS_Part_Num__c !=''){
				if(this.rows[0].ProductItemId !='' && this.rowsWithoutInventory[0].SF_PS_Part_Num__c ==''){
					this.isNotPartsWithInventory =false;
					console.log('inside NEXT DT 1');
				}

				//to do add all fields conditions
				if(this.rowsWithoutInventory[0].SF_PS_Part_Num__c !='' 
					&& this.rowsWithoutInventory[0].Description !='' 
					&& this.rowsWithoutInventory[0].QuantityConsumed !='' 
					&& this.rowsWithoutInventory[0].SF_PS_Cost_Price__c !=''
					&& this.rows[0].ProductItemId =='')
				{
					this.isNotPartsWithoutInventory = false;
					console.log('inside NEXT DT 2');
				}
				if(this.rowsWithoutInventory[0].SF_PS_Part_Num__c !='' && this.rows[0].ProductItemId !=''){
					this.isNotPartsWithInventory =false;
					this.isNotPartsWithoutInventory = false;
					console.log('inside NEXT DT 3');
				}
				this.hanldeNext();
				// else if(this.rowsWithoutInventory.length >= 1 && this.rowsWithoutInventory.length >=1){
				//   this.isNotPartsWithInventory =false;
				//   this.isNotPartsWithoutInventory = false;
				//   this.hanldeNext();
				// 	console.log('inside NEXT DT 3');
				// }
				// this.hanldeNext();
				// console.log('inside NEXT DT');
				
			}
			else{
				const navigateNextEvent = new FlowNavigationNextEvent();
				this.dispatchEvent(navigateNextEvent);
			}
		}
	}

  	// handle summary for inpection flow click
	handleSummaryForParts(){
		console.log('product consume data is DT' + this.rows);
		console.log('handle Summary');
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

    
	// Handle Skip Button show and hide on Parts screen
	handleSkipButton(){
		let showSkipInventory;
		let showSkipWithoutInventory;
		console.log('screen name' + this.screen);
		if(this.screen != 'Review'){
			var comp = this.template.querySelector('c-sbr_3_0_sfs-desktop-flow-buttons');
			for (let i = 0; i <= this.rows.length - 1; i++) {
				console.log('product item' + JSON.stringify(this.rows[i]));
				if(this.rows[i].ProductItemId){
					showSkipInventory = false;
					//comp.showSkipButton = false;
					console.log('inside if skip');
					break;
				}
				else {
					showSkipInventory = true;
					console.log('inside else skip');
					//comp.showSkipButton = true;
				}
			}
			if(this.rowsWithoutInventory && this.rowsWithoutInventory.length)
			{
				for (let i = 0; i <= this.rowsWithoutInventory.length - 1; i++) {
					console.log('product item' + JSON.stringify(this.rowsWithoutInventory[i]));
					if(this.rowsWithoutInventory[i].SF_PS_Part_Num__c){
					//	comp.showSkipButton = false;
					showSkipWithoutInventory=false;
						console.log('inside if skip');
						break;
					}
					else {
						showSkipWithoutInventory=true;
						console.log('inside else skip');
					//	comp.showSkipButton = true;
					}
				}
			}else{
				showSkipWithoutInventory=true;
			}
			if(showSkipInventory == true && showSkipWithoutInventory==true ){
				comp.showSkipButton = true;	
			}
			else{
				comp.showSkipButton = false;
			}
		}
	}

	// To handle price book entry selection
	handlePricebookEntrySelection(priceBookentries){
		for (let pb in priceBookentries) {
			console.log("Company code " + this.companyCode);
			if(this.companyCode == '01' && priceBookentries[pb].CurrencyIsoCode == "USD"){
				console.log("USA " + JSON.stringify(priceBookentries[pb]));
				return priceBookentries[pb];
			}
			else if(this.companyCode == '02' && priceBookentries[pb].CurrencyIsoCode == "CAD"){
				console.log("CAD " + JSON.stringify(priceBookentries[pb]));
				return priceBookentries[pb];
			}
		}
		return null;
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
		if((selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Error_Price__c) && !this.priceReadOnly){
			selectedRecord.minPriceError = true;
		}
		else{
			selectedRecord.minPriceError = false;
		}
			
		if(selectedRecord.SF_PS_Cost_Price__c && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Cost_Price__c && !this.priceReadOnly){
			selectedRecord.avgError = true;
			//selectedRecord.avgErrorMessage='Selling price cannot be more than avg price';
		}
		else{
			selectedRecord.avgError = false;
		}
		// Warning
		if(( !selectedRecord.minPriceError && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Warning_Price__c) && !this.priceReadOnly){
			selectedRecord.warningError = true;
		}
		else{
			selectedRecord.warningError = false;
		}
	}

	//Handle discount change method to calculate selling price based on discount selected 
	handleDiscountChange(event){
		let Id = event.target.dataset.id;
		console.log(Id);
		let selectedRecord;
		let name=event.target.name;
		//selectedRecord = this.rows.find(data => data.uuid === Id);
		console.log(JSON.stringify(selectedRecord));
		if(name=="partsWithoutInventory"){
			selectedRecord = this.rowsWithoutInventory.find(data => data.uuid === Id);

		}
		else{
			selectedRecord = this.rows.find(data => data.uuid === Id);
		}
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
		if(name!="partsWithoutInventory"){
			this.handleWarningAndErors(selectedRecord);
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
		if(this.checkPartsIsEmpty())
		{
			this.validationsErrorFound =false;
			return;
		}
		this.validationsErrorFound = false;
		for (let i = 0; i < this.rows.length; i++) {
			console.log("ROWS Before1");
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
				console.log("ROWS Before3");
			} 
			else{
				this.rows[i].isErrorQtyConsumed = false;
				console.log("ROWS Before3");
			}
			// Validation for Labor Code
			if(this.rows[i].SF_PS_Labor_Code__c == "" || this.rows[i].SF_PS_Labor_Code__c == "-"){
				this.rows[i].isErrorLbrc = true;
				console.log("ROWS Before4");
			} 
			else{
				this.rows[i].isErrorLbrc = false;
				console.log("ROWS Before4");
			}

			if(this.screen == "Review"){
				this.rows[i].isErrorsellingPrice = this.rows[i].SF_PS_Selling_Price__c ? false : true;
			}
			
			//this.rows[i].avgError = this.rows[i].SF_PS_Selling_Price__c < this.rows[i].SF_PS_Cost_Price__c ? true : false;
			
			// Check all fields 
			if(this.rows[i].isErrorsellingPrice || this.rows[i].isErrorPriceBookEntry || this.rows[i].decimalError || this.rows[i].avgError || this.rows[i].isErrorLbrc || this.rows[i].isErrorQtyConsumed || this.rows[i].isErrorParts || this.rows[i].minPriceError || this.rows[i].isErrorDiscount) {
				
				this.validationsErrorFound = true;
			}
			console.log("ROWS Before4");
		}
	}
}