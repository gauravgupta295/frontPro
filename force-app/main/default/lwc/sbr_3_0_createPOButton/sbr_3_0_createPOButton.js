import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkRecordCount from '@salesforce/apex/SBR_3_0_CreatePOButtonController.checkRecordCount';
import checkRequiredFields from '@salesforce/apex/SBR_3_0_CreatePOButtonController.checkRequiredFields';
import checkOldPOLI from '@salesforce/apex/SBR_3_0_CreatePOButtonController.checkOldPOLI';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateStatus from '@salesforce/apex/SBR_3_0_CreatePOButtonController.updateStatus';
import getVendorStatusPicklist from '@salesforce/apex/SBR_3_0_CreatePOButtonController.getVendorStatusPicklist';
import getVendorStatus from '@salesforce/apex/SBR_3_0_CreatePOButtonController.getVendorStatus';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
//Message Channel
import { MessageContext, publish } from 'lightning/messageService';
import PurchaseOrderLineItemMessageChannel from '@salesforce/messageChannel/PurchaseOrderLineItem__c';
export default class Sbr_3_0_createPOButton extends LightningElement {
    @wire(MessageContext)
    messageContext
    _recordId;
    @api set recordId(value) {
        this._recordId = value;
        this.checkValidations();
    }

    get recordId() {
        return this._recordId;
    }

    async checkValidations() {
        try {
            let venStatuses = await getVendorStatusPicklist({ objectName: 'Account', fieldName: 'Vendor_Status__c'});
            //console.log(venStatuses);
            const venStatusMap = new Map(Object.entries(venStatuses));
            let venStatus = await getVendorStatus({ recordId: this.recordId });
            //console.log(venStatus);
            if (venStatusMap.get(venStatus) == 'Hold Payment and Purchasing' || venStatusMap.get(venStatus) == 'Hold for Purchasing (Orders)') {
                let errMsg = 'Unable to Create PO. Vendor now on ' + venStatusMap.get(venStatus) + '.';
                this.showToast(errMsg, '', 'error');
                const payload = {
                    recordId: this.recordId,
                    recordUpdated: false
                };
                publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
            }
            else {
                const recCnt = await checkRecordCount({ recordId: this.recordId });
                console.log(recCnt);
                if (recCnt != undefined && recCnt > 0) {
                    const reqFields = await checkRequiredFields({ recordId: this.recordId });
                    console.log(reqFields);
                    if (reqFields === true) {
                        const oldPOLIValue = await checkOldPOLI({ recordId: this.recordId });
                        console.log('oldPOLIValue', oldPOLIValue);
                        const updStatus = await updateStatus({ recordId: this.recordId });
                        console.log(updStatus);
                        if (updStatus === 'Success') {
                            //TODO: Call SBR_3_0_API_CreatePO.createPO when mulesoft is ready
                            this.showToast('Success', 'Your PO has been created. Generate a PDF to print or email this purchase order.', 'success');
                            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                            const payload = {
                                recordId: this.recordId,
                                recordUpdated: true
                            };
                            publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                        }
                        else if (updStatus === 'Open') {
                            this.showToast('Success', 'Your PO is already Open.', 'success');
                            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                            const payload = {
                                recordId: this.recordId,
                                recordUpdated: true
                            };
                            publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                        }
                        else {
                            this.showToast('Error', 'Please contact your administrator.', 'error');
                            const payload = {
                                recordId: this.recordId,
                                recordUpdated: false
                            };
                            publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                        }
                        }
                    else {
                        this.showToast('Error', 'Unable to create PO. There are required fields on line item details that are empty.', 'error');
                        const payload = {
                            recordId: this.recordId,
                            recordUpdated: false
                        };
                        publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                    }
                }
                else if (recCnt == 0) {
                    console.log(">>> in else if" + recCnt);
                    this.showToast('Error', 'Unable to create PO. There are no line items found.', 'error');
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: false
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                }
                else {
                    console.log(">>> in else" + recCnt);
                    this.showToast('Error', 'Please contact your administrator.', 'error');
                    const payload = {
                        recordId: this.recordId,
                        recordUpdated: false
                    };
                    publish(this.messageContext, PurchaseOrderLineItemMessageChannel, payload);
                }
            }
            this.closeAction();
            this.dispatchEvent(new CustomEvent('close'));
        } catch (err) {
            console.log(err);
        }
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}