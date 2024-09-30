import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_addOnItemCmp extends LightningElement {
    @api itemData;
    @api itemType;
    @api recordId;
    @api objectApiName;
    @api chronosEnabled;
    @api maxCount;
    @api parentQty;
    
    isMobile = false;
    itemDetailCatClass = 'itemDetail-catclass slds-p-bottom_xx-small slds-text-color_weak';
    itemDetailClass = 'itemDetail';
    itemDetailSalesPrice = 'itemDetail slds-p-bottom_xx-small';

    connectedCallback(){
        this.parentQty = 1; // Default Quantity on load
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
        if (this.isMobile){
            this.itemDetailClass = 'itemDetail-mobile';
            this.itemDetailSalesPrice = 'itemDetail-mobile slds-p-bottom_xx-small';
        }

        this.maxCount = this.itemData.value.availQuantity;
    }
    
    get isRentalItem () {
        return (this.itemType == "rental" && this.chronosEnabled == false) ? true : false;        
    }

    get isRentalItemChronos () {
        return (this.itemType == "rental" && this.chronosEnabled == true) ? true : false;        
    }

    get isSalesItem () {
        return (this.itemType == "sales" && this.chronosEnabled == false ) ? true : false;
    }

    get isSalesItemChronos () {
        return (this.itemType == "sales" && this.chronosEnabled == true) ? true : false;        
    }

    get hasAvailabilityInfo(){
        return this.itemData.value.availabilityInfo.length > 0;
    }
    //commented out for SAL-25140, users should be able to add sales add-ons with 0 quantity to their cart/order/quote)
    get isDisabled(){// SAL-22398
        // return (this.itemType == "sales" && (!this.itemData.value.availQuantity || this.itemData.value.availQuantity <= 0) ) ? true : false;   
        return false;
    }

    get isUnavailable(){
        return false;  

        // disables + greys out addto cart 
        // return (this.itemData.value.availabilityInfo.available == 'n/a' || this.itemData.value.availabilityInfo.available == '0') 
        //     && (this.isRentalItemChronos() || this.isSalesItemChronos());
    }

    get isRequiredAddOn(){
        return this.itemData && this.itemData?.value?.isRequired;
    }
}