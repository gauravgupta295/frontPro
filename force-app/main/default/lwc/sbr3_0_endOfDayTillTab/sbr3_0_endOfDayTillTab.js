import { LightningElement,track,api, wire } from 'lwc';
import getCashControlDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getCashControlDetails';
import getCashROAControlDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getCashROAControlDetails';
import getFilteredTillNewDepositDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getFilteredTillNewDepositDetails'; //FRONT-32190
import getotherLocationDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getotherLocationDetails';
import getcashInvoicesDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.getcashInvoicesDetails';
import totalBusinessDetails from '@salesforce/apex/Sbr_3_0_endOfDayTillController.totalBusinessDetails';

import { CurrentPageReference } from 'lightning/navigation';
import { columns, roaColumns, creditColumns, roaCreditcolumns, cashColumns, depositColumns, otherLocationColumns, 
    businessColumns, amountByCreditCardMap, amountsByCreditCard } from './endOfDayTableColumns.js'; //FRONT-32190
import { formatValueWithCurrencySign } from 'c/sbr_3_0_eodTillHelper';

export default class Sbr3_0_endOfDayTillTab extends LightningElement {
    @track isCashControlTab = true;
    @track isCashROAControlTab=false;
    @track cashDetails;
    @track cashROADetails;
    @track newDepositDetails;
    @track otherLocationDetails;
    @track totalBusinessDetailsData;
    @track cashInvoices;
    @track amountByCredit;
    @track amountByROACredit;
    @track visaTotal=0;
    @track amexTotal =0;
    @track checkTotal=0;
    @track cashTotal=0;
    @track subtotal=0;
    @track wynneUserName;
    @track sourceName;
    @track roaTotal=0;
    @track newDepositTotal = 0;
    @track invoiceAmountTotal = 0;
    @track appliedDepositTotal = 0;
    @track netReceivedTotal = 0;
    @track otherAmountTotal = 0;
    @track cashInvoiceAmountTotal=0;
    @track cashInvoiceAppliedDepositTotal=0;
    @track cashInvoiceOtherAmountTotal=0;
    @track cashInvoiceNetCashReceivedTotal=0;
    @track subtotalCreditCard = '$0.00'
    @track subtotalAutoDeposit = '$0.00'
    @track totalCreditCard= 0;
    @track totalAutoDeposit= '$0.00'
    @track roaSubtotalCreditCard = '$0.00'
    @track roaSubtotalAutoDeposit = '$0.00'
    @track totalROACreditCard= 0;
    @track totalROAAutoDeposit = '$0.00'

    //BusinessInvoiceTotal
    @track businessinvoiceAmounttotal= 0;
    @track businesssalesTaxtotal= 0;
    @track businessdamageWaivertotal = 0;
    @track businessdelivertotal = 0;
    @track businesssubTotaltotal =0;

    @api value;
    columns = columns;
    roaColumns=roaColumns;
    cashColumns=cashColumns;
    creditColumns = creditColumns;
    roaCreditcolumns = roaCreditcolumns;
    depositColumns =depositColumns;
    otherLocationColumns = otherLocationColumns;
    businessColumns=businessColumns;
    @wire(CurrentPageReference)
    pagereference;
    //FRONT-32190 START
    @api tillDetailId;
    @api amountsByCreditCard = {};
    @api getTillSummaryResponse;
    @api branchLocationNumber;
    @api branchCompanyId;
    @api selectedDate;
    cashControlTotals = {
        Visa: 0,  
        Amex : 0,  
        Cash_Currency: 0,  
        Check: 0,  
        Discover: 0,  
        Diners_Club : 0,  
        Mastercard	: 0, 
        other: 0 
    };
     cashControlFlags = {
        Visa: false,
        Amex: false,
        Cash_Currency: false,
        Check: false,
        Discover: false,
        Diners_Club: false,
        Mastercard: false,
    };
    //FRONT-32190 END

    connectedCallback() {
        this.loadCashControlDetails();
        this.loadCashROAControlDetails();
        this.loadTillNewDepositDetails(); //FRONT-32190
        this.loadotherLocationDetails();
        this.loadcashInvoicesDetails();
        this.loadtotalBusinessDetails();
        this.loadAmountsByCreditCardData(); //FRONT-32190
    }

