import { LightningElement, api, track, wire } from 'lwc';
import searchOriginalRequest from '@salesforce/apex/SBR_3_0_EngineeringRequestRevision.searchOriginalRequest';
import createEngReqRevision from "@salesforce/apex/SBR_3_0_EngineeringRequestRevision.cloneEngineeringRequest";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import orderSuccess from '@salesforce/label/c.ConvertToOrder_Success';

export default class Sbr_3_0_convertOrderRequestER extends NavigationMixin(LightningElement) {

    @api iconName;
    @api recordId;
    @api filter = '';
    @api searchPlaceholder='Search';
    selectedName;
    records;
    originalRequestId;
    blurTimeout;
    message;
    isDisabled = true;
    isProgressing;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';
    @wire(searchOriginalRequest, {engRequestId : '$recordId'})
    wiredRecords({ error, data }) {
        if (data) {
            console.log('@@Rec'+this.recordId);
            this.error = undefined;
            this.records = data;
            console.log('@@Rec'+this.records);
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    get length() {
        if(this.records?.length > 0) {
            this.isDisabled = false;
            return true;
        }
        else {
            return false;
        }
    }
    handleClick() {
        this.selectedName = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
       // console.log('@@@selectedName'+JSON.stringify(event.currentTarget.value));
        let selectedId = event.currentTarget.dataset.id;
        const selectedData = this.records.find( (obj) => {
            return ( obj.Id === selectedId);
          });
          
        let selectedName = selectedData.Name+' '+selectedData.Revision_Number__c;
        this.selectedName = selectedName;
        this.originalRequestId = selectedId;
        console.log('@@@selectedName'+JSON.stringify(filtered));
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    onChange(event) {
        this.selectedName = event.target.value;
    }

    convertOrderRequest() {
        this.isProgressing = true;
        console.log('this.selectedId'+this.originalRequestId);
        createEngReqRevision({engRequestId : this.recordId, originalRequestId : this.originalRequestId}).
        then(response => {
            console.log('response1'+response);
            this.isProgressing = false;
            this.message = orderSuccess;
            this.showToastMessage('', this.message, 'success', 'sticky');
          //  this.closeAction();
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: response,
                    objectApiName: 'Engineering_Request__c',
                    actionName: 'view'
                },
            });
        }).catch(error => {
            console.log('Error:'+ error.body.message);
            this.isProgressing = false;
            this.message = error.body.message;
            console.log('this.message:'+ this.message);
           this.showToastMessage('', error.body.message, 'error', 'sticky');
           this.closeAction();

        })
    }
    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToastMessage(title, message, variant, mode) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );

    }
}