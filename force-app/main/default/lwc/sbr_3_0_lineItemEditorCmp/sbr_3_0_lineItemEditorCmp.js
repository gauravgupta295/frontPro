import { LightningElement, api, track, wire } from 'lwc';
import * as SBRUtils from 'c/sbrUtils';
import { publish, MessageContext } from "lightning/messageService";//SF-5291,SF-5292
import { createMessageContext } from 'lightning/messageService';//SF-5291,SF-5292
import prefillLineData from '@salesforce/apex/SBR_3_0_LineItemEditorCmpController.getLineItem';
import saveSObjects from '@salesforce/apex/SBR_3_0_LineItemEditorCmpController.saveSObjects';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccessLevelFor from '@salesforce/apex/SBR_3_0_AccessUtilities.isUpdateable';
import searchParentProductWithFuelPlanEnabled from '@salesforce/apex/SBR_3_0_ProductDA.getParentCatClassWithFuelPlan';//SF-5291,SF-5292
import QUOTE_LINE_OBJECT from "@salesforce/schema/SBQQ__QuoteLine__c";//SF-5291,SF-5292
import ORDER_ITEM_OBJECT from "@salesforce/schema/OrderItem";//SF-5291,SF-5292
import getFuelChargePrice from '@salesforce/apex/SBR_3_0_ProductDA.checkProductOptionForLineItem';
import createLineItems from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.createLineItems';//SF-5291,SF-5292
import getProductAddOns from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductAddOns';//SF-5291,SF-5292
import updateLineItemsChannel from "@salesforce/messageChannel/UpdateLineItemsChannel__c"; //SF-5291,SF-5292
let defaultLineItemNote = '{"seasonalQuote" : "Seasonal Rates applied. Please see Seasonal Rate Details section for additional details.","singleShift" : "Single Shift Rate applied. Please see Shift Rate Details section for additional details.", "doubleShift" : "Double Shift Rate applied. Please see Shift Rate Details section for additional details.","tripleShift" : "Triple Shift Rate applied. Please see Shift Rate Details section for additional details.", "standByRate" : "Rate based on standby duty, less than 5 hrs/month."}';
export default class Sbr_3_0_lineItemEditorCmp extends LightningElement {
    // SAL-26337
    @api gridName;
    @track accessLevelMap = { 'Line_Item_Notes__c': true, 'SBQQ__Quantity__c': true, 'Selling_Price__c': true };
    @api companyCode;//SF-5291,SF-5292
    @api objectApiName;//SF-5291,SF-5292
    @api recordId;
    @api groupId;
    @api lineId = '';
    @api isRentalQuoteSubRecType = false;
    rentalQuoteSubMessage = 'Line Items cannot be updated after the Quote has been submitted.';
    _seasonalMultiplier;
    defaultSeasonalMultiplier = 4.0;
    lineItemNotes = '';
    shiftDifferential = "";
    isOverrideDiscount = false;
    applyStandbyRates = false;
    isSeasonalQuote = false;
    hasContingencyPlan = false;
    hasShifting = false;
    hasStandbyRates = false;
    isLoading = false;
    objectType;
    @track lineItem = {};
    itemGroup;
    itemQuantity;
    disableCC = false;
    startDate = '';
    endDate = '';
    showCustomerPricingAlert = false;
    alertClass = 'slds-notify slds-notify_alert slds-alert_warning';
    pricingType = '';
    pricingFlag = false;
    ratesDisabled = false;
    doNotExceedMinRate;
    doNotExceedDailyRate;
    doNotExceedWeeklyRate;
    doNotExceedMonthlyRate;
    suggestedMinRate;
    suggestedDailyRate;
    suggestedWeeklyRate;
    suggestedMonthlyRate;
    discount;
    displayOverrideDiscount = false;
    seasonalRate;
    //To store val from the database
    seasonalRateDbVal;
    //flags to run seasonal rate calculation
    hasSeasonalMultiplierChanged = false;
    hasSeasonalRateChanged = false;
    submittedToWynne;
    rentalmanQuoteId;
    reservationOrderNumber;
    isLineItemEditable = true;
    lineItemNotEditableErrorMessage;
    space = "  ";
    lineName = '';
    containsFuelCharge = false;//SF-5291,SF-5292
    fuelPrice;//SF-5291,SF-5292
    itemHasFuelCatClassParent = false;//SF-5291,SF-5292
    kitNumberBelongsTo;//SF-5291,SF-5292
    productAddOns = {};//SF-5291,SF-5292
    lineItemProduct;//SF-5291,SF-5292
    lineItemRecsToInsert = [];
    flagChecked;//SF-5291,SF-5292
    isRequiredRentalAddOn;
    hasExistingFC;//SF-5291,SF-5292
    messageContext = createMessageContext();//SF-5291,SF-5292
    isMobile = false;
    existingLines = [];
    dynamicFuelPlanLabel="Fuel Plan";//SF-5995
    parentRateBranch = '';



    // SAL-26337
    get isRental() {

        return this.gridName === 'rental' ? true : false;
    }
   //SF-5291,SF-5292
    get isRentalAndContainsFuelCharge() {
        return this.gridName === 'rental' && this.containsFuelCharge ? true : false;

    }
    //Do not deploy,work in progress

    // SAL-26337
    get isSalesPriceEditable() {//SF-5291,SF-5292
        return this.gridName === 'delivery' || this.lineName == 'Fuel Convenience Charge' || this.lineName.includes('Refill') ? true : !this.accessLevelMap.Selling_Price__c;
    }
    // SAL-26337
    get isQuantityEditable() {//SF-5291,SF-5292
        return this.gridName === 'delivery' || this.isRequiredRentalAddOn || this.lineName == 'Fuel Convenience Charge' || this.lineName.includes('Refill') ? true : !this.accessLevelMap.SBQQ__Quantity__c;
    }
    // SAL-26337
    get isNotesEditable() {//SF-5291,SF-5292
        return !this.accessLevelMap.Line_Item_Notes__c || this.lineName == 'Fuel Convenience Charge' || this.lineName.includes('Refill');
    }