    loadAmountsByCreditCardData(){
        const {totalCreditCard,totalROACreditCard,totalAutoDeposit,totalROAAutoDeposit} = this.amountsByCreditCard || {};
        this.totalCreditCard = formatValueWithCurrencySign(totalCreditCard);
        this.totalAutoDeposit = formatValueWithCurrencySign(totalROACreditCard);
        this.totalROACreditCard = formatValueWithCurrencySign(totalAutoDeposit);
        this.totalROAAutoDeposit = formatValueWithCurrencySign(totalROAAutoDeposit);

        this.amountByCredit = []
        this.amountByROACredit = []

        this.getTillSummaryResponse.creditCardDetails.forEach(({ creditCard, amount }) => {
            if (amountByCreditCardMap[creditCard]) {
                amountsByCreditCard[amountByCreditCardMap[creditCard]] += amount;
            }
        });

        this.amountByCredit = [
            {
                visa: formatValueWithCurrencySign(amountsByCreditCard.visa),
                masterCard: formatValueWithCurrencySign(amountsByCreditCard.masterCard),
                amex: formatValueWithCurrencySign(amountsByCreditCard.amex),
                dinersClub: formatValueWithCurrencySign(amountsByCreditCard.dinersClub),
                discover: formatValueWithCurrencySign(amountsByCreditCard.discover)
            }
        ];
        
         this.amountByROACredit = [
            {
                visaroa: formatValueWithCurrencySign(amountsByCreditCard.visaroa),
                masterCardroa: formatValueWithCurrencySign(amountsByCreditCard.masterCardroa),
                amexroa: formatValueWithCurrencySign(amountsByCreditCard.amexroa),
                dinersClubroa: formatValueWithCurrencySign(amountsByCreditCard.dinersClubroa),
                discoverroa: formatValueWithCurrencySign(amountsByCreditCard.discoverroa)
            }
        ];   
    }

    loadCashControlDetails() {
        getCashControlDetails({ tillDetailId: this.tillDetailId })
            .then(async result => {
                let currentData = []      
                result.forEach(row=>{
                    let rowData={}
                    rowData.invoice = row.Contract_Number__c+'-'+row.Detailed_Sequence_Number__c
                    rowData.type = row.Type__c
                    rowData.amount = row.Amount__c
					rowData.sr = row.SR__c
                    rowData.user = row.Wynne_User__c
					rowData.driverlicense = row.Drivers_License__c

                    const paymentMethod = row.Payment_Method__c.split(' ').join('_');
                    if (this.cashControlTotals.hasOwnProperty(paymentMethod)) {
                        this.cashControlTotals[paymentMethod] += row.Amount__c;
                        this.subtotal += row.Amount__c;
                        if (row.Amount__c > 0) {
                            this.cashControlFlags[paymentMethod] = true;
                        }
                    } else {
                        this.cashControlTotals.other += row.Amount__c;
                    }
					currentData.push(rowData)
                })
                this.cashDetails = currentData;
                console.log('cashControlTotals '[this.cashControlTotals,this.cashControlFlags]);
            })
            .catch(error => {
                console.log('result not found');
                this.error = error;
                this.cashDetails = undefined;
            });
    }

    loadCashROAControlDetails() {
        getCashROAControlDetails({ tillDetailId: this.tillDetailId })
            .then(result => {
                let currentData = []
                let roatotal=0;
                let visatotal = 0; // Initialize Visa total
                let amextotal = 0; // Initialize Amex total
                let dinertotal = 0;
                let discovertotal = 0;
                let mastercardtotal =0;
                let othertotal=0;
                result.forEach(row=>{
                    let rowData={}
                    rowData.paymentid = row.Payment_ID__c
                    rowData.type = row.Type__c
                    rowData.location = row.Location__c
					rowData.amount = row.Amount__c
                    rowData.user = row.Wynne_User__c
					rowData.invoiceorcomment = row.Invoice_or_Comment__c
                    roatotal +=row.Amount__c

                    if (row.Payment_Method__c === 'V') {
                        visatotal += row.Amount__c;
                    } else if (row.Payment_Method__c === 'A') {
                        amextotal += row.Amount__c;
                    } else if (row.Payment_Method__c === 'D') {
                        dinertotal += row.Amount__c;
                    } else if (row.Payment_Method__c === 'X') {
                        discovertotal += row.Amount__c;
                    } else if (row.Payment_Method__c === 'M') {
                        mastercardtotal += row.Amount__c;
                    } else {
                        othertotal +=row.Amount__c;
                    }

					currentData.push(rowData)
                })
                this.cashROADetails=currentData;
                this.roaTotal= formatValueWithCurrencySign(roatotal);
            })
            .catch(error => {
                console.log('result not found');
                this.error = error;
                this.cashROADetails = undefined;
            });
    }

