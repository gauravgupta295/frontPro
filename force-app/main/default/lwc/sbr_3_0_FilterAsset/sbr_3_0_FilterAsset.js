import { LightningElement,api, wire,track } from 'lwc';
//Get the filtered Assets
import getFilteredAssets from '@salesforce/apex/SBR_3_0_AssetFilterController.getFilteredAssets';
//Get the count of filtered Assets
import getCountOfFilteredAssets from '@salesforce/apex/SBR_3_0_AssetFilterController.getFilteredAssetsCount';

export default class SBR_3_0_FilterAsset extends LightningElement {

    //Flow input for Asset Category
    @api userInputCategory;
    //Flow input for Asset Cat-Class
    @api userInputCatClass;
    //Flow input for Asset SubClass
    @api userInputSubClass;
    //Flow input for WPT Company Code
    @api inputCompanyCodeWPT;
    //Store selected Data
    @api selectedRowData=[];
    //Check for selected Row
    @api isRowSelected;
    //Variable for check loading of page
    @track showLoading = false;
    //Variable for check loading of page
    @track showLoadingCount = false;
    //The Data Array
    @api recordsToDisplay=[];

    //Total No of Records
    totalRecords = 0;
    //Page size options
    pageSizeOptions = [100, 75, 50, 25]; 
    //No.of records to be displayed per page
    pageSize = 100;
    //Total no.of pages
    totalPages = 0;
    //Page number    
    pageNumber = 1; 
    //Last Querried Record
    lastQuerriedRecord='';
    //Previous Record
    previousRecord='';
    //Search box value
    searchValue = '';
    //Total records selected
    recordsSelected = 0;
    //Last Record Count
    lastRecordCount=0;
    //Record Size per page
    recordSize=0;
    //Store selected data of all pages
    selection = [];
    
    //Columns of Data Table
    columns = [  
        { label: 'Asset Number', fieldName: 'Name' }, 
        { label: 'Asset Cat Class', fieldName: 'SM_PS_Cat_Class__c' }, 
        { label: 'Asset Sub Class', fieldName: 'SM_PS_Sub_Class__c' }, 
        { label: 'Company Code', fieldName: 'SM_PS_Company_Code__c' } 
    ];

    connectedCallback(){
        this.getAssetCount();
        this.getActualAssetData(
        ).then(data => {
            this.populateRecords(data);
        }).catch(error => {
            console.log('Error',error.message);
        });
    }

    //Variable to indicate if First and Previous button to be disabled or enabled
    get disableFirst() {
        return this.pageNumber == 1;
    }

    //Variable to indicate if Last and Next button to be disabled or enabled
    get disableLast() {
        return this.pageNumber == this.totalPages;
    }

    //Variable to check if Display Pagination Options or not
    get disablePagination() {
        return this.recordsToDisplay?.length > 0;
    }
    
