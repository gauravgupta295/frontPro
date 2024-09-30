import { LightningElement, api } from "lwc";
import MOBILE_SCREEN_STACK from "c/sbr_3_0_mobileScreenUtility";

const DEFAULT_HEADER_CLASSES = "slds-grid slds-border_bottom header-section";
const DEFAULT_CONTENT_CLASSES = "content-section";
const DEFAULT_FOOTER_CLASSES = "footer-section";
const DEFAULT_SPINNER_CLASSES = "mobile-spinner";
const DEFAULT_SPINNER_MESSAGE = "Loading...";
const DEFAULT_Z_INDEX = 9002;
const DYNAMIC_VARIANT = "dynamic";
const STATIC_VARIANT = "static";
const DEFAULT_BUFFER_HEIGHT = 0;
const AVAILABLE_VARIANT = [DYNAMIC_VARIANT, STATIC_VARIANT];

const TITLE_CLASS_FOR_HEADER_CANCEL_BTN =
  "slds-var-p-horizontal_small slds-var-p-top_small";
const DEFAULT_SUB_HEADER_CLASS = "slds-grid";
export default class Sbr_3_0_mobileScreen extends LightningElement {
  static renderMode = "light"; // the default is 'shadow'
  isLoading = false;
  spinnerMessage = DEFAULT_SPINNER_MESSAGE;
  _isTitleHidden = false;
  _isPreviousTitleHidden = true;
  _isFooterHidden = false;
  _isPreviousFooterHidden = true;
  _isOpen = false;
  _zIndex = DEFAULT_Z_INDEX;
  _props;
  showFooter = true;
  _variant = DYNAMIC_VARIANT;
  _bufferHeight;
  _fullScreen = true;
  isLoaded;
  _previousFooterHeight = DEFAULT_BUFFER_HEIGHT;
  _footerHeight = 0;
  @api
  get props() {
    return this._props;
  }

  set props(value) {
    this._props = JSON.parse(JSON.stringify(value));
    this.init();
  }

  _uuid;
  @api
  get uuid() {
    return this._uuid;
  }

  set uuid(value) {
    this._uuid = value;
  }

  @api toggleSpinner() {
    this.isLoading = !this.isLoading;
  }

  @api setSpinnerMessage(message) {
    this.spinnerMessage = message;
  }

  get headerClasses() {
    const classes = this.props?.headerClasses
      ? `${DEFAULT_HEADER_CLASSES} ${this.props.headerClasses}`
      : DEFAULT_HEADER_CLASSES;
    return this._isTitleHidden ? `${classes} slds-hide` : classes;
  }

  get contentClasses() {
    return this.props?.contentClasses
      ? `${DEFAULT_CONTENT_CLASSES} ${this.props.contentClasses}`
      : DEFAULT_CONTENT_CLASSES;
  }

  get footerClasses() {
    //alert(this.props.footerClasses);
    const classes = this.props?.footerClasses
      ? `${DEFAULT_FOOTER_CLASSES} ${this.props.footerClasses}`
      : DEFAULT_FOOTER_CLASSES;
    return this._isFooterHidden ? `${classes} slds-hide` : classes;
  }

  get spinnerClasses() {
    return this.isHeadless ? DEFAULT_SPINNER_CLASSES : "";
  }

  get computedInlineStyle() {
    return `${this.zIndexStyle};${this.heightStyle}`;
  }

  get zIndexStyle() {
    return `z-index:${this._zIndex ? this._zIndex : DEFAULT_Z_INDEX}`;
  }

  get heightStyle() {
    return `height:calc(100% - ${this._bufferHeight}px)`;
  }

  connectedCallback() {
    if (this.isDynamicVariant) {
      this.pushToStack();
    }

    this.generateUUID();
  }

  disconnectedCallback() {
    this.popFromStack();
  }

  @api hide(state = { hideTitle: true, hideFooter: true }) {
    this._isTitleHidden = state.hideTitle;
    this._isFooterHidden = state.hideFooter;
    this._zIndex = DEFAULT_Z_INDEX;
  }

  @api show(state = { hideTitle: false, hideFooter: false }) {
    this._isTitleHidden = state.hideTitle;
    this._isFooterHidden = state.hideFooter;
  }

