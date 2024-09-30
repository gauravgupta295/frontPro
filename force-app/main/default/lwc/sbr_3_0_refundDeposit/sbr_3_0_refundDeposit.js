/* Importing necessary modules and dependencies */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import fetchTotalDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDeposit";
import fetchTotalRefundDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDepositforRefund";
import fetchPaymentTypewithRefund from "@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentTypeWithDepositAmount";
import fetchLocationInfo from "@salesforce/apex/SBR_3_0_MakeADepositController.getLocationInfo";
import updateLocationInfo from "@salesforce/apex/SBR_3_0_MakeADepositController.updateLocationInfo"; //added by sreekar
import createTransaction from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction";
import makeAPICall from "@salesforce/apex/SBR_3_0_API_CreatePayments.createPayments";
/* Import schema fields */
import TotalAmount from '@salesforce/schema/Order.Total_Rental_Amount__c';
import InvoiceAmount from '@salesforce/schema/Order.Total_Invoiced_Amount__c';
import USER_ID from '@salesforce/user/Id';
import DEPARTMENT from '@salesforce/schema/User.Department';
import COUNTRYCODE from '@salesforce/schema/User.CountryCode';
import WYNNEUSERNAME from '@salesforce/schema/User.Wynne_User_Name__c';
import contractOrderNumber from '@salesforce/schema/Order.Contract_Order_Number__c';
import reservationOrderNumber from '@salesforce/schema/Order.Reservation_Order_Number__c';

/* Importing messaging related modules */
import { publish, MessageContext } from 'lightning/messageService';
import Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';

/* Import other labels as needed */
import ZeroRefund from '@salesforce/label/c.SBR_3_0_ZeroRefund';
import AddFunds from '@salesforce/label/c.SBR_3_0_AddFunds';
import CheckNumber from '@salesforce/label/c.SBR_3_0_Check_Number';
import PaymentMethod from '@salesforce/label/c.SBR_3_0_Payment_Method';
import CashCurrency from '@salesforce/label/c.SBR_3_0_CashCurrency';
import RefundAmount from '@salesforce/label/c.SBR_3_0_RefundAmount';
import RefundChangeDue from '@salesforce/label/c.SBR_3_0_RefundChangeDue';
import CheckLabel from '@salesforce/label/c.SBR_3_0_Check';
import PreviousPaymentMethod from '@salesforce/label/c.SBR_3_0_PreviousPaymentMethod';
import NewPaymentMethod from '@salesforce/label/c.SBR_3_0_NewPaymentMethod';
import RefundDeposit from '@salesforce/label/c.SBR_3_0_Refund_Deposit';
import TotalDeposit from '@salesforce/label/c.SBR_3_0_Total_Deposit';
import AvailableDepositforRefund from '@salesforce/label/c.SBR_3_0_Available_Deposit_for_Refund';
import SelectionMessage from '@salesforce/label/c.SBR_3_0_RefundSelectionMessage';
import RefundDepositWarning from '@salesforce/label/c.SBR_3_0_Refund_Deposit_Warning_Message';
import RefundDepositError from '@salesforce/label/c.SBR_3_0_Refund_Deposit_Error_Message';
import Terminal from '@salesforce/label/c.SBR_3_0_Terminal';
import SelectCardRefund from '@salesforce/label/c.SBR_3_0_Select_card_to_refund';
import CardLabel from '@salesforce/label/c.SBR_3_0_Card';
import NetChargesLabel from '@salesforce/label/c.SBR_3_0_Net_Charges';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
import DefaultTemplate from "./sbr_3_0_refundDeposit.html";
import mobileTemplate from "./sbr_3_0_refundDepositMobileTemplate.html";
import RequestUrl from '@salesforce/label/c.SBR_3_0_RequestURL';
import SubmitRequest from '@salesforce/label/c.SBR_3_0_SubmitMessage';

import DepositOnReservation from '@salesforce/label/c.SBR_3_0_Deposit_On_Reservation';
import RefundCancelReservation from '@salesforce/label/c.SBR_3_0_Refund_To_Cancel_Reservation';
import Reason from '@salesforce/label/c.SBR_3_0_Reason_For_Reservation';
import RefundOnCreateReturn from '@salesforce/label/c.SBR_3_0_RefundOnCreateReturn'; //FRONT-15078
import RefundOnCreateReturnDescription from '@salesforce/label/c.SBR_3_0_RefundOnCreateReturnDescription';//FRONT-15078
import CreateReturnReason from '@salesforce/label/c.SBR_3_0_Reason_For_Reservation'; //FRONT-15078

import { updateRecord } from "lightning/uiRecordApi";
import { checkTerminalInSession, getTerminalDetails } from 'c/sbr_3_0_TerminalSelection';
import { getPaymentMethodDetails } from 'c/sbr_3_0_PaymentMethodSelection';


export default class Sbr_3_0_refundDeposit extends LightningElement {


