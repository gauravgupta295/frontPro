import { LightningElement, api, track, wire } from "lwc";
import { Logger } from "c/sbr_3_0_frontlineUtils";
import { loadStyle } from "lightning/platformResourceLoader";
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
import LABELS from "c/sbr_3_0_customLabelsCmp";
import lwcDatatableStyle from "@salesforce/resourceUrl/sbr_3_0_customDataTable_css";
import borderStyle from "@salesforce/resourceUrl/Sbr_3_0_AddressCss";
import getBranchChronosDetailsNew from "@salesforce/apex/SBR_3_0_AssetController.getLoggedInUserBranchLocation";
import { getRecord } from "lightning/uiRecordApi";
const ORDER_FIELDS = [
  "Order.Account.RM_Account_Number__c",
  "Order.Branch_Location_Number__c",
  "Order.Start_Date__c"
];

const logger = Logger.create(true);
export default class sbr_3_0_itemSearchAssetsContainer extends LightningElement {
  //@api locationInfo;
  tableColumns;
  @track tableData;
  //@api activeTab; // FRONT-14464
  @api placeholder; //Front -15677, 15681
  recordsCount;
  @track result = []; // FRONT-14464
  @api recordId;
  @api objectApiName;
  @api viewName;
  defaultSortDirection = "asc"; // FRONT-14464
  sortDirection = "asc"; // FRONT-14464
  sortedBy; // FRONT-14464
  brachLocation; // FRONT-14464
  isCssLoaded = false; // FRONT-14464
  noContentimageUrl = noContentSvg; //FRONT-14464
  noContentLabel = LABELS.NOCONTENT_LABEL; //FRONT-14464
  noAssetContentLabel = LABELS.NOASSETCONTENT_LABEL; //FRONT-14480
  noCatContentLabel = LABELS.NOCONTENT_LABEL;
  finalResult = {}; // FRONT-15699
  descriptionSelectedLocation = "Current Branch"; //FRONT - 15702
  productRowsOffset = 0;
  selectedCatClassVal = "";
  infiniteLoad = true;
  showAssetSelectionScreen = false;
  modalHeader = "";
  isMobile = false;
  isItemSearchCatClassTab = false;
  @track displayStaticData = false;
  searchCatClass;

  //FRONT-16637/17145
  orderData = {};
  productIdToOrderItems = {};
  assetIdToOrderItems = {};
  showViewContent = false;
  showCommentContent = false;
  LABELS = LABELS;
  showNoContentImage = false;

  //FRONT-16637/17145: passing order details to sbr_3_0_itemSearchSelectAssetEditorCmp
  @wire(getRecord, { recordId: "$recordId", fields: ORDER_FIELDS })
  wiredOrder({ error, data }) {
    if (data) {
      this.orderData = data;
      console.log("orderData::", JSON.stringify(this.orderData));
    } else if (error) {
      logger.log("error in wiredOrder", JSON.stringify(error));
    }
  }

  // FRONT-14464 Start
  @wire(getBranchChronosDetailsNew)
  getBranchChronosDetailsNew({ error, data }) {
    if (data) {
      this.brachLocation = data.Branch_Location_Number__c;
    } else if (error) {
      logger.log("error: " + JSON.stringify(error));
    }
  }

  get isAssetTab() {
    let result = false;
    if (this.viewName === "Asset") {
      result = true;
    }
    return result;
  }

  //FRONT-14464 End
  get isCatClassTab() {
    //FRONT - 15702
    let result = false;
    if (this.viewName === "CatClass") {
      result = true;
    }
    return result;
  }

  get isCatClassDescriptionTab() {
    //FRONT - 15702
    let result = false;
    if (this.viewName === "Cat Class Description") {
      result = true;
    }
    return result;
  }

  get isSerialTab() {
    //FRONT-19120
    let result = false;
    if (this.viewName === "Serial") {
      result = true;
    }
    return result;
  }

  renderedCallback() {
    if (this.isCssLoaded) {
      return;
    }

    this.isCssLoaded = true;
    Promise.all([
      loadStyle(this, lwcDatatableStyle, borderStyle),
      loadStyle(this, borderStyle)
    ])
      .then(() => {
        logger.log("Loaded Successfully");
      })
      .catch((error) => {
        logger.log(error);
      });
  }

  @api
  loadCatClassFilter(catClassVal, locationFilter) {
    // FRONT-15702
    logger.log("---Selected CatClass" + catClassVal);
    logger.log("--- Selected Location Filter " + locationFilter);
    if (
      this.template.querySelector("c-sbr_3_0_item-search-assets-cat-class-cmp")
    ) {
      this.template
        .querySelector("c-sbr_3_0_item-search-assets-cat-class-cmp")
        .catClassFilter(catClassVal, locationFilter);
    }
  }

  _activeTab;
  @api
  get activeTab() {
    return this._activeTab;
  }

  set activeTab(value) {
    this._activeTab = value;
  }
}