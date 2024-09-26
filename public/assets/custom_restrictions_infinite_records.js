class CustomRestrictionsInfiniteRecords extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }

  fullConfig() {
    const infiniteRecordCfg = {
      treeSelector: 'infinite-records-container',
      infiniteTree: true,
      isInfiniteRecord: true,
      isInfiniteScroll: false,
      nodeSelectorClass: 'infinite-record-record',
      decoratorNodeSelector: '.infinite-item h3',
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...infiniteRecordCfg};
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.manipulateTree(mutationList);
    }

    const observer = new MutationObserver(manipTree);
    observer.observe(document.getElementById(this.cfg.treeSelector), this.mutationCfg.mutationConfig);
  }
}
