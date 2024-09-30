/*********************************************************************************************************************
* Apex Class: SBR_3_0_CrewSummaryOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to handle Crew Summary related calculation and operations  
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh        2023-01-10             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_CrewSummaryOperations {
    
    public static void updateQuoteDetails(List<Crew_Summary__c> newCrewSummaryList) {
        Set<Id> quoteIds = new Set<Id>();
        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        for (Crew_Summary__c crewSummary : newCrewSummaryList) {
            if(crewSummary.Quote__c!=null){
                quoteIds.add(crewSummary.Quote__c);
            }                
        }
        if(quoteIds.isEmpty()){
            return;
        }

        try {
            List<AggregateResult> aggregateResultList = SBR_3_0_CrewSummaryDA.getCrewSummaryAggregateList(quoteIds); 

            List<AggregateResult> otCountList = SBR_3_0_CrewSummaryDA.getOTCountFromCrewSummaryByQuoteIds(quoteIds); 
            Map<Id, Integer> otCountMap = new Map<Id, Integer>();
            for(AggregateResult agr1 : otCountList){
                otCountMap.put((Id)agr1.get('Id'), (Integer)agr1.get('otCountFromCs'));
            }

            List<AggregateResult> stCountList = SBR_3_0_CrewSummaryDA.getSTCountFromCrewSummaryByQuoteIds(quoteIds); 
            Map<Id, Integer> stCountMap = new Map<Id, Integer>();
            for(AggregateResult agr2 : stCountList){
                stCountMap.put((Id)agr2.get('Id'), (Integer)agr2.get('stCountFromCs'));
            }

            if(AggregateResultList != null && aggregateResultList.size() > 0 && !otCountList.isEmpty() && !stCountList.isEmpty()){ 
                for(AggregateResult aggr : aggregateResultList){
                            Id quoteID =  (String)aggr.get('Quote__c'); 
                            SBR_3_0_Log.setRelatedRecordId(quoteID); 
                            if(otCountMap.containsKey(quoteID)) {   
                                if(stCountMap.containsKey(quoteID)) {
                                    SBQQ__Quote__c quote=new SBQQ__Quote__c(id=quoteID); 
                                    Integer otCrewCount = (Integer)aggr.get('otCrewCount'); 
                                    Integer stCrewCount = (Integer)aggr.get('stCrewCount'); 

                                    // SAL-27000
                                    Integer otHoursCount = otCountMap.get(quoteID);
                                    Integer stHoursCount = stCountMap.get(quoteID);
                                    
                                    Decimal csStAvgSum = (Decimal)aggr.get('csStAvgSum'); 
                                    Decimal csOtAvgSum = (Decimal)aggr.get('csOtAvgSum');

                                    quote.ST_Average__c = csStAvgSum/stHoursCount;
                                    quote.OT_Average__c = csOtAvgSum/otHoursCount;
                                    
                                    quotesToUpdate.add(quote); 
                                }
                            }
                } 
            }

            if(!quotesToUpdate.isEmpty()){
                update quotesToUpdate;
            }
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }    
    }

    // This Method will create or update quote line items when crew summary record is created/updated
    public static void updateQuoteLineForScaffolding(List<Crew_Summary__c> newCrewSummaryList) {
        Set<Id> quoteIds = new Set<Id>();
        Set<String> setProductSKU = new Set<String>();
        Map<Id,Product2> mapProduct = new Map<Id,Product2>();
        String eLaborSKU = System.Label.E_Labor_Product_SKU;
        Map<Id,String> mapCrewIdProductSKU = new Map<Id,String>();

        for (Crew_Summary__c crewSummary : newCrewSummaryList) {
            if(crewSummary.Product_SKU__c!=null)
                setProductSKU.add(crewSummary.Product_SKU__c);
        }
        
        if(!setProductSKU.isEmpty())
            mapProduct = new Map<Id,Product2>([Select Product_SKU__c from Product2 Where Id in: setProductSKU]);

        for (Crew_Summary__c crewSummary : newCrewSummaryList) {
            if(crewSummary.Quote__c!=null && crewSummary.Product_SKU__c!=null && mapProduct.containsKey(crewSummary.Product_SKU__c) 
                && mapProduct.get(crewSummary.Product_SKU__c).Product_SKU__c == eLaborSKU) //SAL-26878,27341
            {
                quoteIds.add(crewSummary.Quote__c);
            }                
        }
        if(!quoteIds.isEmpty()){
            updateQuoteLines(quoteIds);
        }     
    }


    @future
    public static void updateQuoteLines( Set<Id> quoteIds)
    {   
        try {
            SBR_3_0_QuoteOperations.updateQuoteLines(quoteIds);
        } catch (Exception ex) {
            SBR_3_0_Log.logException(ex);
        } finally {
            SBR_3_0_Log.saveLog();
        }   
    }
  
}