import { LightningElement, api, wire } from 'lwc';
import getProductKitComponents from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductKitComponents';
import * as SBRUtils from 'c/sbrUtils';

export default class Sbr_3_0_kitComponentsCmp extends LightningElement {
    @api productId;
    @api isKitUnpackaged;
    @api itemQty;
    kitItems = [];
    showNoKitCmpAvailableMsg = false;
    noKitComponentAvailableMsg = 'Kit Components not available.';

    @wire(getProductKitComponents, {productId: '$productId'})
    wiredProductKitComponents({error, data}) {
        if(data) {
            let details = JSON.parse(data);
            this.kitItems = details;
            if (!SBRUtils.isEmpty(this.kitItems)) {
            // Loop through kitItems and update SBQQ__Quantity__c
            this.kitItems.forEach(kitItem => {
                if (kitItem.SBQQ__Quantity__c === null) {
                    kitItem.SBQQ__Quantity__c = this.itemQty;
                }
            });
            } else {
                this.showNoKitCmpAvailableMsg = true;
            }
        }else if(error) {
            this.showNoKitCmpAvailableMsg = true;
            this.noKitComponentAvailableMsg = 'Error retrieving kit components';
            console.error('Error retrieving kit components ' + error.message);
        }
    }
    get isKitUnPackaged() {
        return this.isKitUnpackaged == true ? true : false;
    }
}