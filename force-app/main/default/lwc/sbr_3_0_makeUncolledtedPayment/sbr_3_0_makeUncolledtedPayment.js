/*  Importing necessary modules and dependencies */    
import getInvoiceDetail from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.getInvoiceDetails";
import DefaultTemplate from "./sbr_3_0_makeUncolledtedPayment.html";
import mobileTemplate from "./sbr_3_0_makeUncolledtedPaymentMobileTemplate.html";
import mobileTemplatePaymentMethodTemplate from "./sbr_3_0_makeUncolledtedPaymentMethodMobileTemplate.html";
import { LightningElement, api, track, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
import { checkTerminalInSession, getTerminalDetails } from 'c/sbr_3_0_TerminalSelection';
import { getPaymentMethodDetails } from 'c/sbr_3_0_PaymentMethodSelection';

/* Importing Apex methods */
import PaymentMethodDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentMethod";
import TerminalDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getTerminal";
import updateInvoice from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.updateInvoiceDetails";	
import createTransaction from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction";
import makeAPICall from "@salesforce/apex/SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment";


/* Import other labels as needed */
import ChangeDue from '@salesforce/label/c.SBR_3_0_ChangeDue';
import CheckNumber from '@salesforce/label/c.SBR_3_0_Check_Number';
import Terminal from '@salesforce/label/c.SBR_3_0_Terminal';
import CashReceived from '@salesforce/label/c.SBR_3_0_Cash_Received';
import PaymentMethod from '@salesforce/label/c.SBR_3_0_Payment_Method';
import invoiceLabel from '@salesforce/label/c.SBR_3_0_InvoiceInputField';
import header from '@salesforce/label/c.SBR_3_0_UncollectedPaymentHeader';
import contractLabel from '@salesforce/label/c.SBR_3_0_ContractInputField';
import sequenceLabel from '@salesforce/label/c.SBR_3_0_SequenceInputField';

/* Import schema fields */
import USER_ID from '@salesforce/user/Id';
import DEPARTMENT from '@salesforce/schema/User.Department';
import COUNTRYCODE from '@salesforce/schema/User.CountryCode';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
import WYNNEUSERNAME from '@salesforce/schema/User.Wynne_User_Name__c';


export default class Sbr_3_0_makeUncolledtedPayment extends LightningElement {

    /* Defining labels */
    label = {
        PaymentMethod,
        CheckNumber,
        Terminal,
        CashReceived,
        ChangeDue,
        invoiceLabel,
        contractLabel,
        sequenceLabel,
        header
    };

    /* Define other tracked properties and APIs */
    @wire(MessageContext)
    messageContext;
    @wire(CurrentPageReference)
    pagereference;

    @api recordId;
    @api isuncollectedProcessing = false;
    @api isPaymentCash = false;
    @api isTerminalVisible = false;
    @api invoiceAmount = '0.00';
    @api invoiceAmountValue = '0.00';
    @api cashDueValue;
    @api checkValue = '';
    @api paymentOptionSelected = '--None--';
    @api terminalValue = '--None--';
    @api isPaymentCheck = false;
    @api cashReceivedValue;
    @api isFailedScreenBack = false;
    @api matchedInvoiceDetails;

    @track invoiceId;
    @track error;
    @track department;
    @track wynneUserName ;
    @track countrycode;
    @track invoiceNumberEntered;
    @track sequenceNumberEntered; 
    @track initialModal;
    @track paymentProcessing = false;
    @track amountCollected;
    @track moneyAppliedToInvoice = 0.00;
    @track paymentOptions = [];
    @track showPaymentModal; 
    @track $showSpinner = true;
   
   
    @track rec = {
        paymentMethod: '',
        terminal: '',
        cashReceived: 0,
        checkNumber: 0,
        changeDue: 0,
        amountCollected: 0
    }
   
    IsValid = true;
    terminalOptions = [];
    isLoaded = false;
    modeOfPaymentMap = {};
    transactionId;
    orderId;
    errorMessage;
    sessionId;
    sObjectName;
    invoicePaidInFull;
    invoiceWrittenOff;
    invoiceNumber;
    sequenceNumber;
    invoiceData;
    isValid = true;
    onNextSuccess = false;
    isMobile = false;
    invoiceRelatedData;
    isApiCallComplete = false

    /* Returns a concatenated string of invoice and sequence numbers */
    get fullInvoice() {
        const invoiceSequence = [this.invoiceNumberEntered || '', this.sequenceNumberEntered || ''].join('-');
        return invoiceSequence;
    }
   
    /* Formats the invoice amount with a currency sign */
    get invoiceAmountUI(){
        return this.formatValueWithCurrencySign(this.invoiceAmount);
    }
   
    /* Lifecycle method called when the component is inserted into the DOM */
    connectedCallback() {
        if(this.isFailedScreenBack){
            this.initialModal = false; 
            this.onNextSuccess = true;
            this.showPaymentModal = true;
        }else{
        this.initialModal = true;
        }
        this.$showSpinner = false;
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        this.sObjectName = this.pagereference.attributes.objectApiName;
        this.fetchInvoiceDetails();
        this.isuncollectedProcessing = true;
    }

    /* Determines the template to render based on mobile or desktop view */
    render() {
        if (this.isMobile) {
            if(this.initialModal){
                return mobileTemplate;
            }else if(this.onNextSuccess){
                return mobileTemplatePaymentMethodTemplate;
            }
        }else {
            return DefaultTemplate;
        }
    }

    /* Fetches invoice details based on record ID and object name */
    fetchInvoiceDetails() {
        getInvoiceDetail({ recordId: this.recordId, sObjectName: this.sObjectName })
            .then(result => {
                this.invoiceData = result;
                if(this.sObjectName == 'Invoice__c'){
                    this.invoiceNumberEntered = result?.[0]?.Invoice_number__c;
                    this.sequenceNumberEntered = result?.[0]?.Invoice_Sequence_Number__c;
                    this.checkInvoiceValidity();
                }
            })
            .catch(error => {
                console.error('Error fetching invoice details:', error);
            });
    }

    /* Validates invoice input fields and checks for various conditions */
    checkInvoiceValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("invoiceid") || (inputField.id).includes("sequenceid")) {
                    let invoiceCmp = this.template.querySelector(".invoiceClass");
                    let sequenceCmp = this.template.querySelector(".sequenceClass");
                    if (!this.invoiceNumberEntered || !this.sequenceNumberEntered) {
                        this.isValid = false;
                        invoiceCmp.setCustomValidity("Please enter Invoice#.");
                        sequenceCmp.setCustomValidity(' ');
                        invoiceCmp.reportValidity();
                        sequenceCmp.reportValidity();
                    } else {
                        this.isValid = false;
                        const matchedInvoice = this.invoiceData.find(e => {
                            const invoice = [e.Invoice_number__c || '', e.Invoice_Sequence_Number__c || ''].join('-');
                            return invoice === this.fullInvoice;
                        });
                        this.matchedInvoiceDetails = matchedInvoice;

                        if (!this.validateInvalidInvoice(matchedInvoice)) {
                            invoiceCmp.setCustomValidity("Invalid Invoice Number.");
                            sequenceCmp.setCustomValidity(' ');
                        } else if (this.validatePaidInFullInvoice(matchedInvoice)) {
                            invoiceCmp.setCustomValidity("Invoice is paid off and not accepting payment.");
                            sequenceCmp.setCustomValidity(' ');
                        } else if (this.validateWrittenOffInvoice(matchedInvoice)) {
                            invoiceCmp.setCustomValidity("Invoice is written off and not accepting payment.");
                            sequenceCmp.setCustomValidity(' ');
                        } else {
                            this.isValid = true;
                            invoiceCmp.setCustomValidity("");
                            sequenceCmp.setCustomValidity("");
                        }
                        invoiceCmp.reportValidity();
                        sequenceCmp.reportValidity();
                    }
                }
            }, true);
    }

    /* Validates if the matched invoice is in a valid format */
    validateInvalidInvoice(matchedInvoice) {
        const invoice = [matchedInvoice?.Invoice_number__c, matchedInvoice?.Invoice_Sequence_Number__c].join('-');
        const regex = /^\d{9}-\d{4}$/
        return regex.test(invoice);
    }

    /* Validates if the matched invoice is paid in full */
    validatePaidInFullInvoice(matchedInvoice) {
        return matchedInvoice.Total_invoice_Amount__c === matchedInvoice.Money_Applied_to_Invoice__c;
    }

    /* Validates if the matched invoice is written off */
    validateWrittenOffInvoice(matchedInvoice) {
        return matchedInvoice.Written_Off_Invoice__c
    }

    /* Handles changes in the invoice number input field */
    handleInvoiceChange(event) {
        this.invoiceNumberEntered = event.target.value;
        this.checkInvoiceValidity();
    }

    /* Handles changes in the sequence number input field */
    handleSequenceChange(event) {
        this.sequenceNumberEntered = event.target.value;
        this.checkInvoiceValidity();
    }

    /* Handles the logic when the "Next" button is clicked */
    async handleNext() {
        this.checkInvoiceValidity();
        if (this.isValid) {
            this.initialModal = false;
            this.onNextSuccess = true;
            this.showPaymentModal = true;
            this.$showSpinner = true;
            setTimeout(() => {
                this.$showSpinner = false;
            }, 2000);
            this.rec.amountCollected = this.invoiceAmount = this.amountCollected = this.invoiceAmountValue = this.matchedInvoiceDetails?.Total_invoice_Amount__c - this.matchedInvoiceDetails?.Money_Applied_to_Invoice__c;
            this.invoiceId = this.matchedInvoiceDetails?.Id;
            this.moneyAppliedToInvoice = this.matchedInvoiceDetails?.Money_Applied_to_Invoice__c || this.moneyAppliedToInvoice;
            [this.sessionId, this.terminalValue] = Object.values(await checkTerminalInSession());
        }
    }

    /* Handler for payment failure */
    handlePaymentFailed(event) {
        this.paymentOptionSelected = event.detail.paymentmethod;
        this.handlePaymentMethod(event);
    }

    /* Handler for payment method change */
    handlePaymentMethod(event) {
        let paymentMethodValue;
        paymentMethodValue = event.target.value;
        this.paymentOptionSelected = event.target.value;
        this.checkComboboxValidity();
        if (this.modeOfPaymentMap[paymentMethodValue] === 'Cash') {
            this.isPaymentCash = true;
            this.isTerminalVisible = false;
            this.isPaymentCheck = false;
            this.amountCollected = parseFloat(this.invoiceAmountValue);
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] === 'Check') {
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = true;
            this.amountCollected = parseFloat(this.invoiceAmountValue);
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] == 'Cards') {
            this.isPaymentCash = false;
            this.isTerminalVisible = true;
            this.isPaymentCheck = false;
            this.amountCollected = parseFloat(this.invoiceAmountValue);
        }
    }

    // Format the cashValue with currency sign
    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    /* Wire method to fetch user details */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [DEPARTMENT,COUNTRYCODE,WYNNEUSERNAME]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.department = data.fields.Department.value;
            this.countrycode = data.fields.CountryCode.value;
            this.wynneUserName = data.fields.Wynne_User_Name__c.value;
            this.getPaymentAndterminalDetails();
        }
    }


    /* Retrieve payment and terminal details */
    async getPaymentAndterminalDetails() {
        const [paymentMethodDetails, terminalOptions] = await Promise.all([getPaymentMethodDetails(), getTerminalDetails(this.department)]).finally(()=>{
        }) //FRONT-17121
        this.terminalOptions = terminalOptions;
        ({paymentOptions: this.paymentOptions, paymentMethodMap: this.modeOfPaymentMap} = paymentMethodDetails || {});
    }


    /* Handle amount change */
    handleAmountChange(event) {
        this.invoiceAmountValue = parseFloat(event.target.value);
        this.rec.amountCollected = this.invoiceAmountValue;
        this.amountCollected = parseFloat(this.invoiceAmountValue);
        this.checkInputValidity();
    }

    /* Handle cash change */
    handleCashChange(event) {
        this.cashReceivedValue = parseFloat(event.target.value).toFixed(2);
        this.cashDueValue = undefined;
        this.checkInputValidity();
    }

    /* Handle check change */
    handleCheckChange(event) {
        this.checkValue = event.target.value;
        this.checkInputValidity();
    }

    /* Resets flags to display the previous modal */
    previousModal(){
        this.onNextSuccess= false;
        this.initialModal = true;
    }

    /* Handle terminal selection */
    handleTerminal(event) {
        this.terminalValue = event.target.value;
        localStorage.setItem(this.sessionId,  this.terminalValue);
        this.checkComboboxValidity();
    }

    /* Check input validity */
    checkInputValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("depid")) {
                    let depositAmountCmp = this.template.querySelector(".invoiceAmountClass");
                    if (!isNaN(this.invoiceAmountValue) && (this.invoiceAmountValue > 0 && this.invoiceAmountValue <= 100000) && (this.invoiceAmountValue !== "")) {
                        depositAmountCmp.setCustomValidity("");
                        if ( this.modeOfPaymentMap[this.paymentOptionSelected] === 'Cash') {
                            let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                            if((parseFloat(this.cashReceivedValue) >= 0 && parseFloat(this.cashReceivedValue) <= 1000000)){
                                if ((this.invoiceAmountValue !== "" && this.cashReceivedValue === "")) {
                                    this.IsValid = false;
                                    cashReceivedCmp.setCustomValidity("Enter Cash Received");
                                }else if (this.invoiceAmountValue !== "" && !(parseFloat(this.invoiceAmountValue) <= parseFloat(this.cashReceivedValue))) {
                                    this.IsValid = false;
                                    cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater or Equal To Payment Amount.");
                                } else if( (parseFloat(this.cashReceivedValue) <= 1000000) && (parseFloat(this.cashReceivedValue) >= 0)) {
                                    this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                                    this.cashDueValue = parseFloat(this.cashReceivedValue - this.invoiceAmountValue).toFixed(2);
                                    this.rec.changeDue = this.cashDueValue;
                                    this.cashDueValue=this.formatValueWithCurrencySign(this.cashDueValue);
                                    cashReceivedCmp.setCustomValidity("");
                                }
                                cashReceivedCmp.reportValidity();
                            }
                        }
                        if(this.invoiceAmountValue > this.invoiceAmount){
                            this.IsValid = false;
                            depositAmountCmp.setCustomValidity("Payment amount cannot be greater than amount due.");
                        }

                    } else if (this.invoiceAmountValue === "" || isNaN(this.invoiceAmountValue)) {
                        this.IsValid = false;
                        depositAmountCmp.setCustomValidity("Enter Payment Amount");
                    } else if (this.invoiceAmountValue <= 0) {
                            this.IsValid = false;
                            depositAmountCmp.setCustomValidity("Payment Amount must be greater than $0.");
                    }else {
                        this.IsValid = false;
                        depositAmountCmp.setCustomValidity("Payment Amount Must Be Greater Than 0 and Less Than 100000.");
                    }
                    depositAmountCmp.reportValidity();
                } else if ((inputField.id).includes("cashid") && this.isPaymentCash == true) {
                    let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                    if (!isNaN(this.cashReceivedValue) && (parseFloat(this.cashReceivedValue) >= parseFloat(this.invoiceAmountValue)) && (this.cashReceivedValue !== "") && (parseFloat(this.cashReceivedValue) <= 1000000) && (parseFloat(this.cashReceivedValue) >= 0)) {
                        this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                        this.cashDueValue = parseFloat(this.cashReceivedValue - this.invoiceAmountValue).toFixed(2);
                        this.rec.changeDue = this.cashDueValue;
                        this.cashDueValue=this.formatValueWithCurrencySign(this.cashDueValue);
                        cashReceivedCmp.setCustomValidity("");
                    } else if (this.cashReceivedValue === "" || isNaN(this.cashReceivedValue)) {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Enter Cash Received");
                    }else if(this.cashReceivedValue <= 0 || this.cashReceivedValue >= 1000000){
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater Than 0 and Less Than 100000.");
                    } else {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater and Equal To Payment Amount.");
                    }
                    cashReceivedCmp.reportValidity();
                } else if ((inputField.id).includes("CheckId") && this.isPaymentCheck == true) {
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
                }
            }, true);
    }

    /* Check combobox validity */
    checkComboboxValidity() {
        const All_Compobox_Valid = [...this.template.querySelectorAll('lightning-combobox')]
            .reduce((validSoFar, input_Field_Reference) => {
                if ((input_Field_Reference.id).includes("paymentId")) {
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

    /* Publishes a message to close the modal using Lightning message service */
    closeModal() {
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
    }

    /* Dynamically styles the component based on conditions during rendering */
    renderedCallback() {
        if (!this.isMobile) {
            const STYLE = document.createElement("style");
            STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
                max-width: 43rem;
            }`;
            this.template.querySelector('.uncollected-payment-container').appendChild(STYLE);

            const hideQuickActionCross = document.createElement("style");
            hideQuickActionCross.innerText = `.slds-button_icon-bare{
                content-visibility :hidden;
                visibility: collapse;
            }`;
            this.template.querySelector('.uncollected-payment-container').appendChild(hideQuickActionCross);
        }
        if(this.initialModal){
            const hideCustomValidity = document.createElement("style");
                hideCustomValidity.innerText = `.slds-has-error .slds-form-element__help{
                    white-space: nowrap;
                }`;
            this.template.querySelector('.invoiceClass').appendChild(hideCustomValidity);
        }
        if (this.onNextSuccess && !this.showSpinner && this.showPaymentModal && this.isMobile) {
            const changeInputBoxSize = document.createElement("style");
            changeInputBoxSize.innerText = `.slds-input {
                min-height : 2px;
                line-height : 2.2;
            }`;
            this.template.querySelector('.invoiceAmountClass').appendChild(changeInputBoxSize);
        }
    }

    /* Handle form submission */
    async handleSubmit() {
        this.invoiceRelatedData = {
            invoiceAmount : this.invoiceAmount, 
            invoiceAmountValue : this.invoiceAmountValue, 
            matchedInvoiceDetails : this.matchedInvoiceDetails,
            isTerminalVisible :  this.isTerminalVisible,
            isPaymentCash : this.isPaymentCash,
            isPaymentCheck : this.isPaymentCheck,
        }
        this.IsValid = true;
        this.checkInputValidity();
        this.checkComboboxValidity();
        this.orderId = this.matchedInvoiceDetails?.Order__c;
        if (this.IsValid) {
            const invoiceRecordId = this.invoiceId || this.matchedInvoiceDetails?.Id;
            const invoiceAmountEntered = this.amountCollected || (this.matchedInvoiceDetails?.Total_invoice_Amount__c - this.matchedInvoiceDetails?.Money_Applied_to_Invoice__c);
            const moneyAppliedAmount = this.moneyAppliedToInvoice || this.matchedInvoiceDetails?.Money_Applied_to_Invoice__c;
            console.log('updateInvoice', [invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount])
            this.invoiceRelatedData = { ...this.invoiceRelatedData, invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount, orderId : this.orderId };
            this.rec.amountCollected = this.rec.amountCollected || this.invoiceAmountValue;
            try {
                this.paymentProcessing = true;
                await this.createTransactionRecord();
                await this.callUncollectedAPI(invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount);
            } catch (error) {
                console.error('error in catch api', error);
                this.errorMessage = error?.body?.message || error?.body || error
            } finally {
                this.isApiCallComplete = true;
            }
        } 
    }

    async callUncollectedAPI(invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount) {
        try {
            const result = await makeAPICall({
                orderRecordId: this.orderId,
                paymentDepositData: JSON.stringify(this.rec),
                transactionId: this.transactionId,
                wynneUserName: this.wynneUserName
            });
            const data = result?.data;
            const { contractId, detailSeqNumber, sourceTransactionId, message } = data || {};
            const isCashOrCheck = ['Cash', 'Check'].includes(this.modeOfPaymentMap[this.paymentOptionSelected]);
            const isTransactionValid = isCashOrCheck ? contractId && detailSeqNumber : contractId && detailSeqNumber && sourceTransactionId;
            const asyncSuccessMessage = 'Uncollected Payment request is accepted for further processing';
            if (isTransactionValid || message == asyncSuccessMessage) {
                if (isTransactionValid) {
                    await Promise.all([this.updateTransactionRecord(detailSeqNumber), this.updateInvoiceDetails(invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount)])
                        .catch(error => {
                            console.log('error in promise', error);
                            this.errorMessage = error?.body?.message || error?.body || error;
                        })
                }
            } else {
                this.closeModal();
            }
        } catch (error) {
            console.error('Error in apicall', error);
            this.errorMessage = error?.body?.message || error?.body || error;
        }
    }

    async createTransactionRecord() {
        try {
            const transactionData = await createTransaction({ orderRecordId: this.orderId, paymentDepositData: JSON.stringify(this.rec) })
            console.log('Data Transaction', transactionData);
            if (transactionData != null) {
                this.transactionId = transactionData;
            }
        } catch (error) {
            console.error('Error in creating transaction', error)
            let message = this.errorMessage =  error?.body?.message || error?.body || error;
            const evt = new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error',
            });
            this.closeModal();
            this.dispatchEvent(evt);
        }
    }
    /* Updates transaction record with given detail sequence number and publishes a refresh message */
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
          publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
        }).catch(error => {
          console.error('Error updating transaction record:', error);
          this.errorMessage =  error?.body?.message || error?.body || error;
        });
      }

      /* Updates invoice details asynchronously with error handling */
      async updateInvoiceDetails(invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount){
        console.log('updateInvoiceDetails',[invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount]);
        await updateInvoice({
            invoiceRecordId,
            invoiceAmountEntered,
            moneyAppliedAmount,
        }).catch(error => {
            console.error('Error in updateInvoiceDetails', error);
            this.errorMessage =  error?.body?.message || error?.body || error;
        }) 
      }

}