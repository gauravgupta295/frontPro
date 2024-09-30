import { LightningElement, api, track } from 'lwc';

export default class SBR_3_0_DuplicateAMCRAlert extends LightningElement {
    @api message;
    @track showMessage = false;

    connectedCallback() {
        this.showMessage = true;
    }
}