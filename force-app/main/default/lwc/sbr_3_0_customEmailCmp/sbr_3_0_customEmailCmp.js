import { LightningElement,api,wire,track } from 'lwc';
import sendEmail from '@salesforce/apex/SBR_3_0_API_SendgridService.invokeSendgridAPI';
import { getRecord, updateRecord} from 'lightning/uiRecordApi';
import userNameFld from '@salesforce/schema/User.Name';
import userEmailFld from '@salesforce/schema/User.Email';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import accStatusField from '@salesforce/schema/Account.Sales_Activity_Status__c';
import accRecIdField from '@salesforce/schema/Account.Id';
import { RefreshEvent } from 'lightning/refresh';
import creditAppForm from "@salesforce/resourceUrl/CreditApplicationForm";


export default class Sbr_3_0_customEmailCmp extends LightningElement {
    
  
  
  // Default values
    placeholderText='You can add some personalized text'
  @api addContactDefaultvalue;
  @api bodyDefaultValue = "";
  @api subjectDefaultValue = "";
  @api bccDefaultValue = "";
  @api options = [];
  @api defaultValueTo;
  @api recId;
  // Label,Placeholders ,error messages and Spinner
  @api labelTo;
  @api labelCombobox;
  @api placeholderCombobox;
  @api disableCombobox;
  @api errorToAndAddContactMessage;
  @api isSpinner = false;
  @api refreshPage = false;
  creditApplicationForm = creditAppForm;

  // User
  userEmail;
  userName;
  // Email fileds
  toAddress = [];
  subject;
  body;
  addContact;
  bcc;
  from;
  selectedValues = [];
  // Errors
  errorSubjectRequired = false;
  errorBodyRequired = false;
  errorToAndAddContact = false;
  errorToEmailInvalid = false;
  defaultToValueErased = false;

  


  @wire(getRecord, { recordId: Id, fields: [userNameFld, userEmailFld] })
  userDetails({ error, data }) {

    if (data) {
            console.log('data: ', data);
            console.log("data.fields.Name.value "+data.fields.Name.value);
            console.log("data.fields.Email.value "+data.fields.Email.value);
      this.userName = data.fields.Name.value;
      this.userEmail = data.fields.Email.value;
            
    } else if (error) {
            console.log(error)
    }
  }

  connectedCallback() {
    // Assign default value to variables for validation
    this.subject = this.subjectDefaultValue;
    //this.addContact=this.addContactDefaultvalue;
    this.bcc = this.bccDefaultValue;
    this.from = this.userEmail;
    
  }

  handleChangeContact(event) {
    //this.addContact =event.detail.value;
        this.template.querySelector('c-sbr_3_0_custom-email-cmp-to-input').addContactEmailAsToEmail(event.detail.value);
        this.template.querySelector('lightning-combobox').value="";
        console.log("contact email:"+event.detail.value);
    
  }

  handleToAddressChange(event) {
    this.toAddress = event.detail.selectedValues;

    console.log("this.toAddress-->" + JSON.stringify(this.toAddress));
  }

  handleSubjectChnage(event) {
    this.subject = event.detail.value;
  }

  handleBodyChange(event) {
    this.body = event.detail.value;
    
    let bodyString = JSON.stringify(event.detail);
    //console.log("body String"+ bodyString);
    if (bodyString == '{"value":""}') {
      this.body = "";
      this.bodyDefaultValue = "";
    }
  }

  handleRemove(event) {
    if (event.detail.selecteValues != undefined) {
      this.toAddress = event.detail.selecteValues;
    }
    if (event.detail.removedItem == this.defaultValueTo) {
      this.defaultValueTo = undefined;
      this.defaultToValueErased = true;
    }
    if (this.addContact == event.detail.removedItem) {
      this.addContact = "";
    }
    
  }

