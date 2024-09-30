/* Importing necessary modules and dependencies */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

/* Importing Apex methods */
import createTransaction from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction";
import makeAPICall from "@salesforce/apex/SBR_3_0_API_CreatePayments.createPayments";
import fetchTotalDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDeposit";
import fetchPaymentTypeWithTerminal from "@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentTypeWithTerminal";
import PaymentMethodDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentMethod";
import TerminalDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getTerminal";
import UncollectedReasons from "@salesforce/apex/SBR_3_0_MakeADepositController.getUncollectedReasons";
import userAccesValidation from "@salesforce/apex/SBR_3_0_UserAccess.validateUserAccess";
import orderWithOrderItem from "@salesforce/apex/SBR_3_0_MakeADepositController.orderWithOrderItemDetails";
import getOrder from "@salesforce/apex/SBR_3_0_MakeADepositController.getOrder";
import getrecordType from "@salesforce/apex/SBR_3_0_MakeADepositController.getrecordTypeDetailsFromOrder";

/* Importing labels */
import PreviousPaymentMethod from '@salesforce/label/c.SBR_3_0_PreviousPaymentMethod';
import NewPaymentMethod from '@salesforce/label/c.SBR_3_0_NewPaymentMethod';
import ChangeDue from '@salesforce/label/c.SBR_3_0_ChangeDue';
import MakeaDeposit from '@salesforce/label/c.SBR_3_0_MakeaDeposit';
import PaymentonRentalReturn from '@salesforce/label/c.SBR_3_0_Payment_on_Rental_Return';
import AdditionalDepositDue from '@salesforce/label/c.SBR_3_0_Additional_Deposit_Due';
import DepositAmount from '@salesforce/label/c.SBR_3_0_Deposit_Amount';
import PaymentAmount from '@salesforce/label/c.SBR_3_0_Payment_Amount';
import CheckNumber from '@salesforce/label/c.SBR_3_0_Check_Number';
import Terminal from '@salesforce/label/c.SBR_3_0_Terminal';
import CashReceived from '@salesforce/label/c.SBR_3_0_Cash_Received';
import DepositPaid from '@salesforce/label/c.SBR_3_0_Deposit_Paid';
import PaymentMethod from '@salesforce/label/c.SBR_3_0_Payment_Method';
import TotalEstimatedDeposit from '@salesforce/label/c.SBR_3_0_Total_Estimated_Deposit';
import SelectionMessage from '@salesforce/label/c.SBR_3_0_Selection_Message';
import ReasonForUncollected from '@salesforce/label/c.SBR_3_0_ReasonforUncollected';
import OtherReason from '@salesforce/label/c.SBR_3_0_Other_Reason';

/* Import schema fields */
import TotalAmount from '@salesforce/schema/Order.Total_Rental_Amount__c';
import USER_ID from '@salesforce/user/Id';
import DEPARTMENT from '@salesforce/schema/User.Department';
import COUNTRYCODE from '@salesforce/schema/User.CountryCode';
import WYNNEUSERNAME from '@salesforce/schema/User.Wynne_User_Name__c';
import InvoiceAmount from '@salesforce/schema/Order.Total_Invoiced_Amount__c';
import RevenueAmount from '@salesforce/schema/Account.Total_Revenue_Amount__c';
import RentalAmount from '@salesforce/schema/Account.Rental_Revenue__c';
import StartDate from '@salesforce/schema/Order.Start_Date__c';
import EarliestDeliveryDate from '@salesforce/schema/Order.Earliest_Delivery_Date__c';

/* Importing messaging related modules */
import { publish, MessageContext } from 'lightning/messageService';
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';

/* Importing templates */
import DefaultTemplate from "./sbr_3_0_makeAdeposit.html";
import mobileTemplate from "./sbr_3_0_makeAdepositMobileTemplate.html";

/* Importing utility functions */
import { CurrentPageReference } from 'lightning/navigation';
import { updateRecord } from "lightning/uiRecordApi";
import { checkTerminalInSession, getTerminalDetails } from 'c/sbr_3_0_TerminalSelection';
import { getPaymentMethodDetails } from 'c/sbr_3_0_PaymentMethodSelection';


/* Initialize class */
export default class paymentInitialize extends NavigationMixin(LightningElement) {

