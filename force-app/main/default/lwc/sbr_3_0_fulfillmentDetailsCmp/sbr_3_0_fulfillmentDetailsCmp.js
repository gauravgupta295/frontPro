import { LightningElement, api, track } from "lwc";
import MOBILE_TEMPLATE from "./sbr_3_0_fulfillmentDetailsCmpMobile/sbr_3_0_fulfillmentDetailsCmpMobile.html";
import DESKTOP_TEMPLATE from "./sbr_3_0_fulfillmentDetailsCmpDesktop/sbr_3_0_fulfillmentDetailsCmpDesktop.html";
import getAssetFilteredRecords from "@salesforce/apex/SBR_3_0_AssetDA.getAssetFilteredRecords"; //Added by Gopal Raj
import LABELS from "c/sbr_3_0_customLabelsCmp";
import LOCATION_TEST_DATA from "@salesforce/label/c.SBR_3_0_LocationTestData";
import LOCATION_TEST_DATA1 from "@salesforce/label/c.SBR_3_0_LocationTestData1";

export default class Sbr_3_0_fulfillmentDetailsCmp extends LightningElement {
  @api isMobile;
  @api fulfillmentId;
  label = LABELS;
  testdatalabel = LOCATION_TEST_DATA;
  testdatalabel1 = LOCATION_TEST_DATA1;
  @api fulfillmentPercentage;

  //adding static data for now, this value will be brought in via the API in a later story
  //sourcingBranchValue = "GASTONIA PC051";
  //Added below logic for buisness demo purpose.Gopal Raj
  get sourcingBranchValue() {
    if (this.fulfillmentId === this.testdatalabel) {
       return "MAUI PC693";
    } else if (this.fulfillmentId === this.testdatalabel1) {
       return "CHARLOTTE PC0001 1-FT";
    } else if (this.fulfillmentId === "3") {
      return "RALEIGH PC0003";
    } else if (this.fulfillmentId === "4") {
      return "DULUTH PC0004";
    } else if (this.fulfillmentId === "5") {
      return "GREENSBORO PC0005 TST";
    } else if (this.fulfillmentId === "6") {
      return "CHAROLETTE";
    } else if (this.fulfillmentId === "7") {
      return "JACKSONVILLE PC007";
    } else if (this.fulfillmentId === "8") {
      return "WILMINGTON PC008";
    }else {
        return "";
      }
    }




















































































































  /*Added by Gopal Raj */
  @api locationNumber;
  @api catClassList;
  @api catClassRequestedQtyMap;
  @track catClasses;
  /*Addded by Gopal Raj*/

  generateCatClassLabel(id, description, qtyRequested, available) {
    return `Cat-Class ${id} ${description} (Qty Requested: ${qtyRequested} | Available: ${available})`;
  }

  handleNavigateToSourceBranchTable() {
    this.dispatchEvent(new CustomEvent("opensourcebranch", {}));
  }

  //accordion
  handleToggleSection(event) {
    this.activeSectionMessage =
      "Open section name:  " + event.detail.openSections;
  }

  connectedCallback() {
   
    console.log("locationNumber " + this.locationNumber);
    console.log("catClassList", JSON.stringify(this.catClassList));
    console.log(
      "catClassRequestQuantity",
      JSON.stringify(this.catClassRequestedQtyMap)
    );
    this.getAssetRecord();
  }

