import { LightningElement,api } from 'lwc';

export default class Sbr_3_0_NoLocationFoundIllustrationComponent extends LightningElement {
    _noRecordsFoundMessage =  "No Records Found";

    @api
    get noRecordsFoundMessage() {
        return this._noRecordsFoundMessage;
    }
    set noRecordsFoundMessage(value) {
        this._noRecordsFoundMessage = value;
    }
}