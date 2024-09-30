import { LightningElement,api,track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PC_OBJECT from '@salesforce/schema/ProductConsumed';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getRecords } from 'lightning/uiRecordApi';
import PROD_ITEM from '@salesforce/schema/ProductConsumed.SF_PS_Product_Item__c';
import COST_PRICE from '@salesforce/schema/ProductConsumed.Product2.Average_Cost__c';
import LAST_COST from '@salesforce/schema/ProductConsumed.Product2.Last_Cost__c';
import PROFT_PERCENT from '@salesforce/schema/ProductConsumed.Product2.Expected_Profit_Percent__c';
import FRIEGHT_PERCENT from '@salesforce/schema/ProductConsumed.Product2.Freight_Percentage__c';
import BRANCH_LOC from '@salesforce/schema/ProductConsumed.WorkOrder.ServiceTerritory.Branch_Location_Number__c';
import COMP_CODE from '@salesforce/schema/ProductConsumed.WorkOrder.SF_PS_Company_Code__c';
import BILL_CUST from '@salesforce/schema/ProductConsumed.WorkOrder.SF_PS_BillCustOrLoc__c';
import PRIMARY_PART from '@salesforce/schema/ProductConsumed.SF_PS_Is_Primary_Part__c';
import ITEM_TYPE from '@salesforce/schema/ProductConsumed.SF_PS_ItemType__c';
//import WO_SELF_SCHEDULED_FIELD from '@salesforce/schema/WorkOrder.SF_PS_Is_Self_Schedule__c';
import PROD_ITEM_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_ProductItem__c';
import COST_PRICE_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_Product2Id__r.Average_Cost__c';
import LAST_COST_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_Product2Id__r.Last_Cost__c';
import PROFT_PERCENT_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_Product2Id__r.Expected_Profit_Percent__c';
import FRIEGHT_PERCENT_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_Product2Id__r.Freight_Percentage__c';
import BRANCH_LOC_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_WorkOrderId__r.ServiceTerritory.Branch_Location_Number__c';
import COMP_CODE_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_WorkOrderId__r.SF_PS_Company_Code__c';
import BILL_CUST_QP from '@salesforce/schema/SF_PS_Quoted_Part__c.SF_PS_WorkOrderId__r.SF_PS_BillCustOrLoc__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import lightningConfirmModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import { IsConsoleNavigation, getFocusedTabInfo,closeTab } from 'lightning/platformWorkspaceApi';

const PRODUCT_CONSM_FIELDS = [
                                PROD_ITEM,
                                COST_PRICE,
                                LAST_COST,
                                PROFT_PERCENT,
                                FRIEGHT_PERCENT,
                                BRANCH_LOC,
                                COMP_CODE,
                                BILL_CUST,
                                PRIMARY_PART,
                                ITEM_TYPE
                            ]

const QUOTED_PART_FIELDS =  [
                                PROD_ITEM_QP,
                                COST_PRICE_QP,
                                LAST_COST_QP,
                                PROFT_PERCENT_QP,
                                FRIEGHT_PERCENT_QP,
                                BRANCH_LOC_QP,
                                COMP_CODE_QP,
                                BILL_CUST_QP
                            ]


