/**
     ** This modal is to validate the invoice number entered and give validations accordingly and render UCA payment Modal.
     * @author Manu
     * @userStory FRONT-18661
*/
import DefaultTemplate from "./sbr_3_0_makeROAPayment.html";
import mobileTemplate from "./sbr_3_0_makeROAPaymentMobileTemplate.html";
import { LightningElement, api, track, wire } from 'lwc';

import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import GetInvoiceDetails from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.getNotOpenInvoiceFromAccount";
import getInvoiceData from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.getInvoiceData";
import saveROADetailRecords from "@salesforce/apex/SBR_3_0_MakeADepositController.insertROADetailRecords";
import createTransactionRecord from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansactionFromAccount";
import callROAPaymentAPI from "@salesforce/apex/SBR_3_0_API_CreateROAPayments.createRoaPayment";
import updateROADetailRecords from "@salesforce/apex/SBR_3_0_MakeADepositController.updateROADetailRecords";

import { publish, MessageContext } from 'lightning/messageService';
import sbr_3_0_ROA_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_roaTableRefresh__c';


/* Import other labels as needed */
import ChangeDue from '@salesforce/label/c.SBR_3_0_ChangeDue';
import CheckNumber from '@salesforce/label/c.SBR_3_0_Check_Number';
import Terminal from '@salesforce/label/c.SBR_3_0_Terminal';
import CashReceived from '@salesforce/label/c.SBR_3_0_Cash_Received';
import PaymentMethod from '@salesforce/label/c.SBR_3_0_Payment_Method';
import invoiceLabel from '@salesforce/label/c.SBR_3_0_InvoiceInputField';
import header from '@salesforce/label/c.SBR_3_0_UncollectedPaymentHeader';
import LumpSumLabel from '@salesforce/label/c.SBR_3_0_LumpSumPayment';
import MutipleInvoiceLabel from '@salesforce/label/c.SBR_3_0_MutipleInvoices';
import InvoiceAmountQues from '@salesforce/label/c.SBR_3_0_InvoiceAmountQuestion';
import TotalROAPaymentAmount from '@salesforce/label/c.SBR_3_0_TotalROAPaymentAmount';
import ROASelectionMessage from '@salesforce/label/c.SBR_3_0_ROASelectionMessage';
import Invoices from '@salesforce/label/c.SBR_3_0_Invoices';
import OpenInvoiceMessage from '@salesforce/label/c.SBR_3_0_OpenInvoiceMessage';
import OpenInvoice from '@salesforce/label/c.SBR_3_0_Opennvoice';
import OpenInvoiceMob from '@salesforce/label/c.SBR_3_0_OpennvoiceMob';
import AddInvoiceNotInTable from '@salesforce/label/c.SBR_3_0_Add_Invoice_Not_In_Table';

/* Import schema fields */
import USER_ID from '@salesforce/user/Id';
import DEPARTMENT from '@salesforce/schema/User.Department';
import COUNTRYCODE from '@salesforce/schema/User.CountryCode';
import WYNNEUSERNAME from '@salesforce/schema/User.Wynne_User_Name__c';
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
import { getPaymentMethodDetails } from 'c/sbr_3_0_PaymentMethodSelection';
import { checkTerminalInSession, getTerminalDetails } from 'c/sbr_3_0_TerminalSelection';

export default class Sbr_3_0_makeROAPayment extends LightningElement {

    /* Defining labels */
    label = {
        PaymentMethod,
        CheckNumber,
        Terminal,
        CashReceived,
        ChangeDue,
        invoiceLabel,
        header,
        LumpSumLabel,
        MutipleInvoiceLabel,
        InvoiceAmountQues,
        TotalROAPaymentAmount,
        Invoices,
        ROASelectionMessage,
        OpenInvoiceMessage,
        OpenInvoice,
        AddInvoiceNotInTable
    };

    @wire(MessageContext)
    messageContext;
    @api recordId;
    @api sObjectName;
    invoicePaidInFull;
    invoiceWrittenOff;
    invoiceNumber;
    sequenceNumber;
    @api invoiceData = [];
    @api invoiceOrCommentEntered;
    @track sequenceNumberEntered;
    @track noOpenInvoice = false;
    @track IsValid = false;
    onNextSuccess;
    isMobile = false;
    /* Define other tracked properties and APIs */
    @track paymentProcessing = false;
    @api isROAProcessing = false;
    @api isPaymentCash = false;
    @api isCashChangeDue= false;
    @api isTerminalVisible = false;
    @api paymentAmountValue;
    @track error;
    @track department;
    @track wynneUserName ;
    @track countrycode;
    @api paymentOptionSelected = '--None--';
    @api terminalValue = '--None--';
    @track amountCollected;
    @track moneyAppliedToInvoice = 0.00;
    @track showRadioGroup = true;
    @api value = 'option1';
    //invoiceData = [];
    draftValues = [];
    @track selectedRows = [];
    @api invoiceInfoArray = [];
    hasZeroPaymentAmount = false;
    @track invoiceAmount;
    @track errorMessage = '';
    @track rec = {
        paymentMethod: '',
        amountCollected: 0,
        terminal: '',
        cashReceived: 0,
        checkNumber: 0,
        changeDue: 0,
        invoiceOrComment: '',
        accountId: ''
    }
    @api cashDueValue;
    @api checkValue = '';
    @track paymentOptions = [];
    terminalOptions = [];
    @api isPaymentCheck = false;
    @api cashReceivedValue = 0;
    @api isFailedScreenBack = false;
    @track showPaymentModal;
    @track onLoadRender;
    @track showSpinner = true;
    isPaymentAmount = true;
    @track isInvoiceorComment = true;
    @api isInvoiceAmountQues = false;
    @api isTotalROAAmount = false;
    @api totalPaymentAmount = 0;
    @api totalPaymentAmountMobile = 0;
    @api message = '';
    textValue = 'success';
    @track totalPaymentAmountUI;
    finalEditedValue = 0;
    invoiceIds = [];
    @track invoiceId;
    @api isMultiplePaymentCheck = false;
    @api isMultiplePaymentCash = false;
    @track multipleCheckAmountChange = 0;
    @track totalROAPaymentAmount=0;
    sortByDueDateAsc = false;
    sortByDueDateDesc = false;
    @track editRecord = false;
    //FRONT-17104 START
    openFilterPanel = false;
    @api invoiceDataOnLoad = [];
    jobSiteFilterValue;
    branchFilterValue;
    fromDateFilterValue;
    untilDateFilterValue;
    balanceFilterValue;
    searchedInvoice;
    allInputTemplates;
    @api isMultipleInvoice = false;
    @track totalROAAmount = 0;
    @track totalROAAmountMobile = 0;
    @track keyIndex = 0;
    @track itemList = [];
    //FRONT-17104 END

    errorMessageAPI = '';
    transactionId;
    sessionId;
    paymentMethodRelatedData;
    roaDetailRelatedData;
    @api isInvoice;
    latestEditedValue;
    @track isRowAdded = false;

    //FRONT-27878
    isPaymantAmountChange = false;
    isInvoiceCommentChange = false;
    isMultiInvoiceRecievedAmt = false;
    modeOfPaymentMap = {}; //this map is used to store the key value pair of payment method and mode of payment.
    isApiCallComplete = false;

