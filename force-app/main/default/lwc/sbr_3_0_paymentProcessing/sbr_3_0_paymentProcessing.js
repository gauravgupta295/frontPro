/* Importing necessary modules and dependencies */
import { LightningElement, track, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService'; //added for FRONT-23924

/* Import other labels as needed */
import PaymentProcess from '@salesforce/label/c.SBR_3_0_PaymentProcessing';
import DepositMessage from '@salesforce/label/c.SBR_3_0_PaymentDepositMessage';
import RefundProcess from '@salesforce/label/c.SBR_3_0_RefundProcess';
import RefundMessage from '@salesforce/label/c.SBR_3_0_RefundMessage';
import updateInvoice from "@salesforce/apex/SBR_3_0_MakeUncollectedPaymentController.updateInvoiceDetails";	

import DefaultTemplate from "./sbr_3_0_paymentProcessing.html";
import mobileTemplate from "./sbr_3_0_paymentProcessingMobileTemplate.html";
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c'; //added for FRONT-23924
import updateROADetailRecords from "@salesforce/apex/SBR_3_0_MakeADepositController.updateROADetailRecords";
import sbr_3_0_ROA_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_roaTableRefresh__c';
import getTransactionById from '@salesforce/apex/SBR_3_0_MakeADepositController.getTransactionById';


import { subscribe, unsubscribe } from 'lightning/empApi'; /* Added as part of FRONT-17208 */

/* Added as part of CometD Changes */
import { loadScript } from "lightning/platformResourceLoader";
import CometD from "@salesforce/resourceUrl/cometd_static_resource";
import fetchSessionId from '@salesforce/apex/SBR_3_0_MakeADepositController.fetchSessionId';

/* Initialize class */
export default class PaymentProcessing extends LightningElement {
    
/* Defining labels */
    label = {
        PaymentProcess,
        DepositMessage,
        RefundProcess,
        RefundMessage

    };

    /* Define other tracked properties and APIs */
    @track header = '';
    @track waitMessage = '';
    @track showButtons = true;
    @track success = false;
    @track processing = true;
    @track cancelmodal;
    @api paymentOptionSelected;
    @api error = false;
    @track failure = false;
    @api paymentMethod;
    @api depositAmount;
    @api terminalValue;
    @api recid;
    @api duedeposit;
    @api paymentprocessing = false;
    @api refundprocessing = false;
    @api uncollectedprocessing = false;
    @api roaprocessing = false;
    @api processadditionaldeposit = false;
    @api ispaymentProcessingSuccessful = false;
    @api isrefundProcessingSuccessful = false;
    @api isuncollectedProcessingSuccessful = false;
    @api isroaProcessingSuccessful = false;
    @api isrefundAdditionalDeposit = false;
    @api paymentMethodRelatedData;
    isMobile = false;
    @api isfromcancel = false;
    @api refundgiven;
    @track isrefundavailable;
    @track isrefundnotavailable;
    @api paymentMethodRelatedDataRefund;
    @api invoiceRelatedData;
    @api transactionId;
    subscription = null;/* Added as part of FRONT-17208 */
    channelName = '/data/Transaction__ChangeEvent';/* Added as part of FRONT-17208 */
    //added for FRONT-23924 START
    @api isFromCreateReservation = false;
    @api objectApiName;
    @api recordDetails;
    @api errorMessage;
    @api roaDetailRelatedData;
    @wire(MessageContext)
    messageContext;
    sessionId;
    cometDLib;
    //added for FRONT-23924 END
    @api isFromCreateReturn = false; //FRONT-15078
    @api noRefundGiven = false; //FRONT-15078
    @track $isApiCallComplete;
    @api
    get isApiCallComplete() {
        return this.$isApiCallComplete;
    }
    set isApiCallComplete(value) {
        this.$isApiCallComplete = value;
        if (value) {
            this.determinePaymentOutcome();
        }
    }

    /* 
   Handles the success scenario after an onclick event.
   Sets 'processing' to false and 'success' to true.
   */  
    @api handleOnclickSuccess() {
        this.processing = false;
        this.success = true;
    }
    
    /* 
   Handles the error scenario after an onclick event.
   Sets 'processing' to false and 'failure' to true.
    */
    @api handleOnclickError() {
        this.processing = false;
        this.failure = true;
    }






    connectedCallback() {
        this.isMobile = window.matchMedia("(max-width: 480px)").matches;
        console.log('isApiCallComplete  ',this.isApiCallComplete);





































            if (this.processadditionaldeposit == false) {
                this.isrefundavailable = false;
                this.isrefundnotavailable = true;
            } else {
                this.isrefundavailable = true;
                this.isrefundnotavailable = false;
            }
            
            if (this.isfromcancel) {
                this.cancelmodal = true;
            }else{
                this.cancelmodal = false;
            }
            this.handleProcessingLabel();
    }

    determinePaymentOutcome(){
        const isCardPayment = ['Cash Currency', 'Check', 'Pay on Return' ,'Uncollected'].includes(this.paymentMethod); 
        if (!isCardPayment) {
            console.log('connectedCallback processing 11 ',this.errorMessage)
            if (this.errorMessage) {
                setTimeout(() => {
                    this.failure = true;
                    this.processing = false;
                }, 10000);
            } else {
                this.isMobile ? this.startPolling() : this.subscribeToTransactionDataCapture(); // FRONT-17208
            }
        }else{
            console.log('connectedCallback processing ',this.errorMessage)
            setTimeout(() => {
                this.success = !this.errorMessage;
                this.failure = !!this.errorMessage;
                this.processing = false;
            }, 8000);
        }
    }

    startPolling() {
        this.pollInterval = setInterval(() => {
            this.pollCount++;
            if (this.pollCount > this.maxPollCount) {
                clearInterval(this.pollInterval);
            }
            this.checkTransactionStatus();
        }, 3000);

        setTimeout(() => {
            const message = { //added for FRONT-23924
                messageToSend: 'success',
                sourceSystem: "From Comp : MakeADeposit"
            };
            publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
            publish(this.messageContext, sbr_3_0_ROA_Table_Refresh, message);
        }, 5000);
    }

    checkTransactionStatus() {
        getTransactionById({ transactionId: this.transactionId })
            .then(result => {
                const transactionErrorMessageMobile = result.Transaction_Error_Message__c || '';
                const detailSequenceNumberMobile = result.RM_Detail_Sequence_Number__c || '';
                if (detailSequenceNumberMobile) {
                    if (transactionErrorMessageMobile) {
                        this.responseMessage = 'The transaction is not synched with RentalMan: ' + transactionErrorMessageMobile;
                        this.processing = false;
                        this.success = false;
                        this.failure = true;
                        clearInterval(this.pollInterval);
                    } else {
                        this.responseMessage = 'Transaction Created successfully!!';
                        this.processing = false;
                        this.success = true;
                        this.failure = false;
                        clearInterval(this.pollInterval);
                    }
                } else if (this.pollCount > this.maxPollCount) {
                    this.responseMessage = 'The transaction is not synched with RentalMan: ' + transactionErrorMessageMobile;
                    this.processing = false;
                    this.success = false;
                    this.failure = true;
                    clearInterval(this.pollInterval);
                }
            })
            .catch(error => {
                this.responseMessage = 'Error retrieving transaction: ' + error.body.message;
                this.processing = false;
                this.success = false;
                this.failure = true;
                clearInterval(this.pollInterval);
            });
    }


    initializeCometD() {
        fetchSessionId()
            .then(data => {
                if (data) {
                    this.sessionId = data;
                    this.error = undefined;
                    console.log('Session ID: ' + this.sessionId);
    
                    return loadScript(this, CometD);
                } else {
                    throw new Error('No data received from fetchSessionId');
                }
            })
            .then(() => {
                console.log('CometD script loaded successfully.');
                let cometDLib = new window.org.cometd.CometD();
                console.log('cometDLib ' + JSON.stringify(cometDLib));
                cometDLib.configure({
                    url: window.location.protocol + '//' + window.location.hostname + '/cometd/58.0/',
                    requestHeaders: {
                        Authorization: 'OAuth ' + this.sessionId
                    },
                    appendMessageTypeToURL: false,
                    logLevel: 'debug'
                });
                cometDLib.websocketEnabled = false;
                this.cometDLib = cometDLib;
                this.handshakeCometD();
            })
            .catch(error => {
                console.log('Error occurred in loading script or fetching session ID');
                console.log(JSON.stringify(error));
                this.sessionId = undefined;
            });
    }

    subscribeToTransactionChangeEvent() {
        this.cometDLib.subscribe(this.channelName, message => {
            console.log('Message from Event'+JSON.stringify(message));
            this.handleTransactionChangeEvent(message);
        });
    }

    handleError(error) {
        console.error('Error occurred:', JSON.stringify(error));
        this.sessionId = undefined;
    }


     // Subscribe to the Change Data Capture event channel /* Added as part of FRONT-17208 */
     subscribeToTransactionDataCapture() {
        if (this.subscription) {
            return;
        }
        subscribe(this.channelName, -1, this.handleTransactionChangeEvent).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            console.log('Subscription Response ' + JSON.stringify(this.subscription, null, 2));
            setTimeout(() => {
                // if (!this.success && !this.failure) {
                //         this.failure = true;
                //         this.processing = false;
                // }
                const message = { //added for FRONT-23924
                    messageToSend: 'success',
                    sourceSystem: "From Comp : MakeADeposit"
                };
                publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);
                publish(this.messageContext, sbr_3_0_ROA_Table_Refresh, message);
            }, 5000); // 2seconds
        }).catch(error => {
            console.error('Error subscribing to CDC event: ', JSON.stringify(error));
        });
    }

     // Handle the Change Data Capture event /* Added as part of FRONT-17208 */
     handleTransactionChangeEvent = (response) => {
        const eventMessage = response.data.payload;
        const changeEventHeader = eventMessage.ChangeEventHeader;
        console.log('Event Message:', JSON.stringify(eventMessage, null, 2));
        const detailSequenceNumber = eventMessage.RM_Detail_Sequence_Number__c || '';
        const transactionErrorMessage = eventMessage.Transaction_Error_Message__c || ''; 
        const transactionId = changeEventHeader.recordIds[0];
        const changedFields = changeEventHeader.changedFields || [];
        if (transactionId === this.transactionId) {
            if (changedFields.includes('RM_Detail_Sequence_Number__c') || changedFields.includes('Transaction_Error_Message__c')) {
                if (transactionErrorMessage) {
                    this.responseMessage = 'The transaction is not synched with RentalMan: ' + transactionErrorMessage;
                    this.processing = false;
                    this.success = false;
                    this.failure = true;
                } else {
                     this.responseMessage = 'Transaction Created successfully!!';
                    this.processing = false;
                     this.success = true;
                     this.failure = false;
                    if (this.uncollectedprocessing) {
                        this.updateInvoiceDetails();
                    } else if (this.roaprocessing) {
                        this.updateROARecords(detailSequenceNumber);
                    }
                }
            }
        }
    }

    updateROARecords(detailSeqNumber){
        const { roaRecordWithIds } = this.roaDetailRelatedData || {};
        updateROADetailRecords({ detailSeqNumber, roaRecords: JSON.stringify(roaRecordWithIds) }).catch(error =>{
            console.error('updateROADetailRecords error',error);
        })
    }
     updateInvoiceDetails(){
        const {invoiceRecordId, invoiceAmountEntered, moneyAppliedAmount} = this.invoiceRelatedData || {};
         updateInvoice({
            invoiceRecordId,
            invoiceAmountEntered,
            moneyAppliedAmount,
        }).catch(error => {
            console.error('Error in updateInvoiceDetails', error)
        }) 
      }

     // Invoked when the component is disconnected from the DOM /* Added as part of FRONT-17208 */
   /*  disconnectedCallback() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('unsubscribe() response: ', JSON.stringify(response));
            });
        }
    }
*/

    render() {
        if (this.isMobile == true) {
            return mobileTemplate;
        } else {
            return DefaultTemplate;
        }
    }

    /* 
     Sets header and waitMessage based on the payment or refund processing.
    */
    handleProcessingLabel() {
        if (this.paymentprocessing) {
            this.header = this.label.PaymentProcess;
            this.waitMessage = this.label.DepositMessage;
            this.ispaymentProcessingSuccessful = true;
        } else if (this.refundprocessing) {
            this.header = this.label.RefundProcess;
            this.waitMessage = this.label.RefundMessage;
            this.isrefundProcessingSuccessful = true;
            if (this.processadditionaldeposit) {
                this.isrefundAdditionalDeposit = true;
            }
        } else if (this.uncollectedprocessing) {
            this.header = this.label.PaymentProcess;
            this.waitMessage = this.label.DepositMessage;
            this.isuncollectedProcessingSuccessful = true;
        }
        else if (this.roaprocessing) {
            this.header = this.label.PaymentProcess;
            this.waitMessage = this.label.DepositMessage;
            this.isroaProcessingSuccessful = true;
        }
    }

    /* 
    Executes after the component's template has been rendered.
    Adds custom styling to hide the close button of the modal.
    */
    renderedCallback() {
        if (this.isLoaded) return;
        if (!this.isMobile) {
            const STYLE = document.createElement("style");
            STYLE.innerText = `.slds-modal__close{
            content-visibility :hidden;
        }`;
            this.template.querySelector('.payment-processing-container').appendChild(STYLE);
            this.isLoaded = true;
        }
    }
}