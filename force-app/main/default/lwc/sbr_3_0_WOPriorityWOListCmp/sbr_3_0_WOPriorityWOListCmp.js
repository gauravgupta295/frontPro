import { LightningElement, wire, api } from 'lwc';
//Get the Columns for Work Order DataTable from Metadata
import getColumns from '@salesforce/apex/SBR_3_0_WOPriorityController.getItemSearchColumns';
//Get the filtered Work Orders
import getFilteredWorkOrders from '@salesforce/apex/SBR_3_0_WOPriorityController.getFilteredWorkOrders';
//Get the count of filtered Work Orders
import getCountOfFilteredWorkOrders from '@salesforce/apex/SBR_3_0_WOPriorityController.getFilteredWorkOrdersCount';
import {loadStyle} from 'lightning/platformResourceLoader';
import eidtLWCcss from '@salesforce/resourceUrl/sbr_3_0_WOPriorityList';

export default class SBR_3_0_WOPriorityWOListCmp extends LightningElement {
    //Columns Array
    columns = [];
    //Raw data from wired getColumns() call
    rawColumnsData;
    //Data Array
    recordsToDisplay = [];
    //Sorting needs to be refactored
    defaultSortDirection = 'asc';
    //Current sort direction
    sortDirection = 'asc';
    //Current sorted by column
    sortedBy = '';
    //Fields to be queried for Work Order
    fieldsToQuery;
    //Searchable fields array
    searchablefieldsArray = [];
    //Search key entered by User
    searchKey;
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
    //Variable to store the Selected Fields
    selectedFieldsForSearch = [];
    //Variable for storing lookup field definations to be used to convert it to URL.
    lookupFieldsName = [];
    //Variable to fields of Lookup Record (Relationship)
    relationshipFieldsList = [];
    //Variable for Current Selected Level Value (Branch/District/Inventory Region)
    currentLevelPicklistValue = null;
    //Variable to indicate Current Selected Level (if Branch, use LocId, if any thing else, use PicklistValue)
    currentLevelValue = null;
    //Variable to indicate Current Selected Standard Filter Name 
    currentStandardFilterName = null;
    //Variable to indicate Current Selected Standard Filter Where Clause
    currentStandardFilterWhere = null;
    /*
    *** FOR ASSET ATTRIBUTE FILTER *** 
    */
    //Variable to store the selected Asset Status Values
    selectedStatusValues = ['DOWN - LESS THAN 20 DAYS','DOWN - MORE THAN 20 DAYS','SAFETY/SERVICE LOCKOUT'];
    //Variable to store the selected Asset Equipment Type Values
    selectedEquipmentTypeValues = ['CONSIGNED','FLOORED','NEW FOR SALE','OWNED','RENTAL','SUB LEASED','TRADE IN','LEASED','SEASONAL'];
    //Variable to store the selected Asset Original Cost Value
    selectedOriginalCostValues = [];
    //Variable to store the applied Asset Equipment Type Values
    appliedEquipmentTypeValues = [];
    //Variable to store the applied Asset Status Values
    appliedStatusValues = [];
    //Value of Starting Range of Original Cost 
    startOriginalCost;
    //Value of End Range of Original Cost
    endOriginalCost;
    /* 
    *** FOR WORK ORDER ATTRIBUTE FILTER *** 
    */
    //Variable to store the selected WorkOrder Status Values
    selectedWOStatusValues = ['Open','Scheduled','Dispatched','In Route','On Site','Converted','Completed with Exceptions','Unable to Complete','Cancel with Exception','Closed with Exception','Submitted','Approved','Rejected','Expired','Draft'];
    //Variable to store the selected Work Order Description Values
    selectedWorkOrderDescValues = [];
    //Variable to store the selected Bill Customer or Location Values
    selectedBillCustLocValues = [];
    //Variable to store the selected Claim Type Values
    selectedClaimTypeValues = [];
    //Variable to store the applied WorkOrder Status Values
    appliedWOStatusValues = [];


    renderedCallback(){
        Promise.all([
            loadStyle(this,eidtLWCcss)
        ])
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
        return this.recordsToDisplay.length > 0;
    }

    /**
     * This is the wired method to get the Work Order Table Columns
     * This will be fired on load
    */
    @wire(getColumns)
    getColumns({error, data}) {
        if(data) {
            this.rawColumnsData = data;
            this.parseColumnsOnLoad();
        } else if(error) {
            console.log(error);
        }
    }

