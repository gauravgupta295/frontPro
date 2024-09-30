import { LightningElement, wire } from 'lwc';
import getQuickLinks from '@salesforce/apex/SBR_3_0_PurchaseOrderQuickLinks.getQuickLinks';
import { loadStyle } from 'lightning/platformResourceLoader';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import FORM_FACTOR from "@salesforce/client/formFactor";
import mobileView from './templates/mobile.html';
import desktopView from './templates/desktop.html';

const SMALL_FORM_FACTOR = "Small";

export default class Sbr_3_0_purchaseOrderAppPageMain extends LightningElement {
    quickLinks = [];
    searchString;
    isCSSLoaded = false;
    hasRendered = false;
    vendorClass = 'slds-show';
    purchaseOrderClass = 'slds-hide';

    @wire(getQuickLinks)
    wiredQuickLinks(result) {        
        if (result.data) {
            console.log(result.data);
            this.quickLinks = result.data;
        }
        else {
            console.log(result.error);
        }
    }
    renderedCallback() {
        if (!this.isCSSLoaded) {
            loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
        if (this.isMobileView && !this.hasRendered) {
            this.hasRendered = true;
            this.refs.vendors.classList.add('activeTab');
        }
    }

    render(){
        return (this.isMobileView === true) ? mobileView : desktopView;
    }

    get isMobileView() {
        return FORM_FACTOR === SMALL_FORM_FACTOR;
    }

    handleClear(event) {
        if (!event.target.value.length) {
            this.template.querySelector('c-sbr_3_0_get-all-vendors').getVendors('default');
            this.template.querySelector('c-sbr_3_0_get-all-purchase-orders').handleSearch();            
        }
    }

    handlePOClear(event) {
        if (!event.target.value.length) {
            this.template.querySelector('c-sbr_3_0_get-all-purchase-orders').handleSearch();            
        }
    }

    handleVendorClear(event) {
        if (!event.target.value.length) {
            this.template.querySelector('c-sbr_3_0_get-all-vendors').getVendors('default');         
        }
    }

    handleClick(event) {
        let tabVal = event.currentTarget.dataset.id;
        if (tabVal === 'vendors') {
            this.refs.vendors.classList.add('activeTab');
            this.refs.purchaseOrders.classList.remove('activeTab');
            this.vendorClass = 'slds-show';
            this.purchaseOrderClass = 'slds-hide';
        }
        else if (tabVal === 'purchaseOrders') {
            this.refs.purchaseOrders.classList.add('activeTab');
            this.refs.vendors.classList.remove('activeTab');
            this.purchaseOrderClass = 'slds-show';
            this.vendorClass = 'slds-hide';
        }
    }

    handleSearch(event) {
        if(event.key === "Enter"){
            let inputCmp = this.template.querySelector( 'lightning-input');
    
            if (inputCmp.checkValidity()) {
                this.searchString = event.target.value;
                console.log(this.searchString);
                this.template.querySelector('c-sbr_3_0_get-all-vendors').handleSearch(this.searchString);
                this.template.querySelector('c-sbr_3_0_get-all-purchase-orders').handleSearch(this.searchString);
            }
        }
    }

    handlePOSearch(event){
        if(event.key === "Enter"){
            let inputCmp = this.template.querySelector( 'lightning-input');
    
            if (inputCmp.checkValidity()) {
                this.searchString = event.target.value;
                console.log(this.searchString);

                this.template.querySelector('c-sbr_3_0_get-all-purchase-orders').handleSearch(this.searchString);
            }
        }
    }

    handleVendorSearch(event){
        if(event.key === "Enter"){
            let inputCmp = this.template.querySelector( 'lightning-input');
    
            if (inputCmp.checkValidity()) {
                this.searchString = event.target.value;
                console.log(this.searchString);

                this.template.querySelector('c-sbr_3_0_get-all-vendors').handleSearch(this.searchString);
            }
        }
    }
    
}