  render() {
    return this.isMobile ? MOBILE_TEMPLATE : DESKTOP_TEMPLATE;
  }

 
  getAssetRecord() {
    getAssetFilteredRecords({
      locationNumber: this.locationNumber,
      catClassList: this.catClassList
    })
      .then((value) => {
        console.log("getFilterAssets" + value);
        this.catClasses = [];
        let existingObj = 0;
        let assetDescription;
        value.forEach((obj) => {
          console.log("obj" + JSON.stringify(obj));
          if (typeof obj.SM_PS_Miscellaneous_Options__c === "undefined") {
            assetDescription = "";
          } else {
            assetDescription = obj.SM_PS_Miscellaneous_Options__c;
          }
          if (this.catClasses.length > 0) {
            existingObj = this.catClasses.find(
              (catClassObj) => catClassObj.catClass === obj.SM_PS_Cat_Class__c
            );
          }
          if (!existingObj) {
            let objCls = {};
            objCls.id = obj.Id;
            objCls.description = obj.SM_PS_Cat_Class_Description__c;
            objCls.available = 0;
            objCls.catClass = obj.SM_PS_Cat_Class__c;
            objCls.availableSize = 0;
            objCls.label = this.generateCatClassLabel(
              "",
              objCls.description,
              this.catClassRequestedQtyMap.get(objCls.catClass),
              objCls.available
            );
            objCls.statusList = [];

            let statusObj = {};
            statusObj.name = obj.Status;
            statusObj.listOfRecords = [];

            let listOfRecord = {};
            listOfRecord.name = obj.SM_PS_Make__c;
            listOfRecord.asset = "Asset #: " + obj.SM_PS_Asset_Id__c
            listOfRecord.description = "Asset Description: " + assetDescription;
            statusObj.listOfRecords.push(listOfRecord);
            statusObj.listOfRecordSize = statusObj.listOfRecords.length; //Size of status list of record
            statusObj.fullName =
              this.getStatusName(statusObj.name) +
              " (" +
              statusObj.listOfRecords.length +
              ") ";
            objCls.statusList.push(statusObj);

            if (statusObj.name === "AVAILABLE") {
              objCls.availableSize = statusObj.listOfRecordSize; //Added size attribute for header level population.
              objCls.label = this.generateCatClassLabel(
                "",
                objCls.description,
                this.catClassRequestedQtyMap.get(objCls.catClass),
                objCls.availableSize
              );
            }
            this.catClasses.push(objCls);
          } else {
            let statusObjFind = 0;
            statusObjFind = existingObj.statusList.find(
              (statusObjEle) => statusObjEle.name === obj.Status
            );
            if (!statusObjFind) {
              let statusObj = {};
              statusObj.name = obj.Status;
              statusObj.listOfRecords = [];

              let listOfRecord = {};
              listOfRecord.name = obj.SM_PS_Make__c;
              listOfRecord.asset = "Asset #: " + obj.SM_PS_Asset_Id__c
              listOfRecord.description = "Asset Description: " + assetDescription;
              statusObj.listOfRecords.push(listOfRecord);
              statusObj.listOfRecordSize = statusObj.listOfRecords.length; //Size of status list of record
              statusObj.fullName =
                this.getStatusName(statusObj.name) +
                " (" +
                statusObj.listOfRecords.length +
                ") ";

              if (statusObj.name === "AVAILABLE") {
                existingObj.availableSize = statusObj.listOfRecordSize; //Added size attribute for header level population.
                existingObj.label = this.generateCatClassLabel(
                  "",
                  existingObj.description,
                  this.catClassRequestedQtyMap.get(existingObj.catClass),
                  existingObj.availableSize
                );
              }
              existingObj.statusList.push(statusObj);
              console.log(
                "Addition of new status list and then add the list of record into it"
              );
            } else {
              let listOfRecord = {};
              listOfRecord.name = obj.SM_PS_Make__c;
              listOfRecord.asset = "Asset #: " + obj.SM_PS_Asset_Id__c
              listOfRecord.description = "Asset Description: " + assetDescription;
              statusObjFind.listOfRecords.push(listOfRecord);
              statusObjFind.listOfRecordSize =
                statusObjFind.listOfRecords.length; //Size of status list of record
              statusObjFind.fullName =
                this.getStatusName(statusObjFind.name) +
                " (" +
                statusObjFind.listOfRecordSize +
                ") ";

              if (statusObjFind.name === "AVAILABLE") {
                existingObj.availableSize = statusObjFind.listOfRecordSize; //Added size attribute for header level population.
                existingObj.label = this.generateCatClassLabel(
                  "",
                  existingObj.description,
                  this.catClassRequestedQtyMap.get(existingObj.catClass),
                  existingObj.availableSize
                );
              }
              console.log(
                "Addition of status object on top of existing status list"
              );
            }
            console.log("existing block logic to be placed here");
          }
        });
      })
      .catch((error) => {
        console.error(error);
      });
  }

  getStatusName(statusName) {
    if(statusName) {
      return statusName
      .split(' ')
      .map(
        (word) => word.charAt(0).toUpperCase() + word.substring(1).toLowerCase()
        )
      .join(' ');
    }
    return 'Unassigned';
  }
  /*End: Added by Gopal Raj*/
}