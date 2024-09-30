import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext, publish } from 'lightning/messageService';
import getProductCategories from '@salesforce/apex/SBR_3_0_CustomDataTableCmpController.getProductCategories';
import filterProductListChannel from '@salesforce/messageChannel/filterProductListChannel__c';


export default class Sbr_3_0_filterProductList extends LightningElement {
    isFilterPanelVisible = false;
    currentSuperCategory = "All Items";
    selectedCategories = [];
    selectedSubCategories = [];
    mapSelections = [];  //SAL-26801
    isMobile = false;
    cancelBtnClass = 'slds-button slds-button_neutral selected-btn';
    resetBtnClass = 'slds-button reset-btn-class';
    resetTxtClass = 'slds-button slds-p-right_small reset-txt-class';
    applyBtnClass = 'slds-button slds-button_neutral apply-btn-class';
    selectedClass = 'slds-button slds-button_neutral active-state';
    unselectedClass = 'slds-button slds-button_neutral selected-btn';
    showResetCatTxt = false;
    closeIcon = 'slds-icon';
    closeIconSelected = 'slds-icon close-icon';
    filterApplied = false;
    hasReset = false;
    previousState = [];

    @api horizontalAlign = 'space';

    @track selectedFilterOptions = [];
    @track filterOptions = [];

    @wire(MessageContext)
    messageContext;

    countNotZero = false;