  async validateAndSendEmail() {
    let allValidationDoneWithNoErrors = true;

    

    // Subject required Validation

        if(this.subject == undefined || this.subject=="" || this.subject==null){
      this.errorSubjectRequired = true;
      allValidationDoneWithNoErrors = false;
    } else {
      this.errorSubjectRequired = false;
    }

    //  Contact and To address required validation


        if((this.toAddress.length==0 || this.toAddress[0]==undefined || this.toAddress[0]==null) && (this.defaultValueTo==undefined || this.defaultValueTo==null || this.defaultValueTo=="")
    ) {
      this.errorToAndAddContact = true;
      
      this.errorToEmailInvalid = false;
      allValidationDoneWithNoErrors = false;
    } else {
      this.errorToAndAddContact = false;
    }

    // To email validation in

         const emailRegex=/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    // Note : Not checking email validation at contact level as they already validated from SF UI before saving contact
    /* Note : 
           - Default email coming from account is also validated from SF UI before saving account record.
           - Only email entered by use in Send email component is validate.
         */

    if (this.toAddress != undefined && this.errorToAndAddContact == false) {
      let allEmailValid = true;
      for (let email in this.toAddress) {
        let emailOne = this.toAddress[email];
        if (!String(emailOne).match(emailRegex)) {
          allEmailValid = false;
        }
      }
      if (allEmailValid == false) {
        this.errorToEmailInvalid = true;
        
        allValidationDoneWithNoErrors = false;
      } else {
        this.errorToEmailInvalid = false;
      }
    }

    /********* SEND EMAIL ********/

    if (allValidationDoneWithNoErrors == true) {
      this.isSpinner = true;

      // Default or input value from user
      let tempAdd = [];

      if (this.toAddress.length == 0 && this.defaultToValueErased == false) {
        // Null checks
        if (this.defaultValueTo != null) {
          tempAdd.push(this.defaultValueTo);
          this.toAddress = tempAdd;
        }
      } else if (this.toAddress != 0 && this.defaultToValueErased == false) {
        // Null checks
        if (this.defaultValueTo != null) {
          tempAdd.push(this.defaultValueTo);
          tempAdd = tempAdd.concat(this.toAddress);
          this.toAddress = tempAdd;
        }
      } else if (this.toAddress != 0 && this.defaultToValueErased == true) {
        tempAdd = tempAdd.concat(this.toAddress);
        this.toAddress = tempAdd;
      }

      this.bodyDefaultValue = "";
      this.body = this.body != undefined ? this.body : this.bodyDefaultValue;
      /*this.addContact=this.addContact!=undefined?this.addContact
                    :this.addContactDefaultvalue;*/

      // Insert rich text image as document in salesforce
      let modifiedBody;
                    const div = document.createElement('div')
      div.innerHTML = this.body;
                    this.body = this.body.replace(/<[^>]*>/g, '');
                    console.log('this.toAddress1-->'+JSON.stringify(this.toAddress));
      let bccList = [];
                    bccList.push(this.bcc)

      let emailDetailsToSent = {
        addContact: this.addContact,
        toAddress: this.toAddress,
        frm: this.userEmail,
        bcc: bccList,
        subject: this.subject,
        body: this.body,
        recId: this.recId,
        frmName: this.userName
      };

      // Send email apex method call

                        sendEmail({ emailStr:JSON.stringify(emailDetailsToSent)}).then(()=>{
                          
          const evt = new ShowToastEvent({
            title: "Email Sent Succesfully! ",
                                variant:"success",
          });
          this.dispatchEvent(evt);
          if (this.refreshPage == true) {
            this.refreshCmp();
          } else {
            this.stopSpinner();
          }
                        }).catch((error)=>{
                            console.log("Error: "+JSON.stringify(error));
          const evt = new ShowToastEvent({
                                title: 'Error',
            variant: "error",
            message: error.body.message
          });
          this.dispatchEvent(evt);
        });
                        this.body='';                      
      this.toAddress = [];
      if (this.defaultValueTo) {
        this.toAddress.push(this.defaultValueTo);
      }

      this.updateActivityStatus();
    }
  }

  updateActivityStatus() {
    const fields = {};
    fields[accRecIdField.fieldApiName] = this.recId;
    fields[accStatusField.fieldApiName] = 'Credit App Sent';

    const recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        if (this.refreshPage == true) {
          this.refreshCmp();
        } else {
          this.stopSpinner();
        }
      })
        .catch(error => {
        this.dispatchEvent(
          new ShowToastEvent({
                    title: 'Error updating activity status',
            message: error.body.message,
                    variant: 'error'
          })
        );
      });
  }

  refreshCmp() {
    setTimeout(() => {
      this.dispatchEvent(new RefreshEvent());
    }, 2000);
    this.stopSpinner();
  }

  stopSpinner() {
    setTimeout(() => {
      this.isSpinner = false;
    }, 2000);
  }
  /*Added as part of FRONT-12389*/
  get ariaLabelEmailFromValue() {
    return `From: ${this.userEmail}`;
  }

  get mailToUserEmailFromValue() {
    return `mailto:${this.userEmail}`;
  }

  get ariaLabelBccValue(){
    return `Bcc: ${this.bccDefaultValue}`;
  }
  get mailToUserEmailBccValue() {
    return `mailto:${this.bccDefaultValue}`;
  }
  /*FRONT-12389 Ends*/
}