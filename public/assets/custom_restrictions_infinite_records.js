class CustomRestrictionsInfiniteRecords extends CustomRestrictionsTreeBase {

  constructor(repoId) {
    super(repoId);
    this.treeSelector = 'infinite-records-container';
    this.infiniteTree = true;
    this.isInfiniteRecord = true;
    this.nodeSelectorClass = 'infinite-record-record';
    this.decoratorNodeSelector = '.infinite-item h3';
    this.uriSelector = 'data-uri';
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.manipulateTree(mutationList);
    }
    const observer = new MutationObserver(manipTree);
    observer.observe(document.getElementsByClassName(this.treeSelector)[0], this.mutationConfig);
  }
}
