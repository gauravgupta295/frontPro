import { LightningElement, api, wire, track } from 'lwc';
import getInternalComments from '@salesforce/apex/SBR_3_0_PurchaseOrderIntCommCntrl.getInternalComments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import createOrUpdatePOInternalComments from '@salesforce/apex/SBR_3_0_PurchaseOrderIntCommCntrl.createOrUpdatePOInternalComments';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import FORM_FACTOR from '@salesforce/client/formFactor';

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Type__c']
const MAX_COMMENT_LENGTH = 40;
const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_purchaseOrderInternalPOComments extends LightningElement {

    @track openmodal = false;
    @track open = true;

    data = [];
    rowId;
    comments;
    createdBydate = '';
    str = '';
    createdby = '';
    commentsObj = [];
    currentRowId;
    allComments = '';
    @track commentsArray = [];
    poRecordType;
    poStatus;
    showEditButton = true;
    showNewButton = true;
    _recordId;
    sectionTitle = 'Internal PO Comments';

    @api set recordId(value) {
        this._recordId = value;
        this.getComments();
    }

    get recordId() {
        return this._recordId;
    }

    get sectionClass() {
        return this.open ? 'slds-section slds-is-open' : 'slds-section';
    }

    connectedCallback() {
        if (typeof this.open === 'undefined') this.open = true;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.poRecordType = data.fields.Type__c.value;
            this.poStatus = data.fields.Status__c.value;
            console.log('poRecordType code of PO >>', this.poRecordType);
            console.log('poStatus code of PO >>', this.poStatus);

            if(this.poStatus==='Received' || this.poStatus==='Cancelled')
            {
            /*if (this.poRecordType === '3rd Party Hauler') {
                if (this.poStatus === 'Open' || this.poStatus === 'Back Order' || this.poStatus === 'Partially Received')
                    this.showEditButton = false;
            }*/
            if (this.poRecordType === 'Rerent' || this.poRecordType === '3rd Party Hauler') {
                if (this.poStatus != 'Draft')
                {
                    this.showEditButton = false;
                    this.showNewButton = false;
                }
            }
            }

        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    async getComments() {
        this.getAllComments();
    }

    getAllComments() {
        getInternalComments({ recordId: this.recordId })
            .then(result => {

                // Map data and prevent extensions
                this.data = result.map(item => ({ ...item, createdByName: item.Created_By__c }));

                // Initialize variables
                this.commentsObj = [];

                if (this.data && this.data.length > 0) {
                    // Loop through comments
                    this.data.forEach((comment, idx) => {
                        this.pushCommentObject(comment, idx);
                    });
                    // this.data.forEach(comment => {
                    //     this.pushCommentObject(comment);
                    // });
                } else {
                    console.log('No comments found.');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error while fetching comments:', error);
            });

    }

    // Helper function to push comment object
    pushCommentObject(comment, idx) {
        const { Id, Created_Date__c, CreatedById, Created_By__c, Comments__c, createdByName } = comment;
        let rowId;
        if (Comments__c) {
            if (Comments__c.length <= MAX_COMMENT_LENGTH) {
                let replacedStr = Comments__c.replace(/\xa0/g, '');
                rowId = Id;
                this.commentsObj.push({
                    "Id": rowId,
                    "RecordId": Id,
                    "Date": Created_Date__c,
                    "User": createdByName,
                    "UserId": CreatedById,
                    "Comments": Comments__c
                });
            } else {
                let k = 0;
                for (let i = 0; i < Comments__c.length; i += MAX_COMMENT_LENGTH) {
                    let subs = Comments__c.substring(i, i + MAX_COMMENT_LENGTH);
                    let replacedStr = subs.replace(/\xa0/g, '');
                    k = k + 1;
                    rowId = Id + '-' + k.toString();

                    this.commentsObj.push({
                        "Id": rowId,
                        "RecordId": Id,
                        "Date": Created_Date__c,
                        "User": createdByName,
                        "Comments": subs
                    });
                }
            }
        } else {
            console.log('No comments found.');
        }
        if (idx === this.data.length - 1) {
            this.sectionTitle = this.sectionTitle + ' (' + this.commentsObj.length + ')';
        }
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
        //return true;
    }

    handleMenuSelect(event) {
        const rowId = event.currentTarget.dataset.id;

        if (event.detail.value == 'edit' && rowId != null) {
            let comRow = this.commentsObj.filter(x => x.Id == rowId);
            this.currentRowId = comRow[0].RecordId;
            this.oldCommentVal = comRow[0].Comments;
            this.str = comRow[0].Comments.trim();
            this.createdByDate = comRow[0].Date;
            this.createdBy = comRow[0].User;
            this.openmodal = true;
        }
    }

    handleAddNew() {
        this.currentRowId = '';
        this.oldCommentVal = '';
        this.str = '';
        this.createdByDate = '';
        this.createdBy = '';
        this.openmodal = true;
    }

    handleModalState() {
        this.openmodal = false;
        this.openmodal2 = false;
    }

    handleSaveButton(event) {
        let selectedCommentId = event.detail.rowId || null;
        let oldCommentVal = this.oldCommentVal;
        let newCommentVal = event.detail.comment;
        let isEditMode = selectedCommentId !== null;
        let createdByUserDate = isEditMode ? new Date(this.createdByDate) : null;
        let createdbyUser = isEditMode ? this.createdBy : null;

        console.log(isEditMode);
        console.log(createdbyUser);
        console.log(selectedCommentId);
        
        // Pad new comment value with spaces if it's less than 40 characters
        if (newCommentVal.length < MAX_COMMENT_LENGTH) {
            let remainingSpaces = MAX_COMMENT_LENGTH - newCommentVal.length;
            let spacesToAdd = '\xa0'.repeat(remainingSpaces);
            newCommentVal += spacesToAdd;
        }

        let actionParams = {
            recordId: this.recordId,
            selectedCommentIds: selectedCommentId,
            oldCommentValue: oldCommentVal,
            newCommentValue: newCommentVal,
            commentDate: createdByUserDate ? createdByUserDate : null,
            createdBy: createdbyUser
        };

        console.log(actionParams);

        createOrUpdatePOInternalComments(actionParams)
            .then(result => {
                // Assuming the result is valid, update the UI
                this.getAllComments();

                // Notify changes to the record
                refreshApex(this.data);
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.openmodal = false;

                const toastMessage = isEditMode ? 'Comment updated successfully!' : 'Comment added successfully!';
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: toastMessage,
                        title: 'Success',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                // Handle errors
                const errorMessage = error && error.body ? error.body.message : 'Unknown error';

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: `Error while ${isEditMode ? 'updating' : 'adding'} comment`,
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            });
    }

    handleClick() {
        this.open = !this.open;
    }

    handleFailedModal(event) {
        this.openmodal = false;
    }

}