    //FRONT-17104 START
    get allInvoiceData() {
        if (this.isEmpty(this.invoiceInfoArray)) {
            return this.invoiceDataOnLoad;
        } else {
            let mappedInvoiceInfoData = this.invoiceDataOnLoad.map(invoice => {
                const info = this.invoiceInfoArray.find(({ invoiceId }) => invoiceId === invoice.Id);
                if (info) invoice.Total_invoice_Amount__c = info.editedValue.toLocaleString('en-US', { style: 'currency', currency: 'USD' });
                return invoice;
            });
            return mappedInvoiceInfoData;
        }
    }
    set allInvoiceData(value) {
        this.$allInvoiceData = value;
    }
    @track $allInvoiceData;

    /* Filter Invoice records */
    get filterCount(){
        const count =  [this.jobSiteFilterValue, this.branchFilterValue, (this.fromDateFilterValue || this.untilDateFilterValue), this.balanceFilterValue].filter(e=> e).length;
        this.applyFilterIconStyle(count);
        return count == 0 ? '' : count; 
    }

    /* Filter Icon Styling */
    applyFilterIconStyle(count){
        const STYLE = document.createElement("style");
        if(count > 0){
            STYLE.innerText = ` .slds-button__icon{
                fill: darkgreen;
            }`;
            
        }else{
            STYLE.innerText = ` .slds-button__icon{
                fill: gray;
            }`;
        }
        this.template.querySelector('.filterClass')?.appendChild(STYLE);
    }

    //FRONT-17104 END
    /* Initialize connectedCallback */
    async connectedCallback() {
        this.onLoadRender = true;
        this.showPaymentModal = true;
        this.fetchInvoiceData();
        this.totalPaymentAmountUI =  this.formatValueWithCurrencySign(this.totalPaymentAmount);
        this.cashDueValue = this.isFailedScreenBack ? this.formatValueWithCurrencySign(this.cashDueValue) : this.formatValueWithCurrencySign(this.cashReceivedValue);
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        this.isROAProcessing = true;
        this.OpenInvoiceLabel1 = OpenInvoiceMob.split('split')[0];
        this.OpenInvoiceLabel2 = OpenInvoiceMob.split('split')[1];
        [this.sessionId, this.terminalValue] = Object.values(await checkTerminalInSession());
        console.log('from failed', [this.paymentOptionSelected, this.isPaymentCash, this.isMultiplePaymentCash, this.totalPaymentAmount, this.isMultiplePaymentCheck]);
        this.isPaymentAmount = this.isInvoiceorComment = this.isFailedScreenBack ? this.value == 'option1' : true;
    }

