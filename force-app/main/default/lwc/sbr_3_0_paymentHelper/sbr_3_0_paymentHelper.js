/**
     ** This component is used as a helper to all payment related operations.
     * @author Kavita
*/

import { LightningElement } from 'lwc';
import callROAPaymentAPI from "@salesforce/apex/SBR_3_0_API_CreateROAPayments.createRoaPayment";
import createTansactionFromAccount from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansactionFromAccount";
import { updateRecord } from 'lightning/uiRecordApi';
import updateROADetailRecords from "@salesforce/apex/SBR_3_0_MakeADepositController.updateROADetailRecords";
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
import { MessageContext, publish } from 'lightning/messageService';
import sbr_3_0_ROA_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_roaTableRefresh__c';


export async function makeRoaAPICall() {
    try {
        const { roaRecordWithIds } = this.roaDetailRelatedData || {};
       const apiCallResponse = await callROAPaymentAPI({ accountRecordId: this.recidN, paymentDepositData: JSON.stringify(this.recordDetails), transactionId: this.transactionId, paymentRecords: JSON.stringify(roaRecordWithIds), wynneUserName: this.wynneUserName });
       const { data, sourceTransactionId } = apiCallResponse || {};
        const { referenceNo, message } = data || {};
        const isCashOrCheck = ['Cash Currency', 'Check'].includes(this.paymentMethodPassed);
        const isTransactionValid = isCashOrCheck && sourceTransactionId;
        const asyncSuccessMessage = 'ROA request is accepted for further processing';
        if (isTransactionValid || message == asyncSuccessMessage) {
            if (isTransactionValid) {
                updateTransactionRecord.call(this,sourceTransactionId, roaRecordWithIds);
            }
        } else {
            this.closeModal();
        }
    } catch (error) {
        console.error('error in roa api call',error);
        this.errorMessage = error?.body?.message || error?.body || error;
    }finally{
        this.isApiCallComplete = true;
    }
}

export async function updateTransactionRecord(sourceTransactionId, roaRecordIds) {
    console.log('sourceTransactionId ', [sourceTransactionId,this.transactionId])
    const fields = {
        Id: this.transactionId,
        RM_Detail_Sequence_Number__c: sourceTransactionId
    };
    const recordInput = { fields };

    updateRecord(recordInput).then(result => {
        this.errorMessage = '';
        const message = {
            messageToSend: 'success',
            sourceSystem: "From Comp : MakeADeposit"
        };
        publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
        publish(this.messageContext, sbr_3_0_ROA_Table_Refresh, message);
    }).catch(error => {
        console.error('Error updating transaction record:', error);
        this.errorMessage = error?.body?.message || error?.body || error;
    });
    if (this.isFromRoaScreen) {
        updateROADetailRecords({ detailSeqNumber: sourceTransactionId, roaRecords: JSON.stringify(roaRecordIds) }).catch(error => {
            console.error('updateROADetailRecords', error);
            this.errorMessage = error?.body?.message || error?.body || error;
        });
    }
}