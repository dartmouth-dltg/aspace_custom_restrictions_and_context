class CustomRestrictionsInfiniteRecords extends CustomRestrictionsTreeBase {

  constructor(repoUri, appVersion = 4.1) {
    super(repoUri, appVersion);
  }

  fullConfig() {
    let decoratorNodeSelector = '.infinite-item h3';
    console.log(this.appVersion)
    if (this.appVersion >= 4.2) {
      decoratorNodeSelector = '.infinite-item .h3';
    }
    console.log(decoratorNodeSelector)
    const infiniteRecordCfg = {
      treeSelector: 'infinite-records-container',
      infiniteTree: true,
      isInfiniteRecord: true,
      isInfiniteScroll: false,
      nodeSelectorClass: 'infinite-record-record',
      decoratorNodeSelector: decoratorNodeSelector,
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...infiniteRecordCfg};
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, infiniteRecordsObserver) => {
      self.manipulateTree(mutationList);
    }

    const infiniteRecordsObserver = new MutationObserver(manipTree);
    infiniteRecordsObserver.observe(document.getElementById(this.cfg.treeSelector), this.mutationCfg.mutationConfig);
  }
}