  init() {
    this.setZIndex(this.props?.zIndex);
    this.setVariant(this.props?.variant);
    this.setPreviousScreenStateForDynamicVariant(this.props);
    this.setFullScreenView(this.props?.fullScreen);
    this.setPreviousFooterHeight(this.props?.bufferHeight);
  }

  setZIndex(zIndex) {
    this._zIndex = zIndex;
  }

  setBufferHeight(height) {
    this._bufferHeight = height;
  }

  get hasStringTitle() {
    return !!this.title;
  }

  renderedCallback() {
    if (this.footerSlot) {
      this.showFooter = this.footerSlot.childElementCount > 0;
      this.getFooterPosition();
    }
  }

  get footerSlot() {
    return this.querySelector(".footer-section");
  }

  // renderedCallback() {
  //   if (this.footerSlot) {
  //     this.showFooter = this.footerSlot.assignedElements().length !== 0;
  //   }
  // }

  // get footerSlot() {
  //   return this.template.querySelector("slot[name=footer]");
  // }

  setVariant(variant) {
    if (variant) {
      this._variant =
        AVAILABLE_VARIANT.indexOf(variant) !== -1 ? variant : DYNAMIC_VARIANT;
    }
  }

  get isDynamicVariant() {
    return this._variant === DYNAMIC_VARIANT;
  }

  get isStaticVariant() {
    return this._variant === STATIC_VARIANT;
  }

  pushToStack() {
    this.setIsLoaded();
    MOBILE_SCREEN_STACK.push(this);
  }

  popFromStack() {
    MOBILE_SCREEN_STACK.pop(this);
  }

  @api toggleScreen(state = {}) {
    this._isPreviousTitleHidden =
      state.hidePreviousTitle ?? !this._isPreviousTitleHidden;
    this._isPreviousFooterHidden =
      state.hidePreviousFooter ?? !this._isPreviousFooterHidden;
    this._isOpen = !this._isOpen;
    this._fullScreen = state.fullScreen ?? this._fullScreen;
    if (this._isOpen) {
      this.pushToStack();
    } else {
      this.popFromStack();
    }
  }

  setPreviousScreenStateForDynamicVariant(state) {
    if (this._variant !== DYNAMIC_VARIANT) {
      return;
    }
    this._isPreviousTitleHidden =
      state.hidePreviousTitle || this._isPreviousTitleHidden;
    this._isPreviousFooterHidden =
      state.hidePreviousFooter || this._isPreviousFooterHidden;
  }

  setFullScreenView(fullScreen) {
    this._fullScreen = fullScreen;
    this._previousFooterHeight = 0;
  }

  get fullScreenView() {
    return this._fullScreen || this.isDynamicVariant;
  }

  get slottedTitedClasses() {
    return this._isTitleHidden ? "slds-hide" : "";
  }

  setIsLoaded() {
    if (!this.isLoaded) {
      this.isLoaded = true;
    }
  }

  setPreviousFooterHeight(height) {
    if (height) {
      this._previousFooterHeight = height;
    }
  }

  generateUUID() {
    if (!this.uuid) {
      this._uuid = crypto.randomUUID();
    }
  }

  getFooterPosition() {
    const footerHeight = this.footerSlot?.getBoundingClientRect()?.height;
    if (footerHeight !== undefined) {
      this._footerHeight = footerHeight + 32;
    }
  }

  /*FRONT - 15255 */
  showCrossBtnOnHeader = false;
  @api
  get showCrossCancelBtn() {
    return this.showCrossBtnOnHeader;
  }
  set showCrossCancelBtn(value) {
    this.showCrossBtnOnHeader =
      value && typeof value === "string" && value.toLowerCase() === "true";
  }

  get titleClass() {
    return this.showCrossBtnOnHeader
      ? TITLE_CLASS_FOR_HEADER_CANCEL_BTN + " filter-grey-color"
      : "slds-var-p-vertical_small";
  }

  get subHeaderClass() {
    return !this.showCrossBtnOnHeader
      ? DEFAULT_SUB_HEADER_CLASS
      : DEFAULT_SUB_HEADER_CLASS + " slds-grid_align-spread";
  }

  handleHeaderCloseClick() {
    this.dispatchEvent(new CustomEvent("crossbtnclicked"));
  }
  /*END : FRONT - 15255 */
}