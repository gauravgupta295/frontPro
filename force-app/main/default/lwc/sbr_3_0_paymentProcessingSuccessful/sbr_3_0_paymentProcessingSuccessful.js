/* Importing necessary modules and dependencies */
import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { MessageContext, publish } from 'lightning/messageService';

/* Import other labels as needed */
import PaymentApplied from '@salesforce/label/c.SBR_3_0_PaymentApplied'; 
import RefundApplied from '@salesforce/label/c.SBR_3_0_RefundApplied'; //15915
import RefundAppliedMobile from '@salesforce/label/c.SBR_3_0_RefundMobileApplied';
import RentalReturnApplied from '@salesforce/label/c.SBR_3_0_RentalReturnApplied'; //FRONT-19236
import RefundReceipt from '@salesforce/label/c.SBR_3_0_RefundSendReceipt';
import RefundSuccess from '@salesforce/label/c.SBR_3_0_RefundSuccessfull';
import UncollectedApplied from '@salesforce/label/c.SBR_3_0_UncollectedApplied';
import ROASubmitted from '@salesforce/label/c.SBR_3_0_ROASubmittedToast';
import UncollectedSuccess from '@salesforce/label/c.SBR_3_0_UncollectedSuccessfull';
import AdditionalRefundNew from '@salesforce/label/c.SBR_3_0_AdditionalRefund';
import ROASuccess from '@salesforce/label/c.SBR_3_0_ROASuccessfull';
import RefundProcess from '@salesforce/label/c.SBR_3_0_RefundProcessed';
import PaymentReceipt from '@salesforce/label/c.SBR_3_0_SendPaymentReceipt';
import DepositProcess from '@salesforce/label/c.SBR_3_0_DepositProcessed';
import PaySuccesss from '@salesforce/label/c.SBR_3_0_PaymrntSuccessfull';
import RefundSuccessAdditionalRefund from '@salesforce/label/c.SBR_3_0_RefundSuccessfull_Additional_Deposit'; //FRONT-15914
import PaymentUncollected from '@salesforce/label/c.SBR_3_0_Payment_Marked_as_Uncollected'; //FRONT-19236
import UncollectedSuccessful from '@salesforce/label/c.SBR_3_0_Uncollected_Successful'; //FRONT-19236
import PaymentReturnSuccessful from '@salesforce/label/c.SBR_3_0_Payment_Return_Not_Uncollected_Successful'; 
import CLOSE_MODAL from '@salesforce/messageChannel/sbr_3_0_quickActionModalEvents__c';
import PaySubmitted from '@salesforce/label/c.SBR_3_0_PaymentRequestSubmitted';
import { CloseActionScreenEvent } from "lightning/actions";
import AdditionalRefund from '@salesforce/label/c.SBR_3_0_Process_Additional_Refund';
import CreateReservationSuccess from '@salesforce/label/c.SBR_3_0_CreateReservationSuccessful';
import CreateReservationPayOnReturnSuccess from '@salesforce/label/c.SBR_3_0_CreateReservationPayOnReturnSuccessful';
import CreateReservationNonROPToast from '@salesforce/label/c.SBR_3_0_CreateReservationNonROPToast';
import CreateReservationROPToast from '@salesforce/label/c.SBR_3_0_CreateReservationROPToast';
import AdditionalRefundCreateReturn from '@salesforce/label/c.SBR_3_0_AdditionalRefundCreateReturn'; //FRONT-16361
import RefundReturnSuccessToast from '@salesforce/label/c.SBR_3_0_RefundReturnSuccessToast'; //FRONT-16361
import NoRefundGiven from '@salesforce/label/c.SBR_3_0_No_Refund_Given'; //FRONT-16361
import SubmitRefundRequest from '@salesforce/label/c.SBR_3_0_SubmitRefundRequest';  //FRONT-16361
import requestURL from '@salesforce/label/c.SBR_3_0_RequestURL'; //FRONT-16361


import DefaultTemplate from "./sbr_3_0_paymentProcessingSuccessful.html";
import mobileTemplate from "./sbr_3_0_paymentProcessingSuccessfulMobileTemplate.html";
import { updateRecord } from "lightning/uiRecordApi"; //FRONT-16361

/* Initialize class */
export default class Sbr_3_0_paymentProcessingSuccessful extends LightningElement {

  /* Defining labels */
  label = {
    PaySuccesss,
    RefundReceipt,
    RefundSuccess,
    DepositProcess,
    PaymentReceipt,
    RefundProcess,
    RefundSuccessAdditionalRefund,
    UncollectedSuccess,
    UncollectedApplied,
    PaymentUncollected,
    UncollectedSuccessful,
    PaymentReturnSuccessful,
    RentalReturnApplied,
    PaySubmitted,
    ROASuccess,
    ROASubmitted,
    AdditionalRefund,
    AdditionalRefundNew,
    AdditionalRefundCreateReturn
  };