    /* Defining labels */
    label = {
        MakeaDeposit,
        AdditionalDepositDue,
        DepositAmount,
        DepositPaid,
        PaymentMethod,
        TotalEstimatedDeposit,
        CheckNumber,
        Terminal,
        CashReceived,
        PreviousPaymentMethod,
        NewPaymentMethod,
        SelectionMessage,
        ChangeDue,
        ReasonForUncollected,
        OtherReason,
        PaymentonRentalReturn,
        PaymentAmount
    };

    /* Define other tracked properties and APIs */
    @track paymentLabel;
    @track paymentProcessing = false;
    @track makeAdepositChangeScreen = true;
    @track makeApaymentScreen = false;
    @track paymentMethod;
    @track uncollectedReason;
    @track totalAmount = '0.00';
    @track totalAmountUI = '0.00';
    @track depositAmount = '0.00';
    @track depositAmountUI = '0.00';
    @track InvoiceAmount = '0.00';
    @track sessionId;
    @track error;
    @track department;
    @track wynneUserName;
    @track countrycode;
    @track accountRelatedOrderId;
    @track paymentOptions = [];
    @track $showSpinner = true;
    @track rec = {
        paymentMethod: '',
        amountCollected: 0,
        terminal: '',
        tranType: 'Charged',
        cashReceived: 0,
        checkNumber: 0,
        changeDue: 0
    }

    @api ispaymentProcessing = false;
    @api orderidchange;
    @api makeAdepositScreen = false;
    @api recordId;
    @api message = '';
    @api source = '';
    @api isPaymentOnReturn = false;
    @api isPaymentCash = false;
    @api isTerminalVisible = false;
    @api isUncollectedReasonVisible = false;
    @api isOtherReasonVisible = false;
    @api dueDeposit = '0.00';
    @api dueDepositUI = '0.00';
    @api paymentOptionSelected = '--None--';
    @api depositAmountValue;
    @api terminalValue;
    @api UncollectedReasonValue = '--None--';
    @api isCreateReservation = false;
    @api quickActionAPIName = '';
    @api transactionId;
    @api cashDueValue;
    @api checkValue = '';
    @api value = 'option1';
    @api isComboboxVisible;
    @api isPaymentCheck = false;
    @api cashReceivedValue;
    @api isFailedScreenBack = false;
    @api sObjectName;
    @api isSubmitRentalReturn = false;
    @api isFromCreateReturn = false;

    @wire(MessageContext)
    messageContext;
    @wire(CurrentPageReference)
    pagereference;

    isContractOrderOpen = false;
    createReservation = false;
    isMobile = false;
    paymentMethodRelatedData;
    isOutputFieldVisible = false;
    paymentTransactionTypes;
    showRadioGroup;
    paymentTypes;
    terminalOptions = [];
    UncollectedReasonOptions = [];
    textValue = 'success';
    otherReasonValue = '';
    IsValid = true;
    fetchTotalAmountWire = false;
    fetchuserInfoWire = false;
    errorMessage;
    modeOfPaymentMap = {};
    isApiCallComplete = false;


    /* Getter to determine whether to show the spinner */
    get showSpinner() {
        return !(this.fetchTotalAmountWire && this.fetchuserInfoWire);
    }

