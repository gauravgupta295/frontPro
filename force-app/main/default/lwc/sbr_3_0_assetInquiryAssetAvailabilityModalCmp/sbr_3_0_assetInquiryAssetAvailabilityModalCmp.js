import { LightningElement, api, track} from 'lwc';

//Get the Product Availabilities
import getProductAvailabilities from '@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities';
//CONSTANT FOR CATPURING ESC KEY
const ESC_KEY_CODE = 27;
//CONSTANT FOR CAPTURING ESC STRING
const ESC_KEY_STRING = 'Escape';

export default class Sbr_3_0_assetInquiryAssetAvailabilityModalCmp extends LightningElement {
    //Variable to store location info
    @api locationinfo = "";
    //Variable to store branch name
    @api branchname = "";
    //Variable to store the product cat class
    @api productcatclass = "";

    //Variable to store the Columns for Availablity Window
    columns = [
        {label: '', fieldName: 'label', hasSeparator: false},
        {label: 'Avail', fieldName: 'available', hasSeparator: true},
        {label: 'Rsrv', fieldName: 'reserve', hasSeparator: false},
        {label: 'Pkup', fieldName: 'pickUp', hasSeparator: false},
        {label: 'Util', fieldName: 'utilization', hasSeparator: false}
    ];
    //Variable to indicate if the Modal is Open or Not
    isOpen = false;
    //Variable to store current active tab
    activetabContent = 'District';
    //Variable to store current visible district tab rows
    @track districtRows = [];
    //Variable to store current visible region tab rows 
    @track regionRows = [];
    //Variable to store current visible territory tab rows
    @track territoryRows = [];
    //Variable to store current visible company tab rows
    @track companyRows = [];
    //Variable to store all rows got from Apex for District tab
    allDistrictRows = [];
    //Variable to store all rows got from Apex for Region tab
    allRegionRows = [];
    //Variable to store all rows got from Apex for Territory tab
    allTerritoryRows = [];
    //Variable to store all rows got from Apex for Company tab
    allCompanyRows = [];
    //Variable to the title for District tab
    districtTabTitle = "";
    //Variable to the title for Region tab
    regionTabTitle = "";
    //Variable to the title for Territory tab
    territoryTabTitle = "";
    //Variable to the title for Company tab
    companyTabTitle = "";

    /*
     * This method is called from Asset Inquiry Availablity Panel
     * This opens the Modal and setup the data.
     */
    @api toggleModal() {

        this.activetabContent = 'District';
        this.isOpen = !this.isOpen;

        if(this.isOpen){
            this.districtTabTitle = this.locationinfo.District__c;
            this.regionTabTitle = this.locationinfo.Region__c;
            this.territoryTabTitle = this.locationinfo.Territory__c;
            this.companyTabTitle = this.locationinfo.Company__c;

            this.getAvailability("District");
            this.getAvailability("Region");
            this.getAvailability("Territory");
            this.getAvailability("Company");
        }
    }

    /**
     * This method gets the availablity based on the Asset Selected 
     */
    getAvailability(type){
        if(this.productcatclass && this.locationinfo){
            getProductAvailabilities({products: this.productcatclass, 
                                      type: type, 
                                      locationInfo: JSON.stringify(this.locationinfo)})
            .then(
            result =>{
                if(result){
                    let rows = result[0].availabilityInfo;
                    if(type == "District"){
                        this.districtRows = rows;
                        this.allDistrictRows = rows;
                    }else if(type == "Region"){
                        this.regionRows = rows;
                        this.allRegionRows = rows;
                    }else if(type == "Territory"){
                        this.territoryRows = rows;
                        this.allTerritoryRows = rows;
                    }else if(type == "Company"){
                        this.companyRows = rows;
                        this.allCompanyRows = rows;
                    }
                }
                else {
                    console.log('Error in getting Avalability');
                }
            })
            .catch(error => {
                console.log(error);
            });
        }else{
            console.log('No CatClass and Location Info available');
        }
    }

    /**
     * This method is called when user types for Searching in the Search Input Box of 
     * District, Region, Territory and Company Tabs.
     */
    handleChange(event){

        if(event.target.value == '' || event.target.value == null){
            if(this.activetabContent == "District"){
                this.districtRows = this.allDistrictRows;
            }else if(this.activetabContent == "Region"){
                this.regionRows = this.allRegionRows;
            }else if(this.activetabContent == "Territory"){
                this.territoryRows = this.allTerritoryRows;
            }else if(this.activetabContent == "Company"){
                this.companyRows = this.allCompanyRows;
            } 
        }else{
            let search = event.target.value;
            let toBeFilteredRows = [];
            let filteredRows = [];

            if(this.activetabContent == "District"){
                toBeFilteredRows = this.allDistrictRows;
            }else if(this.activetabContent == "Region"){
                toBeFilteredRows = this.allRegionRows;
            }else if(this.activetabContent == "Territory"){
                toBeFilteredRows = this.allTerritoryRows;
                console.log('in territory selection');
            }else if(this.activetabContent == "Company"){
                toBeFilteredRows = this.allCompanyRows;
            }  

            for(var i = 0; i < toBeFilteredRows.length; i++){
                var labelValue = toBeFilteredRows[i].label;
                var lowerCaseValue = labelValue.toLowerCase();
                if(lowerCaseValue.indexOf(search.toLowerCase()) >= 0){
                    filteredRows.push(toBeFilteredRows[i]);
                }   
            }

            if(this.activetabContent == "District"){
                this.districtRows = filteredRows;
            }else if(this.activetabContent == "Region"){
                this.regionRows = filteredRows;
            }else if(this.activetabContent == "Territory"){
                this.territoryRows = filteredRows;
            }else if(this.activetabContent == "Company"){
                this.companyRows = filteredRows;
            }  
        }
    }

    /**
     * Gets the Modal Class
     */
    get modalClass() {
        const baseClass = "slds-modal outerModalContent ";
        return (
          baseClass + (this.isOpen ? "slds-visible slds-fade-in-open" : "slds-hidden")
        );
    }

    /**
     * Depending on if tab is open or not, Model Aria is set
     */
    get modalAriaHidden() {
        return !this.isOpen;
    }

    /**
     * This is close the Tab using Key Press event
     */
    handleKeyPress(event) {
        if(event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
            this.toggleModal();
        }
    }

    /**
     * This is to handle when tabs are switched.
     */
    handleTabChange(event){
        this.activetabContent = event.target.value;
    }

    /**
     * This will be called when user clicks on a Branch in Modal window.
     * This will close the modal and reset the asset inquiry to this branch
     */
    handleBranchSelection(event){
       this.toggleModal();

       let branchNumber = event.currentTarget.dataset.id;
       //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
       const branchChangeEvent = new CustomEvent('branchchange', {
        'detail': {
            'branchnumber' : branchNumber             
        }
        });
        this.dispatchEvent(branchChangeEvent);
    }
}