    async loadTillNewDepositDetails() { //FRONT-32190
        try {
            const [newDepositData, additionalDepositData] = await Promise.all([
                getFilteredTillNewDepositDetails({ recordTypeName: 'New Deposit', tillDetailId: this.tillDetailId }),
                getFilteredTillNewDepositDetails({ recordTypeName: 'Additional Deposit', tillDetailId: this.tillDetailId })
            ]);
            const [newDepositObject, additionalDepositObject] = await Promise.all([
                this.assignTillNewDepositData(newDepositData, 'New Deposit'),
                this.assignTillNewDepositData(additionalDepositData, 'Additional Deposit')
            ]);

            this.newDepositDetails = newDepositObject?.currentData || {};
            this.newDepositTotal = formatValueWithCurrencySign(newDepositObject?.newDepositTotal);
        
            this.additionalDepositDetails = additionalDepositObject?.currentData || {};
            this.additionalDepositTotal = formatValueWithCurrencySign(additionalDepositObject?.newDepositTotal);
        
        } catch (error) {
            console.log('result not found loadTillNewDepositDetails', error);
            this.error = error;
        }
        
    }

    assignTillNewDepositData(result){ //FRONT-32190
        let currentData = []
        let newDepositTotal=0;
        result.forEach(row=>{
            let rowData={}
            rowData.contract = row.Contract_Number__c
            rowData.user = row.Wynne_User__c
            rowData.type = row.Type__c
            rowData.amount = row.Amount__c
            rowData.driversLicense = row.Drivers_License__c
            newDepositTotal+=row.Amount__c;
            currentData.push(rowData)
        })
        return {currentData,newDepositTotal}
    }

    loadotherLocationDetails() {
        getotherLocationDetails({ recordTypeName: 'InterCompany', tillDetailId: this.tillDetailId })
            .then(result => {
                let currentData = []
                let invoiceAmounttotal=0;
                let appliedDeposittotal=0;
                let netReceivedtotal=0;
                let otherAmounttotal=0;
                result.forEach(row=>{
                    let rowData={}
                    rowData.invoice = row.Invoice_Number__c
					rowData.location = row.Location__c
                    rowData.SR = row.SR__c
					rowData.invoiceAmount = row.Invoice_Amount__c
                    rowData.appliedDeposit = row.Applied_Deposit__c
					rowData.netReceived = row.Net_Cash_Received__c
					rowData.otherAmount = row.Other_Amount__c
                    invoiceAmounttotal += row.Invoice_Amount__c
                    appliedDeposittotal +=  row.Applied_Deposit__c
                    netReceivedtotal += row.Net_Cash_Received__c
                    otherAmounttotal += row.Other_Amount__c

					currentData.push(rowData)
                })
                this.otherLocationDetails=currentData;
                this.invoiceAmountTotal= formatValueWithCurrencySign(invoiceAmounttotal);
                this.appliedDepositTotal = formatValueWithCurrencySign(appliedDeposittotal);
                this.netReceivedTotal = formatValueWithCurrencySign(netReceivedtotal);
                this.otherAmountTotal = formatValueWithCurrencySign(otherAmounttotal);
            })
            .catch(error => {
                console.log('result not found');
                this.error = error;
                this.otherLocationDetails = undefined;
            });
    }

