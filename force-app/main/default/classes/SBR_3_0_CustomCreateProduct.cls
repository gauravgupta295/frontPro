public with sharing class SBR_3_0_CustomCreateProduct {
    private String returnVal {get; set;}
    private ProductRequestWrapper prodReqWrapper {get; set;}
    private RelatedRecordsWrapper relRecordsWrapper {get; set;}
    private final String PRODUCT2 = 'Product2';
    private final String EXTERNAL_ID = 'Product_SKU__c';
    private final String E_SKU = 'e-sku';

    public SBR_3_0_CustomCreateProduct(String req){
        prodReqWrapper = (ProductRequestWrapper)JSON.deserializeStrict(req, ProductRequestWrapper.class);
        relRecordsWrapper = new RelatedRecordsWrapper();
    }

    public String createUpdateProduct() {
        validateProduct();
        validateAndGetRelatedRecords();

        Map<String, Product_Message__c> prodMessagesToDelete;
        Map<String, SBQQ__ProductFeature__c> prodFeaturesToDelete;
        Map<String, SBQQ__ProductOption__c> prodOptionsToDelete;
        
        Id prodId = getProductId();
        Product2 prodToUpsert = prodReqWrapper.data;
        Boolean isUpdate = true;

        if(prodId == null) {
            prodToUpsert.RecordtypeId = getRecordTypeId();
            insert prodToUpsert;
            prodReqWrapper.data.Id = prodToUpsert.Id;
            isUpdate = false;
        }
        else {
            prodReqWrapper.data.Id = prodId;
             //Update
            SBR_3_0_UpdateNewAndClearOtheFields runUpsert =  
                new SBR_3_0_UpdateNewAndClearOtheFields(PRODUCT2, new List<Product2> {prodToUpsert}, EXTERNAL_ID);
            runUpsert.updateNewAndNillOtherFields();

            //Get Related message to delete first. We'll delete if they exist and then reinsert since data may have changed.
            prodMessagesToDelete = SBR_3_0_ProductDA.getProductMessages(prodId);
            prodFeaturesToDelete = SBR_3_0_ProductDA.getProductFeatures(prodId);
            prodOptionsToDelete = SBR_3_0_ProductDA.getProductOptions(prodId);
        }

        if(isUpdate) {
            //need to check for deleteion only if product is existing
            //delete related records
            if(prodMessagesToDelete != null && !prodMessagesToDelete.isEmpty()) { 
                delete prodMessagesToDelete.values();
            }
            if(prodFeaturesToDelete != null && !prodFeaturesToDelete.isEmpty()) { 
                delete prodFeaturesToDelete.values();
            }
            if(prodOptionsToDelete != null && !prodOptionsToDelete.isEmpty()) { 
                delete prodOptionsToDelete.values();
            }
        }

        //Get Related to Insert (need to insert or reinsert if Product is new or updated respectively )
        List<Product_Message__c> prodMessagesToInsert = generateProductMessages(prodToUpsert);
        if(prodMessagesToInsert != null && !prodMessagesToInsert.isEmpty()) { 
            insert prodMessagesToInsert;
        }
        Map<String, SBQQ__ProductFeature__c> productFeaturesToInsert = generateProductFeatures(prodToUpsert);
        if(productFeaturesToInsert != null && !productFeaturesToInsert.isEmpty()) { 
            List<SBQQ__ProductFeature__c> prodFeatures = productFeaturesToInsert.values();
            insert prodFeatures;
            for(SBQQ__ProductFeature__c feat: prodFeatures){
                productFeaturesToInsert.put(feat.Name, feat);
            }
        }
        List<SBQQ__ProductOption__c> prodOptionsToInsert = generateProductOptions(prodToUpsert, productFeaturesToInsert);
        if(prodOptionsToInsert != null && !prodOptionsToInsert.isEmpty()) { 
            insert prodOptionsToInsert;
        }
        return 'Success';
    }

    private Id getProductId() {
        System.debug('@@sku =' + prodReqWrapper.data.Product_SKU__c);
        Map<String, Product2> existing = SBR_3_0_ProductDA.getProductByExternalId(new Set<String> {prodReqWrapper.data.Product_SKU__c});
        System.debug('@@existing prod =' + existing);
        if(!existing.isEmpty()){ 
            return existing.values()[0].Id;
        }
        return null;
    }

    private String getRecordTypeId() {
        return prodReqWrapper.data.Product_Type__c.equalsIgnoreCase(E_SKU) ? 
            SBR_3_0_Constants.PRODUCT_REC_TYPE_ESKU_ID : SBR_3_0_Constants.PRODUCT_REC_TYPE_SKU_ID;
    }

    private void validateProduct() {
        if(prodReqWrapper.data.Product_SKU__c == null) {
            throw new SBR_3_0_CustomCreateProduct_Exception('Product SKU cannot be null');
        }
        if(prodReqWrapper.data.Product_Type__c == null){
            throw new SBR_3_0_CustomCreateProduct_Exception('Product Type cannot be null');
        }
    }
    
    private void validateAndGetProductHierarchy(){
        // Check if Product Hierarchy Exist
        Product_Hierarchy__c prodHierarchy;
        if(prodReqWrapper.hierarchyCode <> NULL){
            prodHierarchy = SBR_3_0_ProductDA.getProductHierarchyByCode(prodReqWrapper.hierarchyCode);
            if(prodHierarchy == NULL){ throw new SBR_3_0_CustomCreateProduct_Exception('Specified Product Hierarchy does not exist in Salesforce!');}
        }
        prodReqWrapper.data.Product_Hierarchy__c = prodHierarchy.Id;
        prodReqWrapper.data.Product_Category_Txt__c = prodHierarchy.Parent_Code__r.Name; //SAL-26801
        prodReqWrapper.data.Product_Sub_Category_Txt__c = prodHierarchy.Name; //SAL-26801
        prodReqWrapper.data.Filter_Level_1_Txt__c = 
            (prodHierarchy.Parent_Code__r.Parent_Code__r.Filter_Level__c == 'N/A') ? 
            prodHierarchy.Parent_Code__r.Name : prodHierarchy.Parent_Code__r.Parent_Code__r.Name; //SAL-26801
        relRecordsWrapper.productHierarchy = prodHierarchy;
    }
    
    private void validateAndGetRelatedRecords(){
        // Check if product hierarchy exists
        validateAndGetProductHierarchy();
        // Check if Messages Exists
        validateAndGetMessages();
        // Check and Validate Product Options
        validateAndGetProductOptions();
    }

    private void validateAndGetMessages(){
        // Check if Messages Exist
        Set<String> screenMessages = String.isNotEmpty(prodReqWrapper.screenMessages) ? new Set<String>(prodReqWrapper.screenMessages.split(',')) : new Set<String>();
        relRecordsWrapper.screenMessages = screenMessages;
        Set<String> printMessages = String.isNotEmpty(prodReqWrapper.printMessages) ? new Set<String>(prodReqWrapper.printMessages.split(',')) : new Set<String>();
        relRecordsWrapper.printMessages = printMessages;
        Set<String> allMessagesSet = new Set<String>(screenMessages);
        allMessagesSet.addAll(printMessages);
        Map<String, Message__c> messagesRecords = new Map<String, Message__c>();
        if(!screenMessages.isEmpty() || !printMessages.isEmpty()){
            messagesRecords = SBR_3_0_ProductDA.getMessageRecordsByExternalId(allMessagesSet);
            for(String msgExternalId: allMessagesSet){
                if(!messagesRecords.containsKey(msgExternalId)) {throw new SBR_3_0_CustomCreateProduct_Exception('Message with Id ' + msgExternalId + ' does not exist in Salesforce!');}
            }
        }
        relRecordsWrapper.messagesRecords = messagesRecords;
    }

    private void validateAndGetProductOptions(){
        // Check if Product Option.Optional SKU exist
         Map<String, String> optionProductFeatureMap = new Map<String, String>();
         Set<String> optionalProductsSku = new Set<String>();

         Set<String> suggestedOptionProductSkus = new Set<String>();
         Set<String> forcedOptionProductSkus = new Set<String>();
         Set<String> kitOptionProductSkus = new Set<String>();

         Map<String, Product2> optionalProductsMap = new Map<String,Product2>();
         Map<String, String> productFeatureMap = new Map<String, String>();

         // Suggested Options
         if(prodReqWrapper.options_suggested <> NULL && !prodReqWrapper.options_suggested.isEmpty()){
            for(SBQQ__ProductOption__c prodOption: prodReqWrapper.options_suggested){
                if(prodOption.Product_Optional_SKU__c <> NULL)
                {
                    if(!prodReqWrapper.data.Product_SKU__c.equalsIgnoreCase(prodOption.Product_Optional_SKU__c.substringBetween('-','-'))){
                        throw new SBR_3_0_CustomCreateProduct_Exception('Option Product with SKU ' + prodOption.Product_Optional_SKU__c + ' does not belong to this product!');
                    }
                    String optionProdctSku = prodOption.Product_Optional_SKU__c.substringAfterLast('-');
                    optionalProductsSku.add(optionProdctSku);
                    suggestedOptionProductSkus.add(optionProdctSku);
                }
            }
         }
         // Forced Options
         if(prodReqWrapper.options_forced <> NULL && !prodReqWrapper.options_forced.isEmpty()){
            for(SBQQ__ProductOption__c prodOption: prodReqWrapper.options_forced){
                if(prodOption.Product_Optional_SKU__c <> NULL)
                {
                    if(!prodReqWrapper.data.Product_SKU__c.equalsIgnoreCase(prodOption.Product_Optional_SKU__c.substringBetween('-','-'))){
                        throw new SBR_3_0_CustomCreateProduct_Exception('Option Product with SKU ' + prodOption.Product_Optional_SKU__c + ' does not belong to this product!');
                    }
                    String optionProdctSku = prodOption.Product_Optional_SKU__c.substringAfterLast('-');
                    optionalProductsSku.add(optionProdctSku);
                    forcedOptionProductSkus.add(optionProdctSku);
                }
            }
         }
          // Kit Options
          if(prodReqWrapper.options_kit <> NULL && !prodReqWrapper.options_kit.isEmpty()){
            for(SBQQ__ProductOption__c prodOption: prodReqWrapper.options_kit){
                if(prodOption.Product_Optional_SKU__c <> NULL)
                {
                    if(!prodReqWrapper.data.Product_SKU__c.equalsIgnoreCase(prodOption.Product_Optional_SKU__c.substringBetween('-','-'))){
                        throw new SBR_3_0_CustomCreateProduct_Exception('Option Product with SKU ' + prodOption.Product_Optional_SKU__c + ' does not belong to this product!');
                    }
                    String optionProdctSku = prodOption.Product_Optional_SKU__c.substringAfterLast('-');
                    optionalProductsSku.add(optionProdctSku);
                    kitOptionProductSkus.add(optionProdctSku);
                }
            }
         }

         if(!optionalProductsSku.isEmpty()){
            optionalProductsMap = SBR_3_0_ProductDA.getProductByExternalId(optionalProductsSku);
            for(String optionalSku: optionalProductsSku){
                if(!optionalProductsMap.containsKey(optionalSku)){
                    throw new SBR_3_0_CustomCreateProduct_Exception('Option Product with SKU ' + optionalSku + ' does not exist in Salesforce!');
                }
                Product2 optionProduct = optionalProductsMap.get(optionalSku);
                if(String.isEmpty(optionProduct.Product_Type__c)){
                    throw new SBR_3_0_CustomCreateProduct_Exception('Option Product with SKU ' + optionalSku + ' does not have product type field populated!');
                }

                if(suggestedOptionProductSkus.contains(optionalSku) || forcedOptionProductSkus.contains(optionalSku)){
                    if(optionProduct.Product_Type__c == 'Cat-Class'){
                        optionProductFeatureMap.put(optionalSku, 'Rental Addons');
                    } else {
                        optionProductFeatureMap.put(optionalSku, 'Sales Addons');
                    }
                } else if(kitOptionProductSkus.contains(optionalSku)){
                    optionProductFeatureMap.put(optionalSku, 'Kit Component');
                }
            }
        }

        relRecordsWrapper.optionProductsFeatureNames  = optionProductFeatureMap;
        relRecordsWrapper.optionalProducts = optionalProductsMap;
    }

    private List<Product_Message__c> generateProductMessages(Product2 mainProduct){
        Set<String> allMessagesSet = new Set<String>(relRecordsWrapper.screenMessages);
        allMessagesSet.addAll(relRecordsWrapper.printMessages);
        List<Product_Message__c> prodMessages= new List<Product_Message__c>();
        for(String msg: allMessagesSet){
            Product_Message__c prodMsgRecord = new Product_Message__c(
                Product_Message_Id__c = mainProduct.Product_SKU__c + '-' + relRecordsWrapper.messagesRecords.get(msg).Product_Message_Id__c,
                Product__c = mainProduct.Id,
                Message__c = relRecordsWrapper.messagesRecords.get(msg).Id,
                Message_Number__c = relRecordsWrapper.messagesRecords.get(msg).Message_Number__c,
                Product_SKU__c = mainProduct.Product_SKU__c
            );

            if(relRecordsWrapper.printMessages.contains(msg) && relRecordsWrapper.screenMessages.contains(msg)){
                prodMsgRecord.Print__c = true;
                prodMsgRecord.Screen__c = true;
            } else if(relRecordsWrapper.printMessages.contains(msg)){
                prodMsgRecord.Print__c = true;
                prodMsgRecord.Screen__c = false;
            } else if(relRecordsWrapper.screenMessages.contains(msg)){
                prodMsgRecord.Screen__c = true;
                prodMsgRecord.Print__c = false;
            }

            prodMessages.add(prodMsgRecord);
        }

        return prodMessages;
    }

    private Map<String, SBQQ__ProductFeature__c> generateProductFeatures(Product2 mainProduct){
        Map<String, SBQQ__ProductFeature__c> productFeatures = new Map<String, SBQQ__ProductFeature__c>();
        for(String featureStr: relRecordsWrapper.optionProductsFeatureNames.values()){
            SBQQ__ProductFeature__c featureObj = new SBQQ__ProductFeature__c(
                Name = featureStr,
                Product_Feature_Load_Ext_ID__c = mainProduct.Product_SKU__c + '_' + featureStr,
                SBQQ__ConfiguredSKU__c = mainProduct.Id,
                SBQQ__MinOptionCount__c = 1,
                SBQQ__Number__c = 1
            );
            productFeatures.put(featureStr, featureObj);
        }

        return productFeatures;
    }

    private List<SBQQ__ProductOption__c> generateProductOptions(Product2 mainProduct, Map<String, SBQQ__ProductFeature__c> features) {
        
        Map<String, SBQQ__ProductOption__c> productOptions = new Map<String, SBQQ__ProductOption__c>();
        productOptions.putAll( 
            generateOptionsFor(mainProduct, features, prodReqWrapper.options_suggested, false)
        );
        productOptions.putAll(
            generateOptionsFor(mainProduct, features, prodReqWrapper.options_forced, true)
        );
        productOptions.putAll(
            generateOptionsFor(mainProduct, features, prodReqWrapper.options_kit, false)
        );

        return productOptions.values();
        
    }

    private Map<String, SBQQ__ProductOption__c> generateOptionsFor(Product2 mainProduct, Map<String, SBQQ__ProductFeature__c> features, List<SBQQ__ProductOption__c> options, Boolean isRequired) {
        if(options != null && options.size()>0) {
            Map<String, SBQQ__ProductOption__c> productOptions = new Map<String, SBQQ__ProductOption__c>();
            integer i = 1;
            for(SBQQ__ProductOption__c prodOption: options){
                String optionalProducSku = prodOption.Product_Optional_SKU__c.substringAfterLast('-');
                // SAL-22442: filtering E-sku product options, so these product options are not created
                if(relRecordsWrapper.optionalProducts.get(optionalProducSku).RecordType.Name =='SKU'){
                    prodOption.SBQQ__ConfiguredSKU__c = mainProduct.Id;
                    prodOption.SBQQ__OptionalSKU__c = relRecordsWrapper.optionalProducts.get(optionalProducSku).Id;
                    prodOption.SBQQ__Quantity__c = prodOption.SBQQ__Quantity__c;
                    prodOption.SBQQ__Required__c = isRequired;
                    prodOption.SBQQ__Number__c = i;
                    i++;
                    if(relRecordsWrapper.optionProductsFeatureNames.containsKey(optionalProducSku)){
                        prodOption.SBQQ__Feature__c = features.get(relRecordsWrapper.optionProductsFeatureNames.get(optionalProducSku)).Id;
                    }                    
                    if(!productOptions.containsKey(prodOption.Product_Optional_SKU__c) ){
                        productOptions.put(prodOption.Product_Optional_SKU__c, prodOption);
                    }
                }                
            }
            return productOptions;
        }
        return new Map<String, SBQQ__ProductOption__c>();
    }

    public class ProductRequestWrapper {
        public String printMessages {get; set;}
        public String screenMessages {get; set;}
        public String hierarchyCode {get; set;}
        public List<SBQQ__ProductOption__c> options_suggested {get; set;}
        public List<SBQQ__ProductOption__c> options_forced {get; set;}
        public List<SBQQ__ProductOption__c> options_kit {get; set;}
        public Product2 data {get; set;}
    }

    public class RelatedRecordsWrapper {
        Product_Hierarchy__c productHierarchy {get; set;}
        Set<String> screenMessages {get; set;}
        Set<String> printMessages {get; set;}
        Map<String, Message__c> messagesRecords {get; set;}
        Map<String, Product2> optionalProducts {get; set;}
        Set<String> featureNames {get; set;}
        Map<String, String> optionProductsFeatureNames {get; set;}
    }

    public class SBR_3_0_CustomCreateProduct_Exception extends Exception {}
}