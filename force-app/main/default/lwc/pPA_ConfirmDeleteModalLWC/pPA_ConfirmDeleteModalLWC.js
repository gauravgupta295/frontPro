import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class PPA_ConfirmDeleteModalLWC extends LightningModal {
    @api modalHeader;
    @api modalBody;

    handleDelete() {
        this.close('OK');
    }

    handleCancel() {
        this.close();
    }
}