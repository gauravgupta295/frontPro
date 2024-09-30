import { LightningElement,wire,api } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { refreshApex } from '@salesforce/apex';
import Power_Of_Sunbelt_Summary_Title from '@salesforce/label/c.SBR_3_0_CMM_Power_Of_Sunbelt_Summary_Title';
import Recommendations_Title from '@salesforce/label/c.SBR_3_0_CMM_Recommendations_Title';

import getMaturityModelResponse from '@salesforce/apex/SBR_3_0_CustomerMaturityModelController.getMaturityModelResponse';
import getCustomMetadataResponse from '@salesforce/apex/SBR_3_0_CustomerMaturityModelController.getCustomMetadataResponse';

export default class SBR_3_0_CustomerMaturityModel extends LightningElement {
    isLoaded = false; /* This variable is used to control loader in the component */
    deviceTypeDesktp; /* This variable is used to determine the device that component is opened as Desktop */
    deviceTypeTablet; /* This variable is used to determine the device that component is opened as Tablet */
    deviceTypeMobile; /* This variable is used to determine the device that component is opened as Mobile */
    
    CurrentLOBUsed; /* This variable is used to calculate lobValue from the response if record type is 2*/
    NoOfProductsRented; /* This variable is used to calculate usedQty from the response */
    CurrentTTMSpent; /* This variable is used to calculate TTM Spent from Salesforce Customer Spend Object based in catClassKey*/
    PotentialLOBUsed; /* This variable is used to calculate lobValue from the response if record type is 1*/
    CurrentLOB; /* This variable is used to calculate TTM Spent,PercentageOfTotal,NoOfProductsRentedOut from Salesforce Customer Spend Object based in catClassKey if recordtype is 2*/
    PotentialLOB; /* This variable is used to calculate Name from response lob if recordtype is 1*/
    isCurrentLOBNULL; /* This variable is used to show Error message LOB's on page*/
    isPotentialLOBNULL; /* This variable is used to show only Current LOB's on page*/
    isServerDown; /* This variable is used to show Sercer down message on page*/
    isServerUpWithError; /* This variable is used to show Sercer down message on page*/
    _recordId; /* This variable is used to capture the record id from the Page */
    isUpsellNULL;
    isCrosssellNULL;
    UpSellResponse;
    CrossSellResponse;
    errorMessage;
    errorMessageRec;
    accountRec;
    ShowPowerOfSunbeltSummaryTab = true;
    ShowRecommendationTab = false;
    isOfficeAccount;
    response;
    AccountDetails;
    

    Tile_Current_LOB_Used;
    Tile_TTM_Spend;
    Tile_No_of_Products_Rented;
    Tile_Potential_LOB;
    Title_Current_Lines_of_Business_LOB;
    Title_Additional_Potential_Lines;
    
    Title_Select_thumbs_up_thumbs_down;
    Table_Title_Upsell;
    Table_Title_Cross_Sell;
    Table_Column_Cat_Class;
    Table_Column_Description;
    Table_Column_Feedback;
    Button_Submit_Feedback;

    Error_loading_data_Please_refresh_or_co;
    There_are_no_current_Lines_of_Business;
    There_are_no_Recommendations;
    Please_provide_any_comments_on_the_recom;

