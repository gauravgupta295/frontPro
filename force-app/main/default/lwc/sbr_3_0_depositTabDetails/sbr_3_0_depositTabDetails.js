/* Importing necessary modules and dependencies */
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import fetchTotalDeposit from "@salesforce/apex/SBR_3_0_MakeADepositController.getDeposit";
import getPaymentData from '@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentData';

/* Importing messaging related modules */
import { subscribe, MessageContext } from 'lightning/messageService';
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';

/* Import schema fields */
import TotalAmount from '@salesforce/schema/Order.Total_Rental_Amount__c';
import InvoiceAmount from '@salesforce/schema/Order.Total_Invoiced_Amount__c';

/* Import other labels as needed */
import TotalAmt from '@salesforce/label/c.SBR_3_0_TotalAmount';
import Totals from '@salesforce/label/c.SBR_3_0_Totals';
import DepositPaid from '@salesforce/label/c.SBR_3_0_Deposit_Paid';
import AdditionalDepositDue from '@salesforce/label/c.SBR_3_0_Additional_Deposit_Due';
import NoRecordsAvailable from '@salesforce/label/c.SBR_3_0_NoRecordsAvailable';
import Payments from '@salesforce/label/c.SBR_3_0_Payments';


import DefaultTemplate from "./sbr_3_0_depositTabDetails.html";
import mobileTemplate from "./sbr_3_0_depositTabDetailsMobileTemplate.html";

/* Initialize class */
export default class Sbr_3_0_depositTabDetails extends LightningElement {

    /* Defining labels */
    label = {
        TotalAmt,
        NoRecordsAvailable,
        Totals,
        AdditionalDepositDue,
        Payments,
        DepositPaid
    };

    /* Define other tracked properties and APIs */
    @track totalAmount = '0.00';
    @track depositAmount = '0.00';
    @track depositAmountUI ='0.00';
    @api dueDeposit='0.00';
    @api dueDepositUI ='0.00';
    @track InvoiceAmount = '0.00';
    @track totalAmountUI ='$0.00';
    @api recordId;
    @track fromDate;
    @track untilDate;
    @track paymentData;
    @track sortBy;
    @track sortDirection;
    @track errorMessage = false;
    @track wiredResultData;
    @track maxFromDate;
    @track maxDate;
    @track minUntilDate;
    @track maxUntilDate;
    @wire(MessageContext)
    messageContext;
    subscription = null;
    isMobile = false;
    tranid='N/A';
    authorization='N/A';

