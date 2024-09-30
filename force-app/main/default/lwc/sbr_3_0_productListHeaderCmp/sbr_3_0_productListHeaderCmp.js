import { LightningElement, api, wire, track } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import getProductSuperCats from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getProductSuperCategories';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
    publish
} from 'lightning/messageService';
import updateLineItemsChannel from '@salesforce/messageChannel/UpdateLineItemsChannel__c';
import pICartLoadedChannel from '@salesforce/messageChannel/PICartLoadedChannel__c';
import filterProductListChannel from '@salesforce/messageChannel/filterProductListChannel__c';
import { getRecord, createRecord, deleteRecord, updateRecord } from 'lightning/uiRecordApi';
import ORDER_ITEM_OBJECT from '@salesforce/schema/OrderItem';
import { NavigationMixin } from 'lightning/navigation';
import ORDER_ID_FIELD from '@salesforce/schema/OrderItem.OrderId';
import PRODUCT_ID_FIELD from '@salesforce/schema/OrderItem.Product2Id';
import PRICEBOOK_ENTRY_FIELD from '@salesforce/schema/OrderItem.PricebookEntryId';
import QUANTITY_FIELD from '@salesforce/schema/OrderItem.Quantity';
import UNIT_PRICE_FIELD from '@salesforce/schema/OrderItem.UnitPrice';



import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY = 500;