    get showDailyRate() {
        return (this.isRental && !this.isSeasonalQuote) ? true : false;
    }

    get isWeeklyRateDisabled() {
        return this.isSeasonalQuote ? true : this.ratesDisabled;
    }

    get isMonthlyRateDisabled() {
        return this.isSeasonalQuote ? true : this.ratesDisabled;
    }

    get showSeasonalMultiplier() {
        return this.isRental && this.isSeasonalQuote;
    }
    get showSeasonalRate() {
        return this.isRental && this.isSeasonalQuote;
    }

    get seasonalMultiplier() {
        return this._seasonalMultiplier;
    }

    @api resetForm() {
        this.lineItem = {};
        this.itemQuantity = '';
        this.parentRateBranch ='';
        this.lineItemNotes = '';
        this.suggestedDailyRate = '';
        this.suggestedWeeklyRate = '';
        this.suggestedMonthlyRate = '';
        this.containsFuelCharge = false;//SF-5291,SF-5292
        this.itemHasFuelCatClassParent = false;//SF-5291,SF-5292
        this.lineItemRecsToInsert = [];//SF-5291,SF-5292
        this.flagChecked = false;//SF-5291,SF-5292
        this.hasExistingFC = false;//SF-5291,SF-5292
        this.isRequiredRentalAddOn = false;
        this.existingLines = [];
        this.dynamicFuelPlanLabel="Fuel Plan";//SF-5995
        let quantityCmp = this.template.querySelector("lightning-input[data-my-id=item-quantity]");//SF-6105
        quantityCmp.setCustomValidity('');//SF-6105
    }
    @api populateLineData(lineId, groupId, parentId,lineItems) {
        this.isLoading=true;
        this.resetForm();
        this.existingLines = lineItems;
        prefillLineData({ lineId: lineId, groupId: groupId, parentId: parentId })
            .then(data => {
                this.pricingFlag = false;
                this.pricingType = '';
                this.doNotExceedDailyRate = null;
                this.doNotExceedMinRate = null;
                this.doNotExceedMonthlyRate = null;
                this.doNotExceedWeeklyRate = null;
                this.ratesDisabled = false;
                this.objectType = data.objectType;
                let line;
                this.containsFuelCharge = data.fuelPlanInfo.hasFuelCharge;//SF-5291,SF-5292
                this.hasExistingFC = data.hasExisitingFuelPlan;//SF-5291,SF-5292
                if (this.objectType == 'OrderItem') {
                    for (let item of data.lineItems) {
                        if (item.Id == lineId) {
                            this.itemGroup = [item];
                            line = item;
                        }
                    }
                    this.itemQuantity = line.Quantity;
                    this.parentRateBranch = line.Rates_Branch__c;
                    this.startDate = line.Order.Start_Date__c ? line.Order.Start_Date__c : '';
                    this.endDate = line.Order.Return_Date__c ? line.Order.Return_Date__c : '';
                    this.discount = line.Order.Order_Discount__c ? line.Order.Order_Discount__c : 0;
                    this.isLineItemEditable = !(line.Order.Reservation_Order_Number__c || line.Order.Rentalman_Quote_Id__c); // SF-6182
                    if(this.isRental)
                    this.lineName = line.Product2.Name ? `${line.Product2.Name} ( ${line.Product2.Category__c} - ${line.Product2.Class__c} )`  : '';
                    else
                    this.lineName = line.Product2.Name ? line.Product2.Name  : '';
                    this.lineItemProduct = line.Product2.Id;//SF-5291,SF-5292
                    this.lineItemNotEditableErrorMessage = 'This Order has been submitted and can no longer be updated. Make any necessary changes in RentalMan or Clone this Order.';
                }
                else {
                    line = data.lineItem;
                    this.lineItemProduct = data.lineItem.SBQQ__Product__r.Id;
                    this.itemQuantity = line.SBQQ__Quantity__c;
                    this.parentRateBranch = line.Rates_Branch__c;
                    this.startDate = line.SBQQ__Quote__r.Start_Date__c ? line.SBQQ__Quote__r.Start_Date__c : '';
                    this.endDate = line.SBQQ__Quote__r.End_Date__c ? line.SBQQ__Quote__r.End_Date__c : '';
                    this.discount = line.SBQQ__Quote__r.Quote_Discount__c ? line.SBQQ__Quote__r.Quote_Discount__c : 0;
                    this._seasonalMultiplier = line.Seasonal_Multiplier__c ? line.Seasonal_Multiplier__c : this.defaultSeasonalMultiplier;
                    this.seasonalRateDbVal = parseFloat(line.Seasonal_Rate__c);
                    this.submittedToWynne = line.SBQQ__Quote__r.Submitted_to_Wynne__c;
                    this.rentalmanQuoteId = line.SBQQ__Quote__r.Rentalman_Quote_Id__c;
                    this.isLineItemEditable = !(line.SBQQ__Quote__r.Submitted_to_Wynne__c && line.SBQQ__Quote__r.Rentalman_Quote_Id__c);
                    if(this.isRental)
                    this.lineName = line.SBQQ__Product__r.Name ? `${line.SBQQ__Product__r.Name} ( ${line.SBQQ__Product__r.Category__c} - ${line.SBQQ__Product__r.Class__c} )`  : '';
                    else
                    this.lineName = line.SBQQ__Product__r.Name ? line.SBQQ__Product__r.Name : '';
                    this.lineItemNotEditableErrorMessage = 'This Quote has been submitted and can no longer be edited. Make any necessary changes in RentalMan or Clone this Quote.';
                }
                this.lineItem = {
                    Id: line.Id,
                    //Name: line.Product2 ? (line.Product2.Name ? line.Product2.Name : '') : '',// SAL-26337
                    Name: this.lineName,
                    Selling_Price__c: line.Selling_Price__c ? line.Selling_Price__c : '',
                    Shift_Differential__c: line.Shift_Differential__c ? line.Shift_Differential__c : '',
                    Contingency_Cost__c: line.Contingency_Cost__c ? line.Contingency_Cost__c : '',
                    Product_SKU__c: this.objectType === 'OrderItem' ? line.Product2.Product_SKU__c : line.Product_SKU__c,
                    Min_Rate__c: line.Min_Rate__c ? line.Min_Rate__c : '',
                    Daily_Rate__c: line.Daily_Rate__c ? line.Daily_Rate__c : '',
                    Weekly_Rate__c: line.Weekly_Rate__c ? line.Weekly_Rate__c : '',
                    Fuel_Plan__c: line.Fuel_Plan__c ? line.Fuel_Plan__c : false,
                    Monthly_Rate__c: line.Monthly_Rate__c ? line.Monthly_Rate__c : '',
                    Override_Discount__c: line.Override_Discount__c ? line.Override_Discount__c : false,
                    Apply_Standby_Rates__c: line.Apply_Standby_Rates__c ? line.Apply_Standby_Rates__c : false,
                    Line_Comments__c: line.Line_Comments__c ? line.Line_Comments__c : '',

                };
                this.kitNumberBelongsTo = this.objectType === 'OrderItem' && (this.lineName == 'Fuel Convenience Charge' || this.lineName.includes('Refill')) ? line.Kit_Number_This_Item_Belongs_To__c : line.Kit_Number_this_Item_Belongs_to__c;//SF-5291,SF-5292
                //Begins SF-5291,SF-5292
                if (this.kitNumberBelongsTo) {
                    this.getParentProductCatClass(this.kitNumberBelongsTo, this.objectType);
                }//Ends SF-5291,SF-5292
                this.fuelPrice = this.containsFuelCharge && line.Fuel_Plan__c ? data.fuelPlanInfo.fuelChargeOption.SBQQ__OptionalSKU__r.Sell_Price__c : '';//SF-5291,SF-5292
                this.dynamicFuelPlanLabel=this.fuelPrice?"Fuel Plan $"+this.fuelPrice:"Fuel Plan";//SF-5995
                this.isOverrideDiscount = this.lineItem.Override_Discount__c;
                this.applyStandbyRates = this.lineItem.Apply_Standby_Rates__c;
                this.lineItemNotes = this.lineItem.Line_Comments__c;
                this.pricingFlag = line.Specific_Pricing_Flag__c;
                this.pricingType = line.Specific_Pricing_Type__c ? line.Specific_Pricing_Type__c : '';
                this.suggestedMinRate = line.Suggested_Minimum_Rate__c;
                this.suggestedDailyRate = line.Suggested_Daily_Rate__c;
                this.suggestedWeeklyRate = line.Suggested_Weekly_Rate__c;
                this.suggestedMonthlyRate = line.Suggested_Monthly_Rate__c;
                this.displayOverrideDiscount = this.discount > 0 ? true : false;
                this.hasContingencyPlan = data.hasContingencyPlan;
                this.seasonalRate = SBRUtils.isEmpty(this.seasonalRateDbVal) || this.seasonalRateDbVal == 0 ? this.lineItem.Monthly_Rate__c : this.seasonalRateDbVal;
                this.isRequiredRentalAddOn = (data?.productOption?.SBQQ__Required__c && data?.productOption?.SBQQ__Feature__r?.Name === 'Rental Addons')? data?.productOption?.SBQQ__Required__c : false;
                this.updateShift(data.hasShiftPricing);
                this.updateSeasonalMultiplier(data.hasSeasonalRate);
                this.updateStandByRate(data.hasStandbyPricing);
                this.getCustomerPricingAlert();
                this.refreshLineItemData();
                this.isLoading=false;
            })
            .catch((error) => {
                this.isLoading=false;
                console.log('error: ' + error.message);
            });


    }

