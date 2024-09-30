import { LightningElement, api, wire, track } from 'lwc';
import getProductAddOns from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getProductAddOns';
import getConsumables from '@salesforce/apex/SBR_3_0_API_Consumables.getConsumableRates';
import getProductAvailabilities from '@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities';
import { refreshApex } from '@salesforce/apex';
import getConsumableRates from '@salesforce/apex/SBR_3_0_API_Consumables.getConsumableRates';
import getBranchDetails from "@salesforce/apex/SBR_3_0_BranchDA.getBranchDetails";

export default class Sbr_3_0_addOnsCmp extends LightningElement {
    @api variant = 'base';
    @api productId;
    @api rentalType = 'rental';
    @api salesType = 'sales';
    @api recordId;
    @api objectApiName;
    @api chronosEnabled;
    @api locationInfo;
    @api companyCode;
    @api parentProductBranch;
    @api parentQty;

    productName = '';
    type = 'summary';
    productDetails = [];
    estimateDetails;
    salesAOEmpty = true;
    rentalAOEmpty = true;
    rentalAvailEmpty = true;
    salesAvailEmpty = true;
    rentalAddonsLoaded = false;
    recordIdConst='';


    naBranchObject = {'available':'n/a','label':'Branch','pickUp':'n/a','reserve':'n/a','utilization':'n/a'};

    connectedCallback(){
        if(this.recordId) {
            this.recordIdConst = this.recordId;
        }  
   } 

      @wire(getProductAddOns, {productId: '$productId', companyCode: '$companyCode', recordId: '$recordIdConst',branch: '$parentProductBranch'})
    wiredProductAddOns({error, data}) {
        if (data) {
            this.productDetails = JSON.parse(data);
            let catClasses = [];
            for (let i=0;i<this.productDetails.rentalAddOns.length;i++){
                catClasses.push(this.productDetails.rentalAddOns[i].catClass);
                this.productDetails.rentalAddOns[i].itemType = 'rental';
            }
            for (let i=0;i<this.productDetails.salesAddOns.length;i++){
                catClasses.push(this.productDetails.salesAddOns[i].catClass);
                this.productDetails.salesAddOns[i].itemType = 'sales';
            }
            if(this.parentProductBranch){
                getBranchDetails({branchNumbers : new Array(this.parentProductBranch)}).then((branchData) => {
                  this.locationInfo = branchData[this.parentProductBranch];
                  getProductAvailabilities({products: catClasses,type: this.type, locationInfo: JSON.stringify(this.locationInfo)}).then(
                    result =>{
                    if(result) {
                        const map1 = new Map();
                        for (let i=0;i<result.length;i++){
                            map1.set(result[i].catClass, result[i]);
                        }
                        // append branch availabilities to rentalAddons[]
                        for (let i=0;i<this.productDetails.rentalAddOns.length;i++){
                            let availabilityInfo = map1.get(this.productDetails.rentalAddOns[i].catClass)?.availabilityInfo;
                            let branchObject;
                            if (availabilityInfo){
                                branchObject = availabilityInfo.find(item => item.label === 'Branch');
                            }
                            if(branchObject) {
                                this.productDetails.rentalAddOns[i].availabilityInfo = branchObject;
                            } else {
                                this.productDetails.rentalAddOns[i].availabilityInfo = this.naBranchObject;
                            }
                        }
                        this.rentalAvailEmpty = false;
                        // append branch availabilities to salesAddons[]
                        for (let i=0;i<this.productDetails.salesAddOns.length;i++){
                            let availabilityInfo = map1.get(this.productDetails.salesAddOns[i].catClass)?.availabilityInfo;
                            let branchObject;
                            if (availabilityInfo){
                                branchObject = availabilityInfo.find(item => item.label === 'Branch');
                            }
                            if(branchObject) {
                                this.productDetails.salesAddOns[i].availabilityInfo = branchObject;
                            } else {
                                this.productDetails.salesAddOns[i].availabilityInfo = this.naBranchObject;   
                            }
                        }
                        this.salesAvailEmpty = false;
                        this.rentalAddonsLoaded = true;            
                    } else {
                        this.rentalAddonsLoaded = true;
                    }
                });    
                this.salesAOEmpty = this.productDetails.salesAddOns.length > 0 ? false : true;
                this.rentalAOEmpty = this.productDetails.rentalAddOns.length > 0 ? false : true;
                this.updateIsAvailEmpty();

                }).catch(err => {
                  console.log('error in getBranchDetails',JSON.stringify(err));
                });
                
              }
            
        } else if (error) {
            console.log(error);
        }
    }

    updateIsAvailEmpty(){
        if (this.productDetails.salesAddOns != undefined) {
            this.salesAvailEmpty = (this.productDetails.salesAddOns[0]?.availabilityInfo != undefined) ? false : true;
        } else{
            this.salesAvailEmpty = true;
        }
        if (this.rentalAOEmpty != undefined) {
            this.rentalAvailEmpty = (this.productDetails.rentalAddOns[0]?.availabilityInfo != undefined) ? false : true;
        } else{
            this.rentalAvailEmpty = true;
        }
    }

    get isSalesAOEmpty(){
        return this.salesAOEmpty;
    }

    get isRentalAOEmpty(){
        return this.rentalAOEmpty;
    }

    get isSalesAvailEmpty(){
        return this.salesAvailEmpty;
    }

    get isRentalAvailEmpty(){
        return this.rentalAvailEmpty;
    }

    get isBase(){
        return this.variant == 'base';
    }

    get isCompact() {
        return this.variant == 'compact';
    }

    get isMobileRental(){
        return this.variant == 'isMobileRental';
    }

    get isMobileSales(){
        return this.variant == 'isMobileSales';
    }
    
    get isMobile(){
        return this.variant == 'mobile';
    }
}