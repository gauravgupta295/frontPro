public with sharing class SBR_3_0_AvailabilityCmpController {
  public class AvailabilityListWrapper {
    @AuraEnabled
    public string catClass { get; set; }
    @AuraEnabled
    public List<AvailabilityWrapper> availabilityInfo { get; set; }

    public AvailabilityListWrapper() {
    }

    public AvailabilityListWrapper(
      String catClass,
      List<AvailabilityWrapper> availabilityInfo
    ) {
      this.availabilityInfo = availabilityInfo;
      this.catClass = catClass;
    }
  }

  public class AvailabilityWrapper {
    @AuraEnabled
    public string label { get; set; }
    @AuraEnabled
    public string available { get; set; }
    @AuraEnabled
    public string reserve { get; set; }
    @AuraEnabled
    public string pickUp { get; set; }
    @AuraEnabled
    public string utilization { get; set; }
    @AuraEnabled
    public string branchNumber { get; set; } //FRONT-8722 & 8721 Sending branch number to ui

    public AvailabilityWrapper() {
    }
  }

  @AuraEnabled
  public static List<AvailabilityListWrapper> getProductAvailabilities(
    List<String> products,
    string type,
    String locationInfo
  ) {
    List<AvailabilityListWrapper> infoByCatClass = new List<AvailabilityListWrapper>();
    //create rows in infoByCatClass and populate it's catClass attribute based on List<String> products
    Map<string, List<AvailabilityWrapper>> wrapperMap = new Map<string, List<AvailabilityWrapper>>();
    List<availabilityWrapper> availWrapper = getDefaultAvailability();
    for (String product : products) {
      wrapperMap.put(product, availWrapper);
    }
    Schema.location locationInformation = (Schema.location) JSON.deserialize(
      locationInfo,
      Schema.location.class
    );
    try {
      if (!products.isEmpty() && type.toLowerCase() == 'summary') {
        String completeProductsString =
          '\'' +
          String.join(products, '\',\'') +
          '\'';
        completeProductsString = '(' + completeProductsString + ')';
        System.debug('completed string = ' + completeProductsString);
        List<AggregateResult> availability = SBR_3_0_Api_Web_getAvailabilitySummary.getAvailabilitySummary(
          locationInformation.name,
          completeProductsString
        );
        if (availability != null) {
          for (AggregateResult result : availability) {
            System.debug(
              'getProductAvailabilities Aggregrate result: ' + result
            );
            AvailabilityWrapper newRow = new AvailabilityWrapper();

            List<AvailabilityWrapper> availabilityList = new List<AvailabilityWrapper>();
            // initiate new class
            MAP<String, Object> locationMap = result.getPopulatedFieldsAsMap();
            if (locationMap.containsKey('Branch')) {
              newRow.Label = 'Branch';
            } else if (locationMap.containsKey('District')) {
              newRow.Label = 'District';
            } else if (locationMap.containsKey('Region')) {
              newRow.Label = 'Region';
            } else if (locationMap.containsKey('Territory')) {
              newRow.Label = 'Territory';
            } else if (locationMap.containsKey('Company')) {
              newRow.Label = 'Company';
            }
            string catClass = (string) result.get('Cat_Class');
            System.debug('catClass: ' + catClass);
            decimal avail = 0;
            if (
              result.get('Quantity_Returned') == null ||
              result.get('Quantity_Returned') == 0
            ) {
              avail = (decimal) result.get('Quantity_Available');
            } else {
              avail =
                (decimal) result.get('Quantity_Available') +
                (decimal) result.get('Quantity_Returned');
            }
            System.debug('avail: ' + avail);
            newRow.available = avail != null
              ? String.valueOf(avail.intValue())
              : '0';
            System.debug('newRow.available: ' + newRow.available);
            decimal reserve;
            decimal pickUp;
            if (
              result.get('Quantity_Reserved') == null ||
              result.get('Quantity_Reserved') == 0
            ) {
              reserve = 0;
            } else {
              reserve = (decimal) result.get('Quantity_Reserved');
            }
            if (
              result.get('Quantity_on_Scheduled_Pick_Up') == null ||
              result.get('Quantity_on_Scheduled_Pick_Up') == 0
            ) {
              pickUp = 0;
            } else {
              pickUp = (decimal) result.get('Quantity_on_Scheduled_Pick_Up');
            }
            newRow.reserve = String.valueOf(reserve.intValue());
            newRow.pickUp = String.valueOf(pickUp.intValue());
            decimal utilUnformatted;
            if (
              result.get('Utilization') == null ||
              result.get('Utilization') == 0
            ) {
              utilUnformatted = 0;
            } else {
              utilUnformatted = (decimal) result.get('Utilization');
            }
            newRow.utilization =
              String.valueOf(utilUnformatted.intValue()) + '%';
            //add the newRow to the correct availabilityInfo list in infoByCatClass based on catClass
            List<AvailabilityWrapper> newAvList = new List<AvailabilityWrapper>();
            for (AvailabilityWrapper av : wrapperMap.get(catClass)) {
              if (av.Label == newRow.Label) {
                newAvList.add(newRow);
              } else {
                newAvList.add(av);
              }
            }
            wrapperMap.put(catClass, newAvList);
          }
        }

        for (String key : wrapperMap.keySet()) {
          AvailabilityListWrapper listWrapper = new AvailabilityListWrapper(
            key,
            wrapperMap.get(key)
          );
          infoByCatClass.add(ListWrapper);
        }
      } else if (
        !products.isEmpty() && type.toLowerCase() == 'district' ||
        type.toLowerCase() == 'region' ||
        type.toLowerCase() == 'territory' ||
        type.toLowerCase() == 'company'
      ) {
        System.debug('else if loop');
        List<AvailabilityWrapper> availabilityList = new List<AvailabilityWrapper>();
        // initiate new class
        AvailabilityListWrapper listWrapper = new AvailabilityListWrapper();
        for (String product : products) {
          String locationId = '';
          if (type.toLowerCase() == 'district')
            locationId = locationInformation.District__c;
          else if (type.toLowerCase() == 'region')
            locationId = locationInformation.Region__c;
          else if (type.toLowerCase() == 'territory')
            locationId = locationInformation.Territory__c;
          else if (type.toLowerCase() == 'company')
            locationId = locationInformation.Company__c;
          List<AggregateResult> availability = SBR_3_0_Api_Web_getAvailability.getAvailability(
            type,
            locationId,
            product
          );
          if (availability != null) {
            //FRONT-8722 this check prevents script execution errors. Please don't remove.
            for (AggregateResult result : availability) {
              AvailabilityWrapper newRow = new AvailabilityWrapper();
              MAP<String, Object> locationMap = result.getPopulatedFieldsAsMap();
              String branchNumber = (String) locationMap.get('Branch');
              // branchNumber = branchNumber.substring(branchNumber.indexOf('PC'),branchNumber.length());
              //  branchNumber = branchNumber.replaceAll('\\D','');
              newRow.branchNumber = branchNumber; //FRONT-8722 & 8721 Sending branch number to ui
              System.debug(branchNumber);
              string catClass = product;
              newRow.Label = 'Branch ' + branchNumber;
              decimal avail = 0;
              if (
                result.get('Quantity_Returned') == null ||
                result.get('Quantity_Returned') == 0
              ) {
                avail = (decimal) result.get('Quantity_Available');
              } else {
                avail =
                  (decimal) result.get('Quantity_Available') +
                  (decimal) result.get('Quantity_Returned');
              }
              newRow.available = String.valueOf(avail.intValue());
              decimal reserve;
              decimal pickUp;
              if (
                result.get('Quantity_Reserved') == null ||
                result.get('Quantity_Reserved') == 0
              ) {
                reserve = 0;
              } else {
                reserve = (decimal) result.get('Quantity_Reserved');
              }
              if (
                result.get('Quantity_on_Scheduled_Pick_Up') == null ||
                result.get('Quantity_on_Scheduled_Pick_Up') == 0
              ) {
                pickUp = 0;
              } else {
                pickUp = (decimal) result.get('Quantity_on_Scheduled_Pick_Up');
              }
              newRow.reserve = String.valueOf(reserve.intValue());
              newRow.pickUp = String.valueOf(pickUp.intValue());
              decimal utilUnformatted;
              if (
                result.get('Utilization') == null ||
                result.get('Utilization') == 0
              ) {
                utilUnformatted = 0;
              } else {
                utilUnformatted = (decimal) result.get('Utilization');
              }
              newRow.utilization =
                String.valueOf(utilUnformatted.intValue()) + '%';
              availabilityList.add(newRow);
              listWrapper.catClass = catClass;
              listWrapper.availabilityInfo = availabilityList;
            }
            infoByCatClass.add(listWrapper);
          }
        }
      }
      System.debug('infoByCatClass: ' + infoByCatClass);
      return infoByCatClass;
    } catch (Exception e) {
      String errorMsg = e.getMessage() + e.getLineNumber();
      System.debug(errorMsg);
      throw new AuraHandledException(errorMsg);
    }
  }

  // Setting default values for Product Availabilities
  private static List<AvailabilityWrapper> getDefaultAvailability() {
    List<AvailabilityWrapper> availWrapper = new List<AvailabilityWrapper>();
    List<string> stringList = new List<String>{
      'Branch',
      'District',
      'Region',
      'Territory',
      'Company'
    };
    for (String str : stringList) {
      AvailabilityWrapper avWrap = new AvailabilityWrapper();
      avWrap.available = '0';
      avWrap.pickUp = '0';
      avWrap.reserve = '0';
      avWrap.utilization = '0%';
      avWrap.label = str;
      availWrapper.add(avWrap);
    }
    return availWrapper;
  }
}