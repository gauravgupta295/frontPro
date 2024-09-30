import { LightningElement,api,wire} from 'lwc';
// import apex method from salesforce module 
import fetchLookupData from '@salesforce/apex/SBR_3_0_CustomLookupController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/SBR_3_0_CustomLookupController.fetchDefaultRecord';

const DELAY = 300; // dealy apex callout timing in miliseconds  

export default class CustomProjectLookup extends LightningElement {
    // public properties with initial default values 
    @api label = 'Custom Lookup Label';
    @api placeholder = ''; 
    @api iconName = '';
    @api sObjectApiName = '';
    @api defaultRecordId = '';
    @api fieldsToInclude = '';
    @api hasCustomNameField = false;
    @api customNameField = '';
    @api fieldsToSet = '';

    @api recordId = '';
    @api whereClause = '';

    // private properties 
    lstResult = []; // to store list of returned records   
    hasRecords = true; 
    searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 

    // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback(){
        if(this.defaultRecordId != ''){
            fetchDefaultRecord({ recordId: this.defaultRecordId , sObjectApiName : this.sObjectApiName , hasCustomNameField : this.hasCustomNameField})
            .then((result) => {
                if(result != null){
                    this.selectedRecord = result;
                    this.recordId = result.Id;
                    this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
                this.recordId = '';
            });
        }
    }

    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName' , 
                                whereClause : '$whereClause' , fieldsToInclude : '$fieldsToInclude', 
                                hasCustomNameField : '$hasCustomNameField'})
    searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true; 
            this.lstResult = JSON.parse(JSON.stringify(data)); 
            for(var i = 0; i < this.lstResult.length; i++) {
                let o = this.lstResult[i];

                if(this.hasCustomNameField){
                    o.DisplayName = o[this.customNameField];
                     console.log('if o.DisplayName 65>>>>'+o.DisplayName);
                    
                }else{
                    
                    o.DisplayName = o['Name'];
                    //o.ProjectNameDisplayField=o['Project_Name__c'];
                    o.ProjectNameDisplayField=o['Project_Name__c']?o['Project_Name__c']:'';
                }
            }
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };

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
    handleRemove(){
        this.searchKey = '';    
        this.selectedRecord = {};
        this.recordId = '';
        this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function 

        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');

        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');
    }

    // method to update selected record from search result 
    handleSelectedRecord(event){   
        var objId = event.target.getAttribute('data-recid'); // get selected record Id
        this.recordId = objId;
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        this.lookupUpdatehandler(this.selectedRecord); // update value on parent component as well from helper function 
        this.handleSelectRecordHelper(); // helper function to show/hide lookup result container on UI
    }

    /*COMMON HELPER METHOD STARTED*/

    handleSelectRecordHelper(){
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

    get selectedRecordName() {
        if(this.hasCustomNameField){
            return this.selectedRecord[this.customNameField];
        }else{
            return this.selectedRecord['Name'];
        }
    }
}