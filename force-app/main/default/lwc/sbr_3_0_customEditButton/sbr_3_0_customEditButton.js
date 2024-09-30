import { LightningElement,api,wire} from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import Status from "@salesforce/schema/Order.Status";
import RT from "@salesforce/schema/Order.RecordType.Name";
import Order from '@salesforce/schema/Order';
const FIELDS = [Status,RT];
import { NavigationMixin } from "lightning/navigation";

export default class Sbr_3_0_customEditButton extends NavigationMixin(LightningElement) {
    @api recordId; // The Id of the record you want to edit
    @api prop1 = '';
    showEdit=false;
    status;
    RT;

    

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    customerRecord({data, error}){
        if (data) {
            this.status = data.fields.Status.value;
            console.log('Payload***  ',JSON.parse(JSON.stringify(data)));
            this.RT=data.fields.RecordType.displayValue;
            if((this.RT=='Reservation Order')&&(this.status=='Draft' || this.status=='Created'  || this.status=='Partially Filled' || this.status=='Open')){
                this.showEdit=true;
               
            }
            else{
                this.showEdit=false;

            }
            
        } else if (error) {
        }
    };

    handleEditClick() {
        // Use the lightning-record-edit-form to enable editing of the record
        console.log('Edit Clicked');
        this[NavigationMixin.Navigate]({
    type: 'standard__recordPage',
    attributes: {
        recordId: this.recordId, // pass the record id here.
        actionName: 'edit',
    },
});
    }

/*
stickyMargin;
contentPadding = 'padding-top:10px;'
    renderedCallback()
    {
        try{

            window.onscroll = () => {

                let stickySection = this.template.querySelector('.stickyHeader');
                let sticky2 = stickySection.offsetTop;
                if(window.pageYOffset > sticky2)
                {
                    stickySection.classList.add('slds-is-fixed');
                this.stickyMargin = 'margin-top:90px';
                this.contentPadding = 'padding-top:102px';
                }
                else{

                      stickySection.classList.remove('slds-is-fixed');
                this.stickyMargin = '';
                this.contentPadding = 'padding-top:10px';
                }

            }
        }
        catch(error)
        {
            alert(error);
        }
    }
*/
}