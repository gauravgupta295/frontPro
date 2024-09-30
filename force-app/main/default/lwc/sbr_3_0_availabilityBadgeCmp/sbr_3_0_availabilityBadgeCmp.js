import { LightningElement, api, track, wire } from "lwc";
import getATPForBranch from "@salesforce/apex/SBR_3_0_AvailabilityBadgeCmpController.getATP";
import getBranchId from "@salesforce/apex/SBR_3_0_AvailabilityBadgeCmpController.getBranchId";
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from "@salesforce/client/formFactor";
import { appName,FL_APP_NAME } from "c/sbr_3_0_frontlineUtils";

export default class Sbr_3_0_availabilityBadgeCmp extends NavigationMixin(
  LightningElement
) {
  @track badge1 = false;
  @track badge2 = false;
  @track badge3 = true;
  @track badge4 = false;
  @api selectedATP;
  @api branch;
  @api branchSelected;
  @api atp;
  @api locationInformation;
  @api productCat;
  type = "summary";
  @api util;
  @api chronosEnabled;
  @api objectApiName;
  @api recordId;
  branchName = "";
  profileBranchName = "";
  atpBranch;
  atpBranchId;
  transactionType = "SBR";
  @track atpFieldLabel = "Adj. ATP";
  oldProductCatClass;
  isMobile = false;
  itemType;
  isBranchAvailable;
  defaultBranchText; //FRONT-9837 - To set the default branch text.

  @api
  get utilvalue() {
    return (this.branchDisplay == undefined ||
      this.branchDisplay == null ||
      this.branchDisplay == "") &&
      (this.atp == undefined || this.atp == null || this.atp == "")
      ? ""
      : this.util;
  }


  @api updateSelectedBranchNumberData(branchData) {
    this.atpBranch = branchData;
    this.branchSelected = branchData;
    this.updateParent();
  }

  @api updateSelectedATPData(atpData) {
    this.atp = atpData;
  }

  @api updateSelectedATPLabelData(atpLabelData) {
    this.atpFieldLabel = atpLabelData;
  }

  // SAL-26605
  @api
  getBranchNumber() {
    return this.atpBranch;
  }

  @api updateLocationData(badges) {
    if (badges) {
      this.badge1 = badges.badge1;
      this.badge2 = badges.badge2;
      this.badge3 = badges.badge3;
      this.badge4 = badges.badge4;
    }
  }

  @api updateItemType(itemType) {
    this.itemType = itemType;
  }

  @wire(getBranchId, { branchNumber: "$atpBranch" })
  getATPBranchId({ error, data }) {
    if (data) {
      this.atpBranchId = data;
    } else if (error) {
      console.error("get ATP Branch Id error:", error);
    }
  }

  get branchDisplay() {
    if (this.isFrontlineApp) {
      return this.frontlineBranchDisplay;
    } else {
      return this.nonFrontlineBranchDisplay;















    }


  }
  // Updated to resolve ATP issue - SAL-24259
  getATPDetails() {
    getATPForBranch({
      objectId: this.recordId,
      catClass: this.productCat[0],
      companyCode: this.locationInformation?.Company_Code__c,
      transactionType: this.transactionType
    })
      .then((data) => {
        if (data) {
          let closestLocation = undefined;
          let lastResortBranch = undefined;
          let closestATP = undefined;
          let closestLocationDistance = undefined;
          JSON.stringify(data, (key, val) => {
            if (key === "lastResortBranch" && val !== undefined && val !== "") {
              lastResortBranch = val.split("-")[1];
            }

            if (key == "availabilityByLocations" && val && val.length > 0) {
              for (const key2 in val) {
                if (
                  val[key2].hasOwnProperty("locationId") &&
                  val[key2].hasOwnProperty("atp") &&
                  val[key2].hasOwnProperty("geoDistanceFromJobSite")
                ) {
                  if (
                    closestLocation === undefined &&
                    closestATP === undefined &&
                    closestLocationDistance === undefined
                  ) {
                    closestLocation = val[key2]["locationId"].split("-")[1];
                    closestATP = val[key2]["atp"];
                    closestLocationDistance =
                      val[key2]["geoDistanceFromJobSite"];
                  } else if (
                    closestLocationDistance !== undefined &&
                    val[key2]["geoDistanceFromJobSite"] <
                      closestLocationDistance
                  ) {
                    closestLocation = val[key2]["locationId"].split("-")[1];
                    closestATP = val[key2]["atp"];
                    closestLocationDistance =
                      val[key2]["geoDistanceFromJobSite"];
                  }
                }
              }
            }

            this.badge1 = false;
            this.badge2 = false;
            this.badge3 = false;
            this.badge4 = false;
            // SAL-23450

            if (key === "transactionType") {

              this.transactionType = val;
              switch (this.transactionType) {
                case "SBR":
                  this.atpFieldLabel = "Adj. ATP";
                  break;
                case "SBR24":
                  this.atpFieldLabel = "ATP";
                  break;
                case "SBR72":
                  this.atpFieldLabel = "Controlled";
                  break;
                default:
                  break;
              }
            }

            if (key === "pcId") {
              closestLocation = val;
            }

            return val;
          });

          if (closestLocation !== undefined && closestATP !== undefined) {
            this.atpBranch = closestLocation;
            this.isBranchAvailable = true;
            this.atp = closestATP;
            this.badge1 = false;
            this.badge2 = false;
            this.badge3 = false;
            this.badge4 = false;

            if (this.transactionType === "SBR") {

              if (this.atp > 0) {
                this.badge1 = true;
              } else {

                this.badge3 = true;
              }
            } else if (this.transactionType === "SBR24") {


              if (this.atp > 0) {
                this.badge2 = true;
              } else {

                this.badge3 = true;
              }
            } else if (this.transactionType === "SBR72") {


              if (this.atp > 0) {
                this.badge2 = true;
              } else {

                this.badge3 = true;
              }
            } else {

              this.badge3 = true;
            }
          } else if (lastResortBranch !== undefined) {
            this.atpBranch = lastResortBranch;
            this.badge3 = true;
            this.isBranchAvailable = true;
          }
          this.updateParent();
        } else {

          this.badge1 = false;
          this.badge2 = false;
          this.badge3 = true;
          this.badge4 = false;
          //this.atp = 'N/A';
          this.atp = "";
          this.isBranchAvailable = false;
          if (!this.branchDisplay && !this.atp) {
            this.util = "";
          }
        }

        if (
          (this.branchDisplay == undefined ||
            this.branchDisplay == null ||
            this.branchDisplay == "") &&
          (this.atp == undefined || this.atp == null || this.atp == "")
        ) {
          this.util = "";
        }
        if (!this.chronosEnabled) {
          // SAL-26964  : If chronosEnabled = false, show profile branch at spotlight branch
          this.branchDisplay = this.branch;
        }
        this.updateParent(); //added new for enhance
      })
      .catch((error) => {
        console.log("error in getATPForBranch " + JSON.stringify(error));


        this.isBranchAvailable = false;
        this.updateParent();
      });
  }

  connectedCallback() {
    this.setAppName();
    if (FORM_FACTOR === "Small") {
      this.isMobile = true;
    }
    this.oldProductCatClass = this.productCat;
    this.getATPDetails();

  }

  renderedCallback() {
    if (this.isMobile && this.oldProductCatClass != this.productCat) {
      this.oldProductCatClass = this.productCat;
      // SAL-25827 __ SAL-26130
      if (this.itemType && this.itemType != "altInventoryChronos") {
        this.getATPDetails();
      }
    }
  }

  @api
  updateUtil(util) {
    this.util = util;
    if (this.itemType == undefined) {
      this.getATPDetails(); // Updated to resolve ATP issue - SAL-24259   // This should be done for mobile only
    }
  }

  navigateToRecord(event) {
    event.stopPropagation();

    let recordId =
      this.chronosEnabled && this.atpBranchId
        ? this.atpBranchId
        : this.locationInformation?.Id;
    if (recordId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: recordId,
          actionName: "view"
        }
      });
    }
  }
  updateParent() {
    const displayValue = this.branchDisplay;
    this.dispatchEvent(
      new CustomEvent("branchdisplayupdate", {
        detail: {
          pc: displayValue,
          productId: this.productCat[0],
          branchAvailable: this.isBranchAvailable
        }

      })
    );
  }


  async setAppName() {
    this.appName = await appName;
  }

  get isFrontlineApp() {
    return this.appName === FL_APP_NAME;
  }

  get frontlineBranchDisplay() {
    let display = "";
    if (!this.defaultBranchText) {
      //FRONT-9837 If the default branch has not been set, we will set the display based on the @api params
      if (this.atpBranch) {
        display = this.atpBranch;
      } else if (this.branch) {
        display = this.branch;
      } else if (this.branchSelected) {
        display = this.branchSelected;
      }
      if (display) {
        this.defaultBranchText = display; //FRONT-9837 - set the default branch once display has been set.
      }
    } else {
      display = this.defaultBranchText; //FRONT-9837 - if default branch has been set, we will display that.
    }
    return display;
  }

  get nonFrontlineBranchDisplay() {
    let display = this.branch;
    if (this.atpBranch) {
      display = this.atpBranch;
    } else if (this.branchSelected) {
      display = this.branchSelected;
    }

    if (display == "n/a") {
      return "";
    }

    if (this.branch) {
      this.profileBranchName = this.branch;
    }
    if (!this.chronosEnabled) {
      // SAL-26964  : If chronosEnabled = false, show profile branch at spotlight branch
      display = this.profileBranchName;
    }
    return display;
  }
}