    loadcashInvoicesDetails() {
        getcashInvoicesDetails({ recordTypeName: 'Invoice', tillDetailId: this.tillDetailId })
            .then(result => {
                let currentData = []
                let cashInvoiceAmounttotal=0;
                let cashInvoiceAppliedDeposittotal=0;
                let cashInvoiceOtherAmounttotal=0;
                let cashInvoiceNetCashReceivedtotal=0;
                result.forEach(row=>{
                    let rowData={}
                    rowData.invoice = row.Invoice_Number__c
					rowData.user = row.Wynne_user__c
                    rowData.SR = row.SR__c
					rowData.invoiceAmount = row.Invoice_Amount__c
                    rowData.appliedDeposit = row.Applied_Deposit__c
					rowData.netCashReceived = row.Net_Cash_Received__c
					rowData.otherAmount = row.Other_Amount__c
                    cashInvoiceAmounttotal += row.Invoice_Amount__c
                    cashInvoiceAppliedDeposittotal +=  row.Applied_Deposit__c
                    cashInvoiceNetCashReceivedtotal += row.Net_Cash_Received__c
                    cashInvoiceOtherAmounttotal += row.Other_Amount__c
					currentData.push(rowData)
                })
                this.cashInvoices=currentData;
                this.cashInvoiceAmountTotal = formatValueWithCurrencySign(cashInvoiceAmounttotal);
                this.cashInvoiceAppliedDepositTotal = formatValueWithCurrencySign(cashInvoiceAppliedDeposittotal);
                this.cashInvoiceNetCashReceivedTotal = formatValueWithCurrencySign(cashInvoiceNetCashReceivedtotal);
                this.cashInvoiceOtherAmountTotal = formatValueWithCurrencySign(cashInvoiceOtherAmounttotal);
            })
            .catch(error => {
                console.log('result not found');
                this.error = error;
                this.cashInvoices = undefined;
            });
    }

    loadtotalBusinessDetails() {
        totalBusinessDetails({invoiceDate : this.selectedDate, companyCode : this.branchCompanyId, profitCenter : this.branchLocationNumber})
            .then(result => {
                let currentData = []
                let invoiceAmounttotal=0;
                let salesTaxtotal=0;
                let damageWaivertotal=0;
                let delivertotal=0;
                let subTotaltotal=0;

                result.forEach(row=>{
                    let rowData={}
                    rowData.invoice = [row.Invoice_number__c,row.Invoice_Sequence_Number__c].join('-')
					rowData.invoiceAmount = row.Total_invoice_Amount__c;
                    rowData.salesTax = row.Sales_Tax_Amount__c
					rowData.damageWaiver = row.Damage_Waiver__c
					rowData.deliver = row.Pickup_Amount__c
                    rowData.subTotal = row.Delivery_Amount__c
                    invoiceAmounttotal += row.Total_invoice_Amount__c
                    salesTaxtotal +=  row.Sales_Tax_Amount__c
                    damageWaivertotal += row.Damage_Waiver__c
                    delivertotal += row.Pickup_Amount__c
                    subTotaltotal += row.Delivery_Amount__c
					currentData.push(rowData)
                })
                this.totalBusinessDetailsData=currentData;
                this.businessinvoiceAmounttotal= formatValueWithCurrencySign(isNaN(invoiceAmounttotal) ? 0 : invoiceAmounttotal);
               this.businesssalesTaxtotal = formatValueWithCurrencySign(isNaN(salesTaxtotal) ? 0 : salesTaxtotal);
                this.businessdamageWaivertotal = formatValueWithCurrencySign(isNaN(damageWaivertotal) ? 0 : damageWaivertotal);
                this.businessdelivertotal = formatValueWithCurrencySign(isNaN(delivertotal) ? 0 : delivertotal);
                this.businesssubTotaltotal = formatValueWithCurrencySign(isNaN(subTotaltotal) ? 0 : subTotaltotal);
            })
            .catch(error => {
                console.log('result not found');
                this.error = error;
                this.totalBusinessDetailsData = undefined;
            });
    }
    
    handleTabChange(event) {
        if (event.detail.value === 'cashControl') {
            this.isCashControlTab = true;
            this.isCashROAControlTab = false;
        } else if(event.detail.value === 'cashROAControl'){
            this.isCashControlTab = false;
            this.isCashROAControlTab = true;
        }
    }
}