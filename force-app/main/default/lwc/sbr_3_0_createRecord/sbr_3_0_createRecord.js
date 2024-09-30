import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';
import ContactMobile from '@salesforce/schema/Case.ContactMobile';


export default class sbr_3_0_createRecord extends LightningElement {
    
    @api recordId = '';
    @api objectApiName = 'Order';
    @api fields = [];
    @api columns = 2;
    @api recordTypeId;
    @api layoutType;
    @api nextPageOnSuccess;
    @api finishOnSuccess;
    @api previousOnCancel;
    @api fieldsToSet;
    objectFields = [];

    connectedCallback() {
        console.log(this.objectApiName);
        console.log(this.fields);
        console.log(this.columns);
        console.log(this.recordTypeId);
        console.log(this.fieldsToSet)

        if(!this.isEmpty(this.fields)){
            var str_array = this.fields.split(',');
            for(var i = 0; i < str_array.length; i++){
                let formattedStr = str_array[i].replace(/\s+/g, '');
                console.log(formattedStr);
                let fieldObj = { objectApiName: this.objectApiName, fieldApiName: formattedStr };
                this.objectFields.push(fieldObj);
            }
        }
        console.log(this.objectFields);

    }

    handleSubmit(event) {
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        fields.RecordTypeId = this.recordTypeId;
        console.log(event.detail.fields);

        console.log('fieldsToSet -> ' + this.fieldsToSet);

        if(!this.isEmpty(this.fieldsToSet)){
            var fieldValArray = this.fieldsToSet.split(',');
            fieldValArray.pop();
            console.log(fieldValArray);
            for(var i = 0; i < fieldValArray.length; i++){
                console.log('fieldValArray[i] -> ' + fieldValArray[i]);

                let formattedStr = fieldValArray[i].replace(/\s+/g, '');
                let keyValArray = formattedStr.split(':');
                let key = keyValArray[0].replace(/\s+/g, '');
                let val = keyValArray[1].replace(/\s+/g, '');
                console.log('key -> ' + key);
                console.log('val -> ' + val);
                fields[key] = val;
            }
        }

        this.template.querySelector('lightning-record-form').submit(fields);
    }

    handleSuccess(event) {
        this.recordId = event.detail.id;
        console.log('Successfully created: ' + this.recordId);
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'Record ID: ' + this.recordId,
            variant: 'success',
        });
        this.dispatchEvent(evt);

        if(this.nextPageOnSuccess) {
            console.log('going to next...');
            // go to next page
            this.handleFlowGoNext();
        }

        if(this.finishOnSuccess) {
            console.log('going to finish...');
            // go to finish
            this.handleFlowFinish();
        }
    }

    handleCancel() {
        if(this.previousOnCancel) {
            console.log('going back on cancel...');
            // go back on cancel
            this.handleFlowPrevious();
        }
    }

    handleError(event) {
        console.log('Error:');
        console.log(event);
    }

    handleFlowGoNext() {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleFlowFinish() {
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }

    handleFlowPrevious() {
        const navigateBackEvent = new FlowNavigationBackEvent();
        this.dispatchEvent(navigateBackEvent);
    }

    isEmpty(str) {
        return (!str || str.length === 0 );
    }

}