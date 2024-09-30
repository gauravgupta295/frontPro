@isTest
public class SBR_3_0_Lead_Assignment_Test {
    
    static testMethod void getTerritoriesTest(){
        String lat='37.811954';
        String lon='-122.395924';
        String acc='account';
        Test.startTest();
        List<Object> terr=SBR_3_0_Lead_Assignment.getTerritories(lat, lon, acc);
        System.assert(terr.size()>0);
        Test.stopTest();  
    }
}