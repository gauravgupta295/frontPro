import { LightningElement, wire, api } from 'lwc';
import getItemSearchColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
import fetchAssetData from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredProductsForAssetInquiry';
import {subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext, publish} from 'lightning/messageService';

export default class Sbr_3_0_assetListCmp extends LightningElement {
    
    @api listHeight;
    data = [];
    columns = [];
    showTable = false;

    @wire(MessageContext)
    messageContext;

    assetRowsOffset = 0;
    batchSize = 50;
    queryParams = '';
    searchKey = '';
    appliedFilters = {
        'Super_Category__c' : ''
    };
    selectedCategories = [];
    selectedSubCategories = [];

    @api searchAssetList(searchKey){
        this.assetRowsOffset = 0;
        this.searchKey = searchKey;
        this.getAssetData(this.assetRowsOffset, false);
    }

    @api filterAssetList(selectedFilter){
        this.assetRowsOffset = 0;
        switch(selectedFilter.filterType){
            case 'Super_Category__c':
                this.appliedFilters.Super_Category__c = selectedFilter.filterValue == 'All Items' ? '' : selectedFilter.filterValue;
                break;
            default:
                this.appliedFilters.Super_Category__c = '';
                break;
        }

        this.selectedCategories = selectedFilter.selectedCategories;
        this.selectedSubCategories = selectedFilter.selectedSubCategories;

        this.getAssetData(this.assetRowsOffset, false);
    }

    @wire(getItemSearchColumns)
    itemSearchColumns({error, data }) {
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
                this.columns.push(colItem);
                this.queryParams+= col.Field_Name__c + ',';
            });
            this.showTable = true;
            this.getAssetData(this.assetRowsOffset, false);
        }else if(error) {
            console.log(error);
        }
    }

    loadMoreItems(event){
        let datatableTarget = event.target;
        datatableTarget.isLoading = true;
        this.getAssetData(this.assetRowsOffset, true);
    }

    getAssetData(offset, isLoadingMoreItems){
        let whereClause = '';
        let selCats = this.selectedCategories;
        let selSubCats = this.selectedSubCategories;
        
        let filterKeyPrefix = 'Product2';
        for(let key in this.appliedFilters){
            if(this.appliedFilters[key]){
                let keyWithPrefix = filterKeyPrefix + '.' + key;
                whereClause = `${whereClause} AND ${keyWithPrefix} = '${this.appliedFilters[key]}'`;
            }
        }

        let catWhereClause = selCats.length === 0 ? "" : "Product2.Product_Category_Txt__c IN ('" + selCats.join("','") + "')";
        let subcatWhereClause = selSubCats.length === 0 ? "" : "Product2.Product_Sub_Category_Txt__c IN ('" + selSubCats.join("','") + "')";
        // needs to be AND ( OR )
        if (selCats.length > 0 && selSubCats.length > 0) whereClause = whereClause + " AND (" + catWhereClause  + " OR " + subcatWhereClause + ")";
        if (selCats.length > 0 && selSubCats.length === 0) whereClause = whereClause + " AND " + catWhereClause;
        if (selCats.length === 0 && selSubCats.length > 0) whereClause = whereClause + " AND " + subcatWhereClause;
       
        console.log("======= getAssetData, catWhereClause: " + catWhereClause);
        console.log("======= getAssetData, subcatWhereClause: " + subcatWhereClause);
        console.log("======= getAssetData, where clause: " + whereClause);

        fetchAssetData({
            offset: offset,
            batchSize: 50,
            searchKey: this.searchKey,
            whereClause: whereClause
        })
        .then((data) => {
            if(data.length < this.batchSize) {
                this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').enableInfiniteLoading = false;
            }else{
                this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').enableInfiniteLoading = true;
            }

            let assetArr = [];
            for(var objIdx in data) { assetArr.push(this.flattenObject('', data[objIdx])); }

            if(isLoadingMoreItems){
                const currentData = this.data;
                const newData = currentData.concat(assetArr); 
                this.data = newData;
            }else{
                this.data = assetArr;
            }
            this.assetRowsOffset+=data.length;
            this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').isLoading = false;
            this.dispatchEvent(new CustomEvent('searchcomplete', {detail: this.assetRowsOffset}));
        })
        .catch((error) => {
            console.log(error);
        });
    }
    updateSelectedRows(event){
        let selectedRows = event.target.getSelectedRows();
        const selectedRowsEvent = new CustomEvent('assetselected', { detail: selectedRows , bubbles: true, composed: true}); 
        console.log('selectedRows'+selectedRowsEvent.detail);
      
        this.dispatchEvent(selectedRowsEvent);
    }

    get listHeightStyle(){
        return `height:${this.listHeight}px;`;
    }

    //sorting needs to be refactored
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    // Used to sort the 'Age' column
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

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    flattenObject = (pfx, obj) => {
        let flatObj = {};
        if(pfx != '') { pfx += '.'; }

        let objKeys = Object.keys(obj);
        for(var keyIdx in objKeys) {
            let key = objKeys[keyIdx];
            let objKeyVal = obj[key];
            if(typeof(objKeyVal) == 'object')
            { Object.assign(flatObj, this.flattenObject(pfx + key, objKeyVal)); }
            else
            { flatObj[pfx + key] = objKeyVal; }
        }

        return flatObj; 
    }
}