    @api set recordId(value) {
        this._recordId = value;
    }
    get recordId() {
        return this._recordId;
    }
    handleModalRefresh(){
        this.isLoaded = false;
        getMaturityModelResponse({recordId: this.recordId})
			.then((data) => {
                this.isLoaded = true;
                this.CurrentLOBUsed = data.CurrentLOBUsed;
                this.NoOfProductsRented = data.NoOfProductsRented;
                this.CurrentTTMSpent = data.CurrentTTMSpent;
                this.PotentialLOBUsed = data.PotentialLOBUsed;
                this.CurrentLOB = data.CurrentLOB;
                this.PotentialLOB = data.PotentialLOB;
                this.isCurrentLOBNULL = data.isCurrentLOBNULL;
                this.isPotentialLOBNULL = data.isPotentialLOBNULL;
                this.UpSellResponse = data.UpSellResponse;
                this.CrossSellResponse = data.CrossSellResponse;
                this.isUpsellNULL = data.isUpsellNULL;
                this.isCrosssellNULL = data.isCrosssellNULL;
                this.isServerDown = false;
                this.accountRec = data.accountRec;
                this.isOfficeAccount = data.isOfficeAccount;
                if(data.isOfficeAccount){
                    this.AccountDetails = "Account Number: "+data.AccountNumber+", "+"Account Name: "+ data.AccountName;
                }
            })
			.catch((error) => {
                this.response = error;
                this.CurrentLOBUsed = '0';
                this.NoOfProductsRented = '0';
                this.CurrentTTMSpent = '$0';
                this.isCurrentLOBNULL = true;
                this.isPotentialLOBNULL = true;
                this.isUpsellNULL = true;
                this.isCrosssellNULL = true;
                this.isLoaded = true;
                this.isServerDown = true;
                let errorObj = error.body.message;
                if(errorObj.includes("::")){
                    let errorObjList = errorObj.split("::");
                    this.errorMessage = errorObjList[1];
                    let errorResponse = errorObjList[0];
                    errorResponse = errorResponse.substring(23);
                    const keyValuePairs = errorResponse.split(', ');
                    let parsedObject = {};
                    keyValuePairs.forEach(pair => {
                        const [key, value] = pair.split('=');
                        parsedObject[key] = value === 'null' ? null : value;
                    });
                    if(parsedObject){
                        this.isOfficeAccount = parsedObject.isOfficeAccount === 'true';
                        if(this.isOfficeAccount){
                            this.AccountDetails = "Account Number: "+parsedObject.AccountNumber+", "+"Account Name: "+ parsedObject.AccountName;
                        }
                    }
                    
                    if(this.errorMessage ==  this.There_are_no_current_Lines_of_Business){
                        this.isServerUpWithError = true;
                        this.errorMessageRec = this.There_are_no_Recommendations;
                    }
                    else{
                        this.isServerUpWithError = true;
                        this.errorMessageRec = this.errorMessage;
                    }
                }
                if(this.errorMessage == this.Error_loading_data_Please_refresh_or_co){
                    this.isServerUpWithError = false;
                    this.errorMessageRec = this.errorMessage;
                }
                else if(this.errorMessage ==  this.There_are_no_current_Lines_of_Business){
                    this.isServerUpWithError = true;
                    this.errorMessageRec = this.There_are_no_Recommendations;
                }
                else{
                    this.isServerUpWithError = true;
                    this.errorMessageRec = this.errorMessage;
                }
            });
    }
    ShowPowerOfSunbeltSummary() {
        const Power_Of_Sunbelt_Summary = this.template.querySelector('.slds-tabs_default__item.power-summary');
        Power_Of_Sunbelt_Summary.setAttribute('class', 'slds-tabs_default__item slds-is-active power-summary');
        Power_Of_Sunbelt_Summary.setAttribute('title', Power_Of_Sunbelt_Summary_Title);
    
        const Recommendations = this.template.querySelector('.slds-tabs_default__item.recommendations');
        Recommendations.setAttribute('class', 'slds-tabs_default__item recommendations');
        Recommendations.setAttribute('title', Recommendations_Title);
    
        this.ShowPowerOfSunbeltSummaryTab = true;
        this.ShowRecommendationTab = false;
    }
    
