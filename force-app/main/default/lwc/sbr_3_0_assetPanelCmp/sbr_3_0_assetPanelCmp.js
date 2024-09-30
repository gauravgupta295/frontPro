import { LightningElement, wire, api } from 'lwc';
import getItemSearchColumns from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getItemSearchColumns';
import fetchActualAssetData from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getFilteredAssets';
import {subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext, publish} from 'lightning/messageService';


export default class Sbr_3_0_assetPanelCmp extends LightningElement {
    @api isMobile = false;
    @api spotlightHeight = '510';
    @api listHeight;

    panelTitle = 'Assets Panel';
    panelType = 'inactivePanel';

    get spotlightHeightStyle(){
        return `height:${this.spotlightHeight}px;`;
    }

    @wire(MessageContext)
    messageContext;
    
    data = [];
    columns = [];
    showTable = false;
    assetRowsOffset = 0;
    batchSize = 50;
    queryParams = '';
    searchKey = '';

    selectedProductSKU = [];
    currentLocationId = null;
    
    searchAssetList(event){
        this.assetRowsOffset = 0;
        this.searchKey = event.target.value;
        console.log('key' + this.searchKey);
        this.getActualAssetData(0, false);
    }

    @wire(getItemSearchColumns)
    itemSearchColumns({error, data }) {
        if(data) {
            let itemSearchCols = data.filter( col => col.Context__c == 'Asset Search');
            itemSearchCols.sort((a,b) => a.Order__c - b.Order__c);
            itemSearchCols.forEach( col => {
                let colItem = {};
                colItem.label = col.Label;
                colItem.fieldName = col.Field_Name__c;
                if(col.Type__c == 'url'){
                    colItem.fieldName = "LinkUrl";
                    colItem.typeAttributes = {
                        label: { fieldName :'Name' },
                        target: '_self'
                    }
                }
                colItem.hideDefaultActions = true;
                colItem.sortable = col.IsSortable__c;
                colItem.type = col.Type__c?col.Type__c:'text';
                colItem.wrapText = true;
                if(col.fixedWidth__c) colItem.fixedWidth = col.fixedWidth__c;
                //.columns.push(colItem);
                this.columns = [...this.columns, colItem];
                this.queryParams+= col.Field_Name__c + ',';

                console.log('this.data : '+JSON.stringify(this.data));
                console.log('this.columns : '+JSON.stringify(this.columns));
            });
            this.showTable = true;
        }else if(error) {
            console.log(error);
        }
    }

    @api assetSelectionPanelHandler(itemCount){
        let jsondata = JSON.parse(JSON.stringify(itemCount));

        this.selectedProductSKU = [];

        for (var i = 0; i < jsondata.length; i++) {
            this.selectedProductSKU.push(jsondata[i]['Product_SKU__c']);
        }
        
        console.log('assetSelectionPanelHandler ' + this.selectedProductSKU);
        this.getActualAssetData(0, false);0
    }

    @api locationSelectionPanelHandler(locrecord){
        if(locrecord) {
            console.log(JSON.parse(JSON.stringify(locrecord)));
            let jsondata = JSON.parse(JSON.stringify(locrecord));
            this.currentLocationId = jsondata['Id'];
            console.log('currentLocationId: '+this.currentLocationId);
            this.getActualAssetData(0, false);
        }else{
            this.currentLocationId = null;
            this.data = [];
        }
    }

    loadMoreItems(event){
        let datatableTarget = event.target;
        datatableTarget.isLoading = true;
        this.getActualAssetData(this.assetRowsOffset, true);
    }

    removeduplicates(data){
        return [...new Set(data)];
    }

    getActualAssetData(offset, isLoadingMoreItems){
        let whereClause = '';
        let selProductSKU = this.selectedProductSKU;
        let selProductSKUSet = [];

        if(selProductSKU.length>0){
            selProductSKUSet = this.removeduplicates(selProductSKU);
        }

        let selProductSKUClause = selProductSKU.length === 0 ? "" : "Product2.Product_SKU__c IN ('" + selProductSKUSet.join("','") + "')";

        let selLocationIdClause = this.currentLocationId === null ? "" : "SM_PS_Current_Location__c = '" +this.currentLocationId + "'";

        if(selLocationIdClause!='') {
            if(selProductSKUClause == ""){
                    whereClause = selLocationIdClause + ' AND Status != \'Deleted\' ';
                }else{
                    whereClause = selProductSKUClause + ' AND ' + selLocationIdClause + ' AND Status != \'Deleted\' ';
                }
                console.log("======= getActualAssetData, where clause: " + whereClause);
                
                fetchActualAssetData({
                    offset: offset,
                    batchSize: 50,
                    searchKey: this.searchKey,
                    whereClause: whereClause
                })
                .then((data) => {
                    console.log('Data Get : ' + data.length)
                    if(data.length < this.batchSize) {
                        this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').enableInfiniteLoading = false;
                    }else{
                        this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').enableInfiniteLoading = true;
                    }

                    //let assetArr = [];
                    //for(var objIdx in data) { assetArr.push(this.flattenObject('', data[objIdx])); }

                    if(isLoadingMoreItems){
                        const currentData = this.data;
                        const newData = currentData.concat(data);
                        this.data = newData;
                    }else{
                        this.data = data;
                    }

                    if(this.data.length>0){
                        let tempRecs = [];
                        this.data.forEach( ( record ) => {
                            let tempRec = Object.assign( {}, record ); 
                            tempRec.LinkUrl= '/' + tempRec.Id;
                            let jsonData = JSON.parse(JSON.stringify(tempRec.RecordType));
                            tempRec.RecordTypeName = jsonData.Name;
                            tempRecs.push( tempRec );
                        });

                        this.data = tempRecs;
                        console.log('Data Show: '+JSON.stringify(this.data));
                        this.assetRowsOffset+=this.data.length;
                        this.showTable = true;
                        this.template.querySelector('c-sbr_3_0_custom-data-table-cmp').isLoading = false;
                    }
                    this.dispatchEvent(new CustomEvent('searchcomplete', {detail: this.assetRowsOffset}));
                })
                .catch((error) => {
                    console.log(error);
                });
        }

    }
    updateSelectedRows(event){
        let selectedRows = event.target.getSelectedRows();
        const selectedRowsEvent = new CustomEvent('rowsselected', { detail: selectedRows })
        this.dispatchEvent(selectedRowsEvent);
    }

    get listHeightStyle(){
        return `height:${this.listHeight}px;`;
    }

    //sorting needs to be refactored
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy = 'Name';

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