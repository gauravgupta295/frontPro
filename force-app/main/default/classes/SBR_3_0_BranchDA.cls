/*********************************************************************************************************************
* Apex Class: SBR_3_0_BranchDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Branch/Location/Profit Center Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Kunal Patel           2022-04-12            Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_BranchDA implements SBR_3_0_BranchDAInterface {
  public static Map<Id, Schema.Location> getBranches() {
    return new Map<Id, Schema.Location>(
      [
        SELECT
          Id,
          Name,
          Street_Address__c,
          City__c,
          State__c,
          Zip_Code__c,
          Country__c,
          Latitude_Longitude__c
        FROM Location
      ]
    );
  }

  public static Map<Id, Schema.Location> getLocationsByIds(
    Set<Id> locationIds
  ) {
    return new Map<Id, Schema.Location>(
      [
        SELECT
          Id,
          Name,
          Street_Address__c,
          City__c,
          State__c,
          Zip_Code__c,
          Country__c,
          Latitude_Longitude__Latitude__s,
          Latitude_Longitude__Longitude__s,
          District__c,
          Region__c,
          Territory__c,
          Company__C,
          OMS_Sourcing_Enabled__c,
          Branch_Location_Number__c
        FROM Location
        WHERE Id IN :locationIds
      ]
    );
  }

  public static Map<Id, Schema.Location> getLocationReadinessFields(
    Set<Id> locationIds
  ) {
    return new Map<Id, Schema.Location>(
      [
        SELECT
          Id,
          Plant_Ready_Required__c,
          Event_Ready_Required__c,
          Airport_Personnel_Badge_Required__c,
          Airport_Vehicle_Badge_Required__c,
          All_gauges_and_controls_must_work_proper__c,
          All_lights_and_alarms_must_work_properly__c,
          Annual_Inspection_must_be_up_to_date__c,
          Anti_Entrapment__c,
          Beacon_Light_Required__c,
          Carb_Registration_Required__c,
          Containment_Berms__c,
          Copy_of_Owner_Manual_and_AEM_Required__c,
          COVID_Negative_Result_Required__c,
          COVID_Vaccination_Required__c,
          Dashboards_must_be_wiped_clean__c,
          Decals_Stencils_Must_Be_Legible__c,
          Equipment_must_be_extremely_clean__c,
          Facial_Hair_Restrictions__c,
          Fire_Extinguisher_Required__c,
          Generators_must_be_hand_wiped__c,
          Glass_must_be_intact_and_wiped_clean__c,
          Hard_Hats_Required__c,
          Headlights_Required__c,
          Motion_Beacons__c,
          No_Photography__c,
          No_visible_damage_to_the_machine__c,
          No_visible_signs_of_leaks__c,
          Non_Marking_Tires__c,
          OSHA_10_Required__c,
          OSHA_30_Required__c,
          Paint_must_be_close_to_perfect__c,
          Prevailing_Wage__c,
          Proximity_Alarms__c,
          Safety_Cones__c,
          Safety_Flags__c,
          Safety_Glasses_Required__c,
          Site_Specific_Crane_Inspection_Required__c,
          Site_Specific_Training_Required__c,
          Special_Back_up_Alarm_Required__c,
          Special_Decals_Required__c,
          Special_Tire_Tread_Requirements__c,
          Spill_Kits__c,
          State_of_MA_Code_Compliance_for_Heaters__c,
          Tier_4_Engine_Required__c,
          Tire_Covers__c,
          Tire_Shine_Required__c,
          Tires_must_be_in_good_condition__c,
          TWIC_Card_Required__c,
          Union_Personnel_Required__c,
          Water_Barriers_Required__c,
          Wheel_Chalks__c,
          Are_there_designated_routes_to_location__c,
          Delivery_timeslot_reservation_required__c,
          Drive_in_Ramp_Available__c,
          Escort_Required__c,
          Ground_Delivery__c,
          Loading_Dock__c,
          Personnel_must_be_US_Citizen__c,
          Personnel_Ramp_Available__c,
          Drip_Diapers__c
        FROM Location
        WHERE Id IN :locationIds
      ]
    );
  }

  public static List<Schema.Location> getBranchesFiltered(
    SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper
  ) {
    String sQuery =
      'SELECT Id, Name, Street_Address__c, City__c, State__c,' +
      ' Zip_Code__c, Country__c, Latitude_Longitude__c, RecordType.Name FROM Location WHERE RecordType.Name = \'Branch\' AND ';

    sQuery += 'Operational_Status__c = \'A\' AND ';

    if (String.isNotBlank(wrapper.branchSearch)) {
      sQuery +=
        '(Name LIKE \'%' +
        String.escapeSingleQuotes(wrapper.branchSearch) +
        '%\'' +
        ' OR Branch_Location_Number__c LIKE \'%' +
        String.escapeSingleQuotes(wrapper.branchSearch) +
        '%\'' +
        ' OR City__c LIKE \'%' +
        String.escapeSingleQuotes(wrapper.branchSearch) +
        '%\'' +
        ' OR Division__c LIKE \'%' +
        String.escapeSingleQuotes(wrapper.branchSearch) +
        '%\') AND ';
    }

    if (String.isNotBlank(wrapper.country) && wrapper.country != 'All') {
      sQuery +=
        'Country__c = \'' +
        String.escapeSingleQuotes(wrapper.country) +
        '\' AND ';
    }

    if (String.isNotBlank(wrapper.lineOfBusiness)) {
      List<String> lineOfBusinessList = (List<String>) JSON.deserialize(
        wrapper.lineOfBusiness,
        List<String>.class
      );
      Set<String> lineOfBusinessSet = new Set<String>(lineOfBusinessList);
      if (!lineOfBusinessSet.isEmpty() && !lineOfBusinessSet.contains('All')) {
        sQuery +=
          'Analysis_Region2__r.Name IN ' +
          inClausify(lineOfBusinessSet) +
          ' AND ';
      }
    }

    sQuery = sQuery.removeEnd(' WHERE ');
    sQuery = sQuery.removeEnd(' AND ');

    System.debug('sQuery -> ' + sQuery);

    List<Schema.Location> result = new List<Schema.Location>();

    //SAL-26375
    System.debug('loadbranchData = ' + wrapper.loadBranchData);
    if (wrapper.loadBranchData == true) {
      result = Database.query(sQuery);
    }

    return result;
  }

  public static List<Schema.Location> getLoggedInUserLocation() {
    /* FRONT-12298 : Added branch short name*/
    return new List<Schema.Location>(
      [
        SELECT
          L.id,
          L.name,
          L.Branch_Location_Number__c,
          L.Company_Code__c,
          L.Time_Zone_Id__c,
          City__c,
          State__c,
          Zip_Code__c,
          District__c,
          Region__c,
          Territory__c,
          Company__C,
          OMS_Sourcing_Enabled__c,
          Phone__c,
          Company_ID__c,
          Latitude_Longitude__c,
          Latitude_Longitude__Latitude__s,
          Latitude_Longitude__longitude__s,
          Country__c,
          Branch_Short_Name__c
        FROM Location L
        WHERE
          L.id IN (
            SELECT Branch__c
            FROM User_Location__c UL
            WHERE User__c = :UserInfo.getUserId()
          )
      ]
    );
  }

  // ayoub
  public static List<Schema.Location> getLoggedInUserProfileBranchLocation() {
    return new List<Schema.Location>(
      [
        SELECT
          L.id,
          L.name,
          L.Time_Zone_Id__c,
          L.Branch_Location_Number__c,
          L.Company_Code__c,
          City__c,
          State__c,
          Zip_Code__c,
          District__c,
          Market_Name__c,
          Region__c,
          Territory__c,
          Company__C,
          OMS_Sourcing_Enabled__c,
          Phone__c,
          Company_ID__c,
          Latitude_Longitude__c,
          Latitude_Longitude__Latitude__s,
          Latitude_Longitude__longitude__s,
          Country__c,
          Branch_Short_Name__c
        FROM Location L
        WHERE
          L.id IN (
            SELECT ProfileBranche__c
            FROM User_Location__c UL
            WHERE User__c = :UserInfo.getUserId()
          )
      ]
    );
  }

  // hamza
  public static List<Schema.Location> getSourcingBranchLocation(Id srcBranch) {
    /* FRONT-12298 : Added branch short name*/
    return new List<Schema.Location>(
      [
        SELECT
          L.id,
          L.name,
          L.Time_Zone_Id__c,
          L.Branch_Location_Number__c,
          L.Company_Code__c,
          City__c,
          State__c,
          Zip_Code__c,
          District__c,
          Market_Name__c,
          Region__c,
          Territory__c,
          Company__C,
          OMS_Sourcing_Enabled__c,
          Phone__c,
          Company_ID__c,
          Latitude_Longitude__c,
          Latitude_Longitude__Latitude__s,
          Latitude_Longitude__longitude__s,
          Country__c,
          Branch_Short_Name__c
        FROM Location L
        WHERE L.id = :srcBranch
      ]
    );
  }

  //amy
  @AuraEnabled(cacheable=true)
  public static Map<String, Schema.Location> getBranchDetails(
    List<String> branchNumbers
  ) {
    Map<String, Schema.Location> locs = new Map<String, Schema.Location>();
    for (Schema.Location loc : [
      SELECT id, name, Branch_Location_Number__c, City__c, State__c, Zip_Code__c
      FROM Location
      WHERE
        Branch_Location_Number__c IN :branchNumbers
        AND RecordType.Name = 'Branch'
    ]) {
      locs.put(loc.Branch_Location_Number__c, loc);
    }
    return locs;
  }

  @AuraEnabled(cacheable=false)
  public static Schema.Location getLocation(Id id) {
    //11775, adding Latitude & Longitude fields, SADAPUR
    return [
      SELECT
        ID,
        Street_Address__c,
        City__c,
        State__c,
        Zip_Code__c,
        Latitude_Longitude__c,
        Latitude_Longitude__Longitude__s,
        Latitude_Longitude__Latitude__s,
        Country__c
      FROM Location
      WHERE ID = :id
    ];
  }
  @AuraEnabled(cacheable=true)
  public static String getBranchesLineOfBusinesses() {
    Map<String, Set<String>> lineOfBusinessesByCountry = new Map<String, Set<String>>();
    List<Schema.Location> locations = [
      SELECT Country__c, Analysis_Region2__r.Name
      FROM Location
      WHERE Analysis_Region2__c != NULL AND Country__c != NULL
    ];

    for (Schema.Location mLocation : locations) {
      String country = mLocation.Country__c;
      String regionName = mLocation.Analysis_Region2__r.Name;

      if (!lineOfBusinessesByCountry.containsKey(country)) {
        lineOfBusinessesByCountry.put(country, new Set<String>());
      }
      lineOfBusinessesByCountry.get(country).add(regionName);
    }

    List<Map<String, Object>> resultList = new List<Map<String, Object>>();
    for (String country : lineOfBusinessesByCountry.keySet()) {
      Map<String, Object> countryData = new Map<String, Object>();
      countryData.put('country', country);
      countryData.put(
        'lobs',
        new List<String>(lineOfBusinessesByCountry.get(country))
      );
      resultList.add(countryData);
    }

    return JSON.serialize(resultList);
  }

  public static List<Schema.Location> getBranchPhones(List<String> pcs) {
    return new List<Schema.Location>(
      [
        SELECT
          L.id,
          L.name,
          L.Branch_Location_Number__c,
          Phone__c,
          L.Time_Zone_Id__c
        FROM Location L
        WHERE L.Branch_Location_Number__c IN :pcs
      ]
    );
  }

  public static Map<String, Schema.Location> getBranchByNumbers(
    Set<String> branchNumbers
  ) {
    Map<String, Schema.Location> branches = new Map<String, Schema.Location>();

    for (Schema.Location l : [
      SELECT Id, Time_Zone__c, Branch_Location_Number__c
      FROM Location
      WHERE
        Branch_Location_Number__c IN :branchNumbers
        AND Recordtype.Name = :SBR_3_0_Constants.LOCATION_REC_TYPE_BRANCH
    ]) {
      branches.put(l.Branch_Location_Number__c, l);
    }
    return branches;
  }

  @AuraEnabled(cacheable=true)
  public static List<Schema.Location> getBranchByBranchNumber(
    String branchDisplayName
  ) {
    System.debug('branchDisplayName @@' + branchDisplayName);
    return new List<Schema.Location>(
      [
        SELECT
          L.id,
          L.name,
          L.Time_Zone_Id__c,
          L.Branch_Location_Number__c,
          L.Company_Code__c,
          City__c,
          State__c,
          Zip_Code__c,
          District__c,
          Region__c,
          Territory__c,
          Company__C,
          OMS_Sourcing_Enabled__c,
          Phone__c,
          Company_ID__c,
          Latitude_Longitude__c,
          Latitude_Longitude__Latitude__s,
          Latitude_Longitude__longitude__s,
          Country__c
        FROM Location L
        WHERE L.Branch_Location_Number__c = :branchDisplayName
        LIMIT 1
      ]
    );
  }

  public static String inClausify(Set<String> stringSet) {
    String inClause = String.format(
      '(\'\'{0}\'\')',
      new List<String>{ String.join(new List<String>(stringSet), '\',\'') }
    );
    return inClause;
  }
}