export default class Sbr_3_0_productListHeaderCmp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api isCustomerAdded;
    @api syncCustomerName;
    totalLineCount = 0;
    isListViewSelected = false;
    isProductFilterSelected = false;
    isAddCustomerSelected = false;
    isMobile = false;
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
    atcSubscription = null;
    clSubscription = null;
    fpSubscription = null;
    lineItems = [];
    filterCount = 0;
    isFilterActive = false;
    relatedListId = '';
    fields = [];
    @wire(MessageContext)
    messageContext;

    selectedClass = 'slds-button slds-button_neutral active-state';
    unselectedClass = 'slds-button slds-button_neutral selected-btn';
    itemSearchBackBtnClass = 'slds-button slds-button_neutral active-state';
    selectedFilterOptions = 'All Items'
    filterBtn = 'slds-icon';
    filterBtnSelected = 'slds-icon active-icon-state';

    isNotRecordPage = false;
    isOrderRecord = false;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: '$relatedListId',
        fields: '$fields'
    }) listInfo({ error, data }) {
        if (data) {
            this.cartItemsCount = data.records.length;
        } else if (error) {
            console.log(error);
        }
    }

    @api searchCompletionHandler(itemCount) {
        console.log(' list header searchCompletionHandler itemCount--> ' + itemCount);
        this.isItemSearchLoading = false;
        this.itemCount = itemCount;
    }

    connectedCallback() {
        this.initListViewOptions();
        if (this.recordId) this.initRecordContextVariables();
        this.subscribeToMessageChannel();
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        this.itemSearchBackBtnClass = this.unselectedClass;
        this.isNotRecordPage = !this.recordId && !this.objectApiName;
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    initListViewOptions() {
        getProductSuperCats()
            .then((data) => {
                if (data.length > 0) {
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

    initRecordContextVariables() {
        if (this.recordId) {
            switch (this.objectApiName) {
                case 'Cart__c':
                    this.relatedListId = 'Cart_Items__r';
                    this.fields = ['Cart_Items__c.Id', 'Cart_Items__c.Name'];
                    break;
                case 'SBQQ__Quote__c':
                    this.relatedListId = 'SBQQ__QuoteLine__r';
                    this.fields = ['SBQQ__QuoteLine__c.Id', 'SBQQ__QuoteLine__c.Name'];
                    break;
                case 'Order':
                    console.log('order context');
                    this.isOrderRecord = true;
                    break;
            }
        }
    }
    searchItems(event) {
        this.isItemSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.itemSearchUpdateHandler(searchKey);
        }, DELAY);
    }

    itemSearchUpdateHandler(searchKey) {
        this.searchKey = searchKey;
        const searchEvent = new CustomEvent('itemsearchupdate',
            {
                'detail': { searchKey: searchKey }
            }
        );
        this.dispatchEvent(searchEvent);
    }

    searchListViews(event) {
        this.isListViewSearchLoading = true;
        const searchKey = event.target.value;
        this.listViewOptions = this.allListViewOptions.filter(option => {
            if (option.label.toLowerCase().indexOf(searchKey.toLowerCase()) !== -1) return option;
        });
        this.isListViewSearchLoading = false;
    }

    toggleListView() {
        this.showListView = !this.showListView;
    }
    toggleOnListViewMob(event) {
        this.showListView = true;
        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            detail: {
                viewState: 'list-view',
                showTabsPanel: false
            }
        });
        this.dispatchEvent(toggleprodinqmobilestate);
    }

    toggleAddCustomerMob(event) {
        console.log("toggleAddCustomerMob");
        this.isAddCustomerSelected = true;
        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            detail: {
                viewState: 'cust-info',
                showTabsPanel: false
            }
        });
        this.dispatchEvent(toggleprodinqmobilestate);
    }

    backToItemSearch(event) {
        this.showListView = false;
        this.itemSearchBackBtnClass = this.selectedClass;

        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            detail: {
                viewState: 'base',
                showTabsPanel: true
            }

        });
        this.dispatchEvent(toggleprodinqmobilestate);
        this.itemSearchBackBtnClass = this.unselectedClass;
    }

    changeSelectedView(event) {
        this.selectedView = event.target.closest('li').dataset.key;
        this.itemSearchPlaceholder = `Search ${this.selectedView}...`;
        this.listViewOptions = this.listViewOptions.map(option => {
            option.isSelected = option.label === this.selectedView ? true : false;
            return option;
        });
        this.allListViewOptions = this.allListViewOptions.map(option => {
            option.isSelected = option.label === this.selectedView ? true : false;
            return option;
        });
        const filterViewEvent = new CustomEvent('listviewupdate', {
            'detail': {
                selectedView: this.selectedView,
                selectedCategories: [],
                selectedSubCategories: [],
                catSubCatWhere : ""
            }
        });
        this.dispatchEvent(filterViewEvent);
        this.toggleListView();
        if (this.isMobile) {
            const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                bubbles: true,
                composed: true,
                detail: {
                    viewState: 'item-search',
                    showTabsPanel: true
                }

            });
            this.dispatchEvent(toggleprodinqmobilestate);
        }
        this.filterCount = 0;
        const payload = { action: 'superCategoryChanged', category: this.selectedView };
        publish(this.messageContext, filterProductListChannel, payload);
    }

    handleViewCart(event) {
        const viewCartEvent = new CustomEvent('viewcart');
        this.dispatchEvent(viewCartEvent);
    }

    handleViewFilter(event) {
        const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
            bubbles: true,
            composed: true,
            'detail': {
                viewState: 'prod-filter',
                showTabsPanel: false,
            }
        });
        this.dispatchEvent(toggleprodinqmobilestate);
        this.showFilterView = !this.showFilterView;
        const payload = {
            action: 'toggleFilterPanel'
        };
        publish(this.messageContext, filterProductListChannel, payload);
    }

    subscribeToMessageChannel() {
        if (!this.atcSubscription) {
            this.atcSubscription = subscribe(
                this.messageContext,
                updateLineItemsChannel,
                (item) => this.updateLineItem(item),
                { scope: APPLICATION_SCOPE }
            );
        }
        if (!this.clSubscription) {
            this.clSubscription = subscribe(
                this.messageContext,
                pICartLoadedChannel,
                (data) => this.initializeCart(data),
                { scope: APPLICATION_SCOPE }
            );
        }
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
        unsubscribe(this.atcSubscription);
        this.atcSubscription = null;
        unsubscribe(this.clSubscription);
        this.clSubscription = null;
        unsubscribe(this.fpSubscription);
        this.fpSubscription = null;
    }

    updateLineItem(item) {
        if (item.type === 'add' && !('fromInitCart' in item)) {
            if (!item.isBulk) {
                this.lineItems.push(item.lineItem);
                console.log('this.lineItems  '+JSON.stringify(this.lineItems));
                this.cartItemsCount = this.lineItems.length;
                // this.cartItemsCount++;
            }
        }
        if (item.type === 'remove') {           
            if (item.recordId == this.recordId) this.cartItemsCount = item.lineItemsCount;
            if(item.lineItemsCount == 0){
                this.lineItems=[];
            }
        }
    }

    initializeCart(data) {
        if (!this.recordId && this.lineItems.length > 0) {
            
            this.lineItems.forEach(item => {
                const payload = {
                    recordId: null,
                    lineItem: item,
                    isBulk: false,
                    fromInitCart: true,
                    type: 'add'
                };
                publish(this.messageContext, updateLineItemsChannel, payload);    
            });

            /* temp fix above, something weird going on with bulk add and chronos in line item component
            const payload = {
                recordId: null,
                lineItem: this.lineItems.length === 1 ? this.lineItems[0] : this.lineItems,
                isBulk: this.lineItems.length === 1 ? false : true,
                type: 'add'
            };
            publish(this.messageContext, updateLineItemsChannel, payload);
            */
        }

    }

    handleFilterMessage(data) {
        if (data.action == "applyFilter") {
            this.filterCount = data.numberOfFilters;
            this.isFilterActive = data.numberOfFilters > 0 ? true : false;

            if (data.selectedFilterOptions.length == 0) {
                this.selectedFilterOptions = 'All Items'
            } else {
                this.selectedFilterOptions = data.selectedFilterOptions;
            }

            const filterViewEvent = new CustomEvent('listviewupdate', {
                'detail': {
                    selectedView: this.selectedView,
                    selectedCategories: data.selectedCategories,
                    selectedSubCategories: data.selectedSubCategories,
                    catSubCatWhere: data.catSubCatWhere //SAL-26801
                }
            });
            this.dispatchEvent(filterViewEvent);
        }
    }

    get listViewContainerClass() {
        return this.showListView ? 'slds-dropdown-trigger_click slds-is-open' : 'slds-dropdown-trigger_click';
    }

    get isCartEmpty() {
        return this.cartItemsCount == 0;
    }

    get listViewDisplay() {
        return this.showListView ? 'list-view-show' : 'list-view';
    }

    get productFilterDisplay() {
        return this.isProductFilterSelected ? 'product-filter-show' : 'product-filter';
    }

    get itemSearchDisplay() {
        return this.showListView ? 'header-mob-hide' : 'header-mob-show';
    }

    get customerIconDisplay() {
        return this.isNotRecordPage ? 'cust-icon-show' : 'cust-icon';
    }

}