class CustomRestrictionsInfiniteScroll extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }
  
  fullConfig() {
    const infiniteScrollCfg = {
      isInfiniteScroll: true,
      treeSelector: 'infinite-record-wrapper',
      nodeSelectorClass: 'record-title',
      decoratorNodeSelector: 'a.recordTitle',
      uriSelector: 'href',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...infiniteScrollCfg};
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, infiniteScrollObserver) => {
      self.manipulateTree(mutationList);
    }
    const infiniteScrollObserver = new MutationObserver(manipTree);
    const container = document.getElementsByClassName(this.cfg.treeSelector)[0];
    if (container) {
      infiniteScrollObserver.observe(container, this.mutationCfg.mutationConfig);
    }
  }
}
