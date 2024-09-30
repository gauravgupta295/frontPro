public class SBR_3_0_AvailabilityController {
   

     //method to fetch alternate products for selected product
    static List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> getAlternateProducts(String productId, String companyCode) {
         Product2 product = SBR_3_0_ProductDA.getProductById(productId);
         List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> alternateItems = new List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();
 
         for (Product2 altItems : SBR_3_0_ProductDA.getAlternateProducts(productId, companyCode, product.Product_Sub_Category__c, product.Product_Hierarchy__r.Product_Hierarchy_Code__c)) {
             alternateItems.add(new SBR_3_0_SpotlightPanelCmpController.AddOn_Details(altItems));
         }
 
         return alternateItems;
     }

     @AuraEnabled(cacheable = true)
     public static String findAlternateProductsByLocation(String recordId,String productId, String companyCode,String branchNumber,String accountNumber){
        Map<String,String> result = new Map<String,String>();
        List<String> catClasses = new List<String>();
        // get alternate products in salesforce
        List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> alternateProducts =  getAlternateProducts(productId, companyCode);

        for(SBR_3_0_SpotlightPanelCmpController.AddOn_Details ao: alternateProducts){
            catClasses.add(ao.catClass);
        }
        // get availability
        String atiResponse = SBR_3_0_AvailabilityBadgeCmpController.getATI(recordId,JSON.serialize(catClasses));
        result.put('atiResponse',atiResponse);

        //get rates for location
        SBR_3_0_WrapAlternateItems.ATIResponse formattedATIResponse = atiResponse!=null ? (SBR_3_0_WrapAlternateItems.ATIResponse)JSON.deserialize(atiResponse,SBR_3_0_WrapAlternateItems.ATIResponse.class) : null;
        
        Map<String,String> productLocationMap = getProductLocationMap(formattedATIResponse,catClasses,branchNumber);

        SBR_3_0_API_RatesRequestWrapper ratesRequest = SBR_3_0_RatesController.getRatesRequest(productLocationMap,companyCode,accountNumber,null,branchNumber);
        String ratesResponse =  SBR_3_0_RatesController.callRatesAPI(JSON.serialize(ratesRequest,true),companyCode);

        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formattedResponse = new List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();

        formattedResponse = SBR_3_0_RatesController.formatRatesResponseForBulk(ratesResponse,alternateProducts,accountNumber,branchNumber);
        result.put('alternateProducts',JSON.serializePretty(formattedResponse)); 
        SBR_3_0_Log.saveLog();
        return JSON.serialize(result);
     }


      // Method to process the provided JSON data and create a map of Product IDs to Location IDs
    public static Map<String, String> getProductLocationMap(SBR_3_0_WrapAlternateItems.ATIResponse formattedResponse,List<String> productSkus,String branchNumber) {

        Map<String, String> productLocationMap = new Map<String, String>();
        if(formattedResponse == null){
            for(String product: productSKus){
                productLocationMap.put(product,branchNumber);
            }
        }

        // Extract product and location information
        if (formattedResponse!=null && formattedResponse.data!=null & formattedResponse.data.availabilityByTransactionType != null && !formattedResponse.data.availabilityByTransactionType.isEmpty()) {

            for(SBR_3_0_WrapAlternateItems.AvailabilityByTransactionType availabilityByTransactionType: formattedResponse.data.availabilityByTransactionType){
                for(SBR_3_0_WrapAlternateItems.AvailabilityByProduct productInfo: availabilityByTransactionType.availabilityByProducts){
                    String productId = productInfo.productId;
                
                    if (productInfo.availabilityByFulfillmentTypes != null && !productInfo.availabilityByFulfillmentTypes.isEmpty()) {
                        SBR_3_0_WrapAlternateItems.AvailabilityByFulfillmentType availability = productInfo.availabilityByFulfillmentTypes[0]; // Assuming there's only one fulfillment type
                        List<SBR_3_0_WrapAlternateItems.AvailabilityDetail> availabilityDetailsList = availability.availabilityDetails;
                        
                        if (availabilityDetailsList != null && !availabilityDetailsList.isEmpty()) {
                            SBR_3_0_WrapAlternateItems.AvailabilityDetail details = availabilityDetailsList[0]; // Assuming there's only one set of availability details
                            List<SBR_3_0_WrapAlternateItems.AvailabilityByLocation> locations = details.availabilityByLocations;
                            
                            if (locations != null && !locations.isEmpty()) {
                                SBR_3_0_WrapAlternateItems.AvailabilityByLocation locationInfo = locations[0]; // Assuming there's only one location
                                String locationId = locationInfo.locationId;
                                
                                // Populate the map with productId as key and locationId as value
                                productLocationMap.put(productId, locationId);
                            }else{

                                // Populate the map with productId as key and lastResortBranch as value
                                productLocationMap.put(productId,availabilityByTransactionType.lastResortBranch);
                            }
                        }
                    }
                }
            }
        }
        
        return productLocationMap;
    }


}