    // Data Tables columns
    columns = [

        {
            label: 'Payment ID', fieldName: 'eventUrl', type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'name'
                },
                target: '_self',
            }, sortable: "true"
        },
        { label: 'Tran ID', fieldName: 'tran', type: 'text', sortable: "true" },
        { label: 'Date', fieldName: 'date', type: 'text', sortable: "true" },
        { label: 'Type', fieldName: 'type', type: 'text', sortable: "true" },
        { label: 'Amount', fieldName: 'depositAmount', type: 'currency', sortable: "true" },
        { label: 'Tran Type', fieldName: 'tranType', type: 'text', sortable: "true" },
        { label: 'Authorization #', fieldName: 'authorization', type: 'text', sortable: "true" }

    ]

    /* Initialize connectedCallback */
    connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        const today = new Date();

        this.setMaxDate();
        this.fetchPaymentData();
        this.subscribeToMessageChannel();
    }

    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    setMaxDate() {
        const today = new Date();
        const year = today.getFullYear();
        let month = today.getMonth() + 1;
        let day = today.getDate();

        // Add leading zeros if month/day is single digit
        if (month < 10) {
            month = '0' + month;
        }
        if (day < 10) {
            day = '0' + day;
        }

        // Set maxDate to today's date in the required format (YYYY-MM-DD)
        this.maxFromDate = year + '-' + month + '-' + day;
        this.maxDate=this.maxFromDate;
    }


    // fetch Total estimated cost from Order record
    @wire(getRecord, { recordId: '$recordId', fields: [TotalAmount, InvoiceAmount] })
    totalAmount({ error, data }) {
        if (data) {
            if (getFieldValue(data, TotalAmount) != null){
                this.totalAmount = getFieldValue(data, TotalAmount).toFixed(2);
                this.totalAmountUI = this.formatValueWithCurrencySign(this.totalAmount);
            }
            if (getFieldValue(data, InvoiceAmount) != null){
                this.InvoiceAmount = getFieldValue(data, InvoiceAmount).toFixed(2);
            }
            setTimeout(() => {
                this.getTotalDeposit();
            }, 300);
        }
        else if (error) {
            console.error(error);
        }
    }

    // Fetch Total deposit amount for a particular order and also calculate due deposit
    getTotalDeposit() {
        fetchTotalDeposit({ orderId: this.recordId })
            .then(data => {
                if(data != null || !isNaN(data)){
                    this.depositAmount = (data.toFixed(2) - this.InvoiceAmount).toFixed(2);
                    if(this.depositAmount >0){
                        this.depositAmountUI = -(this.depositAmount); 
                    }else{
                        this.depositAmountUI = this.depositAmount; 
                    }
                    this.depositAmountUI = this.formatValueWithCurrencySign(this.depositAmountUI);
                   
                }else{
                    this.depositAmount ='0.00';
                    this.depositAmountUI = '$0.00';
                }
                    this.dueDeposit = ((this.totalAmount) - (this.depositAmount)).toFixed(2);
                    this.dueDepositUI = this.formatValueWithCurrencySign(this.dueDeposit);
                    if (this.dueDeposit < 0 ) {
                        this.dueDeposit = '0.00';
                        this.dueDepositUI = '$0.00';
                    }
                    if (this.depositAmount  < 0){
                        this.depositAmount = '0.00';
                        this.depositAmountUI = '$0.00';
                    }
            }).catch(error => {
                console.log('error', error);
            })
    }

    // Format the cashValue with currency sign
    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            sbr_3_0_Payment_Table_Refresh,
            (message) => this.handleMessage(message)
        );
    }


    handleMessage(message) {
        this.getTotalDeposit();
        this.fetchPaymentData();
    }


    handleDateChange(event) {
        const dateType = event.target.name;
        const selectedDate = event.target.value;

        if (dateType === 'fromDate') {
            this.fromDate = selectedDate;
        } else if (dateType === 'untilDate') {
            this.untilDate = selectedDate;
        }
        if(this.untilDate !==null && this.maxDate >this.untilDate){
            this.maxDate=this.untilDate;
        }else{
            this.maxDate=this.maxFromDate;
        }
        const fromDate = new Date(this.fromDate);
        const untilDate = new Date(this.untilDate);
        const setUntilDate = new Date(fromDate);
        const Untilyear = setUntilDate.getFullYear();
        let Untilmonth = setUntilDate.getMonth() + 1;
        let Untilday = setUntilDate.getDate();
        if (Untilmonth < 10) {
            Untilmonth = '0' + Untilmonth;
        }
        if (Untilday < 10) {
            Untilday = '0' + Untilday;
        }
        this.minUntilDate = Untilyear + '-' + Untilmonth + '-' + Untilday;

        const today = new Date();
        const year = today.getFullYear();
        let month = today.getMonth() + 1;
        let day = today.getDate();

        // Add leading zeros if month/day is single digit
        if (month < 10) {
            month = '0' + month;
        }
        if (day < 10) {
            day = '0' + day;
        }
       
        // Set maxDate to today's date in the required format (YYYY-MM-DD)
        this.maxUntilDate = year + '-' + month + '-' + day;
        if ((this.untilDate !== null && this.fromDate <= this.maxDate && this.fromDate <= this.untilDate) &&
            (this.fromDate !== null && this.untilDate <= this.maxFromDate && this.untilDate >= this.fromDate)) {
            this.fetchPaymentData();
        }

    }

 

    // Fetch Payment record details from server side
    fetchPaymentData() {
        getPaymentData({ orderId: this.recordId })
            .then(data => {
                // Filter the data based on the selected date range
                const filteredData = data.filter(payment => {
                    this.errorMessage = false;
                    const paymentDate = new Date(payment.Date__c);
                    const fromDate = this.fromDate ? new Date(this.fromDate) : null;
                    const untilDate = this.untilDate ? new Date(this.untilDate) : null;

                    // Check if the payment date is within the selected range
                    return (!fromDate || paymentDate >= fromDate) && (!untilDate || paymentDate <= untilDate);
                });

                if (filteredData) {
                    let baseUrl = 'https://' + location.host + '/'
                    let currentData = []
                    filteredData.forEach(row => {
                        let rowData = {}

                        rowData.eventUrl = baseUrl + row.Id
                        rowData.name = row.Name
                        rowData.type = row.Type__c
                        rowData.depositAmount = row.Deposit_Amount__c
                        rowData.tranType = row.Tran_Type__c

                        if(rowData.type.includes('Cash Currency')||rowData.type.includes('Check')){
                            rowData.tran=this.tranid;
                            rowData.authorization=this.authorization;
                        }
                        else{
                            rowData.tran = row.Tran__c;
                            rowData.authorization = row.Authorization__c
                        }
                        let date = new Date(row.Date__c);
                        let month = date.getMonth() + 1;
                        let day = date.getDate();
                        let year = date.getFullYear();

                        // Format the components as mm/dd/yyyy
                        let formattedDate = month + '/' + day + '/' + year;
                        rowData.date = formattedDate
                        console.log('formattedDate',formattedDate);

                        currentData.push(rowData)
                    })
                    this.paymentData = currentData
                }
                if (this.paymentData.length === 0) {
                    this.errorMessage = true;
                }
            })
            .catch(error => {
                console.error('Error fetching payment data: ', error);
            });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    // Sort data based on ASC/DESC based on the inputs
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.paymentData));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.paymentData = parseData;
    }
}