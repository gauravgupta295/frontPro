import { LightningElement, wire, api } from 'lwc';
//Get the Columns from Metadata
import getColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
//Get the filtered Assets
import getFilteredAssets from '@salesforce/apex/SBR_3_0_AssetInquiryController.getFilteredAssets';
//Get the count of filtered Assets
import getCountOfFilteredAssets from '@salesforce/apex/SBR_3_0_AssetInquiryController.getFilteredAssetsCount';

export default class Sbr_3_0_assetInquiryAssetListCmp extends LightningElement {
    //The Columns Array
    columns = [];
    //The Data Array
    recordsToDisplay = [];
    //sorting needs to be refactored
    defaultSortDirection = 'asc';
    //current sort direction
    sortDirection = 'asc';
    //current sorted by column
    sortedBy = 'Name';

    //fields to be queried for asset
    fieldsToQuery;
    //searchable fields array
    searchablefieldsArray = [];
    //Search key entered by User
    searchKey;
    //Variable for Current Selected Level Value (Region/Territory/etc.)
    currentLevelPicklistValue = null;
    //Variable to indicate Current Selected Level (if Branch, use loc Id, if any thing else, use PicklistValue)
    currentLevelValue = null;
    //Variable to store the selected Status Values //RITESH
    selectedStatusValues = ['AVAILABLE','ON RENT','SCHEDULED FOR PICKUP','IN TRANSIT','RETURNED - NEED CHECK OUT','DOWN - LESS THAN 20 DAYS','DOWN - MORE THAN 20 DAYS',
    'ON RENTAL PURCHASE','SAFETY/SERVICE LOCKOUT','HELD FOR CENTRAL DISPOSAL','HELD FOR SALE','SATELITE BRANCH','SEASONAL'];
    //Variable to store the selected Equipment Type Values
    selectedEquipmentTypeValues = ['NEW FOR SALE','RENTAL'];
    //Variable to store the Selected Fields
    selectedFieldsForSearch = [];
    //Variable for storing lookup field definations to be used to convert it to URL.
    lookupFieldsName = [];
    //Variable to store the selected Cat Class
    selectedCatClass = [];

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
        return this.recordsToDisplay.length > 0;
    }

    /**
     * This is the wired method to get the Asset Table Columns
     * This will be fired on load
     */
    @wire(getColumns)
    getColumns({error, data}) {
        if(data) {
            //Get all columns which are for context "Asset Search"
            let itemSearchCols = data.filter( col => col.Context__c == 'Asset Search');
            //Sort all columns by Order field
            itemSearchCols.sort((a,b) => a.Order__c - b.Order__c);
            //Variable tp handle 
            let isfirst = true;
            //add these columns in the columns array
            itemSearchCols.forEach( col => {
                let colItem = {};
                colItem.hideDefaultActions = true;
                colItem.sortable = col.IsSortable__c;
                colItem.wrapText = true;
                colItem.label = col.Label;
                colItem.fieldName = col.Field_Name__c;
                colItem.type = col.Type__c?col.Type__c:"text";
                
                if(col.Type__c == 'url'){
                    colItem.fieldName = "LinkUrl";
                    colItem.typeAttributes = {
                        label: { fieldName :'Name' },
                        target: '_self'
                    }
                }
                if(col.Type__c == 'lookup'){
                    colItem.type = "url";
                    colItem.fieldName = col.Field_Name__c.substring(0,col.Field_Name__c.indexOf('_r')) + '_c'; 
                    colItem.typeAttributes = {
                        label: { fieldName : col.Label },
                        target: '_self'
                    }
                }

                if(col.fixedWidth__c) {
                    colItem.fixedWidth = col.fixedWidth__c;
                }

                this.columns = [...this.columns, colItem];

                //Add the column for querying data
                if(col.Field_Name__c != 'Name'){
                    if(isfirst){
                        this.fieldsToQuery = col.Field_Name__c + ',';
                        isfirst = false;
                    }else{
                        this.fieldsToQuery+= col.Field_Name__c + ',';
                    }

                    if(col.Type__c == 'lookup'){
                        this.fieldsToQuery += col.Field_Name__c.substring(0,col.Field_Name__c.indexOf('_r')) + '_r.Name,';

                        let relativeName = col.Field_Name__c.substring(0,col.Field_Name__c.indexOf('_r')) + '_r';
                        let relativeFieldName = col.Field_Name__c.substring((col.Field_Name__c.indexOf('_r') + 3),col.Field_Name__c.length);
                        let relativeFieldActualName = col.Field_Name__c.substring(0,col.Field_Name__c.indexOf('_r')) + '_c';
                        let colName = col.Label;
                        let lookupDefination = {"relativeName" :relativeName, "relativeFieldName" : relativeFieldName, "relativeFieldActualName": relativeFieldActualName, "colName" : colName};
                        this.lookupFieldsName.push(lookupDefination);
                    }
                }

                if(col.Type__c != 'date' && col.Type__c != 'boolean' )
                {
                    let comboOption = {};
                    comboOption.label = col.Label;
                    if(col.Type__c == 'lookup')
                    {
                        comboOption.value = col.Field_Name__c.substring(0,col.Field_Name__c.indexOf('_r')) + '_r.Name';
                    }
                    else
                    {
                        comboOption.value = col.Field_Name__c;
                    }

                    this.searchablefieldsArray = [...this.searchablefieldsArray,comboOption];
                    this.selectedFieldsForSearch = [...this.selectedFieldsForSearch, comboOption.value]; 
                }
                //Add this field to searchable if it is text when serach key is entered
                //let comboOption = {};
                //comboOption.label = col.Label;
                //comboOption.value = col.Field_Name__c;
                //this.searchablefieldsArray = [...this.searchablefieldsArray,comboOption];

            });

            //Add all combo option for serachable array
            let comboOption = {};
            comboOption.label = 'All';
            comboOption.value = 'All';
            this.searchablefieldsArray.splice(0,0,comboOption);

            //Send this event to AssetHeader for setting fields in the filter combo box.
            const searchFilterFieldSetEvent = new CustomEvent('searchfilterfieldsetevent', {
                'detail': {
                    searchfields : this.searchablefieldsArray                     
                }
            });
            this.dispatchEvent(searchFilterFieldSetEvent);

        }else if(error) {
            console.log(error);
        }
    }

    /**
     * This is called when the Level PickList Vales is changed
     * This will acutually call the apex to get assets record 
     */
    @api handleLevelPicklistSelectionEvent(levelDetailRec){
        if(levelDetailRec) {
            this.currentLevelPicklistValue = levelDetailRec.fieldPickListValue;
            this.currentLevelValue = levelDetailRec.fieldAPIName;
            this.getAssetCount();
            this.getActualAssetData(0);
        }else{
            console.error("handleLevelPicklistSelectionEvent : Unable to get the Level Detail Record");
        }
    } 

    /**
     * This is called when the Apply Button of AssetAttributeFilterCmp
     * This will acutually call the apex to get assets record by adding status and equipment type filters
     */
    @api handleApplyAssetAttributeFilterEvent(applyEventDetailRec){
        if(applyEventDetailRec) {
            this.selectedEquipmentTypeValues = applyEventDetailRec.selectedEquipmentTypeValues;
            this.selectedStatusValues = applyEventDetailRec.selectedStatusValues;
            this.getAssetCount();
            this.getActualAssetData(0);
        }else{
            console.error("handleApplyAssetAttributeFilterEvent : Unable to get the Apply Event Record");
        }
    } 

    /**
     * This is called when the Apply Button of AssetAttributeFilterCmp
     * This will acutually call the apex to get assets record by adding status and equipment type filters
     */
    @api handleSearchFilterEvent(searchFilterRec){
        if(searchFilterRec) {
            this.searchKey = searchFilterRec.searchKey;
            if(searchFilterRec.fieldSelected.includes('All')){
                this.selectedFieldsForSearch = [];
                this.searchablefieldsArray.forEach(searchField => {
                    if(searchField.label != 'All'){
                        this.selectedFieldsForSearch = [...this.selectedFieldsForSearch,searchField.value];
                    }
                });
            }else{
                this.selectedFieldsForSearch = searchFilterRec.fieldSelected;
            }
            this.getAssetCount();
            this.getActualAssetData(0);
        }else{
            console.error("handleSearchFilterEvent : Unable to get the Apply Event Record");
        }
    }

    @api handleProductFilterEvent(productFilterRec){
        if(productFilterRec){
            this.selectedCatClass = productFilterRec.selectedCatClass;
            this.getAssetCount();
            this.getActualAssetData(0); 
        }
    }

    /**
     * This method prepares the SOQL Query based on user selected filters
     */
    prepareSOQLQuery(offset, isCountQuery){
        //Variable to store complete query
        let sQuery;
        //Variable to store the Select Clause
        let selectClause = 'SELECT Id, ';
        //Variable to store the From Clause
        let fromClause = 'Name FROM Asset';
        //Variable to store the Where Clause
        let whereClause = ' WHERE ';
        //Variable to store the searchKey Where Clause
        let searchKeyWhereClause = '';
        //Variable to store the status Where Clause
        let statusWhereClause = '';
        //Variable ro store the Equipment Type Where Clause
        let equipmentTypeWhereClause = '';
        //Variable to store CatClass Where Clausew
        let catClassWhereClause = '';
        //Variable to store the limit Clause
        let limitClause = ''; 
        //Variable to store the offsetClause
        let offsetClause = '';

        //Create the Select Clause
        if(isCountQuery){
            selectClause = 'SELECT count() FROM Asset';
        }else{
            if(this.fieldsToQuery){
                selectClause = selectClause + this.fieldsToQuery + fromClause;
            }else{
                selectClause = selectClause + fromClause;
            }
        }

        //Check if the level value is present or not. If present, the query else
        if(this.currentLevelValue && this.currentLevelPicklistValue){
            //Creat Clause for Current Level (Region, Territory etc.
            whereClause = whereClause + ' ' + this.currentLevelValue + ' = \'' + this.currentLevelPicklistValue + '\' ';
        
            //Create Clause for Status Filter
            if(this.selectedStatusValues.length > 0){
                statusWhereClause = 'AND Status IN (';
                this.selectedStatusValues.forEach(statusValue => {
                    statusWhereClause = statusWhereClause + '\'' + statusValue + '\', ';
                })
                statusWhereClause = statusWhereClause.substring(0, statusWhereClause.length - 2)  + ') ';
                whereClause = whereClause + statusWhereClause;
            }else{
                whereClause = whereClause + 'AND Status != \'Deleted\' '; 
            }

            //Create Clause for Equipment Type Filter
            if(this.selectedEquipmentTypeValues.length > 0){
                equipmentTypeWhereClause = 'AND SM_PS_Equipment_Type__c IN (';
                this.selectedEquipmentTypeValues.forEach(equipmentTypeValue => {
                    equipmentTypeWhereClause = equipmentTypeWhereClause + '\'' + equipmentTypeValue + '\', ';
                })
                equipmentTypeWhereClause = equipmentTypeWhereClause.substring(0, equipmentTypeWhereClause.length - 2)  + ') ';
                whereClause = whereClause + equipmentTypeWhereClause;
            }

            //Now create the Where clause from Search Key
            if(this.searchKey){
                let searchKeyStrings = [];
                if(this.searchKey.includes(',')){
                   searchKeyStrings = this.searchKey.split(',');
                }else{
                    searchKeyStrings = [this.searchKey];
                }

                searchKeyWhereClause = 'AND (';

                let isFirst = true;
                searchKeyStrings.forEach(searchstring =>{
                    //Add other fields 
                    if(this.selectedFieldsForSearch.length > 0) {
                        this.selectedFieldsForSearch.forEach(searchField=> {
                            if(isFirst){
                                searchKeyWhereClause += searchField + ' LIKE \'%' +  searchstring + '%\' ';
                                isFirst = false;
                            }else{
                                searchKeyWhereClause += ' OR ' + searchField + ' LIKE \'%' +  searchstring + '%\' ';
                            }
                        });
                    }
                });
                searchKeyWhereClause += ')';
                whereClause = whereClause + searchKeyWhereClause;
            }

            //Create Where clause from CatClass (basically Product Filter)
            if(this.selectedCatClass.length > 0){
                catClassWhereClause = 'AND SM_PS_Cat_Class__c IN (';
                this.selectedCatClass.forEach(selectedCatClassValue => {
                    catClassWhereClause = catClassWhereClause + '\'' + selectedCatClassValue + '\', ';
                })
                catClassWhereClause = catClassWhereClause.substring(0, catClassWhereClause.length - 2)  + ') ';
                whereClause = whereClause + catClassWhereClause;
            }
        
            if(!isCountQuery && this.pageSize != null){
                limitClause = ' LIMIT ' + this.pageSize;
            }

            if(!isCountQuery && offset!=null && offset >= 0){
                this.offset = offset;
                offsetClause = ' OFFSET ' + this.offset;
            }

            sQuery = selectClause + whereClause + limitClause + offsetClause;
            console.log('prepare SOQL Query : CURRENT SOQL QUERY -' + sQuery);
        }
        return sQuery;
    }

    /**
     * This method gets the Asset Count of the Filtered query
     * This will be used in Pagination
     */
    getAssetCount(){

        let sQuery = this.prepareSOQLQuery(0, true);
        
        if(sQuery){
            getCountOfFilteredAssets({
                sCountQuery : sQuery
            })
            .then((data) => {
                if(data){
                    this.totalRecords = data;
                    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                    this.pageNumber = 1;
                }
            })
            .catch((error) => {
                console.log(error);
            });
        }else{
            console.log('No Level Filter is selected');
        }
    }

    /**
    * This method actually calls Apex Method to get Assets and displays them on the data table
    * It requries offset parameter which will be the current offset
    */
    getActualAssetData(offset){
        let sQuery = this.prepareSOQLQuery(offset, false);
        if(sQuery){
            getFilteredAssets({
                sQuery : sQuery
            })
            .then((data) => {
                if(data.length>0){
                    let tempRecs = [];
                    data.forEach( ( record ) => {
                        let tempRec = JSON.parse(JSON.stringify(record));
                        //Update the URL LINK
                        tempRec.LinkUrl= '/' + tempRec.Id;

                        this.lookupFieldsName.forEach(lookupField =>{
                            let relativeName = lookupField.relativeName;
                            let relativeFieldName = lookupField.relativeFieldName;
                            let relativeFieldActualName = lookupField.relativeFieldActualName;
                            let colName = lookupField.colName;

                            let recId = tempRec[relativeName].Id
                            let recName = tempRec[relativeName][relativeFieldName];
                            tempRec[colName] = recName;
                            tempRec[relativeFieldActualName] = '/' + recId;
                        });
                        tempRecs.push( tempRec );
                    });
                    this.recordsToDisplay = tempRecs;
                }else{
                    this.recordsToDisplay = [];
                }
            })
            .catch((error) => {
                console.log(error);
            });
        }else{
            console.log('No Level Filter is selected');
        }
    }

    /**
     * This method is called when the column sorting is clicked by user
     * Depending on the column selected and sorting direction, data will be sorted
     */
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.recordsToDisplay];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.recordsToDisplay = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    /**
     * Used to sort the 'Age' column 
     * */ 
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    /**
     * This event is for handling the change in combo box of Record Per Page
     * This will get the Asset data as per new Page Size
     */
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.totalPages = Math.ceil(this.totalRecords / event.target.value);
        this.getActualAssetData(0);
    }

    /**
     * This is called when Previous Button is clicked
     * This will take previous set of records
     */
    goToPreviousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.getActualAssetData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is called when Next Button is clicked
     * This will take next set of records
     */
    goToNextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.getActualAssetData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is when First Button is clicked
     * This will take to first Page of Pagination
     */
    goToFirstPage() {
        this.pageNumber = 1;
        this.getActualAssetData(0,this.pageSize);
    }
    /**
     * This is when Last Button is clicked
     * This will take to last Page of Pagination
     */
    goToLastPage() {
        this.pageNumber = this.totalPages;
        this.getActualAssetData(this.pageSize * (this.pageNumber-1) ,this.pageSize);
    }

    /**
     * This method is called when Asset is Selected 
     * This event is propogated further to Asset Availability Component
     */
    handleAssetRowSelection(event){
        let selectedRows = event.target.getSelectedRows();
        console.log('** selectedRows: '+JSON.stringify(selectedRows));

        const selectedRowsEvent = new CustomEvent('assetselected', { 
                            detail: selectedRows }); 
        
        if(selectedRows.length > 0) {
            this.dispatchEvent(selectedRowsEvent);
        }
    }
}