    parseColumnsOnLoad() {
        if(!this.rawColumnsData || !this.currentStandardFilterName) {
            return;
        }

        //Get all columns which are for context "Work Order Priority"
        let itemSearchCols = this.rawColumnsData.filter(col =>
            col?.SM_PS_List_Views_Allowed__c?.split(',')?.includes(this.currentStandardFilterName)
        );
        
        //Sort all columns by Order field
        itemSearchCols.sort((a,b) => a.Order__c - b.Order__c);
        //add these columns in the columns array
        this.columns = [];
        // Clear contents prior to appending text in the forEach loop.
        this.fieldsToQuery = '';
        this.lookupFieldsName = [];
        this.searchablefieldsArray = [];
        itemSearchCols.forEach( col => {
            let colItem = {};
            colItem.hideDefaultActions = true;
            colItem.sortable = col.IsSortable__c;
            colItem.wrapText = true;
            colItem.label = col.Label;
            colItem.fieldName = col.Field_Name__c;
            colItem.type = col.Type__c?col.Type__c:"text";

            if(col.Type__c === 'url'){
                colItem.typeAttributes = {
                    target: '_self'
                }
                if(col.SM_PS_URL_Label__c) {
                    colItem.typeAttributes.label = { fieldName : col.SM_PS_URL_Label__c };
                }
            }

            if(col.Field_Name__c.includes(".")) {
                this.relationshipFieldsList.push(col.Field_Name__c);
            }

            if(col.Type__c === 'lookup') {
                let relativeName = col.Field_Name__c.substring(0, col.Field_Name__c.lastIndexOf('.'));
                let relativeFieldName = col.Field_Name__c.substring(col.Field_Name__c.lastIndexOf('.') + 1);
                let fullRelativeName = relativeName + '.' + relativeFieldName;
                let relativeFieldActualName;
                if(relativeName.endsWith('__r')) {
                    relativeFieldActualName = relativeName.substring(0, relativeName.length - 1) + 'c';
                } else {
                    relativeFieldActualName = relativeName + 'Id';
                }
                let colName = col.Label;
                let lookupDefination = {relativeName, relativeFieldName, fullRelativeName, relativeFieldActualName, colName};
                this.lookupFieldsName.push(lookupDefination);
                this.fieldsToQuery += fullRelativeName + ',';

                colItem.type = "url";
                colItem.fieldName = relativeFieldActualName;
                colItem.typeAttributes = {
                    label: { fieldName : fullRelativeName },
                    target: '_self'
                }
            }

            if(col.fixedWidth__c) {
                colItem.fixedWidth = col.fixedWidth__c;
            }

            this.columns = [...this.columns, colItem];

            //Add the column for querying data
            if(!col.Field_Name__c.endsWith('LinkUrl') && col.Type__c !== 'lookup'){
                this.fieldsToQuery += col.Field_Name__c + ',';
            }
            if(col.SM_PS_URL_Label__c && !col.SM_PS_URL_Label__c.endsWith('LinkUrl')) {
                this.fieldsToQuery += col.SM_PS_URL_Label__c + ',';
            }
            if(col.Type__c !== 'date' && col.Type__c !== 'boolean' && col.Type__c !== 'number' && col.Label !== 'Comment') {
                let comboOption = {};
                comboOption.label = col.Label;
                if(col.Type__c === 'url') {
                    comboOption.value = col.SM_PS_URL_Label__c;
                } else {
                    comboOption.value = col.Field_Name__c;
                }

                this.searchablefieldsArray = [...this.searchablefieldsArray,comboOption];
                this.selectedFieldsForSearch = [...this.selectedFieldsForSearch, comboOption.value];
            }
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
    }

    parseColumnsOnStandardFilterChange() {
        if(!this.rawColumnsData || !this.currentStandardFilterName) {
            return;
        }

        //Get all columns which are for context "Work Order Priority"
        let itemSearchCols = this.rawColumnsData.filter(col =>
            col?.SM_PS_List_Views_Allowed__c?.split(',')?.includes(this.currentStandardFilterName)
        );
 
        //Sort all columns by Order field
        itemSearchCols.sort((a,b) => a.Order__c - b.Order__c);
        //add these columns in the columns array
        this.columns = [];
        // Clear contents prior to appending text in the forEach loop.
        this.fieldsToQuery = '';
        this.lookupFieldsName = [];
        this.searchablefieldsArray = [];

        itemSearchCols.forEach( col => {
            let colItem = {};
            colItem.hideDefaultActions = true;
            colItem.sortable = col.IsSortable__c;
            colItem.wrapText = true;
            colItem.label = col.Label;
            colItem.fieldName = col.Field_Name__c;
            colItem.type = col.Type__c?col.Type__c:"text";

            if(col.Type__c === 'url'){
                colItem.typeAttributes = {
                    target: '_self'
                }
                if(col.SM_PS_URL_Label__c) {
                    colItem.typeAttributes.label = { fieldName : col.SM_PS_URL_Label__c };
                }
            }

            if(col.Field_Name__c.includes(".")) {
                this.relationshipFieldsList.push(col.Field_Name__c);
            }

            if(col.Type__c === 'lookup') {
                let relativeName = col.Field_Name__c.substring(0, col.Field_Name__c.lastIndexOf('.'));
                let relativeFieldName = col.Field_Name__c.substring(col.Field_Name__c.lastIndexOf('.') + 1);
                let fullRelativeName = relativeName + '.' + relativeFieldName;
               
                let relativeFieldActualName;
                if(relativeName.endsWith('__r')) {
                    relativeFieldActualName = relativeName.substring(0, relativeName.length - 1) + 'c';
                } else {
                    relativeFieldActualName = relativeName + 'Id';
                    
                }
                let colName = col.Label;
                let lookupDefination = {relativeName, relativeFieldName, fullRelativeName, relativeFieldActualName, colName};
                

                this.lookupFieldsName.push(lookupDefination);
                this.fieldsToQuery += fullRelativeName + ',';

                colItem.type = "url";
                colItem.fieldName = relativeFieldActualName;
                colItem.typeAttributes = {
                    label: { fieldName : fullRelativeName },
                    target: '_self'
                }
            }

            if(col.fixedWidth__c) {
                colItem.fixedWidth = col.fixedWidth__c;
            }

            this.columns = [...this.columns, colItem];

            //Add the column for querying data
            if(!col.Field_Name__c.endsWith('LinkUrl') && col.Type__c !== 'lookup'){
                this.fieldsToQuery += col.Field_Name__c + ',';
            }
            if(col.SM_PS_URL_Label__c && !col.SM_PS_URL_Label__c.endsWith('LinkUrl')) {
                this.fieldsToQuery += col.SM_PS_URL_Label__c + ',';
            }
            if(col.Type__c !== 'date' && col.Type__c !== 'boolean' && col.Type__c !== 'number' && col.Label !== 'Comment') {
                let comboOption = {};
                comboOption.label = col.Label;
                if(col.Type__c === 'url') {
                    comboOption.value = col.SM_PS_URL_Label__c;
                } else {
                    comboOption.value = col.Field_Name__c;
                }

                this.searchablefieldsArray = [...this.searchablefieldsArray,comboOption];
                this.selectedFieldsForSearch = [...this.selectedFieldsForSearch, comboOption.value];
            }
        });

        //Add all combo option for serachable array
        let comboOption = {};
        comboOption.label = 'All';
        comboOption.value = 'All';
        this.searchablefieldsArray.splice(0,0,comboOption);

        //Send this event to WOPriorityHeaderCmp for setting fields in the filter combo box.
        const searchFilterFieldSetEvent = new CustomEvent('searchfilterfieldsetevent', {
            'detail': {
                searchfields : this.searchablefieldsArray
            }
        });
        
        this.dispatchEvent(searchFilterFieldSetEvent);
        
    }

    /**
     * This is called when the Level PickList Vales is changed
     * This will acutually call the apex to get WorkOrder record 
    */
    @api handleLevelPicklistSelectionEvent(levelDetailRec){
        if(levelDetailRec) {
            this.currentLevelPicklistValue = levelDetailRec.standardFilterLevelValue;
            this.currentLevelValue = levelDetailRec.standardFilterLevelApiName;
            this.currentStandardFilterName = levelDetailRec.standardFilterName;
            this.currentStandardFilterWhere = levelDetailRec.standardFilterWhere;
            this.selectedWOStatusValues = levelDetailRec.standardFilterWoStatusMDT;
            this.selectedStatusValues = levelDetailRec.standardFilterAssetStatusMDT;
            this.selectedEquipmentTypeValues = levelDetailRec.standardFilterAssetEqpTypeMDT;

            this.getWorkOrderCount();
            this.getActualWorkOrderData(0);
        }else{
            console.error("handleLevelPicklistSelectionEvent : Unable to get the Level Detail Record");
        }
    } 

    /**
     * This is called when the Level PickList Vales is changed
     * This will acutually call the apex to get WorkOrder record 
    */
    @api handleStandardFilterSelectionEvent(standardFilterDetailRec){
        if(standardFilterDetailRec) {
            let shouldReparseColumns = false;
            if(this.currentStandardFilterName != standardFilterDetailRec.standardFilterName) {
                shouldReparseColumns = true;
            }
            
            this.currentLevelPicklistValue = standardFilterDetailRec.standardFilterLevelValue;
            this.currentLevelValue = standardFilterDetailRec.standardFilterLevelApiName;
            this.currentStandardFilterName = standardFilterDetailRec.standardFilterName;
            this.currentStandardFilterWhere = standardFilterDetailRec.standardFilterWhere;
            this.selectedWOStatusValues = standardFilterDetailRec.standardFilterWoStatusMDT;
            this.selectedStatusValues = standardFilterDetailRec.standardFilterAssetStatusMDT;
            this.selectedEquipmentTypeValues = standardFilterDetailRec.standardFilterAssetEqpTypeMDT;
            this.selectedClaimTypeValues = [];
            this.selectedBillCustLocValues = [];
            this.selectedWorkOrderDescValues = [];
            this.selectedOriginalCostValues = [];
            this.startOriginalCost = null;
            this.endOriginalCost = null;
            this.appliedEquipmentTypeValues = [];
            this.appliedStatusValues = [];
            this.appliedWOStatusValues = [];

            if(shouldReparseColumns) {
               this.parseColumnsOnStandardFilterChange();
            }

            this.getWorkOrderCount();
            this.getActualWorkOrderData(0);
        }else{
            console.error("handleStandardFilterSelectionEvent : Unable to get the Standard Filter Detail Record");
        }
    } 

    /**
     * This is called when the Apply Button of AssetAttributeFilterCmp
     * This will acutually call the apex to get WorkOrder record by adding Asset.Status and Asset.Equipment_Type filters
    */
    @api handleApplyAssetAttributeFilterEvent(applyEventDetailRec){
        if(applyEventDetailRec) {
            this.selectedEquipmentTypeValues = applyEventDetailRec.selectedEquipmentTypeValues;
            this.selectedStatusValues = applyEventDetailRec.selectedStatusValues;
            this.selectedOriginalCostValues = applyEventDetailRec.selectedOriginalCostValues;
            this.startOriginalCost = applyEventDetailRec.startOriginalCost;
            this.endOriginalCost = applyEventDetailRec.endOriginalCost;
            if(this.currentStandardFilterName == 'All Work Orders') {
                this.appliedEquipmentTypeValues = applyEventDetailRec.selectedEquipmentTypeValues;
                this.appliedStatusValues = applyEventDetailRec.selectedStatusValues;
            }

            this.getWorkOrderCount();
            this.getActualWorkOrderData(0);
        }else{
            console.error("handleApplyAssetAttributeFilterEvent : Unable to get the Apply Event Record");
        }
    } 

    /**
     * This is called when the Apply Button of WorkOrderAttributeFilterCmp
     * This will actually call the apex to get WorkOrder records by adding Status, Description, Bill Customer or Location and Claim Type filters
    */
    @api handleApplyWOAttributeFilterEvent(applyEventDetailRec){
        if(applyEventDetailRec) {
            this.selectedWOStatusValues = applyEventDetailRec.selectedWOStatusValues;
            this.selectedWorkOrderDescValues = applyEventDetailRec.selectedWorkOrderDescValues;
            this.selectedBillCustLocValues = applyEventDetailRec.selectedBillCustLocValues;
            this.selectedClaimTypeValues = applyEventDetailRec.selectedClaimTypeValues;
            if(this.currentStandardFilterName == 'All Work Orders') {
                this.appliedWOStatusValues = applyEventDetailRec.selectedWOStatusValues;
            } 

            this.getWorkOrderCount();
            this.getActualWorkOrderData(0);
        }else{
            console.error("handleApplyWOAttributeFilterEvent : Unable to get the Apply Event Record");
        }
    } 

    /**
     * This is called when Search Key filter change is applied 
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
            } else {
                this.selectedFieldsForSearch = searchFilterRec.fieldSelected;
            }

            this.getWorkOrderCount();
            this.getActualWorkOrderData(0);
        }else{
            console.error("handleSearchFilterEvent : Unable to get the Apply Event Record");
        }
    }

    /**
     * This method prepares the SOQL Query based on user selected filters
    */
    prepareSOQLQuery(offset, isCountQuery){
        //Variable to store complete query
        let sQuery;
        //Variable to store the Select Clause
        let selectClause = 'SELECT ';
        //Variable to store the From Clause
        let fromClause = 'Id FROM WorkOrder';
        //Variable to store the Where Clause
        let whereClause = ' WHERE ';
        //Variable to store the searchKey Where Clause
        let searchKeyWhereClause = '';
        //Variable to store the status Where Clause
        let statusWhereClause = '';
        //Variable ro store the Equipment Type Where Clause
        let equipmentTypeWhereClause = '';
        //Variable ro store the Original Cost Where Clause
        let originalCostWhereClause = '';
        //Variable to store the WO Status Where Clause
        let woStatusWhereClause = '';
        //Variable ro store the Work Order Description Where Clause
        let workOrderDescWhereClause = '';
        //Variable to store the Bill to Customer or Location Where Clause
        let billCustLocWhereClause = '';
        //Variable ro store the Claim Type Where Clause
        let claimTypeWhereClause = '';
        //Variable to store the limit Clause
        let limitClause = ''; 
        //Variable to store the offsetClause
        let offsetClause = '';

        //Create the Select Clause
        if(isCountQuery) {
            selectClause = 'SELECT count() FROM WorkOrder';
        } else {
            if(this.fieldsToQuery) {
                selectClause = selectClause + this.fieldsToQuery + fromClause;
            } else {
                selectClause = selectClause + fromClause;
            }
        }

        if(this.currentStandardFilterName == 'All Work Orders') {
            this.selectedStatusValues = this.appliedStatusValues;
            this.selectedEquipmentTypeValues = this.appliedEquipmentTypeValues;
            this.selectedWOStatusValues = this.appliedWOStatusValues;
        }
        //Check if the level value is present or not. If present, the query else
        if(this.currentLevelValue && this.currentLevelPicklistValue) {
            //Create Clause for Current Level (Branch/District/Inventory Region)
            whereClause = whereClause + ' ' + this.currentLevelValue + ' = \'' + this.currentLevelPicklistValue + '\' ';
            //Create Clause for Asset Status Filter
            if(this.selectedStatusValues.length > 0) {
                statusWhereClause = 'AND Asset.Status IN (';
                this.selectedStatusValues.forEach(statusValue => {
                    statusWhereClause = statusWhereClause + '\'' + statusValue + '\', ';
                })
                statusWhereClause = statusWhereClause.substring(0, statusWhereClause.length - 2)  + ') ';
                whereClause = whereClause + statusWhereClause;
            }else {
                whereClause = whereClause + 'AND Status != \'Deleted\' '; 
            }
            //Create Clause for Asset Equipment Type Filter
            if(this.selectedEquipmentTypeValues.length > 0) {
                equipmentTypeWhereClause = 'AND Asset.SM_PS_Equipment_Type__c IN (';
                this.selectedEquipmentTypeValues.forEach(equipmentTypeValue => {
                    equipmentTypeWhereClause = equipmentTypeWhereClause + '\'' + equipmentTypeValue + '\', ';
                })
                equipmentTypeWhereClause = equipmentTypeWhereClause.substring(0, equipmentTypeWhereClause.length - 2)  + ') ';
                whereClause = whereClause + equipmentTypeWhereClause;
            }
            //Create Clause for Asset Original Cost Filter
            if(this.selectedOriginalCostValues != null && this.startOriginalCost != null && this.endOriginalCost != null && this.startOriginalCost != '' && this.endOriginalCost != '') {
                if(this.selectedOriginalCostValues == 'Over $100,000') {
                    originalCostWhereClause = 'AND Asset.SM_PS_Cost__c >= ' + this.startOriginalCost + ' '; 
                } else {
                    originalCostWhereClause = 'AND Asset.SM_PS_Cost__c >= ' + this.startOriginalCost + ' AND Asset.SM_PS_Cost__c <= ' +  this.endOriginalCost + ' ';
                }
                whereClause = whereClause + originalCostWhereClause;
            }
            //Create Clause for Work Order Status Filter
            if(this.selectedWOStatusValues.length > 0) {
                woStatusWhereClause = 'AND Status IN (';
                this.selectedWOStatusValues.forEach(woStatusValue => {
                    if(woStatusValue == 'Open')
                        woStatusValue = 'O';
                    if(woStatusValue == 'Canceled')
                        woStatusValue = 'D';
                    if(woStatusValue == 'Closed')
                        woStatusValue = 'C';

                    woStatusWhereClause = woStatusWhereClause + '\'' + woStatusValue + '\', ';
                })
                woStatusWhereClause = woStatusWhereClause.substring(0, woStatusWhereClause.length - 2)  + ') ';
                whereClause = whereClause + woStatusWhereClause;
            }
            //Create Clause for Work Order Description Filter
            if(this.selectedWorkOrderDescValues.length > 0) {
                workOrderDescWhereClause = 'AND SF_PS_Work_Order_Des__c IN (';
                this.selectedWorkOrderDescValues.forEach(woDescValue => {
                    workOrderDescWhereClause = workOrderDescWhereClause + '\'' + woDescValue + '\', ';
                })
                workOrderDescWhereClause = workOrderDescWhereClause.substring(0, workOrderDescWhereClause.length - 2)  + ') ';
                whereClause = whereClause + workOrderDescWhereClause;
            }
            //Create Clause for Bill Customer or Location Filter
            if(this.selectedBillCustLocValues.length > 0) {
                billCustLocWhereClause = 'AND SF_PS_BillCustOrLoc__c IN (';
                this.selectedBillCustLocValues.forEach(billCustLocValue => {
                    billCustLocWhereClause = billCustLocWhereClause + '\'' + billCustLocValue + '\', ';
                })
                billCustLocWhereClause = billCustLocWhereClause.substring(0, billCustLocWhereClause.length - 2)  + ') ';
                whereClause = whereClause + billCustLocWhereClause;
            }
            //Create Clause for Claim Type Filter
            if(this.selectedClaimTypeValues.length > 0) {
                claimTypeWhereClause = 'AND SF_PS_Claim_Type__c IN (';
                this.selectedClaimTypeValues.forEach(claimTypeValue => {
                    claimTypeWhereClause = claimTypeWhereClause + '\'' + claimTypeValue + '\', ';
                })
                claimTypeWhereClause = claimTypeWhereClause.substring(0, claimTypeWhereClause.length - 2)  + ') ';
                whereClause = whereClause + claimTypeWhereClause;
            }
            //WHERE CLAUSE from Metadata
            if(this.currentStandardFilterWhere != undefined || this.currentStandardFilterWhere != null) {
                whereClause = whereClause + this.currentStandardFilterWhere;
            }
            //Now create the Where clause from Search Key
            if(this.searchKey){
                let searchKeyStrings = [];
                if(this.searchKey.includes(',')){
                   searchKeyStrings = this.searchKey.split(',');
                }else{
                    searchKeyStrings = [this.searchKey];
                }

                searchKeyWhereClause = ' AND (';
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
            console.log('Prepare SOQL Query : CURRENT SOQL QUERY --> ' + sQuery);
        }
        return sQuery;
    }

    /**
     * This method gets the Work Order Count of the Filtered query
     * This will be used in Pagination
     */
    getWorkOrderCount(){
        let sQuery = this.prepareSOQLQuery(0, true);
        if(sQuery){
            getCountOfFilteredWorkOrders({
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
    * This method actually calls Apex Method to get Work Orders and displays them on the data table
    * It requries offset parameter which will be the current offset
    */
    getActualWorkOrderData(offset){
        let sQuery = this.prepareSOQLQuery(offset, false);
        if(sQuery){
            getFilteredWorkOrders({
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
                            
                            if(tempRec[relativeName]) {
                                let recId = tempRec[relativeName].Id;
                                let recName = tempRec[relativeName][relativeFieldName];
                                tempRec[colName] = recName;
                                tempRec[relativeFieldActualName] = '/' + recId;
                            }
                            let label = tempRec;

                            lookupField.fullRelativeName.split('.').forEach(fieldPart => {
                                if (label) {
                                    label = label[fieldPart];
                                }
                            });
                            tempRec[lookupField.fullRelativeName] = label                            
                        });

                        //Handling related record data (Lookup relationship - Asset/Damage Estimator/Service Resource)
                        this.relationshipFieldsList.forEach(fieldName => {
                            if(fieldName != 'LinkUrl') {
                                let fieldapiname = fieldName.split('.');
                                if(JSON.stringify(record).includes(fieldapiname[0])) {
                                    let fieldValue = tempRec[fieldapiname[0]][fieldapiname[1]];
                                    if(typeof fieldValue === "boolean" && fieldValue == true) {
                                        tempRec[fieldName] =  toString(fieldValue);
                                    } else {
                                        tempRec[fieldName] =  fieldValue;
                                    } 
                                }     
                            }
                        });
                        tempRecs.push( tempRec );
                    });

                    this.recordsToDisplay = tempRecs;
                    this.onHandleSort({detail: {fieldName: this.sortedBy, sortDirection: this.sortDirection}});
                } else {
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
        if(sortedBy) {
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        } else {
            cloneData.sort(this.sortByDefault);
        }
        this.recordsToDisplay = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    /**
     * Used to sort the 'Days Down, Svc Due etc.' column 
    **/ 
    sortBy(field, reverse, primer) {
        console.log('*** sortby field '+field);
        console.log('*** sortby reverse '+reverse);
        console.log('*** sortby primer '+primer);
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                console.log('** sortby x[field] '+x[field]);
                  return x[field];
              };

        return function (a, b) {
            a = key(a) ? key(a) : "";
            b = key(b) ? key(b) : "";
            return reverse * ((a > b) - (b > a));
        };
    }

    sortByDefault(a, b) {
        if(a.Asset.SM_PS_Utilization__c > b.Asset.SM_PS_Utilization__c) {
            return -1;
        } else if(a.Asset.SM_PS_Utilization__c < b.Asset.SM_PS_Utilization__c) {
            return 1;
        } else if(a.Asset.SM_PS_Branch_Available_Units__c < b.Asset.SM_PS_Branch_Available_Units__c) {
            return -1;
        } else if(a.Asset.SM_PS_Branch_Available_Units__c > b.Asset.SM_PS_Branch_Available_Units__c) {
            return 1;
        } else if(a.Priority < b.Priority) {
            return -1;
        } else if(a.Priority > b.Priority) {
            return 1;
        } else if(a.Asset.SM_PS_ProductCategory__c < b.Asset.SM_PS_ProductCategory__c) {
            return -1;
        } else if(a.Asset.SM_PS_ProductCategory__c > b.Asset.SM_PS_ProductCategory__c) {
            return 1;
        } else if(a.Asset.SM_PS_ProductSubCategory__c < b.Asset.SM_PS_ProductSubCategory__c) {
            return -1;
        } else if(a.Asset.SM_PS_ProductSubCategory__c > b.Asset.SM_PS_ProductSubCategory__c) {
            return 1;
        }
        return 0;
    }

    /**
     * This event is for handling the change in combo box of Record Per Page
     * This will get the WorkOrder data as per new Page Size
    */
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.pageNumber = 1;
        this.totalPages = Math.ceil(this.totalRecords / event.target.value);
        this.getActualWorkOrderData(0);
    }

    /**
     * This is called when Previous Button is clicked
     * This will take previous set of records
    */
    goToPreviousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.getActualWorkOrderData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is called when Next Button is clicked
     * This will take next set of records
    */
    goToNextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.getActualWorkOrderData(this.pageSize * (this.pageNumber-1));
    }

    /**
     * This is when First Button is clicked
     * This will take to first Page of Pagination
    */
    goToFirstPage() {
        this.pageNumber = 1;
        this.getActualWorkOrderData(0,this.pageSize);
    }

    /**
     * This is when Last Button is clicked
     * This will take to last Page of Pagination
    */
    goToLastPage() {
        this.pageNumber = this.totalPages;
        this.getActualWorkOrderData(this.pageSize * (this.pageNumber-1) ,this.pageSize);
    }
}