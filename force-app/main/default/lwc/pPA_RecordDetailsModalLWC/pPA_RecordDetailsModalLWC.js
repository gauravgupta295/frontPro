import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class PPA_RecordDetailsModalLWC extends LightningModal {
    @api objectName;
    @api recordId;
    @api layout;

    handleClose() {
        this.close();
    }
}