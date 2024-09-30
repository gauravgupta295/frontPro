import { LightningElement, api, track, wire } from 'lwc';
import { getRecord,updateRecord  } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {  getObjectInfo } from 'lightning/uiObjectInfoApi';
import OT_BURDEN_FIELD from '@salesforce/schema/SBQQ__Quote__c.OT_Burden__c';
import ST_BURDEN_FIELD from '@salesforce/schema/SBQQ__Quote__c.ST_Burden__c';
import OT_OVERHEAD_FIELD from '@salesforce/schema/SBQQ__Quote__c.OT_Overhead__c';
import ST_OVERHEAD_FIELD from '@salesforce/schema/SBQQ__Quote__c.ST_Overhead__c';
import OT_PROFIT_FIELD from '@salesforce/schema/SBQQ__Quote__c.OT_Profit__c';
import ST_PROFIT_FIELD from '@salesforce/schema/SBQQ__Quote__c.ST_Profit__c';
import ID_FIELD from "@salesforce/schema/SBQQ__Quote__c.Id";
import QUOTE_OBJECT from '@salesforce/schema/SBQQ__Quote__c';
import { RefreshEvent } from 'lightning/refresh';

export default class Sbr_3_0_crewCostSummaryCmp extends LightningElement {

    showSpinner = false;

    @api recordId;
    @api objectApiName = 'SBQQ__Quote__c';
    @track quoteRecord;
    @track quoteDetails={};
    @track isEdit=false;
    @track readOnly=true;
    showEdit = true;
    crewSummaryTotal;
    @track quoteFields={};

    @wire( getObjectInfo, { objectApiName: QUOTE_OBJECT } )
    objectInfo;

    @wire(getRecord, { recordId: '$recordId', fields: '$fields'})
    wiredRecord({ error, data }) {         
        if (data) {
            //this.getCrewSummaryTotal();
            this.quoteFields = data.fields;
            this.quoteDetails.otBurden = this.quoteFields.OT_Burden__c.value;
            this.quoteDetails.otBurdenPerc = this.quoteFields.OT_Burden__c.value/100;
            this.quoteDetails.stBurden = this.quoteFields.ST_Burden__c.value;
            this.quoteDetails.stBurdenPerc = this.quoteFields.ST_Burden__c.value/100;
            this.quoteDetails.otOverhead = this.quoteFields.OT_Overhead__c.value;
            this.quoteDetails.otOverheadPerc = this.quoteFields.OT_Overhead__c.value/100;
            this.quoteDetails.stOverhead = this.quoteFields.ST_Overhead__c.value;
            this.quoteDetails.stOverheadPerc = this.quoteFields.ST_Overhead__c.value/100;
            this.quoteDetails.otProfit = this.quoteFields.OT_Profit__c.value;
            this.quoteDetails.otProfitPerc = this.quoteFields.OT_Profit__c.value/100;
            this.quoteDetails.stProfit = this.quoteFields.ST_Profit__c.value;
            this.quoteDetails.stProfitPerc = this.quoteFields.ST_Profit__c.value/100;
            this.quoteDetails.otAverage = this.quoteFields.OT_Average__c.value;
            this.quoteDetails.stAverage = this.quoteFields.ST_Average__c.value;
            this.quoteDetails.crewSummaryTotal=this.quoteFields.Total_Crew_Summ__c?.value;

            // SF-6561
            if(this.quoteFields.SBQQ__Status__c?.value  == 'In Review'){
                this.showEdit=false;
            }
            
        }
    }

    setRecordFields() {
                this.fields = ['SBQQ__Quote__c.OT_Burden__c','SBQQ__Quote__c.ST_Burden__c','SBQQ__Quote__c.OT_Overhead__c','SBQQ__Quote__c.ST_Overhead__c','SBQQ__Quote__c.OT_Profit__c',
            'SBQQ__Quote__c.ST_Profit__c','SBQQ__Quote__c.OT_Average__c','SBQQ__Quote__c.ST_Average__c','SBQQ__Quote__c.Total_Crew_Summ__c','SBQQ__Quote__c.SBQQ__Status__c'];
    }

    connectedCallback() {
       if (this.recordId) {
       this.setRecordFields();
         }
    }

    renderedCallback() {
         
    }      

    handleSave(){
        this.showSpinner = true;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[ST_BURDEN_FIELD.fieldApiName] = this.template.querySelector("[data-field='STBurden']").value;
        fields[OT_BURDEN_FIELD.fieldApiName] = this.template.querySelector("[data-field='OTBurden']").value;
        fields[ST_OVERHEAD_FIELD.fieldApiName] = this.template.querySelector("[data-field='STOverhead']").value;
        fields[OT_OVERHEAD_FIELD.fieldApiName] = this.template.querySelector("[data-field='OTOverhead']").value;
        fields[ST_PROFIT_FIELD.fieldApiName] = this.template.querySelector("[data-field='STProfit']").value;
        fields[OT_PROFIT_FIELD.fieldApiName] = this.template.querySelector("[data-field='OTProfit']").value;
       
        const recordInput = {
            fields: fields
            };

        updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record updated',
                            variant: 'success'
                        })
                    );
                    this.isEdit=false;
                    this.readOnly=true;
                    this.showEdit=true;  
                    // Display fresh data in the form
                    //return refreshApex(this.recordId);
                    this.dispatchEvent(new RefreshEvent());
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.showSpinner = false;
                });        
        
    }

    handleCancel(){
        this.isEdit=false;   
        this.showEdit=true;  
        this.readOnly=true;         
    }

    handleEdit(){
        this.isEdit=true;        
        this.showEdit=false;
        this.readOnly=false;        
    }
  
   
}