    ShowRecommendation() {
        const Recommendations = this.template.querySelector('.slds-tabs_default__item.recommendations');
        Recommendations.setAttribute('class', 'slds-tabs_default__item slds-is-active recommendations');
        Recommendations.setAttribute('title', Recommendations_Title);
        const Power_Of_Sunbelt_Summary = this.template.querySelector('.slds-tabs_default__item.power-summary');
        Power_Of_Sunbelt_Summary.setAttribute('class', 'slds-tabs_default__item power-summary');
        Power_Of_Sunbelt_Summary.setAttribute('title', Power_Of_Sunbelt_Summary_Title);
        this.ShowRecommendationTab = true;
        this.ShowPowerOfSunbeltSummaryTab = false;
    }
    connectedCallback() {
        if (FORM_FACTOR === "Large") {
            this.deviceTypeDesktp = true;
        } 
        else if (FORM_FACTOR === "Medium") {
            this.deviceTypeTablet = true;
        } 
        else if (FORM_FACTOR === "Small") {
            this.deviceTypeMobile = true;
        }
    }
    @wire(getCustomMetadataResponse)
    wiredCustomMetadataResponse({ error, data }) {
        if (data) {
            this.Tile_Current_LOB_Used = data['Tile_Current_LOB_Used'].Label_Value__c;
            this.Tile_TTM_Spend = data['Tile_TTM_Spend'].Label_Value__c;
            this.Tile_No_of_Products_Rented = data['Tile_No_of_Products_Rented'].Label_Value__c;
            this.Tile_Potential_LOB = data['Tile_Potential_LOB'].Label_Value__c;
            this.Title_Current_Lines_of_Business_LOB = data['Title_Current_Lines_of_Business_LOB'].Label_Value__c;
            this.Title_Additional_Potential_Lines = data['Title_Additional_Potential_Lines'].Label_Value__c;
            this.Title_Select_thumbs_up_thumbs_down = data['Title_Select_thumbs_up_thumbs_down'].Label_Value__c;
            this.Table_Title_Upsell = data['Table_Title_Upsell'].Label_Value__c;
            this.Table_Title_Cross_Sell = data['Table_Title_Cross_Sell'].Label_Value__c;
            this.Table_Column_Cat_Class = data['Table_Column_Cat_Class'].Label_Value__c;
            this.Table_Column_Description = data['Table_Column_Description'].Label_Value__c;
            this.Table_Column_Feedback = data['Table_Column_Feedback'].Label_Value__c;
            this.Button_Submit_Feedback = data['Button_Submit_Feedback'].Label_Value__c;
            this.Error_loading_data_Please_refresh_or_co = data['Error_loading_data_Please_refresh_or_co'].Label_Value__c;
            this.There_are_no_current_Lines_of_Business = data['There_are_no_current_Lines_of_Business'].Label_Value__c;
            this.There_are_no_Recommendations = data['There_are_no_Recommendations'].Label_Value__c;
            this.Please_provide_any_comments_on_the_recom = data['Please_provide_any_comments_on_the_recom'].Label_Value__c;
        } 
        else if (error) {
            this.isLoaded = true;
        }
    }
    @wire(getMaturityModelResponse, {recordId: "$recordId"})
    wiredResponse({ error, data }) {
        if (data) {
            this.response = data;
            this.isLoaded = true;
            this.CurrentLOBUsed = data.CurrentLOBUsed;
            this.NoOfProductsRented = data.NoOfProductsRented;
            this.CurrentTTMSpent = data.CurrentTTMSpent;
            this.PotentialLOBUsed = data.PotentialLOBUsed;
            this.CurrentLOB = data.CurrentLOB;
            this.PotentialLOB = data.PotentialLOB;
            this.isCurrentLOBNULL = data.isCurrentLOBNULL;
            this.isPotentialLOBNULL = data.isPotentialLOBNULL;
            this.UpSellResponse = data.UpSellResponse;
            this.CrossSellResponse = data.CrossSellResponse;
            this.isUpsellNULL = data.isUpsellNULL;
            this.isCrosssellNULL = data.isCrosssellNULL;
            this.isServerDown = false;
            this.accountRec = data.accountRec;
            this.isOfficeAccount = data.isOfficeAccount;
            if(data.isOfficeAccount){
                this.AccountDetails = "Account Number: "+data.AccountNumber+", "+"Account Name: "+ data.AccountName;
            }
        } 
        else if (error) {
            this.response = error;
            this.CurrentLOBUsed = '0';
            this.NoOfProductsRented = '0';
            this.CurrentTTMSpent = '$0';
            this.isCurrentLOBNULL = true;
            this.isPotentialLOBNULL = true;
            this.isUpsellNULL = true;
            this.isCrosssellNULL = true;
            this.isLoaded = true;
            this.isServerDown = true;
            let errorObj = error.body.message;
            let errorObjList = errorObj.split("::");
            this.errorMessage = errorObjList[1];
            let errorResponse = errorObjList[0];
            errorResponse = errorResponse.substring(23);
            const keyValuePairs = errorResponse.split(', ');
            let parsedObject = {};
            keyValuePairs.forEach(pair => {
                const [key, value] = pair.split('=');
                parsedObject[key] = value === 'null' ? null : value;
            });
            if(parsedObject){
                this.isOfficeAccount = parsedObject.isOfficeAccount === 'true';
                if(this.isOfficeAccount){
                    this.AccountDetails = "Account Number: "+parsedObject.AccountNumber+", "+"Account Name: "+ parsedObject.AccountName;
                }
            }
            if(this.errorMessage == this.Error_loading_data_Please_refresh_or_co){
                this.isServerUpWithError = false;
                this.errorMessageRec = this.errorMessage;
            }
            else if(this.errorMessage ==  this.There_are_no_current_Lines_of_Business){
                this.isServerUpWithError = true;
                this.errorMessageRec = this.There_are_no_Recommendations;
            }
            else{
                this.isServerUpWithError = true;
                this.errorMessageRec = this.errorMessage;
            }
        }
    }

    label = {
        Power_Of_Sunbelt_Summary_Title,
        Recommendations_Title,
	};
}