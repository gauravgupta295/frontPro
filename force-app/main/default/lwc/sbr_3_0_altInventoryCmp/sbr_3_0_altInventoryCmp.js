import { LightningElement, api, wire, track } from 'lwc';
import getAlternateProducts from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getAlternateProducts';
import getProductAvailabilities from '@salesforce/apex/SBR_3_0_AvailabilityCmpController.getProductAvailabilities';
import getBranchPhones from '@salesforce/apex/SBR_3_0_SpotlightPanelCmpController.getBranchPhones';
import getAltInventory from '@salesforce/apex/SBR_3_0_AvailabilityBadgeCmpController.getAltInventory';
import getATI from '@salesforce/apex/SBR_3_0_AvailabilityBadgeCmpController.getATI'; 
import findAlternateProductsByLocation from '@salesforce/apex/SBR_3_0_AvailabilityController.findAlternateProductsByLocation'; 


export default class Sbr_3_0_altInventoryCmp extends LightningElement {
    @api variant = 'base';
    @api itemType = 'altInventory';
    @api productId = '';
    @api chronosEnabled;
    @api branchId;
    @api branchPhone;
    @api type = 'summary';
    @api locationInfo;
    @api itemQty;
    @api syncCartInfo;
    @api productCatclass;
    @api companyCode;
    showSpinner = true;

    _recordId = null;

    @api set recordId(value) {
        if(value){
            this._recordId = value;
        }
    }

    get recordId() {
    return this._recordId;
    }
    
    branchPhoneMap = new Map();
    altInventoryMap = new Map();

    branchList = [];
    catClassList = []; 
    @track inventoryItems = [];
    completedMethodsList = {'getProductAvailabilities':false,'getAltInventory':false,'getBranchPhones':false};
    
    altItemsEmpty = true;
    altItemsAvailEmpty = true;
    altItemsBranchATPEmpty = true;
    branchPhonesEmpty = true;
    isShowAltInventoryItems = false;
    atiResponse;

    isMobile = false;

    naBranchObject = {'available':'n/a','label':'Branch','pickUp':'n/a','reserve':'n/a','utilization':'n/a'};

    connectedCallback(){
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }


    @wire(findAlternateProductsByLocation, {recordId: '$recordId',productId: '$productId',branchNumber:'$branchId', companyCode: '$companyCode',accountNumber: null})
    wiredAlternateProducts({error, data}) {
        if(this.chronosEnabled){
            this.itemType = 'altInventoryChronos';
            this.variant = 'altInventoryChronos';
        }
        // reset variables for mobile, to re-render.
        if (this.isMobile){
            this.resetFields();
        }

        if(data) {
            this.inventoryItems = JSON.parse(JSON.parse(data).alternateProducts);
            this.atiResponse = JSON.parse(JSON.parse(data).atiResponse);
            console.log("----- productId: " + this.productId);
            console.log("----- altInventoryItems: " + JSON.stringify(this.inventoryItems));
            for (let i=0;i<this.inventoryItems.length;i++){
                if (this.inventoryItems[i].catClass.length == 7) {
                    this.catClassList.push(this.inventoryItems[i].catClass);
                }                 
                // this may take longer than the API to execute
                this.inventoryItems[i].locationItemInfo = {
                    "lineId": null,
                    "requestQuantity": this.itemQty,
                    "fulfillQuantity": "n/a",
                    "productId": this.inventoryItems[i].catClass,
                    "pc": this.branchId,
                    "branchPhone": null
                }
                this.inventoryItems[i].availabilityInfo = {
                    "available": "n/a",
                    "label": "Branch",
                    "pickUp": "n/a",
                    "reserve": "n/a",
                    "utilization": "n/a",
                }
            }
            this.altItemsEmpty = this.inventoryItems.length > 0 ? false : true;
            this.isShowDefaultValues = true;
            if(this.chronosEnabled) {
                // get Util values from availabilities.
                getProductAvailabilities({products: this.catClassList,type: this.type, locationInfo: JSON.stringify(this.locationInfo)}).then(
                    data =>{
                        if(data) {
                            console.log('getProductAvailabilities result ->');
                            console.log(JSON.stringify(data, null, 2));
                            const availMap = new Map();
                            for (let i=0;i<data.length;i++){
                                availMap.set(data[i].catClass, data[i]);
                            }
                            // append Branch availability data
                            for (let i=0;i<this.inventoryItems.length;i++){
                                let catClass = this.inventoryItems[i].catClass;
                                let availabilityInfo = availMap.get(catClass)?.availabilityInfo;
                                let branchObject;
                                if (availabilityInfo){
                                    branchObject = availabilityInfo.find(item => item.label === 'Branch');
                                }
                                // console.log('branchObject ->');
                                // console.log(branchObject);
                                if(branchObject) {
                                    this.inventoryItems[i].availabilityInfo = branchObject;
                                } else {
                                    this.inventoryItems[i].availabilityInfo = this.naBranchObject;
                                }
                                // console.log('availabilityInfo -> ');
                                // console.log(availabilityInfo);
                            }
                            this.completedMethodsList.getProductAvailabilities = true; 
                            this.callGetAltInventoryAPI();
                        } else {
                            console.log('Error in altInventory getProductAvailabilities');
                            this.completedMethodsList.getProductAvailabilities = true; 
                            this.callGetAltInventoryAPI();
                        }
                    });
            } else if (!this.chronosEnabled) {
                this.callGetAltInventoryAPI();
                this.showAltInventoryItems();
            }
        this.showSpinner = false;   
        }
        else if(error) {
            console.log("----- productId: " + this.productId);
            console.log('----- error:');
            console.log(error);    
        this.showSpinner = false;          
        }
    }