// eslint-disable-next-line @lwc/lwc/no-leading-uppercase-api-name
export default class Sbr_3_0_sfsDesktopEditPartsLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api WorkOrderId;
    @api objectApiName;
    @api props

    @track changeValues={};
    @track state = { isLoading: false };

    expected_Profit_Percent__c
    freight_Percentage__c
    companyCode
    billCust
    productItemId
    branchLoc
    additionalQuery
    record;
    extended;
    confirm=false;
    isDiscountDisabled=false;
    QuantityNegativeError = false;
    itemType;

    //Wire method to get whether current tab in console app or not
    @wire(IsConsoleNavigation) isConsoleNavigation;

    //wire method to get related record data
    @wire(getRecord, { recordId: '$recordId', fields: '$fields'})
    getProductConsumed( {error, data} ) {
        if (error) {
            console.log('Error in Wire method::' + JSON.stringify(error))
            // this.state.isLoading = false;
        } else if (data) {
            this.handleData(data);
            console.log("inside wire method" + JSON.stringify(data));
            console.log("Change Values inside wire::"+JSON.stringify(this.changeValues));
            this.additionalQuery = `Location.Company_Code__c='${this.companyCode}' and Location.Branch_Location_Number__c='${this.branchLoc}' and QuantityOnHand>0 `;
            this.state.isLoading = false;
        }
    }


    //Method to handle received data from wire getProductConsumed
    handleData(data)
    {
        if(this.objectApiName=='ProductConsumed')
        {
            this.productItemId=data.fields.SF_PS_Product_Item__c.value;
            this.billCust=data.fields.WorkOrder.value.fields.SF_PS_BillCustOrLoc__c.value;
            this.companyCode=data.fields.WorkOrder.value.fields.SF_PS_Company_Code__c.value;
            this.changeValues.Expected_Profit_Percent__c=data.fields.Product2.value.fields.Expected_Profit_Percent__c.value;
            this.branchLoc=data.fields.WorkOrder.value.fields.ServiceTerritory.value.fields.Branch_Location_Number__c.value;
            this.changeValues.Freight_Percentage__c=data.fields.Product2.value.fields.Freight_Percentage__c.value;
            this.changeValues.SF_PS_Last_Cost=data.fields.Product2.value.fields.Last_Cost__c.value;
            this.changeValues.SF_PS_Cost_Price__c=data.fields.Product2.value.fields.Average_Cost__c.value;
            this.changeValues.isErrorDiscount=false;
            this.changeValues.minPriceError=false;
            this.changeValues.isPrimaryPart= data?.fields?.SF_PS_Is_Primary_Part__c.value;
            this.itemType = data?.fields?.SF_PS_ItemType__c.value;
            this.state.isLoading = false;
        }
        else if(this.objectApiName=='SF_PS_Quoted_Part__c'){
            this.productItemId=data.fields.SF_PS_ProductItem__c.value;
            this.billCust=data.fields.SF_PS_WorkOrderId__r.value.fields.SF_PS_BillCustOrLoc__c.value;
            this.companyCode=data.fields.SF_PS_WorkOrderId__r.value.fields.SF_PS_Company_Code__c.value;
            this.branchLoc=data.fields.SF_PS_WorkOrderId__r.value.fields.ServiceTerritory.value.fields.Branch_Location_Number__c.value;
            this.changeValues.Expected_Profit_Percent__c=data.fields.SF_PS_Product2Id__r?.value?.fields?.Expected_Profit_Percent__c.value;
            this.changeValues.Freight_Percentage__c=data.fields.SF_PS_Product2Id__r?.value?.fields?.Freight_Percentage__c.value;
            this.changeValues.SF_PS_Last_Cost=data.fields.SF_PS_Product2Id__r?.value?.fields?.Last_Cost__c.value;
            this.changeValues.SF_PS_Cost_Price__c=data.fields.SF_PS_Product2Id__r?.value?.fields?.Average_Cost__c.value;
            this.changeValues.isErrorDiscount=false;
            this.changeValues.minPriceError=false;

        }
        if(this.billCust=='L' && this.itemType == 'MI'){
            this.isDiscountDisabled=false;
        }
        else if(this.billCust=='L'){
            this.isDiscountDisabled=true;
        }else{
            this.isDiscountDisabled=false;
        }

    }

    //getter method to decide fields required to send in above wire method
    get fields() {
        if (this.objectApiName === "ProductConsumed") {
            return PRODUCT_CONSM_FIELDS;
        } else if(this.objectApiName === "SF_PS_Quoted_Part__c") {
            return QUOTED_PART_FIELDS;
        }
    }

    //Getter method to decide whether need to disable save button
    get checkValidations(){
        if(this.QuantityNegativeError || this.changeValues.isErrorDiscount || this.changeValues.minPriceError)
        {
            return true;
        }
        return false;
    }

    //LWC hook
    connectedCallback() {
        console.log("props in hook" + JSON.stringify(this.props));

        this.state.isLoading = true;
        this.props = this.props == undefined || this.props == null ? {} : JSON.parse(JSON.stringify(this.props));
    }

    //On Submit event handler to perform custom logic
    async onSubmit(event) {debugger;
        console.log('fields are  '+JSON.stringify(event.detail.fields))
        event.preventDefault();
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
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }else{
            this.state.isLoading=false;
        }
    }

    //On Success event handler to handle tab navigation and toast message on successful update
    onSuccess(event) {
        this.state.isLoading = false;
        this.props.recordid = event.detail.id;
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

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: this.props.objectapiname,
                actionName: 'view'
            },
        });


    }

    //On Load event handler for record edit form to assign value fetched from form
    onLoad(event) {
        // this.state.isLoading = false;
        this.state.isLoading=false;
        this.record = event.detail.records;
        let fields = this.record[this.recordId].fields;
        console.log('Fields: '+JSON.stringify(fields));
        this.changeValues.SF_PS_Quantity__c= fields.SF_PS_Quantity__c?.value;
        this.changeValues.SF_PS_Cost_Price__c= fields.SF_PS_Cost_Price__c?.value;
        this.changeValues.SF_PS_Selling_Price__c= fields.SF_PS_Selling_Price__c?.value;
        this.changeValues.SF_PS_Discount_Percentage__c=fields.SF_PS_Discount_Percentage__c?.value;
        this.changeValues.SF_PS_Orig_Selling_Price__c=fields.SF_PS_Orig_Selling_Price__c?.value;
        this.changeValues.partType=fields.SF_PS_Parts_Type__c?.value;
        console.log('Change vaues in onLoad'+ JSON.stringify(this.changeValues));
        this.checkExtended(this.changeValues);
        if( this.changeValues.partType!='Without Inventory'){
            this.handleWarningAndErors(this.changeValues);
        }
    //     }else{
    //     this.template.querySelector('[data-name="SF_PS_Cost_Price__c"]').disabled = false;
    //     this.template.querySelector('[data-name="SF_PS_List_Price__c"]').disabled = false;
    //     this.template.querySelector('[data-name="SF_PS_Orig_Selling_Price__c"]').disabled = false;
    //     this.template.querySelector('[data-name="SM_PS_Description__c"]').disabled = false;

    // }

    }

    //On Error event to show error in toast message if any error occured
    onError(event) {
        this.state.isLoading = false;
        //this.btnToggel();
        // this.insertLog({ Class__c: ‘LwcRecordEditForm’, Method__c: ‘onError’, User__c: this.getuserInfo(), User_ID_Text__c: this.getuserInfo(), Type__c: ‘UI’, Message_Text__c: JSON.stringify(event) }); //Reserved for future use
        //this.showToastMessage('ERROR', 'error', 'DETAIL : ' + '\n' + '\n ${event.detail.detail}');
        let message = '';
        if (event.detail.detail)
        {
            message = event.detail.detail;
        }
        else if(event.detail.message)
        {
            message = event.detail.message;
        }
        this.showToastMessage('ERROR', 'error', 'DETAIL : ' + '\n' + '\n ' + message);
        // Click on this link to show more way of customizing Error :https://developer.salesforce.com/docs/component-library/bundle/lightning-record-edit-form/documentation

    }

    //getter method to get UI measure for field
    get fieldWidth() {
        return (FORM_FACTOR == 'Large') ? this.props.largeff : this.props.smallff;
    }

    //Method to perform input data validation in all input fields
    checkValidation() {
        const allValid = [...this.template.querySelectorAll('lightning-input-field')]
            .reduce((validSoFar, inputCmp) => {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }, true);
        return allValid;
    }

    // Handele parts# chnage
    handleProductItemChange(event){
        let productItemId = event.detail.selectedRecord.Id;
        this.props.SF_PS_Product_Item__c = productItemId;
    }

    //Method to check if qty or cost price is updated
    handleChange(event){
        console.log('datachanged inside handlechange event' +event.target.value+'--'+event.target.name);
        let name=event.target.name;
        this.changeValues[name]=event.target.value;
        if(name=='SF_PS_Quantity__c'||name=='SF_PS_Cost_Price__c')
        {
            if(this.changeValues[name] < 1 && name=='SF_PS_Quantity__c' && this.changeValues[name]){
                this.props.fieldSetFive.find(data => data.apiname === 'SF_PS_Quantity__c').invalidValueError=true; 
                this.QuantityNegativeError = true;
            } else {
                this.props.fieldSetFive.find(data => data.apiname === 'SF_PS_Quantity__c').invalidValueError=false; 
                this.QuantityNegativeError = false;
                this.checkExtended(this.changeValues);
            }
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

    //Method to perform extended amount
    checkExtended(selectedRecord){
        //quantity= this.template.querySelector('lightning-record-edit-form').
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
                recordId: this.recordId,
                objectApiName: this.props.objectapiname,
                actionName: 'view'
            },
        });
        return false;
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
        if( this.changeValues.partType!='Without Inventory'){
		    this.handleWarningAndErors(selectedRecord);
        }

	}


    //Method to validate for warning and min price error
    handleWarningAndErors(selectedRecord){
        console.log("HANDLE WARNING STSR")
		//Last_Cost__c
		let warningPrice=selectedRecord.SF_PS_Last_Cost+((selectedRecord.Expected_Profit_Percent__c*selectedRecord.SF_PS_Last_Cost)/100);
		let errorPrice =selectedRecord.SF_PS_Cost_Price__c+((selectedRecord.Freight_Percentage__c*selectedRecord.SF_PS_Cost_Price__c)/100);
		selectedRecord.SF_PS_Warning_Price__c=warningPrice;
		selectedRecord.SF_PS_Error_Price__c=errorPrice;
		// Error
		if(this.billCust!='L' && (selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Error_Price__c) && !this.priceReadOnly){
			selectedRecord.minPriceError = true;
		}
		else{
			selectedRecord.minPriceError = false;
		}

		if(this.billCust!='L' && selectedRecord.SF_PS_Cost_Price__c && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Cost_Price__c && !this.priceReadOnly){
			selectedRecord.avgError = true;
			//selectedRecord.avgErrorMessage='Selling price cannot be more than avg price';
		}
		else{
			selectedRecord.avgError = false;
		}
		// Warning
		if(( this.billCust!='L' && !selectedRecord.minPriceError && selectedRecord.SF_PS_Selling_Price__c < selectedRecord.SF_PS_Warning_Price__c) && !this.priceReadOnly){
			selectedRecord.warningError = true;
		}
		else{
			selectedRecord.warningError = false;
		}

        console.log("HANDLE WARNING END")
    }

    //Method to handle new selling price change
    handleSellingPriceChange(event){
		let selectedRecord = this.changeValues;
		console.log('Selected Row on selling price change :: '+JSON.stringify(selectedRecord));
		selectedRecord.SF_PS_Selling_Price__c = event.target.value;
		console.log('new selling price::'+selectedRecord.SF_PS_Selling_Price__c);
		selectedRecord.isErrorsellingPrice = false;
		selectedRecord.avgError = false;
        if( this.changeValues.partType!='Without Inventory'){
    	this.handleWarningAndErors(selectedRecord);
        }
		//Discount Calculation
		if(selectedRecord.SF_PS_Orig_Selling_Price__c>=0 && selectedRecord.SF_PS_Selling_Price__c>=0 && selectedRecord.SF_PS_Orig_Selling_Price__c >selectedRecord.SF_PS_Selling_Price__c && this.billCust!='L'){
			selectedRecord.SF_PS_Discount_Percentage__c=(((selectedRecord.SF_PS_Orig_Selling_Price__c - selectedRecord.SF_PS_Selling_Price__c)/selectedRecord.SF_PS_Orig_Selling_Price__c)*100).toFixed(2);
        }
		else {
            selectedRecord.SF_PS_Discount_Percentage__c=0;
			selectedRecord.isErrorDiscount=false;
		}

		this.checkExtended(selectedRecord);
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

}