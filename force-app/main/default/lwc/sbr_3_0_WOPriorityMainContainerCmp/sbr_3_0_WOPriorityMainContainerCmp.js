import { LightningElement,track  } from 'lwc';

export default class SBR_3_0_WOPriorityMainContainerCmp extends LightningElement {
    //Variable for Standard Filter Detail Record Event
    @track standardFilterDetailRec;
    //Variable for checking to run after renderedCallback() or not 
    runAfterRender = false;

    /**
     * This method is used it to perform logic after a component has finished the rendering phase.
    */
    renderedCallback(){
        if(this.runAfterRender) {
           this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleStandardFilterSelectionEvent(this.standardFilterDetailRec);
           this.template.querySelector('c-sbr_3_0_-w-o-Priority-Asset-Filter-Cmp').handleAssetAttributeButtonsEvent(this.standardFilterDetailRec);
           this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-Filter-Cmp').handleWOAttributeButtonsEvent(this.standardFilterDetailRec);       
        }
    }

    /**
     * This method is called when Level Combox Picklist is selected
     * This event comes from WOPriorityHeader Component when Level Combo Box is changed
     * This will further propagate the selection event to WOPriorityWOList Component
     */
    handleLevelChangeEvent(event){
        let levelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleLevelPicklistSelectionEvent(levelDetailRec);
    }

    /**
     * This method is called when Standard Filter is selected
     * This event comes from WOPriorityHeader Component when Standard Filter is changed
     * This will further propagate the selection event to WOPriorityWOList Component
     */
    handleStandardFilterChangeEvent(event) {
        this.standardFilterDetailRec = event.detail;
        if(this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp') == null) {
            this.runAfterRender = true;
        } else {
            this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleStandardFilterSelectionEvent(this.standardFilterDetailRec);
            this.template.querySelector('c-sbr_3_0_-w-o-Priority-Asset-Filter-Cmp').handleAssetAttributeButtonsEvent(this.standardFilterDetailRec);
            this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-Filter-Cmp').handleWOAttributeButtonsEvent(this.standardFilterDetailRec);
        }  
    }

    /**
     * This method is called when the AssetAttributeFilter Toggle Button is clicked
     * This event comes from WOPriorityHeader Component when Asset Attribute Toggle Button is clicked
     * This will further propagate the selection event to WOPriorityAssetFilter Component
     */
    handleToggleAssetFilter(event){
        let toggleLevelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-Asset-Filter-Cmp').handleToggleAssetFilterEvent(toggleLevelDetailRec);
    }

    /**
     * This method is called when the WorkOrderAttributeFilter Toggle Button is clicked
     * This event comes from WOPriorityHeader Component when WO Attribute Toggle Button is clicked
     * This will further propagate the selection event to WOPriorityWOFilter Component
     */
    handleToggleWOFilter(event){
        let toggleLevelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-Filter-Cmp').handleToggleWOFilterEvent(toggleLevelDetailRec);
    }

    /**
     * This method is called when the AssetAttributeFilter Apply Button is clicked
     * This event comes from Asset Attribute Filter - Apply Button and is propogated to WOPriorityWOList Component
     */
    handleApplyAssetAttributeFilterEvent(event){
        let applyAssetAttributeFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleApplyAssetAttributeFilterEvent(applyAssetAttributeFilterRec); 
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-Header-Cmp').handleApplyAssetAttributeFilterEvent(applyAssetAttributeFilterRec); 
    }

     /**
     * This method is called when the WOAttributeFilter Apply Button is clicked
     * This event comes from Work Order Attribute Filter - Apply Button and is propogated to WOPriorityWOList Component
     */
    handleApplyWOAttributeFilterEvent(event){
        let applyWOAttributeFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleApplyWOAttributeFilterEvent(applyWOAttributeFilterRec); 
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-Header-Cmp').handleApplyWOAttributeFilterEvent(applyWOAttributeFilterRec); 
    }

    /**
     * This method is called when the Search Key filter is changed Apply
     * This event comes from Search Key Input Box of Header and is propogated to WOPriorityWOList Component
     */
    handleSearchFilterChange(event){
        let searchKeyFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-w-o-List-Cmp').handleSearchFilterEvent(searchKeyFilterRec);  
    }

    /**
     * This method is called from WOPriorityWOList Component when intializing
     * This event goes to WOPriorityHeaderCmp for setting fields in the filter combo box.
     */
    handleSearchFieldSetEvent(event){
        let searchFieldSetRec = event.detail;
        this.template.querySelector('c-sbr_3_0_-w-o-Priority-Header-Cmp').handleSearchFieldSetEvent(searchFieldSetRec);   
    }
}