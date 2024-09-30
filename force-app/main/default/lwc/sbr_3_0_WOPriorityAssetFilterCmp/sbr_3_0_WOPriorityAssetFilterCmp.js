import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//Get the Picklist Value of Equipment Type and Status from Apex
import fetchPicklistFieldValues from '@salesforce/apex/SBR_3_0_WOPriorityController.getPickListValuesFromFields';

export default class SBR_3_0_WOPriorityAssetFilterCmp extends LightningElement {   
    @track disableAssetAttributeButtons = true;
    //Variable to store the selected Status Values
    @track selectedStatusValues = ['DOWN - LESS THAN 20 DAYS','DOWN - MORE THAN 20 DAYS','SAFETY/SERVICE LOCKOUT'];
    //Variable to store the selected Equipment Type Values
    @track selectedEquipmentTypeValues = ['CONSIGNED','FLOORED','NEW FOR SALE','OWNED','RENTAL','SUB LEASED','TRADE IN','LEASED','SEASONAL'];
    //Variable to store the selected Original Cost Option
    @track selectedOriginalCostValues = [];

    //Variable to find if the panel is visible or not
    isAssetAttributeFilterPanelVisible = false; 
    //Variable to store the selected Standard Filter Name
    selectedStandardFilterName = 'All Down Equipments';
    //Picklist Options for Status Field
    statusFieldOptions = [];
    //Picklist Options for Equipment Type Field
    equipmentTypeFieldOptions = []; 
    //Picklist Options for Original Cost Field
    originalCostFieldOptions = [];
    //Toggle Display of Range Input Fields
    displayRangeInputs = false;
    //Toggle Required for original cost range Input Fields
    requiredValueInput = false;
    //Value of Starting Range of Original Cost 
    startOriginalCost = null;
    //Value of End Range of Original Cost
    endOriginalCost = null;

