/* Importing necessary modules and dependencies */
import { LightningElement,api, track,wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getROAPaymentData from '@salesforce/apex/SBR_3_0_ROAPaymentController.getPayments';
import DefaultTemplate from "./sbr_3_0_roaPaymentsTabDetails.html";
import mobileTemplate from "./sbr_3_0_roaPaymentsTabDetailsMobileTemplate.html";

/* Import other labels as needed */
 import NoRecordsAvailable from '@salesforce/label/c.SBR_3_0_NoRecordsAvailable';
 import RoaPayments from '@salesforce/label/c.SBR_3_0_ROA_Payments';
 /* Importing messaging related modules */
import { subscribe, MessageContext } from 'lightning/messageService';
import sbr_3_0_ROA_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_roaTableRefresh__c';

/* Initialize class */
export default class Sbr_3_0_roaPaymentsTabDetails extends LightningElement {

    /* Defining labels */
    label = {
        NoRecordsAvailable,
        RoaPayments
    };

    /* Define other tracked properties and APIs */
    @api recordId;
    @track fromDate;
    @track untilDate;
    @track minUntilDate;
    @track maxFromDate;
    @track roaPaymentData;
    @track sortBy;
    @track sortDirection;
    @track errorMessage=false;
    @wire(MessageContext)
    messageContext;
    subscription = null;
    isMobile = false;
    

    // Data Tables columns
    columns = [

        {
            label: 'Payment ID', fieldName: 'eventUrl', type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'name'
                },
                target: '_self'
            }, sortable: "true"
        },
        { label: 'Type', fieldName: 'type', type: 'text', sortable: "true" },
        { label: 'Location', fieldName: 'location', type: 'text', sortable: "true" },
        { label: 'Amount', fieldName: 'depositAmount', type: 'currency', sortable: "true" },
        { label: 'User', fieldName: 'user', type: 'text', sortable: "true" },
        { label: 'Date', fieldName: 'date', type: 'text', sortable: "true" },
        { label: 'Time', fieldName: 'time', type: 'time', sortable: "true" }

    ]

    /* Initialize connectedCallback */
    connectedCallback(){
        this.subscribeToMessageChannel();
        this.setMaxDate();
        this.fetchROAPaymentData();        
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    }

    render() {
        if (this.isMobile === true) {
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
    }


    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        const fromDate = new Date(this.fromDate);
        const untilDate = new Date(this.untilDate);

        const today = new Date(fromDate);
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
        this.minUntilDate = year + '-' + month + '-' + day;

    }

    // Until Date Picker
    handleUntilDateChange(event) {
        this.untilDate = event.target.value;
        const untilDate = new Date(this.untilDate);
        const fromDate = new Date(this.fromDate);

        this.fetchROAPaymentData();
    }

    // Fetch ROA Payment record details from server side
    fetchROAPaymentData(){
        getROAPaymentData({accountId: this.recordId})
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
                    rowData.location = row.Location__c
                    rowData.depositAmount = Number.isInteger(row.Deposit_Amount__c) ? row.Deposit_Amount__c.toFixed(2): row.Deposit_Amount__c                                                          
                    rowData.user = row.User__c
                    rowData.date = row.Date__c.split("-")[1]+'/' + row.Date__c.split("-")[2] + '/' + row.Date__c.split("-")[0];                                      
                    rowData.time = this.formatTime(row.Time__c)
                    currentData.push(rowData)
                })
                this.roaPaymentData = currentData
            }
            if (this.roaPaymentData.length === 0) {
                this.errorMessage = true;
            }
        })
        .catch(error => {
            console.error('Error fetching payment data: ', error);
        });
    }

    formatTime(dateTimeString) {
        const date = new Date(dateTimeString);
        const hours = this.padZero(date.getHours());
        const minutes = this.padZero(date.getMinutes());
        const seconds = this.padZero(date.getSeconds());
        return `${hours}:${minutes}:${seconds}`;
    }

    padZero(value) {
        return value < 10 ? '0' + value : value;
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    // Sort data based on ASC/DESC based on the inputs
    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.roaPaymentData));
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
        this.roaPaymentData = parseData;
    }


    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            sbr_3_0_ROA_Table_Refresh,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        this.fetchROAPaymentData();
    }
}