    //Used to prepare SOQL query
    prepareSOQLQuery(lastQuerriedRecord, previousRecord,lastRecordCount,searchKey, isCountQuery){
        //Variable to store complete query
        let sQuery;
        //Variable to store the Select Clause
        let selectClause = 'SELECT Id, ';
        //fields to be queried for asset
        let fieldsToQuery='SM_PS_Category__c,SM_PS_Sub_Class__c, SM_PS_Cat_Class__c,SM_PS_Company_Code__c,Status,';
        //Variable to store the From Clause
        let fromClause = 'Name FROM Asset';
        //Variable to store the Where Clause
        let whereClause = ' WHERE Status NOT IN (\'JUNKED\',\'MISSING LOST\',\'SOLD\',\'STOLEN\',\'Deleted\') AND SM_PS_Record_Status__c !=\'Deleted\'';
        //Variable to store the limit Clause
        let limitClause = ''; 
        //Variable to store the Order By Clause
        let orderByClause = ' ORDER BY ID ASC'; 
        //Variable to store the Order By Clause
        let orderByClauseDesc = ' ORDER BY ID DESC'; 
        //Variable to store the lastRecordCondition
        let lastRecordCondition = '';
        //Variable to store the searchKeyWhereClause
        let searchKeyWhereClause = '';

        //Create the Select Clause
        if(isCountQuery){
            selectClause = 'SELECT count() FROM Asset';
        }else{
            if(fieldsToQuery){
                selectClause = selectClause + fieldsToQuery + fromClause;
            }else{
                selectClause = selectClause + fromClause;
            }
        }

        //Create Clause for userInputCategory
        if(this.userInputCategory != null){
            whereClause = whereClause + ' AND SM_PS_Category__c' + ' = \'' + this.userInputCategory + '\' ';
        }
        //Create Clause for userInputCatClass
        if(this.userInputCatClass != null){
            whereClause = whereClause + ' AND SM_PS_Cat_Class__c' + ' = \'' + this.userInputCatClass + '\' ';
        }
        //Create Clause for userInputSubClass
        if(this.userInputSubClass != null){
            whereClause = whereClause + ' AND SM_PS_Sub_Class__c' + ' = ' + this.userInputSubClass;
        }
        
        //Create Clause for NEXT button
        if(!isCountQuery && lastQuerriedRecord != '' && lastQuerriedRecord != null){
                lastRecordCondition = ' AND Id >  \'' + lastQuerriedRecord+ '\' ';
                whereClause = whereClause + lastRecordCondition;
        }

        //Create Clause for PREVIOUS button
        if(!isCountQuery && previousRecord != '' && previousRecord != null){
            lastRecordCondition = '  AND Id <  \'' + previousRecord+ '\' ';
            whereClause = whereClause + lastRecordCondition;
        }

        //Create Clause for SEARCH bar
        if(searchKey){
            searchKeyWhereClause = ' AND Name' + ' LIKE \'%' +  searchKey + '%\' ';
            whereClause = whereClause + searchKeyWhereClause;
        }

        //LIMIT Clause
        if(!isCountQuery && this.pageSize != null){
                limitClause = ' LIMIT ' + this.pageSize;
        }
        
        //Prepare Final SOQL Query
        if(isCountQuery){
            sQuery = selectClause + whereClause;
        } else if(lastRecordCount > 0) {
            sQuery = selectClause + whereClause + orderByClauseDesc + ' LIMIT '+ lastRecordCount;
        } else if(!isCountQuery && previousRecord != '' && previousRecord != null){
            sQuery = selectClause + whereClause + orderByClauseDesc + limitClause;
        }else {
            sQuery = selectClause + whereClause + orderByClause + limitClause;
        }

        return sQuery;
    }

    //Used to get the Asset Record from Apex Controller
    async getActualAssetData(lastQuerriedRecord,previousRecord,lastRecordCount, searchValue){
        let sQuery = this.prepareSOQLQuery(lastQuerriedRecord,previousRecord,lastRecordCount,searchValue, false);
        let companyCode = JSON.stringify(this.inputCompanyCodeWPT);
        this.showLoading = true;
        try{
            if(sQuery){
                let data = await getFilteredAssets({
                    sQuery : sQuery,
                    companyCode : companyCode
                });
                if(data.length>0){
                    this.showLoading = false;
                    return data;
                }else{
                    this.recordsToDisplay = [];
                    this.recordSize = 0;
                    this.showLoading = false;
                    return Promise.reject(new Error('No Records Querried'));
                } 
            }else{
                console.log('Query is Empty');
            }
        }catch(error){
            console.log(`Record Query Failed`,error.message);
        }
    }

    //Used to get the Total Asset Count from Apex Controller
    getAssetCount(){

        let sQuery = this.prepareSOQLQuery('','','', this.searchValue, true);
        let companyCode = JSON.stringify(this.inputCompanyCodeWPT);
        this.showLoadingCount = true;
        if(sQuery){
            getCountOfFilteredAssets({
                sCountQuery : sQuery,
                companyCode : companyCode
            })
            .then((data) => {
                if(data>0){
                    this.totalRecords = data;
                    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                    this.pageNumber = 1;
                    this.showLoadingCount = false;
                }else{
                    this.totalRecords = 0;
                    this.showLoadingCount = false;
                }
            })
            .catch((error) => {
                console.log(`Count Query Failed`,error.message);
            });
        }else{
            console.log('Count Query Empty');
        }
    }