    /**
     * This is the connectedCallback() method
     * This will be fired on load
     * This sets the options for Original Cost
     */
    connectedCallback() { 
        let originalCostFieldOps = ['$0 - $4,999','$5000 - $24,999','$25,000 - $49,999','$50,000 - $99,999','Over $100,000','Custom Range'];
        if(originalCostFieldOps){
            originalCostFieldOps.forEach(pickListValue => {
                //Add the found Equipment Type picklist Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.originalCostFieldOptions = [...this.originalCostFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Status field of Asset Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'Asset', 
                                      fieldName : 'Status'})
    getStatusPickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Status PickList Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.statusFieldOptions = [...this.statusFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
        
    }

    /**
     * This is the wired method to get the Field Picklist Values
     * This will be fired on load
     * This gets the Picklist Values for Status field of Asset Object 
     */
    @wire(fetchPicklistFieldValues, { objectName : 'Asset', 
                                      fieldName : 'SM_PS_Equipment_Type__c'})
    getEquipmentTypePickListValues({error, data }) {
        if(data){
            data.forEach(pickListValue => {
                //Add the found Equipment Type picklist Values
                let comboOption = {};
                comboOption.label = pickListValue;
                comboOption.value = pickListValue;
                this.equipmentTypeFieldOptions = [...this.equipmentTypeFieldOptions, comboOption]; 
            });
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is called when the Level PickList Vales is changed
     * This will acutually call the apex to get work order records
     */
    @api handleToggleAssetFilterEvent(data) {
        if (data.action == 'toggleAssetAttributeFilterPanel') {
            this.handleToggleAssetAttributeFilterPanelEvent(data);
        }
    }

    /**
     * This is called from multiple places
     * The aim is that if toggle panel is visible, then make it hidden and viceversa
     */
    handleToggleAssetAttributeFilterPanelEvent(event) {
        //If visible, make it hide, If hidden, make it visible
        this.isAssetAttributeFilterPanelVisible = !this.isAssetAttributeFilterPanelVisible;
        //Depending on the current status, set the class list property of filter panel
        if (this.isAssetAttributeFilterPanelVisible) {
            this.template.querySelector('.asset-attribute-filter-panel').classList.add('slds-is-open');
        } else {
            this.template.querySelector('.asset-attribute-filter-panel').classList.remove('slds-is-open');
        }
    }

    /**
     * Handle ChangeEvent on Status Check Group
     * Set the Selected Picklist Values of Status field by user to Variable
    */
    handleStatusPicklistChange(event) {
        this.selectedStatusValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Equipment Typw Check Group
     * Set the Selected Picklist Values of Equipment Type field by user to Variable
    */
    handleEquipmentTypePicklistChange(event) {
        this.selectedEquipmentTypeValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Original Cost Radio Group
     * Set the Selected Option of Original Cost field by user to Variable
    */
    handleOriginalCostOptionChange(event) {
        this.selectedOriginalCostValues = event.detail.value;
        this.handleCostRange(this.selectedOriginalCostValues);
    }

    handleCostRange(selectedRecord) {
        //Handles when Custom Range option is selected (Toggles Range Input Box & Required attribute)
        if(selectedRecord == 'Custom Range') {
            this.displayRangeInputs = true;
            this.requiredValueInput = true;
        } else {
            this.displayRangeInputs = false;
            this.requiredValueInput = false;
        }
        //Handles when options other than Custom Range & Over $100,000 is selected
        if(selectedRecord != 'Over $100,000' && selectedRecord != 'Custom Range') {
            let removeDollar = selectedRecord.replaceAll('$','');
            let removeSpaces = removeDollar.replaceAll(' ','');
            let rangeList = removeSpaces.split('-');
 
            this.startOriginalCost = rangeList[0].replace(',','');
            this.endOriginalCost = rangeList[1].replace(',','');
        }
        //Handles when Over $100,000 option is selected
        if(selectedRecord == 'Over $100,000'){
            this.startOriginalCost = 100000;
            this.endOriginalCost = 999999; //Change this
        }  
    }

    /**
     * Handle ChangeEvent on 'Start of Original Cost Range' Input box
     * Set the Entered value of 'Start of Original Cost Range' field by user to Variable
    */
    handleStartOriginalCostChange(event) {
        this.startOriginalCost = event.detail.value;
    }

    /**
     * Handle ChangeEvent on 'End of Original Cost Range' Input box
     * Set the Entered value of 'End of Original Cost Range' field by user to Variable
    */
    handleEndOriginalCostChange(event) {
        this.endOriginalCost = event.detail.value;
    }

    /**
     * Handle Reset All Filters Button click event
     * This will reset all filters selected
    */
    resetAssetAttributeFilterPanel(event){
        if(this.selectedStandardFilterName == 'All Work Orders') {
            this.selectedStatusValues = [];
            this.selectedEquipmentTypeValues = [];
            this.selectedOriginalCostValues = [];
            this.startOriginalCost = null;
            this.endOriginalCost = null;
        } else {
            this.selectedOriginalCostValues = [];
            this.startOriginalCost = null;
            this.endOriginalCost = null;
        }
        
        this.applyAssetAttributeFilter(event);
    }

    /**
     * Handle the Apply Button click
     * Fire a event for WOListComponent and WOHeaderComponent to refresh
    */
    applyAssetAttributeFilter(event){
        console.log('applyAssetAttributeFilter');
        //Send the applyAssetAttributeFilter event so to propogate to WOListCmp and WOHeaderComponent
        const applyAssetAttributeFilterEvent = new CustomEvent('applyassetattributefilter', {
            'detail': { 
                action : 'applyassetattributefilter',
                selectedStatusValues : this.selectedStatusValues,
                selectedEquipmentTypeValues : this.selectedEquipmentTypeValues,
                selectedOriginalCostValues : this.selectedOriginalCostValues,
                startOriginalCost : this.startOriginalCost,
                endOriginalCost : this.endOriginalCost
             }
        });

        this.dispatchEvent(applyAssetAttributeFilterEvent);
        this.handleToggleAssetAttributeFilterPanelEvent();

        //Start and End Range is required when Custom Range option is selected for Original Cost
        //Send the Error Toast event to show error message
        const errorToastEvent = new ShowToastEvent({
            title: 'Error',
            message: 'Please enter Start and End Range of Original Cost',
            variant: 'error',
            mode: 'dismissable'
        });

        if(this.selectedOriginalCostValues == 'Custom Range' && (this.startOriginalCost == null || this.startOriginalCost == '' || this.endOriginalCost == null || this.endOriginalCost == '')) {
            this.dispatchEvent(errorToastEvent);
        }
    }

    /**
     * Handle the Standard Filter Change Event
     * Fire a event for WOHeaderComponent and WOMainContainer to refresh
    */
    @api handleAssetAttributeButtonsEvent(standardFilterDetailRec)
    {
        this.selectedStandardFilterName = standardFilterDetailRec.standardFilterName;
        this.selectedStatusValues = standardFilterDetailRec.standardFilterAssetStatusMDT;
        this.selectedEquipmentTypeValues = standardFilterDetailRec.standardFilterAssetEqpTypeMDT;
        this.selectedOriginalCostValues = [];
        this.startOriginalCost = null;
        this.endOriginalCost = null;
        this.displayRangeInputs = false;

        if(standardFilterDetailRec.standardFilterName == 'All Work Orders') {
            this.disableAssetAttributeButtons = false;
        } else {
            this.disableAssetAttributeButtons = true;
        }
    }

    /**
     * To disable Apply, Clear All and Cancel button on Asset Atrribute Filter Component
    */
    get disableButton(){
        return this.disableAssetAttributeButtons;
    }
}