global class SBR_3_0_BatchAddPriceBookEntries implements Database.Batchable<sObject> {
    Integer mins = -5;

    public SBR_3_0_BatchAddPriceBookEntries() {
    }

    global SBR_3_0_BatchAddPriceBookEntries(Integer mins) {
        this.mins = mins;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {

        Datetime minutesAgo = System.now().addMinutes(mins);

        String query = 
            'SELECT Id, Company_Code__c FROM Product2 WHERE LastModifiedDate >= :minutesAgo';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope){
        try {
            Map<String,String> ccToCurrency = getCompanyAndCurrencies();
            Id pbId = getStandardPriceBookId();
            
            List<Pricebookentry> pbes = new List<Pricebookentry>();
            // Nitin - Start--PS-4438
            Set<Id> setprdct = new Set<Id>();
            for(Product2 p2 : (List<Product2>)scope) {
                setprdct.add(p2.Id);
            }
            Set<String> existingpbekey = new Set<String>();
            for(Pricebookentry pbe : [SELECT Id,Product2Id,Pricebook2Id,IsActive,UnitPrice,CurrencyIsoCode FROM Pricebookentry WHERE Pricebook2Id=:pbId AND IsActive = true AND UnitPrice = 0 AND 
                                      Product2Id in :setprdct]){
                existingpbekey.add(pbe.Product2Id+pbe.CurrencyIsoCode);
            }
            for(Product2 p2 : (List<Product2>)scope) {
                if(String.isNotBlank(p2.Company_Code__c)){
                    for (String cc : p2.Company_Code__c.split(';')) {
                        if(!existingpbekey.contains(p2.Id+ccToCurrency.get(cc))){
                            Pricebookentry pbe = new Pricebookentry (
                            Pricebook2Id = pbId,
                            IsActive = true,
                            UnitPrice = 0,
                            Product2Id = p2.Id,
                            CurrencyIsoCode = ccToCurrency.get(cc)
                        );
                           pbes.add(pbe); 
                        }
                        // Nitin - End -PS-4438
                    }
                }
            }

            if(!pbes.isEmpty()){
                upsert pbes; 
            }
        }   
        catch (Exception ex) {
            SBR_3_0_LogException.LogIt(ex, BC.getJobId());
        }
    }

    global void finish(Database.BatchableContext BC){
        String jobName = 'PBEJob';
        if (Test.isRunningTest()){
            Double jobSuffix = Math.random() * 255;
            jobName = 'Testing Batch PBEJob' + Datetime.Now().format() + String.valueOf(jobSuffix);
        }
        String cronId = System.ScheduleBatch(new SBR_3_0_BatchAddPriceBookEntries(), jobName, 1,200);
        //System.abortJob(cronId); 
    }

    private Id getStandardPriceBookId() {
        return [SELECT Id 
            FROM PriceBook2 
            WHERE IsStandard = true 
            LIMIT 1].Id;
    }

    private Map<String,String> getCompanyAndCurrencies() {
        Map<String,String> ccToCurrency = new Map<String,String>();
        for (Company_Currency__mdt companyInfo : [SELECT    
             Id, CurrencyIsoCode__c, Company_Code__c
             FROM Company_Currency__mdt]
        ) {
            ccToCurrency.put(companyInfo.Company_Code__c,companyInfo.CurrencyIsoCode__c);
        }
        return ccToCurrency;
    }
}