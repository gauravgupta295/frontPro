import { LightningElement,api,wire,track} from 'lwc';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import DefaultTemplate from "./sbr_3_0_roaPaymentDetailsDisplay.html";
import mobileTemplate from "./sbr_3_0_roaPaymentDetailsDisplayMobileTemplate.html";

/* Import schema fields */

import ACCOUNT from '@salesforce/schema/Payments__c.Account__r.Name';
import TYPE from '@salesforce/schema/Payments__c.Type__c';
import LOCATION from '@salesforce/schema/Payments__c.CreatedBy.Branch__c';
import AMOUNT from '@salesforce/schema/Payments__c.Deposit_Amount__c';
import USERFIRSTNAME from '@salesforce/schema/Payments__c.CreatedBy.FirstName';
import USERLASTNAME from '@salesforce/schema/Payments__c.CreatedBy.LastName';
import DATE from '@salesforce/schema/Payments__c.Date__c';
import CREATEDDATE from '@salesforce/schema/Payments__c.CreatedDate';
import COMMENT from '@salesforce/schema/Payments__c.Invoice_or_Comment__c';
import NAME from '@salesforce/schema/Payments__c.Name';
import ORDERNAME from '@salesforce/schema/Payments__c.Order__r.Name';
import TRANTYPE from '@salesforce/schema/Payments__c.Tran_Type__c';
import TRANID from '@salesforce/schema/Payments__c.Tran__c';
import AUTHORIZATIONNUMBER from '@salesforce/schema/Payments__c.Authorization__c';

import getROADetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getROADetailRecords";
import { getPaymentMethodDetails } from 'c/sbr_3_0_PaymentMethodSelection';

export default class Sbr_3_0_roaPaymentDetailsDisplay extends LightningElement {

@api recordId;
@api account;
@api type;
@api location;
get amount(){
    return this.$amount;
}
set amount(value){
    const paymentAmount = value.replace(/,/g, '');
    this.$amount = this.formatValueWithCurrencySign(paymentAmount)
}
@api $amount = '$0.00';
@api user;
@api date;
@api time;
@api comment;
@api Name;
@api ordername;
@track error;
isMobile = false;
@api currentrecordid;    

@track IsFromOrder;
@track IsFromAccount;
@track TranType = '';
@track TranId = '';
@track Authorization = '';
showPaymentData = false;
roaDetailsArray = [];
modeOfPaymentMap = {};


async connectedCallback(){
    this.currentrecordid = this.recordId;
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
}

getROADetailsRecord(){
    getROADetails({paymentId : this.currentrecordid}).then(result => {
        this.roaDetailsArray = result.map(e=>{
            const paymentAmount = parseFloat(e.Payment_Amount__c).toFixed(2);
            return {InvoiceOrComment : e.Invoice_or_Comment__c, amount : this.formatValueWithCurrencySign(paymentAmount)}
        })
    })
}

async setTranIdAuthorization(){
    ({ paymentMethodMap: this.modeOfPaymentMap } = await getPaymentMethodDetails() || {});
    if(this.modeOfPaymentMap[this.type.split('****')?.[0]?.trim()] != 'Cards'){ 
        this.TranId = this.Authorization = 'N/A';
    }
}

render() {
    if(this.comment){
        this.IsFromAccount = true;
        this.IsFromOrder = false;
    }else{
        this.IsFromOrder = true;
        this.IsFromAccount = false;
    }
    if (this.isMobile === true) {
        return mobileTemplate;
    } else {
        return DefaultTemplate;
    }
}

@wire(getRecord, {
    recordId: "$currentrecordid",
    fields: [AMOUNT,TYPE,NAME,DATE,COMMENT,ACCOUNT,CREATEDDATE,LOCATION,USERLASTNAME,USERFIRSTNAME,ORDERNAME,TRANTYPE,TRANID,AUTHORIZATIONNUMBER]    
}) wirepayment({
    error,
    data
}) {
    if (error) {
        this.error = error;
    } else if (data) {
        let amountLoc = data.fields.Deposit_Amount__c.displayValue;
        this.amount = amountLoc.split(" ")[1];
        this.type = data.fields.Type__c.value;
        this.Name = data.fields.Name.value;
        this.ordername = data.fields.Order__r?.value?.fields?.Name?.value;
        this.date = data.fields.Date__c.value.split("-")[1]+'/' + data.fields.Date__c.value.split("-")[2] + '/' + data.fields.Date__c.value.split("-")[0];
        this.comment = data.fields.Invoice_or_Comment__c.value;
        this.account = data.fields.Account__r.displayValue; 
        var uctTime = data.fields.CreatedDate.value;
        var localDate = new Date(uctTime);
        this.time = localDate.toString().split(" ")[4];
        this.location = data.fields.CreatedBy.value.fields.Branch__c.value;
        this.user = data.fields.CreatedBy.value.fields.FirstName.value?.charAt(0) +  data.fields.CreatedBy.value.fields.LastName.value;
        this.TranId = data.fields.Tran__c.value;
        this.TranType = data.fields.Tran_Type__c.value;
        this.Authorization = data.fields.Authorization__c.value;
        this.showPaymentData = true;   
        if(this.comment){
            this.getROADetailsRecord();
        }  
        this.setTranIdAuthorization();
    }
}

    formatValueWithCurrencySign(value) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(value);
    }
}