import { LightningElement, api,track} from 'lwc';
import fetchLocationfromBranchNumber from "@salesforce/apex/SBR_3_0_BranchDA.getBranchByBranchNumber";
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class Sbr_3_0_availabilityRowCmp extends LightningElement {
    @api rowData;
    @api rowKey;
    @api location;
    @track localLocation = {};
    @track branchLocationObj = {};
    @api isInModal = false;
    @api isInMobileAssets = false;
    branchLocation=false;
    @api omsflag;
    @api branchNumber;
    branchLocationChronos;
    @api spotlightbranch;
    showBranchDetails = false;

    get rowItem(){
        let item = this.rowData[this.rowKey];
        if(this.rowKey == 'label' && this.rowData[this.rowKey].includes('Branch')){
            //adding state, city and zip code to each row
            if(this.isInModal){
                this.branchLocationObj.state = this.rowData.state;
                this.branchLocationObj.city = this.rowData.city;
                this.branchLocationObj.zipcode = this.rowData.zipcode;
                this.showBranchDetails = true;
            }
            else if(this.isInModal == false && this.isInMobileAssets == false){
                if (this.omsflag) {
                    if (FORM_FACTOR === 'Small') {
                        item = 'branch ' + this.spotlightbranch;
                        this.branchNumber=this.spotlightbranch;
                    } else {
                        item = 'branch ' + this.branchNumber;
                    }
                    this.fetchLocation();
                    this.branchLocation= false;
                    this.branchLocationChronos=true;
                } else {
                    item = 'branch ' + this.branchNumber;
                    this.branchLocation = true;
                }
            }
        }else {
            item =  this.rowKey != 'label' && item != 'N/A'? item : item;
            this.branchLocation = false;
        }
        return item;
    }

    fetchLocation() {

        fetchLocationfromBranchNumber({ branchDisplayName: this.branchNumber })
            .then(result => {
                if (result && result.length > 0) {
                    this.localLocation.city = result[0].City__c;
                    this.localLocation.country = result[0].Country__c;
                    this.localLocation.zip = result[0].Zip_Code__c;
                    this.localLocation.state=result[0].State__c;
                } 
              
            })
            .catch(error => {
                // Handle error
                console.error("Error calling Apex method:", error);
            });
    }
    
}