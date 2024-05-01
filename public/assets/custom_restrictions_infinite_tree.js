class CustomRestrictionsInfiniteTree extends CustomRestrictionsTreeBase {

  constructor(repoId) {
    super(repoId);
    this.infiniteTree = true;
    this.nodeSelectorClass = 'largetree-node';
    this.decoratorNodeSelector = 'a.record-title';
    this.uriSelector = 'data-uri';
  }
}
