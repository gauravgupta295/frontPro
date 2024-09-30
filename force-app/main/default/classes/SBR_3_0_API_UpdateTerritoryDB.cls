public with sharing class SBR_3_0_API_UpdateTerritoryDB {
    private static final String APINAME = 'Territory_Account_Update';
    private static final String ACCOUNT = 'Account';
    private static final String PROJECT = 'Project';

    public static void sendAccount(String recordId, Integer rmAccountNum, Decimal lat, Decimal lon){

        WrapAccountReq wr = new WrapAccountReq();
        wr.recordId = recordId;
        if(rmAccountNum != null) {
            wr.prospectNumber = rmAccountNum; //without country code prefix;
        }
        wr.latitude = lat;
        wr.longitude = lon;
        wr.prospectType = ACCOUNT;

        System.debug('\n @@ req Account= ' + JSON.serializePretty(wr));
        String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(wr, true), APINAME, null);
    }

    public static void sendProject(String recordId, String projNum, Decimal lat, Decimal lon){

        WrapProjectReq wr = new WrapProjectReq();
        wr.recordId = recordId;
        wr.prospectNumber = projNum; 
        wr.latitude = lat;
        wr.longitude = lon;
        wr.prospectType = ACCOUNT;

        System.debug('\n @@ req Project= ' + JSON.serializePretty(wr));
        String resp = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(wr), APINAME, null);
    }

    public class WrapAccountReq {
    
        public String recordId = '';
        public Integer prospectNumber;
        public Decimal latitude = 0;
        public Decimal longitude = 0;
        public String prospectType = '';
    }

    public class WrapProjectReq {
    
        public String recordId = '';
        public String prospectNumber = '';
        public Decimal latitude = 0;
        public Decimal longitude = 0;
        public String prospectType = '';
    }
}