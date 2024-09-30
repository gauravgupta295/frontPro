import { LightningElement,api,track,wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import ACCOUNTTYPE_FIELD from '@salesforce/schema/Account.RecordTypeId';
import EMAIL from '@salesforce/schema/Account.Email__c';
import getRecordTypeInfo from '@salesforce/apex/SBR_3_0_CustomLookupController.getRecordTypeInfo'
import DRIVERS_LICENSE from '@salesforce/schema/Account.Drivers_License__c';
import DRIVERS_LICENSE_STATE from '@salesforce/schema/Account.Driver_s_License_State__c';
import ADDITIONAL_COMMENTS from '@salesforce/schema/Account.Additional_Comment__c';
import { createRecord } from 'lightning/uiRecordApi';
import POSTAL_CODE from '@salesforce/schema/Account.BillingPostalCode';
import CITY from '@salesforce/schema/Account.BillingCity';
import COUNTRY from '@salesforce/schema/Account.BillingCountry';
import PROVINCE from '@salesforce/schema/Account.BillingState';
import BILLING_STREET from '@salesforce/schema/Account.BillingStreet';
import BILLING_ADDRESS from '@salesforce/schema/Account.BillingAddress';
import COUNTRY_CODE from '@salesforce/schema/Account.BillingCountryCode';
import STATE_CODE from '@salesforce/schema/Account.BillingStateCode';
import BIRTH_DATE from '@salesforce/schema/Account.BirthDate__c';
import DESCRIPTION from '@salesforce/schema/Account.Comments__c';

export default class Sbr_3_0_nonCreditAccountCreateMobilePg extends LightningElement {
    @track modalHeader = 'New Account: Non-Credit';
    @api isFormOpen = false;
    @track name;
    @track accountType = ACCOUNTTYPE_FIELD;
    @track objectApiNameForForm ='Account';
    @track phone;
    @track email;
    @track driversLicense;
    @track driversLicenseState;
    @track comments;
    @track zipcode;
    @track street;
    @track city;
    @track country;
    @track state;
    @api recordtypeid;
    @track dob;
    @track description;
    @track country = 'US';
    @track isNonCreditRecordType = false;
    @track description;
    @track showLoading =false;
    @track selectedRecordId;
    accountId;
    isMobile = false;
    disabled = false;


    closeModal() {
        const closeModal = new CustomEvent('closemodal',{isModalOpen: false}); 
        this.dispatchEvent(closeModal)
    }


    countryProvinceMap= {
        US:[
        {value :"AL" ,label: "AL"},
        {value :"AK" ,label:"AK"},
        {value :"AZ" ,label:"AZ"},
        {value :"AR" ,label:"AR"},
        {value :"CA" ,label:"CA"},
        {value :"CO" ,label:"CO"},
        {value :"CT",label:"CT"},
        {value :"DE",label:"DE"},
        {value :"DC", label: "DC"},
        {value :"FL",label:"FL"},
        {value :"GA",label:"GA"},
        {value :"HI",label:"HI"},
        {value :"ID",label:"ID"},
        {value :"IL",label:"IL"},
        {value :"IN",label:"IN"},
        {value :"IA",label:"IA"},
        {value :"KS",label:"KS"},
        {value :"KY",label:"KY"},
        {value :"LA",label:"LA"},
        {value :"ME",label:"ME"},
        {value :"MD",label:"MD"},
        {value :"MA",label:"MA"},
        {value :"MI",label:"MI"},
        {value :"MN",label:"MN"},
        {value :"MS",label:"MS"},
        {value :"MO",label:"MO"},
        {value :"MT",label:"MT"},
        {value :"NE",label:"NE"},
        {value :"NV",label:"NV"},
        {value :"NH",label:"NH"},
        {value :"NJ",label:"NJ"},
        {value :"NM",label:"NM"},
        {value :"NY",label:"NY"},
        {value :"NC",label:"NC"},
        {value :"ND",label:"ND"},
        {value :"OH",label:"OH"},
        {value :"OK",label:"OK"},
        {value :"OR",label:"OR"},
        {value :"PA",label:"PA"},
        {value :"RI",label:"RI"},
        {value :"SC",label:"SC"},
        {value :"SD",label:"SD"},
        {value :"TN",label:"TN"},
        {value :"TX",label:"TX"},
        {value :"UT",label:"UT"},
        {value :"VT",label:"VT"},
        {value :"VA",label:"VA"},
        {value :"WA",label:"WA"},
        {value :"WV",label:"WV"},
        {value :"WI",label:"WI"},
        {value :"WY",label:"WY"}
        ],
    CA: [
        {value:'AB', label:'AB'},
        {value:'BC', label:'BC'},
        {value:'MB', label:'MB'},
        {value:'NB', label:'NB'},
        {value:'NL', label:'NL'},
        {value:'NS', label:'NS'},
        {value:'NT', label:'NT'},
        {value:'NU', label:'NU'},
        {value:'ON', label:'ON'},
        {value:'PE', label:'PE'},
        {value:'QC', label:'QC'},
        {value:'SK', label:'SK'},
        {value:'YT', label:'YT'}
    ]};

        countryOptions = [ 
            {value:'US', label:'United States'},
            {value:'CA',label:'Canada'}
        ];

        get getProvinceOptions() {
            return this.countryProvinceMap[this.country];
        }
        get getCountryOptions() {
            return this.countryOptions;
        }

    nameChange(event){
        this.name = event.detail.value;
        this.accountId = undefined;
    }

    phoneChange(event){
        this.phone = event.detail.value;
    }

    stateChange(event){
        this.driversLicenseState = event.detail.value;
    }
    emailChange(event){
        this.email = event.detail.value;
    }
    licenseChange(event){
        this.driversLicense = event.detail.value;
    }
    commentChange(event){
        this.description = event.detail.value;
    }

    genericInputChange(event){
        console.log(event.target);
        this.street = event.target.street;
        this.state = event.target.province;
        this.zipcode = event.target.postalCode;
        this.country = event.target.country;
        this.city = event.target.city;
        console.log('Counttry', event.target.country);
        console.log("province", event.target.province);
        console.log("postalcode", event.target.postalCode);
       /*  to make country
        let key = this.statecodeData.controllerValues[event.target.country];
        console.log('key',key);
        this.statecodeoptions = this.statecodeData.values.filter(opt => opt.validFor.includes(key));
        console.log('stateOptions Now:', this.stateOptions); */

    }

    disableButton() {
        this.disabled = true;
      }

      birthDateChange(event){
        this.dob = event.detail.value;
    }

      validateFields(){

        if(this.name == undefined || this.phone == undefined || this.email == undefined || this.driversLicense == undefined || this.driversLicenseState == undefined || this.dob == undefined)
        {
            return true;
        }
        else if(this.street == undefined || this.city == undefined || this.country == undefined || this.state== undefined || this.zipcode == undefined)
        {
            return true;
        }
        else if(this.dob.length > 1){
            let datepart = this.dob.split('-');
            console.log(datepart);
            let yearEntered = parseInt(datepart[0]);
            let today = new Date();
            today=today.toISOString().slice(0, 10);
            let currentYear = today.split('-');
            currentYear=parseInt(datepart[0]);
            if ( yearEntered < 1950 || yearEntered > currentYear){
                this.displayError('Date of Birth Validation','Date has to be from 1950s to current year.');
                this.noError=true;
               
            }
            else if(this.dob>today){
                this.displayError('Date of Birth Validation','Date must be '+today+' or earlier.');
                this.noError=true;
            }
            else{
                this.noError=false;
            }
        }
        
        else return false;
    }

    /* handleSuccess(event){
       
        if(this.validateFields()){
            const newEvent  = new ShowToastEvent(
                {
                    title: 'Required Fields missing.',
                    message: 'Please complete all address fields.',
                    variant: 'error'
                }
            );
            this.dispatchEvent(newEvent);

        }
        else{
            console.log("inside handlesuccess");
        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.name;
        fields[PHONE_FIELD.fieldApiName] = this.phone;
        fields[ACCOUNTTYPE_FIELD.fieldApiName] = this.recordtypeid;
        fields[EMAIL.fieldApiName] = this.email;
        fields[DRIVERS_LICENSE.fieldApiName]=this.driversLicense;
        fields[DRIVERS_LICENSE_STATE.fieldApiName] = this.driversLicenseState;
        fields[ADDITIONAL_COMMENTS.fieldApiName] = this.comments;
        fields[BILLING_STREET.fieldApiName] = this.street;
        fields[CITY.fieldApiName]= this.city;
        //fields[COUNTRY.fieldApiName] = this.country;
        fields[POSTAL_CODE.fieldApiName] = this.zipcode;
        //fields[PROVINCE.fieldApiName] = this.state;
        fields[COUNTRY_CODE.fieldApiName] = this.country;
        fields[STATE_CODE.fieldApiName] = this.state;
        /* fields[BILLING_ADDRESS.fieldApiName] = {
            "city": this.city,
            "country": this.country,
            "geocodeAccuracy": null,
            "latitude": null,
            "longitude": null,
            "postalCode": this.zipcode,
            "state": this.state,
            "street": this.street
          } */
        /* this.disableButton();
        console.log("fields:",fields);
        const recordInput = { apiName: this.objectApiNameForForm, fields };

        

        createRecord(recordInput)
            .then(account => {
                //console.log(account)
                this.accountId = account.id;
                const cEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'Account created',
                        variant: 'success'
                    });
                this.dispatchEvent(cEvent);
                console.log("inside create record success",this.accountId);
                this.closeModal();
            })
            .catch(error => {
                console.log(error)
                const cEvent = new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    });
                this.dispatchEvent(cEvent);
            });
        }
        
    } */ 

    handleSuccess(event){
        //this.template.querySelector('lightning-record-form').submit(fields);
        if(this.validateFields()){
            /*const newEvent  = new ShowToastEvent(
                {
                    title: 'Required Fields missing.',
                    message: 'Please complete all the required fields.',
                    variant: 'error'
                }
            );
            this.dispatchEvent(newEvent);*/
            this.displayError('Required Fields missing.','Please complete all the required fields.');
        }
        else{
            console.log("inside handlesuccess");
            
            if(!this.noError){
            this.showLoading=true;
            }
        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.name;
        fields[PHONE_FIELD.fieldApiName] = this.phone;
        fields[ACCOUNTTYPE_FIELD.fieldApiName] = this.recordtypeid;
        fields[EMAIL.fieldApiName] = this.email;
        fields[DRIVERS_LICENSE.fieldApiName]=this.driversLicense;
        fields[DRIVERS_LICENSE_STATE.fieldApiName] = this.driversLicenseState;
        //fields[ADDITIONAL_COMMENTS.fieldApiName] = this.comments;
        fields[BILLING_STREET.fieldApiName] = this.street;
        fields[CITY.fieldApiName]= this.city;
        fields[POSTAL_CODE.fieldApiName] = this.zipcode;
        fields[COUNTRY_CODE.fieldApiName] = this.country;
        fields[STATE_CODE.fieldApiName] = this.state;
        fields[DESCRIPTION.fieldApiName] = this.description;
        fields[BIRTH_DATE.fieldApiName] = this.dob;

        if(!this.noError){
        //this.disableButton();
        console.log("fields:",fields);
        const recordInput = { apiName: this.objectApiNameForForm, fields };

        createRecord(recordInput)
                .then(account => {
                    //console.log(account)
                    this.showLoading=false;
                    this.accountId = account.id;
                    const cEvent = new ShowToastEvent(
                        {
                            title: 'Success',
                            message: 'Account created',
                            variant: 'success',
                            bubbles: true
                        }
                    ); 
                    this.dispatchEvent(cEvent);
                    //this.disableButton();
                    console.log("inside create record success",this.accountId);
                    this.closeModal();
                })
                .catch(error => {
                    this.showLoading=false;
                    console.log(error)
                    //console.log('error body::',error.body.output.errors[0].errorCode);
                    
                    if(error.body.output.errors[0].errorCode == 'DUPLICATES_DETECTED')
                    {
                        console.log('entered::');
                        this.displayError('Duplicate Account detected.',error.body.output.errors[0].errorCode);
                    }
                    else{
                        const cEvent = new ShowToastEvent({
                            title: 'Error occured while creating a record.',
                            message: error.body.message,
                            variant: 'error'
                        })
                        this.dispatchEvent(cEvent);
                    }
                });
            }
        }
    }
    
    displayError(errortitle,msg){
        const newEvent  = new ShowToastEvent(
            {
                title: errortitle,
                message: msg,
                variant: 'error'
            }
        );
        this.dispatchEvent(newEvent);
    }
}