import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class PPA_ConfirmClearRatesModalLWC extends LightningModal {
    @api modalHeader;
    @api modalBody;

    handleClear() {
        this.close('OK');
    }

    handleCancel() {
        this.close();
    }
}