    callGetAltInventoryAPI(){
        console.log('recordId ->', this.recordId);
            let result = this.atiResponse;
            if(result) {
                if (result.data != null && result.data.availabilityByTransactionType != null) {
                    let transactionTypes = result.data.availabilityByTransactionType.map(item => {return item});

                    let prodIdIgnore = [];
                    let zeroInventoryProductBranches = {};
                    transactionTypes.forEach((transaction, i) => {
                        
                        transaction.availabilityByProducts.forEach((availability, j) => {

                            let fulfillment = availability.availabilityByFulfillmentTypes[0];
                            let availabilityDetails = fulfillment.availabilityDetails[0];
                            availabilityDetails.availabilityByLocations.forEach((loc, k) => {
                                // console.log('loc below:');
                                // console.log(loc);
                                loc.badge1=false;
                                loc.badge2=false;
                                loc.badge3=false;
                                loc.badge4=false;
   
                                // console.log('loc.locationId ->');
                                // console.log(loc.locationId);
                        
                                let pcArr = loc.locationId.split('-');
                                loc.pc = pcArr[0];
                                if(pcArr.length > 1) {
                                    loc.pc = pcArr[1];
                                }
                                
                                this.branchList.push(loc.pc);
                                if(loc.atp > 0 && transaction.transactionType == 'SBR' && !prodIdIgnore.includes(availability.productId)) {
                                    // console.log('transaction.transactionType 177-->',transaction.transactionType);
                                    // console.log('loc.atp 178-->',loc.atp);
                                    loc.badge1 = true;
                                    loc.atpLabel = 'Adj. ATP: ';
                                    this.altInventoryMap.set(availability.productId, loc);
                                    prodIdIgnore.push(availability.productId);
                                }
                                if(loc.atp > 0 && transaction.transactionType == 'SBR24' && !prodIdIgnore.includes(availability.productId)) {
                                    // console.log('transaction.transactionType 185-->',transaction.transactionType);
                                    // console.log('loc.atp-->186',loc.atp);
                                    loc.badge2 = true;
                                    loc.atpLabel = 'ATP: ';
                                    this.altInventoryMap.set(availability.productId, loc);
                                    prodIdIgnore.push(availability.productId);
                                }
                                if(loc.atp > 0 && transaction.transactionType == 'SBR72' && !prodIdIgnore.includes(availability.productId)) {
                                    // console.log('transaction.transactionType 193-->',transaction.transactionType);
                                    // console.log('loc.atp 194-->',loc.atp);
                                    loc.badge2 = true;
                                    loc.atpLabel = 'Controlled: ';
                                    this.altInventoryMap.set(availability.productId, loc);
                                    prodIdIgnore.push(availability.productId);
                                } else {
                                    zeroInventoryProductBranches[availability.productId] = zeroInventoryProductBranches[availability.productId] || [];
                                    zeroInventoryProductBranches[availability.productId].push(loc.pc);
                                }
                            });

                            // Last Resort Branch
                            if(!prodIdIgnore.includes(availability.productId) && 
                            transaction.transactionType == 'SBR72' && 
                            availabilityDetails.availabilityByLocations.length <= 0){
                                let lastResortBranch = (transaction.lastResortBranch) ? transaction.lastResortBranch.split('-')[1] : this.locationInfo.Branch_Location_Number__c;
                                console.log('transaction.lastResortBranch -> ' + transaction.lastResortBranch);
                                zeroInventoryProductBranches[availability.productId] = zeroInventoryProductBranches[availability.productId] || [];
                                zeroInventoryProductBranches[availability.productId].push(lastResortBranch);
                                this.branchList.push(lastResortBranch);
                            }
                        });
                    });

                    // add reds for products in our catClassList but not in our prodIdIgnore list. These are Ids that didn't return with values
                    this.catClassList.forEach((catClass, i) => {
                        if(!prodIdIgnore.includes(catClass)) {
                            let loc = { 
                                badge4 : true, 
                                pc : zeroInventoryProductBranches[catClass] ? zeroInventoryProductBranches[catClass][0] : '',
                                atpLabel : 'Controlled: ', 
                                atp: 0 
                            };
                            this.altInventoryMap.set(catClass, loc);
                        }
                    });

                    for (let i=0;i<this.inventoryItems.length;i++){
                        let cartItem = this.altInventoryMap.get(this.inventoryItems[i].catClass);
                        // console.log('cartItem', JSON.stringify(cartItem));
                        if (cartItem) {
                            this.inventoryItems[i].locationItemInfo = cartItem;
                        }
                    }

                    console.log('this.altInventoryMap' + JSON.stringify(this.altInventoryMap));
                    console.log('this.inventoryItems: ' + JSON.stringify(this.inventoryItems));

                } else {
                    console.log('Alt inventory availability data is empty');
                }
                this.completedMethodsList.getAltInventory = true;
                this.altItemsEmpty = this.inventoryItems.length > 0 ? false : true;
                this.callGetBranchPhones();
            } else {
                console.log('error getting Alt Inventory API results');
                this.completedMethodsList.getAltInventory = true;
                this.callGetBranchPhones();
            }
    }

