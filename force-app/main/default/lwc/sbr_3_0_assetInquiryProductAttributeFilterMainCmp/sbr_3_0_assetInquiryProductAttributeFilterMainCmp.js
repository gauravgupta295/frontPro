import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_assetInquiryProductAttributeFilterMainCmp extends LightningElement {
    //Variable to find if the panel is visible or not
    isProductAttributeFilterPanelVisible = false;
    
    /**
     * This is called when the Toggle Button of Product Filter on header is clicked 
     * This will acutually call the code to show the product filter
     */
    @api handleToggleProductFilterEvent(data) {
        if (data.action == 'toggleProductAttributeFilterPanel') {
            this.handleToggleProductAttributeFilterPanelEvent(data);
        }
    }

    /**
     * This is called from multiple places
     * The aim is that if toggle panel is visible, then make it hidden and viceversa
     */
    handleToggleProductAttributeFilterPanelEvent(event){
        //If visible, make it hide, If hidden, make it visible
        this.isProductAttributeFilterPanelVisible = !this.isProductAttributeFilterPanelVisible;
        //Depending on the current status, set the class list property of filter panel
        if (this.isProductAttributeFilterPanelVisible) {
            this.template.querySelector('.product-attribute-filter-panel').classList.add('slds-is-open');
        } else {
            //this.closeIcon = this.closeIconSelected;
            this.template.querySelector('.product-attribute-filter-panel').classList.remove('slds-is-open');
        }
    }

    handleProductFilterChange(event){
        let productFilterRec = event.detail.selectedCatClass;
        let selectedFilterCount = event.detail.selectedFilterCount;

        //Send the event to AssetInquiryListComponentCmp to show filtered list
        const productFilterChangeEvent = new CustomEvent('productfilterchange', {
            'detail': { 
                action : 'productfilterchange',
                selectedCatClass : productFilterRec,
                selectedFilterCount : selectedFilterCount
             }
        });
        this.dispatchEvent(productFilterChangeEvent);
    }

    /**
     * 
     * 
     */
    getProductForSelectionEventDetail(event){
        let getproductforselectioneventdetail = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Product-Selection-Panel-Cmp').handleGetProductForSelectionEvent(getproductforselectioneventdetail);
    }

    /**
     *
     */
    resetFilterPanel(event){
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Product-Attribute-Filter-Cmp').handleResetFilter(event);
        this.applyFilter(event);
    }

    /**
     * 
     */
    applyFilter(event){
        this.handleToggleProductAttributeFilterPanelEvent();
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Product-Selection-Panel-Cmp').handleApplyFilter(event);
    }
}