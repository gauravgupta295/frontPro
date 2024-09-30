import { LightningElement, track, api, wire } from 'lwc';
//Get the Super Categories
import getProductSuperCategories from '@salesforce/apex/SBR_3_0_AssetInquiryController.getProductSuperCategories';
//Get the Categories and Sub Category
import getProductCategories from '@salesforce/apex/SBR_3_0_AssetInquiryController.getProductCategories';

export default class Sbr_3_0_assetInquiryProductAttributeFilterCmp extends LightningElement {

    //Variable to store the Super Category Options 
    @track superCategoryOptions = [{
        label: 'All Items',
        value : 'All Items',
        isSelected: true
    }];
    //Variable to store all Category and Sub Category Options
    @track filterOptions = [];
    //Variable to store the Selected Filter Options to be used to show on Pill
    @track selectedFilterOptions = [];
    //Variable to store the selected Categories
    selectedCategories = [];
    //Variable to store the Selected Sub Categories
    selectedSubCategories = [];
    //Variable for current super category
    currentSuperCategory = "";

    /**
     * This method gets all Super Categories
     */
    @wire(getProductSuperCategories)
    getProductSuperCategory({error, data }) {
        if(data){
            data.forEach((superCategory) => {
                let comboOption = {};
                comboOption.label = superCategory.Name;
                comboOption.value = superCategory.Name
                comboOption.isSelected = false;
                this.superCategoryOptions = [...this.superCategoryOptions, comboOption];
            });
        }else if(error) {
            console.log(error);
        }

        let superCategoryInitialEvent = {
            'detail': {
                'value' : 'All Items'               
            }
        }

        this.handleSuperCategoryChangeEvent(superCategoryInitialEvent);

        const comboBox = this.template.querySelector('.combobox');
        if (comboBox) {
            comboBox.value = 'All Items';
        }
    }

    /**
     * Reset the Product Attribute filter
     */
    @api handleResetFilter(event){
        this.selectedFilterOptions = [];
        this.selectedCategories = [];
        this.selectedSubCategories = [];

        this.template.querySelectorAll('lightning-input')
        .forEach((element) => {
            element.checked = false;
        });

        this.template.querySelectorAll('[data-subcatsection]')
        .forEach((element) => {
            if (!element.classList.contains('slds-is-collapsed')) element.classList.add('slds-is-collapsed');
        });

        this.template.querySelectorAll('lightning-icon[data-catname]')
        .forEach((element) => {
            if (element.iconName == 'utility:chevrondown') element.iconName = 'utility:chevronright';
        });

        this.filterOptions
        .forEach((option) => {
            option.showCount = false;
            option.selectedSubcatCount = 0;
        });

        const comboBox = this.template.querySelector('.combobox');
        if (comboBox) {
            comboBox.value = 'All Items';
        }

        let superCategoryInitialEvent = {
            'detail': {
                'value' : 'All Items'               
            }
        }
        this.handleSuperCategoryChangeEvent(superCategoryInitialEvent); 
        this.handleProductSelectionChangeEvent();
    }

    /**
     * This handles the Super Category Change Event
     * As super category is changed, it gets all catgeories and sub categories and refreshes the left 
     * hand side
     */
    handleSuperCategoryChangeEvent(event){
        this.currentSuperCategory = event.detail.value;
        this.selectedFilterOptions = [];
        this.selectedCategories = [];
        this.selectedSubCategories = [];
  
        getProductCategories({ superCategory: this.currentSuperCategory })
        .then((data) => {
            if (data.length > 0) {
                this.filterOptions = [];
                data.forEach((category) => { 
                    var cat = {
                        Id: category.id,
                        Name: category.name,
                        attributeName: category.name.replaceAll('"', ''),
                        Parent: category.parent,
                        hasSubCategory: category.hasSubCategory,
                        isSubCatOpen: false,
                        subCategories: [],
                        selectedSubcatCount: 0,
                        showCount: false,
                        isSelected: false
                    };

                    category.subCategories.forEach((subCategory) => {
                        var subCat = {
                            Id: subCategory.Id,
                            Name: subCategory.Name,
                            attributeName: subCategory.Name.replaceAll('"', ''),
                            ParentName: subCategory.Parent_Code__r.Name,
                            ParentId: subCategory.Parent_Code__r.Id
                        };
                        cat.subCategories.push(subCat);
                    });

                    this.filterOptions.push(cat);
                });
            } else {
                this.filterOptions = [];
            }
        })
        .catch((error) => {
            console.log('Error - handleSuperCategoryChangeEvent : '+error);
        });

        //this.handleProductSelectionChangeEvent();
    }

    /**
     * This method is called when an element is removed from Pill
     * This will deselect the Category and Sub Category
     */
    handleRemovePill(event){
        let attributeName = event.target.getAttribute("data-label");
        let categoryObject = this.filterOptions.find(category => category.attributeName === attributeName);
        let categoryIndex = this.template.querySelector('[data-name="' + attributeName + '"]').dataset.elementid;

        this.selectedFilterOptions = this.selectedFilterOptions.filter(option => option !== categoryObject.Name);
        this.selectedCategories = this.selectedCategories.filter(option => option !== categoryObject.Name);
        this.template.querySelector('[data-name="' + attributeName + '"]').checked = false;

        if (categoryObject.hasSubCategory) {
            categoryObject.subCategories.forEach(subCat => {
                this.template.querySelector('[data-name="' + subCat.attributeName + '"]').checked = false;
                this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCat.Name);
            });
        }
        this.filterOptions[categoryIndex].selectedSubcatCount = 0;
        this.filterOptions[categoryIndex].showCount = false;

