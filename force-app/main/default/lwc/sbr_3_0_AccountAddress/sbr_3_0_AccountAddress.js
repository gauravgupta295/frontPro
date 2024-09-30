import { LightningElement,api,wire,track } from 'lwc';
import { updateRecord, getRecord, getFieldValue} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ShippingStreet_FIELD from '@salesforce/schema/Account.ShippingStreet';
import ShippingState_FIELD from '@salesforce/schema/Account.ShippingState';
import ShippingCountry_FIELD from '@salesforce/schema/Account.ShippingCountry';
import ShippingPostalCode_FIELD from '@salesforce/schema/Account.ShippingPostalCode';
import ShippingCity_FIELD from '@salesforce/schema/Account.ShippingCity';


const fields = [ShippingStreet_FIELD, ShippingState_FIELD, ShippingCountry_FIELD, ShippingPostalCode_FIELD, ShippingCity_FIELD];

export default class sbr_3_0_AccountAddress extends LightningElement {
    @track ShipStreet;
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields})
    account;
  
    get ShippingStreet_Value() {
      return getFieldValue(this.account.data, ShippingStreet_FIELD);
    }
  
    get ShippingState_Value() {
      return getFieldValue(this.account.data, ShippingState_FIELD);
    }

    get ShippingCountry_Value() {
        return getFieldValue(this.account.data, ShippingCountry_FIELD);
    }
    
    get ShippingPostalCode_Value() {
        return getFieldValue(this.account.data, ShippingPostalCode_FIELD);
    }

    get ShippingCity_Value() {
        return getFieldValue(this.account.data, ShippingCity_FIELD);
    }

    handleShippingStreetChange(event) {
        this.ShipStreet = event.target.value;
    }

    handleUpdateStreetAddress()
    {
        const fields = {};
        fields[ShippingStreet_FIELD.fieldApiName] = this.ShipStreet;
        
        const recordInput = { fields:fields, recordId: this.recordId, Object: this.account};
        updateRecord(recordInput)
        .then(() => {
            this.showToast('Success', 'Shipping Address updated successfully.', 'success');
            this.resetFields();
        })
        .catch(error =>{
            this.showToast('Error', 'Error updating Shipping Address: ' + error.body.message, 'error');
                console.error('Error updating Shipping Address:', error);
        })
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    resetFields() {
        this.ShipStreet = '';
    }
}