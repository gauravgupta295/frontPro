import { LightningElement,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import INTORDER_OBJECT from "@salesforce/schema/Internal_Order__c";
import STATUS from "@salesforce/schema/Internal_Order__c.Status__c"; 
import SENDING_BRANCH from "@salesforce/schema/Internal_Order__c.Sending_Branch__c";
import PERMANENT_TRANSFER from "@salesforce/schema/Internal_Order__c.Permanent_Transfer__c";
import TRANSFER_DATE from "@salesforce/schema/Internal_Order__c.Transfer_Date__c";
import RECEIVING_BRANCH from "@salesforce/schema/Internal_Order__c.Receiving_Branch__c";
//import REQUESTED_BY from "@salesforce/schema/Internal_Order__c.Requested_By__c";
import SENDING_REP_UL from "@salesforce/schema/Internal_Order__c.Sending_Rep_User_Location__c";
import RECEIVING_REP_UL from "@salesforce/schema/Internal_Order__c.Receiving_Rep_User_Location__c";
import REQUESTED_BY_UL from "@salesforce/schema/Internal_Order__c.Requested_By_User_Location__c";


import TIME_ZONE from "@salesforce/i18n/timeZone";

import { CloseActionScreenEvent } from 'lightning/actions';
import LABELS from "c/sbr_3_0_customLabelsCmp";
import UserId from "@salesforce/user/Id";

import getLoggedInUserLocation from '@salesforce/apex/SBR_3_0_Create_Inventory_Transfer_Cntr.getLoggedInUserLocation';

import CHECK_INV_TRF_GA_ACCESS from '@salesforce/customPermission/Create_Inventory_Transfer_using_Global_Action';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class ModalDemoInLWC extends NavigationMixin(LightningElement)  {
   
    label = LABELS;
    isDisabled ;
    userId = UserId;
    isShowModal = false;

    userLocationNumber = '';
    userLocationId = '';
    sendingRepUL ='';
    value = '';

    transferToLocationId;
    requestedById;
    requestedByUL;

    userTimeZone = TIME_ZONE;
    startDate;
    startTime;
    startDateTime;
    get options() {
        return [
            { label: 'Select one', value: '' },
            { label: 'Permanent', value: 'Permanent' },
            { label: 'Temporary', value: 'Temporary' },
            
        ];
    }
    blankStr = '';
    hasCustomNameField = true;
    customNameField = "Sales_Rep_Name__c"; 
    orderByWhereClause = 'branch__c = \'' + this.blankStr + '\'';
    isMobileDevice = false; //Added for FRONT-17752 PC to PC Transfer
    modalSize = ""; //Added for FRONT-17752 PC to PC Transfer
    handleChange(event) {
       /* var inputCmp = this.template.querySelector(".transferStatusCombo");
        console.log('inputCmp'+ JSON.stringify(inputCmp));
        if (event.detail.value === 'Select one' ) {
          inputCmp.setCustomValidity("Complete this field.");
          inputCmp.reportValidity();
        }*/
            this.value = event.detail.value;
    }

    connectedCallback() {
        this.checkCustomPermissionAccess();
        this.getUserLocationData();
        this.validateTypeOfDevice(); //Added for FRONT-17752 PC to PC Transfer
    }

    checkCustomPermissionAccess(){
        console.log('Check Global Action Access'+CHECK_INV_TRF_GA_ACCESS);
        if(CHECK_INV_TRF_GA_ACCESS){
            this.isShowModal = true;
        }
    }
    
    getUserLocationData(){
        getLoggedInUserLocation({userId: this.userId})
        .then((data) =>{
            console.log('getinitRecord data —> ' + JSON.stringify(data));
            this.userLocationNumber = data.locationNumber;
            this.userLocationId = data.locationID;
            this.sendingRepUL = data.Id;
        })
        .catch((error)=>{
            console.log('getinitRecord Error —> ' + JSON.stringify(error));
        });
    }

    showModalBox() {  
        this.isShowModal = true;
    }

    hideModalBox() {  
        // this.closeQuickAction();
        // window.location.reload();
        //this.isShowModal = false;
        /*****added by pankaj for FRONT-23826****/       
        if(this.isMobileDevice){
            //onclick of cancel land on chatter home for mobile device
            this[NavigationMixin.Navigate]({
                type : 'standard__webPage',
                attributes : {
                    url : '/lightning/page/chatter'
                }
            });
        }else{
            //for desktop
            this.isShowModal = false;
        }
        /****end by pankaj FRONT-23826****/
        
    }

    handleSave() { 

        /*********** Start Added Null validation check for FRONT-22688 *************/
		const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        const isTransferStatusSelected = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if(!this.requestedById) // Order By Check
        this.template.querySelector('c-sbr_3_0_-inventory-transfer-order-by-lookup').handleRemove();

        if(!this.transferToLocationId) // Transfer to location Check
        this.template.querySelector('c-sbr_3_0_-inventory-transferto-lookup').handleRemove();
        /***********  End Added Null validation check for FRONT-22688 *************/

            // Check if all fields have values before performing Next operation, FRONT-22688
        if (isInputsCorrect && isTransferStatusSelected && this.requestedById && this.transferToLocationId) { 		 
			
			const fields = {};
			fields[STATUS.fieldApiName] = 'Not Yet Submitted';
			fields[SENDING_BRANCH.fieldApiName] = this.userLocationId;
			fields[PERMANENT_TRANSFER.fieldApiName] = this.value; 
			fields[TRANSFER_DATE.fieldApiName] = this.startDateTime;
			fields[RECEIVING_BRANCH.fieldApiName] = this.transferToLocationId;
			//fields[REQUESTED_BY.fieldApiName] = this.requestedById;
			fields[SENDING_REP_UL.fieldApiName] = this.sendingRepUL;
			fields[RECEIVING_REP_UL.fieldApiName] = this.requestedByUL; //PO check, Where to get this mapping detail for Receiping REP UL?
			fields[REQUESTED_BY_UL.fieldApiName] = this.requestedByUL;
			const recordInput = { apiName: INTORDER_OBJECT.objectApiName, fields };        
			//this.navigateToRecord('test');
			createRecord(recordInput)
			.then((result) => {
			   // this.isDisabled = true;
			   // this.isShowModal = false;
			   // this.closeQuickAction();
				this.navigateToRecord(result.id);
				this.isShowModal = false;
				//this.isShowModal = false;
				/*this.showToastMessage(
				"Success"+result.id,
				"Contact successfully created.",
				"success",
				"dismissable"
				)*/
			   // window.location.reload();
				
			});
			
			}
        }
        showToastMessage(title, message, variant, mode) {
            this.dispatchEvent(
              new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
              })
            );
          }
        
          navigateToRecord(recId) {            
           // recId = 'a6C8K0000009B2nUAE'
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recId,
                    objectApiName: "Internal_Order__C",
                    actionName: 'view'
                }
            });
           /*this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                  recordId: recId,
                  objectApiName: "Internal_Order__C",
                  actionName: "view"
                }
              }).then((generatedUrl) => {
                window.open(generatedUrl, "_blank");
              });*/
        }

        closeQuickAction() {            
            this.dispatchEvent(new CloseActionScreenEvent());            
        }

        isDisabled(){
            return isDisabled = false;
        }

        handleDateChange(event){
            this.startDate = event.target.value;
            this.mergeDateTime();
        }
        handleTimeChange(event){
            this.startTime = event.target.value;
            this.mergeDateTime();
        }

        mergeDateTime(){
            console.log('DateTime '+ this.startDate+ 'T' + this.startTime + 'Z');
            this.startDateTime = this.startDate+ 'T' + "00:00:00.000" + 'Z';
            if(this.startTime){
                this.startDateTime = this.startDate+ 'T' + this.startTime + 'Z';
            }
            console.log('startDateTime'+this.startDateTime);
        }
       
        handleDateTime(event){
            console.log('DateTime '+ event.target.value );
            this.startDateTime = event.target.value ;
        }

        handlePickupBranch(event) {
            console.log('Onselect record '+ event);
            if(event.detail.selectedRecord !== undefined && event.detail.selectedRecord !== '' && 
                event.detail.selectedRecord.Id !== undefined && event.detail.selectedRecord.Id !== ''){
                this.transferToLocationId = event.detail.selectedRecord.Id;
            }else{
                this.transferToLocationId = '';
                this.template.querySelector('c-sbr_3_0_-inventory-transfer-order-by-lookup').handleRemove();
            }
            this.getorderedByWhere();
            //console.log('Onselect record '+event.detail.selectedRecord.Id);
           // this.transferToLocationId = event.detail.selectedRecord.Id;
          //  this.getorderedByWhere();
        }

        handleOrderByselection(event){
            console.log('Onselect record '+ event);
            if(event.detail.selectedRecord !== undefined && event.detail.selectedRecord !== '' && 
                event.detail.selectedRecord.User__c !== undefined && event.detail.selectedRecord.User__c !== ''){
                this.requestedById = event.detail.selectedRecord.User__c;
                this.requestedByUL = event.detail.selectedRecord.Id;
            }else{
                this.requestedById = '';
                this.requestedByUL = '';
            }
           // console.log('Onselect record '+event.detail.selectedRecord.User__c);
           // this.requestedById = event.detail.selectedRecord.User__c;
        }

        getorderedByWhere() {
            let blankStr = '';
            this.orderByWhereClause = 'branch__c = \'' + blankStr + '\'';
               if ( this.transferToLocationId ) {
                   this.orderByWhereClause = 'branch__c = \'' + this.transferToLocationId + '\'';
               }
               console.log('orderByWhereClause -> ' + this.orderByWhereClause);
           }
        
        //Added for FRONT-17752 PC to PC Transfer
        validateTypeOfDevice(){
            if(FORM_FACTOR === 'Small'){
                this.isMobileDevice = true;
                this.modalSize = "slds-modal slds-fade-in-open slds-modal_full"; 
                console.log('Mobile device');
            }else{
                this.modalSize = "slds-modal slds-fade-in-open slds-modal_small"; 
            }
        }   
      
       
}