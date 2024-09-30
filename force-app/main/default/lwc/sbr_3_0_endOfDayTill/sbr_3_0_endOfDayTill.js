import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { RefreshEvent } from "lightning/refresh";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import currentUserId from '@salesforce/user/Id';
import getOAuthToken from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getOAuthToken';
import upsertTillRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.upsertTillRecord';
import getReasonRecords from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getReasonRecordsById';
import insertReasons from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertReasons';
import fetchCurrencies from '@salesforce/apex/Sbr_3_0_endOfDayTillController.fetchCurrencies'
import updateEODTill from "@salesforce/apex/SBR_3_0_API_UpdateEodTill.updateTillSummary";
import getEodTillRecords from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getEodTillRecord';
import USER_ID from '@salesforce/user/Id';
import apiparams from '@salesforce/label/c.EndOfDayTillAuth';
import refreshCardsSuccess from '@salesforce/label/c.SBR_3_0_Credt_Card_Transactions_Updated';
import todayTillErrorMessage from '@salesforce/label/c.sbr_3_0_TIllSubmitBeforeToday';
import END_OF_TILL_OBJECT from '@salesforce/schema/End_of_Day_Till__c';
import REASONS_OBJECT from '@salesforce/schema/Till_Over_Short_Reason__c';
import TILL_ID from '@salesforce/schema/End_of_Day_Till__c.Id';
import TILL_DATE_FIELD from '@salesforce/schema/End_of_Day_Till__c.Till_Date__c';
import TOTAL_CHECKS_FIELD from '@salesforce/schema/End_of_Day_Till__c.Total_Checks__c';
import STATUS from '@salesforce/schema/End_of_Day_Till__c.Status__c';
import TILL_STATUS from '@salesforce/schema/End_of_Day_Till__c.Till_Status__c';
import TOTAL_ROA_CHECKS_FIELD from '@salesforce/schema/End_of_Day_Till__c.Total_ROA_Checks__c';
import TOTAL_CURRENCY from '@salesforce/schema/End_of_Day_Till__c.Total_Currency__c';
import TOTAL_CASH from '@salesforce/schema/End_of_Day_Till__c.Total_Cash__c';
import TOTAL_DEPOSIT from '@salesforce/schema/End_of_Day_Till__c.Total_Deposit__c';
import TOTAL_DEPOSIT_IN_BANK from '@salesforce/schema/End_of_Day_Till__c.Total_Deposit_in_Bank__c';
import TOTAL_DRAWER from '@salesforce/schema/End_of_Day_Till__c.Total_Drawer__c';
import TOTAL_TRANSACTIONS from '@salesforce/schema/End_of_Day_Till__c.Total_Transaction__c'
import SUBMITTED_DATE from '@salesforce/schema/End_of_Day_Till__c.Submitted_Date__c';
import START_DRAWER from '@salesforce/schema/End_of_Day_Till__c.Start_Drawer__c'
import NEXT_DAY_DRAWER from '@salesforce/schema/End_of_Day_Till__c.Next_Day_Drawer__c'
import SUBMITTED_USER from '@salesforce/schema/End_of_Day_Till__c.Submitted_User__c';
import TOTAL_CREDIT_CARDS from '@salesforce/schema/End_of_Day_Till__c.Total_Credit_Cards__c';
import LESS_AUTO_DEPOSIT from '@salesforce/schema/End_of_Day_Till__c.Less_Auto_Deposit__c';
import LESS_ROA_AUTO_DEPOSIT from '@salesforce/schema/End_of_Day_Till__c.Less_ROA__c';
import ACCOUNTED_FOR from '@salesforce/schema/End_of_Day_Till__c.Accounted_For__c';

import REASON_AMOUNT from '@salesforce/schema/Till_Over_Short_Reason__c.Amount__c';
import REASON_COMMENT from '@salesforce/schema/Till_Over_Short_Reason__c.Comment__c';
import REASON_REASON from '@salesforce/schema/Till_Over_Short_Reason__c.Reason__c';
import REASON_PARENTID from '@salesforce/schema/Till_Over_Short_Reason__c.End_of_Day_Till__c';
//import radioGroupHorizontal from '@salesforce/resourceUrl/Sbr_3_0_RadioGroupHorizontal';
import { loadStyle } from 'lightning/platformResourceLoader';
import { makeEodAPICalls, openTabForDraftRecord, getInputValues, formatValueWithCurrencySign, formatDate } from 'c/sbr_3_0_eodTillHelper';
import getTillSummary from '@salesforce/apex/SBR_3_0_API_GetEodTillSummary.getTillSummary';

const billAmountFields = [
    { id: 'hundredBillAmountid', key: 'Drawer_Bills_Hundred__c', multiple: 100 },
    { id: 'fiftyBillAmountid', key: 'Drawer_Bills_Fifty__c', multiple: 50 },
    { id: 'twentyBillAmountid', key: 'Drawer_Bills_Twenty__c', multiple: 20 },
    { id: 'tenBillAmountid', key: 'Drawer_Bills_Ten__c', multiple: 10 },
    { id: 'fiveBillAmountid', key: 'Drawer_Bills_Five__c', multiple: 5 },
    { id: 'twoBillAmountid', key: 'Drawer_Bills_Two__c', multiple: 2 },
    { id: 'oneBillAmountid', key: 'Drawer_Bills_One__c', multiple: 1 }
];