    //SF-5291,SF-5292
    getParentProductCatClass(kitNumberBelongsTo, lineItemType) {
        searchParentProductWithFuelPlanEnabled({ kitNumber: kitNumberBelongsTo, objectType: lineItemType})
        .then(apexResult => {
                
                if (apexResult) {
                    this.itemHasFuelCatClassParent = apexResult.hasFuelCatClassParent;                   

                } else {
                    console.log('Invalid data returned from Apex method.');

                }
            })
            .catch(error => {
                console.log('Error calling Apex method: ' + error);

            });


    }

    refreshLineItemData() {
        if (this.lineItem.Product_SKU__c === '1559000')
            this.disableCC = true;
        else
            this.disableCC = false;
    }

    get isLayoutItemVisible() {
        return this.gridName !== 'delivery';
    }

    connectedCallback() {
        this.getFieldsAccesses();
    }

    getFieldsAccesses() {
        getAccessLevelFor({ toCheckObject: 'SBQQ__QuoteLine__c', fieldstoCheck: ['Selling_Price__c', 'Line_Item_Notes__c', 'SBQQ__Quantity__c'] })
            .then(data => {

                this.accessLevelMap = data;
            })
            .catch(error => {
                console.log('**** **** **** getAccessLevelFor error :: ' + JSON.stringify(error));
            });
    }

