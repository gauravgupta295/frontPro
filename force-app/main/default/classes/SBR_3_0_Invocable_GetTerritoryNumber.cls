public without sharing class SBR_3_0_Invocable_GetTerritoryNumber {
    @InvocableMethod(
        label='Get Territory Number'
        description='Use with the Invocable_RepsByTerritory class to retrieve territory number once a rep has been selected in the flow'
    )
    public static List<Response> getTerritoryNumber(List<Request> requests) {
        Map<String, String> repTerritoryMap = new Map<String, String>();
        Request request = requests[0];
        String colon = ':';
        List<Response> responses = new List<Response>();
        Response response = new Response();
        for (String s : request.repAndTerritoryMap) {
            String repId = s.substringBefore(colon);
            String territoryNumber = s.substringAfter(colon);
            repTerritoryMap.put(repId, territoryNumber);
        }
        response.territoryNumber = repTerritoryMap.get(request.selectedRepId);
        responses.add(response);
        return responses;
    }

    public class Request {
        @InvocableVariable(label='Rep and territory map' required=false)
        public List<String> repAndTerritoryMap;
        @InvocableVariable(label='Selected Rep Id')
        public String selectedRepId;
    }

    public class Response {
        @InvocableVariable(label='Territory Number')
        public String territoryNumber;
    }
}