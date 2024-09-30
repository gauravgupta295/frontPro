import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import INTORDER_OBJECT from "@salesforce/schema/Internal_Order__c";
//import TRANSFER_FROM_FIELD from '@salesforce/schema/Internal_Order__c.Sending_Branch__c';
//import TRANSFER_DATE_FIELD from '@salesforce/schema/Internal_Order__c.Transfer_Start_Date__c';
import TRANSFER_NUMBER_FIELD from "@salesforce/schema/Internal_Order__c.Name";
import NOTES_FIELD from "@salesforce/schema/Internal_Order__c.Notes__c";
import STATUS from "@salesforce/schema/Internal_Order__c.Status__c"; 
import SENDING_BRANCH from "@salesforce/schema/Internal_Order__c.Sending_Branch__c";
import PERMANENT_TRANSFER from "@salesforce/schema/Internal_Order__c.Permanent_Transfer__c";
import TRANSFER_DATE from "@salesforce/schema/Internal_Order__c.Transfer_Date__c";
import RECEIVING_BRANCH from "@salesforce/schema/Internal_Order__c.Receiving_Branch__c";
import REQUESTED_BY from "@salesforce/schema/Internal_Order__c.Requested_By__c";
import SENDING_REP_UL from "@salesforce/schema/Internal_Order__c.Sending_Rep_User_Location__c";
import RECEIVING_REP_UL from "@salesforce/schema/Internal_Order__c.Receiving_Rep_User_Location__c";
import REQUESTED_BY_UL from "@salesforce/schema/Internal_Order__c.Requested_By_User_Location__c";
import RECREPNAME from "@salesforce/schema/Internal_Order__c.Receiving_Rep_User_Location__r.Sales_Rep_Name__c";
import RECBRANCHNAME from "@salesforce/schema/Internal_Order__c.Receiving_Branch__r.Branch_Location_Name__c"

import FORM_FACTOR from "@salesforce/client/formFactor";


import getLoggedInUserLocation from '@salesforce/apex/SBR_3_0_Create_Inventory_Transfer_Cntr.getLoggedInUserLocation';
import UserId from "@salesforce/user/Id";
import TIME_ZONE from "@salesforce/i18n/timeZone";


export default class Sbr_3_0_Inventory_Trasfer_Details extends LightningElement {
    isOpen = false;
    @api recordId;
    transferFrom;
    transferDate;
    recRep;
    recRepName;
    name;
    notes;
    isMobileDevice = false;

    permTransfer;

    transferToLocationId;
    requestedById;
    requestedByUL;
    userId = UserId;

    userTimeZone = TIME_ZONE;
    startDate;
    startTime;
    startDateTime;
    mobileStartDateTime;
    mobileDate;
    mobileTime;


    blankStr = '';
    transferToName;

    hasCustomNameField = true;
    customNameField = "Sales_Rep_Name__c"; 
    orderByWhereClause = 'branch__c = \'' + this.blankStr + '\'';

    userLocationNumber = '';
    userLocationId = '';
    sendingRepUL ='';
    value = '';


