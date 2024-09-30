public with sharing class PPA_AddCatClassController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCatClassRecords(Id priceListId, String companyId, String superCat, String category, String subCat, String keyword, Boolean topProduct, Boolean likeCatClass) {
        Map<String, Product2> mapProduct = new Map<String, Product2>();
        Map<String, PPA_Rental_CatClass__c> mapRentalCatClass = new Map<String, PPA_Rental_CatClass__c>();
        Map<String, PPA_CatClass_Rate__c> mapCatClassRate = new Map<String, PPA_CatClass_Rate__c>();
        Map<String, PPA_Rental_CatClass__c> mapLikeCatClass = new Map<String, PPA_Rental_CatClass__c>();
        List<Map<String, Object>> returnVals = new List<Map<String, Object>>();
		List<Product2> productList = new List<Product2>();
        List<PPA_Rental_CatClass__c> likeCatClassList = new List<PPA_Rental_CatClass__c>();
        Set<String> setTopProdCat = new Set<String>();
        Set<String> setTopProdClass = new Set<String>();
        Set<String> setSuperCat = new Set<String>();
        Set<String> setCategory = new Set<String>();
        Set<String> setSubCat = new Set<String>();
        Set<String> setTopCatClass = new Set<String>();
        String strSOQL = '';
        String prodStatus = 'A';
        String prodType = 'Cat-Class';
        
        try {
            strSOQL = strSOQL + 'SELECT Id,Name,Category__c,Class__c,Product_Category__c,Product_Sub_Category__c,Super_Category__c,PPA_CatClass__c';
            strSOQL = strSOQL + '  FROM Product2';
            strSOQL = strSOQL + ' WHERE Product_Type__c = :prodType AND Status__c = :prodStatus AND Company_Code__c INCLUDES (:companyId)';
            
            if(topProduct) {
                for(PPA_CatClass_Rate__c catClassRate : [SELECT Id, Name, CurrencyIsoCode, PPA_CompanyId__c, 
                                                                PPA_Cat__c, PPA_Class__c, PPA_CatClass_Owner__c, PPA_Apply_Rate_Type__c, 
                                                                PPA_Min_Rate__c, PPA_Min_Day__c, PPA_Min_Week__c, PPA_Min_Month__c, 
                                                                PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c, PPA_CatClass__c, PPA_Top_Product__c 
                                                            FROM PPA_CatClass_Rate__c
                                                            WHERE PPA_CompanyId__c = :companyId
                                                            AND PPA_Active__c = true
                                                            AND PPA_Top_Product__c = true])
                {
                    mapCatClassRate.put(catClassRate.PPA_CatClass__c, catClassRate);

                    // Populate the sets for querying the Product2 object
                    setTopProdCat.add(catClassRate.PPA_Cat__C);
                    setTopProdCat.add(catClassRate.PPA_CatClass__c.substring(0,3));

                    setTopProdClass.add(catClassRate.PPA_Class__c);
                    setTopProdClass.add(catClassRate.PPA_CatClass__c.substring(4,8));
                }

                setTopCatClass = mapCatClassRate.keySet();

                strSOQL = strSOQL + ' AND Category__c IN :setTopProdCat AND Class__c IN :setTopProdClass';
                strSOQL = strSOQL + ' AND PPA_CatClass__c IN :setTopCatClass';
            }
            else {
                if(!String.isEmpty(superCat)) {
                    strSOQL = strSOQL + ' AND Super_Category__c = :superCat';
                }
                
                if(!String.isEmpty(category)) {
                    strSOQL = strSOQL + ' AND Product_Category__c = :category';
                }
                
                if(!String.isEmpty(subCat)) {
                    strSOQL = strSOQL + ' AND Product_Sub_Category__c = :subCat';
                }
            }
            
            if(!String.isEmpty(keyword)) {
                strSOQL = strSOQL + ' AND (Name LIKE :keyword OR PPA_CatClass__c LIKE :keyword)';            
            }
            
            strSOQL = strSOQL + ' LIMIT 200';
            
            /*PPA Phase 2: DP-1025
            If likeCatClass = true then do not get Product2 records*/
            if(!likeCatClass) {
                productList = Database.query(strSOQL);
            }
            
            for(Product2 product : productList) {
                mapProduct.put(product.PPA_CatClass__c, product);
            }
    
													  
			 
            for(PPA_Rental_CatClass__c catClass : [SELECT Id,
                                                          PPA_Product__c,
                                                          PPA_Product_Name__c,
                                                          PPA_CatClass__c,
                                                          PPA_Super_Cat__c,
                                                          PPA_Product_Category__c,
                                                          PPA_Sub_Cat__c
                                                     FROM PPA_Rental_CatClass__c 
                                                    WHERE PPA_Price_List__c= :priceListId
                                                      AND PPA_Like_CatClass__c = false])
            {
                mapRentalCatClass.put(catClass.PPA_CatClass__c, catClass);
            }
            strSOQL = '';
            strSOQL = strSOQL + 'SELECT PPA_Product__c, PPA_Product_Name__c, PPA_CatClass__c, PPA_Super_Cat__c, PPA_Product_Category__c, PPA_Sub_Cat__c';
            strSOQL = strSOQL + '  FROM PPA_Rental_CatClass__c';
            strSOQL = strSOQL + ' WHERE PPA_Price_List__c= :priceListId';
            strSOQL = strSOQL + '   AND PPA_Like_CatClass__c = true';

            if(!topProduct) {
                for(PPA_CatClass_Rate__c catClassRate : [SELECT Id, Name, CurrencyIsoCode, PPA_CompanyId__c, 
                                                                PPA_Cat__c, PPA_Class__c, PPA_CatClass_Owner__c, PPA_Apply_Rate_Type__c, 
                                                                PPA_Min_Rate__c, PPA_Min_Day__c, PPA_Min_Week__c, PPA_Min_Month__c, 
                                                                PPA_New_Day__c, PPA_New_Week__c, PPA_New_Month__c, PPA_CatClass__c, PPA_Top_Product__c 
                                                            FROM PPA_CatClass_Rate__c
                                                            WHERE PPA_CompanyId__c = :companyId
                                                            AND PPA_Active__c = true
                                                            AND PPA_CatClass__c IN :mapProduct.keySet()])
                {
                    mapCatClassRate.put(catClassRate.PPA_CatClass__c, catClassRate);
                }

                if(!String.isEmpty(superCat)) {
                    strSOQL = strSOQL + ' AND PPA_Super_Cat__c = :superCat';
                }
                
                if(!String.isEmpty(category)) {
                    strSOQL = strSOQL + ' AND PPA_Product_Category__c = :category';
                }
                
                if(!String.isEmpty(subCat)) {
                    strSOQL = strSOQL + ' AND PPA_Sub_Cat__c = :subCat';
                }            
            }
            else {
                strSOQL = strSOQL + ' AND PPA_CatClass__c IN :setTopCatClass';
            }

            if(!String.isEmpty(keyword)) {
                strSOQL = strSOQL + ' AND (PPA_Product_Name__c LIKE :keyword OR PPA_CatClass__c LIKE :keyword)';    
            }                

            likeCatClassList = Database.query(strSOQL);
                
            for(PPA_Rental_CatClass__c likeCatClassObj : likeCatClassList) {
                mapLikeCatClass.put(likeCatClassObj.PPA_CatClass__c, likeCatClassObj);
            }
            
            for(String key : mapProduct.keySet()) {
                Product2 oneProduct = mapProduct.get(key);
                
                if(!mapLikeCatClass.containsKey(key)) {
                    Map<String, Object> outputRec = new Map<String, Object>();
                    outputRec.put('Id', oneProduct.Id );
                    outputRec.put('Source', 'Product');
                    outputRec.put('SuperCategory', !String.isBlank(oneProduct.Super_Category__c) ? oneProduct.Super_Category__c.toUpperCase() : null);
                    outputRec.put('Category', !String.isBlank(oneProduct.Product_Category__c) ? oneProduct.Product_Category__c.toUpperCase() : null);
                    outputRec.put('SubCategory', !String.isBlank(oneProduct.Product_Sub_Category__c) ? oneProduct.Product_Sub_Category__c.toUpperCase() : null);
                    outputRec.put('CatClass', oneProduct.PPA_CatClass__c);
                    outputRec.put('ProductName', !String.isBlank(oneProduct.Name) ? oneProduct.Name.toUpperCase() : null);
                    /*PPA Phase 2: DP-1025
                    Added LikeCatClass*/
                    outputRec.put('LikeCatClass', false);
                    
                    if(mapCatClassRate.containsKey(key)) {
                        PPA_CatClass_Rate__c oneRate = mapCatClassRate.get(key);
                        
                        if(mapRentalCatClass.containsKey(key)) {
                            outputRec.put('isSelectable', false);
                            outputRec.put('RowColorClass' , 'slds-text-color_inverse-weak');
                            outputRec.put('EligibleDesc', 'No - Item already exists on the Price List');
                        }
                        else {
                            outputRec.put('isSelectable', true);
                            outputRec.put('EligibleDesc', 'Yes');                        
                        }
                        
                        outputRec.put('MinRate', oneRate.PPA_Min_Rate__c);
                        outputRec.put('NewDay', oneRate.PPA_New_Day__c);
                        outputRec.put('NewWeek', oneRate.PPA_New_Week__c);
                        outputRec.put('NewMonth', oneRate.PPA_New_Month__c);
                        outputRec.put('MinDay', oneRate.PPA_Min_Day__c);
                        outputRec.put('MinWeek', oneRate.PPA_Min_Week__c);
                        outputRec.put('MinMonth', oneRate.PPA_Min_Month__c);
                        outputRec.put('CatClassOwner', oneRate.PPA_CatClass_Owner__c);
                        outputRec.put('ApplyRateType', oneRate.PPA_Apply_Rate_Type__c);
                        outputRec.put('TopProduct', oneRate.PPA_Top_Product__c);
                    }
                    else {
                        outputRec.put('isSelectable', false);
                        outputRec.put('RowColorClass' , 'slds-text-color_inverse-weak');
                        outputRec.put('EligibleDesc', 'No - Please check with Rate Analytics');
                    }
                    returnVals.add(outputRec);
                }
            }

            for(string key1 : mapLikeCatClass.keySet()){
                PPA_Rental_CatClass__c oneCatClass = mapLikeCatClass.get(key1);
                Map<String, Object> outputRec = new Map<String, Object>();
                
                outputRec.put('Id', oneCatClass.Id );
                outputRec.put('Source', 'likeCatClass');
                outputRec.put('SuperCategory', oneCatClass.PPA_Super_Cat__c);
                outputRec.put('Category', oneCatClass.PPA_Product_Category__c);
                outputRec.put('SubCategory', oneCatClass.PPA_Sub_Cat__c);
                outputRec.put('CatClass', oneCatClass.PPA_CatClass__c);
                outputRec.put('ProductName', oneCatClass.PPA_Product_Name__c);
                outputRec.put('isSelectable', true); 
                outputRec.put('EligibleDesc', 'Yes');
                /*PPA Phase 2: DP-1025
                Added LikeCatClass*/
                outputRec.put('LikeCatClass', true);
                returnVals.add(outputRec);
            }
    	}
        catch(Exception e) {
            if(!Test.isRunningTest()) {
                throw new AuraException(e.getMessage());
            }
        }

        return returnVals;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> fetchHierarchyProducts() {
        List<Map<String,Object>> outputRecs = new List<Map<String,Object>>();
        
        for(Product_Hierarchy__c prodHier : [SELECT Id, Name, Parent_Code__c, RecordType.DeveloperName
                                               FROM Product_Hierarchy__c
                                              WHERE Product_Family_Type__c = 'Cat-Class'
                                              ORDER BY Name])
        {
            Map<String,String> oneRec = new Map<String,String>();
            oneRec.put('Id', prodHier.Id);
            oneRec.put('Name', prodHier.Name.toUpperCase());
            oneRec.put('Parent_Code__c', prodHier.Parent_Code__c);
            oneRec.put('RecordType', prodHier.RecordType.DeveloperName);
            outputRecs.add(oneRec);
        }

        return outputRecs;
    }

    @AuraEnabled
    public static void handleUpdateProducts(String updateProducts) {
        List<PPA_Rental_CatClass__c> catClassList = new List<PPA_Rental_CatClass__c>();
        
        try {
            if (!String.isBlank(updateProducts)) {
                List<Object> newValuesObject = (List<Object>) JSON.deserializeUntyped(updateProducts);
                
                for (Object obj : newValuesObject) {
                    Map<String, Object> recMap = (Map<String, Object>) obj;
                    String source = String.valueof(recMap.get('Source'));
    
                    system.debug(source);
                    
                    if (source.equals('likeCatClass')) {
                       PPA_Rental_CatClass__c recLikeUpdate = new PPA_Rental_CatClass__c();
                       recLikeUpdate.Id =(Id) recMap.get('recordId');
                       recLikeUpdate.PPA_Like_CatClass__c = false;
                       recLikeUpdate.PPA_CatClass_Added__c = true;
                       catClassList.add(recLikeUpdate);

                    } 
                    
                    if (source.equals('Product')) {
                        PPA_Rental_CatClass__c rentalCreate = new PPA_Rental_CatClass__c();
                        rentalCreate.PPA_Product__c = (Id) recMap.get('recordId');
                        rentalCreate.PPA_Price_List__c = (Id) recMap.get('priceListId');
                        
                        if(recMap.get('ApplyRateType') != null) {
	                        rentalCreate.PPA_Apply_Rate_Type__c = (Boolean) recMap.get('ApplyRateType');                            
                        }
                        
                        rentalCreate.PPA_CatClassOwner__c = (String) recMap.get('CatClassOwner');
                        rentalCreate.PPA_Min_Rate__c = (String) recMap.get('MinRate'); 
                        rentalCreate.PPA_New_Day__c = (Decimal) recMap.get('NewDay');
                        rentalCreate.PPA_New_Week__c = (Decimal) recMap.get('NewWeek');
                        rentalCreate.PPA_New_Month__c = (Decimal) recMap.get('NewMonth');
                        rentalCreate.PPA_Min_Day__c = (Decimal) recMap.get('MinDay');
                        rentalCreate.PPA_Min_Week__c = (Decimal) recMap.get('MinWeek');
                        rentalCreate.PPA_Min_Month__c = (Decimal) recMap.get('MinMonth');
                        rentalCreate.PPA_CatClass_Added__c = true;
                        rentalCreate.PPA_Like_CatClass__c = false;
                        
                        catClassList.add(rentalCreate);
                    } 
                }
    
                system.debug(catClassList);
                
                if (!catClassList.isEmpty()) {
                   upsert catClassList;
                }
            }
        } catch (Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_AddCatClassController');
            exceptionParams.put('MethodName', 'handleUpdateProducts');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);
        
            if(!Test.isRunningTest()) {
                throw new AuraHandledException(e.getMessage());                
            }
        }
    }
}