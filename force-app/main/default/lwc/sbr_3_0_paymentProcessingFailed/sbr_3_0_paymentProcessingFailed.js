/* Importing necessary modules and dependencies */
import { LightningElement, track, api, wire } from 'lwc';
import updateInvoice from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.updateInvoiceDetails";
import createTransaction from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction";
import callCreatePaymentApi from "@salesforce/apex/SBR_3_0_API_CreatePayments.createPayments";
import callUncollectedPaymentApi from "@salesforce/apex/SBR_3_0_API_CreateUncollectedPayments.createUncollectedPayment";

/* Import other labels as needed */
import HeaderTitleDeposit from '@salesforce/label/c.SBR_3_0_Payment_Process_Failed_1'; //15915
import FailedMesssage from '@salesforce/label/c.SBR_3_0_Payment_Process_Failed_2';
import HeaderTitleRefund from '@salesforce/label/c.SBR_3_0_Refund_Process_Failed'; //15915
import PaymentProcess from '@salesforce/label/c.SBR_3_0_PaymentProcessing';
import DepositMessage from '@salesforce/label/c.SBR_3_0_PaymentDepositMessage';

/* Importing messaging related modules */
import { MessageContext, publish } from 'lightning/messageService'; //15915 added publish
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';

import DefaultTemplate from "./sbr_3_0_paymentProcessingFailed.html";
import mobileTemplate from "./sbr_3_0_paymentProcessingFailedMobileTemplate.html";
import { CloseActionScreenEvent } from "lightning/actions";
import { updateRecord } from "lightning/uiRecordApi";
import createTansactionFromAccount from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansactionFromAccount";
import sbr_3_0_ROA_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_roaTableRefresh__c';
import { makeRoaAPICall, updateTransactionRecord } from 'c/sbr_3_0_paymentHelper';

/* Initialize class */
export default class Sbr_3_0_paymentProcessingFailed extends LightningElement {

    /* Import other labels as needed */
    label = {
        FailedMesssageLabel : '',
        HeaderTitle : '', //15915
        PaymentProcess,
        DepositMessage
    };

    /* Define other tracked properties and APIs */
    @api paymentMethodPassed;
    @api depositAmountPassed;
    @api terminalValuePassed;
    @api duedepositN;
    @api ispaymentprocessing = false;
    @api recidN;

    @api isfromsubmitreservation = false; 
    @api submitreservationfailmessage ='';
    @api recordDetail = {};
    @track processing = false;
    waitMessage = '';
    header = '';
    @track makedeposit = false;
    @track errorScreen = true;
    terminalvisibility;
    paymentprocessing = false;
    refundprocessing = false; //15915
    uncollectedprocessing = false;
    textValue = 'success'
    @api isFromDepositScreen; //15915
    @api isFromRefundScreen; //15915
    makeRefund = false; //15915
    @api processAdditionalDeposit = false; //FRONT-15914
    @wire(MessageContext)
    messageContext;
    @api paymentMethodRelatedData;
    @track isMobile = false;
    isComboboxVisible;
    value;
    isFailedScreenBack = true;
    isTerminalVisible;
    isNewPaymentMethod;
    @api isfromcancelprocessing = false;
    @api isFromUncollectedScreen;
    @api isFromRoaScreen;
    uncollectedscreen = false;
    roaScreen = false;
    @api invoiceRelatedData;
    invoiceAmount;
    invoiceAmountValue;
    matchedInvoiceDetails;
    //added for FRONT-23924 START
    @api isFromCreateReservation = false;
    transactionId;
    @api objectApiName
    @api recordDetails; //this contains payment related data.
    openRecordFormCollector= false;
    @api errorMessage;
    isPaymentCash;
    cashReceivedValue;
    cashDueValue;
    isPaymentCheck;
    checkValue;
    isPaymentOnReturn;
    locationId;
    //added for FRONT-23924 END
    @api roaDetailRelatedData;
    isMultipleInvoice;
    isMultiplePaymentCash;
    isInvoiceorComment;
    isMultiplePaymentCheck;
    isInvoiceAmountQues;
    isTotalROAAmount;
    invoiceData;
    isCashChangeDue;
    invoiceOrCommentEntered;
    isInvoice;
    invoiceInfoArray;
    wynneUserName;
    totalPaymentAmount;
    //FRONT-15078 START
    @api isFromCreateReturn = false;
    @api noRefundGiven = false;
    reasonvalue ='';
    isCardPayment;
    isCashOrCheckPayment;
    isRefundChangeDue;
    isCheckNumber;
    isRefundChangeDueNew;
    isCheckNumberNew;
    isCheckNumberMixed;
    isRefundChangeDueMixed;
    modeOfPaymentMap;
    //FRONT-15078 END
    isApiCallComplete = false;
    orderId;
    showRadioGroup;
    cashDueValueUI

