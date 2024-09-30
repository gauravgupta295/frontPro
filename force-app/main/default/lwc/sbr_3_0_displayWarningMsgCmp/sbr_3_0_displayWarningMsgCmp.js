import { LightningElement, api, wire } from 'lwc';
import { getRecord,getFieldValue,notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import Quote_ACCOUNT_STATUS from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__r.Status__c";
import Quote_ACCOUNT_RECORDTYPE from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__r.Record_Type_Text__c";
import Cart_ACCOUNT_STATUS from "@salesforce/schema/Cart__c.Account__r.Status__c";
import Cart_ACCOUNT_RECORDTYPE from "@salesforce/schema/Cart__c.Account__r.Record_Type_Text__c";
import LAST_EDIT_BY_USER_NAME from "@salesforce/schema/SBQQ__Quote__c.Last_Edit_By__r.Name";  //FRONT-4532
//START: FRONT-4586,FRONT-4587
import Order_RECORDTYPE from "@salesforce/schema/Order.Record_Type_Name__c";
import ORDER_LAST_EDIT_BY_USER_NAME from "@salesforce/schema/Order.Last_Edit_By__r.Name";
//END: FRONT-4586,FRONT-4587

export default class Sbr_3_0_displayWarningMsgCmp extends LightningElement {
    @api warningMsg = '';
    @api warningHeader = '';
    @api recordId;
    accountStatus = '';
    accountRecordType = '';
    @api objectApiName;
    FIELDS = [];
     @api purpose = '';   //FRONT-4532
    
    lastEditedByUserName='';  //FRONT-4532
    error;
    //START: FRONT-4586,FRONT-4587
    orderRecordType = '';
    orderLastEditByUserName = '';
    //END: FRONT-4586,FRONT-4587

    @wire(getRecord, { recordId : '$recordId', fields: '$FIELDS'})
    wiredRecord({data }) {
        if (data) {
            if(this.objectApiName === 'SBQQ__Quote__c'){
                this.accountStatus = getFieldValue(data, Quote_ACCOUNT_STATUS); 
                this.accountRecordType = getFieldValue(data, Quote_ACCOUNT_RECORDTYPE); 
                this.lastEditedByUserName=getFieldValue(data,LAST_EDIT_BY_USER_NAME);
            }
            if(this.objectApiName === 'Cart__c'){
                this.accountStatus = getFieldValue(data, Cart_ACCOUNT_STATUS); 
                this.accountRecordType = getFieldValue(data, Cart_ACCOUNT_RECORDTYPE); 
            }
            //START: FRONT-4586,FRONT-4587
            if(this.objectApiName === 'Order'){
                this.orderRecordType = getFieldValue(data, Order_RECORDTYPE); 
                this.orderLastEditByUserName = getFieldValue(data, ORDER_LAST_EDIT_BY_USER_NAME); 
            }
            //END: FRONT-4586,FRONT-4587
        }
    }

    connectedCallback(){
        if(this.warningMsg !== '' &&  this.warningMsg != null && this.warningMsg !== undefined )
        {
            this.warningMsg = this.warningMsg.split(/[<*>]/);
        }
        //FRONT-4532 START
        if(this.warningHeader !== '' &&  this.warningHeader != null && this.warningHeader !== undefined)
        {
            this.warningHeader = this.warningHeader.split(/[<*>]/);
        }     
      
        //FRONT-4532 END
        if(this.objectApiName === 'SBQQ__Quote__c'){
            this.FIELDS = [Quote_ACCOUNT_STATUS, Quote_ACCOUNT_RECORDTYPE,LAST_EDIT_BY_USER_NAME]; //FRONT-4532 
        }
        if(this.objectApiName === 'Cart__c'){
            this.FIELDS = [Cart_ACCOUNT_STATUS, Cart_ACCOUNT_RECORDTYPE];
        }
        //START: FRONT-4586,FRONT-4587
        if(this.objectApiName === 'Order'){
            this.FIELDS = [Order_RECORDTYPE, ORDER_LAST_EDIT_BY_USER_NAME];
        }//END: FRONT-4586,FRONT-4587    
    }

    get warning(){

//FRONT-4532 START
        if(this.purpose=='Diplay Lock Message' )
        {
            return '';             
        }
        else if(this.purpose === 'Display Warning Message')
        {
            if(this.accountRecordType === 'Prospect'){
    
                return this.warningMsg[0];
            }
            else{
                return this.warningMsg[0]+this.accountStatus+this.warningMsg[2];
            }
        }
//FRONT-4532 END
    }

//FRONT-4532 START added getter dynamicHeaderMessage()
    get dynamicHeaderMessage()
    {
        if(this.purpose === 'Diplay Lock Message' && this.objectApiName === 'SBQQ__Quote__c')      
        {
            return this.warningHeader[0]+this.lastEditedByUserName+this.warningHeader[2];             
        }//added objetc condition as a aprt of FRONT-4586,FRONT-4587
        //START: FRONT-4586,FRONT-4587
        else if(this.purpose === 'Diplay Lock Message' && this.objectApiName === 'Order' && this.orderRecordType === 'Reservation Order')      
        {
            return this.warningHeader[0]+this.orderLastEditByUserName+this.warningHeader[2];             
        }//END: FRONT-4586,FRONT-4587
        else if(this.purpose === 'Display Warning Message')
        {
            if(this.accountRecordType === 'Prospect'){ 
                return this.warningHeader;
            }
            else{
                return this.warningHeader;
            }
        }  
     
}
//FRONT-4532 END


}