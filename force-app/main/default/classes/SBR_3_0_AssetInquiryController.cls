/*********************************************************************************************************************
* Apex Class: SBR_3_0_AssetInquiryController
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - Controller class for loading data for Asset Enquiry LWC Components
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*   1.0         Chinmay Kant            2023-04-03          Initial version
*   1.1         Ritesh Mohapatra        2023-12-26          Updated getPicklistMetadata() method 
*   1.2         Chhavi Singhal          2024-03-14          Updated getProductCategories() method
*   1.3         Chhavi Singhal          2024-06-13          Added fields in SOQL Query of Location
*********************************************************************************************************************/
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.EagerlyLoadedDescribeSObjectResult')
public without sharing class SBR_3_0_AssetInquiryController {
    /**
     * @description Get Level Records from SBR_3_0_AssetInquiryPicklistValues__mdt custom metadata type
     * @param context Return only SBR_3_0_AssetInquiryPicklistValues__mdt records where SM_PS_Context__c equals this value
     * @return Relevant SBR_3_0_AssetInquiryPicklistValues__mdt records
     */
    @AuraEnabled(cacheable = true)
    public static List<SBR_3_0_AssetInquiryPicklistValues__mdt> getPicklistMetadata(String context) {
        List<SBR_3_0_AssetInquiryPicklistValues__mdt> picklistValuesList = new List<SBR_3_0_AssetInquiryPicklistValues__mdt>();
        try {
            for(SBR_3_0_AssetInquiryPicklistValues__mdt assetInquiryPicklistValue : SBR_3_0_AssetInquiryPicklistValues__mdt.getAll().values()) {
                if(context == assetInquiryPicklistValue.SM_PS_Context__c) {
                    if(context == 'Level' && assetInquiryPicklistValue.SM_PS_Required_for_Asset_Inquiry__c == TRUE) {
                        picklistValuesList.add(assetInquiryPicklistValue);
                    } else if (context != 'Level') {
                        picklistValuesList.add(assetInquiryPicklistValue);
                    } 
                } 
            }
            
            if(picklistValuesList.size() > 0) {
                picklistValuesList.sort();
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return picklistValuesList; 
    }
    
    /**
     * @description Get User's Current Location
     * @return Location record from current User's User_Location__c record
     */
    @AuraEnabled(cacheable=true)
    public static Schema.Location getCurrentUserLocation() {
        try {
            //User's Current Location
            Schema.Location userCurrentLocation = null;
            Id currentUserId = UserInfo.getUserId();        
            User_Location__c currentUserLocation = [SELECT Id, Name, User__c, Branch__c
                                                    FROM User_Location__c
                                                    WHERE User__c = :currentUserId
                                                    WITH USER_MODE
                                                    LIMIT 1];
            
            if (currentUserLocation != null && currentUserLocation.Branch__c != null) {
                userCurrentLocation = [SELECT Id, Name, Company_Code__c, District__c, Reporting_Region_Name__c, Analysis_Region_Key__c,
                                              Territory__c, Price_Market__c, Market_Name__c
                                       FROM Location
                                       WHERE id = :currentUserLocation.Branch__c
                                       WITH USER_MODE
                                       LIMIT 1];
            }
            return userCurrentLocation;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Branch Location
     * @param branchNumber
     * @return Location record
     */
    @AuraEnabled(cacheable=true)
    public static Schema.Location getBranchLocation(String branchNumber) {
        try {    
            Schema.Location branch = [SELECT Id, Name, Branch_Location_Name__c, Branch_Location_Number__c,City__c, State__c, 
                                      Zip_Code__c, District__c, Region__c, Territory__c, Company__c, Phone__c,Address__c
                                      FROM Location
                                      WHERE Branch_Location_Number__c = :branchNumber
                                      WITH SYSTEM_MODE
                                      LIMIT 1];
            
            return branch;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Branch Details
     * @param branchId
     * @return Location record
     */
    @AuraEnabled(cacheable=true)
    public static Schema.Location getBranchDetails(String branchId) {
        try {
            Schema.Location branch = [SELECT Id, Name, Branch_Location_Name__c, Branch_Location_Number__c, City__c, State__c, 
                                      Zip_Code__c, District__c, Region__c, Territory__c, Company__c
                                      FROM Location
                                      WHERE Id = :branchId
                                      WITH USER_MODE
                                      LIMIT 1];
            
            return branch;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Filtered Asset Records Count
     * @param sCountQuery SOQL COUNT() query to run
     * @return Number of values returned by a COUNT() query
     */
    @AuraEnabled(cacheable=true)
    public static Integer getFilteredAssetsCount(String sCountQuery) {
        try {
            Integer recordCount = Database.countQuery(sCountQuery);
            
            return recordCount;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Filtered Asset Records
     * @param sQuery Asset SOQL query to run
     * @return List of Asset returned by specified query
     */
    @AuraEnabled(cacheable=true)
    public static List<Asset> getFilteredAssets(String sQuery) {
        try {   
            List<Asset> filteredAssetsList = new List<Asset>();
            
            for (Asset assetRec : Database.query(sQuery)) {
                filteredAssetsList.add(assetRec);
            }
            return filteredAssetsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Products for Selection
     * @param sQuery Product SOQL query to run
     * @return List of Products
     */
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductsForSelection(String sQuery) {
        try {
            List<Product2> productList = new List<Product2>();
            
            for (Product2 productRec : Database.query(sQuery)) {
                productList.add(productRec);
            }
            return productList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Picklist Values from Picklist fields (Asset.Status, Asset.Equipment Type)
     * @param objectName API name of the SObject with the picklist field
     * @param fieldName API name of the picklist field
     * @return List of possible picklist values
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getPickListValuesFromFields(String objectName, String fieldName) {
        List<String> valuesList = new List<String>(); 
        Schema.DescribeSobjectResult[] objectResultsList = Schema.describeSObjects(new List<String>{ objectName });
        
        for (Schema.DescribeSobjectResult objectResult : objectResultsList) {
            for (
                Schema.PicklistEntry pickListEntry : objectResult.fields.getMap()
                .get(fieldName)
                .getDescribe()
                .getPicklistValues()
            ) {
                if (pickListEntry.isActive()) {
                    valuesList.add(pickListEntry.getValue());
                }
            }
        }
        
        return valuesList;
    }
    
    /**
     * @description Get Product SuperCategories
     * @return List of Product_Hierarchy__c
     */
    @AuraEnabled(cacheable=true)
    public static List<Product_Hierarchy__c> getProductSuperCategories() {
        try {
            List<Product_Hierarchy__c> categoryOptions = SBR_3_0_ProductDA.getProductCategoryOptions(
                1,
                null,
                null,
                false,
                true
            );
            return removeDuplicateCategories(categoryOptions);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Get Product Categories
     * @param superCategory
     * @return List of SBR_3_0_CategoryDetails
     */
    @AuraEnabled(cacheable=true)
    public static List<SBR_3_0_CategoryDetails> getProductCategories(String superCategory) {
        try {
            List<Product_Hierarchy__c> categoryOptionsList;
            List<Product_Hierarchy__c> subCategoryOptionsList;
            Map<String, SBR_3_0_CategoryDetails> categoryMap = new Map<String, SBR_3_0_CategoryDetails>();
            Set<Id> categoryIDs = new Set<Id>();
            
            //Get Product Categories
            if (String.isBlank(superCategory) || superCategory == 'All Items') {
                categoryOptionsList = SBR_3_0_ProductDA.getProductCategoryOptions(
                    2,
                    null,
                    null,
                    false,
                    true
                );
            } else {
                categoryOptionsList = SBR_3_0_ProductDA.getProductCategoryOptions(
                    2,
                    superCategory,
                    null,
                    false,
                    true
                );
            }
            
            if(!categoryOptionsList.isEmpty()) {
                categoryOptionsList = removeDuplicateCategories(categoryOptionsList);
                for (Product_Hierarchy__c categoryOptions : categoryOptionsList) {
                    categoryIDs.add(categoryOptions.Id);
                    categoryMap.put(
                        categoryOptions.Name,
                        new SBR_3_0_CategoryDetails(categoryOptions)
                    );
                }
            }

            //Get Product Sub Category
            subCategoryOptionsList = SBR_3_0_ProductDA.getProductCategoryOptions(
                    null,
                    null,
                    categoryIDs,
                    true,
                    true
             );
                
            if(!subCategoryOptionsList.isEmpty()) {
                subCategoryOptionsList = removeDuplicateCategories(subCategoryOptionsList);
                for (Product_Hierarchy__c subCategoryOptions : subCategoryOptionsList) {
                    if(subCategoryOptions.Parent_Code__c != null) {
                        categoryMap.get(subCategoryOptions.Parent_Code__r.Name)
                            .subCategories.add(subCategoryOptions);
                        categoryMap.get(subCategoryOptions.Parent_Code__r.Name)
                            .hasSubCategory = true;
                    }
                }
            }  
                 
            return categoryMap.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + '' + e.getLineNumber());
        }
    }
    
    /**
     * @description Remove Duplicate Categories
     * @param categoryOptions
     * @return List of Product_Hierarchy__c
     */
    public static List<Product_Hierarchy__c> removeDuplicateCategories(List<Product_Hierarchy__c> categoryOptions) {
        Map<String, Product_Hierarchy__c> categoryMap = new Map<String, Product_Hierarchy__c>();
        
        for (Product_Hierarchy__c opt : categoryOptions) {
            categoryMap.put(opt.name, opt);
        }
        return categoryMap.values();
    }
    
    @testvisible
    class SBR_3_0_CategoryDetails {
        /**
        * @description Id of Product_Hierarchy__c
        */
        @AuraEnabled
        public String id { get; set; }
        /**
        * @description Name of Product_Hierarchy__c
        */
        @AuraEnabled
        public String name { get; set; }
        /**
        * @description Parent Name of Product_Hierarchy__c
        */
        @AuraEnabled
        public String parent { get; set; }
        /**
        * @description hasSubCategory
        */
        @AuraEnabled
        public Boolean hasSubCategory { get; set; }
        /**
        * @description subCategories
        */
        @AuraEnabled
        public List<Product_Hierarchy__c> subCategories { get; set; }
        
        /**
        * @description Constructor 
        * @param cat
        */
        public SBR_3_0_CategoryDetails(Product_Hierarchy__c cat) {
            this.Id = cat.Id;
            this.Name = cat.Name;
            this.Parent = cat.Parent_Code__r.Name;
            this.hasSubCategory = false;
            this.subCategories = new List<Product_Hierarchy__c>();
        }
    }
}