    /**
     * This event is for handling the change in combo box of Record Per Page
     * This will get the Asset data as per new Page Size
     */
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.totalPages = Math.ceil(this.totalRecords / event.target.value);
        this.getActualAssetData(
            '',
            '',
            '',
            this.searchValue
        ).then(data=>{
            this.populateRecords(data);
        }).catch(error=>{
            console.log('Error',error.message);
        });
    }

    /**
     * This is called when Previous Button is clicked
     * This will take previous set of records
     */
    goToPreviousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.getActualAssetData(
            '',
            this.previousRecord,
            '',
            this.searchValue
        ).then(data=>{
            data = JSON.parse(JSON.stringify(data));
            data = data.sort((data1,data2) => data1.Id > data2.Id ? 1: -1);
            this.populateRecords(data);
        }).catch(error=>{
            console.log('Error',error.message);
        });
    }

    /**
     * This is called when Next Button is clicked
     * This will take next set of records
     */
    goToNextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.getActualAssetData(
            this.lastQuerriedRecord,
            '',
            '',
            this.searchValue
        ).then(data=>{
            this.populateRecords(data);
        }).catch(error=>{
            console.log('Error',error.message);
        });    
    }

    /**
     * This is when First Button is clicked
     * This will take to first Page of Pagination
     */
    goToFirstPage() {
        this.pageNumber = 1;
        this.getActualAssetData(
            '',
            '',
            '',
            this.searchValue
        ).then(data=>{
            this.populateRecords(data);
        }).catch(error=>{
            console.log('Error',error.message);
        });
    }

    /**
     * This is when Last Button is clicked
     * This will take to last Page of Pagination
     */
    goToLastPage() {
        this.pageNumber = this.totalPages;
        this.lastRecordCount = this.totalRecords % this.pageSize;
        this.getActualAssetData(
            '',
            '',
            this.lastRecordCount,
            this.searchValue
        ).then(data=>{
            data = JSON.parse(JSON.stringify(data));
            data = data.sort((data1,data2) => data1.Id > data2.Id ? 1 : -1);
            this.populateRecords(data);
        }).catch(error=>{
            console.log('Error',error.message);
        });
    }

    /**
     * This method is called when Search bar is used
     */
    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.searchValue = event.target.value;
            this.getAssetCount();
            this.getActualAssetData(
                '',
                '',
                '',
                this.searchValue
            ).then(data=>{
                data = JSON.parse(JSON.stringify(data));
                data = data.sort((data1,data2)=>data1.Id>data2.Id?1:-1);
                this.populateRecords(data);
            }).catch(error=>{
                console.log('Error',error.message);
            }); 
        }    
    }

    /**
     * This method is called when Asset is Selected 
     */
    handleAssetRowSelection(evt){
        const {detail:{config:{action}}}=evt;

        if(action === 'rowSelect'){
            const {detail:{selectedRows}} = evt;
            this.selectedRowData =[...this.selectedRowData,...selectedRows].filter((data,index,array)=> array.findIndex(data2=>data2.Id===data.Id)=== index);
        }else if(action === 'rowDeselect'){
            const {detail:{config:{value:recordId}}}=evt;
            this.selectedRowData=this.selectedRowData.filter(data=>data.Id !== recordId);
        }
        
        // List of selected items from the data table event.
        let updatedItemsSet = new Set();
        // List of selected items we maintain.
        let selectedItemsSet = new Set(this.selection);
        // List of items currently loaded for the current view.
        let loadedItemsSet = new Set();
        
        this.recordsToDisplay.map((event) => {
            loadedItemsSet.add(event.Id);
        });
        //updatedselectedData=evt.target.getSelectedRows();
        if(evt.target.getSelectedRows()) {
            evt.target.getSelectedRows().map((event) => {
                updatedItemsSet.add(event.Id);
                
            });
            
            // Add any new items to the selection list
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });   
        }
        
        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                // Remove any items that were unselected.
                selectedItemsSet.delete(id);
            }
        });
        //stores the selected data
        this.selection = [...selectedItemsSet];
        this.recordsSelected = this.selection.length;
    }

    /**
     * Condition to show No Data Found Message 
     */
    get condition() {
        return !this.disablePagination && !this.showLoading ? false : true;
    }

    /**
     * Condition to show Loading of Page
     */
    get conditionShowLoading() {
        return !this.showLoadingCount && !this.showLoading ? false : true;
    }

     /**
     * Condition to set DataTable height dynamically 
     */
    get setDatatableHeight() {
        if(this.recordsToDisplay.length == 0){
            return 'width:100%';
        }
        else if(this.recordsToDisplay.length > 15){
                return 'height:400px; width:100%';
        }
        return 'width:100%';
    }
    
    /**
     * Method used to return data to DataTable
     */
    populateRecords(data){
        this.recordsToDisplay =data;
        this.recordSize=data.length;
        this.previousRecord =  data?.[0].Id;
        this.lastQuerriedRecord =  data[ data?.length - 1].Id;
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selection;
    }
}