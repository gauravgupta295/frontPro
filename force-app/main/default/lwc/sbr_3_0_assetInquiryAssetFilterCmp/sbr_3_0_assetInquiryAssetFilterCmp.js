import { LightningElement, api, track, wire } from 'lwc';
//Get the Picklist Value of Equipment Type and Status from Apex
import fetchPicklistFieldValues from '@salesforce/apex/SBR_3_0_AssetInquiryController.getPickListValuesFromFields';

export default class Sbr_3_0_assetInquiryAssetFilterCmp extends LightningElement {

    //Variable to find if the panel is visible or not
    isAssetAttributeFilterPanelVisible = false;
    //Picklist Options for Status Field
    statusFieldOptions = [];
    //Picklist Options for Equipment Type Field
    equipmentTypeFieldOptions = [];     
    //Variable to store the selected Status Values
    @track selectedStatusValues = ['AVAILABLE','ON RENT','SCHEDULED FOR PICKUP','IN TRANSIT','RETURNED - NEED CHECK OUT','DOWN - LESS THAN 20 DAYS','DOWN - MORE THAN 20 DAYS',
    'ON RENTAL PURCHASE','SAFETY/SERVICE LOCKOUT','HELD FOR CENTRAL DISPOSAL','HELD FOR SALE','SATELITE BRANCH','SEASONAL'];
    //Variable to store the selected Equipment Type Values
    @track selectedEquipmentTypeValues = ['NEW FOR SALE','RENTAL'];

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
     * This will acutually call the apex to get assets record 
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
    handleToggleAssetAttributeFilterPanelEvent(event){
        //If visible, make it hide, If hidden, make it visible
        this.isAssetAttributeFilterPanelVisible = !this.isAssetAttributeFilterPanelVisible;
        //Depending on the current status, set the class list property of filter panel
        if (this.isAssetAttributeFilterPanelVisible) {
            this.template.querySelector('.asset-attribute-filter-panel').classList.add('slds-is-open');
        } else {
            //this.closeIcon = this.closeIconSelected;
            this.template.querySelector('.asset-attribute-filter-panel').classList.remove('slds-is-open');
        }
    }

    /**
     * Handle ChangeEvent on Status Check Group
     * Set the Selected Picklist Values of Status field by user to Variable
     */
    handleStatusPicklistChange(event){
        this.selectedStatusValues = event.detail.value;
    }

    /**
     * Handle ChangeEvent on Equipment Typw Check Group
     * Set the Selected Picklist Values of Equipment Type field by user to Variable
     */
    handleEquipmentTypePicklistChange(event){
        this.selectedEquipmentTypeValues = event.detail.value;
    }

    /**
     * Handle Reset All Filters Button click event
     * This will reset all filters selected
     */
    resetAssetAttributeFilterPanel(event){
        this.selectedStatusValues = [];
        this.selectedEquipmentTypeValues = [];

        this.applyAssetAttributeFilter(event);
    }

    /**
     * Handle the Apply Button click
     * Fire a event for AssetListComponent and AssetHeaderComponent to refresh
     */
    applyAssetAttributeFilter(event){
        //Send the applyAssetAttributeFilter event so to propogate to AssetInquiryListCmp and AsseyInquiryHeaderComponent
        const applyAssetAttributeFilterEvent = new CustomEvent('applyassetattributefilter', {
            'detail': { 
                action : 'applyassetattributefilter',
                selectedStatusValues : this.selectedStatusValues,
                selectedEquipmentTypeValues : this.selectedEquipmentTypeValues 
             }
        });
        this.dispatchEvent(applyAssetAttributeFilterEvent);

        this.handleToggleAssetAttributeFilterPanelEvent();
    }
}