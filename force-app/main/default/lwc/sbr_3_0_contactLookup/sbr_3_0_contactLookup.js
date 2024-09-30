import { LightningElement,api} from 'lwc';

import getContact from '@salesforce/apex/SBR_3_0_ContactDA.getContactById';
import getAppName from "@salesforce/apex/SBR_3_0_CustomLookupController.getAppName";//FRONT-11400


export default class Sbr_3_0_contactLookup extends LightningElement {

    // public properties with initial default values 
    @api label = 'Custom Lookup Label';
    @api placeholder = 'search...'; 
    @api iconName = 'standard:contact';
    @api sObjectApiName = 'Contact';
    @api fieldsToInclude = '';
    @api hasCustomNameField = false;
    @api customNameField = '';
    @api fieldsToSet = '';

    @api recordId = '';
    @api whereClause = '';

    @api isAccountLookup = false;
    @api displayLocationDetails = false;

    @api phoneLabel = '';
    @api phone = '';

    //START: FRONT-11400
    showNewContactButton = false;
    @api accountId = '';
    parentCmp = 'contactLookupCmp';
    //END: FRONT-11400







    handleOrderedByChange(event){

        if(event.detail.selectedRecord !== undefined) {
            this.recordId = event.detail.selectedRecord.id;
            console.log('Selected Contact: ', this.recordId);
            this.fetchPhoneValue();
        }
        else {
            this.orderedBy = '';
            this.contactId = '';
        }
    }

    fetchPhoneValue(){
        if(this.recordId !== undefined) {
            getContact({id : this.recordId})
            .then(result => {
                    console.log('result below:');
                    console.log(result);
                    if(result.MobilePhone) {
                    this.phone = result.MobilePhone.replace(/[^\w]/gi, '');
                        console.log('return mobile ->', this.phone);
                    }
                else if(result.Phone){
                    this.phone = result.Phone.replace(/[^\w]/gi, '');
                    console.log('return Phone ->', this.phone);
                    }
            })
            .catch(error => {
                console.log('Error: '+ error.body.message);
            });

        }
        else {
            this.orderedBy = '';
            this.contactId = '';
        }
    }

    handlePhoneChange(event){
        this.phone = event.target.value;
    } 

    @api
    validate() {
        if(this.recordId && this.phone && this.phone.match("^[0-9]{10}$")) {
            return { isValid: true };
        }
        else {
            // If the component is invalid, return the isValid parameter
            // as false and return an error message.
            return {
                isValid: false,
                errorMessage: 'Please enter valid phone number'
            };
        }
    }

    get phoneVal() {
        console.log('getting phoneVal');
        console.log(this.phone);
        return this.phone;
    }

    //START: FRONT-11400
    connectedCallback() {   
        getAppName()
          .then((results) => {
	    this.fetchPhoneValue();
            if (results === "RAE Frontline") {
              this.showNewContactButton = true;
            }	    
          })
          .catch((error) => {
            console.log("error");
          });	    
      }
    //END: FRONT-11400
}