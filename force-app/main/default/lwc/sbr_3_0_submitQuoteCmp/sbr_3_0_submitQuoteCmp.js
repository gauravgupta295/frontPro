import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkUserPermissions from '@salesforce/apex/SBR_3_0_SubmitQuoteController.checkUpdateablePermission';
import submitQuote from '@salesforce/apex/SBR_3_0_SubmitQuoteController.submitQuote';
import checkRequiredData from '@salesforce/apex/SBR_3_0_SubmitQuoteController.checkRequiredData';
import updateQuoteItemTaxes from '@salesforce/apex/SBR_3_0_API_Contract_OpenQuoteTaxUpdate.updateQuoteTaxes';//19714, 21257, SADAPUR
/* START : FRONT-13993 */
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";
import checkRecord from "@salesforce/apex/SBR_3_0_DynamicRecordFormController.checkRecord"; //FRONT-20239, FRONT-18373
/* END : FRONT-13993 */
import { getRecord } from "lightning/uiRecordApi"; //FRONT-25229
import NAME_FIELD from "@salesforce/schema/SBQQ__Quote__c.Quote_Name__c"; //FRONT - 25229

const quoteFields = [NAME_FIELD]; //FRONT-25229

export default class sbr_3_0_submitQuoteCmp extends LightningElement {
    @api recordId;
    quoteName; //FRONT-25229
    @track isError = false;
    @track isSuccess = false;
    @track isCloseDisabled = true;
    @track isRetryDisabled = true;
    @track message;
    @track showSpinner = false;
    @track isMobile = false;
    /* START : FRONT-13993 */
    staleTotals = true;
    appName = '';
    callCreateQuote = true;
    errMsg = '';
    /* END : FRONT-13993 */

    @wire(checkUserPermissions, { recordId: '$recordId' })
    wiredPermissions({ error, data }) {
        if (data) {
            if (data.hasPermission) {
                this.submitQuoteToRentalman();
            }
            else if (data.hasPermission === false) {
                this.setErrorMessage('You do not have the correct permissions to submit quote. Please reach out to the Quote Owner for access.');
                this.showToastMessage('', this.message, 'warning', 'dismissible');
                this.callValueChangeEvent();
            }
        } else if (error) {
            console.log('wiredPermissions error:');
            console.log(error);
        }
    }

    //FRONT-25229
    @wire(getRecord, { recordId: '$recordId', fields: quoteFields })
    wiredUser({ error, data }) {
        if (data) {
            this.quoteName = data.fields.Quote_Name__c.value;
        } else if (error) {
            console.log("error", error);
        }
    }

    connectedCallback() {
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        /* START : FRONT-13993 */
        getAppName()
            .then((results) => {
                this.appName = results;
                if (this.appName === "RAE Frontline") {
                    checkRecord({ objectName: 'SBQQ__Quote__c', recordId: this.recordId })
                        .then(result => {
                            this.staleTotals = result;
                        })
                }
            });
        /* END : FRONT-13993 */
    }

    submitQuoteToRentalman() {
        /* Added if else for FRONT-13993 */
        /* Modified for FRONT-20459 */
        getAppName()
            .then((results) => {
                this.appName = results;
                checkRecord({ objectName: 'SBQQ__Quote__c', recordId: this.recordId })
                    .then(result => {
                        this.staleTotals = result;
                        if (this.appName === "RAE Frontline" && this.staleTotals) {
                            this.errMsg = 'You have updated the Quote, Please click on the Quote Review tab to confirm before submitting the Quote';
                            this.callCreateQuote = false;
                        } else {
                            this.showSpinner = true;
                            this.message = 'Submitting quote...';
                            this.isError = false;
                            this.isSuccess = false;
                            this.isCloseDisabled = true;
                            this.isRetryDisabled = true;
                            checkRequiredData({ recordId: this.recordId })
                                .then(message => {
                                    console.log('message = ', message);
                                    if (message === 'true') {
                                        submitQuote({ recordId: this.recordId })
                                            .then(result => {
                                                this.isSuccess = true;
                                                this.showSpinner = false;
                                                this.isCloseDisabled = false;
                                                this.isRetryDisabled = true;
                                                this.message = this.quoteName + ' has been successfully created'; //FRONT-25229
                                                this.showToastMessage('', this.message, 'success', 'dismissible');
                                                this.handleCloseClick();
                                                updateQuoteItemTaxes({ recordId: this.recordId })
                                                    .then(result => {
                                                        console.log('isValidQuoteRecord->' + result.isValidQuoteRecord);
                                                        this.callValueChangeEvent();
                                                    }).catch(error => {
                                                        console.log('Failed to retrieve totals: ' + JSON.stringify(error));
                                                        this.callValueChangeEvent();
                                                    })

                                            })
                                            .catch(error => {
                                                console.log('Error: ');
                                                console.log(error);
                                                this.isError = true;
                                                this.showSpinner = false;
                                                this.isCloseDisabled = false;
                                                this.isRetryDisabled = false;
                                                if (error.body.message != null) {
                                                    this.message = error.body.message;
                                                }
                                                else {
                                                    this.message = 'Failed to submit Quote. Please try again. If issues persist, notify your System Administrator';
                                                }
                                                this.handleCloseClick();
                                                this.showToastMessage('', error.body.message, 'error', 'dismissible');
                                                this.callValueChangeEvent();
                                            })
                                    } else {
                                        this.isError = true;
                                        this.showSpinner = false;
                                        this.isCloseDisabled = false;
                                        this.isRetryDisabled = false;
                                        this.message = message;
                                        this.handleCloseClick();
                                        this.showToastMessage('', this.message, 'error', 'dismissible');
                                        this.callValueChangeEvent();
                                    }
                                })
                        }
                    });
            });
    }

    setErrorMessage(msg) {
        this.isError = true;
        this.showSpinner = false;
        this.isCloseDisabled = false;
        this.isRetryDisabled = true;
        this.message = msg;
    }

    handleCloseClick() {
        const closeQA = new CustomEvent('close');
        // Dispatches the event.
        this.dispatchEvent(closeQA);
    }

    @api
    handleRetryClick() {
        console.log('in submitQuote');
        this.submitQuoteToRentalman();
    }

    callValueChangeEvent() {
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: {
                "isCloseDisabled": this.isCloseDisabled,
                "isRetryDisabled": this.isRetryDisabled
            }
        });
        // Fire the custom event
        this.dispatchEvent(valueChangeEvent);
    }
    showToastMessage(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );

    }
}