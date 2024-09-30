import {LightningElement, track, api} from 'lwc';

//Get the Product Availabilities
import getProductAvailabilities from '@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities';

export default class Sbr_3_0_assetInquiryAssetRowCmp extends LightningElement {
    @api rowData;
    @api rowKey;
    @api location;
    branchLocation = false;

    get rowItem(){
        let item = this.rowData[this.rowKey];

        /**if(this.rowKey == 'label' && this.rowData[this.rowKey].includes('Branch')){
            item = 'branch ' + this.location.Branch_Location_Number__c;
            this.branchLocation = true;
        }else{
            item =  this.rowKey != 'label' && item != 'N/A'? item : item;
            this.branchLocation = false;
        }*/

        return item;
    }
}