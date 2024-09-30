import { LightningElement, track, wire, api  } from 'lwc';
import getAssetReqs from '@salesforce/apex/SBR_3_0_AssetRequisitionsController.getAssetReqs'; 
import {refreshApex} from '@salesforce/apex';
import createPOLineItem from '@salesforce/apex/SBR_3_0_AssetRequisitionsController.createPOLineItem';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import FORM_FACTOR from "@salesforce/client/formFactor";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import mobileView from './mobile.html';
//import desktopView from './mobile.html';
import desktopView from './sbr_3_0_AssetRequisitionsLWC.html';
const SMALL_FORM_FACTOR = "Small";
const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Type__c']
export default class Sbr_3_0_AssetRequisitionsLWC extends  LightningElement {

columns = [
    { label: 'Requisition #', fieldName: 'Requisition_Num__c' ,sortable: 'true'},
    { label: 'Quantity', fieldName: 'Quantity__c'}, 
    { label: 'Rqs Date', fieldName: 'Requisition_Date__c', type: 'date', typeAttributes: { day: 'numeric', month: 'numeric', year: 'numeric'}},
    { label: 'Item #', fieldName: 'Item_Number__c', sortable: 'true' },
    { label: 'Due Date', fieldName: 'Due_Date__c', type: 'date', typeAttributes: { day: 'numeric', month: 'numeric', year: 'numeric'}},
    { label: 'Employee', fieldName: 'Added_By__c'},
    { label: 'Type', fieldName: 'Requisition_Type__c' },
    { label: 'Contract', fieldName: 'Contract_Num__c'},
    { label: 'Approval', fieldName: 'Approval_Level__c' },
    { label: 'Maint By', fieldName: 'Maintained_By__c' },
    {
        type: "button", label: '', initialWidth: 100, typeAttributes: {
            label: 'Select',
            name: '',
            title: '',
            disabled: false,
            value: '',
            iconPosition: 'left',
            //iconName:'utility:preview',
            //onclick:'handleClick',
            variant:'Brand'
        }
    }
];
 columns2 = [
    { label: 'Requisition #', fieldName: 'Requisition_Num__c'},
    { label: 'Quantity', fieldName: 'Quantity__c'}, 
    { label: 'Rqs Date', fieldName: 'Requisition_Date__c', type: 'date', typeAttributes: { day: 'numeric', month: 'numeric', year: 'numeric'}},
    { label: 'Item #', fieldName: 'Item_Number__c' },
    { label: 'Due Date', fieldName: 'Due_Date__c', type: 'date', typeAttributes: { day: 'numeric', month: 'numeric', year: 'numeric'}},
    { label: 'Employee', fieldName: 'Added_By__c'},
    { label: 'Type', fieldName: 'Requisition_Type__c' },
    { label: 'Contract', fieldName: 'Contract_Num__c'},
    { label: 'Approval', fieldName: 'Approval_Level__c' },
    { label: 'Maint By', fieldName: 'Maintained_By__c' },
    {
        type: "button", label: '', initialWidth: 100, typeAttributes: {
            label: 'Select',
            name: '',
            title: '',
            disabled: true,
            value: '',
            iconPosition: 'left',
            //iconName:'utility:preview',
            //onclick:'handleClick',
            variant:'Brand'
        }
    }
];
    @api recordId;
    @track data;
    @track error;
    //@track columns2= columns2;
    //@track columns = columns;
    @track searchString;
    @track initialRecords;
    @track sortDirection;
    @track newLineitem;
    @track sortByName;
    @track sortBy;
    @track singleRecordId;
    @track selectedRows = [];
    @track newSingleUnitValue;
    @track singleUnitCost;
    @track onRowSelection=false;
    @track recordId;
    dataToRefresh;
    enabledRowCount = 0;
    statusValue;        

    
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {

            console.log('PO Data', data);
            console.log('status of PO >>',JSON.stringify(data.fields.Status__c.value));

            this.statusValue = data.fields.Status__c.value;

            if (this.statusValue === 'Cancelled'|| this.statusValue === 'Received' ) {
               this.columns=this.columns2;
                
            }else{
               this.columns=this.columns;
            }
            

        } else if (error) {
            console.log(error);
            this.error = error;
        }
    }

    @wire(getAssetReqs, {recordId: '$recordId'})
    wiredData(result) {
        this.dataToRefresh =result;
        if (result.data) {
            console.log(result.data);
            this.data = result.data;
            this.initialRecords = result.data;
            this.error = undefined;
            this.totalNoOfRecords = result.data.length;

        } else if(result.error){
            this.error = result.error;
            this.data = undefined;   
        }

    }

    connectedCallback() {
        
        /*getAssetReqs({ recordId: this.recordId, objectName: 'PO_Requisition__c', fieldName: ['Requisition_Num__c', 'Quantity__c', 'Item_Number__c', 'Status__c', 'Due_Date__c','Requisition_Type__c','Contract_Num__c', 'Approval_Level__c','Maintained_By__c'], filterBy: this.productType })
            .then(result => {
                this.isLoaded = false;
                this.data = result;
                this.totalNoOfRecords = result.length;
                
            })
            .catch(error => {
                console.log('no Data');
            })*/
        
    }
 
    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        //console.log('event.keyCode === 13'+event.keyCode);
 
        if (searchKey) {
            this.data = this.initialRecords;
 
            if (this.data) {
                let searchRecords = [];
 
                for (let record of this.data) {
                    let valuesArray = Object.values(record);
 
                    for (let val of valuesArray) {
                        console.log('val is ' + val);
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
                console.log('Matched Accounts are ' + JSON.stringify(searchRecords));
                this.data = searchRecords;
                this.totalNoOfRecords = this.data.length;
            }
            
        } 
        else {
            

            this.data = this.initialRecords;
            this.totalNoOfRecords = this.data.length;
        }
    }// handleSearch is working fine...no change required

    //start
    handleRowAction(event) {
        console.log('event',event.target.recordTypeId);   
        console.log('purchase',this.recordId);
        const rowRecordId=event.detail.row.Id;
        console.log('purchase',this.recordId);
        console.log('PorequisitioId',rowRecordId);
        this.handleCreatePOLineItem(rowRecordId, this.recordId);
    }

    handleSelect(event) {
        const rowRecordId = event.currentTarget.dataset.id;
        console.log('rowRecordId', rowRecordId);
        console.log('purchase', this.recordId);
        this.handleCreatePOLineItem(rowRecordId, this.recordId);
    }
    //end

    handleCreatePOLineItem(poReqId, poRecId) {
        createPOLineItem({ recordId: poReqId, purchaseOrder: poRecId })
            .then(result => {
                const event = new ShowToastEvent({
                    title: 'Item Added to PO Line Item',
                    message: 'New PO Line item created.',
                    variant: 'success'
                });

                this.dispatchEvent(event);
                refreshApex(this.dataToRefresh);


                //this.dispatchEvent(new RefreshEvent());
                //return refreshApex(this.data);
                //this.refreshApex(this.initialRecords);

                //eval("$A.get('e.force:refreshview').fire();");
            })
            .catch(error => {
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error occurred in creating new PO Line item',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            });
    }


     render() {
        return (this.isMobileView === true) ? mobileView : desktopView;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }
handleFormFactor() {
        if (FORM_FACTOR === "Large") {
            this.deviceType = "Desktop/Laptop";
        } else if (FORM_FACTOR === "Medium") {
            this.deviceType = "Tablet";
        } else if (FORM_FACTOR === "Small") {
            this.deviceType = "Mobile";
        }
    }

    handleClick() {
        this.singleRecordId=this.selectedRows[0].Id;
        this.newSingleUnitValue=this.singleUnitCost;
        console.log(this.recordId);
        console.log(this.singleRecordId);
        createPOLineItem({singleRecordId:this.singleRecordId, newSingleUnitValue:this.newSingleUnitValue})
        .then(productDetails => {
            console.log("productDetails:"+JSON.stringify(productDetails))
        })
        .catch(error => {
            console.log("error:"+JSON.stringify(error))
        })
    }
}