    deliveryDateWeek(){
        let startTime = 'T23:00:00+00:00';
        let startDate;
        let date = new Date();
        date.setDate(date.getDate() + 7);
        let monthPad;
        let dayPad;
        // if both month and date are between 1-9, pad with 0
        if (((date.getMonth() + 1) > 0) && (date.getMonth() + 1) < 10 &&
            date.getDate() > 0 && date.getDate() < 10) {
            monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
            dayPad = date.getDate().toString().padStart(2, '0');
            startDate = `${date.getFullYear()}-${monthPad}-${dayPad}`;
        }
        // if only date is between 1-9
        else if (date.getDate() > 0 && date.getDate() < 10) {
            dayPad = date.getDate().toString().padStart(2, '0');
            startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${dayPad}`;
        }
        // if only month is between 1-9
        else if ((date.getMonth() + 1) > 0 && (date.getMonth() + 1) < 10) {
            monthPad = (date.getMonth() + 1).toString().padStart(2, '0');
            startDate = `${date.getFullYear()}-${monthPad}-${date.getDate()}`;
        } else {
            startDate = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
        }
        return (startDate + startTime);
    }

    resetFields(){
        this.catClassList = [];
        this.branchList = [];
        this.catClassList = []; 
        this.inventoryItems = [];
        this.isShowAltInventoryItems = false;
        this.completedMethodsList = {'getProductAvailabilities':false,'getAltInventory':false,'getBranchPhones':false};
        this.altItemsEmpty = true;
    }

    // Change cart date format from 2022-12-19T18:00:00.000Z --> 2022-12-25T23:00:00+00:00
    getCartRentalStartDate(){
        let date = this.syncCartInfo.Rental_Start_Date__c;
        date = date.replace(' ', '');
        date = date.replace('.000Z', '+00:00');
        return date;
    }

    // Change cart fulfillment format
    getCartFulfillmentType(){
        if (this.syncCartInfo.Customer_Pick_Up__c == 'Delivery'){
            return 'DEL';
        }
        else {
            return 'CPU';
        }
    }

    callGetBranchPhones(){
        getBranchPhones({pcs: this.branchList}).then(
            data =>{
            if(data){
                if(data.length > 0){
                    const phoneMap = new Map();
                    for (let i=0;i<data.length;i++){
                        phoneMap.set(data[i].Branch_Location_Number__c, data[i].Phone__c);
                    }
                    // append branch phone data
                    for (let i=0;i<this.inventoryItems.length;i++){
                        if (this.inventoryItems[i].locationItemInfo.pc) {
                            let branchPhone = phoneMap.get(this.inventoryItems[i].locationItemInfo.pc);
                            if (branchPhone) {
                                this.inventoryItems[i].locationItemInfo.branchPhone = branchPhone;
                            }
                        }
                    }  
                }
                this.completedMethodsList.getBranchPhones = true;
                this.showAltInventoryItems();   
            }
            else {
                console.log('error getting branch phones');
                this.completedMethodsList.getBranchPhones = true;
                this.showAltInventoryItems();   
            }
        });
    }

    showAltInventoryItems(){
        console.log('Display variables: ' + JSON.stringify(this.completedMethodsList));
        if (this.chronosEnabled) {
            if (this.completedMethodsList.getProductAvailabilities == true &&  this.completedMethodsList.getAltInventory == true &&  
                this.completedMethodsList.getBranchPhones == true ){
                this.isShowDefaultValues = false;
                this.isShowAltInventoryItems = true;
            }
        } else {
            if (this.altItemsEmpty === false){
                this.isShowDefaultValues = true
                this.isShowAltInventoryItems = false;
            }
        }
    }

    get isBase(){
        return this.variant == 'base';
    }
    get isCompact() {
        return this.variant == 'compact';
    }
    get isChronos(){
        return this.variant == 'altInventoryChronos';
    }

    handleSelectedItem(event) {
        let selectedItem = event.detail;

        console.log("  ===== Sbr_3_0_altInventoryCmp event received")
        console.log("@vm368--->",JSON.stringify(selectedItem));
        
        const selectedItemEvent = new CustomEvent('itemselected', { detail: selectedItem, bubbles: true, composed: true});
        // console.log('  =====New event');

        this.dispatchEvent(selectedItemEvent);
        // console.log('  ===== After Dispatch');

    }
}