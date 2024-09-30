import { LightningElement, wire, track,  api } from 'lwc';
//Get the Picklist Metadata from Apex
import fetchPicklistMetadata from '@salesforce/apex/SBR_3_0_AssetInquiryController.getPicklistMetadata';
//Get the Current User's Base Location from User-Location Object
import getCurrentUserLocation from '@salesforce/apex/SBR_3_0_AssetInquiryController.getCurrentUserLocation';
//Get the Branch Details from the selected branch number
import getBranchLocation from '@salesforce/apex/SBR_3_0_AssetInquiryController.getBranchLocation';

export default class Sbr_3_0_assetInquiryHeaderCmp extends LightningElement {
    //Variable for current Region/Territory etc. Combo Box Label
    @track levelComboLabel = "Branch";
    //Variable for current Region/Territory etc. Combo Box Place Holder 
    @track levelComboPlaceHolder = "";
     //Variable for current Region/Territory etc. Combo Box Picklist options
    @track levelComboOptions = [];
    //Variable for Level ComboBox Picklist Options
    @track levelOptions = []; 
    //Variable for status options
    @track statusFieldOptions = [];
    //Variable for equipment types options
    @track equipmentTypeFieldOptions = [];
    //Variable to show how many Asset Attribute Filters are selected
    @track assetAttributeFilterCount = 15;
    //Variable to show how many Product Attribute Filters are selected
    @track productAttributeFilterCount = 0; 
    //Variable to handle the Asset Attribute Filter Button Event
    @track isAssetAttributeFilterActive = true;
    //Variable to handle the Product Attribute Filter Button Event
    @track isProductAttributeFilterActive = false;;
    //Variable to store the Selected Options for showing on Pill
    @track selectedSearchFieldPillOptions = ['All'];
    //Variable for Location Lookup Field Value
    @track locationrecordinfo = '';
    //Default Value to be shown in Level Combo
    @track defaultLevelValue = "Branch";

    //Variable to store the default value of Branch Level - Location Lookup Field Value
    defaultLocationRecordInfo;
    //Default Value to be shown in Level Combo Box
    defaultLevelComboBoxValue = "";
    //Variable for default valeu for Fields to Search Combo
    defaultFieldsToSearch = "All";
    //Variable to control the display of Location Lookup
    isCustomLookupVisible = "slds-show";
    //Variable to control the display of Region/Territory etc. Combo Box
    isLabelComboVisible = "slds-hide";
    //Variable to store all fields which can be selected for filter
    fieldsToSearchFieldOptions = [];
    //Variable to store all Selected Field Names
    selectedfieldsToSearchValues = ['All'];
    //Variable array for storing field api names
    apiNameArray = [];
    //Variable to store the selected value for asset query
    //if branch, it will be id, else it will be a picklist value selected
    selectedSearchValue = null;
    //Variable to store the default value of District Level Combo (Current User's District__c)
    defaultDistrictValue = null;
    //Variable to store the default value of Region Level Combo (Current User's Reporting_Region_Name__c)
    defaultRegionValue = null;
    //Variable to store the default value of Region Level Combo (Current User's Company_Code__c-Analysis_Region_Key__c)
    defaultAnalysisRegionValue = null;
    //Variable to store the default value of Region Level Combo (Current User's Territory__c)
    defaultTerritoryValue = null;
    //Variable to store the default value of Region Level Combo (Current User's Market_Name__c - Price_Market__c)
    defaultMarketValue = null;
    //Variable to store the selected Level Combo Picklist Value as backup
    //this will be used to fire when level field is changed
    selectedComboxBackupValue = null;
    //Variable to store the Field API name of selected level
    fieldAPIName = null;
    
