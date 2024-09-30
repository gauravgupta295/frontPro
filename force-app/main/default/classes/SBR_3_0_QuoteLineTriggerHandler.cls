public with sharing class SBR_3_0_QuoteLineTriggerHandler extends SBR_3_0_TriggerHandler {
    
    public static Boolean beforeUpdateRecursiveCheck = false;
    public static Boolean beforeInsertRecursiveCheck = false;
    public static Boolean beforeDeleteRecursiveCheck = false;
    public static Boolean afterInsertRecursiveCheck = false;
    public static Boolean afterUpdateRecursiveCheck = false;
    public static Boolean afterDeleteRecursiveCheck = false;

    public override void beforeInsert() { 
        try{
        SBR_3_0_QuoteLineOperations.updateQuoteLineWithProduct(Trigger.New);
            SBR_3_0_QuoteLineOperations.updateShiftDurationNotes(Trigger.New);
            SBR_3_0_QuoteLineOperations.updateQuoteLinesWithMinValues(Trigger.New);
            SBR_3_0_QuoteLineOperations.updateSellingPrice(Trigger.New);
            // SAL-27320
            SBR_3_0_QuoteLineOperations.updateQuoteLineProductSKUTextBI(Trigger.New);
            // SAL-27320
            SBR_3_0_QuoteLineOperations.updateLineItemTypeIfNullBI(Trigger.New);
            // SAL-27426
            SBR_3_0_QuoteLineOperations.updateLineItemQtyForRateQuote(Trigger.New);
            SBR_3_0_QuoteLineOperations.updateFuelPlanLineItemsFromRentalMan(Trigger.New);
            //SF-5309
            SBR_3_0_QuoteLineOperations.updateUserAddedField((List<SBQQ__QuoteLine__c>)Trigger.New);
        }
    catch(Exception e){
        SBR_3_0_Log.logException(e);
    }finally{
        //below method will publish all logs into Log object
         SBR_3_0_Log.saveLog();
        }
    }

    
    public override void afterInsert() { 
        try{
            if(!SBR_3_0_QuoteLineTriggerHandler.afterInsertRecursiveCheck) {  
                SBR_3_0_QuoteLineOperations.updateTotalQuoteId(Trigger.new);
                //SAL-26932
                SBR_3_0_QuoteLineOperations.updateTotalOnContingencyCatClass((Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,(List<SBQQ__QuoteLine__c>)Trigger.New);
                SBR_3_0_QuoteLineOperations.updateQuoteHeaderSpecificPricingFlag(Trigger.new);
                if(!Test.isRunningTest()){
                    SBR_3_0_QuoteLineOperations.updateQuoteStaleTotals((List<SBQQ__QuoteLine__c>)Trigger.New);
                }
                // SAL-27040 - commented by SAL-27320 fix
                //SBR_3_0_QuoteLineOperations.updateQuoteLineProductSKUText((List<SBQQ__QuoteLine__c>)Trigger.New);
                SBR_3_0_QuoteLineTriggerHandler.afterInsertRecursiveCheck = true;
            } 
        }catch(Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            //below method will publish all logs into Log object
             SBR_3_0_Log.saveLog();
        }
       
        // SAL-26036 - commented by SAL-27320 fix
        //SBR_3_0_QuoteLineOperations.updateLineItemTypeIfNull((List<SBQQ__QuoteLine__c>)Trigger.New);
    }    

    public override void beforeUpdate() {
        try{
            if(!SBR_3_0_QuoteLineTriggerHandler.beforeUpdateRecursiveCheck) { 
                SBR_3_0_QuoteLineOperations.updateQuoteHeaderWithTimeStamp(Trigger.New, Trigger.oldMap);
               //SAL-26762
                SBR_3_0_QuoteLineOperations.updateQuoteLinesWithMinValues(Trigger.New);
                SBR_3_0_QuoteLineOperations.updateSellingPrice(Trigger.New);
                // change for SAL-19006 - BD 
                SBR_3_0_QuoteLineOperations.updateRateOverridden(Trigger.New);
                // here quote method
                SBR_3_0_QuoteLineOperations.updateQuoteHeaderSpecificPricingFlag(Trigger.new);
                // SAL-27426
                SBR_3_0_QuoteLineOperations.updateLineItemQtyForRateQuote(Trigger.New);
                SBR_3_0_QuoteLineOperations.updateFuelPlanLineItemsFromRentalMan(Trigger.New);
                SBR_3_0_QuoteLineTriggerHandler.beforeUpdateRecursiveCheck = true;
            } 
        }
        catch(Exception e){
        SBR_3_0_Log.logException(e);
        }finally{
        //below method will publish all logs into Log object
         SBR_3_0_Log.saveLog();
        }
    }
    

    public override void afterUpdate() {
        try{
            if(!SBR_3_0_QuoteLineTriggerHandler.afterUpdateRecursiveCheck) {  
                //SAL-26932
                SBR_3_0_QuoteLineOperations.updateTotalOnContingencyCatClass((Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,(List<SBQQ__QuoteLine__c>)Trigger.New);
                //SF-5330
                SBR_3_0_QuoteLineOperations.updateQuantityonChildLineToMatchParent((Map<Id,SBQQ__QuoteLine__c>)Trigger.oldMap,(List<SBQQ__QuoteLine__c>)Trigger.New);
                SBR_3_0_QuoteLineOperations.removeChildFuelPlanIfParentUnchecked(Trigger.New, Trigger.oldMap); //SF-5291,SF-5292
                SBR_3_0_QuoteLineTriggerHandler.afterUpdateRecursiveCheck = true;
            }
        }
        catch(Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            //below method will publish all logs into Log object
             SBR_3_0_Log.saveLog();
        }
        
    }

    public override void beforeDelete() {
        if(!SBR_3_0_QuoteLineTriggerHandler.beforeDeleteRecursiveCheck) {  
            SBR_3_0_QuoteLineOperations.removeQuoteHeaderSpecificPricingFlag(Trigger.oldMap);
            SBR_3_0_QuoteLineTriggerHandler.beforeDeleteRecursiveCheck = true;
        }
    }
    public override void afterDelete() {
        try{
            if(!SBR_3_0_QuoteLineTriggerHandler.afterDeleteRecursiveCheck) {  
                SBR_3_0_QuoteLineOperations.updateTotalOnContingencyCatClass(null,Trigger.old);
                if(!Test.isRunningTest()){
                    SBR_3_0_QuoteLineOperations.updateQuoteStaleTotals((List<SBQQ__QuoteLine__c>)Trigger.old); //SAL-27196
                }
                SBR_3_0_QuoteLineOperations.uncheckFuelPlanCheckBox((List<SBQQ__QuoteLine__c>)Trigger.old); //SF-5291,SF-5292
                SBR_3_0_QuoteLineTriggerHandler.afterDeleteRecursiveCheck = true;
            }
        }
        catch(Exception e){
            SBR_3_0_Log.logException(e);
        }finally{
            //below method will publish all logs into Log object
             SBR_3_0_Log.saveLog();
        }
    }
}