    updateLineItem() {
        let updatedQuoteLine;
        let updatedOrderItems = [];
        let contigencyPlanTemp = this.hasContingencyPlan ? this.template.querySelector("lightning-input[data-my-id=contingency-cost]").value : null;
        if (this.objectType == 'OrderItem') {
            for (let i = 0; i < this.itemGroup.length; i++) {
                let newItem = {
                    Id: this.itemGroup[i].Id,
                    // SAL-26337
                    Selling_Price__c: this.template.querySelector("lightning-input[data-my-id=selling-price]") ? this.template.querySelector("lightning-input[data-my-id=selling-price]").value : null,
                    Quantity: parseInt(this.template.querySelector("lightning-input[data-my-id=item-quantity]").value),
                    Daily_Rate__c: this.template.querySelector("lightning-input[data-my-id=daily-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=daily-rate-id]").value : null,
                    Line_Comments__c: this.lineItemNotes,
                    Monthly_Rate__c: this.template.querySelector("lightning-input[data-my-id=monthly-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=monthly-rate-id]").value : null,
                    Weekly_Rate__c: this.template.querySelector("lightning-input[data-my-id=weekly-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=weekly-rate-id]").value : null,
                    Seasonal_Multiplier__c: this.getSeasonalMultiplierToUpdate(),
                    Apply_Standby_Rates__c: this.applyStandbyRates,
                    Contingency_Cost__c: contigencyPlanTemp,
                    Shift_Differential__c: this.shiftDifferential,
                    Override_Discount__c: this.isOverrideDiscount
                }
                //SF-5291,SF-5292
                if (this.template.querySelector("lightning-input[data-my-id=fuel-plan-id]")) {
                    newItem.Fuel_Plan__c = this.template.querySelector("lightning-input[data-my-id=fuel-plan-id]").checked;
                }
                updatedOrderItems.push(newItem);
            }
        }
        else {
            updatedQuoteLine = {
                Id: this.lineItem.Id,
                // SAL-26337
                Selling_Price__c: this.template.querySelector("lightning-input[data-my-id=selling-price]") ? this.template.querySelector("lightning-input[data-my-id=selling-price]").value : null,
                SBQQ__Quantity__c: parseInt(this.template.querySelector("lightning-input[data-my-id=item-quantity]").value),
                Daily_Rate__c: this.template.querySelector("lightning-input[data-my-id=daily-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=daily-rate-id]").value : null,
                Line_Comments__c: this.lineItemNotes,
                Monthly_Rate__c: this.getMonthlyRateToUpdate(),
                Weekly_Rate__c: this.template.querySelector("lightning-input[data-my-id=weekly-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=weekly-rate-id]").value : null,
                Seasonal_Multiplier__c: this.getSeasonalMultiplierToUpdate(),
                Apply_Standby_Rates__c: this.applyStandbyRates,
                Contingency_Cost__c: contigencyPlanTemp,
                Shift_Differential__c: this.shiftDifferential,
                Override_Discount__c: this.isOverrideDiscount,
                Seasonal_Rate__c: this.getSeasonalRateToUpdate(),
                Min_Rate__c: this.isSeasonalQuote ? this.lineItem.Monthly_Rate__c : this.lineItem.Min_Rate__c
            };
            //SF-5291,SF-5292
            if (this.template.querySelector("lightning-input[data-my-id=fuel-plan-id]")) {
                updatedQuoteLine.Fuel_Plan__c = this.template.querySelector("lightning-input[data-my-id=fuel-plan-id]").checked;
            }

        }


        //resetting flags for the same session
        this.hasSeasonalMultiplierChanged = false;
        this.hasSeasonalRateChanged = false;

        return [updatedQuoteLine, updatedOrderItems];
    }

