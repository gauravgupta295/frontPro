// Nikhil Shende
import { LightningElement } from 'lwc';
export default class SBR_3_0_receiptAdjustmentModal extends LightningElement {
    isShowModal = true
    selectedCreditReason;
    isDisabled = true;

    get creditReasonsOptions() {
        return [
            {label: 'CC Cost Change (PRICE INCREASE)', value: 'CC Cost Change'},
            {label: 'DA Damaged', value: 'DA Damaged'},
            {label: 'OV Overage', value: 'OV Overage'},
            {label: 'QC Quantity Change', value: 'QC Quantity Change'},
            {label: 'SH Shortage', value: 'SH Shortage'},
            {label: 'WP Wrong Price', value: 'WP Wrong Price'},
            {label: 'WQ Wrong Quantity', value: 'WQ Wrong Quantity'}
        ]
    }

    hideModalBox() {
        this.isShowModal = false
        const selectedEvent = new CustomEvent("closereceiptadjustment", {
            detail: false
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    handleChange(event) {
        this.selectedCreditReason = event.detail.value;
        if (this.selectedCreditReason.length > 0) {
            this.isDisabled = false;
        }
        else{
            this.isDisabled = true;
        }
    }

    handleProceedClick() {
        this.isShowModal = false
        const selectedEvent = new CustomEvent("proceedreceiptadjustment", {
            detail: {
                isShowModal :false,
                creditReason : this.selectedCreditReason
            }
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}