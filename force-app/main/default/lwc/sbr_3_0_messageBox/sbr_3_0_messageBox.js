import { LightningElement, api, track } from 'lwc';
export default class MessageBox extends LightningElement {
    @api type;
    @api title;
    @api message;
    @track error = false;
    @track warning = false;
    @track info = false;
    @track success = false;
    
    connectedCallback() {
        this.show();
    }

    @api show() {
        if (this.type === "error") {
            this.error = true;
        } else if (this.type === "warning") {
            this.warning = true;
        } else if (this.type === "info") {
            this.info = true;
        } else if (this.type === "success") {
            this.success = true;
        }
    }

    handleClose() {
        this.error = false;
        this.warning = false;
        this.info = false;
        this.success = false;
    }
}