  /* Define other tracked properties and APIs */
  @wire(MessageContext)
    messageContext;
  @api paymentOptionSelected;
  @track generatePdfProcessing = false;
  @api paymentprocessingsuccessful = false;
  @api refundprocessingsuccessful = false;
  @api uncollectedprocessingsuccessful = false;
  @api roaprocessingsuccessful = false;
  @api refundadditionaldeposit = false;
  @track header = '';
  @track successMessage = '';
  @track remindMessage = '';
  @track cancelRefund = false;
  @api recidN;
  @track refunddeposit = false;
  additionalDepositMessage; //FRONT-15914  
  uncollectedSuccessMessage
  roaSuccessMessage
  @api isfromcancelprocessing = false;
  @api isfromsubmitreservation = false; 
  isMobile = false;
  uncollectedSuccessfulContentMessage;
  payOnReturnSuccessfulContentMessage;
  //added for FRONT-23924 START
  @api isFromCreateReservation;
  createReservationNonPORSuccessMessage;
  //added for FRONT-23924 END
  //FRONT-15078 START
  @api isFromCreateReturn = false;
  variantLabel = 'neutral';
  get showSuccessModal() { //success modal will not be visible in case of Create Return when additional deposit is not present.
    !this.isFromCreateReturn || this.refundadditionaldeposit
  }
  @track showSuccessModal = true;
  @api paymentMethodRelatedData;
  @api RefundAppliedToast;
  //FRONT-15078 END
  reservationOrderNum;
  contractOrderNum;

  async connectedCallback() {
    this.isMobile = window.matchMedia("(max-width: 480px)").matches;
    this.variantLabel = this.isFromCreateReturn ? 'brand': 'neutral';  //FRONT-15078
    await this.handleCreateReturn();  //FRONT-15078
    this.additionalDepositMessage =  (RefundSuccessAdditionalRefund || '').split('\\n').join('\n');
    this.uncollectedSuccessMessage = (UncollectedSuccess || '').split('\\n').join('\n');
    this.uncollectedSuccessfulContentMessage = (UncollectedSuccessful || '').split('\\n').join('\n'); 
    this.payOnReturnSuccessfulContentMessage = (PaymentReturnSuccessful || '').split('\\n').join('\n'); 
    this.createReservationNonPORSuccessMessage = (CreateReservationSuccess || '').split('\\n').join('\n');
    this.roaSuccessMessage = (ROASuccess || '').split('\\n').join('\n');
    // Calls a method to handle processing successful label
    if(this.isMobile){
      this.RefundAppliedToast = (RefundAppliedMobile || '').split('\\n').join('\n');
    }else{
      this.RefundAppliedToast =RefundApplied;
    }
    
    this.handleProcessingSuccessfulLabel();

  }

   //FRONT-15078 START
  async handleCreateReturn() {
    if (!this.refundadditionaldeposit && this.isFromCreateReturn) {
      const { modeOfPaymentMap = [], contractOrderNumber = '', reservationOrderNumber='' } = this.paymentMethodRelatedData || {};
      this.reservationOrderNum =reservationOrderNumber;
      this.contractOrderNum =contractOrderNumber;
      if ((modeOfPaymentMap[this.paymentOptionSelected] == 'No Refund Given') || (this.isFromCreateReturn && modeOfPaymentMap[this.paymentOptionSelected] == 'Uncollected')) {
        this.dispatchEvent(new ShowToastEvent({
          message: `${NoRefundGiven} {0}`,
          variant: 'success',
          mode: 'sticky',
          messageData: [
            {
              url: requestURL,
              label: SubmitRefundRequest
            }
          ]
        }));
      }

      const fields = {
        Id: this.recidN,
        Status: 'Closed'
      };
      const recordInput = { fields };
      updateRecord(recordInput).catch(error => console.error('error in updating order status', error))
      const messageClose = {
        closeModal: true
      };
      //publish(this.messageContext, CLOSE_MODAL, { payload: messageClose });
    }
  }

  closeModal(){
    const messageClose = {
      closeModal: true,
      isPaymentSuccessful : true
    };
    publish(this.messageContext, CLOSE_MODAL, { payload: messageClose });
  }
   //FRONT-15078 END

  render() {
    if (this.isMobile == true) {
        return mobileTemplate;
    } else {
        return DefaultTemplate;
    }
}

