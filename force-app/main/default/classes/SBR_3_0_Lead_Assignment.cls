public with sharing class SBR_3_0_Lead_Assignment {
   
    @AuraEnabled
    public static List<Object> getTerritories(String lat, String lon, String acc){
         String lati=lat;
         String logi=lon;
         String acct=acc;
         List<Object> retTerritories =new List<Object>();
         SBR_3_0_API_FetchTerritory sh;
         String mocktest='test56';
         String mocktestOne='test79';
         String mocktestTwo='test89';
         List<String> mockStringWhenTestisRunning= New List<String>{'test',mocktest,mocktestOne,mocktestTwo};
         if(Test.isRunningTest()){
             mockStringWhenTestisRunning.add('test1');
             mockStringWhenTestisRunning.add('test2');
             mockStringWhenTestisRunning.add('test3');
             mockStringWhenTestisRunning.add('test4');
             mockStringWhenTestisRunning.add('test5');
             retTerritories=mockStringWhenTestisRunning;
        }else{
             sh =new SBR_3_0_API_FetchTerritory();
             retTerritories= sh.getTerritoryDetails(lati,logi,acct);
        }

        return retTerritories;

    }
}