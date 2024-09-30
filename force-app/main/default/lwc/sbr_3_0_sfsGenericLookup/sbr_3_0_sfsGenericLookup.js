import { LightningElement,api,wire,track } from 'lwc';
import fetchLookupData from '@salesforce/apex/SBR_3_0_SfsGenericLookupController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/SBR_3_0_SfsGenericLookupController.fetchDefaultRecord';
const DELAY = 300; // dealy apex callout timing in miliseconds  

export default class Sbr_3_0_sfsGenericLookup extends LightningElement {
    
    // public properties with initial default values 
    @api label = 'custom lookup label';
    @api placeholder = 'search...'; 
    @api iconName = 'standard:account';
    @api sObjectApiName = 'Account';
    @api filterQuery="None"
    @api defaultRecordId = '';
    @api isRequiredStyle=false;
    @api objectLabel = "Account";
    @api otherfield=false;
    @api otherFieldApiName = '';
    @api fieldApiName="Name";
    @api selectedRecordId;
    // Retro
    @api isDisable=false;
    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true; 
    searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object format 
    isProductItem=false;
    isWorkOrder=false;
    @api hasDisplayAssetmsg=false;
    
    // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback(){
        
        console.log("IN Connected"+this.defaultRecordId);
        if(this.defaultRecordId != ''){
            if(this.sObjectApiName=='ProductItem'){
                this.isProductItem=true;
            }
            else if(this.sObjectApiName=='WorkOrder'){
                this.isWorkOrder=true;
            }
            else{
                this.isProductItem=false;
                this.isWorkOrder=false;
            }
            
            fetchDefaultRecord({ recordId: this.defaultRecordId , 'sObjectApiName' : this.sObjectApiName,'otherField':this.otherFieldApiName })
            .then((result) => {
                console.log('in result +generic '+JSON.stringify(result));
                if(result != null){
                    this.selectedRecord = result;
                    this.selectedRecordId = this.defaultRecordId;
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                console.log('error '+JSON.stringify(error));
                this.error = error;
                this.selectedRecord = {};
            });
        }
    }
    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName' ,filterQuery:'$filterQuery','otherField':'$otherFieldApiName'})
    searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true; 
            console.log(JSON.stringify(data));
            // Change made for product consumed 
            if(this.sObjectApiName=='ProductItem'){
                this.isProductItem=true;
                
            }
            else if(this.sObjectApiName=='WorkOrder'){
                this.isWorkOrder=true;
            }
            else{
                this.isProductItem=false;
                this.isWorkOrder=false;
            }
            // change for extra field in generic lookup
            if(this.otherfield){
                console.log(JSON.stringify(this.handleData(data)));
                this.lstResult = JSON.parse(JSON.stringify(this.handleData(data))); 
                console.log(this.lstResult);
            }
            else{
                this.lstResult = JSON.parse(JSON.stringify(data)); 
                console.log("checkpoint 2 ::"+ JSON.stringify(data)); 
            }
            
            
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };
    // handle data for extra field 
    handleData(recs){
        let list=[];
     

        recs.forEach(rec=>{
            let record={};
            let mainField='Name';
            if(this.isProductItem){
                mainField='ProductName';
                //let obj={ProductName:rec.ProductName,subField:`${rec.SM_PS_Stock_Class__c}~${rec.SM_PS_Item_Number__c}`,Id:rec.Id};
                //list.push(obj);
            }
            
               // let obj={Name:rec.Name,subField:rec[this.otherFieldApiName],Id:rec.Id};
               

                this.otherFieldApiName.split(',').forEach(data=>{
                    if(record.hasOwnProperty(rec.Id))
                    {
                        let obj=record[rec.Id];
                        let subfield=obj['subField'];
                        if(rec[data])
                        {
                        subfield=subfield?subfield+'~'+rec[data]:rec[data];
                        }
                       
                        obj['subField']=subfield;
                        record[rec.Id]=obj;
                    }
                    else
                    {
                    let obj={subField:rec[data],Id:rec.Id};
                    obj[mainField]=rec[mainField];
                    record[rec.Id]=obj;
                    }
                });

                list.push(record[rec.Id]);
            
        })
        return list;
    }
    
    // update searchKey property on input field change  
    handleKeyChange(event) {
        // Debouncing this method: Do not update the reactive property as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
        }, DELAY);
    }
    // method to toggle lookup result section on UI 
    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
            clsList.add('slds-is-open');
            break;
            case 'lookupContainer':
            clsList.remove('slds-is-open');    
            break;                    
        }
    }
    // method to clear selected lookup record  
    handleRemove(event){
        this.searchKey = '';    
        this.selectedRecord = {};
        this.selectedRecordId=null;
        this.lookupUpdatehandler({}); // update value on parent component as well from helper function 
        
        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
        event.preventDefault();
    }
    // method to update selected record from search result 
    handelSelectedRecord(event){   
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        console.log(event.target);
        let recid= event.currentTarget.dataset.recid;
        console.log(JSON.stringify(event.target.dataset));
        console.log(JSON.stringify(event.currentTarget.dataset));
        console.log(recid);
        this.selectedRecordId=recid;
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        console.log(objId);
        console.log(this.selectedRecord )
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }
    /*COMMON HELPER METHOD STARTED*/
    handelSelectRecordHelper(){
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');     
    }
    // send selected lookup record to parent component using custom event
    lookupUpdatehandler(value){    
        const oEvent = new CustomEvent('lookupupdate',
        {
            'detail': {selectedRecord: value}
        }
        );
        this.dispatchEvent(oEvent);
    }
    
    @api 
    setDefaultRecordId(defaultRecordId){
        console.log("DRVGENERIC: "+defaultRecordId);
        if(defaultRecordId != ''){
            fetchDefaultRecord({ recordId: defaultRecordId , 'sObjectApiName' : this.sObjectApiName })
            .then((result) => {
                if(result != null){
                    this.selectedRecord = result;
                    this.selectedRecordId=defaultRecordId;
                    console.log("this.selectedRecord: "+this.selectedRecord);
                    this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
        }
        
    }
}