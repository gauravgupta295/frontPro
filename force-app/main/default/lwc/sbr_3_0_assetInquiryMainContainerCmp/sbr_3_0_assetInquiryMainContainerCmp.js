import { LightningElement, track } from 'lwc';

export default class Sbr_3_0_assetInquiryMainContainerCmp extends LightningElement {
    //@track boolean variable to indicate if modal is open or not. Default value is false as modal is closed when page is loaded
    @track isModalOpen = false;
    runAfterRender = false;
    @track selectedRows;

    /**
     * This method is used it to perform logic after a component has finished the rendering phase.
    */
    renderedCallback(){
        if(this.runAfterRender) {
            this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Availablity-Panel-Cmp').handleAssetSelectedEvent(this.selectedRows); 
            this.runAfterRender = false;
        }
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

    /**
     * This method is called when Level Combox Picklist is selected
     * This event comes from AssetHeaderComponent when Level Combo Box is changed
     * This will further propagate the selection event to Asset List Component
     */
    handleLevelChangeEvent(event){
        let levelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-List-cmp').handleLevelPicklistSelectionEvent(levelDetailRec);
        //this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Availablity-Panel-Cmp').handleLevelPicklistSelectionEvent(levelDetailRec);
        
    }

    /**
     * This method is called when the AssetAttributeFilter Toggle Button is clicked
     * This event comes from AssetHeaderComponent when Asset Attribute Toggle Button is clicked
     * This will further propagate the selection event to Asset Filter Component
     */
    handleToggleAssetFilter(event){
        let toggleLevelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Filter-Cmp').handleToggleAssetFilterEvent(toggleLevelDetailRec);
    }

     /**
     * This method is called when thea ProductAttributeFilter Toggle Button is clicked
     * This event comes from AssetHeaderComponent when Product Attribute Toggle Button is clicked
     * This will further propagate the selection event to Product Filter Component
     */
     handleToggleProductFilter(event){
        let toggleLevelDetailRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Product-Attribute-Filter-Main-Cmp').handleToggleProductFilterEvent(toggleLevelDetailRec);
    }

    /**
     * This method is called when the AssetAttributeFilter Apply Button is clicked
     * This event comes from Asset Attribute Filter - Apply Button and is propogated to AssetListComponent
     */
    handleApplyAssetAttributeFilterEvent(event){
        let applyAssetAttributeFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-List-Cmp').handleApplyAssetAttributeFilterEvent(applyAssetAttributeFilterRec); 
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Header-cmp').handleApplyAssetAttributeFilterEvent(applyAssetAttributeFilterRec); 
    }
    /**
     * This method is called when the Search Key filter is changed Apply
     * This event comes from Search Key Input Box of Header and is propogated to AssetListComponent
     */
    handleSearchFilterChange(event){
        let searchKeyFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-List-Cmp').handleSearchFilterEvent(searchKeyFilterRec);  
    }

    /**
     * This method is called from Asset List Cmp when intializing
     * This event goes to Asset Header Cmp for setting fields in the filter combo box.
     */
    handleSearchFieldSetEvent(event){
        let searchFieldSetRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Header-cmp').handleSearchFieldSetEvent(searchFieldSetRec); 
    }

    /**
     * This method is called when Asset is Selected 
     * This event is propogated further to Asset Availability Component
     */
    handleAssetRowSelection(event){
        this.selectedRows = event.detail;
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;

        if(this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Availablity-Panel-Cmp') == null) {
            this.runAfterRender = true;
        } else {
            this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Availablity-Panel-Cmp').handleAssetSelectedEvent(this.selectedRows); 
            this.runAfterRender = false;
        }  
    }
    
    /**
     * This method is called when Product Filter is applied
     * This event is further propogated to Header and List Cmp
     */
    handleProductFilterChange(event){
        let productFilterRec = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-List-Cmp').handleProductFilterEvent(productFilterRec);
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Header-cmp').handleProductAttributeFilterEvent(productFilterRec);
    }

    /**
     * This event is called when Branch is selected from Asset Availablity Model Cmp
     */
    handleBranchChange(event){
        let branchChangeDetail = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Header-cmp').handleBranchChange(branchChangeDetail);
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
}