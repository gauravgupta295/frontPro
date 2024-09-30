import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sbr_3_0_quickQuoteContainerCmp extends LightningElement {
    isMobile = false;
    tabsPanelHeight;
    @track selectedCustomer;
    selectedCustomerId='';
    loadingcomplete = false;
    //start prod inq mob ctr attributes
    selectedClass = 'slds-button slds-button_neutral active-state';
    unselectedClass = 'slds-button slds-button_neutral selected-btn';
    itemSearchBtnClass = 'slds-button slds-button_neutral active-state';
    cartBtnClass =  'slds-button slds-button_neutral selected-btn';
    activeTab = 'item-search';
    isLineItems;
    //@track showListViews = false;
    message;
    selectedProducts = [];
    @track showTabsPanel = true;
    //end prod inq mob ctr attributes

    isFirstRender = true;

    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }
    renderedCallback(){
        if(!this.isMobile){
            this.tabsPanelHeight = this.template.querySelector('.tabs-container').offsetHeight - 64;
            if (this.isFirstRender) {   
                this.isFirstRender = false;
                 //activate the cart tab first and then load/focus itemsearch
                this.template.querySelector('lightning-tabset').activeTabValue = 'Cart';
                console.log('cart tab loaded');
                this.template.querySelector('lightning-tabset').activeTabValue = 'ItemSearch';
                console.log('ItemSearch tab loaded');
            }
        }
    }

    handleCartActive() {
        this.selectedCustomer = { ...this.selectedCustomer };
    }
    
    handleViewCart(event) {
        this.template.querySelector('lightning-tabset').activeTabValue = 'Cart';
    }
    syncCustomerInfo(event) {
        this.selectedCustomer = event.detail.selectedRecord? event.detail.selectedRecord : {};
      }
      
    showToast(evt) {
        const event = new ShowToastEvent({
            title: 'Error Message',
            message: 'Please contact your System Administrator. Error: ' + evt.detail,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    //start prod inq mob ctr methods
    //method to toggle between Item Search and Cart tabs on Product Inquiry custom tab
    toggleProdInqMobile(e){
        let currentState = e.target.value;
        this.itemSearchBtnClass = this.unselectedClass;
        this.cartBtnClass = this.unselectedClass;
        switch(currentState){
            case 'Item Search':
                this.itemSearchBtnClass = this.selectedClass;
                this.activeTab = 'item-search';
                break;
            case 'Cart':
                this.cartBtnClass = this.selectedClass;
                this.activeTab = 'cart';
                break;
            default:
                break;
        }
    }

    handleToggleProdInqMobileState(event){
        try {
        this.showTabsPanel = event.detail.showTabsPanel.valueOf();
            console.log('showTabsPanel: ', this.showTabsPanel);
        } catch (error){
            console.log('error: ', error);
    }
    }
    // get showTabsPanelDisplay() {
    //     console.log('showTabsPanel: ', this.showTabsPanel);
    //     return this.showTabsPanel == true ? 'tabs-panel show' : 'tabs-panel';
    // }
    get itemSearchDisplay() {
        return this.activeTab == 'item-search' ?  'item-search show' : 'item-search';
    }
    get lineItemsDisplay() {
        return this.activeTab == 'cart' ? 'line-items show' : 'line-items';
    }
    //end prod inq mob ctr methods
}