    connectedCallback() {
        if (this.isFromCreateReservation) {
            this.label.FailedMesssageLabel = this.errorMessage || FailedMesssage;
        } else {
            this.label.FailedMesssageLabel = this.errorMessage || FailedMesssage;
        }
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        ({
            isComboboxVisible: this.isComboboxVisible,
            value: this.value,
            isTerminalVisible: this.isTerminalVisible,
            isMultiplePaymentCheck: this.isMultiplePaymentCheck,
            isNewPaymentMethod: this.isNewPaymentMethod,
            locationId: this.locationId,
            wynneUserName: this.wynneUserName,
            reasonvalue: this.reasonvalue,
            isCardPayment: this.isCardPayment,
            isCashOrCheckPayment: this.isCashOrCheckPayment,
            isRefundChangeDue: this.isRefundChangeDue,
            isCheckNumber: this.isCheckNumber,
            isRefundChangeDueNew: this.isRefundChangeDueNew,
            isCheckNumberNew: this.isCheckNumberNew,
            isCheckNumberMixed: this.isCheckNumberMixed,
            isRefundChangeDueMixed: this.isRefundChangeDueMixed,
            modeOfPaymentMap: this.modeOfPaymentMap,
            noRefundGiven: this.noRefundGiven,
            showRadioGroup : this.showRadioGroup,
            cashDueValueUI : this.cashDueValueUI
        } = this.paymentMethodRelatedData || {});

        if (this.isFromUncollectedScreen) {
            const { invoiceAmount, invoiceAmountValue, matchedInvoiceDetails, orderId, isTerminalVisible } = this.invoiceRelatedData || {};
            [this.invoiceAmount, this.invoiceAmountValue, this.matchedInvoiceDetails, this.orderId, this.isTerminalVisible] = [invoiceAmount, invoiceAmountValue, matchedInvoiceDetails, orderId, isTerminalVisible];
        }
        console.log('isTerminalVisible   ',this.isTerminalVisible);
        if (this.isfromsubmitreservation) {
            this.processing = true;
            this.makedeposit = false;
            this.errorScreen = false;
            this.paymentprocessing = false;
        }
        // Sets a flag indicating that payment processing is initiated
        this.label.HeaderTitle = (this.isFromDepositScreen || this.isfromsubmitreservation || this.isFromUncollectedScreen || this.isFromRoaScreen) ? HeaderTitleDeposit : (this.isFromRefundScreen ? HeaderTitleRefund : ''); //15915        
    }

    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    // Method to handle the "Try Again" action
    @api async handleTryAgain(event) {
        this.errorMessage = '';
        if(this.isFromCreateReservation){
            this.openRecordFormCollector = true;
            this.errorScreen = false;
            return;
        }
        if(this.isfromsubmitreservation){
            this.header = this.label.PaymentProcess;
            this.waitMessage = this.label.DepositMessage;

            this.processing = true;
            this.makedeposit = false;
            this.errorScreen = false;
            this.paymentprocessing = false;

            let ev = new CustomEvent('failuremethod', 
            {detail : this.recordDetail}
            );
            this.dispatchEvent(ev);  
        }else {
                    // Resets payment processing and related UI states
        //15915 START
        if(this.isFromDepositScreen){
            this.ispaymentprocessing= true;
            this.makedeposit = false;
        }else if(this.isFromRefundScreen){
            this.refundprocessing = true;
            this.makeRefund = false;
            const paymentMethodTrimmed = this.paymentMethodPassed.substring(0, this.paymentMethodPassed.length - 8);
            if (this.modeOfPaymentMap[paymentMethodTrimmed] == 'Cards') {
                this.paymentMethodPassed = this.paymentMethodPassed.substring(0, this.paymentMethodPassed.length - 8)
            } else {
                this.paymentMethodPassed = this.paymentMethodPassed
            }
        } else if(this.isFromUncollectedScreen){
            this.uncollectedprocessing = true;
            this.uncollectedscreen = false;
        }
        this.errorScreen = false;
        this.paymentprocessing = true;
        //15915 END        

        try{
            await this.handleSubmit();
            if (this.isFromUncollectedScreen) {
                await this.handleConfirm();
            }   
        }catch(error){
            console.error('Error in try again', error)
            this.errorMessage = error?.body?.message || error?.body || error;
        }finally{
            this.isApiCallComplete = true;
        }
    }
}

