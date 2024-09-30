const MOBILE_SCREEN_STACK = {
  stack: [],
  push: function (thisArg) {
    if (this.stack.length > 0) {
      const lastScreen = this.stack[this.stack.length - 1];
      let lastZIndex = lastScreen._zIndex;
      let isLastScreenFooterAvailable =
        lastScreen.showFooter || lastScreen._previousFooterHeight > 0;
      thisArg.setZIndex(lastZIndex + 1);
      if (!thisArg.showFooter && isLastScreenFooterAvailable) {
        thisArg._previousFooterHeight =
          lastScreen._footerHeight > 0
            ? lastScreen._footerHeight
            : lastScreen._previousFooterHeight;
      }

      if (isLastScreenFooterAvailable && !this._isPreviousFooterHidden) {
        thisArg.setBufferHeight(thisArg._previousFooterHeight);
      }
      if (thisArg.fullScreenView) {
        this.setFullScreen(thisArg);
      } else {
        lastScreen.hide({
          hideTitle: thisArg._isPreviousTitleHidden,
          hideFooter: thisArg._isPreviousFooterHidden
        });
      }
      thisArg.show();
    }

    this.stack.push(thisArg);
  },

  pop: function (thisArg) {
    const screenIndex = this.stack.findIndex((item) => item === thisArg);
    if (screenIndex !== -1) {
      const lastScreen = this.stack[screenIndex - 1];
      const currentScreen = this.stack[screenIndex];
      currentScreen.hide();
      if (currentScreen.fullScreenView) {
        this.unsetFullScreen(thisArg);
      } else if (lastScreen) {
        lastScreen.show();
      }

      this.stack.splice(screenIndex, 1);
    }
  },

  setFullScreen: function (thisArg) {
    if (this.stack.length > 0) {
      for (let screen of this.stack) {
        if (screen !== thisArg || !thisArg) {
          screen.setBufferHeight(0);
          screen.hide();
        }
      }
    }
  },

  unsetFullScreen: function (thisArg) {
    if (this.stack.length > 0) {
      let screenCount = this.stack.length;
      let lastScreen = screenCount > 1 ? this.stack[screenCount - 2] : null;
      // if (lastScreen && lastScreen.showFooter) {
      //   lastScreen.setBufferHeight(screenCount._previousFooterHeight);
      // }
      if (lastScreen && lastScreen !== thisArg) {
        lastScreen.setBufferHeight(lastScreen._previousFooterHeight);
        lastScreen.show();
      }

      try {
        if (screenCount > 1) {
          for (let i = this.stack.length - 3; i >= 0; i--) {
            let screen = this.stack[i];
            if (screen._previousFooterHeight === 0) {
              screen.show();
            }
          }
        }
      } catch (e) {
        console.error(e);
      }
    }
  }
};

export default MOBILE_SCREEN_STACK;