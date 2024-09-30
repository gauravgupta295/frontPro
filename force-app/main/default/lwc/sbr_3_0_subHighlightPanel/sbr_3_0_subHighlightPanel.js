import { LightningElement, api, wire } from "lwc";
import USER_ID from "@salesforce/user/Id";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTrackedAccount from '@salesforce/apex/SBR_3_0_AccountRelationshipDA.createAccountRelationship';
import deleteTrackedAccount from '@salesforce/apex/SBR_3_0_AccountRelationshipDA.deleteTrackedAccountRelationships';

import TRACKING_ID_FIELD from '@salesforce/schema/Account_Relationship__c.Id';


export default class Sbr_3_0_subHighlightPanel extends LightningElement {
    
    @api recordId;
    @api userId = USER_ID;

    _isTracked = false;
    showSpinner = false;
    tracking_ar_fields = [TRACKING_ID_FIELD];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Account_Relationships__r',
        fields: ['Account_Relationship__c.Id'],
        where: '{ My_Tracking_AR__c : { eq: "true" }}'
      })
    tracking_ar;

    connectedCallback() {
        console.log(this.tracking_ar);
        console.log(this.tracking_ar.data);
        if(this.tracking_ar.data && this.tracking_ar.data.count > 0) {
            this._isTracked = true;
        }
        this._isTracked = false;
    }

    get isTracked() {
        if(this.tracking_ar.data && this.tracking_ar.data.count > 0) {
            return true;
        }
        return this._isTracked;
    }
    
    handleTrack() {
        //this.isTracked = !this.isTracked;
        console.log(this.tracking_ar);
        this.showSpinner = true;
        if(!this.isTracked) {
            createTrackedAccount({ accountId : this.recordId, userId : this.userId })
            .then(result => {
                this.tracking_ar.data = result;
                this._isTracked = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'You are now tracking this Account.',
                        variant: 'success',
                    }),
                );
                
                console.log(JSON.stringify(result));
                console.log("result", this.tracking_ar);
                this.showSpinner = false;

            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an error tracking this Account.',
                        variant: 'error',
                    }),
                );
                this.showSpinner = false;
            });
        } else {
            deleteTrackedAccount({ accountId : this.recordId, userId : this.userId })
            .then(result => {
                this.tracking_ar.data = result;
                this._isTracked = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'You are no longer tracking this Account',
                        variant: 'success',
                    }),
                );
                
                console.log(JSON.stringify(result));
                console.log("result", this.tracking_ar);
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an error tracking this Account.',
                        variant: 'error',
                    }),
                );
                this.showSpinner = false;
            });
        }
        
    }
}