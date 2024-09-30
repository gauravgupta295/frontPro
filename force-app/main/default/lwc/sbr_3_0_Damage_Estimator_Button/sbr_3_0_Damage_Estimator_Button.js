/* eslint-disable @lwc/lwc/no-api-reassignments */
import { LightningElement, api, track } from 'lwc';
import {FlowNavigationNextEvent, FlowAttributeChangeEvent} from 'lightning/flowSupport';
import INVOICE_DESCRIPTION_ERROR from "@salesforce/label/c.SBR_3_0_BillCustomerInvoiceDescriptionError";
import RETAIL_AMOUNT_ERROR from "@salesforce/label/c.SBR_3_0_BillCustomerRetailAmountError";

export default class Sbr_3_0_Damage_Estimator_Button extends LightningElement {
    @track isShowModal = false;
    @api closedWithoutBillingReason ='';
    @api relatedStatus;
    @api invoiceDescription;
    @api isRetailSectionVisible;
    @api buttonName = "";
    @api displayBilltoCustomer = false;
    @api displayCloseUnbilled = false;
    @api totalRetailAmount;

    isShowBillToCustomer;
    validationErrorMessage;
    isShowMessageBox = false;

    showModalBox() {
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    handleSaveUnbilled(event)
    {
        this.buttonName = "";
        const reasonDetails = event?.detail?.reasonValue;
        if(reasonDetails || reasonDetails !== '')
        {
            //Save value to DB, Close the estimator, Set values in flow to update further.
            this.closedWithoutBillingReason = reasonDetails;
            this.relatedStatus = 'CLOSED WITHOUT BILLED';
            this.dispatchFlowAttributeChangeEvent('relatedStatus');
            this.dispatchFlowAttributeChangeEvent('closedWithoutBillingReason');
        }
        this.hideModalBox();
        this.dispatchNextEvent();
    }

    dispatchNextEvent()
    {
        // navigate to the next screen
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    dispatchFlowAttributeChangeEvent(attributeName)
    {
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            attributeName,
            this[attributeName]
        );
        this.dispatchEvent(attributeChangeEvent);
    }

    showBillToCustomer(){
        //Check for validation and display error message for required field.
        if(this.isRetailSectionVisible && (!this.invoiceDescription || !this.totalRetailAmount)){
            //Show error message on screen.
            this.isShowMessageBox = true;
            this.errorDescription = 'Missing required value';
            this.validationErrorMessage = !this.invoiceDescription ? INVOICE_DESCRIPTION_ERROR : '';
            this.validationErrorMessage += !this.totalRetailAmount ? ((this.validationErrorMessage ? '\n' : '') + RETAIL_AMOUNT_ERROR) : '';
        } else{
            this.isShowBillToCustomer = true;
        }
    }

    handleBillToCustomerYes(){
        //Check for validation and display error message for required field.
        if(this.isRetailSectionVisible && (!this.invoiceDescription || !this.totalRetailAmount)){
            //Show error message on screen.
            this.isShowMessageBox = true;
            this.errorDescription = 'Missing required value';
            this.validationErrorMessage = !this.invoiceDescription ? INVOICE_DESCRIPTION_ERROR : '';
            this.validationErrorMessage += !this.totalRetailAmount ? ((this.validationErrorMessage ? '\n' : '') + RETAIL_AMOUNT_ERROR) : '';
            this.isShowBillToCustomer = false;
        } else{
            //Make API Callout
            this.dispatchNextForBillCustomer();
        }
    }

    dispatchNextForBillCustomer()
    {
        //Call API if data is valid
        if(this.handleAPIRequest())
            {
                //Set Damage Estimator Status on API success response
                this.relatedStatus = 'SEND TO RM'; // Make this BILLED as soon we get a response from API.
                //Notify attribute change to Flow
                this.buttonName = 'Bill';
                this.dispatchFlowAttributeChangeEvent('relatedStatus');
                this.dispatchFlowAttributeChangeEvent('buttonName');
                //Save values to database
                this.dispatchNextEvent();
                this.isShowMessageBox = false;
            }
            else{
                //Show API error related data, Or say "Failed to Bill the customer Please try again, or contact your admin"
            }
    }

    /**
     * @description | Call API code for
     * @returns | It will return true or false based on API request pass or fail.
     */
    handleAPIRequest()
    {
        return true;
    }

    hideBillToCustomer()
    {
        
        this.isShowBillToCustomer = false;
        
    }
}