import { LightningElement, api, wire } from 'lwc';
import getProductSuperCats from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getProductSuperCategories';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
    publish
} from 'lightning/messageService';
import filterProductListChannel from '@salesforce/messageChannel/filterProductListChannel__c';
const DELAY = 500;

export default class Sbr_3_0_assetListHeaderCmp extends LightningElement {
    itemCount = 0;
    cartItemsCount = 0; //variable to use for cart items count
    isItemSearchLoading = false;
    isListViewSearchLoading = false;
    delayTimeout;
    listViewOptions = [{
        label: 'All Items',
        isSelected: true
    }];
    allListViewOptions;
    showListView = false;
    selectedView = 'All Items';
    itemSearchPlaceholder = `Search ${this.selectedView}...`;
    clSubscription = null;
    fpSubscription = null;
    lineItems = [];
    filterCount = 0;
    isFilterActive = false;

    locationrecordinfo = null;

    @api get syncLocation() {
        return this.locationrecordinfo;
    }
    set syncLocation(value) {
        this.locationrecordinfo = value;
    }

    @wire(MessageContext)
    messageContext;

    @api searchCompletionHandler(itemCount){
        this.isItemSearchLoading = false;
        this.itemCount = itemCount;
    }

    @api assetSelectionHandler(itemCount){
        console.log('In Asset List Header');
    }
    
    updateLocationInfo(event){
        let selectedRecord = event.detail.selectedRecord;
        console.log('Inside UpdateLocationInfo selectedRecord' + JSON.stringify(selectedRecord));
        if(selectedRecord)
        {
            this.locationrecordinfo = selectedRecord;
        }

        //let selectedRows = event.target.getSelectedRows();
        const selectedLocationEvent = new CustomEvent('locationselected', { detail: selectedRecord , bubbles: true, composed: true}); 
        console.log('selectedLocationEvent'+selectedLocationEvent.detail);
      
        this.dispatchEvent(selectedLocationEvent);
        //console.log('locationrecordinfo' + locationrecordinfo);
    }
    
    connectedCallback(){
        this.initListViewOptions();
        this.subscribeToMessageChannel();
    }
    
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    initListViewOptions(){
        getProductSuperCats()
        .then((data) => {
            if(data.length > 0){
                data.forEach((superCat) => {
                    this.listViewOptions.push({
                        label: superCat.Name,
                        isSelected: false
                    });
                });
                this.allListViewOptions = new Array(...this.listViewOptions);
            }
        })
        .catch((error) => {
            console.log(error);
        });
    }

    searchItems(event){
        this.isItemSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.itemSearchUpdateHandler(searchKey);
        }, DELAY);
    }

    itemSearchUpdateHandler(searchKey){
        this.searchKey = searchKey;
        const searchEvent = new CustomEvent('itemsearchupdate',
            {
                'detail': {searchKey: searchKey}
            }
        );
        this.dispatchEvent(searchEvent);
    }

    searchListViews(event){
        this.isListViewSearchLoading = true;
        const searchKey = event.target.value;
        this.listViewOptions = this.allListViewOptions.filter( option => {
            if(option.label.toLowerCase().indexOf(searchKey) !== -1) return option;
        });
        this.isListViewSearchLoading = false;
    }

    toggleListView(){
        this.showListView = !this.showListView;
    }

    changeSelectedView(event){
        this.selectedView = event.target.closest('li').dataset.key;
        this.itemSearchPlaceholder = `Search ${this.selectedView}...`;
        this.listViewOptions = this.listViewOptions.map( option => {
            option.isSelected = option.label === this.selectedView? true : false;
            return option;
        });
        this.allListViewOptions = this.allListViewOptions.map( option => {
            option.isSelected = option.label === this.selectedView? true : false;
            return option;
        });
        const filterViewEvent = new CustomEvent('listviewupdate', {
            'detail': {
                selectedView: this.selectedView, 
                selectedCategories: [],
                selectedSubCategories: []                        
            }
        });
        this.dispatchEvent(filterViewEvent);
        this.toggleListView();

        this.filterCount = 0;
        const payload = {action: 'superCategoryChanged', category: this.selectedView};
        publish(this.messageContext, filterProductListChannel, payload);
    }

    handleViewFilter(event) {
        this.showFilterView = !this.showFilterView;
        const payload = {
            action: 'toggleFilterPanel'
        };
        publish(this.messageContext, filterProductListChannel, payload);
    }

    subscribeToMessageChannel() {
        if (!this.fpSubscription) {
            this.fpSubscription = subscribe(
                this.messageContext,
                filterProductListChannel,
                (data) => this.handleFilterMessage(data),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.fpSubscription);
        this.fpSubscription = null;
    }

    handleFilterMessage(data){
        if (data.action == "applyFilter") {
            this.filterCount = data.numberOfFilters;
            this.isFilterActive = data.numberOfFilters > 0 ? true : false ;

            const filterViewEvent = new CustomEvent('listviewupdate', {
                'detail': {
                    selectedView: this.selectedView, 
                    selectedCategories: data.selectedCategories,
                    selectedSubCategories: data.selectedSubCategories                        
                }
            });
            this.dispatchEvent(filterViewEvent);
        } 
    }

    handleassetselectednew(data){
        console.log('handleassetselectednew');
    }

    get listViewContainerClass(){
        return this.showListView? 'slds-dropdown-trigger_click slds-is-open': 'slds-dropdown-trigger_click';
    }
}