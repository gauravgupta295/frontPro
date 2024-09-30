import { LightningElement, wire } from "lwc";
import googleMapAPI from "@salesforce/resourceUrl/sbr_3_0_googleMapAPI";
import { loadScript } from "lightning/platformResourceLoader";

import FORM_FACTOR from "@salesforce/client/formFactor";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import * as SBRUtils from "c/sbrUtils";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import getVisualforceDomain from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getVisualforceDomain";
import getLightningDomain from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getLightningDomain";
import getAllRecords from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getAllRecords";
import getWiredTerritories from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getWiredTerritories";
import getTerritories from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.getTerritories";
import getMaxRank from "@salesforce/apex/SBR_3_0_AccountDA.getAccountRelationshipsForUsersLowestRank";

import filterRecords from "@salesforce/apex/SBR_3_0_GoogleMapCmpController.filterRecords";
import { openTab } from "lightning/platformWorkspaceApi";

import PIN_IMAGES from "@salesforce/resourceUrl/map_icons";
import TIME_ZONE from "@salesforce/i18n/timeZone";

const { userAgent } = navigator;
const sizes = { standard: "400px", large: "600px" };
const delay = (ms) => new Promise((res) => setTimeout(res, ms));
const SMALL_FORM_FACTOR = "Small";

export default class sbr_3_0_googleMap extends NavigationMixin(
  LightningElement
) {
  loadGoogleMap = true;
  isLarge = false;
  showFilters = false;
  filterWrapper;

  showWrongAppToast = false;

  showLegend = false;
  showTerritories = true;

  showRecordForm = false;
  showCreateForm = false;
  recordFormWrapper;
  showFooter = true;

  recordFormObjectShow;
  recordFormIdShow;
  recordFormIconShow;
  recordFormTitleShow;
  recordFormWrapperShow;

  recordFormIdCreate;
  recordFormObjectCreate;
  recordFormIconCreate;
  recordFormWrapperCreate;
  recordFormTitleCreate;

  isNextDisabled = true;
  showSelectionScreen = true;

  pinDropLabel;
  pinDropLat;
  pinDropLng;
  pinDropStreet;
  pinDropCity;
  pinDropState;
  pinDropFullState;
  pinDropCountry;
  pinDropZip;

  pageNo = 1;
  recordsToDisplay;
  recordsPerPage = 50;
  totalPages = 0;
  pageIndexStart = 0;
  pageIndexEnd = 0;
  pageTotalRecords;
  disablePrev = true;
  disableNext = true;
  orderBy = "ASC";
  orderByDisplay = "utility:sort";
  userTimeZone = TIME_ZONE;

  selectedListValue = "Appointments";
  mapData = [];
  mapDataForTable = [];
  territoryData;
  mapOptionsCenter;
  vfOrigin;
  ltngOrigin;
  iFrameURL;
  showSpinner;
  error;
  message;
  modalMessage =
    "Error thrown during load. Please adjust the filters and try again.";

  accountProspectRTId;
  accountOfficeRTId;

  appointmentIcon = PIN_IMAGES + "/map_icons/images/Appointment.png";
  accountIcon = PIN_IMAGES + "/map_icons/images/Account.png";
  dormantIcon = PIN_IMAGES + "/map_icons/images/Account_Dormant.png";
  top50Icon = PIN_IMAGES + "/map_icons/images/Account_Top50.png";
  prospectIcon = PIN_IMAGES + "/map_icons/images/Account_Prospect.png";
  watchlistIcon = PIN_IMAGES + "/map_icons/images/Account_Watchlist.png";
  opportunityIcon = PIN_IMAGES + "/map_icons/images/Opportunity.png";
  jobSiteIcon = PIN_IMAGES + "/map_icons/images/JobSite.png";
  projectIcon = PIN_IMAGES + "/map_icons/images/Project.png";
  leadIcon = PIN_IMAGES + "/map_icons/images/Lead.png";
  branchIcon = PIN_IMAGES + "/map_icons/images/Branch.png";
  legendPolygon = PIN_IMAGES + "/map_icons/images/Legend_Polygon.png";
  legendMap = PIN_IMAGES + "/map_icons/images/Legend_Map.png";
  legendCheckIn = PIN_IMAGES + "/map_icons/images/Legend_CheckIn.png";

  // Wire getVisualforceDomain Apex method to a VF Domain
  @wire(getVisualforceDomain, { formFactor: FORM_FACTOR, userAgent: userAgent })
  wiredVFDomain({ error, data }) {
    if (data) {
      this.vfOrigin = "https://" + data;
    } else if (error) {
      this.error = error;
      this.vfOrigin = undefined;
    }
  }

  // Wire getLightningDomain Apex method to a Lightning Domain
  @wire(getLightningDomain)
  wiredLtngDomain({ error, data }) {
    if (data) {
      this.ltngOrigin = data + "/";
      this.iFrameURL = "/apex/SBR_3_0_GoogleMap?lcHost=" + this.ltngOrigin;
    } else if (error) {
      this.error = error;
      this.ltngOrigin = undefined;
    }
  }

  @wire(getAllRecords)
  wiredRecords({ error, data }) {
    if (data) {
      this.mapData.push(...data);

      this.error = undefined;
      this.preparePaginationList();
    } else if (error) {
      this.error = error;
      this.mapData = [];
    }
  }

  @wire(getWiredTerritories)
  wiredTerritories({ error, data }) {
    var mapOptionsCenter = { lat: 37.7749, lng: -122.4194 };
    this.mapOptionsCenter = mapOptionsCenter;
    if (data) {
      this.territoryData = data;

      this.serializeTerritoryData();

      if (this.territoryData && this.territoryData.length > 0) {
        let latSum = 0;
        let lngSum = 0;

        this.territoryData[0].latLngList.forEach((element) => {
          latSum += element.lat;
          lngSum += element.lng;
        });

        mapOptionsCenter = {
          lat: latSum / this.territoryData[0].latLngList.length,
          lng: lngSum / this.territoryData[0].latLngList.length
        };

        this.mapOptionsCenter = mapOptionsCenter;
      }

      this.mapOptionsCenter = mapOptionsCenter;
    } else if (error) {
      this.territoryData = [];
      this.template.querySelector(".warningModal").toggleModal(); // opens warning
      this.handleHideSpinner();
    }
  }

  @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
  objectInfo({ error, data }) {
    if (data) {
      const recordTypes = data.recordTypeInfos;
      let prospectRT = Object.values(recordTypes).filter(
        (element) => element.name == "Prospect"
      );
      let officeRT = Object.values(recordTypes).filter(
        (element) => element.name == "Office"
      );
      this.accountProspectRTId = prospectRT[0].recordTypeId;
      this.accountOfficeRTId = officeRT[0].recordTypeId;
    }
  }

  connectedCallback() {
    if (FORM_FACTOR == SMALL_FORM_FACTOR) {
      this.showWrongAppToast = true;
    }
  }

  constructor() {
    super();
    window.addEventListener(
      "message",
      (e) => {
        /*if(e.origin != this.vfOrigin) {
                return;
            }*/
        if (e.data.request == "LOADED") {
          this.filterPolygonPins();
          //console.log('post filterPolygonData');
          //var message = this.buildMapDataMessage();
          //this.sendData(message); // initial load of data - sends Data to VF page
          //this.loadGoogleMap = false;
          //this.openSidebarPanel();
        } else if (e.data.request == "reloadMapData") {
          this.filterPolygonPins();
          //var message = this.buildMapDataMessage();
          //this.sendData(message);
        } else if (e.data.request == "openSidePanel") {
          this.openSidebarPanel();
        } else if (e.data.request == "goToCurrentLocation") {
          this.goToCurrentLocation();
        } else if (e.data.request == "panelAction") {
          var action = e.data.action;
          if (action == "view") {
            var recordId = e.data.id;
            var wrapper = this.mapData.filter((item) => item.recId == recordId);
            wrapper = wrapper[0];
            if (wrapper) {
              var objName = wrapper.objectType;
              var icon = wrapper.iconName;
              var title = wrapper.summary;
              this.showRecord(recordId, objName, icon, title, wrapper);
            }
          }

          if (action == "create") {
            var recordId = e.data.id;
            // this wrapper will be the parent of the new record
            var wrapper = this.mapData.filter((item) => item.recId == recordId);
            wrapper = wrapper[0];
            var objName = e.data.type;
            this.pinDropLabel = e.data.label;
            this.pinDropLat = e.data.lat;
            this.pinDropLng = e.data.lng;
            this.pinDropStreet = e.data.street;
            this.pinDropCity = e.data.city;
            this.pinDropState = e.data.state;
            this.pinDropFullState = e.data.fullState;
            this.pinDropCountry = e.data.country;
            this.pinDropZip = e.data.zip;

            this.createRecord(objName, wrapper);
          }
        }
      },
      false
    );
  }

  filterPolygonPins() {
    loadScript(this, googleMapAPI)
      .then(() => {
        this.mapDataForTable = this.mapData;
        this.mapData = this.mapData.filter((element) => {
          // remove show me data
          if (this.filterWrapper) {
            if (
              this.filterWrapper.showAppointments == false &&
              element.isEvent
            ) {
              return false;
            }
            if (this.filterWrapper.showTasks == false && element.isTask) {
              return false;
            }
            if (this.filterWrapper.showAccounts == false && element.isAccount) {
              return false;
            }
            if (this.filterWrapper.showLeads == false && element.isLead) {
              return false;
            }
            if (this.filterWrapper.showJobSites == false && element.isJobsite) {
              return false;
            }
            if (this.filterWrapper.showProjects == false && element.isProject) {
              return false;
            }
            if (
              this.filterWrapper.showOpportunities == false &&
              element.isOpportunity
            ) {
              return false;
            }
            if (this.filterWrapper.showBranches == false && element.isBranch) {
              return false;
            }
          } else if (element.isBranch) {
            return false;
          } // hide branches by default

          return true;

          // per SAL-27243, we are removing functionality to only show pins within a polygon with the introduction of 'show me'
          /*
        console.log('element', JSON.stringify(element));
        if(!!element.lat && !!element.lng && element.objectType != 'Account' && this.territoryData && this.territoryData.length > 0) {
          let withinPoly;
          let latLng = new google.maps.LatLng(element.lat, element.lng);
          this.territoryData.forEach((terElem) => {
            const poly = new google.maps.Polygon({ paths: terElem.latLngList });
            //polygonData.push(poly);
            let withinSinglePoly = google.maps.geometry.poly.containsLocation(latLng, poly);
            console.log('withinPoly ->' + withinPoly);
            withinPoly = withinPoly || withinSinglePoly;
          });
          console.log('withinPoly ->' + withinPoly);
          return withinPoly;
        }
        else {
          return true;
        }*/
        });

        var message = this.buildMapDataMessage();
        this.sendData(message);
        this.loadGoogleMap = false;
        this.openSidebarPanel();
      })
      .catch((error) => console.log("googleMapAPI load exception -> " + error));
  }

  buildMapDataMessage() {
    var message = {
      loadGoogleMap: this.loadGoogleMap,
      reloadMap: true,
      mapData: this.mapData,
      mapOptionsCenter: this.mapOptionsCenter,
      territories: this.territoryData
    };
    return message;
  }

  buildCreateSidePanelControlMessage() {
    var message = {
      createSidePanelControl: true
    };
    return message;
  }

  buildRecenterToRowMessage(recId, latLng, name, address, recordType) {
    var message = {
      markerType: "recenterToRecord",
      recId: recId,
      position: latLng,
      name: name,
      address: address,
      recordType: recordType
    };
    return message;
  }

  buildRecenterMessage(latLng) {
    var message = {
      markerType: "recenter",
      position: latLng
    };
    return message;
  }

  buildNewRecordMarkerMessage(
    recId,
    summary,
    latLng,
    obj,
    address,
    recordType
  ) {
    var message = {
      markerType: "addMarker",
      summary: summary,
      recId: recId,
      position: latLng,
      objectType: obj,
      address: address,
      recordType: recordType
    };
    return message;
  }

  sendData(message) {
    this.template
      .querySelector("iframe")
      .contentWindow.postMessage(JSON.stringify(message), this.vfOrigin);
  }

  goToCurrentLocation() {
    this.showSpinner = true;
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        this.showSpinner = false;
        // Get the Latitude and Longitude from Geolocation API
        var userLatitude = position.coords.latitude;
        var userLongitude = position.coords.longitude;

        var myLocation = {
          lat: parseFloat(userLatitude),
          lng: parseFloat(userLongitude)
        };

        var message = this.recenter(myLocation);
        this.sendData(message);
      });
    }
  }

  applyFilters(event) {
    this.handleShowSpinner();

    this.filterWrapper = event.detail;

    this.filterWrapper.accountRecordType = JSON.stringify(
      this.filterWrapper.accountRecordType
    );
    this.filterWrapper.projectDodgePhase = JSON.stringify(
      this.filterWrapper.projectDodgePhase
    );
    this.filterWrapper.projectPrimaryType = JSON.stringify(
      this.filterWrapper.projectPrimaryType
    );
    this.filterWrapper.projectOrigin = JSON.stringify(
      this.filterWrapper.projectOrigin
    );
    this.filterWrapper.opportunityStage = JSON.stringify(
      this.filterWrapper.opportunityStage
    );
    this.filterWrapper.lineOfBusiness = JSON.stringify(
      this.filterWrapper.lineOfBusiness
    );

    if (this.filterWrapper.globalSearch) {
      this.filterWrapper.appointmentSearch = this.filterWrapper.globalSearch;
      this.filterWrapper.taskSearch = this.filterWrapper.globalSearch;
      this.filterWrapper.accountSearch = this.filterWrapper.globalSearch;
      this.filterWrapper.jobSiteSearch = this.filterWrapper.globalSearch;
      this.filterWrapper.projectSearch = this.filterWrapper.globalSearch;
      this.filterWrapper.opportunitySearch = this.filterWrapper.globalSearch;
      this.filterWrapper.branchSearch = this.filterWrapper.globalSearch;
    }

    getTerritories({ filterWrapper: this.filterWrapper })
      .then((data) => {
        if (data) {
          this.territoryData = data;

          // clean territory data
          this.serializeTerritoryData();

          filterRecords({ wrapper: this.filterWrapper })
            .then((result) => {
              this.mapData = new Array();
              this.mapData.push(...result);

              this.pageNo = 1;

              if (this.territoryData && this.territoryData.length > 0) {
                let latSum = 0;
                let lngSum = 0;

                this.territoryData[0].latLngList.forEach((element) => {
                  latSum += element.lat;
                  lngSum += element.lng;
                });

                let mapOptionsCenter = {
                  lat: latSum / this.territoryData[0].latLngList.length,
                  lng: lngSum / this.territoryData[0].latLngList.length
                };

                this.mapOptionsCenter = mapOptionsCenter;
                let message = this.recenter(mapOptionsCenter);
              }

              this.filterPolygonPins();
              this.preparePaginationList();
              //var message = this.buildMapDataMessage();
              //this.sendData(message);

              if (!this.filterWrapper.rankRangeAccountsEnd) {
                getMaxRank({ filterWrapper: this.filterWrapper })
                  .then((maxRank) => {
                    this.filterWrapper.rankRangeAccountsEnd = maxRank;

                    this.goBack();
                    this.handleHideSpinner();
                  })
                  .catch((error) => {
                    this.error = error;
                    this.mapData = [];
                    this.template.querySelector(".warningModal").toggleModal(); // opens warning
                    this.handleHideSpinner();
                  });
              } else {
                this.goBack();
                this.handleHideSpinner();
              }
            })
            .catch((error) => {
              this.error = error;
              this.mapData = [];
              this.template.querySelector(".warningModal").toggleModal(); // opens warning
              this.handleHideSpinner();
            });
        }
      })
      .catch((error) => {
        this.error = error;
        this.territoryData = [];
        this.template.querySelector(".warningModal").toggleModal(); // opens warning
        this.handleHideSpinner();
      });
  }

  moveToPin(event) {
    let target = event.currentTarget;
    this.navigateToRow(target);
  }

  showRecord(recordId, objName, icon, title, wrapper) {
    this.recordFormObjectShow = objName;
    this.recordFormIdShow = recordId;
    this.recordFormIconShow = icon;
    this.recordFormTitleShow = title;
    this.recordFormWrapperShow = wrapper;
    if (title.length > 50) {
      this.isLarge = true;
    }
    this.openSidebarPanel();
    this.showRecordForm = true;
  }

  createRecord(objName, wrapper) {
    // objName is the object to create
    // wrapper is the parent of the new record
    this.recordFormIdCreate = null;
    this.recordFormObjectCreate = objName;
    this.recordFormWrapperCreate = wrapper;
    this.recordFormTitleCreate = "Create " + this.pinDropLabel;
    //this.openSidebarPanel();
    this.showCreateForm = true;
  }

  goToRecord(event) {
    var recordId = event.target.dataset.id;
    var objName = event.target.dataset.obj;
    // Navigate to Appointment/Event record page
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: objName,
        actionName: "view"
      }
    });
  }

  navigateToRow(target) {
    var recId = target.dataset.id;

    var lat = target.dataset.lat;
    var lng = target.dataset.lng;
    var title = target.dataset.title;
    var street = target.dataset.street;
    var city = target.dataset.city;
    var state = target.dataset.state;
    var postal = target.dataset.postal;
    var country = target.dataset.country;
    var recordType = target.dataset.recordtype;

    var address = this.buildAddress(street, city, state, postal, country);

    var position = { lat: parseFloat(lat), lng: parseFloat(lng) };

    var message = this.buildRecenterToRowMessage(
      recId,
      position,
      title,
      address,
      recordType
    );
    this.sendData(message);

    // display selected row in panel
    var wrapper = this.mapDataForTable.filter((item) => item.recId == recId);
    wrapper = wrapper[0];
    if (wrapper) {
      var objName = wrapper.objectType;
      var icon = wrapper.iconName;
      var title = wrapper.summary;
      this.showRecord(recId, objName, icon, title, wrapper);
    }
  }

  recenter(position) {
    var message = this.buildRecenterMessage(position);
    this.sendData(message);
  }

  addMarkerNewRecord(event) {
    console.log("saved - addMarkerNewRecord");
    this.showCreateForm = false;
    this.showSelectionScreen = true;
    this.isNextDisabled = true;

    var recId = event.detail.recId;
    var lat = event.detail.lat;
    var lng = event.detail.lng;
    var summary = event.detail.summary;
    var address = event.detail.address;
    var obj = event.detail.objectType;
    var icon = event.detail.icon;
    var recordType = event.detail.recordType;

    var position = { lat: parseFloat(lat), lng: parseFloat(lng) };

    this.mapData.push({
      recId: recId,
      summary: summary,
      lat: lat,
      lng: lng,
      objectType: obj,
      icon: icon
    });

    var message = this.buildNewRecordMarkerMessage(
      recId,
      summary,
      position,
      obj,
      address,
      recordType
    );
    this.sendData(message);

    //var message = this.buildRecenterToRowMessage(recId, position, summary, address);
    var message = this.buildRecenterToRowMessage(
      recId,
      position,
      summary,
      address,
      recordType
    );

    this.sendData(message);
  }

  openSidebarPanel() {
    if (this.isLarge) {
      this.template.querySelector("div[data-my-id=sidebarPanel]").style.width =
        sizes.large;
      this.template.querySelector(
        "div[data-my-id=closeSideDiv]"
      ).style.marginLeft = sizes.large;
    } else {
      this.template.querySelector("div[data-my-id=sidebarPanel]").style.width =
        sizes.standard;
      this.template.querySelector(
        "div[data-my-id=closeSideDiv]"
      ).style.marginLeft = sizes.standard;
    }
    this.template.querySelector("div[data-my-id=sidebarPanel]").style.overflow =
      "visible";
  }

  panelSizeChange(event) {
    if (event.detail) {
      this.isLarge = true;
    } else {
      this.isLarge = false;
    }
    this.openSidebarPanel();
  }

  closeSidePanel() {
    var createSidePanelControlMsg = this.buildCreateSidePanelControlMessage();
    this.sendData(createSidePanelControlMsg);
    this.template.querySelector("div[data-my-id=sidebarPanel]").style.width =
      "0";
    this.template.querySelector("div[data-my-id=sidebarPanel]").style.overflow =
      "hidden";
  }

  goBack() {
    this.showRecordForm = false;
    this.showFilters = false;
    this.isLarge = false;
    this.openSidebarPanel();
  }

  toggleFilters() {
    this.showFilters = !this.showFilters;
  }

  async preparePaginationList() {
    await delay(1500);
    let begin = (this.pageNo - 1) * parseInt(this.recordsPerPage);
    let end = parseInt(begin) + parseInt(this.recordsPerPage);
    let tableData = this.mapDataForTable.filter(
      (element) => element.isBranch == null || element.isBranch == false
    );

    let orderSeq = this.orderBy == "ASC" ? 1 : -1;

    if (this.selectedListValue == "Appointments") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isEvent == true
      );
    } else if (this.selectedListValue == "Tasks") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isTask == true
      );
    } else if (this.selectedListValue == "Job Sites") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isJobsite == true
      );
    } else if (this.selectedListValue == "Projects") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isProject == true
      );
    } else if (this.selectedListValue == "Opportunities") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isOpportunity == true
      );
    } else if (this.selectedListValue == "Accounts") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isAccount == true
      );
    } else if (this.selectedListValue == "Leads") {
      tableData = this.mapDataForTable.filter(
        (element) => element.isLead == true
      );
    }

    /*if (this.selectedListValue == "Places") {
      // Places have Job Sites, Opps, and Projects so we need to sort this list by Alpha. Otherwise this list will be separated by type, then name
      tableData.sort((a, b) =>
        a.summary > b.summary
          ? 1 * orderSeq
          : b.summary > a.summary
          ? -1 * orderSeq
          : 0
      );
    }*/

    let pageRecords = tableData.slice(begin, end);
    this.totalPages = Math.ceil(tableData.length / this.recordsPerPage);

    // index records to display
    this.recordsToDisplay = [];
    var startIndex = (this.pageNo - 1) * this.recordsPerPage + 1;
    this.pageIndexStart = startIndex;
    this.pageIndexEnd = startIndex + this.recordsPerPage - 1;
    this.pageTotalRecords = tableData.length;
    if (tableData.length == 0) {
      this.pageIndexStart = 0;
    }

    // disable/enable prev next
    if (this.pageIndexEnd > this.pageTotalRecords) {
      this.pageIndexEnd = this.pageTotalRecords;
    }
    if (this.pageNo <= 1) {
      this.disablePrev = true;
    } else {
      this.disablePrev = false;
    }
    if (this.pageIndexEnd >= this.pageTotalRecords) {
      this.disableNext = true;
    } else {
      this.disableNext = false;
    }

    pageRecords.forEach((element) => {
      var newElement = JSON.parse(JSON.stringify(element));
      newElement.index = startIndex;
      // set badges
      let cats = newElement.categories;

      if (cats != undefined && cats != null) {
        if (cats.includes("top25")) {
          newElement.isTop25 = true;
        }
        if (cats.includes("top50")) {
          newElement.isTop50 = true;
        }
        if (cats.includes("prospect")) {
          newElement.isProspect = true;
        }
        if (cats.includes("watchlist")) {
          newElement.isWatchlist = true;
        }
        if (cats.includes("dormant")) {
          newElement.isDormant = true;
        }
        if (cats.includes("fingerprint")) {
          newElement.isFingerprint = true;
        }
        if (cats.includes("commissionable")) {
          newElement.isCommissionable = true;
        }
        if (cats.includes("credit")) {
          newElement.isCredit = true;
        }
        if (cats.includes("erp-link")) {
          newElement.isERPLink = true;
        }
        if (cats.includes("non-credit")) {
          newElement.isNonCredit = true;
        }
        if (cats.includes("office")) {
          newElement.isOffice = true;
        }
        if (cats.includes("vendor")) {
          newElement.isVendor = true;
        }
        if (cats.includes("global")) {
          newElement.isGlobal = true;
        }
      }

      // merge RelatedToWhoWhat
      if (element.whoName && element.parentName) {
        newElement.hasRelatedToWhoAndWhat = true;
      }

      this.recordsToDisplay.push(newElement);
      startIndex++;
    });

    // scroll to top
    if (this.template.querySelector(".table-container")) {
      this.template.querySelector(".table-container").scrollTop = 0;
    }
  }

  handleNext() {
    this.pageNo += 1;
    this.preparePaginationList();
  }

  handlePrevious() {
    this.pageNo -= 1;
    this.preparePaginationList();
  }

  get listSelectOptions() {
    return [
      { label: "Appointments", value: "Appointments" },
      { label: "Tasks", value: "Tasks" },
      { label: "Job Sites", value: "Job Sites" },
      { label: "Projects", value: "Projects" },
      { label: "Opportunities", value: "Opportunities" },
      { label: "Accounts", value: "Accounts" },
      { label: "Leads", value: "Leads" }
      //{ label: "Places", value: "Places" },
    ];
  }

  handleListSelectChange(event) {
    this.selectedListValue = event.detail.value;
    this.pageNo = 1;
    this.preparePaginationList();
  }

  sortList() {
    this.handleShowSpinner();
    this.orderBy = this.orderBy == "ASC" ? "DESC" : "ASC";
    console.log(this.orderBy);
    this.orderByDisplay =
      this.orderBy == "ASC" ? "utility:arrowup" : "utility:arrowdown";

    // console.log('Map = ', JSON.stringify(this.mapDataForTable));
    // this.mapDataForTable.sort(this.customSort);
    const accountsWithRank = this.mapDataForTable.filter(
      (item) => item.isAccount && item.rank !== undefined
    );
    const accountsWithoutRank = this.mapDataForTable.filter(
      (item) => item.isAccount && item.rank === undefined
    );
    const otherItems = this.mapDataForTable.filter(
      (item) =>
        item.isLead ||
        item.isEvent ||
        item.isJobsite ||
        item.isProject ||
        item.isOpportunity ||
        item.isTask
    );

    const sortedAccountsWithRank = accountsWithRank.sort(this.customSort);
    const sortedAccountsWithoutRank = accountsWithoutRank.sort(this.customSort);
    const sortedOtherItems = otherItems.sort(this.customSort);

    this.mapDataForTable = [
      ...sortedAccountsWithRank,
      ...sortedAccountsWithoutRank,
      ...sortedOtherItems
    ];

    this.pageNo = 1;
    this.preparePaginationList();
    this.handleHideSpinner();
  }

  customSort = (a, b) => {
    function getObjectType(obj) {
      console.log(obj.isTask);
      if (obj.isAccount) return "account";
      if (obj.isEvent) return "appointment";
      if (obj.isTask) return "task";
      if (obj.isLead) return "lead";
      if (obj.isJobsite) return "jobSite";
      if (obj.isProject) return "project";
      if (obj.isOpportunity) return "opportunity";
      return "";
    }

    const typeA = getObjectType(a);
    const typeB = getObjectType(b);

    if (typeA !== typeB) {
      return typeA.localeCompare(typeB);
    }
    let comparison = 0;
    if (typeA === "account") {
      if (a.rank !== undefined && b.rank !== undefined) {
        comparison = a.rank - b.rank;
      } else if (a.rank !== undefined) {
        comparison = -1;
      } else if (b.rank !== undefined) {
        comparison = 1;
      } else {
        comparison = a.account.Name.localeCompare(b.account.Name);
      }
    } else if (typeA === "appointment") {
      const dateA = new Date(a.event.StartDateTime);
      const dateB = new Date(b.event.StartDateTime);
      comparison = dateA - dateB;
    } else if (typeA === "task") {
      const dateA = new Date(a.task.ActivityDate);
      const dateB = new Date(b.task.ActivityDate);
      comparison = dateA - dateB;
    } else if (typeA === "lead") {
      comparison = a.lead.Name.localeCompare(b.lead.Name);
    } else if (
      typeA === "jobSite" ||
      typeA === "project" ||
      typeA === "opportunity"
    ) {
      comparison = a.summary.localeCompare(b.summary);
    }
    console.log(this.orderBy);
    return this.orderBy === "ASC" ? comparison : -comparison;
  };

  refreshList() {
    this.handleShowSpinner();

    filterRecords({ wrapper: this.filterWrapper })
      .then((result) => {
        this.mapData = new Array();
        this.mapData.push(...result);

        this.filterPolygonPins();

        this.pageNo = 1;
        this.preparePaginationList();
        //var message = this.buildMapDataMessage();
        //this.sendData(message);
        this.orderByDisplay = "utility:sort";
        this.handleHideSpinner();
      })
      .catch((error) => {
        this.error = error;
        this.mapData = [];
        this.template.querySelector(".warningModal").toggleModal(); // opens warning
        this.handleHideSpinner();
      });
  }

  hideCreateForm(event) {
    if (this.recordFormObjectCreate != "Lead") {
      this.showCreateForm = false;
      this.showSelectionScreen = true;
      this.isNextDisabled = true;
    } else {
      let target = event.currentTarget;
      let info = target.dataset.info;
      if (info == "cancel") {
        this.showCreateForm = false;
        this.showSelectionScreen = true;
        this.isNextDisabled = true;
      }
    }
  }

  hideCreateFormLead() {
    console.log("in hide hideCreateFormLead");
    this.showCreateForm = false;
    this.showSelectionScreen = true;
    this.isNextDisabled = true;
    //this.showFooter = true; // reset footer
  }

  showNextRadioButton(event) {
    this.recordFormObjectCreate = event.detail;
    this.isNextDisabled = false;
  }

  handleNextRadioButton() {
    this.showSelectionScreen = false;
    this.isNextDisabled = true;
    if (this.recordFormObjectCreate == "Lead") {
      //this.showFooter = false; // hide footer to allow Next in lightning-flow (recordForm.html)
    }
  }

  handleSaveRecord() {
    this.template.querySelector("c-sbr_3_0_record-form").handleSubmit();
  }

  handleError(error, stack) {
    this.showCreateForm = true;
    this.showSelectionScreen = false;
    this.isNextDisabled = true;

    this.error = error;
    const toastEvent = new ShowToastEvent({
      title: "An error occured. Please try again.",
      message: error.detail,
      variant: "error"
    });
    this.dispatchEvent(toastEvent);
  }

  handleSaveError(event) {
    event.detail?.output?.errors.forEach((error) => {
      const evt = new ShowToastEvent({
        title: "An error occured while saving the record",
        message: error?.message,
        variant: "error",
        mode: "sticky"
      });
      this.dispatchEvent(evt);
    });
  }

  toggleLegend() {
    this.showLegend = !this.showLegend;
  }

  toggleTerritory() {
    this.showTerritories = !this.showTerritories;
    let message = {
      action: "toggleTerritory",
      showTerritories: this.showTerritories
    };
    this.sendData(message);
  }

  handleShowSpinner() {
    this.showSpinner = true;
  }

  handleHideSpinner() {
    this.showSpinner = false;
  }

  buildAddress(street, city, state, postal, country) {
    var addressArray = [street, city, state, postal, country];
    addressArray = addressArray.filter((element) => element); // remove nulls, blanks, undefined
    var address = addressArray.join(", ");
    return address;
  }

  handleMenuCreateNew(event) {
    let target = event.currentTarget;
    let obj = target.dataset.obj;

    if (obj == "Prospect") {
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: "Account",
          actionName: "new"
        },
        state: {
          recordTypeId: this.accountProspectRTId
        }
      });
    } else if (obj == "Office") {
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: "Account",
          actionName: "new"
        },
        state: {
          recordTypeId: this.accountOfficeRTId
        }
      });
    } else if (obj == "Lead") {
      this[NavigationMixin.Navigate]({
        type: "standard__component",
        attributes: {
          componentName: "c__SBR_3_0_CreateLeadWrapperCmp"
        },
        state: {
          c__xAction: "closeModal"
        }
      });
    } else {
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: obj,
          actionName: "new"
        }
      });
    }
  }

  serializeTerritoryData() {
    // clean data
    let cleanTerritoryData = [];
    this.territoryData.forEach((element) => {
      let rawData = element.coordinates;
      if (rawData) {
        let respObj = JSON.parse(rawData);
        if (respObj.data.coordinates) {
          let coordinates = JSON.parse(rawData).data.coordinates;

          if (respObj.data.type == "Polygon") {
            let latLngList = [];
            let newElement = {};
            newElement.territoryId = element.territoryId;
            newElement.userId = element.userId;
            coordinates[0].forEach((coord) => {
              let latLng = {
                lat: coord[1],
                lng: coord[0]
              };

              latLngList.push(latLng);
            });
            newElement.latLngList = latLngList;
            newElement.coordinates = "";
            cleanTerritoryData.push(newElement);
          } else if (respObj.data.type == "MultiPolygon") {
            coordinates.forEach((section) => {
              let latLngList = [];
              let newElement = {};
              newElement.territoryId = element.territoryId;
              newElement.userId = element.userId;

              section[0].forEach((coord) => {
                let latLng = {
                  lat: coord[1],
                  lng: coord[0]
                };

                latLngList.push(latLng);
              });

              newElement.latLngList = latLngList;
              newElement.coordinates = "";
              cleanTerritoryData.push(newElement);
            });
          }
        }
      }
    });

    this.territoryData = cleanTerritoryData;
  }

  //Handler to modify filterWrapper in the event user filter values were changed
  updateFilterWrapper(event) {
    if (SBRUtils.isEmpty(this.filterWrapper)) {
      this.filterWrapper = { userTerritories: event.detail };
    } else {
      this.filterWrapper.userTerritories = event.detail;
    }
  }

  openMapNewTab() {
    openTab({
      url: "/lightning/n/Maps",
      label: "Maps",
      focus: true,
      icon: "action:map"
    }).catch((error) => {
      console.log("openMaps -> openTab error: " + error);
    });
  }

  get showSaveButton() {
    return !this.showSelectionScreen && this.recordFormObjectCreate != "Lead";
  }
}