    /* Defining labels */
    @track label = {
        RefundDeposit,
        RefundChangeDue,
        CheckLabel,
        CheckNumber,
        PaymentMethod,
        RefundAmount,
        PreviousPaymentMethod,
        NewPaymentMethod,
        AvailableDepositforRefund,
        ZeroRefund,
        Terminal,
        AddFunds,
        TotalDeposit,
        CashCurrency,
        SelectionMessage,
        RefundDepositError,
        SelectCardRefund,
        CardLabel,
        NetChargesLabel,
        DepositOnReservation,
        RefundCancelReservation,
        Reason,
        RequestUrl,
        SubmitRequest,
        RefundOnCreateReturn, //FRONT-15078
        RefundOnCreateReturnDescription, //FRONT-15078
        CreateReturnReason //FRONT-15078
    };


    /* Define other tracked properties and APIs */
    @track InvoiceAmount = '0.00';
    @track refundPaymentProcessing = false;
    @api isrefundProcessing = false;
    @api recordId;
    @api message = '';
    @api source = '';
    @track noRefund = false;
    @track paymentMethod;
    @track totalAmount;
    @track rec = {
        paymentMethod: '',
        amountCollected: 0,
        terminal: '',
        tranType: 'Refunded',
        cashReceived: 0,
        checkNumber: 0,
        changeDue: 0,
        reason:''
    }
    @track depositAmount = '0.00';
    @track depositAmountUI = '0.00';
    @track refundAmount = '0.00';
    @track refundAmountUIvalue = '0.00';
    @track sessionId;
    @track CardOrMethodLabel = '';
    @track CardOrMethodLowerCase = '';
    @track error;
    @track department;
    @track wynneUserName;
    @track countrycode;
    @api paymentOptionSelected = '--None--';
    @api depositAmountValue;
    @api terminalValue;
    cashDueValue;
    @api cashDueValueUI;
    @api checkValue = '';
    IsValid = true;
    @track paymentOptions = [];
    terminalOptions = [];
    textValue = 'success'
    @wire(MessageContext)
    messageContext;
    @api value = 'option1';
    @track valueTable;
    @track idTable;
    showRadioGroup = true;
    paymentTypes;
    @track data;

    @api isCardPayment = false;
    @track isCashPayment = false;
    @api isCashOrCheckPayment = false;
    @track isCheckPayment = false;
    @api isRefundChangeDue = false;
    @api isCheckNumber = false;
    @api isRefundChangeDueNew = false;
    @api isCheckNumberNew = false;
    @api isCheckNumberMixed = false;
    @api isRefundChangeDueMixed = false;
    //FRONT-15561 START
    showWarning = false;
    showError = false;
    warningRequest;
    warninginformation;
    netChargesFromTable;
    //FRONT-15561 END
    initialNetCharges;
    @api isNewPaymentMethod = false; //FRONT-15916
    @api isProcessAdditionalDeposit = false;
    @track allowRefundGreaterAmount; //FRONT-15561
    @track allowRefundNewCard; //FRONT-15916
    @track refundAmountUI; //FRONT-15561

    @track locationId;  //added by sreekar
    @track newCard;  //added by sreekar
    @track refundGreater;  //added by sreekar

    paymentMethodRelatedData
    @api isComboboxVisible
    @api isTerminalVisible
    transactionId;

    //FRONT-15561 START
    get refundAmountValue() {
        return this.$refundAmountValue;
    }
    set refundAmountValue(value) {
        this.$refundAmountValue = value;
        this.refundAmountUI = - value;
    }
    @api $refundAmountValue;
    //FRONT-15561 END

    get showSpinner() {
        return !(this.fetchTotalAmountWire && this.fetchuserInfoWire);
    }
    @track $showSpinner = true;
    fetchTotalAmountWire = false;
    fetchuserInfoWire = false;
    @api isFailedScreenBack = false;
    isMobile = false;
    paymentCashOptions = [];
    paymentCheckOptions = [];
    @api isfromcancel = false;
    @track reasonSelected = '';
    @api additionaldeposit = false;
    errorMessage;
    modeOfPaymentMap = {}; //this map is used to store the key value pair of payment method and mode of payment.
    @api isFromCreateReturn = false; //this variable is used for Create Return CTA FRONT-15078 
   //FRONT-16361 START
    @api noRefundGiven = false; 
    @api reasonvalue ;
    contractOrderNumber;
    reservationOrderNumber;
    //FRONT-16361 END
    isApiCallComplete = false;