const coinAmountFields = [
    { id: 'oneCoinAmountid', key: 'Drawer_Coins_One__c', multiple: 1 },
    { id: 'fiftyCoinAmountid', key: 'Drawer_Coins_Fifty__c', multiple: 0.50 },
    { id: 'twentyFiveCoinAmountid', key: 'Drawer_Coins_Quarter__c', multiple: 0.25 },
    { id: 'tenCoinAmountid', key: 'Drawer_Coins_Dime__c', multiple: 0.10 },
    { id: 'fiveCoinAmountid', key: 'Drawer_Coins_Nickel__c', multiple: 0.05 },
    { id: 'CoinCentAmountid', key: 'Drawer_Coins_Penny__c', multiple: 0.01 }
];

const allFields = [...billAmountFields, ...coinAmountFields];


export default class Sbr_3_0_endOfDayTill extends NavigationMixin(LightningElement) {
    @api selectedDate;
    @track dateInfo = false;
    selectedformateddate
    @track TotalCurrency = "0.00"
    @track TotalCreditCards ="0.00";

    @track StartDrawer = "0.00";
    @track LessAutoDeposits = "0.00";
    @track LessROAAutoDeposits = "0.00";
    @track accountedFor = 0

    @track ReceivedOnChargeAccount = "0.00"; 
    @track CashSales ="0.00";
    @track DepositsAppliedRefunded = "0.00";
    @track Uncollected = "0.00";
    @track WireTransfers = "0.00";
    @track NetCashFromInvoice = "0.00";
    @track DepositsTaken = "0.00";
    @track RefundsNotTaken = "0.00";
    @track InterLocationCash = "0.00";
    @track TotalCash = "0.00";
    @track TotalTransactionsystem = "0.00";
    @track finalStartDrawerValue = "0.00"
    tempstartDrawerValue
    @track notInbalancemodel = false
    @track Inbalancemodel = false
    @track todayTillmodel = false
    startDrawerModel = false
    enterCurrencyModel = false
    enterReasonsModel = false
    @api recordId;
    @track tillStatus;
    @track digitalSignature = '';
    tillTodayMessage = todayTillErrorMessage;
    get statusValue() {
        return this.tillStatus == 'Submitted' ?  this.recordStatus : this.status;        
    }
    get submittedRec() {
        return this.tillStatus == 'Submitted';        
    }
    get TotalDepostInBank() {
        const finalTotal = Number(this.TotalDeposits) - Number(this.LessAutoDeposits) - Number(this.LessROAAutoDeposits) + Number(this.totalReasonsAmount || '')
        this.status = this.calculatecurrenttillstatus(finalTotal)
        return finalTotal<=0 ? Number('0.00') : finalTotal;
    }
    get TotalDeposits() {
        const totalDeposit = Number(this.TotalTransactions) + Number(this.finalStartDrawerValue) - Number(this.nextDayDrawer);
        return totalDeposit <=0 ? Number('0.00') : totalDeposit;
    }
    get TotalTransactions() {
        const totalTransaction = Number(this.TotalDrawer) - Number(this.finalStartDrawerValue);
        return totalTransaction <=0 ? Number('0.00') : totalTransaction ;
    }
    get TotalDrawer() {
        const totalDrawer = Number(this.TotalCurrency) + Number(this.totalchecks) + Number(this.totalRoaChecks) + Number(this.TotalCreditCards);
        return totalDrawer <=0 ? Number('0.00') : totalDrawer ; 
    }
    errorlabel;
    errorlabel1;
    @track userpswd = '';
    @track userEmail = '';
    @track tillId;
    @track totalchecks ="0.00";
    @track nextDayDrawer ="0.00";
    @track totalRoaChecks ="0.00";
    PswdErrorMessage = ''
    passworderror = false
    @track CurrencyEntered = false;
    @api subTotalCurrencyMessage = 'Calculated after entering currency';
    reasonsMessage = 'Calculated after entering Reasons'
    @track IsValid = false;
    /********************Refresh Cards *******************/
    @track isRefreshCards = false;
    @track isProcessingRefresh = false;
    @track isRefreshFailed = false;
    @track isEndOfDayTill = true;
    isFromtryAgain = false;
    /*********************Enter Currency ****************/
    @track isenterCurrency = false;

    @track isCashControlTab = true;
    @track isCashROAControlTab = false
    @track isTabsetEnabled = true;
    @track status = this.calculatecurrenttillstatus(this.TotalDepostInBank);
    @api eodTillSaveRecordId;
    @api reasonDetails = [];
    @api savedReasonsList = {};
    //FRONT-32190 START
    tillDetailId;
    amountsByCreditCard={};
    getTillSummaryResponse;
    openEndOfDayTab = false;
    branchLocationNumber;
    branchCompanyId;
    adjustmentsAccountedFor = 0;
    savedReasons = [{
        amount: '',
        comments: '',
        id: 1,
        selectedReason: "Over"
    }];
     //FRONT-32190 END

