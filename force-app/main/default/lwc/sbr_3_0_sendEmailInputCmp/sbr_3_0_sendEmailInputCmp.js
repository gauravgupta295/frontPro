import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_sendEmailInputCmp extends LightningElement {

    _selectedValues = [];
    selectedValuesMap = new Map();

    get selectedValues() {
        return this._selectedValues;
    }

    set selectedValues(value) {
        this._selectedValues = value;

        let selectedValuesEvent = new CustomEvent('selection', { detail: { selectedValues: this._selectedValues} });
        this.dispatchEvent(selectedValuesEvent);
    }

    handleBlur() {
        this.setToAddressValues();
    }

    handleKeyPress(event) {
        if (event.keyCode === 13) {
            event.preventDefault();
            this.setToAddressValues();
        }
    }

    setToAddressValues() {
        let value = this.template.querySelector('input.input').value;
            if (value !== undefined && value != null && value !== '') {
                this.selectedValuesMap.set(value, value);
                this.selectedValues = [...this.selectedValuesMap.keys()];
            }
            this.template.querySelector('input.input').value = '';
    }

    handleRemove(event) {
        let item = event.target.label;
        this.selectedValuesMap.delete(item);
        this.selectedValues = [...this.selectedValuesMap.keys()];
    }

    @api reset() {
        this.selectedValuesMap = new Map();
        this.selectedValues = [];
    }

    @api validate() {
        this.template.querySelector('input').reportValidity();
        let isValid = this.template.querySelector('input').checkValidity();
        return isValid;
    }
}