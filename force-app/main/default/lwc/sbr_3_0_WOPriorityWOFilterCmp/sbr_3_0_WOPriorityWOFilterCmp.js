import { LightningElement, api, track, wire } from 'lwc';
//Get the Picklist Value of Status, Work Order Description, Bill Customer or Location, Claim Type from Apex Controller
import fetchPicklistFieldValues from '@salesforce/apex/SBR_3_0_WOPriorityController.getPickListValuesFromFields';

export default class Sbr_3_0_WOPriorityWOFilterCmp extends LightningElement {
    //Variable to store the selected Status Values
    @track selectedWOStatusValues = ['Open','Scheduled','Dispatched','In Route','On Site','Converted','Completed with Exceptions','Unable to Complete','Cancel with Exception','Closed with Exception','Submitted','Approved','Rejected','Expired','Draft'];
    //Variable to store the selected Work Order Description Values
    @track selectedWorkOrderDescValues = [];
    //Variable to store the selected Bill Customer or Location Values
    @track selectedBillCustLocValues = [];
    //Variable to store the selected Claim Type Values
    @track selectedClaimTypeValues = [];
    //Variable to find if WOAttributeButtons is disable or not
    @track disableWOAttributeButtons = true;

    //Variable to find if the panel is visible or not
    isWOAttributeFilterPanelVisible = false;
    //Variable to store the selected Standard Filter Name
    selectedStandardFilterName = 'All Down Equipments';
    //Picklist Options for Status Field
    workOrderStatusFieldOptions = [];
    //Picklist Options for Work Order Description Field
    workOrderDescFieldOptions = [];   
    //Picklist Options for Bill Customer or Location Field
    billCustLocFieldOptions = [];    
    //Picklist Options for Claim Type Field
    claimTypeFieldOptions = [];   

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Status field of Work Order Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'WorkOrder', 
                                      fieldName : 'Status'})
    getStatusPickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Status PickList Values
                let comboOption = {};
                if(pickListValue == 'O') {
                    comboOption.label = 'Open';
                    comboOption.value = 'Open';
                } if(pickListValue == 'D') {
                    comboOption.label = 'Canceled';
                    comboOption.value = 'Canceled';
                } if(pickListValue == 'C') {
                    comboOption.label = 'Closed';
                    comboOption.value = 'Closed'; 
                } if(pickListValue != 'O' && pickListValue != 'C' && pickListValue != 'D') {
                    comboOption.label = pickListValue;
                    comboOption.value = pickListValue;
                }

                this.workOrderStatusFieldOptions = [...this.workOrderStatusFieldOptions, comboOption];           
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Work Order Description field of Work Order Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'WorkOrder', 
                                      fieldName : 'SF_PS_Work_Order_Des__c'})
    getWorkOrderDescPickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Equipment Type picklist Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.workOrderDescFieldOptions = [...this.workOrderDescFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Bill Customer or Location field of Work Order Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'WorkOrder', 
                                      fieldName : 'SF_PS_BillCustOrLoc__c'})
    getBillCustLocPickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Bill Customer or Location picklist Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.billCustLocFieldOptions = [...this.billCustLocFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Claim Type field of Work Order Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'WorkOrder', 
                                      fieldName : 'SF_PS_Claim_Type__c'})
    getClaimTypePickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Claim Type picklist Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.claimTypeFieldOptions = [...this.claimTypeFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is called when the Level PickList Vales is changed
     * This will acutually call the apex to get work order record 
     */
    @api handleToggleWOFilterEvent(data) {
        if (data.action == 'toggleWOAttributeFilterPanel') {
            this.handleToggleWOAttributeFilterPanelEvent(data);
        }
    }

    /**
     * This is called from multiple places
     * The aim is that if toggle panel is visible, then make it hidden and viceversa
     */
    handleToggleWOAttributeFilterPanelEvent(event){
        //If visible, make it hide, If hidden, make it visible
        this.isWOAttributeFilterPanelVisible = !this.isWOAttributeFilterPanelVisible;
        //Depending on the current status, set the class list property of filter panel
        if (this.isWOAttributeFilterPanelVisible) {
            this.template.querySelector('.wo-attribute-filter-panel').classList.add('slds-is-open');
        } else {
            this.template.querySelector('.wo-attribute-filter-panel').classList.remove('slds-is-open');
        }
    }

    /**
     * Handle ChangeEvent on Status Check Group
     * Set the Selected Picklist Values of Status field by user to Variable
     */
    handleStatusPicklistChange(event){
        this.selectedWOStatusValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Work Order Description Check Group
     * Set the Selected Picklist Values of Work Order Description field by user to Variable
     */
    handleWorkOrderDescPicklistChange(event){
        this.selectedWorkOrderDescValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Bill Customer or Location Check Group
     * Set the Selected Picklist Values of Bill Customer or Location field by user to Variable
     */
    handleBillCustLocPicklistChange(event){
        this.selectedBillCustLocValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Claim Type Check Group
     * Set the Selected Picklist Values of Claim Type field by user to Variable
     */
    handleClaimTypePicklistChange(event){
        this.selectedClaimTypeValues = event.detail.value;
    }

    /**
     * Handle Clear All Filters Button click event
     * This will reset all filters selected
     */
    resetWOAttributeFilterPanel(event){
        if(this.selectedStandardFilterName == 'All Work Orders') {
            this.selectedWOStatusValues = [];
            this.selectedWorkOrderDescValues = [];
            this.selectedBillCustLocValues = [];
            this.selectedClaimTypeValues = [];
        } else {
            this.selectedWorkOrderDescValues = [];
            this.selectedBillCustLocValues = [];
            this.selectedClaimTypeValues = [];
        }
        
        this.applyWOAttributeFilter(event);
    }

    /**
     * Handle the Apply Button click
     * Fire a event for WOPriorityWOList Component and WOPriorityHeader Component to refresh
     */
    applyWOAttributeFilter(event){
        //Send the applyAssetAttributeFilter event so to propogate to WOPriorityWOList Cmp and WOPriorityHeaderCmp
        const applyWOAttributeFilterEvent = new CustomEvent('applywoattributefilter', {
            'detail': { 
                action : 'applyWOattributefilter',
                selectedWOStatusValues : this.selectedWOStatusValues,
                selectedWorkOrderDescValues : this.selectedWorkOrderDescValues,
                selectedBillCustLocValues : this.selectedBillCustLocValues,
                selectedClaimTypeValues : this.selectedClaimTypeValues 
             }
        });

        this.dispatchEvent(applyWOAttributeFilterEvent);
        this.handleToggleWOAttributeFilterPanelEvent();
    }

    /**
     * Handle the Standard Filter Change Event
     * Fire a event for WOPriorityHeader Component and WOPriorityMainContainerCmp to refresh
     */
    @api handleWOAttributeButtonsEvent(standardFilterDetailRec)
    {
        this.selectedStandardFilterName = standardFilterDetailRec.standardFilterName;
        this.selectedWOStatusValues = standardFilterDetailRec.standardFilterWoStatusMDT;
        this.selectedWorkOrderDescValues = [];
        this.selectedBillCustLocValues = [];
        this.selectedClaimTypeValues  = [];

        if(standardFilterDetailRec.standardFilterName == 'All Work Orders') {
            this.disableWOAttributeButtons = false;
        } else {
            this.disableWOAttributeButtons = true;
        }
    }

    /**
     * To disable Apply, Clear All and Cancel button on WorkOrder Atrribute Filter Component
    */
    get disableButton(){
        return this.disableWOAttributeButtons;
    }
}