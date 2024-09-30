import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_genericReadOnlyField extends LightningElement {

    @api fieldLabel;
    @api fieldValue;
    @api styleValue;
}