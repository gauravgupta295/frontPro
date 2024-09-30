import { LightningElement, wire, api } from 'lwc';
import fetchRentalCatClass from '@salesforce/apex/PPA_RentalCatClassController.fetchRentalCatClass';
import deleteSelectedRecords from '@salesforce/apex/PPA_RentalCatClassController.deleteSelectedRecords';
import fetchMonthOnlyMetaData from '@salesforce/apex/PPA_RentalCatClassController.fetchMonthOnlyMetaData';
import { refreshApex } from '@salesforce/apex';
import { updateRecord, deleteRecord, getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RECORD_TYPE_FIELD from '@salesforce/schema/PPA_Price_List__c.RecordType.DeveloperName';
import STATUS_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_Status__c';
import COMPANY_NAME_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_Customer_Name__c';
import RA_IMPROVEMENT_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_RA_Improvement__c';
import HASPERMISSION from '@salesforce/schema/PPA_Price_List__c.PPA_hasEditPermission__c';
import deleteModal from 'c/pPA_ConfirmDeleteModalLWC';
import detailsModal from 'c/pPA_RecordDetailsModalLWC';
import addCatClass from 'c/pPA_AddCatClassLWC';
import massEditModal from 'c/pPA_CatClassMassEditLWC';
import COMPANYID from '@salesforce/schema/PPA_Price_List__c.PPA_CompanyId__c';
import { loadStyle } from 'lightning/platformResourceLoader';
import PPALWCCSS from '@salesforce/resourceUrl/PPA_lwcCSS';
import NAT_ACT_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_National_Account__c';
//Inline editing
import updateRecords from '@salesforce/apex/PPA_RentalCatClassController.updateRecords';

const col1 = [
    { label: 'CatClass', fieldName: 'PPA_CatClass__c', type: 'button', typeAttributes: { label: { fieldName: 'PPA_CatClass__c'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: {alignment: 'left', class: 'slds-p-vertical_none slds-m-vertical_none'}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Class Name', fieldName: 'PPA_Product_Name__c', type: 'text', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 300, wrapText: true},
    { label: 'Loaded', fieldName: 'PPA_Rates_Loaded__c', type: 'boolean', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Rental Revenue', fieldName: 'PPA_Rental_Revenue__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Times Rented', fieldName: 'PPA_Times_Rented__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Day', fieldName: 'PPA_Old_Day__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Week', fieldName: 'PPA_Old_Week__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Month', fieldName: 'PPA_Old_Month__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true}         
];

const col2 = [
    { label: 'CatClass', fieldName: 'PPA_CatClass__c', type: 'button', typeAttributes: { label: { fieldName: 'PPA_CatClass__c'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: {alignment: 'left', class: 'slds-p-vertical_none slds-m-vertical_none'}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Class Name', fieldName: 'PPA_Product_Name__c', type: 'text', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 300, wrapText: true},
    { label: 'Loaded', fieldName: 'PPA_Rates_Loaded__c', type: 'boolean', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Rental Revenue', fieldName: 'PPA_Rental_Revenue__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Times Rented', fieldName: 'PPA_Times_Rented__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Day', fieldName: 'PPA_Old_Day__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Week', fieldName: 'PPA_Old_Week__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Month', fieldName: 'PPA_Old_Month__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},         
    { label: 'New Day', fieldName: 'PPA_New_Day__c', type: 'currency', editable: false, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'New Week', fieldName: 'PPA_New_Week__c', type: 'currency', editable: false , cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'New Month', fieldName: 'PPA_New_Month__c', type: 'currency', editable: false, cellAttributes: {alignment: 'left'}, hideDefaultActions: true},
    { label: 'D%', fieldName: 'PPA_Change_Day__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50},
    { label: 'W%', fieldName: 'PPA_Change_Week__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50},
    { label: 'M%', fieldName: 'PPA_Change_Month__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50}
 ];

const col3 = [
    { label: 'CatClass', fieldName: 'PPA_CatClass__c', type: 'button', typeAttributes: { label: { fieldName: 'PPA_CatClass__c'}, name: 'view', value: 'view', variant: 'base'}, cellAttributes: {alignment: 'left', class: 'slds-p-vertical_none slds-m-vertical_none'}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Class Name', fieldName: 'PPA_Product_Name__c', type: 'text', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 300, wrapText: true},
    { label: 'Loaded', fieldName: 'PPA_Rates_Loaded__c', type: 'boolean', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 75},
    { label: 'Rental Revenue', fieldName: 'PPA_Rental_Revenue__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Times Rented', fieldName: 'PPA_Times_Rented__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Day', fieldName: 'PPA_Old_Day__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Week', fieldName: 'PPA_Old_Week__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'Current Month', fieldName: 'PPA_Old_Month__c', type: 'currency', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},         
    { label: 'New Day', fieldName: 'PPA_New_Day__c', type: 'currency', editable: false, cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'New Week', fieldName: 'PPA_New_Week__c', type: 'currency', editable: false , cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'New Month', fieldName: 'PPA_New_Month__c', type: 'currency',editable: false, cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true},
    { label: 'D%', fieldName: 'PPA_Change_Day__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50},
    { label: 'W%', fieldName: 'PPA_Change_Week__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50},
    { label: 'M%', fieldName: 'PPA_Change_Month__c', type: 'number', cellAttributes: {alignment: 'left', class: { fieldName: 'PPA_RowColorClass__c'}}, hideDefaultActions: true, initialWidth: 50}
];

const sortOptions1 = [
    {label: "--None--", value: 'None'},
    {label: "CatClass", value: 'PPA_CatClass__c'},
    {label: "Class Name", value: 'PPA_Product_Name__c'},
    {label: 'Rental Revenue', value: 'PPA_Rental_Revenue__c'},
    {label: 'Times Rented', value: 'PPA_Times_Rented__c'},
    {label: 'Current day', value: 'PPA_Old_Day__c'},
    {label: 'Current Week', value: 'PPA_Old_Week__c'},
    {label: 'Current Month', value: 'PPA_Old_Month__c'},
    {label: 'New Day', value: 'PPA_New_Day__c'},
    {label: 'New Week', value: 'PPA_New_Week__c'},
    {label: 'New Month', value: 'PPA_New_Month__c'},
    {label: 'Changed D%', value: 'PPA_Change_Day__c'},
    {label: 'Changed W%', value: 'PPA_Change_Week__c'},
    {label: 'Changed M%', value: 'PPA_Change_Month__c'},
];

const sortOptions2 = [
    {label: "--None--", value: 'None'},
    {label: "CatClass", value: 'PPA_CatClass__c'},
    {label: "Class Name", value: 'PPA_Product_Name__c'},
    {label: 'Rental Revenue', value: 'PPA_Rental_Revenue__c'},
    {label: 'Times Rented', value: 'PPA_Times_Rented__c'},
    {label: 'Current day', value: 'PPA_Old_Day__c'},
    {label: 'Current Week', value: 'PPA_Old_Week__c'},
    {label: 'Current Month', value: 'PPA_Old_Month__c'},
];

const filterOptions = [
    {label: "--None--", value: 'None'},
    {label: "Below Pain Point(s)", value: 'PPA_Below_Min__c'},
    {label: "CatClass", value: 'PPA_CatClass__c'},
    {label: "CatClass Owner", value: 'PPA_CatClassOwner__c'},
    {label: "Class Name", value: 'PPA_Product_Name__c'},
    {label: "Flat % Applied", value: 'PPA_UpdatedBy_Mass_Edit__c'},
    {label: "Free Rental", value: 'PPA_Free_Rental__c'},
    {label: "Rates Loaded", value: 'PPA_Rates_Loaded__c'},
    {label: "Recently Added", value: 'PPA_CatClass_Added__c'},
    {label: "Top X Rentals", value: 'PPA_Top_X_Rentals__c' },
    {label: "Week Error", value: 'PPA_Week_Error__c'},
];

const fieldAPINames = {
    standardDay : 'PPA_New_Day__c',
    standardWeek : 'PPA_New_Week__c',
    standardMonth : 'PPA_New_Month__c',

    nonStrategicDay : 'PPA_Non_Managed_Account_Day__c',
    nonStrategicWeek : 'PPA_Non_Managed_Account_Week__c',
    nonStrategicMonth : 'PPA_Non_Managed_Account_Month__c',

    strategicDay : 'PPA_Managed_Account_Day__c',
    strategicWeek : 'PPA_Managed_Account_Week__c',
    strategicMonth : 'PPA_Managed_Account_Month__c',

    nationalDay : 'PPA_National_Account_Day__c',
    nationalWeek : 'PPA_National_Account_Week__c',
    nationalMonth : 'PPA_National_Account_Month__c',
}


export default class PPA_RentalCatClassLWCWrapper extends LightningElement {
    @api recordId; 
    mapData = [];
    allRecords = [];
    dataToRefresh;
    recordTypeName;
    recordStatus;
    error;
    col1 = col1;
    col2 = col2;
    col3 = col3;
    colDisplay;
    showtop10Records = false;
    top10Records= [];
    IsActive = false;
    keyword ='';
    selectedFilter = null;
    filteredData =[];
    filteredRecordsOnly = false;
    showSpinner = true;
    showInputField = true;
    showCheckbox = false;
    isChecked = true;
    percentageValue = '';
    displayPercentage = '';
    sortedRecords=[];
    superCats = [];
    activeSections = [];
    companyName;
    showActionButtons = false;
    disableButton = false;
    sortFilter = null;
    sortDirection = 'asc';
    showUpButton = true;
    masterSort = 'PPA_MasterSort__c';
    filterApplied = false;
    reBuildOnLoad = true;
    weekErrorRecord =[];
    recentlyAddedRecord =[];
    productCount = 0;
    displayCount = 0;
    companyId;
    okToProcess = true;
    isCSSLoaded = false;
    isSelectAllChecked = false;
    showSpinner = false;
    hasEditPermission = false;
    sortOptions;
    sortOptions1 = sortOptions1;
    sortOptions2 = sortOptions2;
    filterOptions = filterOptions;
    
    //PPA Phase 2 -- start
    fetchedCatClasses = [];
    monthOnlyValues = [];
    numberOfDays = 28;
    numberOfWeeks = 4;
    priceListRAImprovement = 0.00;
    raImprovePct = 0.00;
    nonStrategicAccountRAImprovePct = 0.00;
    strategicAccountRAImprovePct = 0.00;
    nationalAccountRAImprovePct = 0.00;
    isXNum;
    inputType;
    showNationalAccFields = false;
    //PPA Phase 2 -- End
    
    //Inline editing start
    editClicked = false;
    top10EditClicked = false;
    showCancelButton = false;
    showEditButton = false;
    showSaveButton = false;
    showAdditionalCols = false;
    showEditableCols = false;
    finalRows = {};
    finalRowsList = [];
    errMsgList = [];
    showTop10Toggle = true;
    showRevertButton = false;
    catClassDatatableClass = 'hideFirstColTable fixedHeader record-container datatable-zoom';
    top10datatableClass = 'hideFirstColTable datatable-zoom';
    //Inline editing end

    //Added as part of PPA Phase 2
    connectedCallback() {
        fetchMonthOnlyMetaData()
            .then((data) => {
                if (data != null) {
                    this.monthOnlyValues = data;
                    // If wired catClass promise returned before this promise,
                    // invoke wire again by reactive property update.
                    if(this.allRecords.length > 0){
                        this.recordId = this.recordId;
                    } 
                }
            })
            .catch((error) => {
                this.error = error;
                this.monthOnlyValues =[];

            });
        }

    renderedCallback() {
        if(!this.isCSSLoaded) {
            loadStyle(this, PPALWCCSS + '/PPAlwc.css').then(() => {
                console.log('loaded successfully');
                this.CSSisLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_FIELD, STATUS_FIELD, COMPANY_NAME_FIELD, COMPANYID, NAT_ACT_FIELD, RA_IMPROVEMENT_FIELD, HASPERMISSION] })
    wiredRecord({ error, data }) {
        if (data) {
            this.record = data;
            this.recordTypeName = getFieldValue(this.record, RECORD_TYPE_FIELD);
            this.recordStatus = getFieldValue(this.record, STATUS_FIELD);
            this.companyName = getFieldValue(this.record, COMPANY_NAME_FIELD);
            this.companyId = getFieldValue(this.record, COMPANYID);
            this.hasEditPermission = getFieldValue(this.record, HASPERMISSION);
            this.priceListRAImprovement = getFieldValue(this.record, RA_IMPROVEMENT_FIELD).toFixed(2);
            this.raImprovePct = this.priceListRAImprovement;
            this.showNationalAccFields = getFieldValue(this.record, NAT_ACT_FIELD) && 
                                        (this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied' || 
                                        this.recordTypeName == 'PPA_Extension' || this.recordTypeName == 'PPA_Extension_Denied') ;

             // PPA Phase 2 
             // Execution of wire methods not guaranteed, check if wiredCatclass executed first, 
             // then calculate the RA Improvement based on records displayed.
            if(this.allRecords.length > 0){
                this.calculateRAImprovePct();
            }


            if (this.recordTypeName == 'PPA_Renewal') {
                if(this.recordStatus == 'Draft') {
                    if(this.hasEditPermission) {
                        this.colDisplay = this.col2;
                        this.showActionButtons = true;
                        this.showEditButton = true;
                        this.showAdditionalCols = true;
                        this.showEditableCols = true;
                        this.catClassDatatableClass = 'fixedHeader record-container datatable-zoom';
                        this.top10datatableClass = 'datatable-zoom';
                    }
                    else {
                        this.colDisplay = this.col3;
                        this.showActionButtons = false;
                        this.showEditButton = false;
                        this.showAdditionalCols = true;
                        this.showEditableCols = false;    
                    }
                }
                else {
                    this.colDisplay = this.col3;
                    this.showActionButtons = false;
                    this.showEditButton = false;
                    this.showAdditionalCols = true;
                    this.showEditableCols = false;    
                }
                
                this.sortOptions = this.sortOptions1;
            }
            else {
                this.colDisplay = this.col1;
                this.showActionButtons = false;
                this.sortOptions = this.sortOptions2;
                this.showEditButton = false;
                this.showAdditionalCols = false;
                this.showEditableCols = false;
            }
 
            this.error = null;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(fetchRentalCatClass, { priceListId: '$recordId' })
    wiredCatclass(result) {
        this.dataToRefresh = result;
        this.mapData = [];
        this.initialSuperCats = [];       

        if (result.data) {
            this.fetchedCatClasses = result.data;

            //PPA Phase 2 -- start
            this.allRecords = this.fetchedCatClasses.map(item => {
                return {
                    ...item, notMonthOnly: true, monthOnly: false,
                                  Number_Of_Days__c : this.numberOfDays, 
                                  Number_Of_Weeks__c : this.numberOfWeeks};
            });

            Object.preventExtensions(this.allRecords);

            if(this.monthOnlyValues.length > 0){
                for(var j =0; j < this.monthOnlyValues.length; j++ ){
                    this.allRecords.forEach(element => {
                        if(element.PPA_CatClassOwner__c && this.monthOnlyValues[j].MasterLabel.toLowerCase() === element.PPA_CatClassOwner__c.toLowerCase()){
                            element.notMonthOnly = false;
                            element.monthOnly = true;
                            element.Number_Of_Days__c = this.monthOnlyValues[j].Number_Of_Days__c;
                            element.Number_Of_Weeks__c = this.monthOnlyValues[j].Number_Of_Weeks__c;
                        }
                    });
                }               
            }
            //PPA Phase 2 -- End

            //Count the number of catClass product
            this.productCount = this.allRecords.length;

            //Top 10 rental revenue records
            let filteredRecords = this.allRecords.filter((record) => !isNaN(record.PPA_Rental_Revenue__c));
            filteredRecords = filteredRecords.filter((record) => record.PPA_Rental_Revenue__c > 0);
            filteredRecords = filteredRecords.slice().sort((a,b) => b.PPA_Rental_Revenue__c - a.PPA_Rental_Revenue__c);
            this.top10Records = filteredRecords.slice(0,10);

            if(this.showtop10Records) {
                this.displayCount = this.top10Records.length;
            }
            else {
                if(this.filterApplied) {
                    this.handleApplyFilter('reApply');
                }
                else {
                    this.mapData = this.convertRecsToMap(this.allRecords);
                    this.displayCount = this.productCount;
                }    
            }

            //To calculate Top 10 Products Percentage.
            const top10Sum = this.top10Records.reduce((acc, record) => acc + parseFloat(record.PPA_Rental_Revenue__c, 0),0);
            const totalSum = filteredRecords.reduce((acc, record) => acc + parseFloat(record.PPA_Rental_Revenue__c, 0),0);

            const percentage = Number(((top10Sum/totalSum)*100).toFixed(2));
            this.percentageValue = percentage;
            
            // PPA Phase 2
            this.calculateRAImprovePct();
            
            if(this.reBuildOnLoad) {
                this.activeSections = this.superCats;
            }

            this.error = null;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    genRevenueTotal(revenue) {
        outputRev = 0;

        if(!isNaN(revenue)) {
            outputRev = parseFloat(revenue, 0);
        }

        return outputRev;
    }

    convertRecsToMap(records) {
        var tmpSCList = [];
        var tmpRecs = [];
        var returnMap = [];

        for(var i=0;i<records.length;i++) {
            if(!tmpSCList.includes(records[i].PPA_Super_Cat__c)) {
                tmpSCList.push(records[i].PPA_Super_Cat__c);
            }
        }

        this.superCats = tmpSCList.sort();

        for(var j=0;j<tmpSCList.length;j++) {
            tmpRecs = records.filter((record) => record.PPA_Super_Cat__c === tmpSCList[j]);
            returnMap.push({key: tmpSCList[j], value: tmpRecs});
        }

        return returnMap;
    }
    
    toggleTop10(event){
        if(event.target.checked){
            this.showtop10Records = true;
            this.displayPercentage = this.percentageValue;
            this.displayCount = this.top10Records.length;
            
            // PPA Phase 2
            this.calculateRAImprovePct();
        }

        if (!event.target.checked) {
            this.reBuildOnLoad = true;
            this.showtop10Records = false;
            this.displayPercentage = '';
            this.sortFilter = null;
            this.selectedFilter = null;
            this.clearFilter();
        }

        this.isSelectAllChecked = false;
    }

    async handleAddCatClass() {
        const result = await addCatClass.open({
            size: 'large',
            description: 'This is to open the Add CatClass Modal',
            recordId: this.recordId,
            companyId: this.companyId,
       });

        if(result == 'OK') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records added successfully',
                    variant: 'success'
                })
            );
            
            this.clearSelectedRows();
            await refreshApex(this.dataToRefresh);
        }
    }

    getSelectedRows(type) {
        var selectedRows = [];
        var dtArray = this.template.querySelectorAll('lightning-datatable');

        for(var i=0;i<dtArray.length;i++) {
            var tmpRecs = dtArray[i].getSelectedRows();
            for(var j=0;j<tmpRecs.length;j++) {
                if(type == 'Delete' || (type == 'MassEdit' && !tmpRecs[j].PPA_CatClass_Added__c)) {
                    selectedRows.push(tmpRecs[j].Id);
                }
            }
        }

        return selectedRows;
    }

    async handleMassEdit() {
        var selectedRows = this.getSelectedRows('MassEdit');

        if(selectedRows.length > 0) {
            const result = await massEditModal.open({
                size: 'small',
                description: 'This is to open the Mass Edit Modal',
                recordId: this.recordId,
                allRecords: this.allRecords,
                selectedRows: selectedRows
            });

            if(result == 'OK') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );

                this.clearSelectedRows();
                await refreshApex(this.dataToRefresh);
            }
        }
    }
    
    async handleMassDelete() {
        var selectedRows = this.getSelectedRows('Delete');

        if(selectedRows.length > 0) {
            const result = await deleteModal.open({
                size: 'small',
                description: 'This is a delete confirmation modal',
                modalHeader: 'Delete Cat-Class',
                modalBody: 'Are you sure you want to delete the selected Cat-Class records?'
            });
    
            if(result == 'OK') {
                this.showSpinner = true;
                deleteSelectedRecords({ recordIds: selectedRows })
                    .then((result) => {
                        this.showSpinner = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Record deleted successfully',
                                variant: 'success'
                            })
                        );    
    
                        this.clearSelectedRows();
                        getRecordNotifyChange([{ recordId: this.recordId }]);               
                        refreshApex(this.dataToRefresh);               
                    })
                    .catch((error) => {
                        this.showSpinner = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error'
                            })
                        );        
                    });
            }    
        }
    }

    handleFilterSelection(event){
        this.selectedFilter = event.detail.value;
        /* PPA Phase 2: DP-1025
        Added PPA_Top_X_Rentals__c and inputType as part of PPA Phase-2 */
        if (this.selectedFilter === "PPA_Product_Name__c" || this.selectedFilter === "PPA_CatClassOwner__c" || this.selectedFilter === "PPA_CatClass__c"){
            this.showCheckbox = false;
            this.inputType = 'text';
        }
        else if (this.selectedFilter === "PPA_Top_X_Rentals__c") {
            this.showCheckbox = false;
            this.inputType = 'number';
        }
        else if(this.selectedFilter === "None" ){
            this.selectedFilter = null;
            this.showCheckbox = false;
            this.keyword ='';
            this.clearFilter(); 
        }
        else {
            this.showCheckbox = true;
            this.keyword ='';
        }
    }

    handleKeyword(event){
        this.keyword = event.target.value;        
    }
    
    handleCheckbox(event){
        this.isChecked = event.target.checked;
        this.showInputField = false;
    }
    
    handleApplyFilter(type) {
        if(type == 'reApply') {
            this.reBuildOnLoad = false;
        }
        else {
            this.reBuildOnLoad = true;
        }

        if(this.selectedFilter != null) {
            if(this.showCheckbox == false) {
                if(this.keyword) {
                    this.applyFilter('keyword');
                }
            }
            else {
                if(this.isChecked) {
                    this.applyFilter('true');
                }
                else {
                    this.applyFilter('false');
                }
            }
        }       
    };

    applyFilter(type) {
        switch(type) {
            case 'keyword':
                if(this.selectedFilter == 'PPA_CatClassOwner__c') {
                    this.filteredData = this.allRecords.filter((record) => {
                        if(record.PPA_CatClassOwner__c) {
                            return record.PPA_CatClassOwner__c.toLowerCase().includes(this.keyword.toLowerCase());
                        }
                    });
                }
                /* PPA Phase 2: DP-1025
                Added Top X Rentals filter logic */
                else if (this.selectedFilter == 'PPA_Top_X_Rentals__c') {
                    this.isXNum = !isNaN(parseInt(this.keyword));
                    if(this.isXNum) {
                        //Top 10 rental revenue records
                        let filteredRecords = this.allRecords.filter((record) => !isNaN(record.PPA_Rental_Revenue__c));
                        filteredRecords = filteredRecords.filter((record) => record.PPA_Rental_Revenue__c > 0);
                        filteredRecords = filteredRecords.slice().sort((a, b) => b.PPA_Rental_Revenue__c - a.PPA_Rental_Revenue__c);
                        this.filteredData = filteredRecords.slice(0, parseInt(this.keyword));
                    }
                }
                else {
                    this.filteredData = this.allRecords.filter((record) => record[this.selectedFilter].toLowerCase().includes(this.keyword.toLowerCase()));
                }
                break;

            case 'true':
                this.filteredData = this.allRecords.filter((record) => record[this.selectedFilter] == true);
                break;

            default:
                this.filteredData = this.allRecords.filter((record) => record[this.selectedFilter] == false);
        }

        this.displayCount = this.filteredData.length;

        if(this.sortFilter == null) {
            this.mapData = this.convertRecsToMap(this.filteredData);
        }
        else {
            this.sortData();
        }

        this.filterApplied = true;

        // PPA Phase 2
        //call after filter is applied.
        this.calculateRAImprovePct();

        if(this.reBuildOnLoad) {
            setTimeout(() => {
                this.activeSections = this.superCats;
                this.clearSelectedRows();
            }, "500");    
        }

        this.isSelectAllChecked = false;
    }

    clearFilter(){
        this.filteredData = [];
        this.keyword = '';
        this.filterApplied = false;
        this.isSelectAllChecked = false;
        this.calculateRAImprovePct();

        this.displayCount = this.allRecords.length;

        if(this.sortFilter == null) {
            this.mapData = this.convertRecsToMap(this.allRecords);
        }
        else {
            this.sortData();
        }

        this.showCheckbox = false;

        setTimeout(() => {
            this.activeSections = this.superCats;
            this.clearSelectedRows();
        }, "500");
    }

 
    handleSorting(event){
        this.sortFilter = event.detail.value;
        this.sortDirection = 'asc';
        this.showUpButton = false;
        if(this.sortFilter == 'None') {
            this.sortFilter = null;
            if(this.filteredData.length > 0) {
                this.mapData = this.convertRecsToMap(this.filteredData);
            }
            else {
                this.mapData = this.convertRecsToMap(this.allRecords);
            }
        }
        else {
            this.sortData();
        }
    }

    handleAscendingSorting(){
         this.sortDirection = 'asc';
         this.showUpButton= false;
         this.sortData();
    }

    handleDescendingSorting(){
         this.sortDirection = 'desc';
         this.showUpButton= true;
         this.sortData();
    }

    sortData(){
        const sortField = this.sortFilter;
        let sortedRecords;

        if(this.filterApplied) {
            sortedRecords = this.filteredData;
        }
        else {
            sortedRecords = this.allRecords;
        }

        if (this.sortDirection === 'asc'){
            sortedRecords = sortedRecords.slice().sort((a,b) => (a[sortField] > b[sortField]) ? 1 : -1);
        }
        else if (this.sortDirection === 'desc'){
            sortedRecords = sortedRecords.slice().sort((a,b) => (a[sortField] < b[sortField]) ? 1 : -1);
        }

        this.sortedRecords = sortedRecords;
        this.mapData = this.convertRecsToMap(this.sortedRecords);
    }
    
    handleRowAction(event) {
        const record = event.detail.row;
        const actionName = event.detail.action.name;

        if(actionName == 'view') {
            this.viewDetails(record.Id);
        }
    }

    async viewDetails(recordId) {
        const result = await detailsModal.open({
            size: 'large',
            description: 'This is to view record details',
            objectName: 'PPA_Rental_CatClass__c',
            recordId: recordId,
            layout: 'Full'
        });
    }

    handleCancelAll() {
        var dtArray = this.template.querySelectorAll("lightning-datatable");
        
        for(var i=0;i<dtArray.length;i++) {
            dtArray[i].draftValues = [];
        }        
    }

    handleSaveAll() {
        var updatedRows = [];
        var dtArray = this.template.querySelectorAll('lightning-datatable');

        for(var i=0;i<dtArray.length;i++) {
            var tmpRecs = dtArray[i].draftValues;

            for(var j=0;j<tmpRecs.length;j++) {
                updatedRows.push(tmpRecs[j]);
            }
        }

        if(updatedRows.length > 0) {
            this.saveAllUpdatedRows(updatedRows, true);
        }
    }

    handleSave(event) {
        this.saveAllUpdatedRows(event.detail.draftValues, false);
    }

    async saveAllUpdatedRows(updatedRows, allRows) {
        this.okToProcess = true;
        let draftValueIds = [];
        let updatedRowIds = [];

        for(var i=0;i<updatedRows.length;i++) {
            updatedRowIds.push(updatedRows[i].Id);            
        }

        const records = updatedRows.slice().map((draftValue) => {
            draftValue.PPA_UpdatedBy_Mass_Edit__c = false;

            // PPA Phase 2
            this.handleMonthOnly(draftValue);

            const fields = Object.assign({}, draftValue);

            if (
                (draftValue.PPA_New_Day__c == '' || draftValue.PPA_New_Day__c < 0) ||
                (draftValue.PPA_New_Week__c == '' || draftValue.PPA_New_Week__c < 0) ||
                (draftValue.PPA_New_Month__c == '' || draftValue.PPA_New_Month__c < 0))
            {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'All values must be greater than or equal to zero',
                        variant: 'error'
                    })
                );

                this.okToProcess = false;
            }
            
            return { fields };
        });

        try {
            if(this.okToProcess) {
                this.showSpinner = true;

                const recordUpdatePromises = records.map((record) => 
                    updateRecord(record)
                );
                await Promise.all(recordUpdatePromises);

                this.showSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        variant: 'success'
                    })
                );

                var dtArray = this.template.querySelectorAll("lightning-datatable");
                for(var i=0;i<dtArray.length;i++) {
                    draftValueIds = [];
                    for(var j=0;j<dtArray[i].draftValues.length;j++) {
                        draftValueIds.push(dtArray[i].draftValues[j].Id);
                    }

                    if(allRows || (JSON.stringify(draftValueIds) == JSON.stringify(updatedRowIds))) {
                        dtArray[i].draftValues = [];
                    }
                }

                this.reBuildOnLoad = false;
                await refreshApex(this.dataToRefresh);
            }
        }
        catch(error) {
            this.showSpinner = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating records',
                    message: 'A value must be supplied for New Day, New Week and New Month',
                    variant: 'error'
                })
            );
        }
    }

    // Added as part of PPA Phase 2
    handleMonthOnly(draftValue){
        if(this.allRecords.some((item) => (item.Id === draftValue.Id && item.notMonthOnly == false))){
            const catClassMonthOnly = this.allRecords.find((item) => (item.Id === draftValue.Id && item.notMonthOnly == false));
            draftValue.PPA_New_Day__c = (draftValue.PPA_New_Month__c / catClassMonthOnly.Number_Of_Days__c).toFixed(2);
            draftValue.PPA_New_Week__c = (draftValue.PPA_New_Month__c / catClassMonthOnly.Number_Of_Weeks__c).toFixed(2);
        }
    }

    
    // PPA Phase 2 - calculate RA improvement for records displayed.
    calculateRAImprovePct() {
        if(this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied' ||
           this.recordTypeName == 'PPA_Extension' || this.recordTypeName == 'PPA_Extension_Denied' ){
            
            let raRecords = [];                    
            if(this.showtop10Records == true){
                raRecords = this.top10Records;
            }
            else if(this.filterApplied == true){
                raRecords = this.filteredData;
            }
            else{
                raRecords = this.allRecords;
            }
            
            if(this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied'){           
                this.calculateRA(raRecords, 'standard');   
            }
            if(this.showNationalAccFields){
                this.calculateRA(raRecords, 'nonStrategic');
                this.calculateRA(raRecords, 'strategic');
                this.calculateRA(raRecords, 'national');  
            }
        }      
    }

    calculateRA(raRecords, raType){
        let dayCalc;
        let weekCalc;
        let monthCalc;
        let dayCalcChg;
        let weekCalcChg;
        let monthCalcChg;
        let raNumerator = 0.00;
        let raDenominator = 0.00;
        let raImpPct = 0.00;

        if (raRecords.length > 0) {

            let dayField;
            let weekField;
            let monthField;

            if(raType == 'standard'){
                dayField = fieldAPINames.standardDay;
                weekField = fieldAPINames.standardWeek;
                monthField = fieldAPINames.standardMonth;
            }
            else if (raType == 'nonStrategic'){
                dayField = fieldAPINames.nonStrategicDay;
                weekField = fieldAPINames.nonStrategicWeek;
                monthField = fieldAPINames.nonStrategicMonth;
            }
            else if (raType == 'strategic'){
                dayField = fieldAPINames.strategicDay;
                weekField = fieldAPINames.strategicWeek;
                monthField = fieldAPINames.strategicMonth;
            }
            else if(raType == 'national'){
                dayField = fieldAPINames.nationalDay;
                weekField = fieldAPINames.nationalWeek;
                monthField = fieldAPINames.nationalMonth;
            }

            for (var i = 0; i < raRecords.length; i++) {
                dayCalc = 0;
                weekCalc = 0;
                monthCalc = 0;
                dayCalcChg = 0;
                weekCalcChg = 0;
                monthCalcChg = 0;
        
                if (!isNaN(raRecords[i][monthField]) && !isNaN(raRecords[i].PPA_Month_Rental__c)) {
                    if(raType == 'standard'){
                        if(!isNaN(!raRecords[i].PPA_Old_Month__c) && raRecords[i].PPA_Old_Month__c > 0){
                            monthCalcChg = (raRecords[i][monthField] - raRecords[i].PPA_Old_Month__c) / raRecords[i].PPA_Old_Month__c;
                            monthCalc = Number(monthCalcChg * raRecords[i].PPA_Month_Rental__c);
                        }
                        else{
                            monthCalc = raRecords[i].PPA_RA_Improvement_Month_Calc__c;
                        }
                    }
                    else{
                        if(this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied'){
                            if(!isNaN(!raRecords[i].PPA_New_Month__c) && raRecords[i][monthField] > 0){
                                monthCalcChg = (raRecords[i].PPA_New_Month__c - raRecords[i][monthField]) / raRecords[i][monthField];
                            }
                        }
                        if(this.recordTypeName == 'PPA_Extension' || this.recordTypeName == 'PPA_Extension_Denied'){
                            if(!isNaN(!raRecords[i].PPA_Old_Month__c) && raRecords[i][monthField] > 0){
                                monthCalcChg = (raRecords[i].PPA_Old_Month__c - raRecords[i][monthField]) / raRecords[i][monthField];
                            }
                        }
                        monthCalc = Number(monthCalcChg * raRecords[i].PPA_Month_Rental__c);
                    }
                } 
                else {
                    if(raType == 'standard'){
                        monthCalc = raRecords[i].PPA_RA_Improvement_Month_Calc__c;
                    }
                }

                if (!isNaN(raRecords[i][weekField]) && !isNaN(raRecords[i].PPA_Week_Rental__c)) {  
                    if(raType == 'standard'){
                        if(!isNaN(!raRecords[i].PPA_Old_Week__c) && raRecords[i].PPA_Old_Week__c > 0){
                            weekCalcChg = (raRecords[i][weekField] - raRecords[i].PPA_Old_Week__c) / raRecords[i].PPA_Old_Week__c;
                            weekCalc = Number(weekCalcChg * raRecords[i].PPA_Week_Rental__c);
                        }
                        else{
                            weekCalc = Number(weekCalcChg * raRecords[i].PPA_Week_Rental__c);
                        }
                    }
                    else{                        
                        if(this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied'){
                            if(!isNaN(!raRecords[i].PPA_New_Week__c) && raRecords[i][weekField] > 0){
                                weekCalcChg = (raRecords[i].PPA_New_Week__c - raRecords[i][weekField]) / raRecords[i][weekField];
                            }
                        }
                        if(this.recordTypeName == 'PPA_Extension' || this.recordTypeName == 'PPA_Extension_Denied'){
                            if(!isNaN(!raRecords[i].PPA_Old_Week__c) && raRecords[i][weekField] > 0){
                                weekCalcChg = (raRecords[i].PPA_Old_Week__c - raRecords[i][weekField]) / raRecords[i][weekField];
                            }
                        }
                        weekCalc = Number(weekCalcChg * raRecords[i].PPA_Week_Rental__c);
                    }
                } 
                else {
                    if(raType == 'standard'){
                        weekCalc = raRecords[i].PPA_RA_Improvement_Week_Calc__c;
                    }
                }

                if (!isNaN(!raRecords[i].PPA_Old_Day__c) && !isNaN(raRecords[i][dayField]) && !isNaN(raRecords[i].PPA_Day_Rental__c)) {  
                    if(raType == 'standard'){
                        if(!isNaN(!raRecords[i].PPA_Old_Day__c) && raRecords[i].PPA_Old_Day__c > 0){
                            dayCalcChg = (raRecords[i][dayField] - raRecords[i].PPA_Old_Day__c) / raRecords[i].PPA_Old_Day__c;
                            dayCalc = Number(dayCalcChg * raRecords[i].PPA_Day_Rental__c);
                        }
                        else{
                            dayCalc = raRecords[i].PPA_RA_Improvement_Day_Calc__c;
                        }
                    }
                    else{                        
                        if(this.recordTypeName == 'PPA_Renewal' || this.recordTypeName == 'PPA_Renewal_Denied'){
                            if(!isNaN(!raRecords[i].PPA_New_Day__c) && raRecords[i][dayField] > 0){
                                dayCalcChg = (raRecords[i].PPA_New_Day__c - raRecords[i][dayField]) / raRecords[i][dayField];
                            }
                        }
                        if(this.recordTypeName == 'PPA_Extension' || this.recordTypeName == 'PPA_Extension_Denied'){
                            if(!isNaN(!raRecords[i].PPA_Old_Day__c) && raRecords[i][dayField] > 0){
                                dayCalcChg = (raRecords[i].PPA_Old_Day__c - raRecords[i][dayField]) / raRecords[i][dayField];
                            }
                        }
                        dayCalc = Number(dayCalcChg * raRecords[i].PPA_Day_Rental__c);
                    }
                } 
                else {
                    if(raType == 'standard'){
                        dayCalc = raRecords[i].PPA_RA_Improvement_Day_Calc__c;
                    }
                }

                raNumerator = raNumerator + monthCalc + weekCalc + dayCalc;  
                raDenominator = raDenominator + raRecords[i].PPA_RA_Improvement_Denominator_Calc__c;
            }

            if (raDenominator > 0) {
                raImpPct = (raNumerator / raDenominator) * 100;
            } else {
                raImpPct = 0.00;
            }    
        }
        else{
            if(this.filterApplied || this.showtop10Records){
                raImpPct = 0.00;
            }
        }
        
        if(raType == 'standard'){
            this.raImprovePct = raImpPct.toFixed(2);
        }
        else if (raType == 'nonStrategic'){
            this.nonStrategicAccountRAImprovePct = raImpPct.toFixed(2);
        }
        else if (raType == 'strategic'){
            this.strategicAccountRAImprovePct = raImpPct.toFixed(2);
        }
        else if(raType == 'national'){
            this.nationalAccountRAImprovePct = raImpPct.toFixed(2);
        }
    }

    handleSelectAll() {
        if(this.isSelectAllChecked) {
            this.clearSelectedRows();
            this.isSelectAllChecked = false;
        }
        else {
            this.isSelectAllChecked = true;

            var dtArray = this.template.querySelectorAll('lightning-datatable');
            var selectedRows = [];
    
            for(var k=0;k<this.allRecords.length;k++) {
                selectedRows.push(this.allRecords[k].Id);
            }
    
            for(var i=0;i<dtArray.length;i++) {
                dtArray[i].selectedRows = selectedRows;
            }    
        }
    }

    clearSelectedRows() {
        this.isSelectAllChecked = false;
        
        var dtArray = this.template.querySelectorAll('lightning-datatable');
        for(var i=0;i<dtArray.length;i++) {        
            dtArray[i].selectedRows = [];
        }
    }

    //Inline editing changes
    handleNewDayChange(event) {
        this.showSaveButton = true;
        this.showCancelButton = true;
        const fieldName = event.currentTarget.dataset.id;
        const recordId = event.currentTarget.dataset.recordid;
        const currVal = event.detail.value;
        var newMap = {};
        var finalRecs = [];

        //update class
        if (!event.currentTarget.className.includes('changedInput')) {
            event.currentTarget.className = event.currentTarget.className + ' changedInput';
        }

        if (parseFloat(currVal) < 0 || isNaN(parseFloat(currVal))) {
            if (this.errMsgList.find(x => x.Id === recordId) == undefined) {
                let err = {
                    "Id": recordId,
                    "ErrMsg": 'All values must be greater than or equal to zero.'
                }
                this.errMsgList.push(err);
            }
        }
        else {
            if (this.errMsgList.find(x => x.Id === recordId) != undefined && this.errMsgList.find(x => x.Id === recordId).Id == recordId) {
                const index = this.errMsgList.findIndex(e => e.Id === recordId);
                if (index >= 0) {
                    this.errMsgList.splice(index, 1);
                }
            }
            if (Object.keys(this.finalRows).includes(recordId)) {
                let recFound = this.finalRows[recordId];
                recFound.PPA_New_Day__c = currVal;
            }
            else {
                newMap[fieldName] = currVal;
                newMap['Id'] = String(recordId);
                this.finalRows[recordId] = newMap;
                finalRecs.push(this.finalRows);
                this.finalRowsList = finalRecs;
            }
        }
    }
    handleNewWeekChange(event) {
        this.showSaveButton = true;
        this.showCancelButton = true;
        const fieldName = event.currentTarget.dataset.id;
        const recordId = event.currentTarget.dataset.recordid;
        const currVal = event.detail.value;
        var newMap = {};
        var finalRecs = [];

        //update class
        if (!event.currentTarget.className.includes('changedInput')) {
            event.currentTarget.className = event.currentTarget.className + ' changedInput';
        }

        if (parseFloat(currVal) < 0 || isNaN(parseFloat(currVal))) {
            if (this.errMsgList.find(x => x.Id === recordId) == undefined) {
                let err = {
                    "Id": recordId,
                    "ErrMsg": 'All values must be greater than or equal to zero.'
                }
                this.errMsgList.push(err);
            }
        }
        else {
            if (this.errMsgList.find(x => x.Id === recordId) != undefined && this.errMsgList.find(x => x.Id === recordId).Id == recordId) {
                const index = this.errMsgList.findIndex(e => e.Id === recordId);
                if (index >= 0) {
                    this.errMsgList.splice(index, 1);
                }
            }
            if (Object.keys(this.finalRows).includes(recordId)) {
                let recFound = this.finalRows[recordId];
                recFound.PPA_New_Week__c = currVal;
            }
            else {
                newMap[fieldName] = currVal;
                newMap['Id'] = String(recordId);
                this.finalRows[recordId] = newMap;
                finalRecs.push(this.finalRows);
                this.finalRowsList = finalRecs;
            }
        }
    }
    handleNewMonthChange(event) {
        this.showSaveButton = true;
        this.showCancelButton = true;
        const fieldName = event.currentTarget.dataset.id;
        const recordId = event.currentTarget.dataset.recordid;
        const monthOnly = event.currentTarget.dataset.monthonly;
        const newdays = event.currentTarget.dataset.newdays;
        const newweeks = event.currentTarget.dataset.newweeks;
        const currVal = event.detail.value;
        var newMap = {};
        var finalRecs = [];

        //update class
        if (!event.currentTarget.className.includes('changedInput')) {
            event.currentTarget.className = event.currentTarget.className + ' changedInput';
        }

        if (parseFloat(currVal) < 0 || isNaN(parseFloat(currVal))) {
            if (this.errMsgList.find(x => x.Id === recordId) == undefined) {
                let err = {
                    "Id": recordId,
                    "ErrMsg": 'All values must be greater than or equal to zero.'
                }
                this.errMsgList.push(err);
            }
        }
        else {
            if (this.errMsgList.find(x => x.Id === recordId) != undefined && this.errMsgList.find(x => x.Id === recordId).Id == recordId) {
                const index = this.errMsgList.findIndex(e => e.Id === recordId);
                if (index >= 0) {
                    this.errMsgList.splice(index, 1);
                }
            }
            if (Object.keys(this.finalRows).includes(recordId)) {
                let recFound = this.finalRows[recordId];
                recFound.PPA_New_Month__c = currVal;
                if (monthOnly != undefined && monthOnly === "true") {
                    let newDay = (currVal / newdays).toFixed(2);
                    let newWeek = ((currVal / newweeks)).toFixed(2);
                    //Check condition for week error
                    if (parseFloat((currVal / 4).toFixed(2)) * 4 < currVal) {
                        newWeek = ((currVal / newweeks) + 0.01).toFixed(2); // To avoid week error, add a penny.
                    }
                    recFound.PPA_New_Day__c = newDay;
                    recFound.PPA_New_Week__c = newWeek;
                }
            }
            else {
                if (monthOnly != undefined && monthOnly === "true") {
                    let newDay = (currVal / newdays).toFixed(2);
                    let newWeek = ((currVal / newweeks)).toFixed(2);
                    //Check condition for week error
                    if (parseFloat((currVal / 4).toFixed(2)) * 4 < currVal) {
                        newWeek = ((currVal / newweeks) + 0.01).toFixed(2); // To avoid week error, add a penny.
                    }
                    newMap['PPA_New_Day__c'] = newDay;
                    newMap['PPA_New_Week__c'] = newWeek;
                }
                newMap[fieldName] = currVal;
                newMap['Id'] = String(recordId);
                this.finalRows[recordId] = newMap;
                finalRecs.push(this.finalRows);
                this.finalRowsList = finalRecs;
            }
        }
    }
    handleEdit() {
        if(this.showtop10Records) {
            this.IsActive = true;
            this.top10EditClicked = true;
        }
        else {
            this.IsActive = false;
            this.editClicked = true;
        }
        this.showRevertButton = true;
        this.showEditButton = false;
        this.showActionButtons = false;
        this.showUpButton = false;
        this.showTop10Toggle = false;
    }
    handleCancel() {
        this.showCancelButton = false;
        this.showRevertButton = false;
        this.showSaveButton = false;
        this.showEditButton = true;
        this.showActionButtons = true;
        this.showUpButton = true;
        this.showTop10Toggle = true;
        if (this.showtop10Records) {
            this.IsActive = true;
            this.top10EditClicked = false;
        }
        else {
            this.IsActive = false;
            this.editClicked = false;
        }
    }
    async handleSaveRecords() {
        this.showSpinner = true;
        //Check default errors
        const allValid = [
            ...this.template.querySelectorAll("lightning-input[class*='changedInput']")]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        //Check custom errors
        if (this.errMsgList.length > 0) {
            const key = 'ErrMsg';
            var array = this.errMsgList;
            const uniqVals = [
                ...array
                    .reduce((uniq, curr) => {
                        if (!uniq.has(curr[key])) {
                            uniq.set(curr[key], curr);
                        }
                        return uniq;
                    }, new Map())
                    .values()
            ];
            uniqVals.forEach(x =>
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error updating records',
                    message: x.ErrMsg,
                    variant: 'error'
                }))
            );
        }
        else if (!allValid) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error updating records',
                message: 'All values must be greater than or equal to zero.',
                variant: 'error'
            }));
        }
        else if (this.finalRowsList.length > 0) {
            let paramVal = JSON.stringify(this.finalRowsList);
            this.editClicked = false;
            this.showEditButton = false;
            this.showCancelButton = false;
            this.showSaveButton = false;
            /* Call apex class to update records
            Show success/failure toast message
            Refresh records */
            updateRecords({ paramVal: paramVal })
                .then(result => {
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Records updated successfully',
                        //message: result,
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                    refreshApex(this.dataToRefresh);
                    refreshApex(this.allRecords);
                    refreshApex(this.mapData);
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                })
                .catch(error => {
                    console.log('--error--' + JSON.stringify(error));
                    console.log(error);
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating records. Please Contact your System Administrator',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                    refreshApex(this.dataToRefresh);
                    refreshApex(this.allRecords);
                    refreshApex(this.mapData);
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                });
            this.showCancelButton = false;
            this.showRevertButton = false;
            this.showSaveButton = false;
            this.showEditButton = true;
            this.showActionButtons = true;
            this.showUpButton = true;
            this.showTop10Toggle = true;
            if (this.showtop10Records) {
                this.IsActive = true;
                this.top10EditClicked = false;
            }
            else {
                this.IsActive = false;
                this.editClicked = false;
            }
            this.finalRows = {};
            this.finalRowsList = [];
        }
        this.showSpinner = false;
    }
}