import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_assetListContainerCmp extends LightningElement {
    @api tabsPanelHeight;
    
    get listHeight() {
        let listHeaderHeight = this.template.querySelector('.list-header-container')? this.template.querySelector('.list-header-container').offsetHeight : 75;
        return (this.tabsPanelHeight - listHeaderHeight);
    }
    handleSelectedRows(event){
        let selectedRows = event.detail;
        const selectedRowsEvent = new CustomEvent('rowsselected', { detail: selectedRows });
        this.dispatchEvent(selectedRowsEvent);
    }
    handleItemSearch(event){
        let data = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-list-cmp').searchAssetList(data.searchKey);
    }
    handleListViewChange(event){
        let data = event.detail;

        this.template.querySelector('c-sbr_3_0_asset-list-cmp').filterAssetList({
            'filterType': 'Super_Category__c',
            'filterValue': data.selectedView,
            'selectedCategories': data.selectedCategories,
            'selectedSubCategories': data.selectedSubCategories                        
        });
    }
    handleSearchCompletion(event){
        let itemCount = event.detail;
        this.template.querySelector('c-sbr_3_0_asset-list-header-cmp').searchCompletionHandler(itemCount);
    }
    handleassetselectednew(event){
        console.log('handleassetselectednew');
        let selectedRows = event.detail;
        const selectedRowsEvent = new CustomEvent('assetselectednew', { detail: selectedRows});
        this.dispatchEvent(selectedRowsEvent);
    }

    handledselectedlocation(event){
        console.log('handledselectedlocation: '+JSON.stringify(event.detail));
        let selectedlocation = event.detail;
        const selectedlocEvent = new CustomEvent('locationselectednew', { detail: selectedlocation});
        this.dispatchEvent(selectedlocEvent);
    }
}