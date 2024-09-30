import { wire, api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getCatClassRecords from '@salesforce/apex/PPA_AddCatClassController.getCatClassRecords';
import fetchHierarchyProducts from '@salesforce/apex/PPA_AddCatClassController.fetchHierarchyProducts';
import selectedProductsCart from 'c/pPA_AddCatClassLWCAddedItems';
import { refreshApex } from '@salesforce/apex';

export default class PPA_AddCatClassLWC extends LightningModal {
    @api recordId;
    @api companyId;
    dataToRefresh;
    allRecords = [];
    topProducts = [];
    filteredRecords = [];
    displayRecords = [];
    addedRecords = [];
    hierarchyProducts = [];
    superCategoryOptions = [];
    categoryOptions = [];
    subCategoryOptions = [];
    selectedSuperCategory = null;
    selectedCategory = null;
    selectedSubCategory = null;
    selectedSuperCategoryName = null;
    selectedCategoryName = null;
    selectedSubCategoryName = null;
    keyword = '';
    queryKeyword = null;
    selectedProductText = 'Selected Products';
    selectedProducts = this.selectedProductText + '(0)';
    isSuperCategoryDisabled = false;
    isCategoryDisabled = true;
    isSubCategoryDisabled = true;
    productsAddedFlag = false;
    isActive = false;
    topProductActive = false;
    categoryFilterApplied = false;
    alreadyLoaded = false;
    showSpinner = true;
    error;
    //PPA Phase 2: DP-1025
    likeCatClass = false;
    @track disableLikeCatClass = false;
    @track disableTopProducts = false;
    /*PPA Phase 2: DP-1025
    Added likeCatClass*/
    column = [
        { label: 'Product', fieldName: 'ProductName', type: 'text', cellAttributes: { alignment: 'left', class: { fieldName: 'RowColorClass' } } },
        { label: 'CatClass', fieldName: 'CatClass', type: 'text', cellAttributes: { alignment: 'left', class: { fieldName: 'RowColorClass' } } },
        { label: 'Eligible', fieldName: 'EligibleDesc', type: 'text', cellAttributes: { alignment: 'left', class: { fieldName: 'RowColorClass' } } },
        { label: 'Like CatClass', fieldName: 'LikeCatClass', type: 'boolean', cellAttributes: { alignment: 'left', class: { fieldName: 'RowColorClass' } } }
    ];
    /*PPA Phase 2: DP-1025
    Passed likeCatClass*/
    @wire(getCatClassRecords, { priceListId: '$recordId', companyId: '$companyId', superCat: '$selectedSuperCategoryName', category: '$selectedCategoryName', subCat: '$selectedSubCategoryName', keyword: '$queryKeyword', topProduct: '$topProductActive', likeCatClass: '$likeCatClass' }) 
    wiredCatclass(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.allRecords = result.data;
        }
        this.showSpinner = false;
    }

    @wire(fetchHierarchyProducts)
    wiredHierarchyProducts({ error, data }) {
        if (data) {
            this.hierarchyProducts = data;
            const superCat = this.hierarchyProducts.filter(product => product.RecordType === 'Super_Category');
            this.superCategoryOptions = [{ label: '--None--', value: 'None' }, ...superCat.map(product => ({ label: product.Name, value: product.Id }))];
        }
    }

    generateProductCatOptions() {
        const productCat = this.hierarchyProducts.filter(product => product.Parent_Code__c === this.selectedSuperCategory && product.RecordType === 'Product_Category');
        this.categoryOptions = [{ label: '--None--', value: 'None' }, ...productCat.map(product => ({ label: product.Name, value: product.Id }))];
    }

    generateSubCatOptions() {
        const subcat = this.hierarchyProducts.filter(product => product.Parent_Code__c === this.selectedCategory && product.RecordType === 'Product_Sub_Category');
        this.subCategoryOptions = [{ label: '--None--', value: 'None' }, ...subcat.map(product => ({ label: product.Name, value: product.Id }))];

    }

    toggleTop(event){
        this.showSpinner = true;
        if(event.target.checked){
            this.topProductActive = true;
            this.isSuperCategoryDisabled = true;
            this.isCategoryDisabled = true;
            this.isSubCategoryDisabled = true;
            this.selectedSuperCategory = null;
            this.selectedCategory = null;
            this.selectedSubCategory = null;
            this.selectedSuperCategoryName = null;
            this.selectedCategoryName = null;
            this.selectedSubCategoryName = null;
            this.likeCatClass = false;
            this.filteredRecords = [];
            this.disableLikeCatClass = true;
        }
        else {
            this.isSuperCategoryDisabled = false;
            this.topProductActive = false;
            this.topProducts = [];
            this.disableLikeCatClass = false;
        }
    }

    //PPA Phase 2: DP-1025
    toggleLikeCatClass(event) {
        this.showSpinner = true;
        if (event.target.checked) {
            this.likeCatClass = true;
            this.isTopProductsActive = false;
            this.topProductActive = false;
            this.isSuperCategoryDisabled = true;
            this.isCategoryDisabled = true;
            this.isSubCategoryDisabled = true;
            this.selectedSuperCategory = null;
            this.selectedCategory = null;
            this.selectedSubCategory = null;
            this.selectedSuperCategoryName = null;
            this.selectedCategoryName = null;
            this.selectedSubCategoryName = null;
            this.topProducts = [];
            this.disableTopProducts = true;
        }
        else {
            this.likeCatClass = false;
            this.isSuperCategoryDisabled = false;
            this.disableTopProducts = false;
        }
    }

    handleSuperCategorySelection(event) {
        this.showSpinner = true;
        this.selectedSuperCategory = event.detail.value;
        this.selectedCategory = null;
        this.selectedCategoryName = null;
        this.selectedSubCategory = null;
        this.selectedSubCategoryName = null;
        this.isCategoryDisabled = false;
        this.isSubCategoryDisabled = true;
        this.categoryOptions = [];
        this.subCategoryOptions = [];

        if(this.selectedSuperCategory == 'None') {
            this.selectedSuperCategory = null;
            this.selectedSuperCategoryName = null;
            this.isCategoryDisabled = true;
            this.categoryFilterApplied = false;
            this.filteredRecords = [];
        }
        else {
            this.generateProductCatOptions();
            this.selectedSuperCategoryName = event.target.options.find(opt => opt.value === event.detail.value).label;
        }
    }

    handleCategorySelection(event) {
        this.showSpinner = true;
        this.selectedCategory = event.detail.value;
        this.selectedCategoryName = event.target.options.find(opt => opt.value === event.detail.value).label;
        this.selectedSubCategory = null;
        this.selectedSubCategoryName = null;
        this.isSubCategoryDisabled = false;
        this.subCategoryOptions = [];
        
        if(this.selectedCategory === 'None') {
            this.selectedCategory = null;
            this.selectedCategoryName = null;
            this.isSubCategoryDisabled = true;
        }
        else {
            this.generateSubCatOptions();
            this.selectedCategoryName = event.target.options.find(opt => opt.value === event.detail.value).label;
        }
    }

    handleSubCategorySelection(event) {
        this.showSpinner = true;
        this.selectedSubCategory = event.detail.value;

        if(this.selectedSubCategory === 'None') {
            this.selectedSubCategory = null;
            this.selectedSubCategoryName = null;
        }
        else {
            this.selectedSubCategoryName = event.target.options.find(opt => opt.value === event.detail.value).label;
        }
    }

    handleKeyword(event) {
        this.keyword = event.target.value;
    }

    applySearch() {
        this.showSpinner = true;
        if(this.keyword) {
            this.queryKeyword = '%' + this.keyword + '%';
        }
        else {
            this.queryKeyword = null;
        }
    }
    
    addToCart() {
        let selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        let addedRecordIds = [];

        for(var j=0;j<this.addedRecords.length;j++) {
            addedRecordIds.push(this.addedRecords[j].Id);
        }

        console.log(addedRecordIds);

        for (var i = 0; i < selectedRows.length; i++) {
            console.log(selectedRows[i].Id);
            
            if (selectedRows[i].isSelectable && !addedRecordIds.includes(selectedRows[i].Id)) {
                this.addedRecords.push(selectedRows[i]);
            }
        }

        this.selectedProducts = this.selectedProductText + '(' + this.addedRecords.length.toString() + ')';
    }

    handleCancel() {
        this.close();
    }

    async onSelectedProducts() {
        if(this.addedRecords.length > 0) {
            const result = await selectedProductsCart.open({
                size: 'small',
                description: 'This is to open the Selected Products Modal',
                recordId: this.recordId,
                addedRecords: this.addedRecords
            });
    
            if(result) {
                if(result == 'OK') {
                    this.showSpinner = true;
                    await refreshApex(this.dataToRefresh);
                    this.close('OK');
                }
                else {
                    this.showSpinner = false;
                    this.addedRecords = result;
                    this.selectedProducts = this.selectedProductText + '(' + this.addedRecords.length.toString() + ')';
                }    
            }
        }
    }
}