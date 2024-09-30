const FORM_REGISTRY = {
  components: {},
  register: function (thisArg) {
    if (!this.components[thisArg.config]) {
      let component = {
        context: thisArg
      };
      this.components[thisArg.config] = component;
    }
  },
  unregisterContext: function (thisArg) {
    if (this.components[thisArg.config]) {
      delete this.components[thisArg.config].context;
    }
  },
  unregisterAll: function (thisArg) {
    if (this.components[thisArg.config]) {
      delete this.components[thisArg.config];
    }
  },
  getComponentPropFromRegistry: function (thisArg, propName) {
    return this.components[thisArg.config] !== undefined
      ? this.components[thisArg.config][propName]
      : undefined;
  },
  setComponentPropsInRegistry: function (thisArg, propName, value) {
    this.components[thisArg.config][propName] = value;
  }
};

export default FORM_REGISTRY;