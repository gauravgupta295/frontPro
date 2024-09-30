import { LightningElement, api, track } from 'lwc';
//Get the Picklist Metadata from Apex
import fetchBranchDetails from '@salesforce/apex/SBR_3_0_AssetInquiryController.getBranchDetails';
//Get the Product Availabilities
import getProductAvailabilities from '@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities';

export default class Sbr_3_0_assetInquiryAssetAvailablityPanelCmp extends LightningElement {
    //Variable to store the Product Name to shown in Availabilty Window Top
    @track productName = "";
    //Variable to store the Product Cat Class to shown in Availabilty Window Top 
    @track productCatClass = "";
    //Variable to store the Branch Code to shown in Availabilty Window Top
    @track branch = "";
    //Variable to store the Availability Rows feteched to shown in Availabilty Window Tops
    @track rows = [];

     //Variable to store the branchIds to shown in Availabilty Window Top
    branchId = "";
    //Variable to store the complete Location Object
    locationInfo = "";
    //Variable to store the Columns for Availablity Window
    columns = [
        {label: '', fieldName: 'label', hasSeparator: false},
        {label: 'Avail', fieldName: 'available', hasSeparator: true},
        {label: 'Rsrv', fieldName: 'reserve', hasSeparator: false},
        {label: 'Pkup', fieldName: 'pickUp', hasSeparator: false},
        {label: 'Util', fieldName: 'utilization', hasSeparator: false}
    ];

    /**
     * This method gets the availablity based on the Asset Selected 
     */
    getAvailability(){
        if(this.productCatClass && this.locationInfo){
            getProductAvailabilities({products: this.productCatClass, 
                                      type: 'summary', 
                                      locationInfo: JSON.stringify(this.locationInfo)})
            .then(
            result =>{
                if(result){
                    this.rows = result[0].availabilityInfo;
                }
                else {
                    console.log('error getting Avalability');
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
     * This method gets called when Asset is selected from the Asset List 
     * This will show the availablities based on the asset catclass and asset location
     */
    @api handleAssetSelectedEvent(selectedRows){
       if(selectedRows.length > 0){
        this.productCatClass = selectedRows[0].SM_PS_Cat_Class__c;
        this.productName = selectedRows[0].SM_PS_Miscellaneous_Options__c;
        this.branchId = selectedRows[0].SM_PS_Current_Location__c.substring(1,selectedRows[0].SM_PS_Current_Location__c.length);
        fetchBranchDetails({
            branchId : this.branchId
        })
        .then((data) => {
            if(data){
                this.branch = data.Branch_Location_Number__c;
                this.branchId = data.Id;
                this.locationInfo = data;
                this.getAvailability();
            }
        })
        .catch((error) => {
            console.log(error);
        });
       }else{
        this.productCatClass = "";
        this.productName = "";
        this.rows = [];
        this.branch = "";
        this.branchId = "";
        this.locationInfo = "";
       }
    }
    
    /**
     * This method calls Asset Inquiry Avaiablity Model Cmp to open up
     */
    showModalBox(event) {
        this.template.querySelector('c-sbr_3_0_asset-Inquiry-Asset-Availability-Modal-Cmp').toggleModal();
    }

    /**
     * This will be called when user clicks on a Branch in Modal window.
     * This needs to be propagated to Asset Inquiry header 
     */
    handleBranchChange(event){
        let branchNumber = event.detail.branchnumber;
        //Send the event to AssetInquiryMainContainerCmp to propogate to AssetInquiryListCmp
        const branchChangeEvent = new CustomEvent('branchchange', {
         'detail': {
             'branchnumber' : branchNumber             
         }
         });
         this.dispatchEvent(branchChangeEvent);
     }
}