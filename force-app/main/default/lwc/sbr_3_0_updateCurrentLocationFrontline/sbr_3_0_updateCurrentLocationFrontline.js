import { LightningElement } from 'lwc';
export default class Sbr_3_0_updateCurrentLocationFrontline extends LightningElement {
     value = '01';
     userLocationFields='Branch_Location_Number__c';
    get options() {
        return [
            { label: '01', value: '01' },
            { label: '02', value: '02' },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
    }


}