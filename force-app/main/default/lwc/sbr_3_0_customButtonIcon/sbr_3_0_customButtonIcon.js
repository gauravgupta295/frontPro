import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_customButtonIcon extends LightningElement {

    @api iconName;
    @api iconVariant;
    @api tooltip;
    @api iconSize;
    @api name;
    @api value;
    @api rowId;

    loadNotesModal() {
        console.log('Inside notes click');
        console.log('@@this.value item::', this.value);
        const event = new CustomEvent('notesiconselected', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                name: this.name,
                value: this.value,
                rowid: this.rowId
            },
        });

        this.dispatchEvent(event);
    }
}