    @wire(getRecord, { recordId: '$recordId', fields: [TRANSFER_NUMBER_FIELD, NOTES_FIELD, RECEIVING_REP_UL, TRANSFER_DATE, PERMANENT_TRANSFER, RECEIVING_BRANCH, RECBRANCHNAME, RECREPNAME] })
    wiredInternalOrdersRecord({ error, data }) {
        if (data) {
            this.name = data.fields.Name.value;
            this.notes = data.fields.Notes__c.value;
            this.recRep = data.fields.Receiving_Rep_User_Location__c.value;
            this.startDateTime = data.fields.Transfer_Date__c.displayValue;
            this.permTransfer = data.fields.Permanent_Transfer__c.value;
            this.transferToLocationId = data.fields.Receiving_Branch__c.value;
            this.transferToName = data.fields.Receiving_Branch__r.displayValue;
            this.startDate = this.startDateTime.split(', ')[0];
            this.startTime = this.startDateTime.split(', ')[1];

          
            this.toggleSection();
            this.mergeDateTimeMobileValue();
            this.splitMobileDateTimeValue();
            this.getorderedByWhere();

            

        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    mergeDateTimeMobileValue(){
        this.mobileStartDateTime = this.startDate+ 'T' + "00:00:00.000" + 'Z';
        if(this.startTime){
            this.mobileStartDateTime = this.startDate+ 'T' + this.startTime + 'Z';
        }
    }
    splitMobileDateTimeValue(){
        this.textDate = this.mobileStartDateTime.split('T')[0];
        this.day = this.textDate.split('/')[1];
        this.month = this.textDate.split('/')[0];
        this.year = this.textDate.split('/')[2];
        if(this.day.length ===1){
            this.day = '0'+this.day;
        }
        if(this.month.length ===1){
            this.month = '0'+this.month;
        }

        this.mobileDate = this.year +'-' + this.month +'-'+ this.day;

        this.textTime = this.mobileStartDateTime.split('T')[1];
        this.meridian = this.textTime.split(' ')[1][0];
        this.hour = this.textTime.split(':')[0];
        this.minute = this.textTime.split(':')[1];
        this.minute = this.minute.split(' ')[0];
        if (this.meridian === 'P'){
            this.num = parseInt(this.hour);
            this.hour = (this.num + 12).toString();
        }   
        this.mobileTime = this.hour + ':' + this.minute + ':00.000Z';
    }

    handleChange(event) {
       
             this.value = event.detail.value;
     }     





    get options() {
        return [
            { label: 'Permanent', value: 'Permanent' },
            { label: 'Temporary', value: 'Temporary' },
            
        ];
    }

    //handle date or time changes
  
    handleMobileDateChange(event){
        this.mobileDate = event.target.value;
        this.mergeDateTimeMobileValue();
    }
    handleMobileTimeChange(event){
        this.mobileTime = event.target.value;
        this.mergeDateTimeMobileValue();
    }
    

    mergeDateTimeDisplayValue(){
        this.startDateTime = this.startDate+', '+ this.startTime;
    }

    handleDesktopDateChange(event){
        this.startDate = event.target.value;
        this.mergeDateTimeDisplayValue();
    }

    handleDesktopTimeChange(event){
        this.startTime = event.target.value;
        this.mergeDateTimeDisplayValue();
    }


    toggleSection() {
        this.isOpen = !this.isOpen;
    }

    getorderedByWhere() {
        let blankStr = '';
        this.orderByWhereClause = 'branch__c = \'' + blankStr + '\'';
           if ( this.transferToLocationId ) {
               this.orderByWhereClause = 'branch__c = \'' + this.transferToLocationId + '\'';
           }
       }

       handleOrderByselection(event){
        if(event.detail.selectedRecord !== undefined && event.detail.selectedRecord !== '' && 
            event.detail.selectedRecord.User__c !== undefined && event.detail.selectedRecord.User__c !== ''){
            this.requestedById = event.detail.selectedRecord.User__c;
            this.requestedByUL = event.detail.selectedRecord.Id;
        }else{
            this.requestedById = '';
            this.requestedByUL = '';
        }
      
    }
       handlePickupBranch(event) {
        if(event.detail.selectedRecord !== undefined && event.detail.selectedRecord !== '' && 
            event.detail.selectedRecord.Id !== undefined && event.detail.selectedRecord.Id !== ''){
            this.transferToLocationId = event.detail.selectedRecord.Id;
        }else{
            this.transferToLocationId = '';
            this.template.querySelector('c-sbr_3_0_-inventory-transfer-order-by-lookup').handleRemove();
        }
        this.getorderedByWhere();
  
    }

   
       
    
    

    connectedCallback() {
        this.getUserLocationData();
        this.validateTypeOfDevice();
    
    }

    getUserLocationData(){
        getLoggedInUserLocation({userId: this.userId})
        .then((data) =>{
            this.userLocationNumber = data.locationNumber;
            this.userLocationId = data.locationID;
            this.sendingRepUL = data.Id;
        })
        .catch((error)=>{
            console.log('getinitRecord Error —> ' + JSON.stringify(error));
        });
    }

    handleSave() {
        const fields = {};
        //fields[TRANSFER_FROM_FIELD.fieldApiName] = this.transferFrom;
        //fields[TRANSFER_DATE_FIELD.fieldApiName] = this.transferDate;

        const recordInput = { fields, id: this.recordId };
        updateRecord(recordInput)
            .then(() => {
                // Record is updated successfully
                // You may want to show a success message or refresh the record page
            })
            .catch(error => {
                console.error('Error updating record', error);
            });
    }

    handleOrderByselection(event){
        if(event.detail.selectedRecord !== undefined && event.detail.selectedRecord !== '' && 
            event.detail.selectedRecord.User__c !== undefined && event.detail.selectedRecord.User__c !== ''){
            this.requestedById = event.detail.selectedRecord.User__c;
            this.requestedByUL = event.detail.selectedRecord.Id;
        }else{
            this.requestedById = '';
            this.requestedByUL = '';
        }
     
    }

    validateTypeOfDevice(){
        if(FORM_FACTOR === 'Small'){
            this.isMobileDevice = true;
        }
    }   
}