    /**
     * This is the wired method to get the Level Options 
     * This will be fired on load
     * This gets the Level Options from Asset Inquiry Metadata
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
            this.defaultDistrictValue = jsonSelectedBranchRec['District__c'];
            this.defaultMarketValue = jsonSelectedBranchRec['Market_Name__c'] + ' - ' + jsonSelectedBranchRec['Price_Market__c'];
            this.defaultRegionValue = jsonSelectedBranchRec['Reporting_Region_Name__c'];
            this.defaultAnalysisRegionValue = jsonSelectedBranchRec['Company_Code__c'] + '-' + jsonSelectedBranchRec['Analysis_Region_Key__c'];
            this.defaultTerritoryValue = jsonSelectedBranchRec['Territory__c'];
        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is called when the Apply Button of AssetAttributeFilterCmp
     * This will acutually set the filter to be active and count of filters
     */
    @api handleApplyAssetAttributeFilterEvent(applyEventDetailRec){
        let selectedEquipmentTypeValues = [];
        let selectedStatusValues = [];
        if(applyEventDetailRec) {
            selectedEquipmentTypeValues = applyEventDetailRec.selectedEquipmentTypeValues;
            selectedStatusValues = applyEventDetailRec.selectedStatusValues;
            this.assetAttributeFilterCount = selectedEquipmentTypeValues.length + selectedStatusValues.length;
            this.isAssetAttributeFilterActive =  this.assetAttributeFilterCount > 0 ? true : false;
        }else{
            console.error("handleLevelPicklistSelectionEvent : Unable to get the Level Detail Record");
        }
    }

    /**
     * This is called when the Apply Button of AssetAttributeFilterCmp
     * This will acutually set the filter to be active and count of filters
     */
    @api handleProductAttributeFilterEvent(eventDetailRec){
        if(eventDetailRec) {
            let selectedFilterCount = eventDetailRec.selectedFilterCount;
            this.productAttributeFilterCount = selectedFilterCount;
            this.isProductAttributeFilterActive =  this.productAttributeFilterCount > 0 ? true : false;
        }else{
            console.error("handleProductAttributeFilterEvent : Unable to get the Level Detail Record");
        }
    } 

     /**
     * This method is called from Asset List Cmp when intializing
     * This event goes to Asset Header Cmp for setting fields in the filter combo box.
     */
    @api handleSearchFieldSetEvent(searchFieldSetRec){
        if(searchFieldSetRec){
            this.fieldsToSearchFieldOptions = searchFieldSetRec.searchfields;
        }

        //We are calling to here the handleBranchLookup because
        //This event is called when all fields are read by assetlist cmp and
        //sends the event back here.
        //ideally calling in wire method of getCurrentLocationForUser is ideal
        //But this will not help to fetch all data as by that time
        //wire of assetlistcmp is not called.
        if(this.locationrecordinfo){
           this.handleBranchLookup(this.locationrecordinfo);
        }
    }

    /**
     * This event is called when Branch is selected from Asset Availablility Modal Cmp
     * This will reset the Header to the selected Bracnch
     */
    @api handleBranchChange(branchChangeDetail){
        //Get the selected Branch Number
        let branchNumber = branchChangeDetail.branchnumber;
        //remove "Branch " word from branch number so that it can be used to do SOQL Query
        let branchNumberFormatted = branchNumber.replace('Branch ', '');
        let str = ''
        if (branchNumberFormatted.length === 3) {
            str = '0';
            branchNumberFormatted = str.concat(branchNumberFormatted);
        }
        else if (branchNumberFormatted.length === 2) {
            str = '00';
            branchNumberFormatted = str.concat(branchNumberFormatted);
        }
        else if (branchNumberFormatted.length === 1) {
            str = '000';
            branchNumberFormatted = str.concat(branchNumberFormatted);
        }
    
       //Get Branch details
       if(branchNumber){
            getBranchLocation({
                branchNumber: branchNumberFormatted
            })
            .then((data) => {
                if(data){
                    //Reset the Header Combo to "Branch" and the Value of Selected Branch to the selected Branch Number
                    let selectedLevelValue = "Branch";
                   
                    this.levelComboLabel = selectedLevelValue;
                    this.defaultLevelValue = selectedLevelValue;
                    this.levelComboPlaceHolder = "Select " + selectedLevelValue;

                    const levelCombo = this.template.querySelector(".levelcombo");
                    if (levelCombo) {
                        levelCombo.value = selectedLevelValue;
                    }

                    this.apiNameArray .forEach( item => {
                        if(item.label == selectedLevelValue){
                            this.fieldAPIName = item.value;
                        }
                    });
                    this.isCustomLookupVisible = "slds-show";
                    this.isLabelComboVisible = "slds-hide";

                    this.locationrecordinfo = data;
                    this.handleBranchLookup(this.locationrecordinfo);
                }
            })
            .catch((error) => {
                    console.log(error);
            });
       }
    }