    /* Initialize connectedCallback */
    async connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        this.sObjectName = this.pagereference.attributes.objectApiName;
        this.ispaymentProcessing = true;
        this.handleComponentHeaderLabel();
        [this.sessionId, this.terminalValue] = Object.values(await checkTerminalInSession());
        this.fetchOrderDetails();
    }

    /* Method to handle processing successful label based on payment or refund */
    handleComponentHeaderLabel() {

        if (this.pagereference.type === 'standard__recordPage' && this.pagereference.attributes.objectApiName === 'Account' ) {
            this.header = this.label.PaymentonRentalReturn;
            this.amount = this.label.PaymentAmount;
        } else {
            this.header = this.label.MakeaDeposit;
            this.amount = this.label.DepositAmount;
        }

        if(this.isFromCreateReturn){
            this.header = this.label.PaymentonRentalReturn;
            this.amount = this.label.PaymentAmount;
        }
    }

    /* Rendered callback to adjust modal style */
    renderedCallback() {
        if (!this.isMobile) {
            const makeDepositContainer = this.template.querySelector('.make-deposit-container');
            if (makeDepositContainer) {
                const STYLE = document.createElement("style");
                STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
                max-width: 35rem;   
                min-width: 35rem;
            }`;
                this.template.querySelector('.make-deposit-container').appendChild(STYLE);
                const hideExtraCloseIcon = document.createElement("style");
                hideExtraCloseIcon.innerText = `.slds-button_icon-bare{
                content-visibility :hidden;
                visibility: collapse;
            }`;
                this.template.querySelector('.make-deposit-container').appendChild(hideExtraCloseIcon);
                const STYLEN = document.createElement("style");
                const STYLEN1 = document.createElement("style");
                STYLEN.innerText = ` .header{
            content-visibility :hidden;
            }`;
                STYLEN1.innerText = ` .slds-card__header{
                content-visibility :hidden;
            }`;
                this.template.querySelector('.make-deposit-container').appendChild(STYLEN);
                this.template.querySelector('.make-deposit-container').appendChild(STYLEN1);
            }
        }
        if (this.isPaymentOnReturn) {
            const depositAmountElement = this.template.querySelector('.depositAmountClass');
            if (depositAmountElement) {
                const STYLEBGC = document.createElement("style");
                STYLEBGC.innerText = `.slds-input[disabled], .slds-input.slds-is-disabled {
                background-color : #E5E5E5;
            }`;
                this.template.querySelector('.depositAmountClass')?.appendChild(STYLEBGC);
            }
            if (!this.showSpinner && this.isMobile) {
                const changeInputBoxSize = document.createElement("style");
                changeInputBoxSize.innerText = `.slds-input {
                min-height : 2px;
                line-height : 2.2;
            }`;
                this.template.querySelector('.depositAmountClass')?.appendChild(changeInputBoxSize);
            }
        }
    }

    /* Render method to determine which template to use based on the device type */
    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    /* Handler for payment failure */
    handlePaymentFailed(event) {
        this.paymentOptionSelected = event.detail.paymentmethod;
        this.handlePaymentMethod(event);
        this.getTotalDeposit();
    }

    /* Handler for payment method change */
    handlePaymentMethod(event) {
        let paymentMethodValue;
        paymentMethodValue = event.target.value;
        this.paymentOptionSelected = event.target.value;
        this.checkComboboxValidity();
        if (this.modeOfPaymentMap[paymentMethodValue] == 'Pay on Return') {
            this.isPaymentOnReturn = true;
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = false;
            this.isUncollectedReasonVisible = false;
            this.isOtherReasonVisible = false;
            let depositAmountCmp = this.template.querySelector(".depositAmountClass");
            depositAmountCmp.required = false;
            depositAmountCmp.value = '0.00';
            this.rec.amountCollected = 0.00;
            this.depositAmountValue = 0.00;
            depositAmountCmp.setCustomValidity("");
            depositAmountCmp.reportValidity();
        } else if (this.modeOfPaymentMap[paymentMethodValue] == 'Cash') {
            this.isPaymentOnReturn = false;
            this.isPaymentCash = true;
            this.isTerminalVisible = false;
            this.isPaymentCheck = false;
            this.isUncollectedReasonVisible = false;
            this.isOtherReasonVisible = false;
            if (this.depositAmountValue == (this.dueDeposit) || this.depositAmountValue == 0.00) {
                this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                if (this.depositAmountValue < 0) {
                    this.depositAmountValue = '0.00';
                }
                this.rec.amountCollected = parseFloat(this.depositAmountValue);
            }
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] == 'Check') {
            this.isPaymentOnReturn = false;
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = true;
            this.isUncollectedReasonVisible = false;
            this.isOtherReasonVisible = false;
            if (this.depositAmountValue == (this.dueDeposit) || this.depositAmountValue == 0.00) {
                this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                if (this.depositAmountValue < 0) {
                    this.depositAmountValue = '0.00';
                }
                this.rec.amountCollected = parseFloat(this.depositAmountValue);
            }
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] == 'Cards') {
            this.isPaymentOnReturn = false;
            this.isPaymentCash = false;
            this.isTerminalVisible = true;
            this.isPaymentCheck = false;
            this.isUncollectedReasonVisible = false;
            this.isOtherReasonVisible = false;
            if (this.depositAmountValue == (this.dueDeposit) || this.depositAmountValue == 0.00) {
                this.depositAmountValue = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                if (this.depositAmountValue < 0) {
                    this.depositAmountValue = '0.00';
                }
                this.rec.amountCollected = parseFloat(this.depositAmountValue);
            }
        } else if (this.modeOfPaymentMap[paymentMethodValue] == 'Uncollected') {
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = false;
            this.isUncollectedReasonVisible = true;
            this.isPaymentOnReturn = true;
            let depositAmountCmp = this.template.querySelector(".depositAmountClass");
            depositAmountCmp.required = false;
            depositAmountCmp.value = '0.00';
            this.rec.amountCollected = 0.00;
            this.depositAmountValue = 0.00;
            depositAmountCmp.setCustomValidity("");
            depositAmountCmp.reportValidity();
        }
    }

    /* Checks if the selected value is 'option1' */
    get isOption1Checked() {
        return this.value === 'option1';
    }

    /* Checks if the selected value is 'option2' */
    get isOption2Checked() {
        return this.value === 'option2';
    }

    /* Handle radio button change */
    async handleRadioChange(event) {
        this.value = event.target.value;
        this.isFailedScreenBack = false;
        if (this.value == 'option2') {
            this.terminalValue = localStorage.getItem(this.sessionId) || '--None--';
            this.isComboboxVisible = true;
            this.paymentOptionSelected = '--None--';
            this.getTotalDeposit();
        } else if (this.value == 'option1') {
            this.isComboboxVisible = false;
            this.isPaymentOnReturn = false;
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = false;
            this.isUncollectedReasonVisible = false;
            this.isOtherReasonVisible = false;
            this.paymentOptionSelected = this.rec.paymentMethod = this.paymentLabel.substring(0, this.paymentLabel.length - 9);
            this.getTotalDeposit();

        }
    }

    /* Format the cashValue with currency sign */
    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    /* Retrieve payment types */
    async getPaymentTypes() {
        var inputId;
        if (this.pagereference.type === 'standard__recordPage' && this.pagereference.attributes.objectApiName === 'Account') {
            inputId = this.accountRelatedOrderId;
        } else {
            inputId = this.recordId
        }
        fetchPaymentTypeWithTerminal({ orderId: inputId })
            .then(async (paymentTypesWithTerminal) => {
                let paymentTypeFound = false;
                let matchingPaymentType = '';
                const { paymentMethodMap } = await getPaymentMethodDetails(this.getComponentName()) || {};
                const acceptedCardTypes = Object.keys(paymentMethodMap).filter(e => paymentMethodMap[e] == "Cards");
                if (paymentTypesWithTerminal && paymentTypesWithTerminal.length > 0) {
                    for (let i = 0; i < paymentTypesWithTerminal.length; i++) {
                        const currentType = paymentTypesWithTerminal[i].type;
                        const currentTerminal = paymentTypesWithTerminal[i].terminal;
                        if (acceptedCardTypes.some(cardType => currentType.includes(cardType))) {
                            paymentTypeFound = true;
                            matchingPaymentType = currentType;
                            this.paymentOptionSelected = this.isFailedScreenBack ? this.paymentOptionSelected : currentType.substring(0, currentType.length - 9);
                            this.terminalValue = this.isFailedScreenBack ? this.terminalValue : currentTerminal; // Store the terminal
                            break;
                        }
                    }
                }
                if (paymentTypeFound) {
                    this.showRadioGroup = true;
                    this.paymentLabel = matchingPaymentType;
                    if (!this.isFailedScreenBack && !this.value == 'option1') {
                        this.isComboboxVisible = false;
                    }
                } else {
                    this.isComboboxVisible = true;
                    this.showRadioGroup = false;
                }

                if (this.paymentOptionSelected !== null && paymentTypeFound) {
                    this.rec.paymentMethod = this.paymentOptionSelected;
                    this.rec.terminal = this.terminalValue;
                }

            })
            .catch(error => {
                console.error('error fetchPaymentTypeWithTerminal', error);
            })
    }

    /* Wire method to fetch user details */
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


    /* Retrieve payment and terminal details */
    async getPaymentAndterminalDetails() {
        const [paymentMethodDetails, terminalOption,] = await Promise.all([getPaymentMethodDetails(this.getComponentName()), getTerminalDetails(this.department), this.getUncollectedReasons()]).finally(() => {
            this.fetchuserInfoWire = true;
        })
        this.terminalOptions = terminalOption;
        ({ paymentOptions: this.paymentOptions, paymentMethodMap: this.modeOfPaymentMap } = paymentMethodDetails || {});
    }

    /* Determines and returns the component name based on page reference and flags */
    getComponentName() {
        if (!this.isSubmitRentalReturn) {
            this.isSubmitRentalReturn = this.pagereference.type === 'standard__recordPage' && this.pagereference.attributes.objectApiName === 'Account';
        }
        return this.isCreateReservation ? 'Create Reservation' : (this.isSubmitRentalReturn ? 'Submit Rental Return' : '');
    }

    /* Fetches uncollected reasons and populates options */
    async getUncollectedReasons() {
        await UncollectedReasons()
            .then(data => {
                let tempOptions = [];
                if (data) {
                    tempOptions.push({ value: '--None--', label: '--None--' })
                    if (data != null) {
                        data.forEach(UncollectedReasonOption => {
                            let rowData = {};
                            rowData.label = UncollectedReasonOption
                            rowData.value = UncollectedReasonOption
                            tempOptions.push(rowData)
                        });
                        this.UncollectedReasonOptions = tempOptions;
                    }
                }
            }).catch(error => {
                console.log('error', error);
            })
    }

    /* Wire method to fetch total amount & invoice Amount */
    @wire(getRecord, { recordId: '$recordId', fields: [TotalAmount, InvoiceAmount, StartDate, EarliestDeliveryDate] })
    totalAmount({ error, data }) {
        if (data) {
            if (getFieldValue(data, TotalAmount) != null) {
                this.totalAmount = getFieldValue(data, TotalAmount).toFixed(2);
                this.totalAmountUI = this.formatValueWithCurrencySign(this.totalAmount);
            } else {
                this.totalAmountUI = this.formatValueWithCurrencySign(this.totalAmount);
            }
            if (getFieldValue(data, InvoiceAmount) != null) {
                this.InvoiceAmount = getFieldValue(data, InvoiceAmount).toFixed(2);
            }
            this.getPaymentTypesAndTotalDeposit();
        }
        else if (error) {
            this.fetchTotalAmountWire = true
            console.error(error);
        }
    }

    /* Fetches order details and sets order state based on record type and status */
    fetchOrderDetails() {
        getrecordType({ orderId: this.recordId })
            .then(data => {
                this.orderDetails = data.length > 0 ? data[0] : {};
                this.isContractOrderOpen = this.orderDetails.Record_Type_Name__c === 'Contract Order' && this.orderDetails.Status !== 'Open';

            })
            .catch(error => {
                this.orderDetails = undefined;
                console.error('Error fetching order details', error);
            });
    }

    /* Fetches payment types and total deposit based on account or order context */
    async getPaymentTypesAndTotalDeposit() {
        if (this.pagereference.attributes.objectApiName == 'Account') {
            await getOrder({ accountId: this.recordId })
                .then(result => {
                    this.accountRelatedOrderId = result[0].Id;
                })
                .catch(error => {
                    this.error = error;
                });
            Promise.all([this.getPaymentTypes(), this.getTotalDepositRentalReturn()]).finally(() => {
                this.fetchTotalAmountWire = true;
            })
        } else {
            Promise.all([this.getPaymentTypes(), this.getTotalDeposit()]).finally(() => {
                this.fetchTotalAmountWire = true;
            })
        }
    }

    /* Validates user access and order item presence before submitting reservation details */
    validateSubmitReservationDetails() {
        userAccesValidation({
            orderId: this.recordId
        }).then(data => {
            if (data == true) {
                this.orderHasOrderItem();
            } else {
                let message = 'User don\'t have access for sending.';
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message,
                    variant: 'error',
                });
                this.closeModal();
                this.dispatchEvent(evt);
            }
        }).catch(error => {
            console.error('Error', error)
            let message = error?.body?.message;
            const evt = new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error',
            });
            this.closeModal();
            this.dispatchEvent(evt);
        })
    }

    /* Checks if the order has associated order items */
    orderHasOrderItem() {
        orderWithOrderItem({
            orderId: this.recordId
        }).then(data => {
            if (data == true) {
            } else {
                let message = 'There is no Order Item present on this Order.';
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message,
                    variant: 'error',
                });
                this.closeModal();
                this.dispatchEvent(evt);
            }
        }).catch(error => {
            console.error('Error', error)
            let message = error?.body?.message;
            const evt = new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error',
            });
            this.closeModal();
            this.dispatchEvent(evt);
        })

    }

    /* Wire method to fetch total amount & invoice Amount */
    @wire(getRecord, { recordId: '$recordId', fields: [RevenueAmount, RentalAmount] })
    rentalAmount({ error, data }) {
        if (data) {
            if (this.pagereference.type === 'standard__recordPage' && this.pagereference.attributes.objectApiName === 'Account') {
                if (getFieldValue(data, RevenueAmount) != null) {
                    this.totalAmount = getFieldValue(data, RevenueAmount).toFixed(2);
                    this.totalAmountUI = this.formatValueWithCurrencySign(this.totalAmount);
                } else {
                    this.totalAmount = 0;
                    this.totalAmountUI = this.formatValueWithCurrencySign(0);
                }
                if (getFieldValue(data, RentalAmount) != null) {
                    this.InvoiceAmount = getFieldValue(data, RentalAmount).toFixed(2);
                }
                this.getPaymentTypesAndTotalDeposit();
            }
        }
        else if (error) {
            console.error(error);
        }
    }

    /* Fetch total deposit for RentalReturn */
    async getTotalDepositRentalReturn() {
        this.depositAmount = this.InvoiceAmount;
        if (this.depositAmount > 0) {
            this.depositAmountUI = -(this.depositAmount);
        } else {
            this.depositAmountUI = this.depositAmount;
        }
        this.depositAmountUI = this.formatValueWithCurrencySign(this.depositAmountUI);
        this.dueDeposit = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
        this.dueDepositUI = this.formatValueWithCurrencySign(this.dueDeposit);
        if (this.dueDeposit < 0) {
            this.dueDeposit = '0.00';
            this.dueDepositUI = '$0.00';
        }
        if (this.depositAmount < 0) {
            this.depositAmount = '0.00';
            this.depositAmountUI = '-$0.00';
        }
        this.depositAmountValue = this.dueDeposit;

    }

    /* Fetch total deposit */
    async getTotalDeposit() {
        await fetchTotalDeposit({ orderId: this.recordId })
            .then(data => {
                if (this.depositAmountValue == null || this.depositAmountValue == undefined || this.depositAmountValue === "") { //FRONT-17140 
                    if (data != null || !isNaN(data)) {
                        this.depositAmount = (data.toFixed(2) - this.InvoiceAmount).toFixed(2);
                        if (this.depositAmount > 0) {
                            this.depositAmountUI = -(this.depositAmount);
                        } else {
                            this.depositAmountUI = this.depositAmount;
                        }
                        this.depositAmountUI = this.formatValueWithCurrencySign(this.depositAmountUI);

                    } else {
                        this.depositAmount = '0.00';
                        this.depositAmountUI = '-$0.00';
                    }

                    this.dueDeposit = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                    this.dueDepositUI = this.formatValueWithCurrencySign(this.dueDeposit);
                    if (this.dueDeposit < 0) {
                        this.dueDeposit = '0.00';
                        this.dueDepositUI = '$0.00';
                    }
                    if (this.depositAmount <= 0) {
                        this.depositAmount = '0.00';
                        this.depositAmountUI = '-$0.00';
                    }
                    this.depositAmountValue = this.dueDeposit;
                    this.rec.amountCollected = parseFloat(this.depositAmountValue);
                } else {
                    this.depositAmount = data.toFixed(2) - this.InvoiceAmount;
                    const depositAmountNegative = -(this.depositAmount)
                    this.depositAmountUI = this.formatValueWithCurrencySign(depositAmountNegative);
                    this.dueDeposit = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                    this.dueDepositUI = this.formatValueWithCurrencySign(this.dueDeposit);
                    if (this.dueDeposit < 0) {
                        this.dueDeposit = '0.00';
                        this.dueDepositUI = '$0.00';
                    }
                    this.rec.amountCollected = parseFloat(this.depositAmountValue);
                }

            }).catch(error => {
                console.log('error', error);
            })

    }

    /* Handle amount change */
    handleAmountChange(event) {
        this.depositAmountValue = parseFloat(event.target.value);
        this.rec.amountCollected = this.depositAmountValue;
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

    /* Handle UncollectedReason selection */
    handleUncollectedReason(event) {
        this.UncollectedReasonValue = event.target.value;
        this.checkComboboxValidity();
        if (this.UncollectedReasonValue === 'Other') {
            this.isOtherReasonVisible = true;
        } else {
            this.isOtherReasonVisible = false;
        }
    }

    /* Handle UncollectedReason selection */
    handleOtherReasonChange(event) {
        this.otherReasonValue = event.target.value;
        this.checkInputValidity();
    }


    /* Check input validity */
    checkInputValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("depid") && this.paymentOptionSelected != 'Pay on Return') {
                    let depositAmountCmp = this.template.querySelector(".depositAmountClass");
                    if (!isNaN(this.depositAmountValue) && (this.depositAmountValue > 0 && this.depositAmountValue <= 100000) && (this.depositAmountValue !== "")) {
                        depositAmountCmp.setCustomValidity("");
                        if (this.modeOfPaymentMap[this.paymentOptionSelected] === 'Cash') {
                            let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                            if ((parseFloat(this.cashReceivedValue) > 0 && parseFloat(this.cashReceivedValue) <= 100000)) {
                                if ((this.depositAmountValue !== "" && this.cashReceivedValue === "")) {
                                    this.IsValid = false;
                                    cashReceivedCmp.setCustomValidity("Enter Cash Received");
                                } else if (this.depositAmountValue !== "" && !(parseFloat(this.depositAmountValue) <= parseFloat(this.cashReceivedValue))) {
                                    this.IsValid = false;
                                    this.cashDueValue = undefined;
                                    if(this.isFromCreateReturn){
                                        cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater or Equal To Payment Amount.");
                                    }else{
                                        cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater or Equal To Deposit Amount.");
                                    }
                                } else if ((parseFloat(this.cashReceivedValue) <= 100000) && (parseFloat(this.cashReceivedValue) > 0)) {
                                    this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                                    this.cashDueValue = parseFloat(this.cashReceivedValue - this.depositAmountValue).toFixed(2);
                                    this.rec.changeDue = this.cashDueValue;
                                    this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                                    cashReceivedCmp.setCustomValidity("");
                                }
                                cashReceivedCmp.reportValidity();
                            }
                        }

                    } else if (this.depositAmountValue === "" || isNaN(this.depositAmountValue) ) {
                        if(this.modeOfPaymentMap[this.paymentOptionSelected] != 'Uncollected'){
                            this.IsValid = false;
                            if(this.isFromCreateReturn){
                                depositAmountCmp.setCustomValidity("Enter Payment Amount");
                            }else{
                                depositAmountCmp.setCustomValidity("Enter Deposit Amount");
                            }
                        } 
                    }
                    else if (this.depositAmountValue <= 0) {
                        if (this.modeOfPaymentMap[this.paymentOptionSelected] != 'Uncollected') {
                            this.IsValid = false;
                            if(this.isFromCreateReturn){
                                depositAmountCmp.setCustomValidity("Payment amount must be greater than $0.");
                            }else{
                                depositAmountCmp.setCustomValidity("Deposit amount must be greater than $0.");
                            }
                        }
                    } else {
                        this.IsValid = false;
                        depositAmountCmp.setCustomValidity("Deposit Amount Must Be Greater Than $0 and Less Than $100,000.");
                    }
                    if (this.isContractOrderOpen) {
                        if (this.depositAmountValue < this.dueDeposit) {
                            this.IsValid = false;
                            depositAmountCmp.setCustomValidity("Deposit Amount cannot be Less than deposit due.");
                        }
                    }
                    depositAmountCmp.reportValidity();
                } else if ((inputField.id).includes("cashid") && this.isPaymentCash == true) {
                    let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                    if (!isNaN(this.cashReceivedValue) && (parseFloat(this.cashReceivedValue) >= parseFloat(this.depositAmountValue)) && (this.cashReceivedValue !== "") && (parseFloat(this.cashReceivedValue) <= 100000) && (parseFloat(this.cashReceivedValue) >= 0)) {
                        this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                        this.cashDueValue = parseFloat(this.cashReceivedValue - this.depositAmountValue).toFixed(2);
                        this.rec.changeDue = this.cashDueValue;
                        this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                        cashReceivedCmp.setCustomValidity("");
                    } else if (this.cashReceivedValue === "" || isNaN(this.cashReceivedValue)) {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Enter Cash Received");
                    } else if (this.cashReceivedValue < 0 || this.cashReceivedValue > 100000) {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater Than $0 and Less Than $100,000.");
                    } else {
                        this.IsValid = false;
                        if(this.isFromCreateReturn){
                            cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater or Equal To Payment Amount.");
                        }else{
                            cashReceivedCmp.setCustomValidity("Cash Received Must Be Greater and Equal To Deposit Amount.");
                        }
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
                } else if ((inputField.id).includes("reasonid") && this.isOtherReasonVisible == true) {
                    let otherReasonCmp = this.template.querySelector(".otherReasonClass");
                    let regExp = /^0*$/g;
                    let regExpSpecial = /[`~!@#$%^&*()\-+={}[\]:;"'<>?\/|\\]/;

                    if (this.otherReasonValue === "" || this.otherReasonValue === undefined) {
                        this.IsValid = false;
                        otherReasonCmp.setCustomValidity("Enter Valid Reason");
                    } else if (regExp.test(this.otherReasonValue) || regExpSpecial.test(this.otherReasonValue) || Math.sign(this.otherReasonValue) === -1 || this.otherReasonValue.trim() === "") {
                        this.IsValid = false;
                        otherReasonCmp.setCustomValidity("Please specify Valid Reason");
                    } else {
                        otherReasonCmp.setCustomValidity("");
                        this.rec.reason = this.otherReasonValue;
                    }
                    otherReasonCmp.reportValidity();
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
                } else if ((input_Field_Reference.id).includes("UncollectedReasonId")) {
                    let uncollectedCmp = this.template.querySelector(".UncollectedReasonClass");
                    if (!this.UncollectedReasonValue || this.UncollectedReasonValue === '--None--') {
                        this.IsValid = false;
                        uncollectedCmp.setCustomValidity("Select Reason for Uncollected");
                    } else {
                        uncollectedCmp.setCustomValidity("");
                        this.rec.uncollectedReason = this.UncollectedReasonValue;
                    }
                    uncollectedCmp.reportValidity();
                }
            }, true);
    }

    /* Handle form submission */
    async handleSubmit() {
        if (this.value === 'option1') {
            this.rec.usePreviousCard = true;
        }
        this.paymentMethodRelatedData = { value: this.value, isComboboxVisible: this.isComboboxVisible, showRadioGroup : this.showRadioGroup };
        if (this.isCreateReservation === true) {
            this.IsValid = true;
            this.checkInputValidity();
            this.checkComboboxValidity();
            if (this.IsValid) {
                this.createReservation = true;
                return;
            }
        } else {
            this.IsValid = true;
            this.checkInputValidity();
            this.checkComboboxValidity();
            if (this.IsValid) {
                try{
                this.paymentProcessing = true;
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
    }

    async callPaymentsAPI(){
        try{
            const result =  await makeAPICall({ orderRecordId: this.recordId,
                paymentDepositData: JSON.stringify(this.rec),
                transactionId: this.transactionId,
                wynneUserName: this.wynneUserName
            })
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
        }catch(error){
            console.error('Error in api call', error)
            this.errorMessage = error?.body?.message || error?.body || error;
        }
    }

    async createTransactionRecord(){
        try{
            const transactionData = await createTransaction({ orderRecordId: this.recordId, paymentDepositData: JSON.stringify(this.rec) })
            console.log('transaction response', transactionData);
            if (transactionData != null) {
                this.transactionId = transactionData;
            }
            const message = {
                messageToSend: this.textValue,
                sourceSystem: "From Comp : MakeADeposit"
            };
            publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
        }catch(error){
            console.error('Error in creating transaction record', error)
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

    /* Updates the transaction record with the provided detail sequence number and publishes a success message */
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
            this.errorMessage = error?.body?.message || error?.body || error;
        });
    }
}