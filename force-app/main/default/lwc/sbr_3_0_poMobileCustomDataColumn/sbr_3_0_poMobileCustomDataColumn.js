import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_poMobileCustomDataColumn extends LightningElement {

    isText = false;
    isNumber = false;
    isURL = false;
    isCurrency = false;
    _columnObj ={};

    @api
    set columnObj(value) {
        this._columnObj = value;
        if (this._columnObj.type) {
            if (this._columnObj.type.toUpperCase() === 'TEXT') {
                this.isText = true;
            }
            else if (this._columnObj.type.toUpperCase() === 'NUMBER') {
                this.isNumber = true;
            }
            else if (this._columnObj.type.toUpperCase() === 'URL') {
                this.isURL = true;
            }
            else if (this._columnObj.type.toUpperCase() === 'CURRENCY') {
                this.isCurrency = true;
                let formattedValue = this._columnObj.value.toLocaleString('en-US', {
                    style: 'currency',
                    currency: 'USD',
                    minimumFractionDigits: 3,
                    maximumFractionDigits: 3,
                });
                let newColumnObj = { ...this._columnObj, value: formattedValue };
                this._columnObj = newColumnObj;
            }
        }
        else {
            this.isText = true;
        }
    }
    get columnObj() {
        return this._columnObj;
    }
}