        this.handleProductSelectionChangeEvent();
    }

    /**
     * This method is called when a CheckBox of either Category or Sub Category is selected.
     */
    handleCheckboxUpdate(event) {
        let categoryLabel = event.target.getAttribute("data-name");
        let categoryType = event.target.getAttribute("data-type");
        let categoryIndex = event.target.dataset.elementid;

        var categoryObject;
        var subcategoryObject;

        if (categoryType == 'cat') {
            subcategoryObject = this.filterOptions.find(cat => cat.subCategories.find(subcat => subcat.ParentName == categoryLabel));
            categoryObject = this.filterOptions.find(category => category.attributeName === categoryLabel);
        }

        if (categoryType == 'subcat') {
            subcategoryObject = this.filterOptions.find(cat => cat.subCategories.find(subcat => subcat.attributeName == categoryLabel));
            categoryObject = this.filterOptions.find(cat => cat.subCategories.find(subcat => subcat.attributeName == categoryLabel));
        }

        // type is Cat; select/deselect all checkboxes if Cat checkbox is checked/unchecked
        if (event.target.checked){
            if(categoryType == 'cat'){
                if (subcategoryObject != null) {
                    subcategoryObject.subCategories.forEach(subcat => {
                        if (!this.template.querySelector('[data-name="' + subcat.attributeName + '"]').checked) {
                            this.template.querySelector('[data-name="' + subcat.attributeName + '"]').checked = true;
                            this.filterOptions[categoryIndex].selectedSubcatCount++;
                            this.selectedSubCategories.push(subcat.Name);
                        };
                    });
                }
                this.selectedCategories.push(categoryObject.Name);
            }
            else if (categoryType == 'subcat') {
                if (!this.template.querySelector('[data-name="' + categoryObject.attributeName + '"]').checked) {
                    this.template.querySelector('[data-name="' + categoryObject.attributeName + '"]').checked = true;
                };
                this.filterOptions[categoryIndex].selectedSubcatCount++;
                this.selectedSubCategories.push(categoryObject.subCategories.find(subcat => subcat.attributeName == categoryLabel).Name);
            } 

            if (!this.selectedFilterOptions.find(name => name === categoryObject.Name)) {
                this.selectedFilterOptions.push(categoryObject.Name);
            }

        }else if (!event.target.checked) {
            if(categoryType == 'cat'){
                if (subcategoryObject != null) {
                    subcategoryObject.subCategories.forEach(subcat => {
                        if (this.template.querySelector('[data-name="' + subcat.attributeName + '"]').checked) {
                            this.template.querySelector('[data-name="' + subcat.attributeName + '"]').checked = false;
                            this.filterOptions[categoryIndex].selectedSubcatCount--;
                        };
                    });
                }

                this.selectedCategories = this.selectedCategories.filter(name => name !== categoryObject.Name);
                
                //Find its sub categories and remove it if selected
                categoryObject.subCategories.forEach(subcategory => {
                    let subCatName = subcategory.Name;
                    this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCatName);
                });

                this.selectedFilterOptions = this.selectedFilterOptions.filter(name => name !== categoryObject.Name);

            }else if(categoryType == 'subcat'){

                var checkCount = 0;

                this.filterOptions[categoryIndex].selectedSubcatCount--;

                let subCatName = categoryObject.subCategories.find(subcat => subcat.attributeName == categoryLabel).Name;
                this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCatName);

                categoryObject.subCategories.forEach(category => {
                    if (this.template.querySelector('[data-name="' + category.attributeName + '"]').checked) checkCount++;
                });
    
                if (checkCount == 0) {
                    this.selectedFilterOptions = this.selectedFilterOptions.filter(name => name !== categoryObject.Name);
                    if (this.template.querySelector('[data-name="' + categoryObject.attributeName + '"]').checked) {
                        this.template.querySelector('[data-name="' + categoryObject.attributeName + '"]').checked = false;
                    };
                    this.selectedCategories = this.selectedCategories.filter(name => name !== categoryObject.Name); 
                }
            }
        } 

        if (this.filterOptions[categoryIndex].selectedSubcatCount > 0) {
            this.filterOptions[categoryIndex].showCount = true;
        }else{
            this.filterOptions[categoryIndex].showCount = false;
        }

        this.handleProductSelectionChangeEvent();
    }

    /**
     * This method is called when the toggle button on Category is clicked
     */
    handleToggleSubCatSection(event){
        let categoryLabel = event.target.getAttribute("data-catname");
        let category = this.filterOptions.find(cat => cat.Name == categoryLabel);

        this.template.querySelector('[data-subcatsection="' + category.Name + '"]').classList.toggle('slds-is-collapsed');
        this.filterOptions.find(cat => cat.Name == categoryLabel).isSubCatOpen = !category.isSubCatOpen;
    }

   /**
    * This method gets called when either checkbox of category & subcategory is selected/deselected or remove pill is done
    */
    handleProductSelectionChangeEvent(){
        //Send the event to AssetInquiryProductAttributeMain so that it is propgated to AssetInquiryProductSelectionPanel
        const getProductForSelectionEventdetail =  new CustomEvent('getproductforselectioneventdetail', {
            'detail': {
                'selectedcategories': this.selectedCategories, 
                'selectedsubcategories' : this.selectedSubCategories,
            }
        });
        this.dispatchEvent(getProductForSelectionEventdetail);
    }  
}