    // Method to handle navigation back
    async handleBack() {
        // Sets UI state to navigate back
        this.errorScreen = false;
        if(this.isFromDepositScreen || this.isfromsubmitreservation){ //15915
            if(this.isFromCreateReservation || this.isFromDepositScreen){
               await this.setPaymentRelatedValues();
            }else{
                this.terminalvisibility = this.value != 'option1'
            }
            this.makedeposit = true;
        }else if(this.isFromRefundScreen){ //15915
            const paymentMethodTrimmed = this.paymentMethodPassed.substring(0, this.paymentMethodPassed.length - 8);
            if (this.modeOfPaymentMap[paymentMethodTrimmed] == 'Cards') {
                this.paymentMethodPassed = (this.paymentMethodPassed || '').split(' ')?.[0];
            } else {
                this.paymentMethodPassed = this.paymentMethodPassed;
            }  
            await this.setPaymentRelatedValues();
            this.makeRefund = true;
        }else if(this.isFromUncollectedScreen){
           await this.setPaymentRelatedValues();
            this.uncollectedscreen = true;
        }else if(this.isFromRoaScreen){    
        ({
            isMultipleInvoice: this.isMultipleInvoice,
            isMultiplePaymentCash: this.isMultiplePaymentCash,
            isInvoiceorComment: this.isInvoiceorComment,
            isMultiplePaymentCheck: this.isMultiplePaymentCheck,
            isInvoiceAmountQues: this.isInvoiceAmountQues,
            isTotalROAAmount: this.isTotalROAAmount,
            isInvoice: this.isInvoice,
            invoiceData: this.invoiceData,
            isCashChangeDue : this.isCashChangeDue,
            invoiceOrCommentEntered : this.invoiceOrCommentEntered,
            invoiceInfoArray : this.invoiceInfoArray,
            totalPaymentAmount : this.totalPaymentAmount
        } = this.roaDetailRelatedData || {});
            await this.setPaymentRelatedValues();
                this.roaScreen = true;
            }
    }

    async setPaymentRelatedValues(){
        const isNonCardPayment = ['Cash Currency', 'Check', 'Pay on Return','No Refund Given'].includes(this.paymentMethodPassed);
        this.terminalvisibility = !isNonCardPayment && ((this.value != 'option1') || (this.value == 'option1' && this.showRadioGroup == false));
        if(this.paymentMethodPassed == 'Cash Currency'){
            this.isPaymentCash = true;
            this.cashReceivedValue = this.recordDetails?.cashReceived;
            this.cashDueValue = this.recordDetails?.changeDue;
        }else if(this.paymentMethodPassed == 'Check'){
            this.isPaymentCheck = true;
            this.checkValue = this.recordDetails?.checkNumber;
        }else if(this.paymentMethodPassed == 'Pay on Return'){
            this.isPaymentOnReturn = true;
        }
    }

    // Method to handle form submission
    async handleSubmit() {
        await this.createTransactionRecord();
        if (this.isFromRoaScreen) {
            makeRoaAPICall.call(this);
            const message = {
                messageToSend: 'success',
                sourceSystem: "From Comp : MakeADeposit"
            };
            publish(this.messageContext, sbr_3_0_ROA_Table_Refresh, message);
        } else {
            await this.makeAPICall();
        }
    }

