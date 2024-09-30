import { LightningElement, api, wire, track} from 'lwc';

export default class Sbr_3_0_prodInqMobCtrCmp extends LightningElement {

    @api tabsPanelHeight;

    selectedClass = 'slds-button slds-button_neutral active-state';
    unselectedClass = 'slds-button slds-button_neutral selected-btn';
    itemSearchBtnClass = 'slds-button slds-button_neutral active-state';
    cartBtnClass =  'slds-button slds-button_neutral selected-btn';
    activeTab = 'item-search';
    isLineItems;
    @track showListViews = false;
    message;

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

    handleShowListViews(event){
        this.showListViews = event.detail.showListViews.valueOf();        
    }

    get itemSearchDisplay() {
        return this.activeTab == 'item-search' ?  'item-search show' : 'item-search';
    }
    get lineItemsDisplay() {
        return this.activeTab == 'cart' ? 'line-items show' : 'line-items';
    }
    
}