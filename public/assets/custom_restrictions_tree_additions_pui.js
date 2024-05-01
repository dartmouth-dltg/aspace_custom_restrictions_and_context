class CustomRestrictionsTree extends CustomRestrictionsTreeBase {

  constructor(repoId) {
    super(repoId);
    this.decoratorNodeSelector = 'a.record-title';
    this.nodeSelectorClass = 'record-title';
    this.uriSelector = 'href';
    this.decoratorNodeSelector = '.infinite-item h3';
  }
}