    async createTransactionRecord(){
        try{
            let transactionRecordId;
            const orderId = this.uncollectedscreen ? this.orderId : this.recidN;
            if (this.isFromRoaScreen) {
                transactionRecordId = await createTansactionFromAccount({ accountRecordId: this.recidN, paymentDepositData: JSON.stringify(this.recordDetails) })
            } else {
                transactionRecordId = await createTransaction({ orderRecordId: orderId, paymentDepositData: JSON.stringify(this.recordDetails) });
            }
            this.transactionId = transactionRecordId;
            console.log('this.transactionId failed',this.transactionId)
            const message = {
                messageToSend: this.textValue,
                sourceSystem: "From Comp : RefundDeposit"
            };
            publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);

        }catch(error){
            console.error('Error in creating transaction', error)
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

    async makeAPICall(){
        try{
            let apiResponse;
            if(this.uncollectedscreen){
                apiResponse = await callUncollectedPaymentApi({ orderRecordId: this.recidN, paymentDepositData: JSON.stringify(this.recordDetails), transactionId: this.transactionId, wynneUserName : this.wynneUserName });
            }else{
                apiResponse = await callCreatePaymentApi({ orderRecordId : this.recidN, paymentDepositData : JSON.stringify(this.recordDetails), transactionId :this.transactionId, wynneUserName : this.wynneUserName });
            }
           console.log('createTransaction api response',apiResponse);
           const data = apiResponse?.data;
           const { contractId, detailSeqNumber, sourceTransactionId, message } = data || {};
           const isCashOrCheck = ['Cash Currency', 'Check'].includes(this.paymentMethodPassed);
           const isTransactionValid = isCashOrCheck ? contractId && detailSeqNumber : contractId && detailSeqNumber && sourceTransactionId;
           const asyncSuccessMessage = 'Deposit Maintenance request is accepted for further processing';
           const asyncSuccessMessageUncollected = 'Uncollected Payment request is accepted for further processing';
           if (isTransactionValid || message == asyncSuccessMessage || message == asyncSuccessMessageUncollected) {
               if(isTransactionValid){
                   await updateTransactionRecord.call(this,detailSeqNumber);
               }
            if(this.refundprocessing){
                const fields = {
                    Id: this.locationId,
                    Allow_Refund_Greater_Than_Amount__c:  false,
                    Allow_Refund_on_New_Card__c: false
                  };
                  const recordInput = { fields };
                  updateRecord(recordInput).catch(error => {
                    console.error('error in updating location',error);
                  })
            }
           }else{
               this.closeModal();
           }       
        }catch(error){
            console.error('error in api call',error);
            this.errorMessage = error?.body?.message || error?.body || error;
        }
    }

    /* Handle form submission */
   async handleConfirm() {
        const invoiceRecordId = this.matchedInvoiceDetails?.Id;
        const invoiceAmountEntered = parseFloat(this.invoiceAmountValue);
        const moneyAppliedAmount = this.matchedInvoiceDetails?.Money_Applied_to_Invoice__c;
        updateInvoice({
            invoiceRecordId,
            invoiceAmountEntered,
            moneyAppliedAmount,
        }).catch(error => {
            console.error('Error', error);
            this.errorMessage = error?.body?.message || error?.body || error;
        }) 
    }
    
    @api handleSubmitReservation(failedmessage){
        this.paymentMethodPassed = this.recordDetail.paymentMethod;
        this.depositAmountPassed = this.recordDetail.amountCollected;
        this.terminalValuePassed = this.recordDetail.terminal;
        this.label.FailedMesssage = failedmessage;
        this.processing = false; 
        this.errorScreen = true;            
    }

    closeModal() {
        if(this.isfromcancelprocessing || this.isfromsubmitreservation){            
            this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
        }else{
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });
        }
    }

    // Called when the component is rendered
    renderedCallback() {
        // Checks if already loaded to avoid re-execution
        if (this.isLoaded) return;
        if (!this.isMobile) {
            const container = document.createElement("style");
            container.innerText = ` .uiModal--horizontalForm .modal-container{
            max-width: 35rem;   
            min-width: 35rem;
        }`;
            this.template.querySelector('.payment-processing-failed').appendChild(container);

            // Dynamically adds CSS style for .slds-modal__close element
            const STYLE = document.createElement("style");
            STYLE.innerText = `.slds-modal__close {
            content-visibility: visible; 
        }`; //visibility : visible;

            // Appends the style to the payment processing failed section
            this.template.querySelector('.payment-processing-failed').appendChild(STYLE);
        }

        // Marks as loaded to prevent re-execution
        this.isLoaded = true;
    }

}