    /* Render respective templates */
    render() {
        if (this.isMobile === true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    //FRONT-17104 START
    handleFilterClick() {
        this.openFilterPanel = !this.openFilterPanel;
    }

    /* Handle Filtering based on user inputs */
    handleFilterFieldChange() {
        this.jobSiteFilterValue = this.template.querySelector('[data-id="jobsiteFilter"]')?.value;
        this.branchFilterValue = this.template.querySelector('[data-id="branchFilter"]')?.value;
        this.fromDateFilterValue = this.template.querySelector('[data-id="fromDateFilter"]')?.value;
        this.untilDateFilterValue = this.template.querySelector('[data-id="untilDateFilter"]')?.value;
        this.balanceFilterValue = this.template.querySelector('[data-id="balanceFilter"]')?.value;
    }

    handleBranchValidation(event) {
        const branchValidity = this.template.querySelector('[data-id="branchFilter"]');
        const regex = /^[0-9]+$/;
        if(!regex.test(this.branchFilterValue) && this.branchFilterValue){
            branchValidity.setCustomValidity("Only Numeric value allowed.");
        }else{
            branchValidity.setCustomValidity("");
        }
        branchValidity.reportValidity();
    }

    handleJobSiteValidation() {
        const jobSiteValidity = this.template.querySelector('[data-id="jobsiteFilter"]');
        const regex = /^[a-zA-Z0-9]+$/;
        if (!regex.test(this.jobSiteFilterValue) && this.jobSiteFilterValue) {
            jobSiteValidity.setCustomValidity("Job Site Should be an alphanumeric input field.");
        } else {
            jobSiteValidity.setCustomValidity("");
        }
        jobSiteValidity.reportValidity();
    }

    /* Resets Invoice table */
    handleResetFilter() {
        this.jobSiteFilterValue = this.branchFilterValue = this.fromDateFilterValue = this.untilDateFilterValue = this.balanceFilterValue = '';
        this.invoiceData = Object.values(Object.fromEntries([...this.invoiceDataOnLoad, ...this.invoiceData].map(e => ([e.Id, e]))));
        this.removeFieldValidations();
    }

    removeFieldValidations() {
        const jobSiteValidity = this.template.querySelector('[data-id="jobsiteFilter"]');
        jobSiteValidity.setCustomValidity("");
        jobSiteValidity.reportValidity();
        const branchValidity = this.template.querySelector('[data-id="branchFilter"]');
        branchValidity.setCustomValidity("");
        branchValidity.reportValidity();
    }

    handleFilterApply() {
        const [jobsiteValue = '', branchValue = '', fromDateValue = '', untilDateValue = '', balanceValue = ''] =
            [this.jobSiteFilterValue, this.branchFilterValue, this.fromDateFilterValue, this.untilDateFilterValue, this.balanceFilterValue]

        this.openFilterPanel = !this.openFilterPanel;
        this.invoiceData = this.allInvoiceData.filter(item => {
            return (
                (jobsiteValue === '' || (item.Job_Site_Location__c || '').includes(jobsiteValue)) &&
                (branchValue === '' || (item.Profit_Center__c || '').includes(branchValue)) &&
                (fromDateValue === '' || (item.Due_Date__c || '') >= fromDateValue) &&
                (untilDateValue === '' || (item.Due_Date__c || '') <= untilDateValue) &&
                (balanceValue === '' || parseFloat((item.Amount_Due__c || '').replace('$', '').replace(',', '')) === parseFloat(balanceValue))
            );
        });
    }

    handleSearchChange(event) {
        const invoiceSearched = event.detail.value;
        this.invoiceData = this.allInvoiceData.filter(e => {
            const invoiceNum = [e.Invoice_number__c, e.Invoice_Sequence_Number__c].join('-');
            return invoiceNum.includes(invoiceSearched);
        })
    }
 
    isEmpty(obj) {
        return typeof obj === 'object' ? (!obj || !Object.keys(obj).length) : !obj;
    }
    //FRONT-17104 END

    get areAllRowsSelected() {
        return this.invoiceData.every(row => row.checked);

    }

    handleCheckboxChangeMobile(event) {
        const selectedRow = event.target.value;
        const isChecked = event.target.checked;
        var counter = 0;
        var invoiceDataTemp = this.invoiceData;
        invoiceDataTemp.forEach(row => {          
            if (row.Id === selectedRow) {
                row.checked = isChecked;

                var totalInvoice 

                if(isChecked){
                    row.Total_invoice_Amount__c = row.Total_invoice_Amount__c.replace(/[\$,]/g, '') > 0 ?  row.Total_invoice_Amount__c.replace(/[\$,]/g, '') : row.Amount_Due__c;
                    totalInvoice = row.Total_invoice_Amount__c.replace(/[\$,]/g, '');
                    totalInvoice = parseFloat(totalInvoice);
                    this.rec.invoiceOrComment = (row.Invoice_Sequence_Number__c !== '' ? row.Invoice_Sequence_Number__c + '-' : '') + (row.Invoice_number__c !== '' ? row.Invoice_number__c : '');
                    counter++;
                   if(!((totalInvoice)>0)){                    
                        row.errorMessage = 'Enter an amount for all selected invoices';
                        row.highlightRow = 'hightlightRowCss';
                    }else {
                        row.errorMessageExist = false;
                        row.errorMessage = '';
                        row.highlightRow = '';
                        if(!row.invoiceAmountAdded){
                         //   this.totalROAAmountMobile =  parseFloat(this.totalROAAmountMobile) + totalInvoice;
                         //   this.totalPaymentAmountUI = this.formatValueWithCurrencySign(this.totalROAAmountMobile);
                            row.invoiceAmountAdded = true;
                        }                        
                    }
                    if(counter > 20){
                       row.errorMessage = 'You may only pay upto 20 invoices at a time.';
                    }
                } else{
                    totalInvoice = row.Total_invoice_Amount__c.replace(/[\$,]/g, ''); 
                    row.Total_invoice_Amount__c = `$0`;
                    row.errorMessageExist = false;
                    row.errorMessage = '';
                    row.highlightRow = '';
                    row.invoiceAmountAdded = false;
                   // this.totalPaymentAmount =  parseFloat(this.totalPaymentAmount) - totalInvoice;
                   // this.totalPaymentAmountUI = this.formatValueWithCurrencySign(this.totalPaymentAmount);
                    if(totalInvoice > 0){
                        row.errorMessage = 'Select all invoices with a payment greater than $0.';
                    }
                }
            }                             
        });       
        this.invoiceData = invoiceDataTemp;
        this.invoiceCalculationMobile();
        this.displayErrorMessage();
    }

    invoiceCalculationMobile(){
        let totalInvoice = 0;
        let invoiceValues ;
        this.invoiceData.forEach(row => {
            if (row.checked) {
                invoiceValues = row.Total_invoice_Amount__c.replace(/[\$,]/g, '');
                totalInvoice += parseFloat(invoiceValues);
            }
        });
        
        this.totalROAAmountMobile = this.totalPaymentAmount = totalInvoice;
        this.rec.amountCollected = parseFloat(this.totalROAAmountMobile);
        this.totalPaymentAmountUI = this.formatValueWithCurrencySign(this.totalROAAmountMobile);
        
    }

    /* Validate and throw error messages when required */
    displayErrorMessage(){
        var errorMessageExists = false;
        
        if(this.invoiceData.some(record => record?.errorMessage == 'Enter an amount for all selected invoices')){ 
            this.errorMessage = 'Enter an amount for all selected invoices';
            errorMessageExists = true;
        }else if(this.invoiceData.some(record => record?.errorMessage == 'You may only pay upto 20 invoices at a time.')){
            this.errorMessage = 'You may only pay upto 20 invoices at a time.';
            errorMessageExists = true;
        }else if(this.invoiceData.some(record => record?.errorMessage == 'Select all invoices with a payment greater than $0.')){
            this.errorMessage = 'Select all invoices with a payment greater than $0.';
            errorMessageExists = true;
        }

        if (errorMessageExists) {
            this.IsValid = false;
            return;
        } else {
            this.IsValid = true;
            this.errorMessage = '';
        }
        
    }

    /* Handle Header checkbox changes */
    handleHeaderCheckboxChange(event) {
        const isChecked = event.target.checked;  

        // Update the 'checked' property for all rows
        this.invoiceData = this.invoiceData.map(row => ({
            ...row,
            checked: isChecked          
        }));

        this.invoiceInfoArray = [];
        this.invoiceData.forEach(info => {
            info.Total_invoice_Amount__c = isChecked ? info.Amount_Due__c : `$0`;
            let numericValue= this.removeCurrencySign(info.Amount_Due__c);
            const editVal = isChecked ? numericValue : 0;

            const invoiceInfo = {
                isChecked: isChecked,
                editedValue: editVal,
                invoiceId: info.Id
            };
            this.invoiceInfoArray.push(invoiceInfo);
        });

        // Update the 'isChecked' property in the invoiceInfoArray based on the checkbox change
        this.invoiceInfoArray.forEach(info => {
            info.isChecked = isChecked;
        });
        this.calculateTotalROAPayment();
        this.multipleInvoiceValidation();
    }

    /* Calculate total ROA amount based on user inputs */
    calculateTotalROAPayment() {
        this.totalPaymentAmount = this.totalROAAmount = 0;
        this.invoiceInfoArray.forEach(info => {
            if (info.isChecked) {
                this.totalPaymentAmount += info.editedValue;
            }
        });
        this.itemList.map(info => {
            this.totalROAAmount += parseFloat(info.Amount); 
        })

        this.totalROAPaymentAmount= (this.totalPaymentAmount + this.totalROAAmount);
        if (this.isMultiplePaymentCheck === true) {
            this.multipleCheckAmountChange = this.totalROAPaymentAmount;
        }
        this.totalPaymentAmountUI = this.formatValueWithCurrencySign(this.totalPaymentAmount + this.totalROAAmount);
        this.rec.amountCollected = parseFloat(this.totalPaymentAmount) + parseFloat(this.totalROAAmount);
        this.checkInputValidity();
    }

    /* Handle Checkbox input change */
    handleCellEdit(event) {
        const editableCell = event.target;
        const editedValue = parseFloat(editableCell.textContent.trim());
        this.latestEditedValue = editableCell.textContent.trim();
        const editableCellContainer = editableCell.parentNode;

         // Assuming row.checked is a boolean variable indicating whether the checkbox is selected or not
        const rowId = editableCell.getAttribute('data-recid');
        const row = this.invoiceData.find(item => item.Id === rowId);
        const isChecked = row.checked; // Assuming `checked` property holds the checkbox state

        if (isChecked) {
            if (isNaN(editedValue) || editedValue <= 0) {
                editableCell.textContent = '';
                editableCellContainer.classList.add('error');

            } else {
                editableCellContainer.classList.remove('error');
                editableCellContainer.removeAttribute('data-error-message');
                editableCellContainer.classList.add('edited');
            }
        } else {
            // Ignore error condition if checkbox is not selected
            editableCellContainer.classList.remove('error');
            editableCellContainer.removeAttribute('data-error-message');
            editableCellContainer.classList.add('edited');

        }
        this.calculateTotalROAPayment();
    }

    /* Handle Payment amount change in Invoice table */
    handlePaymentAddition(event) {
        const editableCell = event.target;
        editableCell.textContent = this.latestEditedValue;
        let editedValue = parseFloat(editableCell.textContent.trim());
        if(isNaN(editedValue) || editedValue === null){
            editedValue =0;
        }
        const editableCellContainer = editableCell.parentNode;
        const row = editableCellContainer.parentNode;
        const spanElement = row.querySelector('.editable-cell');
        const currentInvoiceId = spanElement.getAttribute('data-recid');
        const rowIndex = this.invoiceIds.indexOf(currentInvoiceId);

        if (rowIndex !== -1 && editedValue !== null && !isNaN(editedValue)) {
            const checkbox = row.querySelector('input[type="checkbox"]');
            const isChecked = checkbox.checked;
            const invoiceInfo = {
                invoiceId: currentInvoiceId,
                isChecked: isChecked,
                editedValue: editedValue
            };
            this.hasZeroPaymentAmount = true;
            this.errorMessage = '';
            const existingEntryIndex = this.invoiceInfoArray.findIndex(entry => entry.invoiceId === currentInvoiceId);
            if (existingEntryIndex !== -1) {
                this.invoiceInfoArray[existingEntryIndex] = invoiceInfo;
            } else {
                this.invoiceInfoArray.push(invoiceInfo);
            }
            this.calculateTotalROAPayment();
            this.multipleInvoiceValidation();
            editableCell.textContent =this.formatValueWithCurrencySign(editedValue);
        }
    }

    /* Handle Inline record edit */
    handleEditRecord(event) {
        this.editedInvoiceRecord = event.detail.value;
        const { Invoice_number__c: invoiceNumber, Invoice_Sequence_Number__c: sequenceNumber, Total_invoice_Amount__c: invoiceAmount } = this.editedInvoiceRecord || {}
        const invoiceId = [invoiceNumber, sequenceNumber].join('-');
        this.editedInvoiceRecord = { ...this.editedInvoiceRecord, invoiceId };
        this.editedInvoiceAmount = invoiceAmount > 0 ? invoiceAmount : 0;
        var  totalInvoice = this.editedInvoiceRecord.Total_invoice_Amount__c.replace(/[\$,]/g, '');
        this.editedInvoiceRecord.Total_invoice_Amount__c = totalInvoice > 0 ? totalInvoice : 0;
        this.editRecord = true;
    }

    /* Handle form save */
    handleSave(event) {
        const invoiceId = this.editedInvoiceRecord?.invoiceId;
        const invoiceAmount = parseFloat(this.editedInvoiceAmount);
        this.invoiceData = this.invoiceData.map(e => {
            const recordInvoiceid = [e.Invoice_number__c, e.Invoice_Sequence_Number__c].join('-');
            if (recordInvoiceid == invoiceId) {
                // e.recordEdited = (e.Total_invoice_Amount__c != this.formatValueWithCurrencySign(invoiceAmount)) ? 'recordEditedCss': '';
                e.recordEdited ='recordEditedCss';
                e.Total_invoice_Amount__c = this.formatValueWithCurrencySign(invoiceAmount); 
                var  totalInvoice = e.Total_invoice_Amount__c.replace(/[\$,]/g, '');
                totalInvoice = parseFloat(totalInvoice);
                
                if(totalInvoice > 0 && (e.checked)){
                    e.errorMessageExist = false;
                    e.errorMessage = '';
                    e.highlightRow = '';
                    e.isPaymentAmountEdited = true;
                  
                 //   this.totalROAAmountMobile =  parseFloat(this.totalROAAmountMobile) + totalInvoice;
                 //   this.totalPaymentAmountUI = this.formatValueWithCurrencySign(this.totalROAAmountMobile);
                    e.invoiceAmountAdded = true;
                }else if(totalInvoice > 0 && !(e.checked)){
                    e.errorMessage = 'Select all invoices with a payment greater than $0.'
                    e.highlightCheckBox = 'highlightCheckBoxCss';
                }else if(totalInvoice == 0 && !(e.checked)){
                    e.errorMessage = ''
                }
            }
            return e;
        })
        this.invoiceCalculationMobile();
        this.displayErrorMessage();
        this.editRecord = false;
    }

    handleInvoiceAmountEdit(event) {
        let paymentAmountInput = this.template.querySelector(".paymentAmountClass");
        let paymentAmount =event.detail.value;
        if (paymentAmount <= 0) {
            paymentAmountInput.setCustomValidity("Payment amount must be greater than $0.");
        } else {
            paymentAmountInput.setCustomValidity('');
            this.editedInvoiceAmount = paymentAmount;
        }
        paymentAmountInput.reportValidity();
    }

    handleCloseEditRecord() {
        this.editRecord = false;
    }
   
    /* Handler when checkbox is checked/dechecked */
    handleCheckboxChange(event) {
        const checkboxId = event.target.value;
        const isChecked = event.target.checked;
        // Update the 'checked' property for the corresponding row
        this.invoiceData = this.invoiceData.map(row => {
            if (row.Id === checkboxId) {
                return { ...row, checked: isChecked };
            }
            return row;
        });

        // Find the index of checkboxId in the invoiceIds array
        const rowIndex = this.invoiceIds.indexOf(checkboxId);
        if (rowIndex !== -1) {
            // Use the invoiceId corresponding to the rowIndex
            const currentInvoiceId = this.invoiceIds[rowIndex];
            const invoiceData = this.invoiceData[rowIndex];
            const balance = this.invoiceData[rowIndex].Amount_Due__c;
            this.invoiceData[rowIndex].Total_invoice_Amount__c = isChecked ? this.invoiceData[rowIndex].Amount_Due__c : `$0.00`;
            // Update the 'isChecked' property in the invoiceInfoArray based on the checkbox change
            const existingEntryIndex = this.invoiceInfoArray.findIndex(entry => entry.invoiceId === currentInvoiceId);   
            if (existingEntryIndex !== -1) {
                this.invoiceInfoArray[existingEntryIndex].isChecked = isChecked;
                let numericValue= this.removeCurrencySign(balance);
                let existingValue = this.invoiceInfoArray[existingEntryIndex].editedValue;
                if(numericValue === existingValue){
                    existingValue=0;
                }else if(existingValue >0){
                    numericValue = existingValue ;
                }
                const editVal = isChecked ? numericValue : existingValue;
                this.invoiceInfoArray[existingEntryIndex].editedValue = editVal;       
            }  else {
                // If checkbox is checked and no entry exists in invoiceInfoArray, add a new entry with editedValue as 0
                let numericValue= this.removeCurrencySign(balance);
                const editVal = isChecked ? numericValue : 0;

                const invoiceInfo = {
                    invoiceId: currentInvoiceId,
                    isChecked: isChecked,
                    editedValue: editVal // Set editedValue to 0 if checked, otherwise null
                };
                this.invoiceInfoArray.push(invoiceInfo);
            }
        }
            this.calculateTotalROAPayment();
            this.multipleInvoiceValidation();
            const latestInvoiceNumber = this.invoiceData.length > 0 ? Math.max(...this.invoiceData.map(item => item.Invoice_Sequence_Number__c)) : '';
            const latestSequenceNumber = this.invoiceData.length > 0 ? Math.max(...this.invoiceData.map(item => item.Invoice_number__c)) : '';
            this.rec.invoiceOrComment = (latestSequenceNumber !== '' ? latestSequenceNumber + '-' : '') + (latestInvoiceNumber !== '' ? latestInvoiceNumber : '');
    }

    /* Handler for Invoice or Comment field */
    handleInvoiceorCommentChange(event) {
        this.invoiceOrCommentEntered = event.target.value;
        this.rec.invoiceOrComment = event.target.value;
        this.isInvoiceCommentChange = true;
        this.checkInputValidity();
    }

    /* Handler for payment failure */
    handlePaymentFailed(event) {
        this.paymentOptionSelected = event.detail.paymentmethod;
        this.handlePaymentMethod(event);
    }

    /* Handler for payment method change */
    handlePaymentMethod(event) {
        let paymentMethodValue;
        paymentMethodValue = this.rec.paymentMethod = event.target.value;
        this.paymentOptionSelected = event.target.value;
        this.checkComboboxValidity();
        if (this.modeOfPaymentMap[paymentMethodValue] === 'Cash') {
            this.isPaymentCash = true;
            this.isTerminalVisible = false;
            this.isCashChangeDue = true;
            this.isMultiplePaymentCheck = false;
            if (this.isTotalROAAmount) {
                this.isMultiplePaymentCash = true;
                this.isPaymentCash = false;
            }
            else {
                this.isMultiplePaymentCash = false;
            }
            this.isPaymentCheck = false;
            this.rec.amountCollected = parseFloat(this.paymentAmountValue);
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] === 'Check') {
            this.isPaymentCash = false;
            this.isTerminalVisible = false;
            this.isPaymentCheck = true;
            this.isMultiplePaymentCash = false;
            this.isCashChangeDue = false;
            if (this.isTotalROAAmount) {
                this.isMultiplePaymentCheck = true;
            }
            else {
                this.isMultiplePaymentCheck = false;
            }
            this.rec.amountCollected = parseFloat(this.paymentAmountValue);
        }
        else if (this.modeOfPaymentMap[paymentMethodValue] == 'Cards') {
            this.isPaymentCash = false;
            this.isMultiplePaymentCheck = false;
            this.isMultiplePaymentCash = false;
            this.isCashChangeDue = false;
            this.isTerminalVisible = true;
            this.isPaymentCheck = false;
            this.rec.amountCollected = parseFloat(this.paymentAmountValue);
        }
    }

    get isOption1Checked() {
        return this.value === 'option1';
    }

    get isOption2Checked() {
        return this.value === 'option2';
    }

    /* Handle radio button change */
    handleRadioChange(event) {
        this.value = event.target.value;
        if (this.value == 'option2') {
            this.isTerminalVisible = false;
            this.paymentOptionSelected = '--None--';
            this.isPaymentAmount = false;
            this.isInvoiceorComment = false;
            this.isInvoiceAmountQues = true;
            this.isMultiplePaymentCheck = false;
            this.isMultiplePaymentCash = false;
            this.isCashChangeDue = false;
            this.isPaymentCash = false;
            this.isPaymentCheck = false;
            this.isTotalROAAmount = true;
            this.isInvoice = true;
            this.sortByDueDateAsc = true;
            this.cashReceivedValue = 0;
            this.cashDueValue = this.formatValueWithCurrencySign(this.cashReceivedValue);
            this.isMultipleInvoice = true;
            this.terminalValue = localStorage.getItem(this.sessionId) || '--None--';
        } else if (this.value == 'option1') {
            this.isMultipleInvoice = false;
            this.isTerminalVisible = false;
            this.paymentOptionSelected = '--None--';
            this.isPaymentAmount = true;
            this.isInvoiceorComment = true;
            this.isInvoiceAmountQues = false;
            this.isTotalROAAmount = false;
            this.isMultiplePaymentCheck = false;
            this.isMultiplePaymentCash = false;
            this.isCashChangeDue = false;
            this.isPaymentCash = false;
            this.isPaymentCheck = false;
            this.isInvoice = false;
            this.cashReceivedValue = 0;
            this.cashDueValue = this.formatValueWithCurrencySign(this.cashReceivedValue);
            this.terminalValue = localStorage.getItem(this.sessionId) || '--None--';
        }
    }

    // Format the cashValue with currency sign
    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    removeCurrencySign(formattedValue) {
        const numericString = formattedValue.replace(/[^\d.]/g, '');
        return parseFloat(numericString);
    }

    /* Wire method to fetch user details */
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [DEPARTMENT, COUNTRYCODE,WYNNEUSERNAME]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
            this.showSpinner = false;
        } else if (data) {
            this.department = data.fields.Department.value;
            this.countrycode = data.fields.CountryCode.value;
            this.wynneUserName = data.fields.Wynne_User_Name__c.value;
            this.getPaymentAndterminalDetails();
        }
    }

    /* Wire method to fetch open Invoice*/
    async getOpenInvoices() {
        await GetInvoiceDetails({ accountId: this.recordId })
            .then(result => {
                console.log('result', result);
                if (result.length === 0) {
                    this.noOpenInvoice = true;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    // Fetch Payment record details from server side
    fetchInvoiceData() {
        getInvoiceData({ accountId: this.recordId })
            .then(data => {
                if (data) {
                    this.invoiceIds = data.map(item => item.Id);
                    this.invoiceData = this.isFailedScreenBack ? this.invoiceData : data.map(item => ({
                        ...item,
                        Amount_Due__c: !isNaN(item.Amount_Due__c) ? this.formatValueWithCurrencySign(item.Amount_Due__c) : this.formatValueWithCurrencySign(0),
                        Total_invoice_Amount__c: !isNaN(item.Total_invoice_Amount__c) ? this.formatValueWithCurrencySign(item.Total_invoice_Amount__c) : this.formatValueWithCurrencySign(0)
                    }));
                    this.allInvoiceData = this.invoiceDataOnLoad = this.invoiceData;
                    if (this.isFailedScreenBack) {
                        this.invoiceData = this.invoiceData.map(e => {
                            const matchedInvoice = this.invoiceInfoArray.find(({ invoiceId }) => invoiceId === e.Id);
                            return { ...e, Total_invoice_Amount__c: matchedInvoice?.editedValue || e.Total_invoice_Amount__c }
                        });
                    }
                    console.log('invoiceData ',this.invoiceData);
                } else {
                    console.error('No invoice data received.');
                }
            })
            .catch(error => {
                console.error('Error fetching invoice data:', error);
            });
    }

    handleChange(event) {
        let totalROA = 0;
        if (event.target.name === 'comment') {
            this.itemList[event.currentTarget.dataset.index].Comment = this.rec.invoiceOrComment = event.target.value;
        }
        else if (event.target.name === 'amount') {
            this.itemList[event.currentTarget.dataset.index].Amount = event.target.value;
            this.calculateTotalROAPayment();
        }
        this.isRowAdded = this.itemList.some(item => parseFloat(item.Amount) > 0);
    }

    /* Add new Invoice data which is not in table*/
    handleAddRow() {
        this.hasZeroPaymentAmount = true;
        this.errorMessage = '';
        let objRow = {
            Comment: '',
            Amount: '',
            id: ++this.keyIndex
        }
        this.itemList = [...this.itemList, Object.create(objRow)];
        this.isRowAdded = true; 
    }

    /* onclick remove the selected row */
    handleRemoveRow(event) {
        let totalROA = 0;
        this.itemList = this.itemList.filter((ele) => {
            return parseInt(ele.id) !== parseInt(event.currentTarget.dataset.index);
        });
        this.itemList.forEach(data => {
            totalROA = parseFloat(data.Amount) + totalROA;
        })
        this.totalROAAmount = totalROA;
        this.calculateTotalROAPayment();
        this.isRowAdded = this.itemList.some(item => parseFloat(item.Amount) > 0);
    }

    /* Sort Due Date Header */
    handleSortByDueDate() {
        // Toggle sorting direction when Due Date header is clicked
        this.sortByDueDateAsc = !this.sortByDueDateAsc;
        this.sortByDueDateDesc = !this.sortByDueDateAsc;

        // Implement sorting logic based on Due Date
        if (this.sortByDueDateAsc) {
            this.invoiceData.sort((a, b) => new Date(a.Due_Date__c) - new Date(b.Due_Date__c));
        } else {
            this.invoiceData.sort((a, b) => new Date(b.Due_Date__c) - new Date(a.Due_Date__c));
        }
    }


    /* Retrieve payment and terminal details */
    async getPaymentAndterminalDetails() {
       const[,paymentMethodDetails,terminalOptions] = await Promise.all([this.getOpenInvoices(), getPaymentMethodDetails(), getTerminalDetails(this.department)]).finally(() => {
            this.showSpinner = false;
        }) //FRONT-17121
        this.terminalOptions = terminalOptions;
        ({paymentOptions: this.paymentOptions, paymentMethodMap: this.modeOfPaymentMap} = paymentMethodDetails || {});
    }

    /* Handle amount change */
    handleAmountChange(event) {
        this.paymentAmountValue = parseFloat(event.target.value);
        this.rec.amountCollected = parseFloat(this.paymentAmountValue);
        this.isPaymantAmountChange = true;
        this.checkInputValidity();
    }

    /* Handle cash change */
    handleCashChange(event) {
        this.cashReceivedValue = isNaN(parseFloat(event.target.value).toFixed(2)) ? 0 : parseFloat(event.target.value).toFixed(2);
        this.cashDueValue = undefined;
        this.checkInputValidity();
    }

    /* Handle check change */
    handleCheckChange(event) {
        this.checkValue = event.target.value;
        if (this.isMultiplePaymentCheck === true) {
            this.multipleCheckAmountChange = this.totalROAPaymentAmount;
        }
        this.checkInputValidity();
    }

    /* Handle terminal selection */
    handleTerminal(event) {
        this.terminalValue = event.target.value;
        localStorage.setItem(this.sessionId,  this.terminalValue);
        this.checkComboboxValidity();
    }

    /* Handle Check Amount Change */
    handleCheckAmountChange(event) {
        this.multipleCheckAmountChange = event.target.value;
        this.checkInputValidity();

    }

    /* Check input validity */
    checkInputValidity() {
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                if ((inputField.id).includes("depid") && this.isPaymantAmountChange ) {
                    let depositAmountCmp = this.template.querySelector(".paymentAmountClass");
                    if (!isNaN(this.paymentAmountValue) && (this.paymentAmountValue > 0 && this.paymentAmountValue <= 100000) && (this.paymentAmountValue !== "")) {
                        depositAmountCmp.setCustomValidity("");
                        if (this.modeOfPaymentMap[this.paymentOptionSelected] === 'Cash') {
                            let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                            if ((parseFloat(this.cashReceivedValue) > 0 && parseFloat(this.cashReceivedValue) <= 1000000)) {
                                if ((this.paymentAmountValue !== "" && this.cashReceivedValue === "")) {
                                    this.IsValid = false;
                                    cashReceivedCmp.setCustomValidity("Enter cash received");
                                } else if (this.paymentAmountValue !== "" && !(parseFloat(this.paymentAmountValue) <= parseFloat(this.cashReceivedValue))) {
                                    this.IsValid = false;
                                    this.cashDueValue = undefined;
                                    cashReceivedCmp.setCustomValidity("Cash Received must be greater or equal to payment amount.");
                                } else if ((parseFloat(this.cashReceivedValue) <= 1000000) && (parseFloat(this.cashReceivedValue) > 0)) {
                                    this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                                    this.cashDueValue = parseFloat(this.cashReceivedValue - this.paymentAmountValue).toFixed(2);
                                    this.rec.changeDue = this.cashDueValue;
                                    this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                                    cashReceivedCmp.setCustomValidity("");
                                }
                                cashReceivedCmp.reportValidity();
                            }
                        }
                    } else if (this.paymentAmountValue === "" || isNaN(this.paymentAmountValue)) {
                        this.IsValid = false;
                        depositAmountCmp.setCustomValidity("Enter payment amount");
                    } else if (this.paymentAmountValue <= 0) {
                        this.IsValid = false;
                        this.cashDueValue = undefined;
                        depositAmountCmp.setCustomValidity("Payment amount must be greater than $0.");
                    }
                    depositAmountCmp.reportValidity();
                } else if ((inputField.id).includes("cashid") && this.isPaymentCash == true) {
                    let cashReceivedCmp = this.template.querySelector(".cashReceivedClass");
                    if (!isNaN(this.cashReceivedValue) && (parseFloat(this.cashReceivedValue) >= parseFloat(this.paymentAmountValue)) && (this.cashReceivedValue !== "") && (parseFloat(this.cashReceivedValue) <= 1000000) && (parseFloat(this.cashReceivedValue) >= 0)) {
                        this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                        this.cashDueValue = parseFloat(this.cashReceivedValue - this.paymentAmountValue).toFixed(2);
                        this.rec.changeDue = this.cashDueValue;
                        this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                        cashReceivedCmp.setCustomValidity("");
                    } else if (this.cashReceivedValue === "" || isNaN(this.cashReceivedValue)) {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Enter cash received");
                    } else if (this.cashReceivedValue <= 0 || this.cashReceivedValue >= 1000000) {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Cash Received must be greater than $0 and less than $100,000.");
                    } else {
                        this.IsValid = false;
                        cashReceivedCmp.setCustomValidity("Cash Received must be greater and equal to payment amount.");
                    }
                    cashReceivedCmp.reportValidity();
                } else if ((inputField.id).includes("CheckId") && this.isPaymentCheck == true) {
                    let checkCmp = this.template.querySelector(".checkClass");
                    let regExp = /^0*$/g;
                    let regExpSpecial = /[`~!@#$%^&*()\-+={}[\]:;"'<>,.?\/|\\]/;

                    if (this.checkValue === "" || this.checkValue === undefined) {
                        this.IsValid = false;
                        checkCmp.setCustomValidity("Enter check number");
                    } else if (regExp.test(this.checkValue) || regExpSpecial.test(this.checkValue) || Math.sign(this.checkValue) === -1 || this.checkValue.trim() === "") {
                        this.IsValid = false;
                        checkCmp.setCustomValidity("Please specify valid check number");
                    } else {
                        checkCmp.setCustomValidity("");
                        this.rec.checkNumber = this.checkValue;
                    }
                    checkCmp.reportValidity();
                } else if ((inputField.id).includes("commentid") && this.isInvoiceCommentChange) {
                    let invoiceOrCommentCmp = this.template.querySelector(".invoiceorcomment");
                    if (this.invoiceOrCommentEntered === "" || this.invoiceOrCommentEntered === undefined) {
                        this.IsValid = false;
                        invoiceOrCommentCmp.setCustomValidity("Enter invoice # or comment");
                    } else {
                        invoiceOrCommentCmp.setCustomValidity("");
                        this.rec.invoiceOrComment = this.invoiceOrCommentEntered;
                    }
                    invoiceOrCommentCmp.reportValidity();
                } else if ((inputField.id).includes("multipleCheck")) {
                    let MultipleCheckCmp = this.template.querySelector(".CheckPaymentAmount");
                    if (parseFloat(this.multipleCheckAmountChange) !== parseFloat(this.totalROAPaymentAmount)) {
                        this.IsValid = false;
                        MultipleCheckCmp.setCustomValidity("Total check amount must match total ROA payment amount.");
                    }
                    else {
                        MultipleCheckCmp.setCustomValidity("");
                    }
                    MultipleCheckCmp.reportValidity();
                }
                else if ((inputField.id).includes("multipleCash")) {
                    let MultipleCashCmp = this.template.querySelector(".CashPaymentAmount");
                    if (parseFloat(this.cashReceivedValue) < parseFloat(this.totalPaymentAmount)  ) {
                        this.IsValid = false;
                        MultipleCashCmp.setCustomValidity("Cash Received cannot be less than the total roa payment amount.");
                        this.cashDueValue = parseFloat(this.cashReceivedValue - (this.totalPaymentAmount + this.totalROAAmount)).toFixed(2);
                        this.cashDueValue = this.cashDueValue > 0 ? this.formatValueWithCurrencySign(this.cashDueValue) : undefined;
                    }
                    else if(this.isMultiInvoiceRecievedAmt && parseFloat(this.cashReceivedValue) < parseFloat(this.totalROAAmount) ){
                        this.IsValid = false;
                        MultipleCashCmp.setCustomValidity("Cash Received cannot be less than the total roa payment amount.");
                        this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                        this.cashDueValue = parseFloat(this.cashReceivedValue - (this.totalPaymentAmount + this.totalROAAmount)).toFixed(2);
                        this.rec.changeDue = this.cashDueValue;
                        this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                    } else {
                        MultipleCashCmp.setCustomValidity("");
                        this.rec.cashReceived = parseFloat(this.cashReceivedValue);
                        this.cashDueValue = parseFloat(this.cashReceivedValue -  (this.totalPaymentAmount + this.totalROAAmount)).toFixed(2);
                        this.rec.changeDue = this.cashDueValue;
                        this.cashDueValue = this.formatValueWithCurrencySign(this.cashDueValue);
                    }
                    MultipleCashCmp.reportValidity();
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
                        paymentCmp.setCustomValidity("Select payment method");
                    } else {
                        paymentCmp.setCustomValidity("");
                        this.rec.paymentMethod = this.paymentOptionSelected;
                    }
                    paymentCmp.reportValidity();
                } else if ((input_Field_Reference.id).includes("terminalId") && this.isTerminalVisible == true) {
                    let terminalCmp = this.template.querySelector(".terminalClass");
                    if (!(this.terminalValue) || (this.terminalValue == "") || this.terminalValue === '--None--') {
                        this.IsValid = false;
                        terminalCmp.setCustomValidity("Terminal is mandatory for card payments.");
                        this.terminalValue = "";
                    } else {
                        this.rec.terminal = this.terminalValue;
                        terminalCmp.setCustomValidity("");
                    }
                    terminalCmp.reportValidity();
                }
            }, true);
    }

    /* Close modal */
    closeModal() {
        this.editRecord = false;
        const message = {
            closeModal: true
        };
        publish(this.messageContext, CLOSE_MODAL, { payload: message });

        this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
    }

    /* Rendered callback to adjust modal style */
    renderedCallback() {
        if (!this.isMobile) {
            const STYLE = document.createElement("style");
            STYLE.innerText = ` .uiModal--horizontalForm .modal-container{
                max-width: 47rem;
            }`;
            this.template.querySelector('.roa-payment-container').appendChild(STYLE);

            const hideSearchLabel = document.createElement("style");
            hideSearchLabel.innerText = `.custom-medium-input label{
                display: none;
            }`;
            this.template.querySelector('.roa-payment-container').appendChild(hideSearchLabel);

            const hideQuickActionCross = document.createElement("style");
            hideQuickActionCross.innerText = `.slds-button_icon-bare{
                content-visibility :hidden;
                visibility: collapse;
            }`;
            this.template.querySelector('.roa-payment-container').appendChild(hideQuickActionCross);

            if (this.isInvoice) { //FRONT-17104 START
                    const changeBorder = document.createElement("style");
                    changeBorder.innerText = `.slds-button_icon-border{
                    border-color : white;
                }`;
                    this.template.querySelector('.filterClass')?.appendChild(changeBorder);

                    const changeFilterIconSize = document.createElement("style");
                    changeFilterIconSize.innerText = `.slds-button__icon{
                    width : 1.3rem;
                }`;
                    this.template.querySelector('.filterClass')?.appendChild(changeFilterIconSize);
            }//FRONT-17104 END
        } else {
            const changeInputBoxSize = document.createElement("style");
            changeInputBoxSize.innerText = `.slds-input {
                    min-height : 2px;
                    line-height : 2.2;
                }`;
            this.template.querySelector('.changeBoxSize')?.appendChild(changeInputBoxSize);
        }
    }

    /* Validation check for mutiple invoices */
    multipleInvoiceValidation() {
        let anyChecked = false;
        let errorMessage = '';


        // Iterate through the invoiceData to check for selected checkboxes
        this.invoiceData.forEach(item => {
            if (item.checked) {
                anyChecked = true;

                // Find the corresponding invoice info in the invoiceInfoArray
                const invoiceInfo = this.invoiceInfoArray.find(info => info.invoiceId === item.Id);

                const editableCell = this.template.querySelector(`td[data-recid="${item.Id}"]`);
                editableCell.classList.remove('error-cell');

                const fauxCheckbox = this.template.querySelector(`input[name="selectedRow"][value="${item.Id}"] + .slds-checkbox_faux`);
                if (fauxCheckbox) {
                    fauxCheckbox.classList.remove('error-checkbox');
                }

                // Check if the payment amount is available for the selected invoice
                if (!invoiceInfo || !invoiceInfo.editedValue || invoiceInfo.editedValue <= 0) {
                    errorMessage = 'Enter an amount for all selected invoices';
                    const editableCell = this.template.querySelector(`td[data-recid="${item.Id}"]`);
                    editableCell.classList.add('error-cell');

                } else {
                    const editableCell = this.template.querySelector(`td[data-recid="${item.Id}"]`);
                    editableCell.classList.remove('error-cell');
                }
            } else {
                // Check if payment amount is entered without selecting the checkbox
                const invoiceInfo = this.invoiceInfoArray.find(info => info.invoiceId === item.Id);

                const editableCell = this.template.querySelector(`td[data-recid="${item.Id}"]`);
                editableCell.classList.remove('error-cell');

                const fauxCheckbox = this.template.querySelector(`input[name="selectedRow"][value="${item.Id}"] + .slds-checkbox_faux`);
                if (fauxCheckbox) {
                    fauxCheckbox.classList.remove('error-checkbox');
                }

                if (invoiceInfo && invoiceInfo.editedValue && invoiceInfo.editedValue > 0) {
                    errorMessage = 'Select all invoices with a payment amount greater than $0.00.';
                    // Select the faux checkbox span element corresponding to the item
                    const fauxCheckbox = this.template.querySelector(`input[name="selectedRow"][value="${item.Id}"] + .slds-checkbox_faux`);
                    if (fauxCheckbox) {
                        // Add the error-checkbox class to apply the CSS styling
                        fauxCheckbox.classList.add('error-checkbox');
                    }

                } else {
                    const fauxCheckbox = this.template.querySelector(`input[name="selectedRow"][value="${item.Id}"] + .slds-checkbox_faux`);
                    if (fauxCheckbox) {
                        // Remove the error-checkbox class to remove the CSS styling
                        fauxCheckbox.classList.remove('error-checkbox');
                    }
                }
            }
        });

        // Handle the case when no checkboxes are selected
        if (!anyChecked) {
            errorMessage = 'Select all invoices with a payment amount greater than $0.00.';
        }

        // If there's an error message, set the appropriate flags and display the error
        if (errorMessage) {
            this.hasZeroPaymentAmount = true;
            this.IsValid = false;
            this.errorMessage = errorMessage;
            return;
        } else {
            this.hasZeroPaymentAmount = false;
            this.IsValid = true;
            this.errorMessage = '';
        }

    }

    /* Handle form submission */
    async handleSubmit() {
        this.isPaymantAmountChange = true;
        this.isInvoiceCommentChange = true;
        this.isMultiInvoiceRecievedAmt = true;

        if (this.value === 'option2') {
            this.IsValid = true;
            if(!this.isMobile){
                this.checkInputValidity();
                this.checkComboboxValidity();
                            this.template.querySelectorAll('lightning-input').forEach(element => {
                    this.itemList.forEach(data => {
                        if(data.Amount === '' || data.Comment === ''){
                            this.IsValid = false;
                        }
                    })
                    element.reportValidity();
                });
                if (this.IsValid && !this.isRowAdded) {                
                    this.multipleInvoiceValidation();
                }
            }

            if(this.isMobile){
                if (!this.isRowAdded){
                this.displayErrorMessage();                
                }
                this.checkInputValidity();
                this.checkComboboxValidity();
                this.template.querySelectorAll('lightning-input').forEach(element => {
                    this.itemList.forEach(data => {
                        if (data.Amount === '' || data.Comment === '') {
                            this.IsValid = false;
                        }
                    })
                    element.reportValidity();
                });

                this.invoiceData.forEach(row => { 
                    var  totalInvoice = row.Total_invoice_Amount__c.replace(/[\$,]/g, '');
                    totalInvoice = parseFloat(totalInvoice);
                    
                    if(!(this.invoiceData.some(record => (record?.checked == true)))){ 
                        this.errorMessage = 'Select all invoices with a payment greater than $0.';
                        this.IsValid = false;
                    }                    
                });
            }
        } else {
            this.IsValid = true;
            this.checkInputValidity();
            this.checkComboboxValidity();
        }
        if (this.IsValid) {
            if(this.isMobile){
                this.invoiceDataPushMobile();
            }       
            this.rec.accountId = this.recordId;
           await this.makeROAPaymentAPICall();               
        }
    }

    /* API call to Mulesoft-RM */
    async makeROAPaymentAPICall() {
 
        try {
            console.log('this.itemList',this.itemList)
            let invoiceInfoArrayAPI = [];
            if (this.value == 'option1') {
                invoiceInfoArrayAPI = [this.rec].map(({ amountCollected, invoiceOrComment }) => ({ paymentAmount: amountCollected, comment: invoiceOrComment }));
            } else {
                invoiceInfoArrayAPI = this.invoiceInfoArray.map(invoice => {
                    const { Invoice_number__c, Invoice_Sequence_Number__c } = this.invoiceData.find(({ Id }) => Id === invoice.invoiceId);
                    const comment = `${Invoice_number__c}-${Invoice_Sequence_Number__c}`;
                    return { paymentAmount: invoice.editedValue, comment };
                });
                let invoiceAddedValues  = this.itemList.map(({ Amount, Comment }) => ({ paymentAmount: parseFloat(Amount), comment: Comment })) || []
                invoiceInfoArrayAPI = [...invoiceInfoArrayAPI, ...invoiceAddedValues]
            }
            let roaRecordIds=[];
            this.paymentProcessing = true;
            [roaRecordIds, this.transactionId] = await Promise.all([saveROADetailRecords({ roaDetailRecords: JSON.stringify(invoiceInfoArrayAPI), accountId: this.recordId }),
                                                        createTransactionRecord({ accountRecordId: this.recordId, paymentDepositData: JSON.stringify(this.rec) })]);
            this.paymentMethodRelatedData = { value : this.value, isTerminalVisible : this.isTerminalVisible, wynneUserName : this.wynneUserName };
            this.roaDetailRelatedData = {
                roaRecordWithIds: roaRecordIds, isMultipleInvoice: this.isMultipleInvoice, isMultiplePaymentCash: this.isMultiplePaymentCash,
                isInvoiceorComment: this.isInvoiceorComment, isMultiplePaymentCheck: this.isMultiplePaymentCheck, isInvoiceAmountQues: this.isInvoiceAmountQues,
                isTotalROAAmount: this.isTotalROAAmount, isInvoice: this.isInvoice, invoiceData: this.invoiceData, isCashChangeDue: this.isCashChangeDue,
                invoiceOrCommentEntered: this.invoiceOrCommentEntered, isPaymentAmount: this.isPaymentAmount, invoiceInfoArray : this.invoiceInfoArray,
                totalPaymentAmount: this.totalPaymentAmount
            }
          
            const apiCallResponse = await callROAPaymentAPI({ accountRecordId: this.recordId, 
                paymentDepositData: JSON.stringify(this.rec), transactionId: this.transactionId, 
                paymentRecords : JSON.stringify(roaRecordIds), 
                wynneUserName: this.wynneUserName
            });
            const { data, sourceTransactionId } = apiCallResponse || {};
            const { referenceNo, message } = data || {};
            const isCashOrCheck = ['Cash','Check'].includes(this.modeOfPaymentMap[this.paymentOptionSelected])
            const isTransactionValid = isCashOrCheck && sourceTransactionId;
            const asyncSuccessMessage = 'ROA request is accepted for further processing';
            if (isTransactionValid || message == asyncSuccessMessage) {
                if (isTransactionValid) {
                    await this.updateTransactionRecord(sourceTransactionId, roaRecordIds);
                }
            } else {
                this.closeModal();
            }
        } catch (error) {
            console.error('erorr in makeROAPaymentAPICall',error);
            this.errorMessageAPI = error?.body?.message || error?.body || error;
        }finally{
            this.isApiCallComplete = true;
        }
    }
    
    invoiceDataPushMobile(){
        let invoiceValues =0;
        this.invoiceData.forEach(invoice => {
            if (invoice.checked) {
                invoiceValues = invoice.Total_invoice_Amount__c.replace(/[\$,]/g, '');
                const invoiceInfo = {
                    invoiceId: invoice.Id,
                    isChecked: invoice.checked,
                    editedValue: invoiceValues
                };
                this.invoiceInfoArray.push(invoiceInfo);
            }
        });
    }
 

    /* Update transaction record fields */
    async updateTransactionRecord(sourceTransactionId, roaRecordIds) {
        const fields = {
            Id: this.transactionId,
            RM_Detail_Sequence_Number__c: sourceTransactionId
        };
        const recordInput = { fields };

        await updateRecord(recordInput).catch(error => {
            console.error('error in updating record', error);
            this.errorMessageAPI = error?.body?.message || error?.body || error;
        });
        updateROADetailRecords({ detailSeqNumber: sourceTransactionId, roaRecords: JSON.stringify(roaRecordIds) }).catch(error => {
            console.error('updateROADetailRecords', error);
            this.errorMessageAPI = error?.body?.message || error?.body || error;
        });
        const message = {
            messageToSend: 'success',
            sourceSystem: "From Comp : MakeADeposit"
        };
        publish(this.messageContext, sbr_3_0_ROA_Table_Refresh, message);
    }
}