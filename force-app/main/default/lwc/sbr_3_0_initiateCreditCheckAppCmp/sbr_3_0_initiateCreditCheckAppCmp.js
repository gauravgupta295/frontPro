import { LightningElement,wire,api } from 'lwc';
import getContacts from '@salesforce/apex/SBR_3_0_ContactDA.getContactsWithAccId';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import accRecIdFld from '@salesforce/schema/Account.Id'
import accCreditApplicationLinkFld from '@salesforce/schema/Account.Credit_Application_Link__c';
import accEmailFld from '@salesforce/schema/Account.E_mail_Address__c';
import accStatusField from '@salesforce/schema/Account.Sales_Activity_Status__c';

export default class Sbr_3_0_initiateCreditCheckAppCmp extends LightningElement {

    // Default values
    @api recordId;
    addContactDefaultvalue;
    bodyDefaultValue;
    subjectDefaultValue="Sunbelt Rentals Credit Application";
    bccDefaultValue="noreply@sunbeltrentals.com";
    options=[];
    labelTo="To:";
    labelCombobox="Add Contact Email";
    placeholderCombobox="Select contact email to be added";
    disableCombobox;
    errorToAndAddContactMessage="To or Contact email is required."
    defaultValueTo;
    refreshPage=true;

    get defaultValueTo(){
        return this.defaultValueTo;
    }

    // Getting account fileds to display on component
    @wire(getRecord ,{recordId:'$recordId', fields: [accRecIdFld,accCreditApplicationLinkFld,accEmailFld,accStatusField]})
    accDetails({error, data}) {
        if (data) {
            this.accId=data.fields.Id.value;
            // To Deafult value 
            this.defaultValueTo=data.fields.E_mail_Address__c.value;
            getContacts({accountId:this.accId}).then(res=>{
                //console.log(JSON.stringify(res));
                let tempOpts=[];
                let tempOptsEmail=[];
                
                // Disable combobox if there is no related contact
                if(JSON.stringify(res)=="[]"){
                    this.disableCombobox=true;
                }

                if(JSON.stringify(res)!="[]"){
                    for(let opts in res ){
                        // Check for undefined email or no email in contact
                        if(res[opts].Email!=undefined){
                            tempOpts.push({
                                label:res[opts].Name+" <"+res[opts].Email+">",
                                value:res[opts].Email
                                });
                            tempOptsEmail.push(res[opts].Email);
                        }
                    }
                    this.options=tempOpts;
                    // Add Contact default value
                    //this.addContactDefaultvalue=this.options[0].value;
                }  
            })
           console.log('data: ', data);
           
           //this.bodyDefaultValue= '<p>Please use the included link to complete your credit application:</p><br/><a href='+data.fields.Credit_Application_Link__c.value+'+target="_blank">'+data.fields.Credit_Application_Link__c.value+'</a>';
          
           
        }  else if (error) {
            console.log('error in getRecord: ', error) ;
        }
    
    }



}