    /**
     * This method handles the change event of Level Combo
     * This method updates the below Level Combo Box Visible deoending on Level Chosen
     * If Branch is selected, then show Location Lookup Field
     * If anything else, then show the Level Combo Box
     * It also fills the picklist values from Asset Inquiry Metadata
     */
    handleLevelChange(event) {
        //Get the user selected Level Value
        var selectedLevelValue = event.target.value;
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
                this.locationrecordinfo = {...this.defaultLocationRecordInfo};
                this.handleBranchLookup(this.locationrecordinfo);
            }
        //If the Level is not Branch, then hide the Location Lookup Visible and make visible the Level Combo Box 
        }else { 
            this.isCustomLookupVisible = "slds-hide";
            this.isLabelComboVisible = "slds-show";

            //Fire the query to get the picklist items depending on the selected level
            fetchPicklistMetadata({
                context: this.levelComboLabel
            })
            .then((data) => {
                let districtPickListItems = data; //var picklistItems = map1.get(this.levelComboLabel);
                let regionPickListItems = data;
                let marketPickListItems = data;
                let analysisRegionPickListItems = data;
                let territoryPickListItems = data;
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

                //Looping through Region Picklist Items
                regionPickListItems = data.filter( col => col.SM_PS_Context__c == 'Region');
                regionPickListItems.forEach( item => {
                    let comboOption = {};
                    this.levelComboLabelValue = item.SM_PS_PickList_Value__c;
                    comboOption.label = item.SM_PS_PickList_Value__c;
                    comboOption.value = item.MasterLabel;
                    this.levelComboOptions = [...this.levelComboOptions, comboOption];
 
                    if(item.SM_PS_Is_Default_Value__c){
                        this.defaultLevelComboBoxValue = item.SM_PS_PickList_Value__c;
                    }
                    
                });

                //Looping through Market Picklist Items
                marketPickListItems = data.filter( col => col.SM_PS_Context__c == 'Market');
                marketPickListItems.forEach( item => {
                    let comboOption = {};
                    this.levelComboLabelValue = item.SM_PS_PickList_Value__c;
                    comboOption.label = item.SM_PS_PickList_Value__c;
                    comboOption.value = item.MasterLabel;
                    this.levelComboOptions = [...this.levelComboOptions, comboOption];
 
                    if(item.SM_PS_Is_Default_Value__c){
                        this.defaultLevelComboBoxValue = item.SM_PS_PickList_Value__c;
                    }
                    
                });

                //Looping through Analysis Region Picklist Items
                analysisRegionPickListItems = data.filter( col => col.SM_PS_Context__c == 'Analysis Region');
                analysisRegionPickListItems.forEach( item => {
                    let comboOption = {};
                    this.levelComboLabelValue = item.SM_PS_PickList_Value__c;
                    comboOption.label = item.SM_PS_PickList_Value__c;
                    comboOption.value = item.MasterLabel;
                    this.levelComboOptions = [...this.levelComboOptions, comboOption];
 
                    if(item.SM_PS_Is_Default_Value__c){
                        this.defaultLevelComboBoxValue = item.SM_PS_PickList_Value__c;
                    }
                    
                });

                //Looping through Territory Picklist Items
                territoryPickListItems = data.filter( col => col.SM_PS_Context__c == 'Territory');
                territoryPickListItems.forEach( item => {
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
                    this.handleBranchLookup(this.locationrecordinfo);
                }
                if(this.defaultMarketValue != null && selectedLevelValue == "Market") {
                    this.defaultLevelComboBoxValue = this.defaultMarketValue;
                    this.handleBranchLookup(this.locationrecordinfo);
                }
                if(this.defaultRegionValue != null && selectedLevelValue == "Region") {
                    this.defaultLevelComboBoxValue = this.defaultRegionValue;
                    this.handleBranchLookup(this.locationrecordinfo);
                }
                if(this.defaultAnalysisRegionValue != null && selectedLevelValue == "Analysis Region") {
                    this.defaultLevelComboBoxValue = this.defaultAnalysisRegionValue;
                    this.handleBranchLookup(this.locationrecordinfo);
                }
                if(this.defaultTerritoryValue != null && selectedLevelValue == "Territory") {
                    this.defaultLevelComboBoxValue = this.defaultTerritoryValue;
                    this.handleBranchLookup(this.locationrecordinfo);
                }

            })
            .catch((error) => {
                console.log(error);
            });

            if(this.selectedSearchValue){
                this.selectedSearchValue = this.selectedComboxBackupValue;
                //this.handleLevelCombo();
            }
        }
    }

    /**
     * This method is called when Branch Lookup is changed or when initialized or when combobox of level
     * is changed to Branch.This will further propagate the selection event to Asset inquiry.
     */
    handleBranchLookup(selectedRecord){
        //Set the selectedSearchValue based on which Level (Branch/District/Inv Region) is selected
        if(this.levelComboLabel == "Branch") {
            let jsonSelectedBranchRec = JSON.parse(JSON.stringify(selectedRecord));
            this.selectedSearchValue = jsonSelectedBranchRec['Id'];
            this.locationrecordinfo = selectedRecord;
        }
        if(this.levelComboLabel == "District") {
            this.selectedSearchValue = this.defaultDistrictValue;
        }
        if(this.levelComboLabel == "Market") {
            this.selectedSearchValue = this.defaultMarketValue;
        }
        if(this.levelComboLabel == "Region") {
            this.selectedSearchValue = this.defaultRegionValue;
        }
        if(this.levelComboLabel == "Analysis Region") {
            this.selectedSearchValue = this.defaultAnalysisRegionValue;
        }
        if(this.levelComboLabel == "Territory") {
            this.selectedSearchValue = this.defaultTerritoryValue;
        }

        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const levelChangeEvent = new CustomEvent('levelchange', {
            'detail': {
                'fieldAPIName': this.fieldAPIName, 
                'fieldPickListValue' : this.selectedSearchValue,
                'isBranchChange' : 'Yes'                 
            }
        });
        this.dispatchEvent(levelChangeEvent);
    }

    /**
     * This method is called when Branch Record is selected in Lookup Box
     * This will further propagate the selection event to Asset inquiry
     */
    handleBranchLookupChange(event){
        //Get the Selected Location Record
        let selectedBranchRec= event.detail.selectedRecord;
        if(selectedBranchRec){
            this.handleBranchLookup(selectedBranchRec);
        }
    }

    /**
     * This method is called when Branch Record is selected in Lookup Box
     * This will further propagate the selection event to Asset inquiry 
     */
    handleLevelCombo(){
        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const levelChangeEvent = new CustomEvent('levelchange', {
            'detail': {
                'fieldAPIName': this.fieldAPIName, 
                'fieldPickListValue' : this.selectedSearchValue,
                'isBranchChange' : 'No'                
            }
        });
        this.dispatchEvent(levelChangeEvent);
    }

    /**
     * This method is called when Level Combox Picklist is selected
     * This will further propagate the selection event to Asset List Component
     */
    handleLevelComboPicklistChange(event){
        //Get the Selected Picklist Value for region, territory etc.
        let selectedLevelComboValue = event.detail.value;
        //If found, send it to event
        if(selectedLevelComboValue){            
            this.selectedSearchValue = selectedLevelComboValue;
            this.selectedComboxBackupValue = selectedLevelComboValue;
            this.handleLevelCombo();
        }
    }

    /**
     * This method is called when the ProductAttributeFilter Toggle Button is clicked
     * This will further propagate the selection event to Product Filter Component
     */
    handleProductAttributeFilterButtonClick(event){
        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const toggleProductFilterEvent = new CustomEvent('toggleproductfilter', {
            'detail': { 
                action : 'toggleProductAttributeFilterPanel'
             }
        });
        this.dispatchEvent(toggleProductFilterEvent);
    }

     /**
     * This method is called when the AssetAttributeFilter Toggle Button is clicked
     * This will further propagate the selection event to Asset Filter Component
     */
     handleAssetAttributeFilterButtonClick(event){
        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const toggleAssetFilterEvent = new CustomEvent('toggleassetfilter', {
            'detail': { 
                action : 'toggleAssetAttributeFilterPanel'
             }
        });
        this.dispatchEvent(toggleAssetFilterEvent);
    }

    /**
     * This method is called when Filter Search Combox Box is selected
     * This will make sure that the selected field is added to Pill
     */
    handleSearchFieldComboPicklistChange(event){
        //Get the Selected Picklist Value
        let selectedSearchField = event.detail.value;
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
     * This is propagated to AssetInquiryListCmp
     */
    handleSearchFilterChange(event){
        let searchKey = event.target.value;

        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const searchFilterChangeEvent = new CustomEvent('searchfilterchange', {
            'detail': { 
                action : 'searchfilterchange',
                searchKey : searchKey,
                fieldSelected : this.selectedfieldsToSearchValues
             }
        });
        this.dispatchEvent(searchFilterChangeEvent);
    }
}