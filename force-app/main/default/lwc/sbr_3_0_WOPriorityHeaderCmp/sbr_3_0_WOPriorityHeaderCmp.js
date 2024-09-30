import { LightningElement, wire, track,  api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//Get the Picklist Metadata from Apex
import fetchPicklistMetadata from '@salesforce/apex/SBR_3_0_WOPriorityController.getPicklistMetadata';
//Get the Current User's Base Location from User-Location Object
import getCurrentUserLocation from '@salesforce/apex/SBR_3_0_WOPriorityController.getCurrentUserLocation';
//Get the Standard Filter Details defined in custom metadata
import getStandardFiltersMetdata from '@salesforce/apex/SBR_3_0_WOPriorityController.getStandardFiltersDetails';
//Get the Current User Location Record for logged in User
import getCurrentUserLocRecord from '@salesforce/apex/SBR_3_0_WOPriorityController.getCurrentUserLocationRecord';
 
export default class SBR_3_0_WOPriorityHeaderCmp extends LightningElement {
    //Variable for current Level
    @track levelComboLabel = "Branch";
    //Variable for current Level value
    @track levelComboLabelValue = "";
    //Variable for current StandardFilter etc. Combo Box Label
    @track standardFilterComboLabel = "";
    //Variable for current Branch/District etc. Combo Box Place Holder
    @track levelComboPlaceHolder = "";
     //Variable for current Branch/District etc. Combo Box Picklist options
    @track levelComboOptions = [];
    //Variable for Level ComboBox Picklist Options
    @track levelOptions = [];
    //Variable for Standard Filter ComboBox Picklist Options
    @track standardFilterOptions = [];
    //Variable to show how many Asset Attribute Filters are selected
    @track assetAttributeFilterCount = 12;
    //Variable to show how many Work Order Attribute Filters are selected
    @track woAttributeFilterCount = 15;
    //Variable to handle the Asset Attribute Filter Button Event
    @track isAssetAttributeFilterActive = true;
    //Variable to handle the Work Order Attribute Filter Button Event
    @track isWOAttributeFilterActive = true;
    //Variable to store the Selected Options for showing on Pill
    @track selectedSearchFieldPillOptions = ['All'];
    //Variable for Location Lookup Field Value
    @track locationrecordinfo = '';
    //Default Value to be shown in Level Combo
    @track defaultLevelValue = "Branch";
    //Default Value to be shown in Standard Filters combo
    @track defaultStandardFilterValue = "All Down Equipments";
    //Default Value of Standard Filters WHERE
    @track defaultStandardFilterWhere = null;
    //Variable to store Asset Equipment Type Values from metadata record
    @track woAssetEqpTypeValuesMDT = [];
    //Variable to store Asset Status Values from metadata record
    @track woAssetStatusValuesMDT = [];
    //Variable to store WorkOrder Status Values from metadata record
    @track woStatusValuesMDT = [];
    //Variable to store Standard Filters Metadata Values
    @track pickListItemsWOP = [];

    //Variable to store the default value of Branch Level - Location Lookup Field Value
    defaultLocationRecordInfo;
    //Default Value to be shown in Level Combo Box
    defaultLevelComboBoxValue = "";
    //Variable for default valeu for Fields to Search Combo
    defaultFieldsToSearch = "All";
    //Variable to control the display of Location Lookup
    isCustomLookupVisible = "slds-show";
    //Variable to control the display of Branch/District etc. Combo Box
    isLabelComboVisible = "slds-hide";
    //Variable to store all fields which can be selected for filter
    fieldsToSearchFieldOptions = [];
    //Variable to store all Selected Field Names
    selectedfieldsToSearchValues = ['All'];
    //Variable array for storing field api names
    apiNameArray = [];
    //Variable to store the selected value for asset query. If branch, it will be id, else it will be a picklist value selected
    selectedSearchValue = null;
    //Variable to store the selected Level Combo Picklist Value as backup. This will be used to fire when level field is changed
    selectedComboxBackupValue = null;
    //Variable to store the Field API name of selected level
    fieldAPIName = null;
    //Stores Selected Standard Filter on Screen
    selectedStandardFilterValue = "";
    //Stores WHERE Clause of Selected Standard Filter on Screen
    selectedStandardFilterWhere = "";
    //Variable to store the default selected WO Status Values
    defaultSelectedWOStatusValues = ['Open','Scheduled','Dispatched','In Route','On Site','Converted','Completed with Exceptions','Unable to Complete','Cancel with Exception','Closed with Exception','Submitted','Approved','Rejected','Expired','Draft'];
    //Variable to store the default selected Asset Status Values
    defaultSelectedAssetStatusValues = ['DOWN - LESS THAN 20 DAYS','DOWN - MORE THAN 20 DAYS','SAFETY/SERVICE LOCKOUT'];
    //Variable to store the default selected Asset EquipmentType Values
    defaultSelectedEquipmentTypeValues = ['CONSIGNED','FLOORED','NEW FOR SALE','OWNED','RENTAL','SUB LEASED','TRADE IN','LEASED','SEASONAL'];
    //Variable to store the default value of District Level Combo (Current User's SM_PS_District__c)
    defaultDistrictValue = null;
    //Variable to store the default value of Inventory Region Level Combo (Current User's SM_PS_Inventory_Region_Key__c)
    defaultInvRegionValue = null;
    //Variable to store the count of WorkOrder Status values for a Standard Filter (stored in metadata)
    woStatusCount = 0;
    //Variable to store the count of Asset Status values for a Standard Filter (stored in metadata)
    woAssetStatusCount = 0;
    //Variable to store the count of Asset Equipment Type values for a Standard Filter (stored in metadata)
    woAssetEqpTypeCount = 0;
 
    /**
     * This is the wired method to get the Level Options
     * This will be fired on load
     * This gets the Level Options from Asset Inquiry Metadata (For WorkOrderPriority)
    */
    @wire(fetchPicklistMetadata, {context : 'Level'})
    getLevelPickListItems({error, data }) {
        if(data){
            let pickListItems = data.filter( col => col.SM_PS_Context__c == 'Level');
            pickListItems.sort((a,b) => a.SM_PS_Sequence_Number__c - b.SM_PS_Sequence_Number__c);
            pickListItems.forEach( item => {
                //Add the found level options
                let comboOption = {};
                comboOption.label = item.SM_PS_PickList_Value__c;
                comboOption.value = item.SM_PS_PickList_Value__c;
                this.levelOptions = [...this.levelOptions, comboOption];
                //Set the default level combo value - Branch
                if(item.SM_PS_Is_Default_Value__c){
                    this.defaultLevelValue = item.SM_PS_PickList_Value__c;
                    this.fieldAPIName = item.SM_PS_Field_API_Name__c;
                }
                //Set the API name array to be used to send for querying assets
                let apiName = {};
                apiName.label = item.SM_PS_PickList_Value__c;
                apiName.value = item.SM_PS_Field_API_Name__c;
                this.apiNameArray = [...this.apiNameArray, apiName] ;
            });
        }else if(error) {
            console.log(error);
        }
    }
 
    /**
     * Get the current user Location to be shown as default value selected for level
    */
    @wire(getCurrentUserLocation)
    getCurrentLocationForUser({error, data}) {
        if(data){
            this.locationrecordinfo = data;
            this.defaultLocationRecordInfo = data;
            let jsonSelectedBranchRec = JSON.parse(JSON.stringify(data));
            this.selectedSearchValue = jsonSelectedBranchRec['Id'];
            
        }else if(error) {
            console.log(error);
        }
    }
    
    /**
     * Get the current user's User-Location to be shown as default value selected for level
    */
    @wire(getCurrentUserLocRecord)
    getDefaultUserLocation({error, data}) {
        if(data) {
            let defaultUserLocRecord = JSON.parse(JSON.stringify(data));
            this.defaultDistrictValue = defaultUserLocRecord['SM_PS_District__c'];
            this.defaultInvRegionValue = defaultUserLocRecord['SM_PS_Inventory_Region_Key__c'];
        }
        else if(error) {
            console.log(error);
        }
    }
 
    /**
     * This is the wired method to get the Standard Filters Options
     * This will be fired on load
     * This gets the Standard Filters Options from WOPriority Standard Filters Metadata
     */
    @wire(getStandardFiltersMetdata, {objectName : 'WorkOrder'})
    getStandardFilters({error, data }) {
        if(data){
            this.pickListItemsWOP = data.filter( col => col.SM_PS_Object_Name__c == 'WorkOrder');
            this.pickListItemsWOP.sort((a,b) => a.SM_PS_Sequence_Order__c - b.SM_PS_Sequence_Order__c);
            this.pickListItemsWOP.forEach( item => {
                //Add the found standard filter options
                let comboOption = {};
                comboOption.label = item.SM_PS_Filter_Name__c;
                comboOption.value = item.SM_PS_Filter_Name__c;
                this.standardFilterOptions = [...this.standardFilterOptions, comboOption];
                //Set the default level combo value - Branch
                if(item.SM_PS_isDefault__c) {
                    this.defaultStandardFilterValue = item.SM_PS_Filter_Name__c;
                    this.defaultStandardFilterWhere = item.SM_PS_Where_Clause__c;
                    
                    if(item.SM_PS_Status_IN__c != null) {
                        this.woStatusCount = item.SM_PS_Status_IN__c.split(',').length;
                        this.woStatusValuesMDT = item.SM_PS_Status_IN__c.split(',');
                    }
                    if(item.SM_PS_Asset_Status_IN__c != null) {
                        this.woAssetStatusCount = item.SM_PS_Asset_Status_IN__c.split(',').length;
                        this.woAssetStatusValuesMDT = item.SM_PS_Asset_Status_IN__c.split(',');
                    }
                    if(item.SM_PS_Asset_Equipment_Type_IN__c != null) {
                        this.woAssetEqpTypeCount = item.SM_PS_Asset_Equipment_Type_IN__c.split(',').length;
                        this.woAssetEqpTypeValuesMDT = item.SM_PS_Asset_Equipment_Type_IN__c.split(',');
                    }
 
                    this.assetAttributeFilterCount =  this.woAssetStatusCount + this.woAssetEqpTypeCount;
                    this.woAttributeFilterCount = this.woStatusCount;
                }
            });
 
            this.handleStandardFilterCombo();
        }else if(error) {
            console.log(error);
        }
    }
 
    /**
     * This is called when the Apply Button of WOPriorityAssetFilter Cmp
     * This will acutually set the filter to be active and count of filters
     */
    @api handleApplyAssetAttributeFilterEvent(applyEventDetailRec){
        let selectedEquipmentTypeValues = [];
        let selectedStatusValues = [];
        let selectedOriginalCostValues = [];
 
        if(applyEventDetailRec) {
            selectedEquipmentTypeValues = applyEventDetailRec.selectedEquipmentTypeValues;
            selectedStatusValues = applyEventDetailRec.selectedStatusValues;
            selectedOriginalCostValues = applyEventDetailRec.selectedOriginalCostValues;
 
            if(selectedOriginalCostValues != null && selectedOriginalCostValues != '')
            {
                this.assetAttributeFilterCount = selectedEquipmentTypeValues.length + selectedStatusValues.length + 1;
            }
            else
            {
                this.assetAttributeFilterCount = selectedEquipmentTypeValues.length + selectedStatusValues.length;
            }
 
            this.isAssetAttributeFilterActive =  this.assetAttributeFilterCount > 0 ? true : false;
        }
        else
        {
            
        }
        console.log('** Asset Attribute Filter Label in handleApplyAssetAttributeFilterEvent : '+this.assetAttributeFilterCount);
        
    }
 
    /**
     * This is called when the Apply Button of WOPriorityWOFilter Cmp
     * This will acutually set the filter to be active and count of filters
     */
    @api handleApplyWOAttributeFilterEvent(applyEventDetailRec){
        let selectedWOStatusValues = [];
        let selectedWorkOrderDescValues = [];
        let selectedBillCustLocValues = [];
        let selectedClaimTypeValues = [];
        if(applyEventDetailRec) {
            selectedWOStatusValues = applyEventDetailRec.selectedWOStatusValues;
            selectedWorkOrderDescValues = applyEventDetailRec.selectedWorkOrderDescValues;
            selectedBillCustLocValues = applyEventDetailRec.selectedBillCustLocValues;
            selectedClaimTypeValues = applyEventDetailRec.selectedClaimTypeValues;
            this.woAttributeFilterCount = selectedWorkOrderDescValues.length + selectedWOStatusValues.length + selectedBillCustLocValues.length + selectedClaimTypeValues.length;
            this.isWOAttributeFilterActive =  this.woAttributeFilterCount > 0 ? true : false;
        }else{
            console.error("handleApplyWOAttributeFilterEvent : Unable to get the Work Order Detail Record");
        }
    }
 
     /**
     * This method is called from WOPriorityWOList Cmp when intializing
     * This event goes to WOPriorityHeaderCmp for setting fields in the filter combo box.
     */
    @api handleSearchFieldSetEvent(searchFieldSetRec){
        if(searchFieldSetRec){
            this.fieldsToSearchFieldOptions = searchFieldSetRec.searchfields;
        }
 
        //We are calling to here the handleBranchLookup because
        //This event is called when all fields are read by wo list cmp and
        //sends the event back here.
        //ideally calling in wire method of getCurrentLocationForUser is ideal
        //But this will not help to fetch all data as by that time
        //wire of wolistcmp is not called.
        
        if(this.locationrecordinfo)
        {
          let jsonSelectedBranchRec = JSON.parse(JSON.stringify(this.locationrecordinfo));
          var locationobj = {};

          locationobj["Id"] = jsonSelectedBranchRec['Id'];
          locationobj["Name"] = jsonSelectedBranchRec['Name'];
          this.handleBranchLookupOnChange(locationobj);
        }


    }
 
    /**
     * This method handles the change event of Level Combo
     * This method updates the below Level Combo Box Visible deoending on Level Chosen
     * If Branch is selected, then show Location Lookup Field
     * If anything else, then show the Level Combo Box
     * It also fills the picklist values from Asset Inquiry Metadata (For WorkOrderPriority)
     */
    handleLevelChange(event) {
        //Get the user selected Level Value
        this.handleLevelChangeByValue(event.target.value);
         
    }
 
    handleLevelChangeByValue(selectedLevelValue) {
        //Set the LevelComboBox Label as per the Selected Level
        this.levelComboLabel = selectedLevelValue;
        //Set the Level ComboBox PlaceHolder as per the Selected Level
        this.levelComboPlaceHolder = "Select " + selectedLevelValue;
        //Reset the Combo Option Array
        this.levelComboOptions = [];
        //Set the Field API name as per current Level
        this.apiNameArray .forEach( item => {
            if(item.label == selectedLevelValue){
                this.fieldAPIName = item.value;
            }
        });
    
        //If the Level is Branch, then make the Location Lookup Visible and hide the Level Combo Box
        if(selectedLevelValue == "Branch"){
            this.isCustomLookupVisible = "slds-show";
            this.isLabelComboVisible = "slds-hide";
            if(this.locationrecordinfo){
                this.locationrecordinfo = this.defaultLocationRecordInfo;
                this.handleBranchLookupOnChange(this.locationrecordinfo);
            }
        //If the Level is not Branch, then hide the Location Lookup Visible and make visible the Level Combo Box
        } else {
            this.isCustomLookupVisible = "slds-hide";
            this.isLabelComboVisible = "slds-show";
 
            //Fire the query to get the picklist items depending on the selected level
            fetchPicklistMetadata({
                context: this.levelComboLabel
            })
            .then((data) => {
                let districtPickListItems = data;
                let invRegionPickListItems = data;
                //Intialize the array
                this.levelComboOptions = [];
 
                //Looping through District Picklist Items
                districtPickListItems = data.filter( col => col.SM_PS_Context__c == 'District');
                districtPickListItems.forEach( item => {
                    let comboOption = {};
                    this.levelComboLabelValue = item.SM_PS_PickList_Value__c;
                    comboOption.label = item.SM_PS_PickList_Value__c;
                    comboOption.value = item.MasterLabel;
                    this.levelComboOptions = [...this.levelComboOptions, comboOption];
 
                    if(item.SM_PS_Is_Default_Value__c){
                        this.defaultLevelComboBoxValue = item.SM_PS_PickList_Value__c;
                    }
                    
                });
 
                //Looping through Inventory Region Picklist Items
                invRegionPickListItems = data.filter( col => col.SM_PS_Context__c == 'Inventory Region');
                invRegionPickListItems.sort((a,b) => a.SM_PS_Sequence_Number__c - b.SM_PS_Sequence_Number__c);
                invRegionPickListItems.forEach( item => {
                    let comboOption = {};
                    this.levelComboLabelValue = item.SM_PS_PickList_Value__c;
                    comboOption.label = item.SM_PS_PickList_Value__c;
                    comboOption.value = item.MasterLabel;
                    this.levelComboOptions = [...this.levelComboOptions, comboOption];
 
                    if(item.SM_PS_Is_Default_Value__c){
                        this.defaultLevelComboBoxValue = item.SM_PS_PickList_Value__c;
                    }
                    
                });
 
                if(this.defaultDistrictValue != null && selectedLevelValue == "District") {
                    this.defaultLevelComboBoxValue = this.defaultDistrictValue;
                    this.handleBranchLookupOnChange(this.locationrecordinfo);
                }
                if(this.defaultInvRegionValue != null && selectedLevelValue == "Inventory Region") {
                    this.defaultLevelComboBoxValue = this.defaultInvRegionValue;
                    this.handleBranchLookupOnChange(this.locationrecordinfo);
                }
            })
            .catch((error) => {
                console.log(error);
            });
 
            if(this.selectedSearchValue){
                this.selectedSearchValue = this.selectedComboxBackupValue;
            }
        }
    }
 
    /**
     * This method handles the change event of Standard Filter Combo
     */
    handleStandardFilterChange(event) {
        //Get the user selected Standard Filter Value from the event
        this.handleStandardFilterChangeByValue(event.target.value);
    }
 
    handleStandardFilterChangeByValue(standardFilterName){
        this.woStatusCount = 0;
        this.woAssetStatusCount = 0;
        this.woAssetEqpTypeCount = 0;
        this.woStatusValuesMDT = [];
        this.woAssetStatusValuesMDT = [];
        this.woAssetEqpTypeValuesMDT = [];
        this.selectedOriginalCostValues = [];
        //Set the StandardFilter ComboBox Label as per the Standard Filter Value
        this.selectedStandardFilterValue = standardFilterName;
        
        this.pickListItemsWOP.forEach( item => {
            if(item.SM_PS_Filter_Name__c == this.selectedStandardFilterValue) {
                if(item.SM_PS_Status_IN__c != null) {
                        this.woStatusCount = item.SM_PS_Status_IN__c.split(',').length;
                        this.woStatusValuesMDT = item.SM_PS_Status_IN__c.split(',');
                }
                if(item.SM_PS_Asset_Status_IN__c != null) {
                        this.woAssetStatusCount = item.SM_PS_Asset_Status_IN__c.split(',').length;
                        this.woAssetStatusValuesMDT = item.SM_PS_Asset_Status_IN__c.split(',');
                }
                if(item.SM_PS_Asset_Equipment_Type_IN__c != null) {
                        this.woAssetEqpTypeCount = item.SM_PS_Asset_Equipment_Type_IN__c.split(',').length;
                        this.woAssetEqpTypeValuesMDT = item.SM_PS_Asset_Equipment_Type_IN__c.split(',');
                }
 
                this.assetAttributeFilterCount =  this.woAssetStatusCount + this.woAssetEqpTypeCount;      
                this.woAttributeFilterCount = this.woStatusCount;
 
                this.selectedStandardFilterWhere = item.SM_PS_Where_Clause__c;
            }
        });
        
        //Resets Selected Filter
        this.template.querySelector('.selected-fields-combo').value = 'All';
        this.handleSearchFieldComboPicklistChangeByValue('All');
        //Resets Selected Fields For Search
        this.template.querySelector('.search-input').value = '';
        this.handleSearchFilterChangeByValue('');
                      
        this.handleStandardFilterCombo();
    }
 
    /**
     * This method is called when Branch Lookup is changed or when initialized or when combobox of level
     * is changed to Branch.This will further propagate the selection event to Work Order Priority.
    */
    handleBranchLookup(selectedRecord){
        let jsonSelectedBranchRec = JSON.parse(JSON.stringify(selectedRecord));
        this.selectedSearchValue = jsonSelectedBranchRec['Id'];
 
        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        const levelChangeEvent = new CustomEvent('levelchange', {
            'detail': {
                'standardFilterName' : this.defaultStandardFilterValue,
                'standardFilterLevelApiName': this.fieldAPIName,
                'standardFilterLevelValue' : this.selectedSearchValue,
                'standardFilterWhere' : this.defaultStandardFilterWhere,  
                'standardFilterWoStatusMDT' : this.defaultSelectedWOStatusValues,
                'standardFilterAssetStatusMDT' : this.defaultSelectedAssetStatusValues,
                'standardFilterAssetEqpTypeMDT' : this.defaultSelectedEquipmentTypeValues
            }
        });
        this.dispatchEvent(levelChangeEvent);
    }
 
    /**
     * This method is called when Branch Lookup is changed or when initialized or when combobox of level
     * is changed to Branch.This will further propagate the selection event to Work Order Priority.
    */
    handleBranchLookupOnChange(selectedRecord) {
        let finalStandardFilterValue = '';
        let finalStandardFilterWhere = '';
 
        if(this.selectedStandardFilterValue) {
            finalStandardFilterValue = this.selectedStandardFilterValue;
            finalStandardFilterWhere = this.selectedStandardFilterWhere;
        } else {
            finalStandardFilterValue = this.defaultStandardFilterValue;
            finalStandardFilterWhere = this.defaultStandardFilterWhere;
        }
 
        //Set the selectedSearchValue based on which Level (Branch/District/Inv Region) is selected
        if(this.levelComboLabel == "Branch") {
            let jsonSelectedBranchRec = JSON.parse(JSON.stringify(selectedRecord));
            this.selectedSearchValue = jsonSelectedBranchRec['Id'];
            this.locationrecordinfo = selectedRecord;
        }
        if(this.levelComboLabel == "District") {
            this.selectedSearchValue = this.defaultDistrictValue;
        }
        if(this.levelComboLabel == "Inventory Region") {
            this.selectedSearchValue = this.defaultInvRegionValue;
        }

        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        const levelChangeEvent = new CustomEvent('levelchange', {
            'detail': {
                'standardFilterName' : finalStandardFilterValue,
                'standardFilterLevelApiName': this.fieldAPIName,
                'standardFilterLevelValue' : this.selectedSearchValue,
                'standardFilterWhere' : finalStandardFilterWhere,
                'standardFilterWoStatusMDT' : this.woStatusValuesMDT,
                'standardFilterAssetStatusMDT' : this.woAssetStatusValuesMDT,
                'standardFilterAssetEqpTypeMDT' : this.woAssetEqpTypeValuesMDT
            }
        });
        this.dispatchEvent(levelChangeEvent);
    }
 
    /**
     * This method is called when Branch Record is selected in Lookup Box
     * This will further propagate the selection event to Work Order Priority
     */
    handleBranchLookupChange(event){
        //Get the Selected Location Record
        let selectedBranchRec= event.detail.selectedRecord;

        if(selectedBranchRec){
            this.handleBranchLookupOnChange(selectedBranchRec);
        }
    }
 
    /* This method is called when any of the following values are changed -
     * 1. Standard Filters
     * 2. Level (Branch, District, Inventory Region)
     * 3. Level Value
     * 4. WorkOrder Status from MDT record
     * 5. Asset Status from MDT record
     * 6. Asset Equipment Type from MDT record
    */
    handleStandardFilterCombo(){
        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        let finalStandardFilterValue = '';
        let finalStandardFilterWhere = '';
        if(this.selectedStandardFilterValue) {
            finalStandardFilterValue = this.selectedStandardFilterValue;
            finalStandardFilterWhere = this.selectedStandardFilterWhere;
        } else {
            finalStandardFilterValue = this.defaultStandardFilterValue;
            finalStandardFilterWhere = this.defaultStandardFilterWhere;
        }
 
        const standardFilterChangeEvent = new CustomEvent('standardfilterchange', {
            'detail': {
                'standardFilterName' : finalStandardFilterValue,
                'standardFilterLevelApiName': this.fieldAPIName,
                'standardFilterLevelValue' : this.selectedSearchValue,
                'standardFilterWhere' : finalStandardFilterWhere,
                'standardFilterWoStatusMDT' : this.woStatusValuesMDT,
                'standardFilterAssetStatusMDT' : this.woAssetStatusValuesMDT,
                'standardFilterAssetEqpTypeMDT' : this.woAssetEqpTypeValuesMDT
            }
        });
        this.dispatchEvent(standardFilterChangeEvent);
    }
 
    /**
     * This method is called when Level Combox Picklist is selected
     * This will further propagate the selection event to WOPriorityWOListCmp
     */
    handleLevelComboPicklistChange(event){
        //Get the Selected Picklist Value for Branch, District etc.
        let selectedLevelComboValue = event.detail.value;
        //If found, send it to event
        if(selectedLevelComboValue){            
            this.selectedSearchValue = selectedLevelComboValue;
            this.selectedComboxBackupValue = selectedLevelComboValue;
            this.handleStandardFilterCombo();
        }
    }
 
     /**
     * This method is called when the AssetAttributeFilter Toggle Button is clicked
     * This will further propagate the selection event to WOPriorityAssetFilter Component
     */
     handleAssetAttributeFilterButtonClick(event){
        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        const toggleAssetFilterEvent = new CustomEvent('toggleassetfilter', {
            'detail': {
                action : 'toggleAssetAttributeFilterPanel'
             }
        });
        this.dispatchEvent(toggleAssetFilterEvent);
    }
 
    /**
     * This method is called when the WorkOrderAttributeFilter Toggle Button is clicked
     * This will further propagate the selection event to WOPriorityWOFilter Component
     */
    handleWOAttributeFilterButtonClick(event){
        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        const toggleWOFilterEvent = new CustomEvent('togglewofilter', {
            'detail': {
                action : 'toggleWOAttributeFilterPanel'
             }
        });
        this.dispatchEvent(toggleWOFilterEvent);
    }
 
    /**
     * This method is called when Filter Search Combox Box is selected
     * This will make sure that the selected field is added to Pill
     */
    handleSearchFieldComboPicklistChange(event) {
        //Get the Selected Picklist Value
        this.handleSearchFieldComboPicklistChangeByValue(event.detail.value);
    }
 
    handleSearchFieldComboPicklistChangeByValue(selectedSearchField){
        //Get the Label of selected search field
        let index = 0;
        //Get the index for all
        let allIndex = -1;
 
        if(selectedSearchField == 'All'){
            this.selectedSearchFieldPillOptions = ['All'];
            this.selectedfieldsToSearchValues = ['All'];
        }else{
            //Get the Index for 'All' value
            this.selectedSearchFieldPillOptions.forEach(selectedField => {
                if(selectedField == 'All'){
                    allIndex = index;
                }
                index++;
            });
 
            this.fieldsToSearchFieldOptions.forEach(searchFields =>{
                if(searchFields.value == selectedSearchField){
                    //If found, send it to event
                    if(!this.selectedSearchFieldPillOptions.includes(searchFields.label)){
                        if(allIndex != -1){
                            this.selectedSearchFieldPillOptions.splice(allIndex, 1);
                            this.selectedfieldsToSearchValues.splice(allIndex, 1);
                        }
                        this.selectedSearchFieldPillOptions.push(searchFields.label);
                        this.selectedfieldsToSearchValues.push(searchFields.value);
                    }
                }
            });
        }
    }
 
    /**
     * This method is called when a selected search field is removed from Pill
     * This will remove the pill from the selected element list
     */
    handleSearchFieldRemove(event){
        //Get the Selected Picklist Value
        let selectedSearchField = event.target.name;
        //Get the Label of selected search field
        let index = 0;
        //Get the index for all
        let allIndex = -1;
        
        //Get the Index for 'All' value
        this.selectedSearchFieldPillOptions.forEach(selectedField => {
            if(selectedField == 'All'){
                allIndex = index;
            }
            index++;
        });
 
        index = 0;
        this.selectedSearchFieldPillOptions.forEach(selectedField => {
            if(selectedField === selectedSearchField){
                if(allIndex != -1){
                    this.selectedSearchFieldPillOptions.splice(allIndex, 1);
                    this.selectedSearchFieldPillOptions.splice(allIndex, 1);
                    this.selectedSearchFieldPillOptions.splice(--index, 1);
                    this.selectedfieldsToSearchValues.splice(--index, 1);
                }else{
                    this.selectedSearchFieldPillOptions.splice(index, 1);
                    this.selectedfieldsToSearchValues.splice(index, 1);
                }
            }
            index++;
        });
 
        if(this.selectedSearchFieldPillOptions.length == 0){
            this.selectedSearchFieldPillOptions = ['All'];
            this.selectedfieldsToSearchValues = ['All'];
        }
    }
 
    /**
     * This method is called from Search Input Box change
     * This is propagated to WOPriorityWOListCmp
     */
    handleSearchFilterChange(event){
        this.handleSearchFilterChangeByValue(event.target.value);
    }
 
    handleSearchFilterChangeByValue(searchKey) {
        //Send the event to WOPriorityMainContainerCmp to propogate to WOPriorityWOListCmp
        const searchFilterChangeEvent = new CustomEvent('searchfilterchange', {
            'detail': {
                action : 'searchfilterchange',
                searchKey : searchKey,
                fieldSelected : this.selectedfieldsToSearchValues
             }
        });
        this.dispatchEvent(searchFilterChangeEvent);
    }
 
    /**
     * This method is called when RESET button is clicked
     * It resets the screen with default values (StandardFilter, AssetFilter, WOFilter, LevelFilter, SearchFilter)
     */
    handleResetClick(){
        //Resets Selected Filter
        this.template.querySelector('.selected-fields-combo').value = 'All';
        this.handleSearchFieldComboPicklistChangeByValue('All');
        //Resets Selected Fields For Search
        this.template.querySelector('.search-input').value = '';
        this.handleSearchFilterChangeByValue('');
 
        //Reset Standard Filter, Asset Filter, WO Filter
        this.template.querySelector('.standardcombo').value = this.defaultStandardFilterValue;
        this.handleStandardFilterChangeByValue(this.defaultStandardFilterValue);
        
        //Resets Level Filter
        this.template.querySelector('.levelcombo').value = 'Branch';
        this.handleLevelChangeByValue('Branch');
        //Resets Selected Level Value
        this.template.querySelector('c-s-b-r_3_0_custom-lookup-cmp').selectedRecordObject = this.locationrecordinfo;
        this.handleBranchLookup(this.locationrecordinfo);
 
        const successToastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Reset Completed Successfully !!',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(successToastEvent);
        
    }
}