    calculatecurrenttillstatus(depostivalue) {
        var finalvalue = Number(this.TotalDeposits) - Number(depostivalue)
        console.log('inside calculation' + finalvalue)
        if (finalvalue < 0) {
            return 'Short by ' + formatValueWithCurrencySign(finalvalue)
        }
        else if (finalvalue > 0) {
            return 'Over by ' + formatValueWithCurrencySign(finalvalue)
        }
        else {
            return 'In Balance'
        }
    }

    @track label = {
        refreshCardsSuccess
    };

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        this.recordId = this.currentPageReference.state?.c__eodTillRecordId;
        this.tillDetailId = this.currentPageReference.state?.c__tillDetailId; //FRONT-32190
        this.getEodTillRecord();

        //FRONT-32190 START
        this.branchLocationNumber = this.currentPageReference.state.c__branchLocationNumber;
        this.branchCompanyId = this.currentPageReference.state.c__branchCompanyId;
        this.getTillSummaryResponse = JSON.parse(decodeURIComponent(this.currentPageReference.state.c__getTillSummaryResponse))
       //FRONT-32190 END 
       this.tillId = this.currentPageReference.state.c__eodTillRecordId;
        this.finalStartDrawerValue = this.currentPageReference.state.c__startDrawer != '' ? this.currentPageReference.state.c__startDrawer : 1000
        console.log('finalStartDrawerValue 343',this.finalStartDrawerValue)
        if (this.currentPageReference.state.c__startDrawer != '') {
            this.tempstartDrawerValue = this.currentPageReference.state.c__startDrawer
        }
        if (!this.nextDayDrawer) {
            this.nextDayDrawer = 1200;
        }
        if (this.accountedFor != '') {
            this.totalReasonsAmount = this.accountedFor
        }