    renderedCallback() {
        if (!this.isMobile) {
            const STYLE1 = document.createElement("style");
            STYLE1.innerText = `.slds-modal__close{
        content-visibility :visible;
        }`;
            this.template.querySelector('.refund-deposit-container').appendChild(STYLE1);

            const STYLE3 = document.createElement("style");
            STYLE3.innerText = `.slds-button_icon-bare{
            content-visibility :hidden;
            visibility: collapse;
            }`;
            this.template.querySelector('.refund-deposit-container').appendChild(STYLE3);

            const STYLE = document.createElement("style");
            STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
            max-width: 35rem;
            min-width: 35rem;
        }`;
            this.template.querySelector('.refund-deposit-container').appendChild(STYLE);
        }
        if (!this.showSpinner && this.isMobile) {
            const changeInputBoxSize = document.createElement("style");
            changeInputBoxSize.innerText = `.slds-input {
                min-height : 2px;
                line-height : 2.2;
            }`;
            this.template.querySelector('.refundAmountClass')?.appendChild(changeInputBoxSize);
        }
    }

    /* Initialize connectedCallback */
    async connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        this.isrefundProcessing = true;
        [this.warningRequest, this.warninginformation] = (RefundDepositWarning || '').split('\\n');
        [this.sessionId, this.terminalValue] = Object.values(await checkTerminalInSession());
    }

    /* Render respective templates */
    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    /* Handle check change */
    handleCheckChange(event) {
        this.checkValue = event.target.value;
        this.checkNumber = event.target.value;
        this.checkInputValidity();
    }
    /* return selected option value */
    get isOption1Checked() {
        return this.value === 'option1';
    }
    /* return selected option value */
    get isOption2Checked() {
        return this.value === 'option2';
    }

    /* Handle radio button change */
    handleRadioChange(event) {
        this.value = event.target.value;
        if (this.value === 'option2') {
            this.isComboboxVisible = true;
            this.isNewPaymentMethod = true;
            this.terminalValue = localStorage.getItem(this.sessionId) || '--None--';
            this.paymentOptionSelected = '--None--';
            this.refundAmountValue = this.refundAmount;
            this.rec.amountCollected = -this.refundAmountValue
            this.showError = false;
            this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);

        } else if (this.value === 'option1') {
            this.isComboboxVisible = false;
            this.showWarning = false;
            this.showError = false;
            this.isRefundChangeDueNew = false;
            this.isCheckNumberNew = false;
            this.isNewPaymentMethod = false;
            this.isRefundChangeDueMixed = false;
            this.isCheckNumberMixed = false;
            this.isTerminalVisible = false;
            this.refundAmountValue = this.initialNetCharges;
            this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
            const checkedRecord = this.data.filter(e => e.checked == true)?.[0];
            if (!this.isEmpty(checkedRecord)) {
                const paymentmethodName = checkedRecord.Id.substring(0, checkedRecord.Id.length - 9);
                [this.rec.paymentMethod, this.rec.amountCollected] = [paymentmethodName, checkedRecord?.Name];
                this.valueTable = checkedRecord.Id;
            }
        }
    }

    /* generic empty check method */
    isEmpty(obj) {
        return typeof obj === 'object' ? (!obj || !Object.keys(obj).length) : !obj;
    }

    /* Handle radio button change inside table*/
    handleRadioChangeTable(event) {
        this.value = 'option1';
        this.valueTable = event.target.value;
        const valueEvent = event.target.id?.split('-')?.[0]?.replace('$', '')
        this.idTable = this.netChargesFromTable = this.refundAmountValue = valueEvent?.replace(',', '')
        this.rec.amountCollected = - (this.refundAmountValue);
        this.rec.paymentMethod = this.valueTable.substring(0, this.valueTable.length - 9);
        this.isRefundChangeDueMixed = false;
        this.isCheckNumberMixed = false;
        if (this.isCashOrCheckPayment) {
            if (this.modeOfPaymentMap[this.valueTable] === 'Cash') {
                this.isRefundChangeDue = true;
                this.isCheckNumber = false;
                this.rec.paymentMethod = this.valueTable;
                this.cashDueValue = this.refundAmountValue;
                this.cashDueValueUI = this.formatValueWithCurrencySign(this.cashDueValue);
            } else if (this.modeOfPaymentMap[this.valueTable] === 'Check') {
                this.isRefundChangeDue = false;
                this.isCheckNumber = true;
                this.rec.paymentMethod = this.valueTable;
            }
        } else if (!this.isNewPaymentMethod) {
            if (this.modeOfPaymentMap[this.valueTable] === 'Cash') {
                this.isRefundChangeDueMixed = true;
                this.isCheckNumberMixed = false;
                this.rec.paymentMethod = this.valueTable;
                this.cashDueValue = this.refundAmountValue;
                this.cashDueValueUI = this.formatValueWithCurrencySign(this.cashDueValue);
            } else if (this.modeOfPaymentMap[this.valueTable] === 'Check') {
                this.isRefundChangeDueMixed = false;
                this.isCheckNumberMixed = true;
                this.rec.paymentMethod = this.valueTable;
            }
        }
        this.showError = this.showWarning = false;
    }

    /* Wire method to fetch total amount & invoice Amount */
    @wire(getRecord, { recordId: '$recordId', fields: [TotalAmount, InvoiceAmount, contractOrderNumber, reservationOrderNumber] })
    totalAmount({ error, data }) {

        if (data) {
            if (getFieldValue(data, TotalAmount) != null) {
                this.totalAmount = getFieldValue(data, TotalAmount).toFixed(2);
            }
            if (getFieldValue(data, InvoiceAmount) != null) {
                this.InvoiceAmount = getFieldValue(data, InvoiceAmount).toFixed(2);
            }
            this.contractOrderNumber = getFieldValue(data, contractOrderNumber);
            this.reservationOrderNumber = getFieldValue(data, reservationOrderNumber);
            console.log('this.contractOrderNumber',[this.contractOrderNumber,this.reservationOrderNumber]);
            this.setAllData();
        }
        else if (error) {
            console.error(error);
        }
    }

    /* Promise to get all the required data */
    async setAllData() {
        await Promise.all([this.getRefundTypes(), this.getTotalDeposit(), this.getLocationInfo()]).finally(() => {
            this.fetchTotalAmountWire = true;
        })
    }
    /* Fetch total deposit */
    async getTotalDeposit() {
        await Promise.all([this.getFetchTotalRefundDeposit(), this.getFetchTotalDeposit()]) //FRONT-15561 FRONT-15916
    }

    /* Fetch Total Refund Deposit */
    async getFetchTotalRefundDeposit() { //FRONT-15561 FRONT-15916
        await fetchTotalRefundDeposit({ orderId: this.recordId })
            .then(data => {
                if (data != null) {
                    this.depositAmount = data.toFixed(2);
                    this.depositAmountUI = this.formatValueWithCurrencySign(this.depositAmount);
                } else {
                    this.depositAmount = '0.00';
                    this.depositAmountUI = '$0.00';
                }
            }).catch(error => {
                console.error('error', error);
            })
    }

    /* Fetch Total Deposit on Order */
    async getFetchTotalDeposit() { //FRONT-15561 FRONT-15916
        await fetchTotalDeposit({ orderId: this.recordId })
            .then(data => {
                this.refundAmount = ((data.toFixed(2)) - (this.InvoiceAmount)).toFixed(2);
                this.refundAmountUIvalue = this.formatValueWithCurrencySign(this.refundAmount);
                if (this.refundAmount <= 0) {
                    this.noRefund = true;
                    this.refundAmount = '0.00';
                    this.refundAmountUIvalue = '$0.00';
                }
            }).catch(error => {
                console.error('error', error);
            })
    }

    // Format the cashValue with currency sign
    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    /* Fetch Location details associated with Order */
    async getLocationInfo() { //FRONT-15561 FRONT-15916
        await fetchLocationInfo({ orderId: this.recordId }).then(result => {
            if (!this.isEmpty(result)) {
                this.allowRefundGreaterAmount = result?.[0]?.Allow_Refund_Greater_Than_Amount__c;
                this.allowRefundNewCard = result?.[0]?.Allow_Refund_on_New_Card__c;
                this.locationId = result?.[0]?.Id;
            }
        }).catch(error => {
            console.error('getLocationInfo error', error);
        })
    }

    /* Fetch User Details */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [DEPARTMENT, COUNTRYCODE, WYNNEUSERNAME]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.fetchuserInfoWire = true;
            this.error = error;
        } else if (data) {
            this.department = data.fields.Department.value;
            this.countrycode = data.fields.CountryCode.value;
            this.wynneUserName = data.fields.Wynne_User_Name__c.value;
            this.getPaymentAndterminalDetails();
        }
    }

    /* Fetch Payment method and Terminal details */
    async getPaymentAndterminalDetails() {
        const componentName = this.isFromCreateReturn ? 'Create Return' : '';
        const [paymentMethodDetails, terminalOptions] = await Promise.all([getPaymentMethodDetails(componentName), getTerminalDetails(this.department)]).finally(() => {
            this.fetchuserInfoWire = true;
        })
        this.terminalOptions = terminalOptions;
        ({paymentOptions: this.paymentOptions, paymentMethodMap: this.modeOfPaymentMap} = paymentMethodDetails || {});
    }

    /* Handler for payment method change */
    handlePaymentMethod(event) {
        let paymentMethodValue;
        paymentMethodValue = this.valueTable = this.rec.paymentMethod = event.target.value;
        this.paymentOptionSelected = event.target.value;
        this.checkComboboxValidity();

        if (this.modeOfPaymentMap[paymentMethodValue] == 'Cards') {
            this.isTerminalVisible = true;
            this.isCheckNumberNew = false;
            this.isRefundChangeDueNew = false;
            this.noRefundGiven = false;
            this.showWarning = true;
            if (this.depositAmountValue == (this.dueDeposit) || this.depositAmountValue == 0.00) {
                this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                if (this.depositAmountValue < 0) {
                    this.depositAmountValue = '0.00';
                }
                this.rec.amountCollected = parseFloat(this.depositAmountValue);
            }
        } else {
            this.showWarning = false;
            this.isTerminalVisible = false;
            if (this.modeOfPaymentMap[paymentMethodValue] == 'Cash') {
                this.isRefundChangeDueNew = true;
                this.isCheckNumberNew = false;
                this.cashDueValue = this.refundAmountValue;
                this.cashDueValueUI = this.formatValueWithCurrencySign(this.cashDueValue);
                this.noRefundGiven = false;
            } else if (this.modeOfPaymentMap[paymentMethodValue] == 'Check') {
                this.isCheckNumberNew = true;
                this.isRefundChangeDueNew = false;
                this.noRefundGiven = false;
            } else if(this.modeOfPaymentMap[paymentMethodValue] == 'No Refund Given'){ //FRONT-16361
                this.noRefundGiven = true;
                this.isTerminalVisible = false;
                this.isCheckNumberNew = false;
                this.isRefundChangeDueNew = false;
                this.showError= false;
                this.showWarning=false;
                this.rec.cashReceived = parseFloat('0.00');
                this.rec.checkNumber = parseFloat('0.00');
                this.rec.paymentMethod = this.modeOfPaymentMap[paymentMethodValue];
                this.rec.amountCollected = parseFloat('0.00');
            }
        }
    }

    /* FRONT-15079 */ 
    //FRONT-15078 START 
    handlereason(event) {
        this.reasonSelected = this.reasonvalue = event.target.value;
        this.rec.reason = this.reasonSelected;
        this.checkInputValidity();
    }
    //FRONT-15078 END

    /* Check combobox validity */
    checkComboboxValidity() {
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                if ((input_Field_Reference.id).includes("paymentId") || (input_Field_Reference.id).includes("paymentIdNoRefund") || (input_Field_Reference.id).includes("paymentIdcheck") || (input_Field_Reference.id).includes("paymentIdCash")) {
                    let paymentCmp = this.template.querySelector(".paymentClass");
                    if (!this.paymentOptionSelected || this.paymentOptionSelected === '--None--') {
                        this.IsValid = false;
                        paymentCmp.setCustomValidity("Select Payment Method");
                    } else {
                        paymentCmp.setCustomValidity("");
                        this.rec.paymentMethod = this.paymentOptionSelected;
                    }
                    paymentCmp.reportValidity();
                } else if ((input_Field_Reference.id).includes("terminalId") && this.isTerminalVisible == true) {
                    let terminalCmp = this.template.querySelector(".terminalClass");
                    if (!(this.terminalValue) || (this.terminalValue == "") || this.terminalValue === '--None--') {
                        this.IsValid = false;
                        terminalCmp.setCustomValidity("Terminal Is Mandatory For Card Payments.");
                        this.terminalValue = "";
                    } else {
                        this.rec.terminal = this.terminalValue;
                        terminalCmp.setCustomValidity("");
                    }
                    terminalCmp.reportValidity();
                }
            }, true);
    }

    /* Retrieve refund types */
    async getRefundTypes() {
        await fetchPaymentTypewithRefund({ orderId: this.recordId })
            .then(async (paymentTypesWithDeposit) => {
                let count = 0;
                let flag = false;
                console.log('paymentTypesWithDeposit',paymentTypesWithDeposit)
                if (Object.keys(paymentTypesWithDeposit)) {
                    const componentName = this.isFromCreateReturn ? 'Create Return' : '';
                    ({ paymentMethodMap: this.paymentMethodMap } = await getPaymentMethodDetails(componentName) || {});
                    const isSomeCash = Object.keys(paymentTypesWithDeposit).some(((val, i, arr) => this.paymentMethodMap[val] === 'Cash'))
                    const isSomeCheck = Object.keys(paymentTypesWithDeposit).some(((val, i, arr) => this.paymentMethodMap[val] === 'Check'))
                    const isEveryCash = Object.keys(paymentTypesWithDeposit).every(((val, i, arr) => this.paymentMethodMap[val] === 'Cash'))
                    const isEveryCheck = Object.keys(paymentTypesWithDeposit).every(((val, i, arr) => this.paymentMethodMap[val] === 'Check'))

                    // Assuming paymentTypesWithDeposit is an array of objects
                    let data = Object.keys(paymentTypesWithDeposit).map(paymentType => {
                        return {
                            Id: paymentType, // Using currentType as Id
                            Name: (paymentTypesWithDeposit[paymentType]).toFixed(2) // Using paymentAmount as Name
                        };
                    });

                    if (isEveryCash) {
                        data = [...data, { Id: 'Check', Name: '0' }]
                    } else if (isEveryCheck) {
                        data = [...data, { Id: 'Cash Currency', Name: '0' }]
                    }
                    const cardPresent = Object.keys(paymentTypesWithDeposit).some(((val, i, arr) => this.paymentMethodMap[val?.split(' ')?.[0]] == 'Cards'))
                    if (((isSomeCash || isSomeCheck) && cardPresent)) {
                        this.CardOrMethodLabel = 'Method';
                        this.CardOrMethodLowerCase = 'method';
                    } else {
                        this.CardOrMethodLabel = 'Card';
                        this.CardOrMethodLowerCase = 'card';
                    }
                    let currentData = []
                    let finalData;
                    data.forEach(row => {
                        if (((isSomeCash || isSomeCheck) && cardPresent) || cardPresent) {
                            let rowData = {}
                            this.isCardPayment = true;
                            if (count === 0 && row.Name > 0) {
                                rowData.checked = true;
                                rowData.Id = row.Id;
                                rowData.Name = this.formatValueWithCurrencySign(row.Name);
                                if (this.paymentMethodMap[row.Id] === 'Cash') {
                                    this.isRefundChangeDueMixed = true;
                                    this.isCheckNumberMixed = false;
                                }else if(this.paymentMethodMap[row.Id] === 'Check'){
                                    this.isRefundChangeDueMixed = false;
                                    this.isCheckNumberMixed = true; 
                                }
                                if (parseFloat(row.Name) === 0 || parseFloat(row.Name) < 0) {
                                    flag = true;
                                    rowData.disabled = true;
                                    rowData.checked = false;
                                }
                                count++;
                            }
                            else {
                                rowData.checked = false;
                                rowData.Id = row.Id;
                                rowData.Name = this.formatValueWithCurrencySign(row.Name);
                                if (parseFloat(row.Name) === 0 || parseFloat(row.Name) < 0) {
                                    rowData.disabled = true;
                                } else if (flag) {
                                    rowData.checked = true;
                                }
                            }
                            if (rowData.checked === true) {
                                const isFailedBackNewPayment = this.isFailedScreenBack;
                                this.refundAmountValue = isFailedBackNewPayment ? this.depositAmountValue : row.Name;
                                this.rec.amountCollected = - (this.refundAmountValue);
                                this.valueTable = isFailedBackNewPayment ? this.paymentOptionSelected : row.Id;
                                const paymentOptionFromFailedBack = this.paymentOptionSelected.substring(0, this.paymentOptionSelected.length - 9) || this.paymentOptionSelected
                                this.rec.paymentMethod = isFailedBackNewPayment ? paymentOptionFromFailedBack : row.Id.substring(0, row.Id.length - 9);
                                if ((this.paymentMethodMap[row.Id] == 'Check' || this.paymentMethodMap[row.Id] == 'Cash')) {
                                    this.rec.paymentMethod = isFailedBackNewPayment ? paymentOptionFromFailedBack : row.Id;
                                }else{
                                    if(this.isFailedScreenBack && this.value == 'option1'){
                                        this.isRefundChangeDue = this.isRefundChangeDueNew = this.isRefundChangeDueMixed = false;
                                        this.isCheckNumberMixed = this.isCheckNumber = this.isCheckNumberNew = false;
                                    }
                                }
                                this.netChargesFromTable = parseFloat(row.Name);
                                this.initialNetCharges = parseFloat(row.Name);
                            }
                            currentData.push(rowData);
                        }
                        else if ((isSomeCash || isSomeCheck)) {
                            this.showError = false;
                            this.showWarning = false;
                            this.isCashOrCheckPayment = true;

                            let rowData = {}
                            if ((isEveryCash || isEveryCheck) && row.Name > 0) {
                                rowData.checked = true;
                                rowData.Id = row.Id;
                                rowData.Name = this.formatValueWithCurrencySign(row.Name);
                                if (this.paymentMethodMap[row.Id] === 'Cash') {
                                    this.isRefundChangeDue = true;
                                    this.isCheckNumber = false;
                                }else{
                                    this.isRefundChangeDue = false;
                                    this.isCheckNumber = true; 
                                }
                            } else if (this.paymentMethodMap[row.Id] === 'Check' && isSomeCheck) {
                                rowData.checked = true;
                                rowData.Id = row.Id;
                                rowData.Name = this.formatValueWithCurrencySign(row.Name);
                                this.isRefundChangeDue = false;
                                this.isCheckNumber = true; 
                            } else {
                                rowData.checked = false;
                                rowData.Id = row.Id;
                                rowData.Name = this.formatValueWithCurrencySign(row.Name);
                            }
                            if (rowData.checked === true) {
                                const isFailedBackNewPayment = this.isFailedScreenBack;
                                this.refundAmountValue = isFailedBackNewPayment ? this.depositAmountValue : row.Name;
                                this.rec.amountCollected = - (this.refundAmountValue);
                                this.valueTable = isFailedBackNewPayment ? this.paymentOptionSelected : row.Id;
                                const paymentOptionFromFailedBack = this.paymentOptionSelected.substring(0, this.paymentOptionSelected.length - 9) || this.paymentOptionSelected
                                this.rec.paymentMethod = isFailedBackNewPayment ? paymentOptionFromFailedBack : row.Id;
                                this.netChargesFromTable = parseFloat(row.Name);
                                this.initialNetCharges = parseFloat(row.Name);
                                this.cashDueValue = this.refundAmountValue;
                                this.cashDueValueUI = this.formatValueWithCurrencySign(this.cashDueValue);
                            }
                            currentData.push(rowData);
                        }                        
                    })
                    finalData = currentData.filter(e =>  this.paymentMethodMap[e.Id.split('****')?.[0]?.trim()] == 'Cards').concat(currentData.filter(e => this.paymentMethodMap[e.Id] == 'Cash')).concat(currentData.filter(e => this.paymentMethodMap[e.Id] == 'Check'))
                    this.data = finalData;
                }
            })
            .catch(error => {
                console.error('Error fetching refund types: ', error);
            });
    }

    /* Handle change in refund amount value */
    handleAmountChange(event) {
        this.refundAmountValue = Math.abs(parseFloat(event.target.value)); //FRONT-15561 START
        this.rec.amountCollected = - (this.refundAmountValue);
        if (this.refundAmountValue <= this.refundAmount) {
            this.cashDueValue = this.refundAmountValue;
            this.cashDueValueUI = this.formatValueWithCurrencySign(this.cashDueValue);
        }
        else {
            this.cashDueValueUI = '';
        }
        if ((!this.isCashOrCheckPayment) && (this.modeOfPaymentMap[this.rec.paymentMethod] == 'Cards')) {
            this.showWarning = ((this.refundAmount >= this.refundAmountValue) && (this.refundAmountValue > this.netChargesFromTable)) || this.isNewPaymentMethod;
        }
        if ((this.modeOfPaymentMap[this.rec.paymentMethod] == 'Cash' || this.modeOfPaymentMap[this.rec.paymentMethod] == 'Check')) {
            this.showWarning = (this.refundAmountValue > this.refundAmount);
        }
        this.showError = false;
        this.checkInputValidity();
    }

    /* Close modal */
    closeModal() {
            const message = {
                closeModal: true
            };
            publish(this.messageContext, CLOSE_MODAL, { payload: message });
    }

    /* Handle terminal selection */
    handleTerminal(event) {
        this.terminalValue = event.target.value;
        localStorage.setItem(this.sessionId, this.terminalValue)
        this.checkComboboxValidity();
    }

    /* Check input validity */
    checkInputValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("refundid") || (inputField.id).includes("refundidcash") || (inputField.id).includes("refundidcheck")) {
                    let refundAmountCmp = this.template.querySelector(".refundAmountClass");
                    if (this.refundAmountValue === "" || isNaN(this.refundAmountValue)) {
                        this.IsValid = false;
                        refundAmountCmp.setCustomValidity("Enter Refund Amount");
                    } else if (this.refundAmountValue > this.refundAmount) {
                        this.IsValid = false;
                        refundAmountCmp.setCustomValidity("Refund amount cannot exceed available deposit for refund amount.");
                    } else if (this.refundAmountValue <= 0) {
                        this.IsValid = false;
                        refundAmountCmp.setCustomValidity("Enter Valid Refund Amount");
                    } else {
                        refundAmountCmp.setCustomValidity("");
                    }
                    refundAmountCmp.reportValidity();
                } else if ((inputField.id).includes("CheckId")) {
                    let checkCmp = this.template.querySelector(".checkClass");
                    let regExp = /^0*$/g;
                    let regExpSpecial = /[`~!@#$%^&*()\-+={}[\]:;"'<>,.?\/|\\]/;

                    if (this.checkValue === "" || this.checkValue === undefined) {
                        this.IsValid = false;
                        checkCmp.setCustomValidity("Enter Check Number");
                    } else if (regExp.test(this.checkValue) || regExpSpecial.test(this.checkValue) || Math.sign(this.checkValue) === -1 || this.checkValue.trim() === "") {
                        this.IsValid = false;
                        checkCmp.setCustomValidity("Please specify valid check number");
                    } else {
                        checkCmp.setCustomValidity("");
                        this.rec.checkNumber = this.checkValue;
                    }
                    checkCmp.reportValidity();
                } else if ((inputField.id).includes("reasonidcash") || (inputField.id).includes("reasonidcheck") || (inputField.id).includes("reasonidcard")) {
                    let reasonClassCmp = this.template.querySelector(".reasonClass");
                    if (this.reasonSelected === "") {
                        this.IsValid = false;
                        reasonClassCmp.setCustomValidity("Enter Valid Reason.");
                        reasonClassCmp.reportValidity();
                    } else {
                        reasonClassCmp.setCustomValidity("");
                    }
                }
            }, true);
    }

    /* Handle form submission */
    async handleSubmit() {
        this.paymentMethodRelatedData = {
            value: this.value, isComboboxVisible: this.isComboboxVisible,
            isTerminalVisible: this.isTerminalVisible, isNewPaymentMethod: this.isNewPaymentMethod, locationId: this.locationId,
            modeOfPaymentMap: this.modeOfPaymentMap,noRefundGiven: this.noRefundGiven , reasonvalue: this.reasonvalue, isCardPayment: this.isCardPayment, isCashOrCheckPayment: this.isCashOrCheckPayment,
            isRefundChangeDue: this.isRefundChangeDue, isCheckNumber: this.isCheckNumber, isCheckNumberNew: this.isCheckNumberNew, 
            isCheckNumberMixed: this.isCheckNumberMixed, isCheckNumberMixed: this.isCheckNumberMixed, 
            contractOrderNumber : this.contractOrderNumber, reservationOrderNumber: this.reservationOrderNumber, 
            isRefundChangeDueNew: this.isRefundChangeDueNew, isRefundChangeDueMixed : this.isRefundChangeDueMixed,
            cashDueValueUI : this.cashDueValueUI
        };
        this.IsValid = true;
        this.checkInputValidity();
        this.checkComboboxValidity();

        if (this.value === 'option1') {
            this.rec.usePreviousCard = true;
        }
        if (!this.IsValid) {
            this.showError = false;
            return;
        }

        if ((this.isNewPaymentMethod) && (this.modeOfPaymentMap[this.rec.paymentMethod] == 'Cards')) { //FRONT-15916
            this.rec.amountCollected = -(this.refundAmountValue);
            await this.getLocationInfo();
            this.showError = !this.allowRefundNewCard;
            if (!this.allowRefundNewCard) return;

        }
        else if ((this.refundAmountValue > this.netChargesFromTable) && (!this.isCashOrCheckPayment)
            && (this.modeOfPaymentMap[this.rec.paymentMethod] == 'Cards')) { //FRONT-15561
            await this.getLocationInfo();
            this.showError = !this.allowRefundGreaterAmount;

            if (!this.allowRefundGreaterAmount) return;
        }
        this.isProcessAdditionalDeposit = !(this.refundAmount == parseFloat(this.refundAmountValue)?.toFixed(2)?.toString()); //FRONT-15914
        if (this.IsValid) {
            try{
            this.refundPaymentProcessing = true;
            await this.createTransactionRecord();
            await this.callPaymentsAPI();
            }catch(error){
                console.error('error in catch api',error);
                this.errorMessage = error?.body?.message || error?.body || error
            }finally{
                this.isApiCallComplete = true;
            }
        }
    }

    async createTransactionRecord() {
        try {
            const transactionId = await createTransaction({ orderRecordId: this.recordId, paymentDepositData: JSON.stringify(this.rec) })
            console.log('Data Transaction', transactionId);
            if (transactionId != null) {
                this.transactionId = transactionId;
            }
            const message = {
                messageToSend: this.textValue,
                sourceSystem: "From Comp : RefundDeposit"
            };
            publish(this.messageContext, Table_Refresh, message);
        } catch (error) {
            console.error('Error in create transaction record', error)
            let message = this.errorMessage = error?.body?.message || error?.body || error;
            const evt = new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error',
            });
            this.closeModal();
            this.dispatchEvent(evt);
        }
    }

    async callPaymentsAPI() {
        try {
            const result = await makeAPICall({
                orderRecordId: this.recordId,
                paymentDepositData: JSON.stringify(this.rec),
                transactionId: this.transactionId,
                wynneUserName: this.wynneUserName
            })
            console.log('makeAPICall response', result);
            const data = result?.data;
            const { contractId, detailSeqNumber, sourceTransactionId, message } = data || {};
            const isCashOrCheck = ['Cash', 'Check'].includes(this.modeOfPaymentMap[this.paymentOptionSelected]);
            const isTransactionValid = isCashOrCheck ? contractId && detailSeqNumber : contractId && detailSeqNumber && sourceTransactionId;
            const asyncSuccessMessage = 'Deposit Maintenance request is accepted for further processing';

            if (isTransactionValid || message == asyncSuccessMessage) {
                if (isTransactionValid) {
                    await this.updateTransactionRecord(detailSeqNumber);
                }
            } else {
                this.closeModal();
            }

            this.newCard = false;
            this.refundGreater = false;
            updateLocationInfo({ locationId: this.locationId, newCard: this.newCard, refundGreater: this.refundGreater })
                .then(() => {
                    console.log('payement updated')
                })
                .catch(error => {
                    console.error('Error in updating location', error)
                });

            const message2 = {
                messageToSend: this.textValue,
                sourceSystem: "From Comp : RefundDeposit"
            };
            publish(this.messageContext, Table_Refresh, message2);
        } catch (error) {
            console.error('Error in apicall', error);
            this.errorMessage = error?.body?.message || error?.body || error;
        }
    }

    /* update Transaction record fields */
    async updateTransactionRecord(detailSeqNumber) {
        const fields = {
            Id: this.transactionId,
            RM_Detail_Sequence_Number__c: detailSeqNumber
        };
        const recordInput = { fields };
        updateRecord(recordInput).then(result => {
            const message = {
                messageToSend: 'success',
                sourceSystem: "From Comp : MakeADeposit"
            };
            publish(this.messageContext, Table_Refresh, message);
        }).catch(error => {
            console.error('Error updating transaction record:', error);
            this.errorMessage = error?.body?.message || error;
        });
    }
}