  // Method to handle processing successful label based on payment or refund
  handleProcessingSuccessfulLabel() {
    if (this.paymentprocessingsuccessful) {
      if (this.isFromCreateReservation) {
        if (this.paymentOptionSelected === 'Pay on Return') {
          this.header = 'Pay on Return';
          this.successMessage = CreateReservationPayOnReturnSuccess;
          this.remindMessage = this.label.PaymentReceipt;
        } else {
          this.header = this.label.PaySuccesss;
          this.successMessage = this.createReservationNonPORSuccessMessage;
          this.remindMessage = this.label.PaymentReceipt;
        }
        return;
      }
      // Set labels for successful payment //FRONT-19236
      if(this.paymentOptionSelected ==='Uncollected'){
        this.header = this.label.PaymentUncollected;
      this.successMessage = this.uncollectedSuccessfulContentMessage;
      this.remindMessage = this.label.PaymentReceipt;
      }else{
        if(this.isFromCreateReturn){
          this.header = this.label.PaySuccesss;
          this.successMessage = this.payOnReturnSuccessfulContentMessage;
          this.remindMessage = this.label.PaymentReceipt;
        }else{
          this.header = this.label.PaySuccesss;
          this.successMessage = this.label.DepositProcess;
          this.remindMessage = this.label.PaymentReceipt;
        }
      }
    } else if (this.refundprocessingsuccessful) {
      if(this.isFromCreateReturn){ //FRONT-16361
        this.remindMessage = this.label.AdditionalRefundCreateReturn
      }else if(this.isfromcancelprocessing){
        this.cancelRefund = true;
        this.remindMessage = this.label.AdditionalRefundNew
      }else{
        this.remindMessage = this.refundadditionaldeposit === true ? this.additionalDepositMessage  :this.label.PaymentReceipt ; //FRONT-15914
      }
      this.header = this.label.RefundProcess;
      this.successMessage = this.label.RefundSuccess;
    } else if(this.uncollectedprocessingsuccessful){
      this.header = this.label.PaySuccesss;
      this.successMessage = this.uncollectedSuccessMessage;
      this.remindMessage = this.label.PaymentReceipt;
    }else if(this.roaprocessingsuccessful){
      this.header = this.label.PaySubmitted;
      this.successMessage = this.roaSuccessMessage;
      this.remindMessage = this.label.PaymentReceipt;
    }
  }

  

  // Event handler for skipping the process for now 
  handleSkipForNow(event) {
    // Dispatches a success toast message event for certain payment options
    let message; //FRONT-19236
    if(this.paymentOptionSelected ==='Uncollected'){
       message = this.label.RentalReturnApplied;
    }
    else{
      if(this.isFromCreateReservation){
        if (this.paymentOptionSelected === 'Pay on Return') {
          message = CreateReservationROPToast;
        }else{
          message = CreateReservationNonROPToast;
        }
      }else{
     message = this.paymentprocessingsuccessful ? PaymentApplied : (this.refundprocessingsuccessful ? this.RefundAppliedToast : (this.uncollectedprocessingsuccessful ? UncollectedApplied : (this.roaprocessingsuccessful ? ROASubmitted : ''))); //15915
      }
    }

    if (this.isFromCreateReservation && this.isMobile) {
      const messageClose = {
        closeModal: true,
        isPaymentSuccessful : true
      };
      publish(this.messageContext, CLOSE_MODAL, { payload: messageClose });
    }

    if (message === UncollectedApplied) {
      const evt = new ShowToastEvent({
        message,
        variant: 'success',
      });
      this.dispatchEvent(evt);
    }

  if(this.isfromsubmitreservation){
    this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
  }else{
    const messageClose = {
      closeModal: true
    };
    publish(this.messageContext, CLOSE_MODAL, { payload: messageClose });
  } 

    if (!this.refundadditionaldeposit && this.isFromCreateReturn) {
      const successToastMessage = RefundReturnSuccessToast.replace('{0}',this.contractOrderNum || this.reservationOrderNum);
      this.dispatchEvent(new ShowToastEvent({
          message: successToastMessage,
          variant: 'success'
        }));
    }

    if (!this.isFromCreateReturn) {
      if (this.isMobile == true && message == PaymentApplied) {
        const evt = new ShowToastEvent({
          message: message+'        ',
          variant: 'success',
        });
        this.dispatchEvent(evt);
      } else if(message !== UncollectedApplied){
        const evt = new ShowToastEvent({
          message,
          variant: 'success',
        });  
        this.dispatchEvent(evt);  
      }
    }
    
  }

  // Event handler for handling  
  handleprocessAdditionalDeposit(){
    this.refunddeposit = true;
  }

  // Method to set a flag indicating PDF generation is in progress
  handleGeneratePdf() {
    setTimeout(() => {
        this.generatePdfProcessing = true;
    }, 30000);
  }

  // Called when the component is rendered
  renderedCallback() {
    // Checks if already loaded to avoid re-execution
    if (this.isLoaded) return;
    if (!this.isMobile) {
      // Dynamically adds CSS style for .slds-modal__close element
      const STYLE1 = document.createElement("style");
      STYLE1.innerText = `.slds-modal__close{
       content-visibility :visible;
    }`;
      this.template.querySelector('.slds-modal__header')?.appendChild(STYLE1);
    }
    // Marks as loaded to prevent re-execution
    this.isLoaded = true;
  }
}