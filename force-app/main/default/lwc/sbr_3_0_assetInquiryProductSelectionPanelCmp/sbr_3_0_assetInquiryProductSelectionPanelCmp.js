import { LightningElement,track, api, wire } from 'lwc';
//Get the Columns from Metadata
import getColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
//
import fetchAssetData from '@salesforce/apex/SBR_3_0_AssetInquiryController.getProductsForSelection';
//Get the count of filtered Assets
import getCountOfFilteredAssets from '@salesforce/apex/SBR_3_0_AssetInquiryController.getFilteredAssetsCount';

export default class Sbr_3_0_assetInquiryProductSelectionPanelCmp extends LightningElement {
    //Variable to store the selected Categories
    selectedCategories = [];
    //Variable to store the Selected Sub Categories
    selectedSubCategories = [];

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
    fieldsToQuery = '';
    //Search key entered by User
    searchKey = '';
    //fields to be searched
    selectedFieldsForSearch = [];

    //selected catclass to be sued by asset inquiry list
    selectedCatClass = [];

    //Total No of Records
    totalRecords = 0;
    //Page size options
    pageSizeOptions = [25, 50, 75, 100]; 
    //No.of records to be displayed per page
    pageSize = 25;
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

    @wire(getColumns)
    getColumns({error, data }) {
        if(data) {
            let itemSearchCols = data.filter( col => col.Context__c == 'Product Search');
            itemSearchCols.sort((a,b) => a.Order__c - b.Order__c);
            itemSearchCols.forEach( col => {
                let colItem = {};
                colItem.label = col.Label;
                colItem.fieldName = col.Field_Name__c;
                colItem.hideDefaultActions = true;
                colItem.sortable = col.IsSortable__c;
                colItem.type = col.Type__c?col.Type__c:'text';
                colItem.wrapText = true;
                if(col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;

                this.columns = [...this.columns, colItem];

                if(col.Field_Name__c != 'Name'){
                    this.fieldsToQuery += col.Field_Name__c + ',';
                }

                if(colItem.type == 'text'){
                    this.selectedFieldsForSearch = [...this.selectedFieldsForSearch, col.Field_Name__c];
                }
            });
        }else if(error) {
            console.log(error);
        }
    } 

    @api handleGetProductForSelectionEvent(getProductForSelectionEventdetail){
        this.selectedCategories = getProductForSelectionEventdetail.selectedcategories;
        this.selectedSubCategories = getProductForSelectionEventdetail.selectedsubcategories;
        this.searchKey = '';
        this.selectedCatClass = '';

        if(this.selectedCategories.length > 0 || this.selectedSubCategories.length > 0){
            this.getProductCount();
            this.getProductData(0);
        }else{
            this.recordsToDisplay = [];
        }
    }

    @api handleApplyFilter(event){
        //Send the event to AssetInquiryListComponentCmp to show filtered lisd
        const productFilterChangeEvent = new CustomEvent('productfilterchange', {
            'detail': { 
                action : 'productfilterchange',
                selectedCatClass : this.selectedCatClass,
                selectedFilterCount : this.selectedCatClass.length
             }
        });
        this.dispatchEvent(productFilterChangeEvent);
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
        let fromClause = 'Name FROM Product2';
        //Variable to store the Where Clause
        let whereClause = ' WHERE ';
        //Variable to store the searchKey Where Clause
        let searchKeyWhereClause = '';
        //Variable to store the limit Clause
        let limitClause = ''; 
        //Variable to store the offsetClause
        let offsetClause = '';

        //Create the Select Clause
        if(isCountQuery){
            selectClause = 'SELECT count() FROM Product2';
        }else{
            if(this.fieldsToQuery){
                selectClause = selectClause + this.fieldsToQuery + fromClause;
            }else{
                selectClause = selectClause + fromClause;
            }
        }

        let catWhereClause = this.selectedCategories.length === 0 ? 
                             "" :   
                            "Product_Category_Txt__c IN ('" + this.selectedCategories.join("','") + "')";
        let subcatWhereClause = this.selectedSubCategories.length === 0 ? 
                                "" : 
                                "Product_Sub_Category_Txt__c IN ('" + this.selectedSubCategories.join("','") + "')";

        if (this.selectedCategories.length > 0 && this.selectedSubCategories.length > 0) {
            whereClause = whereClause +  "(" + catWhereClause  + " AND " + subcatWhereClause + ")";
        }else if (this.selectedCategories.length > 0 && this.selectedSubCategories.length === 0) {
            whereClause = whereClause  + catWhereClause;
        }else if (this.selectedCategories.length === 0 && this.selectedSubCategories.length > 0){
             whereClause = whereClause +  subcatWhereClause;
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
        
        if(!isCountQuery && this.pageSize != null){
            limitClause = ' LIMIT ' + this.pageSize;
        }

        if(!isCountQuery && offset!=null && offset >= 0){
            this.offset = offset;
            offsetClause = ' OFFSET ' + this.offset;
        }

        sQuery = selectClause + whereClause + limitClause + offsetClause;
        console.log('prepare SOQL Query : CURRENT SOQL QUERY -' + sQuery);
        return sQuery;
    }

    /**
     * This method gets the Product Count of the Filtered query
     * This will be used in Pagination
     */
    getProductCount(){

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
            console.log('Count SOQL not prepared');
        }
    }

    /**
     * This method gets the Product of the Filtered query
     * This will be used to show the products
     */
    getProductData(offset){
        let sQuery = this.prepareSOQLQuery(offset, false);
        if(sQuery){
            fetchAssetData({
                sQuery : sQuery
            })
            .then((data) => {
                if(data.length>0){
                    this.recordsToDisplay = data;
                }else{
                    this.recordsToDisplay = [];
                }
            })
            .catch((error) => {
                console.log(error);
            });
        }else{
            console.log('Query SOQL not prepared');
        }
    }
    
    handleSearchFilterChange(event){
        this.searchKey = event.target.value;
        this.selectedCatClass = '';
        if(this.searchKey){
            this.getProductCount();
            this.getProductData(0);
        }else{
            this.recordsToDisplay = [];
        } 
    }

    handleProductRowSelection(event){
        let selectedRows = event.target.getSelectedRows();
        this.selectedCatClass = [];
        if(selectedRows.length > 0){
            selectedRows.forEach(rows => {
                this.selectedCatClass.push(rows.Product_SKU__c);
            });
        }else{
            this.selectedCatClass = [];
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
        this.getProductData(0);
    }

    /**
     * This is called when Previous Button is clicked
     * This will take previous set of records
     */
    goToPreviousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.getProductData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is called when Next Button is clicked
     * This will take next set of records
     */
    goToNextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.getProductData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is when First Button is clicked
     * This will take to first Page of Pagination
     */
    goToFirstPage() {
        this.pageNumber = 1;
        this.getProductData(0,this.pageSize);
    }
    /**
     * This is when Last Button is clicked
     * This will take to last Page of Pagination
     */
    goToLastPage() {
        this.pageNumber = this.totalPages;
        this.getProductData(this.pageSize * (this.pageNumber-1) ,this.pageSize);
    }
}