    connectedCallback() {
        this.initCategoryOptions(this.currentSuperCategory);
        this.subscribeToMessageChannel();
        this.isMobile = window.matchMedia('(max-width: 480px)').matches;
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    initCategoryOptions(superCat) {

        getProductCategories({ superCategory: superCat })
            .then((data) => {
				this.filterOptions = [];
                if (data.length > 0) {
                    data.forEach((category) => {
                        var cat = {
                            Id: category.Id,
                            Name: category.Name,
                            attributeName: category.Name.replaceAll('"', ''),
                            Parent: category.Parent,
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



                }
            })
            .catch((error) => {
                console.log(error);
            });
    }

    subscribeToMessageChannel() {
        if (!this.filterProductSubscription) {
            this.filterProductSubscription = subscribe(
                this.messageContext,
                filterProductListChannel,
                (data) => this.handleFilterMessage(data),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.filterProductSubscription);
        this.filterProductSubscription = null;
    }

    resetFilterPanel() {
        this.deselectCategories();
        this.saveFilter();
        //this.applyFilter();
    }

    resetCategory(e) {
        let catIndex = e.currentTarget.dataset.id;
        let category = this.filterOptions[catIndex];
        let attributeName = this.filterOptions[catIndex].attributeName;

        // clear category and sub categories in individual element
        this.template.querySelector('[data-id="' + category.Id + '"]').checked = false;
        category.subCategories.forEach(subcat => {
            this.template.querySelector('[data-id="' + subcat.Id + '"]').checked = false;
        });

        const resetButton = this.template.querySelector('[data-id="' + catIndex + '"]');
        resetButton.style.visibility = 'hidden';

        this.filterOptions[catIndex].showCount = false;
        this.filterOptions[catIndex].selectedSubcatCount = 0;

        // clear pill
        this.removeSelectedFilterOption(attributeName, 'cat');

        // collapse section
        let icon = this.template.querySelector('lightning-icon[data-catname="' + attributeName + '"]');
        if (this.filterOptions[catIndex].hasSubCategory) {
            console.log('subcat section');
            if (!this.template.querySelector('[data-subcatsection="' + category.Name + '"]').contains('slds-is-collapsed')) {
                console.log('slds is NOT COLLAPSED');
                this.template.querySelector('[data-subcatsection="' + category.Name + '"]').classList.add('slds-is-collapsed');
                if (!this.isMobile) {
                    if (icon.iconName == 'utility:chevrondown') {
                        icon.iconName = 'utility:chevronright';
                    }
                } else {
                    if (icon.iconName == 'utility:chevronup') {
                        icon.iconName = 'utility:chevrondown';
                    }
                }
            }
        }
        this.mapSelections = [];
    }

    applyFilter() {
        this.saveFilter();
        this.selectedFilterOptions.forEach(op => {
            this.previousState.push(op);
        });

        // previous filter panel state values
        this.previousState.forEach(op => {
            console.log('temp val === ' + op);
        });
        // need to ask about this
        this.togglePanel();
    }

    togglePanel() {
        this.selectedFilterOptions.forEach(op => {
            if (!this.previousState.includes(op)) {
                console.log('val not in previous state');
                let fo = this.filterOptions.find(fo => fo.Name == op);
                console.log('attributeName and Name ==== ' + fo.attributeName + ' **** ' + op);
                this.template.querySelector('[data-Id="' + fo.Id + '"]').checked = false;
                let catIndex = this.template.querySelector('[data-name="' + fo.attributeName + '"]').dataset.elementid;
                const resetButton = this.template.querySelector('[data-id="' + catIndex + '"]');
                resetButton.style.visibility = 'hidden';

                this.selectedFilterOptions = this.selectedFilterOptions.filter(option => option !== fo.Name);
                this.selectedCategories = this.selectedCategories.filter(option => option !== fo.Name);
                this.template.querySelector('[data-id="' + fo.Id + '"]').checked = false;

                if (fo.hasSubCategory) {
                    fo.subCategories.forEach(subCat => {
                        this.template.querySelector('[data-id="' + subCat.Id + '"]').checked = false;
                        this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCat.Name);
                        this.filterOptions[catIndex].selectedSubcatCount = 0;
                        if (this.filterOptions[catIndex].selectedSubcatCount == 0) {
                            this.filterOptions[catIndex].showCount = false;
                        }
                    });
                } else {
                    this.filterOptions[catIndex].selectedSubcatCount = 0;
                    if (this.filterOptions[catIndex].selectedSubcatCount == 0) {
                        this.filterOptions[catIndex].showCount = false;
                    }
                }
            }
        });

        this.previousState.forEach(op => {
            console.log('PREVIOUSLY SAVED +++ ' + op);
        });

        console.log('togglePanel filterApplied val === ' + this.filterApplied);
        console.log('togglePanel filter ==== ' + this.selectedFilterOptions);
        if (this.template.querySelector('lightning-button-icon')) {
            const toggleprodinqmobilestate = new CustomEvent('toggleprodinqmobilestate', {
                bubbles: true,
                composed: true,
                'detail': {
                    viewState: 'base',
                    showTabsPanel: true,
                }
            });
            this.dispatchEvent(toggleprodinqmobilestate);

        }
        this.isFilterPanelVisible = !this.isFilterPanelVisible;

        if (this.isFilterPanelVisible) {
            this.template.querySelector('.filter-panel').classList.add('slds-is-open');
        } else {
            //this.closeIcon = this.closeIconSelected;
            this.template.querySelector('.filter-panel').classList.remove('slds-is-open');
        }
    }

    handleFilterMessage(data) {
        if (data.action == "toggleFilterPanel") {
            console.log('toggleFilterPanel')
            this.togglePanel();
        }
        if (data.action == "superCategoryChanged") {
            this.resetFilterPanel();
            this.initCategoryOptions(data.category);
        }
    }

    handleToggleSubCatSection(e) {
        // toggle reset on chevron icons as well
        let catIndex = e.target.dataset.elementid;
        var catObj = this.filterOptions[catIndex];

        console.log('utility icon ===');

        const resetButton = this.template.querySelector('[data-id="' + catIndex + '"]');

        let catLabel = e.target.getAttribute("data-catname");
        let category = this.filterOptions.find(cat => cat.Name == catLabel);

        this.template.querySelector('[data-subcatsection="' + category.Name + '"]').classList.toggle('slds-is-collapsed');
        this.filterOptions.find(cat => cat.Name == catLabel).isSubCatOpen = !category.isSubCatOpen;
    }


    handleCheckboxUpdate(e) {
        console.log('handleCheckboxUpdate applied === ' + e.target.checked);
        let catLabel = e.target.getAttribute("data-name");
        let catType = e.target.getAttribute("data-type");

        let catIndex = e.target.dataset.elementid;
        var catObj = this.filterOptions[catIndex];
        var subcatObj;
        var tempSubCats = [];
        var indexCat;

        if (catType == 'cat') {
            subcatObj = this.filterOptions.find(cat => cat.subCategories.find(subcat => subcat.ParentName == catLabel));

            //SAL-26801
            indexCat = this.mapSelections.indexOf(this.mapSelections.find(element => element.key === catLabel));
            if(!e.target.checked && indexCat>=0) {
                this.mapSelections.splice(indexCat,1); 
                console.log('Cat deselected >> '+JSON.stringify(this.mapSelections));
            } else if(e.target.checked) {
                this.mapSelections.push({key: catLabel, value: []});
                console.log('Cat selected >> '+JSON.stringify(this.mapSelections));

        }
        }

        if (catType == 'subcat') {
            
            subcatObj = this.filterOptions.find(cat => cat.subCategories.find(subcat => (subcat.attributeName == catLabel && catObj.attributeName == subcat.ParentName)));
            console.log('CAT '+subcatObj.attributeName+' | SubCat '+ catLabel);
            
            //SAL-26801
            indexCat = this.mapSelections.indexOf(this.mapSelections.find(element => element.key === subcatObj.attributeName));
            if(indexCat >= 0) {
                tempSubCats = this.mapSelections.find(element => element.key === subcatObj.attributeName).value;
                this.mapSelections.splice(indexCat,1); 
        }
            if(e.target.checked && tempSubCats.indexOf(catLabel)<0) {
                tempSubCats.push(catLabel);
                this.mapSelections.push({key: subcatObj.attributeName, value: tempSubCats});
            }
        
            else if(!e.target.checked && tempSubCats.indexOf(catLabel)>=0) {
                tempSubCats.splice(tempSubCats.indexOf(catLabel),1); 
                this.mapSelections.push({key: subcatObj.attributeName, value: tempSubCats});
            }
            console.log(tempSubCats.length + ' Subcat selected/deselected >> '+JSON.stringify(this.mapSelections));
        }
        
        const resetButton = this.template.querySelector('[data-id="' + catIndex + '"]');
        resetButton.style.visibility = 'hidden';

        // counter for number of cat/subcats selected per cat

        if (catObj != null && subcatObj == null) {
            resetButton.style.visibility = 'hidden';
        }

        if (catObj != null && subcatObj == null) {
            resetButton.style.visibility = 'hidden';
        } else {
            subcatObj.subCategories.forEach(subcat => {
                if (this.template.querySelector('[data-id="' + catObj.Id + '"]').checked
                    || this.template.querySelector('[data-id="' + subcat.Id + '"]').checked) {
                    resetButton.style.visibility = 'visible';
                }
                if (!this.template.querySelector('[data-id="' + catObj.Id + '"]').checked
                    && this.template.querySelector('[data-id="' + subcat.Id + '"]').checked) {
                    resetButton.style.visibility = 'visible';
                }
            });
        }

        // type is Cat; select/deselect all checkboxes if Cat checkbox is checked/unchecked
        if (e.target.checked && catType == 'cat') {
            tempSubCats = [];
            if (subcatObj != null) {
                subcatObj.subCategories.forEach(subcat => {
                    tempSubCats.push(subcat.attributeName); //SAL-26801
                    if (!this.template.querySelector('[data-id="' + subcat.Id + '"]').checked) {
                        this.template.querySelector('[data-id="' + subcat.Id + '"]').checked = true;
                        this.filterOptions[catIndex].selectedSubcatCount++;
                    };
                });
                //SAL-26801
                if(tempSubCats.length > 0) {
                    indexCat = this.mapSelections.indexOf(this.mapSelections.find(element => element.key === subcatObj.attributeName));
                    if(indexCat>=0) {
                        this.mapSelections.splice(indexCat,1); 
                    }
                    this.mapSelections.push({key: subcatObj.attributeName, value: tempSubCats});
                    console.log('map after push subcats '+JSON.stringify(this.mapSelections));
                }
            }
        }

        if (!e.target.checked && catType == 'cat') {
            resetButton.style.visibility = 'hidden';
        }

        if (!e.target.checked && catType == 'cat') {
            if (subcatObj != null) {
                subcatObj.subCategories.forEach(subcat => {
                    if (this.template.querySelector('[data-id="' + subcat.Id + '"]').checked) {
                        this.template.querySelector('[data-id="' + subcat.Id + '"]').checked = false;
                        this.filterOptions[catIndex].selectedSubcatCount--;
                        resetButton.style.visibility = 'hidden';
                    };
                });
            }
        }
        if (e.target.checked && catType == 'cat') {
            this.addSelectedFilterOption(catLabel, catType, catObj.attributeName);
        } else if (e.target.checked && catType == 'subcat') {
            this.addSelectedFilterOption(catLabel, catType, catObj.attributeName);
            this.filterOptions[catIndex].selectedSubcatCount++;
        } else if (!e.target.checked && catType == 'subcat') {
            this.removeSelectedFilterOption(catLabel, catType);
            this.filterOptions[catIndex].selectedSubcatCount--;
        } else if (!e.target.checked && catType != 'subcat') {
            this.removeSelectedFilterOption(catLabel, catType);
        } else {
            this.removeSelectedFilterOption(catLabel, catType);
        }

        if (this.filterOptions[catIndex].selectedSubcatCount > 0) {
            this.filterOptions[catIndex].showCount = true;
        }

        if (this.filterOptions[catIndex].selectedSubcatCount == 0) {
            this.filterOptions[catIndex].showCount = false;
        }
    }

    addSelectedFilterOption(catLabel, catType, parentName) {
        var catObj;

        if (catType == "cat") {
            catObj = this.filterOptions.find(category => category.attributeName === catLabel);
            this.selectedCategories.push(catObj.Name);
        }
        if (catType == "subcat") {
            catObj = this.filterOptions.find(cat => cat.subCategories.find(subcat => (subcat.attributeName == catLabel && subcat.ParentName == parentName)));
            this.selectedSubCategories.push(catObj.subCategories.find(subcat => (subcat.attributeName == catLabel && subcat.ParentName == parentName)).Name);
        }

        if (!this.selectedFilterOptions.find(name => name === catObj.Name)) {
            this.selectedFilterOptions.push(catObj.Name);
        }
    }

    removeSelectedFilterOption(catLabel, catType) {
        var catObj;
        var checkCount = 0;

        if (catType == "cat") {
            catObj = this.filterOptions.find(category => category.attributeName === catLabel);

            this.selectedCategories = this.selectedCategories.filter(name => name !== catObj.Name);

        }
        if (catType == "subcat") {
            catObj = this.filterOptions.find(cat => cat.subCategories.find(subcat => subcat.attributeName == catLabel));
            let subCatName = catObj.subCategories.find(subcat => subcat.attributeName == catLabel).Name;

            this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCatName);
            if (this.template.querySelector('[data-id="' + catObj.Id + '"]').checked) checkCount++;
        }

        catObj.subCategories.forEach(category => {
            if (this.template.querySelector('[data-id="' + category.Id + '"]').checked) checkCount++;
        });
        if (checkCount == 0) {
            this.selectedFilterOptions = this.selectedFilterOptions.filter(name => name !== catObj.Name);
        }
    }

    handleRemovePill(e) {
        let attributeName = e.target.getAttribute("data-label");
        let catObj = this.filterOptions.find(category => category.attributeName === attributeName);

         //SAL-26801
        var indexCat = this.mapSelections.indexOf(this.mapSelections.find(element => element.key === attributeName));
        if(indexCat>=0) {
             this.mapSelections.splice(indexCat,1); 
             console.log('Pile deselected >> '+JSON.stringify(this.mapSelections));
        } 

        //remove reset buttons
        let catIndex = this.template.querySelector('[data-id="' + catObj.Id + '"]').dataset.elementid;
        const resetButton = this.template.querySelector('[data-id="' + catIndex + '"]');
        resetButton.style.visibility = 'hidden';

        this.selectedFilterOptions = this.selectedFilterOptions.filter(option => option !== catObj.Name);
        this.selectedCategories = this.selectedCategories.filter(option => option !== catObj.Name);
        this.template.querySelector('[data-id="' + catObj.Id + '"]').checked = false;
        console.log(attributeName+' - catIndex '+catIndex+' - resetButton '+resetButton+' checkbox '+this.template.querySelector('[data-id="' + catObj.Id + '"]').checked);

        if (catObj.hasSubCategory) {
            catObj.subCategories.forEach(subCat => {
                this.template.querySelector('[data-id="' + subCat.Id + '"]').checked = false;
                this.selectedSubCategories = this.selectedSubCategories.filter(option => option !== subCat.Name);
                this.filterOptions[catIndex].selectedSubcatCount = 0;
                if (this.filterOptions[catIndex].selectedSubcatCount == 0) {
                    this.filterOptions[catIndex].showCount = false;
                }

            });
        } else {
            this.filterOptions[catIndex].selectedSubcatCount = 0;
            if (this.filterOptions[catIndex].selectedSubcatCount == 0) {
                this.filterOptions[catIndex].showCount = false;
            }
        }
    }

   saveFilter() {
        // display selected filter options in a, b, c format vs. a,b,c
        const selectedFilterOpsSpaced = this.selectedFilterOptions.join(', ');
        let catFilter, subCatFilter;
        let cat;
        let subCats = [];
        let catSubCatWhereList = [];
        let originalSubCatNum;

        //SAL-26801 Create Category and Sub-Cat WHERE clause as: (cat1 AND subcat1) OR (cat2 AND subcat2)
        for(var i=0; i < this.mapSelections.length; i++){
            cat = this.mapSelections[i].key;
            subCats = this.mapSelections[i].value;
            originalSubCatNum = this.filterOptions.find(category => category.attributeName == cat).subCategories.length;

            if(cat && this.selectedCategories.includes(cat)) {
                cat = cat.replaceAll("\'","\\'");
                catFilter = "Product_Category__c = '" + cat + "'";
            }
            else    
                catFilter = "";
            if(subCats.length > 0 && originalSubCatNum > subCats.length) {
                for(var i=0;i<subCats.length;i++) {
                    subCats[i] = subCats[i].replaceAll("\'","\\'");
                }
                subCatFilter = "Product_Sub_Category__c IN ('" + subCats.join("','") + "')";
                subCatFilter = catFilter != "" ? " AND " + subCatFilter : subCatFilter;
            }
            else {
                subCatFilter = "";
            }
            if(catFilter && originalSubCatNum == 0){
                catFilter += " OR Product_Sub_Category__c = '" + cat + "'";
            }
            if(catFilter || subCatFilter)
                catSubCatWhereList.push("(" + catFilter + subCatFilter + ")"); 
        }

        const catSubCatWhere = catSubCatWhereList.length>0 ? "("+catSubCatWhereList.join(" OR ")+")" : "";
        console.log('catSubCatWhere >> '+catSubCatWhere);
        const payload = {
            action: 'applyFilter',
            numberOfFilters: this.selectedFilterOptions.length,
            selectedCategories: this.selectedCategories,
            selectedSubCategories: this.selectedSubCategories,
            selectedFilterOptions: selectedFilterOpsSpaced,
            catSubCatWhere: catSubCatWhere  //SAL-26801
        };
        publish(this.messageContext, filterProductListChannel, payload);
    }


    deselectCategories() {
        this.selectedFilterOptions = [];
        this.selectedCategories = [];
        this.selectedSubCategories = [];
        this.showResetCatTxt = false;
        this.mapSelections = [];
        this.template.querySelectorAll('lightning-input')
            .forEach((element) => {
                element.checked = false;
            });

        console.log('is subcat section? ----> ' + this.template.querySelectorAll('[data-subcatsection]'));
        this.template.querySelectorAll('[data-subcatsection]')
            .forEach((element) => {
                if (!element.classList.contains('slds-is-collapsed')) element.classList.add('slds-is-collapsed');
            });

        if (!this.isMobile) {
            this.template.querySelectorAll('lightning-icon[data-catname]')
                .forEach((element) => {
                    if (element.iconName == 'utility:chevrondown') element.iconName = 'utility:chevronright';
                });
        } else {
            this.template.querySelectorAll('lightning-icon[data-catname]')
                .forEach((element) => {
                    if (element.iconName == 'utility:chevronup') element.iconName = 'utility:chevrondown';
                });
        }

        this.filterOptions
            .forEach((option) => {
                option.showCount = false;
                option.selectedSubcatCount = 0;
            });

        //remove reset buttons
        this.template.querySelectorAll('button')
            .forEach((element) => {
                if (element.value == 'Apply' || element.value != 'Reset All Filters' || element.value != 'Cancel') {
                    element.style.visibility = 'visible';
                }
                if (element.value == 'Reset') {
                    element.style.visibility = 'hidden';
                }
            });
    }
}