        if (this.tillId) {
            fetchCurrencies({ tillId: this.tillId })
                .then(data => {
                    if (data) {
                        console.log('data '+JSON.stringify(data));
                        for (let key in data) {
                            if (this.Currencies.hasOwnProperty(key)) {
                                this.Currencies[key] = data[key];
                            }
                        }
                        this.CurrencyEntered = true
                    }
                })
                .catch(error => {
                    console.log(error)
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error,
                            variant: 'error'
                        })
                    );
                })

        }

        let finalTotal = Number(this.TotalDeposits) - Number(this.LessAutoDeposits) - Number(this.LessROAAutoDeposits) + Number(this.totalReasonsAmount)
        this.status = this.calculatecurrenttillstatus(finalTotal)

    }

    getEodTillRecord() {
        getEodTillRecords({ recordId: this.recordId })
            .then(data => {
                this.totalchecks = data?.Total_Checks__c;
                this.totalRoaChecks = data?.Total_ROA_Checks__c;
                this.tillStatus =data?.Till_Status__c;
                this.TotalCurrency = data?.Total_Currency__c;
                this.TotalCreditCards = data?.Total_Credit_Cards__c;
                this.accountedFor = data?.Accounted_For__c;
                this.CashSales = formatValueWithCurrencySign(data?.Cash_Sales__c); 
                this.DepositsAppliedRefunded = formatValueWithCurrencySign(data?.Deposits_Applied_Refunded__c); 
                this.Uncollected = formatValueWithCurrencySign(data?.Uncollected__c);
                this.WireTransfers = formatValueWithCurrencySign(data?.Wire_Transfer__c); 
                this.NetCashFromInvoice = formatValueWithCurrencySign(data?.Net_Cash_From_Invoice__c); 
                this.DepositsTaken = formatValueWithCurrencySign(data?.Deposits_Taken__c); 
                this.RefundsNotTaken = formatValueWithCurrencySign(data?.Refunds_Not_Given__c); 
                this.InterLocationCash =formatValueWithCurrencySign( data?.Inter_Location_Cash__c); 
                this.TotalCash = formatValueWithCurrencySign(data?.Total_Cash__c); 
                this.TotalTransactionsystem = formatValueWithCurrencySign(data?.Total_Transactions_System__c); 
                this.LessAutoDeposits = data?.Less_Auto_Deposit__c;
                this.LessROAAutoDeposits =  data?.Less_ROA__c;
                this.finalStartDrawerValue = data?.Start_Drawer__c;
                this.ReceivedOnChargeAccount = formatValueWithCurrencySign(data?.Received_on_Charge_Account__c); 
                this.adjustmentsAccountedFor = data?.Accounted_For__c;
                this.recordStatus = data?.Status__c;
                console.log('finalStartDrawerValue 416',this.finalStartDrawerValue)
                this.nextDayDrawer = data?.Next_Day_Drawer__c;
                this.amountsByCreditCard = { 
                    totalCreditCard : data?.Total_Credit_Cards__c,
                    totalROACreditCard : data?.Total_Auto_Deposit_Amount__c,
                    totalAutoDeposit : data?.Total_ROA_Credit_Card_Amount__c,
                    totalROAAutoDeposit: data?.Total_ROA_Auto_Deposit__c
                }

                this.selectedDate = data?.Till_Date__c;
                this.dateInfo = true;
                this.selectedformateddate = formatDate(this.selectedDate);
                
                if (data) {
                    for (let key in data) {
                        if (this.Currencies.hasOwnProperty(key)) {
                            this.Currencies[key] = data[key];
                        }
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching record: ', error);
            }).finally(()=>{ //FRONT-32190
                this.openEndOfDayTab = true; 
            })
    }

    handleTotalChecks(event) {
        this.totalchecks = event.detail.value;
    }
    handleNextDayDrawer(event) {
        this.nextDayDrawer = event.detail.value;
    }
    handleTotalRoaChecks(event) {
        this.totalRoaChecks = event.detail.value;

    }
    handleEnterCurrency() {
        this.enterCurrencyModel = true;
        document.body.style.overflow = 'hidden';
    }

    handleTabChange(event) {
        if (event.detail.value === 'cashControl') {
            this.isCashControlTab = true;
            this.isCashROAControlTab = false;
        } else if (event.detail.value === 'cashROAControl') {
            this.isCashControlTab = false;
            this.isCashROAControlTab = true;
        }
    }

    @track fields = {}

    @wire(getObjectInfo, { objectApiName: END_OF_TILL_OBJECT })
    objInfo({ data, error }) {
        if (data) {
            Object.keys(data.fields).forEach(field => {
                this.fields[field] = data.fields[field].label;
            });
            console.log('this.fields  ',this.fields)
        } else if (error) {
            console.error('Error retrieving object info', error);
        }
    }

   async handleCancel() {
        await getFocusedTabInfo().then(tabInfo => {
            closeTab(tabInfo.tabId);
           // window.history.back();
        });
    }
    renderedCallback() {
        this.dispatchEvent(new RefreshEvent());
        if (this.isEndOfDayTill) {

            Promise.all([
               // loadStyle(this,radioGroupHorizontal)
            ])
            const STYLE = document.createElement("style");
            STYLE.innerText = `.inputnolabel label{
                display : none;
            } .slds-input{
                border: 1px solid lightgray !important;
                
            }.slds-form-element__icon{
                padding-top: 0px !important;
            }.inputnolabel input{
                text-align : right;
            }.validatepassword label{
                display : none;
            }.reasonsRadio .slds-radio{
                padding-top : 12px;
            }.reasonbtn button{
                position : initial;
                margin-top: 16px;
            }.slds-button_text-destructive{
                --slds-c-button-text-color : var(--slds-g-color-error-base-40, var(--lwc-colorTextError,rgb(234, 0, 30)));
            }`;
            if (this.status != 'Submitted') {
                this.template.querySelector('.inputnolabel').appendChild(STYLE);
            }
            const STYLE1 = document.createElement("style");
            STYLE1.innerText = `.slds-form-element__icon{
                padding-top: 0px !important;
            }`;
            if (this.status == 'Submitted') {
                this.template.querySelector('.mainsection').appendChild(STYLE1);
            }

        }

    }
    closeModal() {
        this.notInbalancemodel = false;
        this.Inbalancemodel = false
        this.startDrawerModel = false
        this.enterCurrencyModel = false
        this.enterReasonsModel = false
        this.todayTillmodel = false
        this.reasons = JSON.parse(JSON.stringify(this.savedReasons));
        this.calculateReasonsTotal();
        document.body.style.overflow = 'visible';
    }
    goBack() {
        this.notInbalancemodel = false;
        this.Inbalancemodel = false
        this.todayTillmodel = false
    }
    async handleSave() {
        const requiredFields = this.template.querySelectorAll('.validate');
        const currentstatus = this.status
        let isValid = true;
        if (!this.CurrencyEntered) {
            isValid = false;
            this.currencyvalidation = true
        }
        let tempStatus = this.status
        if (this.totalReasonsAmount == 0 && (tempStatus.includes('Short') || tempStatus.includes('Over'))) {
            isValid = false;
            this.reasonsvalidation = true
        }
        requiredFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });

        if (currentstatus.includes("In Balance") && isValid) {
            if (this.tillId) {
                await this.loadTillRecord('Update');
            }
            else {
                await this.loadTillRecord('New');
            }
            this.callIntegration();
        }

        if (!currentstatus.includes("In Balance") && isValid) {
            this.notInbalancemodel = true
            this.errorlabel = 'Save'
            this.errorlabel1 = 'saving'
        }
    }

    async callIntegration() {
        if (this.eodTillSaveRecordId == null) {
            this.eodTillSaveRecordId = this.tillId;
        }
        if (!this.reasonDetails || this.reasonDetails.length === 0) {
            await this.handleFetchRecord();
        }
        const convertedReasonList = this.reasonDetails.map(item => ({
            amount: item.Amount__c,
            description: item.Comment__c,
            reasonCode: item.Reason__c.substring(0, 2)
        }));
        const convertedReasonListString = JSON.stringify(convertedReasonList);
        console.log('this.eodTillSaveRecordId ' + this.eodTillSaveRecordId);
        console.log('convertedReasonListString ' + convertedReasonListString);
        updateEODTill({
            eodTillRecordId: this.eodTillSaveRecordId,
            userId: USER_ID,
            reasonRecords: convertedReasonListString
        })
            .then(data => {
                if (data && data.data.message && data.data.referenceNo) {
                    this.handleCancel();
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: '',
                            message: this.tillStatus == 'Submitted' ? 'Till for ' + this.selectedformateddate + ' has been submitted' : ' Till for ' + this.selectedformateddate + ' has been saved as a draft.',
                            variant: 'success'
                        })
                    );
                }
            })
            .catch(error => {
                console.error('An error occurred:', error);
                const errorMessage = error.body.message;
                const errorCode = error.body.errorCode;
                const fullErrorMessage = `Error Code: ${errorCode}. ${errorMessage}`;
                this.handleCancel();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving EOD Till records',
                        message: fullErrorMessage,
                        variant: 'error'
                    })
                );
            });
    }

    async handleFetchRecord() {
        await getReasonRecords({ recordId: this.eodTillSaveRecordId })
            .then(data => {
                this.reasonDetails = data;
            })
            .catch(error => {
                console.error('Error fetching record: ', error);
            });
    }


    handleSubmit() {
        const requiredFields = this.template.querySelectorAll('.validate');
        const currentstatus = this.status
        let isValid = true;
        if (!this.CurrencyEntered) {
            isValid = false;
            this.currencyvalidation = true
        }
        let tempStatus = this.status
        if (this.totalReasonsAmount == 0 && (tempStatus.includes('Short') || tempStatus.includes('Over'))) {
            isValid = false;
            this.reasonsvalidation = true
        }
        requiredFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });
        if (currentstatus.includes("In Balance") && isValid) {
            console.log('selected date' + this.selectedDate)
            let yourDate = new Date()
            let formatteddate = yourDate.toISOString().split('T')[0]
            console.log('current date is' + formatteddate)
            if (this.selectedDate == formatteddate) {
                this.todayTillmodel = true
            } else {
                this.Inbalancemodel = true
            }

        }
        if (!currentstatus.includes("In Balance") && isValid) {
            this.notInbalancemodel = true
            this.errorlabel = 'Submit'
            this.errorlabel1 = 'submitting'
        }

    }

    get modalClass() {
        return this.notInbalancemodel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
    get inbalancemodelclass() {
        return this.Inbalancemodel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
    get startdrawerclass() {
        return this.startDrawerModel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
    get entercurrencyclass() {
        return this.enterCurrencyModel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
    get enterReasonsClass() {
        return this.enterReasonsModel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
    get todaytillmodelclass() {
        return this.todayTillmodel ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    // Getter method for backdrop class
    get backdropClass() {
        return this.notInbalancemodel ? 'slds-backdrop slds-backdrop_open' : '';
    }
    get inbalancebackdropClass() {
        return this.Inbalancemodel ? 'slds-backdrop slds-backdrop_open' : '';
    }
    get startdrawerbackdropClass() {
        return this.startDrawerModel ? 'slds-backdrop slds-backdrop_open' : '';
    }
    get entercurrencybackdropClass() {
        return this.enterCurrencyModel ? 'slds-backdrop slds-backdrop_open' : '';
    }
    get enterReasonsbackdropClass() {
        return this.enterReasonsModel ? 'slds-backdrop slds-backdrop_open' : '';
    }
    get todaytillbackdropClass() {
        return this.todayTillmodel ? 'slds-backdrop slds-backdrop_open' : '';
    }

    savePassword(event) {
        this.userpswd = event.detail.value
        this.passworderror = false
        const STYLE = document.createElement("style");
        STYLE.innerText = `.validatepassword .slds-form-element__control{
           border : 1px solid lightgray;
           border-radius: 4px;
        }.validatepassword .slds-input{
            border : none !important;
        }`;
        this.template.querySelector('.validatepassword').appendChild(STYLE);
    }

    finalSubmit(event) {
        let isValid = true
        this.passworderror = false
        if (this.userpswd == '') {
            this.passworderror = true
            this.PswdErrorMessage = 'Please enter password.'
            const STYLE = document.createElement("style");
            STYLE.innerText = `.validatepassword .slds-form-element__control{
               border : 1px solid var(--slds-g-color-error-base-40, var(--lwc-colorTextError,rgb(234, 0, 30)));
               border-radius: 4px;
            }.validatepassword .slds-input{
                border : none !important;
            }`;
            this.template.querySelector('.validatepassword').appendChild(STYLE);
            isValid = false
        }
        if (isValid) {

            const params = new URLSearchParams(apiparams);
            const clientId = params.get('client_id');
            const clientSecret = params.get('client_secret');
            getOAuthToken({ password: this.userpswd, clientId, clientSecret })
                .then(result => {
                    console.log(result)
                    if (result == '200') {
                        this.status = 'Submitted'
                        this.loadTillRecord('final');
                    }
                    if (result == '400') {
                        this.passworderror = true
                        this.PswdErrorMessage = 'Password is invalid. Please check your entry.'
                        const STYLE = document.createElement("style");
                        STYLE.innerText = `.validatepassword .slds-form-element__control{
                    border : 1px solid var(--slds-g-color-error-base-40, var(--lwc-colorTextError,rgb(234, 0, 30)));
                    border-radius: 4px;
                    }.validatepassword .slds-input{
                        border : none !important;
                    }`;
                        this.template.querySelector('.validatepassword').appendChild(STYLE);
                    }

                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'ERROR',
                            message: 'Error while processing the Till record',
                            variant: 'error'
                        })
                    );
                });
        }
    }
    async loadTillRecord(rectype) {
        const fields = {};
        fields[TOTAL_CURRENCY.fieldApiName] = this.TotalCurrency;
        fields[TILL_DATE_FIELD.fieldApiName] = this.selectedDate;
        fields[TOTAL_CHECKS_FIELD.fieldApiName] = this.totalchecks;
        fields[TOTAL_ROA_CHECKS_FIELD.fieldApiName] = this.totalRoaChecks;
        fields[TOTAL_CREDIT_CARDS.fieldApiName] = this.TotalCreditCards;
        fields[TOTAL_DRAWER.fieldApiName] = this.TotalDrawer;
        fields[START_DRAWER.fieldApiName] = this.finalStartDrawerValue;
        fields[TOTAL_TRANSACTIONS.fieldApiName] = this.TotalTransactions;
        fields[NEXT_DAY_DRAWER.fieldApiName] = this.nextDayDrawer;
        fields[TOTAL_DEPOSIT.fieldApiName] = this.TotalDeposits;
        fields[LESS_AUTO_DEPOSIT.fieldApiName] = this.LessAutoDeposits;
        fields[LESS_ROA_AUTO_DEPOSIT.fieldApiName] = this.LessROAAutoDeposits;
        fields[TOTAL_DEPOSIT_IN_BANK.fieldApiName] = this.TotalDepostInBank;
        fields[ACCOUNTED_FOR.fieldApiName] = this.totalReasonsAmount;
        fields[TOTAL_CASH.fieldApiName] = 1000;

        if (rectype == 'final') {
            if (this.tillId) {
                fields[TILL_ID.fieldApiName] = this.tillId
            }
            fields[STATUS.fieldApiName] = this.status
            fields[TILL_STATUS.fieldApiName] = 'Submitted'
            fields[SUBMITTED_USER.fieldApiName] = currentUserId
            fields[SUBMITTED_DATE.fieldApiName] = new Date().toISOString();
            this.tillStatus = 'Submitted';
        }
        else if (rectype == 'New') {
            fields[STATUS.fieldApiName] = 'Draft'
            fields[TILL_STATUS.fieldApiName] = 'Draft'        
        }
        else if (rectype == 'Update') {
            fields[TILL_ID.fieldApiName] = this.tillId
            fields[TILL_STATUS.fieldApiName] = 'Draft' 
        }
        for (let currency in this.Currencies) {
            if (this.Currencies.hasOwnProperty(currency)) {
                fields[currency] = parseFloat(this.Currencies[currency]);
            }
        }
        console.log('fields details '+JSON.stringify(fields));

        upsertTillRecord({ tillrec: fields })
            .then(record => {
                console.log('till rec id  after upsert' + record)
                this.eodTillSaveRecordId = record;
                this.handleCancel();
                this.dispatchEvent(
                    new ShowToastEvent({
                        tittle: '',
                        message: this.tillStatus == 'Submitted' ? 'Till for ' + this.selectedformateddate + ' has been submitted' : ' Till for ' + this.selectedformateddate + ' has been saved as a draft.',
                        variant: 'success'
                    })
                );
                this.createReasons(record)
            })
            .catch(error => {
                console.log(error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });


    }
    createReasons(parentId) {
        let reasonList = []
        console.log('this.reasons[0].amount' + this.reasons[0].amount)
        if (this.reasons[0].amount != '') {
            this.reasons.forEach(currentReason => {
                let reasonrec = {}
                reasonrec[REASON_AMOUNT.fieldApiName] = currentReason.amount
                reasonrec[REASON_COMMENT.fieldApiName] = currentReason.comments
                reasonrec[REASON_REASON.fieldApiName] = currentReason.selectedReason
                reasonrec[REASON_PARENTID.fieldApiName] = parentId
                reasonList.push(reasonrec)

            });
            console.log(reasonList)
            let jsonInput = JSON.stringify(reasonList);
            console.log(jsonInput);
            this.reasonDetails = jsonInput;
            console.log('this.reasonDetails ' + this.reasonDetails);
            insertReasons({ reasonsInput: jsonInput }).catch(error => {
                    console.log(error)
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating reason records',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }
    handleStartDrawer(event) {
        this.startDrawerModel = true
        document.body.style.overflow = 'hidden';
    }
    updateStartDrawer(event) {
        this.tempstartDrawerValue = event.target.value
    }
    submitStartDrawer() {
        const requiredFields = this.template.querySelectorAll('.validatestartdrawer');
        let isValid = true;
        requiredFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
                }
        });
        if (isValid) {
            this.finalStartDrawerValue = this.tempstartDrawerValue
            console.log('finalStartDrawerValue 924',this.finalStartDrawerValue)
            let finalTotal = Number(this.TotalDeposits) - Number(this.LessAutoDeposits) - Number(this.LessROAAutoDeposits) + Number(this.totalReasonsAmount)
            this.status = this.calculatecurrenttillstatus(finalTotal)
            this.startDrawerModel = false
            document.body.style.overflow = 'visible';
        }

    }
    /* Refresh Cards from this below method. */
    async handleRefreshTill() {
        this.isRefreshCards = true;
        this.isProcessingRefresh = true;
        this.isEndOfDayTill = false;
        const compoundKey = [this.branchCompanyId, this.branchLocationNumber, this.selectedDate].join('-');
        try{
            this.getTillSummaryResponse = await getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'Next' })
            const [getTillSummaryNext, eodTillId, tillDetailId] = [this.getTillSummaryResponse, this.tillId, this.tillDetailId]
            await makeEodAPICalls.call(this, getTillSummaryNext, compoundKey);
            const inputValues = await getInputValues.call(this, eodTillId, tillDetailId, getTillSummaryNext);
            await this.handleCancel();
            setTimeout(() => {
                openTabForDraftRecord.call(this, inputValues);
            }, 1000)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    message: 'Till has been updated.',
                    variant: 'success'
                })
            );
        }catch(error){
            console.log('error',error)
            this.callRefreshFailed()
        }    
            // this.dispatchEvent(new RefreshEvent());
    }

    callRefreshFailed() {
        /********* Remove below setTimeout once the integration in place********/
        setTimeout(() => {
            this.isProcessingRefresh = false;
            this.isRefreshFailed = true;
        }, 5000);
    }

    handleRefreshCardsTryAgain() {
        this.isRefreshFailed = false;
        this.isProcessingRefresh = true;
        this.handleRefreshTill();
    }

    handleRefreshCardsBack(){
        this.isProcessingRefresh = false;
        this.isRefreshFailed = false;
        this.isEndOfDayTill = true;
    }


    //currency change code
    @track Currencies = {
        Drawer_Bills_Hundred__c: '',
        Drawer_Bills_Fifty__c: '',
        Drawer_Bills_Twenty__c: '',
        Drawer_Bills_Ten__c: '',
        Drawer_Bills_Five__c: '',
        Drawer_Bills_Two__c: '',
        Drawer_Bills_One__c: '',
        Drawer_Coins_One__c: '',
        Drawer_Coins_Fifty__c: '',
        Drawer_Coins_Quarter__c: '',
        Drawer_Coins_Dime__c: '',
        Drawer_Coins_Nickel__c: '',
        Drawer_Coins_Penny__c: ''
    }

    get subTotalCurrency() {
        let totalCurrencies = 0;
        let tempcurrencies = Object.values(this.Currencies);

        tempcurrencies.forEach((currency) => {
            const numericValue = Number(currency);
            if (numericValue > 0) {
                totalCurrencies += numericValue;
            }
        });
        this.TotalCurrency = totalCurrencies

        totalCurrencies = formatValueWithCurrencySign(totalCurrencies);
        return totalCurrencies
    }

    @track currencyvalidation = false
    get currencyvalidationstyle() {
        return this.currencyvalidation ? 'inputReadonly errorborder' : 'inputReadonly'
    }
    @track reasonsvalidation = false
    get reasonsvalidationstyle() {
        return this.reasonsvalidation ? 'inputReadonly errorborder' : 'inputReadonly'
    }

    currencyChangeHandler(event) {
        const inputField = event.target;
        const inputValue = event.target.value;
        const field = this.findFieldById(inputField.id);

        if (field) {
            const isValid = this.validateField(inputField, inputValue, field);
            this.fieldValidation = isValid;
        }
        this.Currencies[event.target.name] = inputValue;
    }


    validateField(inputField, amount, field) {
        if (isNaN(amount) || amount === "") {
            inputField.setCustomValidity("Please enter amount.");
            inputField.reportValidity();
            if (inputField){
                inputField.classList.add('error');
            }
            return false;
        }

        // Handling precision issues by scaling
        const scaledAmount = Math.round(parseFloat(amount) * 100); // Convert amount to cents
        const scaledMultiple = Math.round(parseFloat(field.multiple) * 100); // Convert multiple to cents

        if (parseFloat(amount) < 0 || scaledAmount % scaledMultiple !== 0) {
            let message;
            if (field.multiple < 1) {
                const centValue = scaledMultiple / 100; // Convert scaled multiple back to dollars
                message = `Amount must be in multiples of ${centValue}¢.`;
            } else {
                message = `Amount must be in multiples of $${field.multiple}.`;
            }
            inputField.setCustomValidity(message);
            inputField.reportValidity();
            if (inputField) {
                inputField.classList.add('error');
            }
            return false;
        } else {
            inputField.setCustomValidity("");
            inputField.reportValidity();
            if (inputField) {
                inputField.classList.remove('error');
            }
            return true;
        }
    }


    findFieldById(inputFieldId) {
        return allFields.find(field => inputFieldId.includes(field.id));
    }

    checkInputValidity() {
        this.IsValid = true;
        [...this.template.querySelectorAll('lightning-input')].forEach(inputField => {
            const field = this.findFieldById(inputField.id);

            if (field) {
                const amount = parseFloat(this.Currencies[field.key]);
                const isValid = this.validateField(inputField, amount, field);
                if (!isValid) {
                    this.IsValid = false;
                }
            }
        });

        return this.IsValid;
    }











    submitCurrencies() {
        this.IsValid = false;
        this.checkInputValidity();
        if (this.IsValid) {
            this.closeModal();
            document.body.style.overflow = 'visible';
            console.log(this.Currencies);
            this.CurrencyEntered = true;
            this.currencyvalidation = false;
        }
    }


    /* Enter Reasons  Start*/

    @track reasons = [{ id: 1, amount: '', comments: '', selectedReason: '' }];
    @track totalReasonsAmount = 0;
    @track totalReasonsAmount1 = 0;
    reasonOptions = [
        { label: 'Short', value: 'Short' },
        { label: 'Over', value: 'Over' }
    ];

    handleEnterReasons(event) {
        this.enterReasonsModel = true
        document.body.style.overflow = 'hidden';
        let tempStatus = this.status
        if (this.reasons[0].amount == '') {
            this.reasons[0].selectedReason = tempStatus.includes('Short') ? 'Short' : tempStatus.includes('Over') ? 'Over' : ''
        }
    }
    handleReasonChange(event) {
        const reasonId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value || event.detail.value;
        let tempStatus = this.status

        if (value == 0 && field == 'amount') {
            event.target.setCustomValidity("Please enter amount greater than 0.");
        } else {
            event.target.setCustomValidity("");
        }

        this.updateReasonField(reasonId, field, value);


    }
    get reasonlimit() {
        return this.reasons.length <= 4 ? true : false
    }
    handleAddReason() {
        const newReasonId = this.reasons.length + 1;
        this.totalReasonsAmount = this.totalReasonsAmount1
        this.status = this.calculatecurrenttillstatus(this.TotalDepostInBank)

        let tempStatus = this.status
        this.reasons.push({ id: newReasonId, amount: '', comments: '', selectedReason: tempStatus.includes('Short') ? 'Short' : tempStatus.includes('Over') ? 'Over' : '' });
    }

    handleRemoveReason(event) {
        const reasonId = event.target.dataset.id;
        const index = this.reasons.findIndex(reason => reason.id === parseInt(reasonId));
        if (index !== -1) {
            this.reasons.splice(index, 1);
            this.calculateReasonsTotal();
        }
        this.totalReasonsAmount = this.totalReasonsAmount1
        this.status = this.calculatecurrenttillstatus(this.TotalDepostInBank)
    }

    updateReasonField(id, field, value) {
        const index = this.reasons.findIndex(reason => reason.id === parseInt(id));
        if (index !== -1) {

            if (field == 'selectedReason' && value == 'Short') {
                this.reasons[index]['amount'] = -Math.abs(parseFloat(this.reasons[index]['amount']));
                this.reasons[index][field] = value
            }
            else if (field == 'selectedReason' && value == 'Over') {
                this.reasons[index]['amount'] = Math.abs(parseFloat(this.reasons[index]['amount']));
                this.reasons[index][field] = value
            }

            if (this.reasons[index]['selectedReason'] == 'Short' && field == 'amount') {
                this.reasons[index][field] = -Math.abs(parseFloat(value));
            } else if (this.reasons[index]['selectedReason'] == 'Over' && field == 'amount') {
                this.reasons[index][field] = Math.abs(parseFloat(value));
            }
            if (field == 'comments') {
                this.reasons[index][field] = value
            }
            this.calculateReasonsTotal();
        }
    }

    calculateReasonsTotal() {
        this.totalReasonsAmount1 = this.reasons.reduce((total, reason) => total + parseFloat(reason.amount || 0), 0);
    }
    get reasonsValue() {
        console.log('this.totalReasonsAmount ',this.totalReasonsAmount, this.status)
        return this.totalReasonsAmount == 0 && this.status != 'In Balance' ? false : this.totalReasonsAmount
    }

    get hideReasonbtn() {
        return this.status == 'Submitted' ? true : false
    }

    submitReasons(event) {
        const requiredFields = this.template.querySelectorAll('.validatereasons');
        let isValid = true;
        requiredFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });

        if (isValid) {
            this.enterReasonsModel = false
            this.totalReasonsAmount = this.totalReasonsAmount1
            this.status = this.calculatecurrenttillstatus(this.TotalDepostInBank)
            document.body.style.overflow = 'visible';
        }

        this.savedReasons = JSON.parse(JSON.stringify(this.reasons))

    }
}