    @api async saveData() {
        try {
            this.isLoading=true;
            let isRentalOrSales;
            //Begins SF-5291,SF-5292
            let isFuelLineItemsCreated = false;
             // if fuel plan is already true no need to check for add-ons
             this.flagChecked = this.lineItem?.Fuel_Plan__c == true ? false : this.flagChecked;

            if (this.flagChecked) {
                await this.getProductAddOns();
                this.addRentalForcedAddOns();
                this.addSalesForcedAddOns();
            }//Ends SF-5291,SF-5292
            if (!this.isLineItemEditable) {
                this.dispatchEvent(new ShowToastEvent({
                    name: 'Submit Error',
                    message: this.lineItemNotEditableErrorMessage,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.isLoading = false; // SF-6182
                return null;
            }
            
            const updateList = this.updateLineItem();
            
            // Show error on quantity for sales required addons when quantity is less than parent quantity
            let quantityCmp = this.template.querySelector("lightning-input[data-my-id=item-quantity]");
            let showError = false;
            if (this.objectType == 'OrderItem') {
                // Get current Line 
                let currentEditedLine = this.existingLines?.find(item => item?.Id == updateList[1][0]?.Id);
                let parentLine = this.existingLines?.find(item => item?.CatClass == currentEditedLine?.Kit_Number_this_Item_Belongs_to);
                if(parentLine?.Quantity > updateList[1][0]?.Quantity){ 
                    isRentalOrSales=currentEditedLine?.Sale_Price!=undefined && currentEditedLine?.Sale_Price!=null ? 'Sales' :'Rental';
                    quantityCmp.setCustomValidity('Quantity must be greater than or equal to the quantity of the Rental Item this Add On is associated to.');//SF-6258
                    showError = true;
                }else{
                    quantityCmp.setCustomValidity('');
                }

            }else{
                // Get current Line 
                let currentEditedLine = this.existingLines?.find(item => item?.Id == updateList[0]?.Id);
                let parentLine = this.existingLines?.find(item => item?.CatClass == currentEditedLine?.Kit_Number_this_Item_Belongs_to);
                if(parentLine?.Quantity > updateList[0]?.SBQQ__Quantity__c){  
                    isRentalOrSales=currentEditedLine?.Sale_Price!=undefined && currentEditedLine?.Sale_Price!=null ? 'Sales' :'Rental';
                    quantityCmp.setCustomValidity('Quantity must be greater than or equal to the quantity of the Rental Item this Add On is associated to.');//SF-6258
                    showError = true;
                }else{
                    quantityCmp.setCustomValidity('');
                }
            }
            quantityCmp.reportValidity();
            if(showError){
                this.isLoading = false; // SF-5340
                return null;
            }
            if (this.pricingFlag) {
                if (this.pricingType == 'Do Not Exceed' || this.pricingType == 'Percent Off Local Book') {
                    if (this.objectType == 'OrderItem') {
                        let item = updateList[1];


                        if (updateList[1][0].Min_Rate__c > this.suggestedMinRate || updateList[1][0].Monthly_Rate__c > this.suggestedMonthlyRate || updateList[1][0].Daily_Rate__c > this.suggestedDailyRate || updateList[1][0].Weekly_Rate__c > this.suggestedWeeklyRate) {
                            throw new Error('Rates cannot exceed Suggested Rate');
                        }
                    }
                    else {
                        if (updateList[0].Min_Rate__c > this.suggestedMinRate || updateList[0].Monthly_Rate__c > this.suggestedMonthlyRate || updateList[0].Daily_Rate__c > this.suggestedDailyRate || updateList[0].Weekly_Rate__c > this.suggestedWeeklyRate) {
                            throw new Error('Rates cannot exceed Suggested Rate');
                        }
                    }
                }
            }
             //Begins SF-5291,SF-5292
            if (!SBRUtils.isEmpty(this.lineItemRecsToInsert)) {
                isFuelLineItemsCreated = await this.createFuelPlanLineItemRecords();
            } //Ends SF-5291,SF-5292
            const results = await saveSObjects({ quoteLines: [updateList[0]], orderLines: updateList[1], objectType: this.objectType });
            //this.isLoading=false;
            return this.objectType == 'OrderItem' ? updateList[1] : updateList[0];
        }
        catch (e) {
            //this.isLoading=false;
            let message = e.body?.message || e.message;
            if (message.indexOf('INSUFFICIENT_ACCESS_OR_READONLY') > 0) {
                message = 'You do not have the necessary privileges to edit this record. See your administrator for help.';
            } else {
                message = 'Failed to update line item.'
            }
            this.dispatchEvent(new ShowToastEvent({
                name: 'Submit Error',
                message,
                variant: 'error',
                mode: 'sticky'
            }));
            return null;
        }
    }
    // how is this changed on the modal? may not be needed. What should happen to LIN if multiplier is 0/empty/undefined
    handleSeasonalMultiplierChange(event) {
        let seasonalMultiplierCmp = this.template.querySelector("lightning-input[data-my-id=seasonal-multiplier]");
        this.hasSeasonalMultiplierChanged = false;
        if (this._seasonalMultiplier != parseFloat(event.target.value)) {
            this.hasSeasonalMultiplierChanged = true;
        }
        if (parseFloat(event.target.value) === 0 || SBRUtils.isEmpty(event.target.value)) {
            seasonalMultiplierCmp.setCustomValidity('Seasonal Multiplier must be greater than 0');
            this.dispatchEvent(new CustomEvent('disablesavebtn', {}));
        } else {
            this._seasonalMultiplier = event.target.value;
            this.dispatchEvent(new CustomEvent('enablesavebtn', {}));
            seasonalMultiplierCmp.setCustomValidity('');
        }
        seasonalMultiplierCmp.reportValidity();
    }
    get shiftOptions() {
        return [
            { label: 'Single', value: 'S' },
            { label: 'Double', value: 'D' },
            { label: 'Triple', value: 'T' },
        ]
    }
    changeShiftDuration(event) {
        this.shiftDifferential = event.target.value;
        this.updateShiftNotes();
    }
    changeApplyStandByRate(event) {
        this.applyStandbyRates = event.target.checked;
    }
    changeOverrideDiscount(event) {
        this.isOverrideDiscount = event.target.checked;
    }
    changeLineItemNotes(event) {
        this.lineItemNotes = event.target.value;
    }
    updateSeasonalMultiplier(isSeasonalQuote) {
        this.isSeasonalQuote = isSeasonalQuote;
        let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
        if (isSeasonalQuote) {
            if (!this.lineItemNotes.includes(defaultLineItemNoteJSON.seasonalQuote)) {
                this.lineItemNotes = this.lineItemNotes.concat("\n" + defaultLineItemNoteJSON.seasonalQuote);
            }
        }
        else {
            this.lineItemNotes = this.lineItemNotes.replace(defaultLineItemNoteJSON.seasonalQuote, '');
        }
    }

    updateShift(shifting) {
        let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
        if (shifting) {
            this.hasShifting = shifting;
            this.shiftDifferential = this.lineItem.Shift_Differential__c;
            this.removeDefaultShiftNote();
            switch (true) {
                case (this.shiftDifferential == 'S') && (!this.lineItemNotes.includes(defaultLineItemNoteJSON.singleShift)):
                    this.lineItemNotes = this.lineItemNotes.concat("\n" + defaultLineItemNoteJSON.singleShift);
                    break;
                case (this.shiftDifferential == 'D') && (!this.lineItemNotes.includes(defaultLineItemNoteJSON.doubleShift)):
                    this.lineItemNotes = this.lineItemNotes.concat("\n" + defaultLineItemNoteJSON.doubleShift);
                    break;
                case (this.shiftDifferential == 'T') && (!this.lineItemNotes.includes(defaultLineItemNoteJSON.tripleShift)):
                    this.lineItemNotes = this.lineItemNotes.concat("\n" + defaultLineItemNoteJSON.tripleShift);
                    break;
            }
        }
    }
    updateStandByRate(standbyRates) {
        this.hasStandbyRates = standbyRates;
        let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
        let standyByRateStr = defaultLineItemNoteJSON.standyByRate;
        if (standyByRateStr == undefined || standyByRateStr == null) {
            standyByRateStr = 'Rate based on standby duty, less than 5 hrs/month.'
        }

        if (standbyRates) {
            //  this.hasStandbyRates = standbyRates;
            if (standyByRateStr != undefined && !this.lineItemNotes.includes(standyByRateStr)) {
                this.lineItemNotes = this.lineItemNotes.concat("\n" + standyByRateStr);
            }
        } else {
            this.lineItemNotes = this.lineItemNotes.replace(defaultLineItemNoteJSON.standByRate, '');
        }
    }
    // updateShiftNotes helper method: clears line item notes of any existing default line item note statements
    removeDefaultShiftNote() {
        let defaultLineItemNoteJSON = JSON.parse(defaultLineItemNote);
        this.lineItemNotes = this.lineItemNotes.replace("\n" + defaultLineItemNoteJSON.singleShift, '');
        this.lineItemNotes = this.lineItemNotes.replace(defaultLineItemNoteJSON.singleShift, '');
        this.lineItemNotes = this.lineItemNotes.replace("\n" + defaultLineItemNoteJSON.doubleShift, '');
        this.lineItemNotes = this.lineItemNotes.replace(defaultLineItemNoteJSON.doubleShift, '');
        this.lineItemNotes = this.lineItemNotes.replace("\n" + defaultLineItemNoteJSON.tripleShift, '');
        this.lineItemNotes = this.lineItemNotes.replace(defaultLineItemNoteJSON.tripleShift, '');
    }
    getCustomerPricingAlert() {
        if (this.pricingFlag) {
            if (this.pricingType == 'Set Rates') {
                this.customerPricingAlert = 'Customer has Set Rates. Rates cannot be changed.';
                this.disableCC = true;
                this.ratesDisabled = true;
            }
            if (this.pricingType == 'Do Not Exceed') {
                this.customerPricingAlert = 'Customer has Do Not Exceed Rates. Rates increases not allowed.';
                this.ratesDisabled = false;
                this.doNotExceedDailyRate = this.suggestedDailyRate;
                this.doNotExceedMinRate = this.suggestedMinRate;
                this.doNotExceedMonthlyRate = this.suggestedMonthlyRate;
                this.doNotExceedWeeklyRate = this.suggestedWeeklyRate;

            }
            if (this.pricingType == 'Percent Off Local Book') {
                this.customerPricingAlert = 'Customer has % off Local Book Rates. Rates increases not allowed.';
                this.ratesDisabled = false;
                this.doNotExceedDailyRate = this.suggestedDailyRate;
                this.doNotExceedMinRate = this.suggestedMinRate;
                this.doNotExceedMonthlyRate = this.suggestedMonthlyRate;
                this.doNotExceedWeeklyRate = this.suggestedWeeklyRate;
            }
            if (this.pricingType == 'Customer Loaded') {
                this.customerPricingAlert = 'Customer has special rates.';
                this.ratesDisabled = false;
            }
            this.showCustomerPricingAlert = true;
        }
        else {
            this.showCustomerPricingAlert = false;
            this.ratesDisabled = false;
        }
    }

    handleSeasonalRateChange(event) {
        let seasonalRateCmp = this.template.querySelector("lightning-input[data-my-id=seasonal-rate]");
        this.hasSeasonalRateChanged = false;
        if (parseFloat(this.seasonalRate) != parseFloat(event.target.value)) {
            this.hasSeasonalRateChanged = true;
        }
        if (parseFloat(event.target.value) === 0 || SBRUtils.isEmpty(event.target.value)) {
            seasonalRateCmp.setCustomValidity('Seasonal Rate must be greater than 0');
            this.dispatchEvent(new CustomEvent('disablesavebtn', {}));
        } else {
            this.seasonalRate = parseFloat(event.target.value);
            this.dispatchEvent(new CustomEvent('enablesavebtn', {}));
            seasonalRateCmp.setCustomValidity('');
        }
        seasonalRateCmp.reportValidity();
    }
    getMonthlyRateToUpdate() {
        if (this.isSeasonalQuote && (this.hasSeasonalMultiplierChanged || this.hasSeasonalRateChanged)) {
            return this.seasonalRate * this._seasonalMultiplier;
        } else if (this.isSeasonalQuote && (SBRUtils.isEmpty(this.seasonalRateDbVal) || this.seasonalRateDbVal == 0)) {
            return this.seasonalRate * this._seasonalMultiplier;
        }
        return this.template.querySelector("lightning-input[data-my-id=monthly-rate-id]") ? this.template.querySelector("lightning-input[data-my-id=monthly-rate-id]").value : null;
    }

    getSeasonalRateToUpdate() {
        if (this.isSeasonalQuote) {
            return this.seasonalRate;
        }
        //All other cases update with value from UI
        return this.template.querySelector("lightning-input[data-my-id=seasonal-rate]") ? this.template.querySelector("lightning-input[data-my-id=seasonal-rate]").value : null;
    }
    getSeasonalMultiplierToUpdate() {
        if (this.isSeasonalQuote) {
            return this._seasonalMultiplier;
        }
        return this.template.querySelector("lightning-input[data-my-id=seasonal-multiplier]") ? this.template.querySelector("lightning-input[data-my-id=seasonal-multiplier]") : null;
    }
     //SF-5291,SF-5292
    async toggleFuelPlanAmount(event) {
        this.flagChecked = event.target.checked;
        if (this.flagChecked) {
            const fuelFlag = await getFuelChargePrice({ lineId: this.lineItem.Id, objectType: this.objectType });
            this.fuelPrice = fuelFlag?.fuelChargeOption?.SBQQ__OptionalSKU__r?.Sell_Price__c? Math.floor(Number(fuelFlag.fuelChargeOption.SBQQ__OptionalSKU__r.Sell_Price__c)).toString().replace('US', ''): '';

            this.dynamicFuelPlanLabel=this.fuelPrice?'Fuel Plan $'+this.fuelPrice:'Fuel Plan';//SF-5995
        } else {
            this.fuelPrice = '';
            this.dynamicFuelPlanLabel='Fuel Plan';

        }

    }
    //SF-5291,SF-5292
    async getProductAddOns() {
        
        let results;
        try {
            results = await getProductAddOns({
                productId: this.lineItemProduct,
                companyCode: this.companyCode,
                recordId: this.recordId,
                branch: this.parentRateBranch
            });
        } catch (error) {
            console.error('Error fetching product addons ' + error.message)
        }
        this.productAddOns = JSON.parse(results);
    }
    //SF-5291,SF-5292
    addSalesForcedAddOns() {
        this.salesAddOns = this.productAddOns?.salesAddOns;
        if (!SBRUtils.isEmpty(this.salesAddOns)) {
            //Filtering sales forced addons
            this.salesAddOns.forEach(salesAddOn => {
                let addOnSalesProdname = salesAddOn?.name;
                let hasFuelProductSales=addOnSalesProdname.indexOf('Refill') !== -1 || addOnSalesProdname.indexOf('Fuel Convenience Charge') !== -1?true:false;
               if (hasFuelProductSales) {//SF-5879
                    this.addForcedAddOn(salesAddOn, false, true);
                }
            })
        } else {
            console.warn('No sales addons found for the selected product');
        }
  }
     //SF-5291,SF-5292
     addRentalForcedAddOns() {
        this.rentalAddOns = this.productAddOns?.rentalAddOns;
        if (!SBRUtils.isEmpty(this.rentalAddOns)) {
            //Filtering rental forced addons OR //SF-5291,SF-5292
            this.rentalAddOns.forEach(rentalAddon => {
                let addOnRentalProdname = rentalAddon?.name;
                let hasFuelProductRental=addOnRentalProdname.indexOf('Refill') !== -1 || addOnRentalProdname.indexOf('Fuel Convenience Charge') !== -1?true:false;
                if (hasFuelProductRental) {//SF-5879
                    this.addForcedAddOn(rentalAddon, true, false);
                }
            });
        } else {
            console.warn('No rental addons found for the selected product');
        }
    }
    //SF-5291,SF-5292
    addForcedAddOn(forcedAddOnData, isRentalAddOn, isSalesAddOn) {
      if (this.objectApiName === 'SBQQ__Quote__c') {
            //Item searched and added from Quote record
            let fields = this.getForcedAddOnFieldsQuoteLine(forcedAddOnData,isRentalAddOn, isSalesAddOn);
            let lineItemRecordInput = {
                apiName: QUOTE_LINE_OBJECT.objectApiName,
                fields
            };
            //Add forced addon as line item
            this.lineItemRecsToInsert.push(lineItemRecordInput);
           

        } else if (this.objectApiName === 'Order') {
            //Item searched and added from Order record
            let fields = this.getForcedAddOnFieldsOrderItem(forcedAddOnData,isRentalAddOn, isSalesAddOn);
            let lineItemRecordInput = {
                apiName: ORDER_ITEM_OBJECT.objectApiName,
                fields
            };
            //Add forced addon as line item
            this.lineItemRecsToInsert.push(lineItemRecordInput);
        }
    }
     //SF-5291,SF-5292
    getForcedAddOnFieldsQuoteLine(forcedAddOnData,isRentalAddOn, isSalesAddOn) {
       let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
       let addOnQuoteProdname=forcedAddOnData?.name;//SF-5291,SF-5292
       let hasQuoteFuelProduct=(addOnQuoteProdname && (addOnQuoteProdname.indexOf('Refill') !== -1 || addOnQuoteProdname.indexOf('Fuel Convenience Charge') !== -1))?true:false;//SF-5291,SF-5292 
        //SF-6248, Scenario 2
        const parentQuantity = parseInt(this.template.querySelector("lightning-input[data-my-id=item-quantity]").value);
        const forcedAddOnLineQuantity = this.parseQuantityValue(forcedAddOnData?.minQuantity);

        let fields = {
            SBQQ__Quote__c: this.recordId,
            SBQQ__Quantity__c: hasQuoteFuelProduct ? forcedAddOnLineQuantity*parentQuantity : forcedAddOnLineQuantity,
            SBQQ__Product__c: forcedAddOnData?.id,
            Min_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
            Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
            Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
            Total_Price__c: 0,
            Suggested_Minimum_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Suggested_Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Suggested_Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
            Suggested_Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
            Suggested_Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
            Line_Item_Type__c: 'VS',
            is_User_Added__c: true,
            is_Forced_Item__c:forcedAddOnData?.isRequired?true:false,//SF-5879
            SBQQ__UnitCost__c: this.parseRateValue(forcedAddOnData?.sellPrice),
            Selling_Price__c: this.parseRateValue(forcedAddOnData?.sellPrice),
            Kit_Number_this_Item_Belongs_to__c: hasQuoteFuelProduct? this.lineItem.Product_SKU__c : '', //SF-5291,SF-5292
            Line_Comments__c:hasQuoteFuelProduct && this.lineItem?.Name?'Fuel Plan for '+this.lineItem.Name:'',//SF-5997
            Misc_Charge__c: forcedAddOnData?.productType === 'MISC' ? this.parseRateValue(forcedAddOnData?.sellPrice) : 0
        };

        console.log('Fuel line item fields->' + JSON.stringify(fields));
        return fields;
    }
    //SF-5291,SF-5292
    getForcedAddOnFieldsOrderItem(forcedAddOnData,isRentalAddOn, isSalesAddOn) {
        let productInfo = this.getForcedAddOnProductInfo(forcedAddOnData);
        let addOnOrderProdname=forcedAddOnData?.name;
        let hasOrderFuelProduct=(addOnOrderProdname && (addOnOrderProdname.indexOf('Refill') !== -1 || addOnOrderProdname.indexOf('Fuel Convenience Charge') !== -1))?true:false;//SF-5291,SF-5292
        let fields = {
            OrderId: this.recordId,
            Product2Id: forcedAddOnData?.id,
            Cat_Class__c: forcedAddOnData?.catClass,
            Quantity: this.parseQuantityValue(forcedAddOnData?.minQuantity),
            Min_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
            Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
            Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
            Total_Price__c: 0,
            Suggested_Minimum_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Suggested_Hourly_Rate__c: this.parseRateValue(forcedAddOnData?.minRate),
            Suggested_Daily_Rate__c: this.parseRateValue(forcedAddOnData?.ratesDaily),
            Suggested_Weekly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesWeekly),
            Suggested_Monthly_Rate__c: this.parseRateValue(forcedAddOnData?.ratesMonthly),
            Line_Item_Type__c: 'VS',
            is_User_Added__c: true,
            is_Forced_Item__c: forcedAddOnData?.isRequired?true:false,//SF-5879
            Selling_Price__c: this.parseRateValue(forcedAddOnData?.sellPrice),
            UnitPrice: this.parseRateValue(forcedAddOnData?.sellPrice),
            Kit_Number_This_Item_Belongs_To__c: hasOrderFuelProduct ? this.lineItem.Product_SKU__c : '', //SF-5291,SF-5292
            Line_Comments__c:hasOrderFuelProduct && this.lineItem?.Name?'Fuel Plan for '+this.lineItem.Name:'',//SF-5997
            Misc_Charge__c: forcedAddOnData?.productType === 'MISC' ? this.parseRateValue(forcedAddOnData?.sellPrice) : 0
        };
        return fields;
    }
   //SF-5291,SF-5292
    getForcedAddOnProductInfo(forcedAddOnData) {
        let productInfo = {
            productType: forcedAddOnData?.productType,
            inventoriedItem: forcedAddOnData?.inventoriedItem,
            miscellaneousChargeItem: forcedAddOnData?.miscellaneousChargeItem,
            stockClass: forcedAddOnData?.stockClass,
        }
        return productInfo;
    }
    //SF-5291,SF-5292
    createFuelPlanLineItemRecords() {
       
        if (this.hasExistingFC) {

            const evt = new ShowToastEvent({
                title: "Info",
                    message: "Fuel Plan already exists for this Product",
                    variant: "info",
              });
              this.dispatchEvent(evt);

            return false;
        }

           
        return createLineItems({ apiName: this.objectApiName, lineItems: JSON.stringify(this.lineItemRecsToInsert) })
            .then((createdLineItemRecords) => {
                createdLineItemRecords.forEach(createdLineItem => {
                    const payload = {
                        recordId: this.recordId,
                        lineItem: createdLineItem,
                        type: "add"
                    };
                    publish(this.messageContext, updateLineItemsChannel, payload);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Success",
                            message: "Line items were successfully added",
                            variant: "success"
                        })
                    );


                })
                return true;
            }).catch((error) => {
                let errorMsg = JSON.stringify(error);
                console.log('errorMsg',errorMsg)
                if (errorMsg.includes('INSUFFICIENT_ACCESS')) {
                    errorMsg = 'You do not have sufficient rights to add the item(s)';
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error adding line items',
                        message: errorMsg,
                        variant: 'error',
                    }),
                );
                return false;
            });
    }
     //SF-5291,SF-5292
    parseRateValue(rateValue) {
        if (!SBRUtils.isEmpty(rateValue)) {
            return rateValue === 'n/a' || rateValue === 'null' ? 0 : rateValue;
        }
        return 0;
    }
     //SF-5291,SF-5292
    getLineItemType(obj) {
        let result = '';
        if (obj?.productType === 'Cat-Class' || obj.productType.includes('altInventory')) {
            result = 'VR';
        } else if (obj?.inventoriedItem && (obj?.productType === 'Parts' || obj?.productType === 'Merchandise')) {
            result = 'VS';
        } else if (obj?.miscellaneousChargeItem && !(obj?.productType === 'Parts' || obj?.productType === 'Merchandise' || obj?.productType === 'DEL')) {
            result = 'YC';
        } else if (obj?.miscellaneousChargeItem && obj?.typeOfMiscChargeItem === 'MS' && obj?.stockClass === 'DEL') {
            result = 'YD';
        }

        return result;
    }
     //SF-5291,SF-5292
    parseQuantityValue(quantityValue) {
        if (!SBRUtils.isEmpty(quantityValue)) {
            return quantityValue === 'n/a' || null ? 1 : quantityValue;
        }
        return 1;
    }

}