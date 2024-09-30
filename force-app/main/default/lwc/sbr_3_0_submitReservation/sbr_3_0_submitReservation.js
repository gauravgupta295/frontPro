import { LightningElement, api, wire, track} from "lwc";
import createOrders from "@salesforce/apex/SBR_3_0_API_CreateOrders.createOrders";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, unsubscribe } from 'lightning/empApi'; /* Added as part of FRONT-18316 */
import reservationSuccess from "@salesforce/label/c.Reservation_API_Success";
import saveDepositData from "@salesforce/apex/SBR_3_0_MakeADepositController.createDeposit";
import createTransactionId from "@salesforce/apex/SBR_3_0_MakeADepositController.createTansaction";
/* Import other labels as needed */
import header from '@salesforce/label/c.SBR_3_0_PaymentProcessing';
import waitMessage from '@salesforce/label/c.SBR_3_0_PaymentDepositMessage';
import { updateRecord } from 'lightning/uiRecordApi';
import {
  FlowAttributeChangeEvent,
  FlowNavigationFinishEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";
import { CloseActionScreenEvent } from "lightning/actions";

import STATUS_FIELD from '@salesforce/schema/Order.Status';
import ID_FIELD from '@salesforce/schema/Order.Id';
import { refreshApex } from '@salesforce/apex';
/* Importing messaging related modules */
import { MessageContext, publish } from 'lightning/messageService'; //15915 added publish
import sbr_3_0_Payment_Table_Refresh from '@salesforce/messageChannel/sbr_3_0_paymentTableRefresh__c';
export default class Sbr_3_0_submitReservation extends LightningElement {
  progress = 0;
  @track isProgressing = true;
  isDisabled = true;
  @api recordId;
  @api message = "";
  @api source = "";
  @api recordDetails = {};
  @track header = '';
  @track waitMessage = '';
  @track responseMessage = '';
  @track success = false;
  @track failure = false ;
  transactionId ;
  textValue = 'success'
  @track label = {
    header,
    waitMessage
  }
  @wire(MessageContext)
  messageContext; 
  subscription = null;
  channelName = '/data/OrderChangeEvent'; /* Added as part of FRONT-18316 */
  PaymentSubscription = null;/* Added as part of FRONT-21598 */
  paymentChannelName = '/data/Payments__ChangeEvent';/* Added as part of FRONT-21598 */
 
  connectedCallback() {
    //Check Validation to show error or call updateOrders() 

    console.log("recId" + this.recordId);
    this.subscribeToOrder(); /* Added as part of FRONT-18316 */
    this.updateOrders();       
  }

    /* Added as part of FRONT-18316 */
   disconnectedCallback() {
    if (this.subscription) {
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }
    /* Added as part of FRONT-21598 */
    if (this.PaymentSubscription) {
      unsubscribe(this.PaymentSubscription, response => {
          console.log('unsubscribe() response: ', JSON.stringify(response));
      });
  }
}
 
/* Added as part of FRONT-21598 */
subscribeToPayments() {
  if (this.PaymentSubscription) {
      console.log('Payment Subscription Response');
      return;
  }
  subscribe(this.paymentChannelName, -1, this.handlePaymentChangeEvent).then(response => {
      console.log('Subscription request sent to: ', JSON.stringify(response.channel));
      this.PaymentSubscription = response;
      console.log('Subscription Response ' + JSON.stringify(this.PaymentSubscription, null, 2));
  }).catch(error => {
      console.error('Error subscribing to Payment CDC event: ', JSON.stringify(error));
  });
}

   /* Added as part of FRONT-18316 */
   subscribeToOrder() {
   if (this.subscription) {
       return;
   }
   subscribe(this.channelName, -1, this.handleOrderChangeEvent).then(response => {
      // console.log('Subscription request sent to: ', JSON.stringify(response.channel));
       this.subscription = response;
      // console.log('Subscription Response ' + JSON.stringify(this.subscription, null, 2));
   }).catch(error => {
       console.error('Error subscribing to CDC event: ', JSON.stringify(error));
   });
}

 // Handle the Change Data Capture event  /* Added as part of FRONT-18316 */
 handleOrderChangeEvent = (response) => {
  const eventMessage = response.data.payload;
  const changeEventHeader = eventMessage.ChangeEventHeader;

 // console.log('Event Message:', JSON.stringify(eventMessage, null, 2));
  const externalOrderId = eventMessage.External_Order_ID__c || '';
  const orderId = changeEventHeader.recordIds[0];
  const syncError = eventMessage.RentalMan_Sync_Error__c || '';
  const transactionError = eventMessage.Transaction_Error_Message__c || '';
  const changedFields = changeEventHeader.changedFields || [];
  console.log('Changed Fields :',changedFields);
  console.log('External Order ID',changedFields.includes('External_Order_ID__c'));
  if (orderId === this.recordId) {
      if (changedFields.includes('External_Order_ID__c') || changedFields.includes('RentalMan_Sync_Error__c') || changedFields.includes('Transaction_Error_Message__c')) {
          if (syncError || transactionError) {
             this.label.waitMessage = 'The Reservation or Contract was not synched with RentalMan: ' + syncError;
             this.responseMessage = 'The Reservation or Contract was not synched with RentalMan: ' + syncError;
             this.success = false;
             this.failure = true;
          } else {
            //Keep the spinner till we get payment information/Status
            this.label.waitMessage = 'Reservation Created successfully!! Waiting for Payment record to get created.';
            this.responseMessage = 'Reservation Created successfully!!';
            //this.isProgressing = true;
            //this.subscribeToPayments();
          }
      }
  }
}

 /* Added as part of FRONT-21598 */
 handlePaymentChangeEvent = (response) => {
  const eventMessage = response.data.payload;
  const changeEventHeader = eventMessage.ChangeEventHeader;
  console.log('Event Message logs');
  console.log('Event Message:', JSON.stringify(eventMessage, null, 2));
  const orderIDforPayment = eventMessage.Order__c || '';
  const companyCode = eventMessage.Company_Code__c || '';
  const rmContractNumber = eventMessage.RM_Contract_Number__c || '';
  const changedFields = changeEventHeader.changedFields || [];

  if (orderIDforPayment === this.recordId) {
      if (changedFields.includes('companyCode') || changedFields.includes('rmContractNumber')) {
          if (companyCode) {
            this.failure = false;
            this.isProgressing=false;
            this.responseMessage = 'Payment applied successfully!!';
            this.success = true;       
          } else {
            this.responseMessage='The Payment was not synched with RentalMan: ' + companyCode;
            this.success = false;
            this.failure = true;
          }
      }
  }
}

  /* Added as part of FRONT-18316 */
displayError(errorMessage) {
  const event = new ShowToastEvent({
      title: 'Error',
      message: errorMessage,
      variant: 'error',
  });
  this.dispatchEvent(event);
}
  
// On success or error   

updateOrders() {
  if(this.source == 'Create Reservation'){
    createTransactionId({
      orderRecordId : this.recordId
    })
    .then(data => {
            console.log('Transaction Id Details', data);        
            this.transactionId=data;
            this.createOrder();
    }).catch(error => {
        console.error('Error', error)
        let message = error.body.message;
        const evt = new ShowToastEvent({
            title: 'Error',
            message,
            variant: 'error',
        });
        this.closeModal();
        this.dispatchEvent(evt);
      })
      
  }else{
    this.createOrder();
  }
 

}

createOrder(){
  console.log('Inside createOrder function');
  var recordDetailsString = JSON.stringify(this.recordDetails, null, "\t")
  console.log('recordDetailsString ',recordDetailsString);
  createOrders({ orderId: this.recordId,
    recordDetailsJsonString : recordDetailsString,
    TransactionID : this.transactionId})
    .then((response) => {
      if (this.source == 'Create Reservation') {
        this.isProgressing = true;
        // Navigate to success component  
        if(this.recordDetails.paymentMethod!= 'Cash Currency' && this.recordDetails.paymentMethod!= 'Check' && this.recordDetails.paymentMethod!= 'Pay on Return'){
          this.label.waitMessage = 'Deposit Maintenance request is accepted for further processing!!';
          console.log('this.label.waitMessage : ',this.label.waitMessage);
        }else {
          // Navigate to success component  
            this.responseMessage = 'Reservation submitted successfully!!';
            this.success = true;
            this.failure = false;
            saveDepositData({
              paymentDepositData: JSON.stringify(this.recordDetails),
              orderRecordId: this.recordId
          }).then(data => {            
            // Publishes a message for refreshing a table
              const message = {
                  messageToSend: this.textValue,
                  sourceSystem: "From Comp : MakeADeposit"
              };
              publish(this.messageContext, sbr_3_0_Payment_Table_Refresh, message);

              setTimeout(() => {
                let successMessageCmp = this.template.querySelector('c-sbr_3_0_payment-processing-successful');
                successMessageCmp.handleSubmitReservation(this.responseMessage); 
              }, 100);
          }).catch(error => {
              console.error('error in saveDepositData',error)

          })
         this.isProgressing = false;
       }
    }else if (this.source == "auto") {
        const attributeFinishEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(attributeFinishEvent);
        this.isProgressing = false;
        this.message = reservationSuccess;
        const attributeChangeEvent = new FlowAttributeChangeEvent(
          "message",
          reservationSuccess
        );
        this.dispatchEvent(attributeChangeEvent);
        this.showToastMessage("", reservationSuccess, "success", "sticky");
      } else {
      const attributeFinishEvent = new FlowNavigationFinishEvent();
      this.dispatchEvent(attributeFinishEvent);
      this.isProgressing = false;
      this.message = reservationSuccess;
      const attributeChangeEvent = new FlowAttributeChangeEvent(
        "message",
        reservationSuccess
      );
      this.dispatchEvent(attributeChangeEvent);
      this.showToastMessage("", reservationSuccess, "success", "sticky");
    }
    })
    .catch((error) => {
      console.log("Error in createOrders:" + error.body.message);
      if (this.source == 'Create Reservation') {
        this.isProgressing = false;
        this.success = false;
        this.failure = true;
        // Navigate to Error screen 
        if (error.body.message != null) {
          this.message = error.body.message;
          if(this.message.includes('Rental Man Error') || this.message.includes('Invalid input') || this.message.includes('rentals1')
          || this.message.includes('HTTP Method get not allowed') || this.message.includes('Unsupported mediaType')
          || this.message.includes('Error occurred, please refer application logs for more details')){
            let messages =  this.message.split("message:");
            this.message = messages[0] + "\n" + "\n" +"\n" +"message:" + messages[1];
          } 
        }
        setTimeout(() => {
          let failedMessageCmp = this.template.querySelector('c-sbr_3_0_payment-processing-failed');
          failedMessageCmp.handleSubmitReservation(this.message); 
        }, 100);
              
       
      }else if (this.source == "auto") {

        const attributeFinishEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(attributeFinishEvent);
        this.isProgressing = false;
        if (error.body.message != null) {
          this.message = error.body.message;
        } else {
          this.message =
            "Failed to submit Order. Please try again. If issues persist, notify your System Administrator";
        }
        console.log("this.message:" + this.message);
        const attributeChangeEvent = new FlowAttributeChangeEvent(
          "message",
          error.body.message
        );
        this.dispatchEvent(attributeChangeEvent);
        //this.closeAction();
        this.showToastMessage("", this.message, "error", "sticky");

      } else {

        const attributeFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(attributeFinishEvent);
        this.isProgressing = false;
          if (error.body.message != null) {
        this.message = error.body.message;
          } else {
            this.message =
              "Failed to submit Order. Please try again. If issues persist, notify your System Administrator";
          }
        console.log("this.message:" + this.message);
        const attributeChangeEvent = new FlowAttributeChangeEvent(
          "message",
          error.body.message
        );
        this.dispatchEvent(attributeChangeEvent);
        this.closeAction();
        this.showToastMessage("", this.message, "error", "sticky");
      }
    });
}

callFromFailureComp(event){
  this.recordDetails = event.detail;
  this.updateOrders();
}


  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
  }
  showToastMessage(title, message, variant, mode) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: mode
      })
    );
  }
}